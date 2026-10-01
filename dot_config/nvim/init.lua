
-- Diable netrw in favor of neo-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set leader key BEFORE loading plugins (required by lazy.nvim)
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')

require('lazy').setup({
  -- Import per-plugin specs from lua/plugins (lazy.nvim auto-loads them).
  { import = 'plugins' },
}, {
  colorscheme = 'catppuccin',
  install = { colorscheme = { 'catppuccin' } },
  performance = {
    rtp = {
      -- Belt-and-braces: keep lazy from adding netrw to the rtp.
      disabled_plugins = { 'netrw', 'netrwPlugin' },
    },
  },
})

require('config.options')
require('config.narrow')
require('config.manual')
require('config.keymaps')
require('config.lsp')
require('config.dap')
