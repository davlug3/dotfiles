return {
  {
    'williamboman/mason.nvim',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUninstallAll', 'MasonLog' },
  },
  {
    'williamboman/mason-lspconfig.nvim',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig' },
    config = function()
      local lsp = require('config.lsp')
      if lsp.setup then
        lsp.setup()
      end
    end,
  },
  {
    'neovim/nvim-lspconfig',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
  },
  {
    'hrsh7th/nvim-cmp',
    lazy = true,
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
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
    end,
  },
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  { 'hrsh7th/cmp-path', lazy = true },
  { 'L3MON4D3/LuaSnip', lazy = true },
  { 'saadparwaiz1/cmp_luasnip', lazy = true },
}