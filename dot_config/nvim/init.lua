-- Set leader key BEFORE loading plugins (required by lazy.nvim)
vim.g.mapleader = " "

vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')

require('lazy').setup({
  -- Import per-plugin specs from lua/plugins (lazy.nvim auto-loads them).
  { import = 'plugins' },
}, {
  colorscheme = 'catppuccin',
  install = { colorscheme = { 'catppuccin' } },
})

require('config.options')
require('config.keymaps')
require('config.lsp')