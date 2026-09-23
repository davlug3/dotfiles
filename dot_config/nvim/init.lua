-- Disable netrw BEFORE anything (esp. lazy.nvim) can load it.
-- Neo-tree handles directory browsing instead.
-- NOTE: these must stay here at the top. Setting them later (e.g. in
-- config/options.lua, after lazy.setup()) is too late: lazy triggers
-- `packadd netrw` during setup, the plugin then defines its FileExplorer
-- VimEnter autocmds, but the autoload file bails out early on
-- g:loaded_netrw — leaving `netrw#LocalBrowseCheck` undefined (E117).
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set leader key BEFORE loading plugins (required by lazy.nvim)
vim.g.mapleader = " "

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