-- Mobile gesture-like keybindings
-- These emulate swipe gestures using easily accessible thumb keys
-- Only loaded when running on Termux Android

-- Set mobile-friendly leader
vim.g.mapleader = " "

-- Real cursor movement with arrow keys (actual swipe gestures)
-- These are designed to work with terminal emulators that
-- translate touch swipes into arrow key events

-- Buffer navigation (swipe left/right on screen edges)
vim.keymap.set('n', '<Leader>[', ':bp<CR>', { noremap = true, silent = true, desc = "Swipe Left - Previous buffer" })
vim.keymap.set('n', '<Leader>]', ':bn<CR>', { noremap = true, silent = true, desc = "Swipe Right - Next buffer" })

-- Window navigation (swipe within editor area)
vim.keymap.set('n', '<Leader>{', '<C-w>k', { noremap = true, silent = true, desc = "Swipe Up - Window above" })
vim.keymap.set('n', '<Leader>}', '<C-w>j', { noremap = true, silent = true, desc = "Swipe Down - Window below" })

-- Precise cursor movement for fine control after coarse swipes
vim.keymap.set('n', '<Right>', 'l', { noremap = true, silent = true, desc = "Cursor right" })
vim.keymap.set('n', '<Left>', 'h', { noremap = true, silent = true, desc = "Cursor left" })
vim.keymap.set('n', '<Up>', 'k', { noremap = true, silent = true, desc = "Cursor up" })
vim.keymap.set('n', '<Down>', 'j', { noremap = true, silent = true, desc = "Cursor down" })

-- Half-screen jumps for quick navigation (swipe then tap)
vim.keymap.set('n', '<PageDown>', '<C-d>', { noremap = true, silent = true, desc = "Half page down" })
vim.keymap.set('n', '<PageUp>', '<C-u>', { noremap = true, silent = true, desc = "Half page up" })

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
