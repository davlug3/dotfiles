-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android
-- Provides gesture-like navigation and touch-friendly settings

-- Force cursor-only movement (disable all scrolling behavior)
vim.opt.scrolloff = 0  -- Never scroll ahead of cursor
vim.opt.sidescrolloff = 0  -- Never sideway-scroll ahead of cursor
vim.opt.wrap = false  -- Disable wrapping for precise cursor control
vim.opt.linebreak = false  -- Don't break at word boundaries

-- Visual settings optimized for touch
vim.g.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.signcolumn = "yes"  -- Prevents text shifting
vim.opt.number = true  -- Show line numbers
vim.opt.relativenumber = false  -- Absolute line numbers for easier touch targeting
vim.opt.cursorline = true  -- Highlight current line for better touch targeting
vim.opt.showmode = true  -- Show current mode

-- Better visual selection for touch
vim.opt.hlsearch = true  -- Highlight search matches
vim.opt.incsearch = true  -- Incremental search
vim.opt.visualbell = true  -- Use visual bell instead of audio
vim.opt.scrolloff = 8  -- Keep some context though
vim.opt.sidescrolloff = 8

-- Disable mouse scrolling behavior to prevent interference with swipes
vim.opt.mouse = ""  -- Disable mouse entirely to prevent scroll events
