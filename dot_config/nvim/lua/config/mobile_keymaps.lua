-- Mobile gesture-like keybindings
-- These emulate swipe gestures using easily accessible thumb keys
-- Only loaded when running on Termux Android

-- CORE SWIPE GESTURES - CURSOR MOVEMENT ONLY (NO SCROLLING)

-- Horizontal swipes - move cursor left/right (no scrolling ever)
vim.keymap.set('n', '<Right>', 'l', { noremap = true, silent = true, desc = "Swipe Right - Move cursor right" })
vim.keymap.set('n', '<Left>', 'h', { noremap = true, silent = true, desc = "Swipe Left - Move cursor left" })

-- Shift-swipe gestures for enhanced horizontal navigation
-- These work in terminals that support shift-modified events
vim.keymap.set('n', '<S-Right>', 'W', { noremap = true, silent = true, desc = "Shift+Swipe Right - Jump to next word" })
vim.keymap.set('n', '<S-Left>', 'E', { noremap = true, silent = true, desc = "Shift+Swipe Left - Jump to previous word" })

-- Ctrl+arrows for larger jumps
vim.keymap.set('n', '<C-Right>', 'W', { noremap = true, silent = true, desc = "Ctrl+Right - Jump forward" })
vim.keymap.set('n', '<C-Left>', 'E', { noremap = true, silent = true, desc = "Ctrl+Left - Jump backward" })

-- Vertical swipes - move cursor up/down (no scrolling ever!)
vim.keymap.set('n', '<Up>', 'k', { noremap = true, silent = true, desc = "Swipe Up - Move cursor up" })
vim.keymap.set('n', '<Down>', 'j', { noremap = true, silent = true, desc = "Swipe Down - Move cursor down" })

-- Shift-swipe vertical for larger movements
vim.keymap.set('n', '<S-Up>', 'k', { noremap = true, silent = true, desc = "Shift+Swipe Up - Move cursor up" })
vim.keymap.set('n', '<S-Down>', 'j', { noremap = true, silent = true, desc = "Shift+Swipe Down - Move cursor down" })

-- Disable any scrollbar-like behavior (converts to cursor movement)
vim.keymap.set('n', '<ScrollWheelLeft>', 'h', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelRight>', 'l', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelUp>', 'k', { noremap = true, silent = true })
vim.keymap.set('n', '<ScrollWheelDown>', 'j', { noremap = true, silent = true })

-- DOUBLE-CLICK AS ENTER FUNCTIONALITY
-- When terminal sends double-click events, treat them as Enter key
vim.keymap.set('n', '<DoubleClick>', '<CR>', { noremap = true, silent = true, desc = "Double-click - Open/Expand" })
vim.keymap.set('n', '<TripleClick>', '<CR>', { noremap = true, silent = true, desc = "Triple-click - Open/Expand" })

-- In insert mode, double-click exits to normal mode and triggers open
vim.keymap.set('i', '<DoubleClick>', '<Esc><CR>', { noremap = true, silent = true, desc = "Double-click - Exit and open" })

-- When running inside tmux, also handle the C-m that tmux sends for double-click
vim.keymap.set('n', '<C-m>', '<CR>', { noremap = true, silent = true, desc = "Double-click (tmux) - Open/Expand" })
vim.keymap.set('i', '<C-m>', '<Esc><CR>', { noremap = true, silent = true, desc = "Double-click (tmux) - Exit and open" })

-- BUFFER NAVIGATION

-- Swipe left/right on screen edges to navigate buffers
vim.keymap.set('n', '<Leader>[', ':bp<CR>', { noremap = true, silent = true, desc = "Swipe Left - Previous buffer" })
vim.keymap.set('n', '<Leader>]', ':bn<CR>', { noremap = true, silent = true, desc = "Swipe Right - Next buffer" })

-- WINDOW/SPLIT NAVIGATION

-- Swipe up/down within editor area to switch windows
vim.keymap.set('n', '<Leader>{', '<C-w>k', { noremap = true, silent = true, desc = "Swipe Up - Window above" })
vim.keymap.set('n', '<Leader>}', '<C-w>j', { noremap = true, silent = true, desc = "Swipe Down - Window below" })

-- Diagonal swipes for split navigation
vim.keymap.set('n', '<Home>', '<C-w>t<C-w>H', { noremap = true, silent = true, desc = "Diagonal Swipe - Top-left split" })
vim.keymap.set('n', '<End>', '<C-w>b<C-w>L', { noremap = true, silent = true, desc = "Diagonal Swipe - Bottom-right split" })

-- GESTURE SEQUENCES

-- Multi-key gesture sequences for common operations

-- Save gesture (like double-tap save)
vim.keymap.set('n', '<Leader>s', ':w<CR>:echo " Saved"<CR>', 
               { noremap = true, silent = true, desc = "Double-tap - Quick save" })

-- Exit sequence
vim.keymap.set('n', '<Leader>q', ':q<CR>', 
               { noremap = true, silent = true, desc = "Swipe Down - Quick exit" })

-- Pinch-to-zoom equivalent (toggle zoom)
vim.keymap.set('n', '<Leader>z', ':wincmd _<CR>:wincmd |<CR>', 
               { noremap = true, silent = true, desc = "Pinch - Toggle zoom" })

-- PRECISION MOVEMENT

-- Tab centers cursor after navigation
vim.keymap.set('n', '<Tab>', 'zz', { noremap = true, silent = true, desc = "Center cursor after swipe" })

-- Half-page jumps converted to cursor movement
vim.keymap.set('n', '<PageDown>', 'j', { noremap = true, silent = true, desc = "Page Down - Move cursor down (not scroll)" })
vim.keymap.set('n', '<PageUp>', 'k', { noremap = true, silent = true, desc = "Page Up - Move cursor up (not scroll)" })

-- TERMINAL INTEGRATION

-- Mobile-optimized copy/paste with termux integration
if vim.fn.executable('termux-clipboard-get') == 1 then
  -- Copy to system clipboard
  vim.keymap.set('n', '<Leader>y', '"+y', { noremap = true, silent = true, desc = "Copy to system clipboard" })
  
  -- Paste from system clipboard
  vim.keymap.set('n', '<Leader>p', '"+p', { noremap = true, silent = true, desc = "Paste from system clipboard" })
  
  -- Send selection to clipboard immediately
  vim.keymap.set('v', '<Leader>y', '"+y', { noremap = true, silent = true, desc = "Copy selection to clipboard" })
end

-- MOBILE HELP SYSTEM

-- Quick help overlay for mobile gestures
vim.keymap.set('n', '<Leader>?', function()
  local help_text = {
    " MOBILE MODE - TOUCH GESTURES",
    "",
    "ARROW KEYS      Move cursor (no scrolling)",
    "SHIFT+ARROWS    Word/line jumps",
    "CTRL+ARROWS     Fast navigation",
    "DOUBLE-CLICK    Open/Expand (acts as Enter)",
    "<Leader>[/]    Previous/Next buffer",
    "<Leader>{/}    Up/Down windows",
    "<Home>/<End>   Diagonal window navigation",
    "<PageUp/Dn>   Cursor up/down (not scroll)",
    "<Tab>         Center cursor",
    "<Leader>s     Quick save (double-tap equivalent)",
    "<Leader>z     Toggle zoom (pinch equivalent)",
    "<Leader>y/p   Clipboard copy/paste",
    "<Leader>?     Show this help",
    "",
    "Press any key to dismiss"
  }
  
  -- Create a floating window with help text
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
  
  local width = math.floor(vim.o.columns * 0.8)
  local height = #help_text + 2
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Mobile Gesture Help"
  })
  
  -- Auto-close on any key press
  vim.api.nvim_set_current_win(win)
  local char = vim.fn.getcharstr()
  vim.api.nvim_win_close(0, true)
end, { noremap = true, silent = true, desc = "Show mobile gesture help" })

-- Set up auto-commands for visual feedback
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.g.mobile_mode then
      -- Brief visual feedback when entering buffer
      vim.defer_fn(function()
        print(" Mobile mode active")
      end, 500)
    end
  end
})
