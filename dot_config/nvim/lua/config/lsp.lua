-- Setup is handled by the plugin config.
local _setup_done = false
local function setup()
  if _setup_done then
    return
  end
  _setup_done = true
  require('mason').setup()
  require('mason-lspconfig').setup({
    ensure_installed = {}, -- Install on demand, not upfront
    automatic_installation = true, -- Install when a server is requested
    automatic_enable = true, -- Auto-enable servers when installed
  })
end

local _configs_done = false
local function setup_lsp_configs()
  if _configs_done then
    return
  end
  _configs_done = true
  -- Configure lua_ls to use system installation if available
  if vim.fn.executable('lua-language-server') == 1 then
    vim.lsp.config['lua_ls'] = {
      cmd = { 'lua-language-server' },
    }
    pcall(vim.lsp.enable, 'lua_ls')
  end

  -- gopls: formatting via gofumpt + staticcheck + unusedparams/shadow analyses.
  -- goimports-style import organizing is done on save via the
  -- source.organizeImports code action below (no extra plugin needed).
  vim.lsp.config['gopls'] = {
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
        usePlaceholders = true,
        analyses = {
          unusedparams = true,
          shadow = true,
        },
      },
    },
  }
end

-- Vue + TypeScript: vue_ls requires a companion ts_ls/vtsls client in the
-- same project, otherwise it errors with "Could not find ts_ls, vtsls, or
-- typescript-tools lsp client required by vue_ls". ts_ls must also load
-- @vue/typescript-plugin and claim the `vue` filetype.
local function vue_typescript_plugin_location()
  local candidates = {
    vim.fn.stdpath('data') .. '/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin',
  }
  for _, p in ipairs(candidates) do
    if vim.fn.isdirectory(p) == 1 then
      return p
    end
  end
  -- Fallback: global npm install (npm i -g @vue/typescript-plugin).
  local npm_root = vim.fn.system({ 'npm', 'root', '-g' }):gsub('%s+$', '')
  if npm_root ~= '' then
    local p = npm_root .. '/@vue/typescript-plugin'
    if vim.fn.isdirectory(p) == 1 then
      return p
    end
  end
  return nil
end

local function vue_typescript_tsdk()
  local candidates = {
    vim.fn.stdpath('data') .. '/mason/packages/typescript-language-server/node_modules/typescript/lib',
    vim.fn.stdpath('data') .. '/mason/packages/vue-language-server/node_modules/typescript/lib',
  }
  for _, p in ipairs(candidates) do
    if vim.fn.isdirectory(p) == 1 then
      return p
    end
  end
  return nil
end

do
  local plugin_location = vue_typescript_plugin_location()
  local plugins = {}
  if plugin_location then
    plugins = {
      {
        name = '@vue/typescript-plugin',
        location = plugin_location,
        languages = { 'vue' },
      },
    }
  end
  vim.lsp.config['ts_ls'] = {
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    init_options = {
      plugins = plugins,
    },
  }
end

do
  local tsdk = vue_typescript_tsdk()
  local init_options = {
    vue = {
      -- Takeover mode: vue_ls handles all Vue intelligence, ts_ls assists
      -- via @vue/typescript-plugin. hybridMode = true would split duties.
      hybridMode = false,
    },
  }
  if tsdk then
    init_options.typescript = { tsdk = tsdk }
  end
  vim.lsp.config['vue_ls'] = {
    filetypes = { 'vue' },
    init_options = init_options,
  }
end

local function capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if ok then
    caps = cmp_nvim_lsp.default_capabilities(caps)
  end
  return caps
end

vim.lsp.config['*'] = {
  capabilities = capabilities(),
}

-- Servers are auto-enabled by mason-lspconfig on demand.
-- Completion (nvim-cmp) is configured in lua/plugins/lsp.lua.

-- LSP buffer local keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(args)
    local buf = args.buf
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    map('n', 'gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    map('n', 'gr', vim.lsp.buf.references, '[G]oto [R]eferences')
    map('n', 'gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    map('n', 'gt', vim.lsp.buf.type_definition, '[G]oto [T]ype definition')
    map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
    map('n', '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('n', '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    map('n', '<leader>cf', function()
      vim.lsp.buf.format({ async = false })
    end, '[C]ode [F]ormat buffer')
    map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  end,
})

-- Go: goimports (organize imports) + gofumpt formatting on save via gopls.
-- No extra plugin needed; guarded so it only runs when gopls is attached.
-- Synchronous so edits land before the write completes.
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function(args)
    local params = vim.lsp.util.make_range_params(nil, 'utf-8')
    params.context = { only = { 'source.organizeImports' } }
    local resp = vim.lsp.buf_request_sync(args.buf, 'textDocument/codeAction', params, 1000)
    if resp then
      for _, r in pairs(resp) do
        for _, action in pairs(r.result or {}) do
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, 'utf-8')
          else
            vim.lsp.buf.execute_command(action.command)
          end
        end
      end
    end
    local clients = vim.lsp.get_clients({ bufnr = args.buf, name = 'gopls' })
    if #clients > 0 then
      vim.lsp.buf.format({ bufnr = args.buf, async = false })
    end
  end,
})

-- Treesitter highlighting for gotmpl: chezmoi-template.nvim only sets the
-- filetype + registers the injection directive, so start parsing explicitly.
-- When the deployed filetype has no treesitter parser (e.g. tmux, gitconfig)
-- the plugin injects nothing and the buffer would stay unhighlighted, so fall
-- back to that filetype's classic syntax in the gotmpl buffer.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gotmpl',
  callback = function(args)
    local ft = vim.b[args.buf].chezmoi_target_ft
    local lang = vim.b[args.buf].chezmoi_target_lang

    if ft and ft ~= 'gotmpl' and not lang then
      local has_syntax = vim.api.nvim_get_runtime_file('syntax/' .. ft .. '.vim', false)[1]
      if has_syntax then
        vim.treesitter.stop(args.buf)
        -- Neovim's syntaxset FileType autocmd runs after this one and sets
        -- `syntax` to the buffer filetype (gotmpl), so wait for it to finish.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype == 'gotmpl' then
            vim.bo[args.buf].syntax = ft
          end
        end)
        return
      end
    end

    vim.treesitter.start(args.buf)
  end,
})

return {
  setup = function()
    setup()
    setup_lsp_configs()
  end,
}