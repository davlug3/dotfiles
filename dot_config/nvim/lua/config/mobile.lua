-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android
-- Provides enhanced touch support and visual feedback

-- Set flag to indicate mobile mode is active
vim.g.mobile_mode = true

-- Touch Gesture Handling
-- CRITICAL: Disable mouse to prevent scrolling interference
-- This ensures touch gestures only move the cursor
vim.opt.mouse = ""

-- Disable automatic scrolling when cursor moves near edges
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 0

-- Disable line wrapping for precise cursor positioning
vim.opt.wrap = false
vim.opt.linebreak = false

-- Visual Optimizations for Touch
-- Better cursor visibility
vim.g.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.cursorline = true
vim.opt.cursorcolumn = false

-- Touch-friendly line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- Better visual feedback
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.ruler = false

-- Visual indicators for mobile mode
vim.opt.laststatus = 2
vim.opt.showtabline = 2

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

-- Simple statusline for mobile
vim.opt.statusline = " %{mode()} %f %h%m %=%-14.(%l:%c%V%) %P"

vim.g.mobile_config_loaded = true
