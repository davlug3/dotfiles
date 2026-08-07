local servers = {
  'ts_ls',
  'pyright',
  'rust_analyzer',
  'terraformls',
  'lua_ls',
  'html',
  'cssls',
  'jsonls',
}

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = servers,
  automatic_installation = true,
})

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
    map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
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