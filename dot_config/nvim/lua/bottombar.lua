-- bottombar.lua
--
-- A state-machine driven button bar for Neovim in Termux, optimized 
-- using standard Vim cheat sheet patterns (vim.rtorr.com).
-- 
-- Division of labor:
--   - Termux `extra-keys` handles spatial navigation (h, j, k, l / arrows), 
--     modifiers (CTRL, ALT, ESC), and raw symbols/numbers.
--   - This 1D statusline handles Vim's contextual state: operators, 
--     text objects, motions, prefixes, and mode switching.

local M = {}

M.state = {
  page = 1,
  context = 'normal', -- 'normal', 'operator', 'visual', 'prefix_g', etc.
}

local NAV_PREV = 900
local NAV_NEXT = 901

local function feed(keys)
  local tc = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(tc, "n", false)
end

local function run(action)
  if type(action) == "function" then
    action()
  else
    feed(action)
  end
end

-- ===================== State Machine =====================

local function get_context()
  local mode_info = vim.api.nvim_get_mode()
  local m = mode_info.mode
  
  -- 1. Operator-pending is the highest priority (Vim native state 'no' or 'nov')
  if m == 'no' or m == 'nov' then return 'operator' end
  
  -- 2. Visual modes
  if m:match('^[vV\22]') then return 'visual' end
  
  -- 3. Insert/Replace
  if m:match('^[iR]') then return 'insert' end
  
  -- 4. Manual prefix contexts (set by bottom bar clicks)
  if M.state.context:match('^prefix_') then return M.state.context end
  
  return 'normal'
end

function M.enter_prefix(char)
  M.state.context = 'prefix_' .. char
  M.state.page = 1
  vim.cmd('redrawstatus')
  feed(char)
end

-- ===================== Button Definitions =====================
-- Note: h, j, k, l are intentionally omitted. Termux extra-keys handles them!

M.pages = {
  normal = {
    { -- Page 1: Core Operators & Insert Entry
      { label = ' d ', action = 'd' }, { label = ' c ', action = 'c' }, { label = ' y ', action = 'y' },
      { label = ' p ', action = 'p' }, { label = ' P ', action = 'P' }, { label = ' u ', action = 'u' },
      { label = '<C-r>', action = '<C-r>' }, { label = ' i ', action = 'i' }, { label = ' a ', action = 'a' },
      { label = ' o ', action = 'o' }, { label = ' O ', action = 'O' }, { label = ' I ', action = 'I' },
    },
    { -- Page 2: Mobile Superpowers (Quick Combos - saves 3+ taps)
      { label = 'dd', action = 'dd' }, { label = 'yy', action = 'yy' }, { label = 'cc', action = 'cc' },
      { label = 'ciw',action = 'ciw'}, { label = 'daw',action = 'daw'}, { label = 'caW',action = 'caW'},
      { label = '>>', action = '>>' }, { label = '<<', action = '<<' }, { label = ' * ', action = '*' },
      { label = ' . ', action = '.' }, { label = ' J ', action = 'J' }, { label = ' x ', action = 'x' },
    },
    { -- Page 3: Motions & Search (hjkl in Termux)
      { label = ' w ', action = 'w' }, { label = ' e ', action = 'e' }, { label = ' b ', action = 'b' },
      { label = ' 0 ', action = '0' }, { label = ' ^ ', action = '^' }, { label = ' $ ', action = '$' },
      { label = ' f ', action = 'f' }, { label = ' t ', action = 't' }, { label = ' F ', action = 'F' },
      { label = ' T ', action = 'T' }, { label = ' ; ', action = ';' }, { label = ' , ', action = ',' },
    },
    { -- Page 4: Prefixes, Marks & Misc
      { label = ' v ', action = 'v' }, { label = ' V ', action = 'V' }, { label = ' % ', action = '%' },
      { label = ' g ', action = function() M.enter_prefix('g') end },
      { label = ' [ ', action = function() M.enter_prefix('[') end },
      { label = ' ] ', action = function() M.enter_prefix(']') end },
      { label = ' Z ', action = function() M.enter_prefix('Z') end },
      { label = ' m ', action = 'm' }, { label = ' ` ', action = '`' }, { label = ' " ', action = '"' },
      { label = ' : ', action = ':' }, { label = ' / ', action = '/' },
    },
  },
  
  operator = { -- Shown when d/c/y/>/</= is pressed (Vim mode 'no')
    { -- Page 1: Word & Line Motions
      { label = ' w ', action = 'w' }, { label = ' e ', action = 'e' }, { label = ' b ', action = 'b' },
      { label = ' 0 ', action = '0' }, { label = ' ^ ', action = '^' }, { label = ' $ ', action = '$' },
      { label = ' _ ', action = '_' }, { label = ' W ', action = 'W' }, { label = ' E ', action = 'E' },
      { label = ' B ', action = 'B' },
    },
    { -- Page 2: Text Objects (The holy grail of Vim editing)
      { label = 'iw', action = 'iw' }, { label = 'aw', action = 'aw' },
      { label = 'i"', action = 'i"' }, { label = 'a"', action = 'a"' },
      { label = "i'", action = "i'" }, { label = "a'", action = "a'" },
      { label = 'i(', action = 'i(' }, { label = 'a(', action = 'a(' },
      { label = 'i[', action = 'i[' }, { label = 'a[', action = 'a[' },
      { label = 'i{', action = 'i{' }, { label = 'a{', action = 'a{' },
    },
    { -- Page 3: Block & Jump Motions
      { label = ' % ', action = '%' }, { label = ' { ', action = '{' }, { label = ' } ', action = '}' },
      { label = 'gg', action = 'gg' }, { label = ' G ', action = 'G' }, { label = ' H ', action = 'H' },
      { label = ' M ', action = 'M' }, { label = ' L ', action = 'L' },
    },
  },

  visual = {
    { -- Page 1: Immediate Actions on Selection
      { label = ' d ', action = 'd' }, { label = ' c ', action = 'c' }, { label = ' y ', action = 'y' },
      { label = ' > ', action = '>' }, { label = ' < ', action = '<' }, { label = ' = ', action = '=' },
      { label = ' ~ ', action = '~' }, { label = ' U ', action = 'U' }, { label = ' r ', action = 'r' },
      { label = ' J ', action = 'J' }, { label = ' o ', action = 'o' }, { label = ' : ', action = ':' },
    },
    { -- Page 2: Selection Motions & Toggles
      { label = ' w ', action = 'w' }, { label = ' e ', action = 'e' }, { label = ' b ', action = 'b' },
      { label = ' 0 ', action = '0' }, { label = ' $ ', action = '$' }, { label = ' f ', action = 'f' },
      { label = ' t ', action = 't' }, { label = ' F ', action = 'F' }, { label = ' T ', action = 'T' },
      { label = ' v ', action = 'v' }, { label = ' V ', action = 'V' }, { label = ' " ', action = '"' },
    },
  },

  insert = {
    {
      { label = 'ESC', action = '<Esc>' }, { label = ' ← ', action = '<Left>' }, 
      { label = ' → ', action = '<Right>' }, { label = ' ↑ ', action = '<Up>' }, 
      { label = ' ↓ ', action = '<Down>' }, { label = 'BS', action = '<BS>' }, 
      { label = 'DEL', action = '<Del>' }, { label = 'TAB', action = '<Tab>' },
    },
  },

  -- Prefix pages based on standard Vim combinations
  prefix_g = {
    {
      { label = ' g ', action = 'g' }, { label = ' e ', action = 'e' }, { label = ' E ', action = 'E' },
      { label = ' _ ', action = '_' }, { label = ' v ', action = 'v' }, { label = ' u ', action = 'u' },
      { label = ' U ', action = 'U' }, { label = ' ~ ', action = '~' }, { label = ' ? ', action = '?' },
      { label = ' J ', action = 'J' }, { label = ' i ', action = 'i' }, { label = ' p ', action = 'p' },
    },
  },
  ['prefix_['] = {
    {
      { label = ' [ ', action = '[' }, { label = ' ] ', action = ']' }, { label = ' p ', action = 'p' },
      { label = ' P ', action = 'P' }, { label = ' { ', action = '{' }, { label = ' ( ', action = '(' },
      { label = ' m ', action = 'm' },
    },
},
  ['prefix_]'] = {
    {
      { label = ' ] ', action = ']' }, { label = ' [ ', action = '[' }, { label = ' p ', action = 'p' },
      { label = ' P ', action = 'P' }, { label = ' } ', action = '}' }, { label = ' ) ', action = ')' },
      { label = ' m ', action = 'm' },
    },
  },
  prefix_Z = {
    {
      { label = ' Z ', action = 'Z' }, { label = ' Q ', action = 'Q' },
    },
  },
}

-- ===================== Click handling =====================

function _G.BottomBarClick(minwid, _clicks, _button, _mods)
  local ctx = get_context()
  local pages = M.pages[ctx] or M.pages.normal

  if minwid == NAV_PREV then
    M.state.page = M.state.page - 1
    if M.state.page < 1 then M.state.page = #pages end
    vim.cmd("redrawstatus")
    return
  elseif minwid == NAV_NEXT then
    M.state.page = M.state.page + 1
    if M.state.page > #pages then M.state.page = 1 end
    vim.cmd("redrawstatus")
    return
  end

  local is_prefix = ctx:match('^prefix_')
  local page = pages[M.state.page] or pages[1]
  local btn = page[minwid]
  
  if btn then
    run(btn.action)
    -- If we were in a prefix context, any button press completes it and resets
    if is_prefix then
      M.state.context = 'normal'
      M.state.page = 1
    end
    vim.cmd("redrawstatus")
  end
end

-- ===================== Rendering =====================

local function render_mode_badge()
  local mode_info = vim.api.nvim_get_mode()
  local m = mode_info.mode
  local mode_name = 'NORMAL'
  local hl_group = 'BottomBarMode'
  
  if m == 'no' or m == 'nov' then
    mode_name = 'OP-PENDING'
    hl_group = 'BottomBarOperator'
  elseif m:match('^[vV\22]') then
    mode_name = m == 'v' and 'VISUAL' or (m == 'V' and 'V-LINE' or 'V-BLOCK')
    hl_group = 'BottomBarVisual'
  elseif m:match('^[iR]') then
    mode_name = m == 'i' and 'INSERT' or 'REPLACE'
    hl_group = 'BottomBarInsert'
  end
  
  local pending = ''
  if M.state.context:match('^prefix_') then
    pending = ' · pending'
  elseif m == 'no' then
    pending = ' · motion?'
  end
  
  return string.format("%%#%s# %s%s %%*", hl_group, mode_name, pending)
end

local function render_status()
  local fname = vim.fn.expand("%:t")
  if fname == "" then fname = "[No Name]" end
  local modified = vim.bo.modified and " [+]" or ""
  local lnum = vim.fn.line(".")
  local col = vim.fn.col(".")
  return string.format("%%#BottomBarInfo#%s%s %d:%d%%*", fname, modified, lnum, col)
end

function M.render()
  local ctx = get_context()
  local pages = M.pages[ctx] or M.pages.normal
  
  if M.state.page > #pages then M.state.page = 1 end
  local page = pages[M.state.page]

  local parts = {}
  table.insert(parts, render_mode_badge())
  table.insert(parts, " ")
  table.insert(parts, render_status())
  
  table.insert(parts, "  ")
  
  -- Ensure v:lua. is present for Neovim statusline click syntax
  table.insert(parts, string.format("%%#BottomBarNav#%%%d@v:lua.BottomBarClick@ ◀ %%X", NAV_PREV))

  for i, btn in ipairs(page) do
    table.insert(parts, string.format("%%%d@v:lua.BottomBarClick@%%#BottomBarBtn#%s%%X", i, btn.label))
  end

  table.insert(parts, string.format("%%#BottomBarNav#%%%d@v:lua.BottomBarClick@ ▶ %%X", NAV_NEXT))
  table.insert(parts, string.format("%%#BottomBarInfo#%%=[p%d/%d]", M.state.page, #pages))

  return table.concat(parts, " ")
end

-- ===================== Setup =====================

function M.setup(opts)
  opts = opts or {}

  vim.o.laststatus = 3 
  vim.o.statusline = "%!v:lua.require('bottombar').render()"

  if opts.winbar ~= false then
    vim.o.winbar = "%f %m%r [%{&filetype}] %=%l:%c"
  end

  -- Nord-inspired palette for clear mode distinction
  vim.api.nvim_set_hl(0, "BottomBarBtn",  { bg = "#3b4252", fg = "#eceff4", bold = true })
  vim.api.nvim_set_hl(0, "BottomBarNav",  { bg = "#434c5e", fg = "#88c0d0", bold = true })
  vim.api.nvim_set_hl(0, "BottomBarInfo", { bg = "#2e3440", fg = "#d8dee9" })
  vim.api.nvim_set_hl(0, "BottomBarMode", { bg = "#5e81ac", fg = "#eceff4", bold = true }) -- Normal: Blue
  vim.api.nvim_set_hl(0, "BottomBarVisual", { bg = "#a3be8c", fg = "#2e3440", bold = true }) -- Visual: Green
  vim.api.nvim_set_hl(0, "BottomBarInsert", { bg = "#ebcb8b", fg = "#2e3440", bold = true }) -- Insert: Yellow
  vim.api.nvim_set_hl(0, "BottomBarOperator", { bg = "#d08770", fg = "#2e3440", bold = true }) -- Operator: Orange

  vim.api.nvim_create_augroup("BottomBar", { clear = true })
  
  -- Reset page and operator context on mode changes
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = "BottomBar",
    callback = function()
      M.state.page = 1
      if vim.api.nvim_get_mode().mode ~= 'no' then
        M.state.context = 'normal'
      end
      vim.cmd("redrawstatus")
    end,
  })

  -- Reset prefix contexts if the user types on the physical/extra keyboard 
  -- instead of the bottom bar (e.g., they press 'g' then 'j' which aborts)
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "TextChanged", "InsertEnter"}, {
    group = "BottomBar",
    callback = function()
      if M.state.context:match('^prefix_') then
        M.state.context = 'normal'
        M.state.page = 1
        vim.cmd("redrawstatus")
      end
    end,
  })
end

return M
