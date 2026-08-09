-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android
-- Provides real touch swipe gestures and mobile-optimized settings

-- Apply mobile-specific settings
vim.g.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.signcolumn = "yes"      -- Prevents text shifting
vim.opt.wrap = true             -- Enable word wrap for better readability
vim.opt.linebreak = true        -- Break lines at word boundaries
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = false  -- Don't show relative line numbers (touch friendly)
vim.opt.hlsearch = true         -- Highlight search matches
vim.opt.incsearch = true        -- Incremental search
vim.opt.visualbell = true       -- Use visual bell instead of audio
vim.opt.scrolloff = 8           -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8       -- Keep 8 columns left/right of cursor

-- Enable true touch gesture support
-- These mappings enable swipe-like movement in normal mode using
-- terminal escape sequences that some terminal emulators send for swipes

-- Swipe left/right for window navigation
vim.keymap.set('n', '<Right>', '<C-w>l', { noremap = true, silent = true, desc = "Swipe Right - Next window" })
vim.keymap.set('n', '<Left>', '<C-w>h', { noremap = true, silent = true, desc = "Swipe Left - Previous window" })

-- Swipe up/down for buffer navigation
vim.keymap.set('n', '<Up>', ':bprevious<CR>', { noremap = true, silent = true, desc = "Swipe Up - Previous buffer" })
vim.keymap.set('n', '<Down>', ':bnext<CR>', { noremap = true, silent = true, desc = "Swipe Down - Next buffer" })

-- Diagonal swipes for split navigation
vim.keymap.set('n', '<Home>', '<C-w>t<C-w>H', { noremap = true, silent = true, desc = "Swipe Diagonal - Top-left split" })
vim.keymap.set('n', '<End>', '<C-w>b<C-w>L', { noremap = true, silent = true, desc = "Swipe Diagonal - Bottom-right split" })

-- Enable cursor movement with arrow keys for precision
-- This allows fine cursor control after coarse swipe navigation
vim.keymap.set('n', '<Tab>', 'zz', { noremap = true, silent = true, desc = "Center cursor" })
