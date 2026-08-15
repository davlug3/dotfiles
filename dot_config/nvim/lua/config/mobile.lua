-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android
-- Provides enhanced touch support and visual feedback

-- Set flag to indicate mobile mode is active
vim.g.mobile_mode = true

-- Touch Gesture Handling
-- Disable mouse in Neovim to prevent scrolling interference
-- This ensures touch gestures only move the cursor
vim.opt.mouse = ""

-- Disable automatic scrolling when cursor moves near edges
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 0

-- Disable line wrapping for precise cursor positioning
vim.opt.wrap = false
vim.opt.linebreak = false

-- ─── HORIZONTAL SWIPE DETECTION ────────────────────────────────────────
-- Handle terminal sequences that might represent horizontal touch gestures
-- Debug: set to true to log all received key sequences
local debug_swipes = false

vim.on_key(function(key, _)
  -- Debug logging
  if debug_swipes then
    local hex_key = ""
    for i = 1, #key do
      hex_key = hex_key .. string.format("%02x:", string.byte(key, i))
    end
    print("KEY: [" .. hex_key .. "] name: " .. vim.fn.keytrans(key))
  end

  -- Handle any escape sequence ending in C or D (horizontal gestures)
  if #key >= 2 and key:sub(1, 1) == "\x1b" and (key:sub(-1) == "C" or key:sub(-1) == "D") then
    if key:sub(-1) == "C" then
      -- Convert any horizontal right gesture to cursor right
      vim.api.nvim_feedkeys("l", "nt", false)
      return false
    elseif key:sub(-1) == "D" then
      -- Convert any horizontal left gesture to cursor left
      vim.api.nvim_feedkeys("h", "nt", false)
      return false
    end
  end
end)

-- Visual Optimizations for Touch
-- Better cursor visibility
vim.g.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- Touch-friendly line numbers
vim.opt.number = true
vim.opt.relativenumber = true

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

-- Visual bell instead of audio h
vim.opt.visualbell = true
vim.opt.errorbells = false

-- Better completion for touch
vim.opt.completeopt = "menuone,noinsert,noselect,preview"

-- Simple statusline for mobile
vim.opt.statusline = "%{mode()} %f %h%m %=%-14.(%l:%c%V%) %P"

vim.g.mobile_config_loaded = true
