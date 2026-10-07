
-- Diable netrw in favor of neo-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set leader key BEFORE loading plugins (required by lazy.nvim)
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim (clone on first run; no-op afterwards).
-- Per https://lazy.folke.io/installation
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

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
