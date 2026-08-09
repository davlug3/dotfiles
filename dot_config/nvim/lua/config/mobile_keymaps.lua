-- Mobile gesture-like keybindings
-- These emulate swipe gestures using easily accessible thumb keys
-- Only loaded when running on Termux Android

-- Set mobile-friendly leader
vim.g.mapleader = " "

-- Swipe-left equivalent (previous buffer)
vim.keymap.set('n', '<Leader>[', ':b#<CR>', { noremap = true, silent = true, desc = "Swipe Left - Previous buffer" })

-- Swipe-right equivalent (next buffer)
vim.keymap.set('n', '<Leader>]', ':bn<CR>', { noremap = true, silent = true, desc = "Swipe Right - Next buffer" })

-- Swipe-up equivalent (window above)
vim.keymap.set('n', '<Leader>}', '<C-w>k', { noremap = true, silent = true, desc = "Swipe Up - Window above" })

-- Swipe-down equivalent (window below)
vim.keymap.set('n', '<Leader>{', '<C-w>j', { noremap = true, silent = true, desc = "Swipe Down - Window below" })

-- Diagonal swipe-left-up (top-left split)
vim.keymap.set('n', '<Leader>h', '<C-w>t<C-w>H', { noremap = true, silent = true, desc = "Diagonal Swipe - Top-left split" })

-- Diagonal swipe-right-down (bottom-right split)
vim.keymap.set('n', '<Leader>l', '<C-w>b<C-w>L', { noremap = true, silent = true, desc = "Diagonal Swipe - Bottom-right split" })

-- Pinch-to-zoom equivalent (toggle zoom)
vim.keymap.set('n', '<Leader>z', ':wincmd _<CR>:wincmd |<CR>', { noremap = true, silent = true, desc = "Pinch - Toggle zoom" })

-- Double-tap save (quick save with visual feedback)
vim.keymap.set('n', '<Leader>s', ':w<CR>:echo "Saved!"<CR>', { noremap = true, silent = true, desc = "Double-tap - Quick save" })

-- Quick terminal exit (swipe down from top)
vim.keymap.set('n', '<Leader>q', ':q<CR>', { noremap = true, silent = true, desc = "Swipe Down - Quick exit" })

-- Visual feedback for navigation (less intrusive)
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true, desc = "Swipe Left" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true, silent = true, desc = "Swipe Down" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true, silent = true, desc = "Swipe Up" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true, desc = "Swipe Right" })

-- Mobile-optimized copy/paste (integration with termux-clipboard)
if vim.fn.executable('termux-clipboard-get') == 1 then
  vim.keymap.set('n', '<Leader>y', '"+y', { noremap = true, silent = true, desc = "Copy to clipboard" })
  vim.keymap.set('n', '<Leader>p', '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })
end
