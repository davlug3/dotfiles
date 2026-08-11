-- Set leader key BEFORE loading plugins (required by lazy.nvim)
vim.g.mapleader = " "

vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')

require('lazy').setup({
  -- Import per-plugin specs from lua/plugins (lazy.nvim auto-loads them).
  { import = 'plugins' },
}, {
  colorscheme = 'PaperColor',
  install = { colorscheme = { 'PaperColor' } },
})

require('config.options')
require('config.keymaps')
require('config.lsp')

-- Load Termux Android mobile-specific configuration
-- Uses filesystem detection for reliable Termux identification
if vim.fn.isdirectory("/data/data/com.termux") == 1 then
  require('config.mobile')
  require('config.mobile_keymaps')
end