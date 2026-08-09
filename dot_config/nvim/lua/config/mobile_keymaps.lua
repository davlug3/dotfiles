-- Mobile gesture-like keybindings
-- These emulate swipe gestures that ONLY move the cursor (no scrolling)
-- Only loaded when running on Termux Android

-- Note: vim.g.mapleader is already set in init.lua to " "

-- SWIPE GESTURES - CURSOR MOVEMENT ONLY (NO SCROLLING)
-- These mappings ensure that touch gestures only move the cursor,
-- not scroll the viewport

-- Horizontal swipes - move cursor left/right (no scrolling ever)
vim.keymap.set('n', '<Right>', 'l', { noremap = true, silent = true, desc = "Swipe Right - Move cursor right" })
vim.keymap.set('n', '<Left>', 'h', { noremap = true, silent = true, desc = "Swipe Left - Move cursor left" })

-- Vertical swipes - move cursor up/down (no scrolling ever!)
vim.keymap.set('n', '<Up>', 'k', { noremap = true, silent = true, desc = "Swipe Up - Move cursor up" })
vim.keymap.set('n', '<Down>', 'j', { noremap = true, silent = true, desc = "Swipe Down - Move cursor down" })

-- Disable any scrollbar-like behavior (converts to cursor movement)
vim.keymap.set('n', '<ScrollWheelLeft>', 'h', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelRight>', 'l', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelUp>', 'k', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelDown>', 'j', { noremap = true, silent = true })

-- Buffer navigation (swipe left/right on screen edges)
vim.keymap.set('n', '<Leader>[', ':bp<CR>', { noremap = true, silent = true, desc = "Swipe Left - Previous buffer" })
vim.keymap.set('n', '<Leader>]', ':bn<CR>', { noremap = true, silent = true, desc = "Swipe Right - Next buffer" })

-- Window navigation (swipe within editor area)
vim.keymap.set('n', '<Leader>{', '<C-w>k', { noremap = true, silent = true, desc = "Swipe Up - Window above" })
vim.keymap.set('n', '<Leader>}', '<C-w>j', { noremap = true, silent = true, desc = "Swipe Down - Window below" })

-- Diagonal swipe navigation
vim.keymap.set('n', '<Home>', '<C-w>t<C-w>H', { noremap = true, silent = true, desc = "Diagonal Swipe - Top-left split" })
vim.keymap.set('n', '<End>', '<C-w>b<C-w>L', { noremap = true, silent = true, desc = "Diagonal Swipe - Bottom-right split" })

-- Zoom and save gestures
vim.keymap.set('n', '<Leader>z', ':wincmd _<CR>:wincmd |<CR>', { noremap = true, silent = true, desc = "Pinch - Toggle zoom" })
vim.keymap.set('n', '<Leader>s', ':w<CR>:echo "Saved!"<CR>', { noremap = true, silent = true, desc = "Double-tap - Quick save" })
vim.keymap.set('n', '<Leader>q', ':q<CR>', { noremap = true, silent = true, desc = "Swipe Down - Quick exit" })

-- Tab for centering cursor after navigation
vim.keymap.set('n', '<Tab>', 'zz', { noremap = true, silent = true, desc = "Center cursor after swipe" })

-- Mobile-optimized copy/paste (integration with termux-clipboard)
if vim.fn.executable('termux-clipboard-get') == 1 then
  vim.keymap.set('n', '<Leader>y', '"+y', { noremap = true, silent = true, desc = "Copy to clipboard" })
  vim.keymap.set('n', '<Leader>p', '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })
end

-- Ensure cursor stays visible during movement without scrolling
vim.opt.scrolloff = 0  -- Never scroll ahead of cursor
vim.opt.sidescrolloff = 0  -- Never sideway-scroll ahead of cursor
