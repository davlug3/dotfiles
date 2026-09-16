local servers = {
  'ts_ls',
  'pyright',
  'terraformls',
  'lua_ls',
  'html',
  'cssls',
  'jsonls',
  'gopls',
}

-- Remove lua_ls from Mason installation if already installed system-wide
if vim.fn.executable('lua-language-server') == 1 then
  for i, srv in ipairs(servers) do
    if srv == 'lua_ls' then
      table.remove(servers, i)
      break
    end
  end
end

-- Try to add rust_analyzer if rustup or rustc is available
if vim.fn.executable('rustc') == 1 or vim.fn.executable('rustup') == 1 then
  table.insert(servers, 'rust_analyzer')
end

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = servers,
  automatic_installation = false, -- Only install servers that are explicitly requested
})

-- Configure lua_ls to use system installation if available
if vim.fn.executable('lua-language-server') == 1 then
  vim.lsp.config['lua_ls'] = {
    cmd = { 'lua-language-server' },
  }
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

vim.lsp.config['*'] = {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

vim.lsp.enable(servers)

-- Completion
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

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
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gotmpl',
  callback = function()
    vim.treesitter.start()
  end,
})