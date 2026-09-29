-- Responsive UI for narrow screens (columns < threshold, e.g. phone portrait,
-- Termux split, tmux side-pane).
--
-- What it does when narrow:
--   * reclaims ~5 columns: foldcolumn 0, signcolumn 1 col, numberwidth 2,
--     no relativenumber
--   * soft-wrap friendly: breakindent + showbreak, sidescroll 1/0
--   * less chrome: global statusline, tabline only with >1 tab
--   * diagnostics virtual-text off (signs + float only, no wrap spam)
--   * gitsigns eol blame off (wraps badly on 50 cols)
--   * refreshes lualine so its hide_in_width components update
--
-- When the screen is wide again, everything it changed is restored to the
-- values you had before going narrow (snapshot/restore), instead of being
-- overwritten with hardcoded "wide" values.
--
-- Manual override:
--   :NarrowOn / :NarrowOff / :NarrowToggle  (sets vim.g.narrow_force)
--   unset with :NarrowAuto (follow vim.o.columns again)
--
-- Usage:
--   require('narrow')                        -- defaults (threshold 55)
--   require('narrow').setup({ threshold = 60 })
--   vim.keymap.set('n', '<leader>s', require('narrow').smart_split)

local M = {}

M.threshold = 55

-- Window-local options: applied to every normal window and (via vim.go) to
-- windows created later.
local WIN_NARROW = {
  number = true,
  relativenumber = false,
  numberwidth = 2,
  foldcolumn = '0',
  signcolumn = 'yes:1',
  wrap = true,
  linebreak = true,
  breakindent = true,
  showbreak = '\u{21AA} ', -- "↪ "
}

-- Global options.
local GLOBAL_NARROW = {
  sidescroll = 1,
  sidescrolloff = 0,
  scrolloff = 1,
  laststatus = 3, -- one global statusline
  showtabline = 1, -- tabline only with >1 tab
  cmdheight = 1,
  winminwidth = 10,
  winwidth = 10,
  splitkeep = 'screen',
}

-- Buffer types whose windows we leave alone.
local SKIP_BUFTYPE = { prompt = true, nofile = true, terminal = true }

-- State: nil = not applied yet, true/false = last applied narrow state.
M._state = nil
M._saved = nil -- snapshot of the user's values taken when entering narrow

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function try_set(scope, key, value)
  -- Individual options can be missing on older Neovim (e.g. splitkeep);
  -- never let one bad option abort the rest.
  pcall(function()
    scope[key] = value
  end)
end

local function snapshot()
  local s = { win = {}, global = {}, diag = nil, blame_was_on = false }
  for k in pairs(WIN_NARROW) do
    s.win[k] = vim.go[k]
  end
  for k in pairs(GLOBAL_NARROW) do
    s.global[k] = vim.go[k]
  end
  s.diag = vim.diagnostic.config()
  return s
end

local function each_normal_window(fn)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == '' then
      local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
      if ok and vim.api.nvim_buf_is_valid(buf) and not SKIP_BUFTYPE[vim.bo[buf].buftype] then
        fn(win)
      end
    end
  end
end

local function apply_win_opts(values)
  each_normal_window(function(win)
    for k, v in pairs(values) do
      try_set(vim.wo[win], k, v)
    end
  end)
end

-- Gitsigns: read the real state so we never invert it by accident, and only
-- re-enable blame later if *we* were the one who turned it off.
local function blame_enabled()
  local ok, cfg = pcall(require, 'gitsigns.config')
  if ok and cfg.config then
    return cfg.config.current_line_blame == true
  end
  return nil
end

local function set_blame(want)
  local gs = package.loaded.gitsigns
  if not (gs and gs.toggle_current_line_blame) then
    return false
  end
  local current = blame_enabled()
  if current == nil or current == want then
    return false
  end
  gs.toggle_current_line_blame()
  return true
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

function M.is_narrow()
  if vim.g.narrow_force == true then
    return true
  end
  if vim.g.narrow_force == false then
    return false
  end
  return vim.o.columns < M.threshold
end

local function enter_narrow()
  M._saved = snapshot()

  -- Globals (also become the defaults for new windows).
  for k, v in pairs(WIN_NARROW) do
    try_set(vim.go, k, v)
  end
  for k, v in pairs(GLOBAL_NARROW) do
    try_set(vim.go, k, v)
  end

  -- Diagnostics: signs + float only, no virtual text.
  local float = M._saved.diag.float
  float = type(float) == 'table' and float or {}
  vim.diagnostic.config({
    virtual_text = false,
    float = vim.tbl_extend('force', float, {
      border = float.border or 'single',
      max_width = 50,
      max_height = 10,
      wrap = true,
    }),
  })

  -- Gitsigns eol blame wraps into mush on ~50 cols.
  M._saved.blame_was_on = blame_enabled() == true
  if M._saved.blame_was_on then
    set_blame(false)
  end
end

local function leave_narrow()
  local s = M._saved
  M._saved = nil
  if not s then
    return
  end

  for k, v in pairs(s.win) do
    try_set(vim.go, k, v)
  end
  for k, v in pairs(s.global) do
    try_set(vim.go, k, v)
  end
  -- Existing windows were narrowed individually; put them back too.
  apply_win_opts(s.win)

  vim.diagnostic.config(s.diag)

  if s.blame_was_on then
    set_blame(true)
  end
end

function M.apply()
  local narrow = M.is_narrow()

  if narrow ~= M._state then
    local first = M._state == nil
    M._state = narrow
    if narrow then
      enter_narrow()
    elseif not first then
      leave_narrow()
    end

    -- Lualine caches `cond` results; force re-evaluation on change.
    pcall(function()
      require('lualine').refresh()
    end)
  end

  -- Windows opened while narrow (or before the module ran) may not have
  -- picked up the window-local values; cheap to re-assert on every event.
  if narrow then
    apply_win_opts(WIN_NARROW)
  end
end

-- Smart split: :vsplit on a 50-col screen gives two unusable 25-col panes,
-- so pick the orientation by width.
function M.smart_split()
  if M.is_narrow() then
    vim.cmd('split')
  else
    vim.cmd('vsplit')
  end
end

function M.setup(opts)
  opts = opts or {}
  if opts.threshold then
    M.threshold = opts.threshold
  end

  local function cmd(name, fn, desc)
    vim.api.nvim_create_user_command(name, function()
      fn()
      M.apply()
    end, { desc = desc })
  end
  cmd('NarrowOn', function()
    vim.g.narrow_force = true
  end, 'Force narrow-screen UI')
  cmd('NarrowOff', function()
    vim.g.narrow_force = false
  end, 'Force wide-screen UI')
  cmd('NarrowAuto', function()
    vim.g.narrow_force = nil
  end, 'Follow window width for narrow UI')
  cmd('NarrowToggle', function()
    vim.g.narrow_force = not M.is_narrow()
  end, 'Toggle narrow-screen UI')

  local grp = vim.api.nvim_create_augroup('NarrowScreen', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResized', 'VimResume', 'WinNew', 'BufWinEnter' }, {
    group = grp,
    callback = function()
      -- Defer so vim.o.columns has settled (tmux / phone rotate).
      vim.schedule(M.apply)
    end,
  })

  -- If this module was loaded lazily after VimEnter, that event won't fire.
  if vim.v.vim_did_enter == 1 then
    vim.schedule(M.apply)
  end
end

M.setup()

return M
