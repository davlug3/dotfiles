vim.cmd('source ~/.vimrc')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'tpope/vim-commentary' },
  { 'christoomey/vim-tmux-navigator' },
  { 'hashivim/vim-terraform' },
  { 'mattn/emmet-vim' },
  { 'NLKNguyen/papercolor-theme' },

  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  {
    'nvim-lualine/lualine.nvim',
    opts = { theme = 'PaperColor' },
  },

  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      filesystem = { follow_current_file = { enabled = true } },
    },
  },

  {
    'stevearc/aerial.nvim',
    opts = {},
    keys = {
      { '<F8>', '<cmd>AerialToggle<CR>', desc = 'Aerial (symbols)' },
    },
  },

  { 'williamboman/mason.nvim', build = ':MasonUpdate' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'L3MON4D3/LuaSnip' },
  { 'saadparwaiz1/cmp_luasnip' },
})

local servers = { 'ts_ls', 'pyright', 'rust_analyzer', 'gopls', 'terraformls', 'lua_ls', 'html', 'cssls', 'jsonls' }
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = servers,
  automatic_installation = true,
})

local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

for _, server in ipairs(servers) do
  lspconfig[server].setup({ capabilities = capabilities })
end

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

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<F1>', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fs', function()
  builtin.find_files({ hidden = true })
end, { desc = 'Telescope find files (hidden)' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>1', '<cmd>Neotree toggle<CR>', { desc = 'Toggle Neo-tree' })

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'
vim.opt.tags = vim.fn.stdpath('data') .. '/tags,tags'
vim.opt.completeopt = { 'menuone', 'noinsert', 'noselect', 'preview' }
vim.opt.relativenumber = true

local undodir = vim.fn.stdpath('data') .. '/undo'
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(args)
    local buf = args.buf
    local map = function(mode, lhs, rhs, desc)
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
