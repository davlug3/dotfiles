-- floatingbar.lua
-- A 2D floating button grid for Neovim in Termux.
-- No paging. All buttons for the current mode are visible at once.
-- Uses a "bouncy buffer" trick to prevent focus/cursor stealing.

local M = {}

local state = {
  win = nil,
  buf = nil,
  current_mode = 'n',
}

-- Button width in characters. Keep it consistent for click math.
local BTN_WIDTH = 4 

-- 2D Layouts. Every button is exactly BTN_WIDTH characters wide.
-- Normal mode gets 3 rows. Visual gets 2. Insert gets 1.
local layouts = {
  n = {
    { " d  ", " c  ", " y  ", " p  ", " u  ", " i  ", " a  ", " o  ", " v  ", " x  " },
    { " w  ", " e  ", " b  ", " 0  ", " $  ", " f  ", " t  ", " ;  ", " ,  ", " %  " },
    { "dd  ", "yy  ", ">>  ", "<<  ", "ciw ", "daw ", " I  ", " A  ", " O  ", " :  " },
  },
  v = {
    { " d  ", " c  ", " y  ", " >  ", " <  ", " ~  ", " U  ", " r  ", " J  ", " o  " },
    { " w  ", " e  ", " b  ", " 0  ", " $  ", " f  ", " t  ", " ;  ", " ,  ", " v  " },
  },
  i = {
    { "ESC ", " ←  ", " →  ", " ↑  ", " ↓  ", "BS  ", "DEL ", "TAB ", "    ", "    " },
  }
}

local function get_mode()
  local m = vim.api.nvim_get_mode().mode
  if m:match('^[vV\22]') then return 'v' end
  if m:match('^[iR]') then return 'i' end
  return 'n'
end

local function feed(keys)
  local tc = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(tc, 'n', false)
end

-- ===================== The "Bouncy" Click Logic =====================

local function on_click()
  local row = vim.v.mouse_lnum
  local col = vim.v.mouse_col
  
  -- Calculate which button was clicked based on column index
  local btn_idx = math.ceil(col / BTN_WIDTH)
  
  local mode = get_mode()
  local layout = layouts[mode]
  
  if layout and layout[row] and layout[row][btn_idx] then
    local action = layout[row][btn_idx]:gsub("%s+", "") -- trim spaces
    if action ~= "" then
      feed(action)
    end
  end
  
  -- CRITICAL: We do not return anything. Because this is a noremap, 
  -- the default <LeftMouse> (which moves the cursor) is blocked.
end

-- ===================== Window Management =====================

local function create_floating_window()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = 'nofile'
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].modifiable = false

  -- 1. The Intercept: Block default mouse behavior
  local opts = { noremap = true, silent = true, callback = on_click }
  vim.api.nvim_buf_set_keymap(state.buf, 'n', '<LeftMouse>', '', opts)
  vim.api.nvim_buf_set_keymap(state.buf, 'n', '<LeftDrag>', '<Nop>', opts)
  vim.api.nvim_buf_set_keymap(state.buf, 'n', '<LeftRelease>', '<Nop>', opts)

  -- 2. The Safety Net: Bounce focus back if it ever enters this window
  vim.api.nvim_create_autocmd("WinEnter", {
    buffer = state.buf,
    callback = function()
      -- If we somehow get focus, instantly go back to the previous window
      vim.cmd('wincmd p')
    end
  })

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * 0.95)
  local height = 3 -- Max 3 rows for normal mode
  
  -- Create the window
  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = vim.o.lines - vim.o.cmdheight - height - 2, -- Anchor to bottom
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  })

  -- Apply highlights to the window
  vim.wo[state.win].winhl = 'Normal:FloatBarBg,NormalFloat:FloatBarBg'
  vim.api.nvim_set_hl(0, 'FloatBarBg', { bg = '#2e3440', fg = '#d8dee9' })
  vim.api.nvim_set_hl(0, 'FloatBarBorder', { bg = '#2e3440', fg = '#5e81ac' })
end

local function render_grid()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  
  local mode = get_mode()
  local layout = layouts[mode]
  
  vim.bo[state.buf].modifiable = true
  
  -- Clear buffer
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
  
  -- Draw the 2D grid
  local lines = {}
  for _, row in ipairs(layout) do
    table.insert(lines, table.concat(row, ""))
  end
  
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  
  -- Resize window height if mode changes (e.g., Insert only needs 1 row)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local width = math.floor(vim.o.columns * 0.95)
    local height = #lines
    local new_row = vim.o.lines - vim.o.cmdheight - height - 2
    local col = math.floor((vim.o.columns - width) / 2)
    
    vim.api.nvim_win_set_config(state.win, {
      relative = 'editor',
      width = width,
      height = height,
      row = new_row,
      col = col,
    })
  end
end

-- ===================== Setup =====================

function M.setup()
  vim.o.mouse = 'a' -- Mandatory for touch clicks
  
  create_floating_window()
  render_grid()

  -- Redraw when mode changes
  vim.api.nvim_create_autocmd("ModeChanged", {
    callback = function()
      local new_mode = get_mode()
      if new_mode ~= state.current_mode then
        state.current_mode = new_mode
        render_grid()
      end
    end
  })

  -- Recalculate position if terminal resizes
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        local width = math.floor(vim.o.columns * 0.95)
        local height = #layouts[get_mode()]
        vim.api.nvim_win_set_config(state.win, {
          relative = 'editor',
          width = width,
          height = height,
          row = vim.o.lines - vim.o.cmdheight - height - 2,
          col = math.floor((vim.o.columns - width) / 2),
        })
        render_grid()
      end
    end
  })
end

return M
