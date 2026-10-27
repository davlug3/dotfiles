-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android (see lua/mobile.lua)
-- Provides touch-friendly options and visual feedback

-- Set flag to indicate mobile mode is active
vim.g.mobile_mode = true

-- Touch handling: mouse must stay enabled ('a') so statusline buttons and
-- <2-LeftMouse> events work. lua/mobile.lua owns this option.

-- Disable automatic scrolling when cursor moves near edges
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 0

-- Disable line wrapping for precise cursor positioning
vim.opt.wrap = false
vim.opt.linebreak = false

-- Visual Optimizations for Touch
-- Better cursor visibility
vim.opt.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.cursorline = true
vim.opt.cursorcolumn = false

-- Touch-friendly line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- Better visual feedback
vim.g.mobile_config_loaded = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.ruler = false

-- Statusline: owned by bottombar (loaded last by lua/mobile.lua).

-- Performance Optimizations
vim.opt.lazyredraw = true
vim.opt.ttyfast = true
vim.opt.updatecount = 5000
vim.opt.updatetime = 300

-- Mobile-Specific Settings
vim.opt.signcolumn = "yes"
vim.opt.foldcolumn = "auto"

-- Visual bell instead of audio
vim.opt.visualbell = true
vim.opt.errorbells = false

-- Better completion for touch
vim.opt.completeopt = "menuone,noinsert,noselect"
