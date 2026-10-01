-- Responsive UI for narrow screens.
--
-- Narrow mode:
--   * compact window chrome
--   * soft wrapping / breakindent
--   * global statusline
--   * minimal tabline
--   * diagnostic virtual-text disabled
--   * gitsigns current-line blame disabled
--   * lualine refreshed
--   * editor-relative floating windows lose outer margins
--
-- Wide mode restores the exact values that existed before narrow mode.
--
-- Manual:
--   :NarrowOn      force narrow
--   :NarrowOff     force wide
--   :NarrowToggle toggle forced state
--   :NarrowAuto    follow vim.o.columns
--
-- Usage:
--   require("narrow")
--   require("narrow").setup({ threshold = 55 })
--   vim.keymap.set("n", "<leader>s", require("narrow").smart_split)

local M = {}

M.threshold = 55

------------------------------------------------------------------------
-- Configuration
------------------------------------------------------------------------

local WIN_NARROW = {
  number = true,
  relativenumber = false,
  numberwidth = 2,
  foldcolumn = "0",
  signcolumn = "yes:1",

  wrap = true,
  linebreak = true,
  breakindent = true,
  showbreak = "↪ ",
}

local GLOBAL_NARROW = {
  sidescroll = 1,
  sidescrolloff = 0,
  scrolloff = 1,

  laststatus = 3,
  showtabline = 1,

  cmdheight = 1,

  winminwidth = 10,
  winwidth = 10,
  splitkeep = "screen",
}

local SKIP_BUFTYPE = {
  prompt = true,
  nofile = true,
  terminal = true,
}

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

M._state = nil
M._saved = nil

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function try_set(scope, key, value)
  pcall(function()
    scope[key] = value
  end)
end

local function is_normal_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local config = vim.api.nvim_win_get_config(win)

  if config.relative ~= "" then
    return false
  end

  local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Let Neo-tree own its wrap setting (W toggle in neo-tree.lua).
  local ok_ft, ft = pcall(function()
    return vim.bo[buf].filetype
  end)
  if ok_ft and (ft == "neo-tree" or ft == "neo-tree-popup") then
    return false
  end

  return not SKIP_BUFTYPE[vim.bo[buf].buftype]
end

local function is_float(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local ok, config = pcall(
    vim.api.nvim_win_get_config,
    win
  )

  if not ok then
    return false
  end

  return config.relative ~= ""
end

local function each_normal_window(fn)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_normal_window(win) then
      fn(win)
    end
  end
end

local function each_float(fn)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_float(win) then
      fn(win)
    end
  end
end

local function get_win_values(win, options)
  local values = {}

  for key in pairs(options) do
    local ok, value = pcall(function()
      return vim.wo[win][key]
    end)

    if ok then
      values[key] = value
    end
  end

  return values
end

local function set_win_values(win, values)
  if not is_normal_window(win) then
    return
  end

  for key, value in pairs(values) do
    try_set(vim.wo[win], key, value)
  end
end

local function apply_win_opts(values)
  each_normal_window(function(win)
    set_win_values(win, values)
  end)
end

------------------------------------------------------------------------
-- Floating windows
------------------------------------------------------------------------

local function get_float_config(win)
  if not is_float(win) then
    return nil
  end

  local ok, config = pcall(
    vim.api.nvim_win_get_config,
    win
  )

  if not ok then
    return nil
  end

  return vim.deepcopy(config)
end

local function save_float_config(win)
  if not M._saved or not is_float(win) then
    return
  end

  -- Save each float only once.
  --
  -- This is important for floats created after entering narrow mode:
  -- their first-seen configuration is their "wide/intended" layout.
  if M._saved.floats[win] == nil then
    local config = get_float_config(win)

    if config then
      M._saved.floats[win] = config
    end
  end
end

local function narrow_float_config(win)
  local config = get_float_config(win)

  if not config then
    return
  end

  save_float_config(win)

  local columns = vim.o.columns
  local rows = vim.o.lines

  ----------------------------------------------------------------------
  -- Editor-relative floats
  --
  -- These are the normal popup windows that are centered/positioned
  -- relative to the editor. On narrow screens make them edge-to-edge
  -- instead of leaving the usual outer margin.
  ----------------------------------------------------------------------

  if config.relative == "editor" then
    local border = config.border

    -- Width/height describe the content area. Leave enough room for
    -- borders when a float actually has one.
    local border_x = border and 2 or 0
    local border_y = border and 2 or 0

    local width = math.max(
      1,
      columns - border_x
    )

    local height = math.max(
      1,
      rows - vim.o.cmdheight - border_y
    )

    local new_config = {
      relative = "editor",
      row = 0,
      col = 0,
      width = width,
      height = height,
    }

    pcall(
      vim.api.nvim_win_set_config,
      win,
      new_config
    )

    return
  end

  ----------------------------------------------------------------------
  -- Window/cursor-relative floats
  --
  -- Preserve their anchor/relative positioning. We only make sure their
  -- dimensions cannot exceed the narrow screen.
  ----------------------------------------------------------------------

  local width = math.min(
    config.width or columns,
    math.max(1, columns - 1)
  )

  local height = math.min(
    config.height or rows,
    math.max(1, rows - vim.o.cmdheight - 1)
  )

  if width ~= config.width
      or height ~= config.height then
    pcall(
      vim.api.nvim_win_set_config,
      win,
      {
        width = width,
        height = height,
      }
    )
  end
end

local function apply_narrow_floats()
  if not M._saved then
    return
  end

  each_float(function(win)
    narrow_float_config(win)
  end)
end

local function restore_floats(saved)
  for win, config in pairs(saved.floats or {}) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(
        vim.api.nvim_win_set_config,
        win,
        config
      )
    end
  end
end

------------------------------------------------------------------------
-- Snapshot / restore
------------------------------------------------------------------------

local function snapshot()
  local state = {
    windows = {},
    floats = {},
    global = {},
    diag = vim.diagnostic.config(),
    blame_was_on = false,
  }

  -- Save global options exactly as they were.
  for key in pairs(GLOBAL_NARROW) do
    local ok, value = pcall(function()
      return vim.go[key]
    end)

    if ok then
      state.global[key] = value
    end
  end

  -- Save each normal window independently.
  each_normal_window(function(win)
    state.windows[win] =
      get_win_values(win, WIN_NARROW)
  end)

  -- Save existing floats independently.
  each_float(function(win)
    local config = get_float_config(win)

    if config then
      state.floats[win] = config
    end
  end)

  return state
end

local function restore_windows(saved)
  for win, values in pairs(saved.windows or {}) do
    if vim.api.nvim_win_is_valid(win) then
      set_win_values(win, values)
    end
  end
end

------------------------------------------------------------------------
-- Gitsigns
------------------------------------------------------------------------

local function blame_enabled()
  local ok, config = pcall(
    require,
    "gitsigns.config"
  )

  if ok and config.config then
    return config.config.current_line_blame == true
  end

  return nil
end

local function set_blame(want)
  local gs = package.loaded.gitsigns

  if not gs or not gs.toggle_current_line_blame then
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
-- Narrow state
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
  -- Snapshot BEFORE changing anything.
  M._saved = snapshot()

  -- Set global defaults first. This also gives newly-created windows
  -- sensible narrow defaults.
  for key, value in pairs(GLOBAL_NARROW) do
    try_set(vim.go, key, value)
  end

  for key, value in pairs(WIN_NARROW) do
    try_set(vim.go, key, value)
  end

  -- Existing windows need their local values changed explicitly.
  apply_win_opts(WIN_NARROW)

  -- Existing floating windows lose their outer margin.
  apply_narrow_floats()

  -- Diagnostics: keep signs + floating diagnostics, remove virtual text.
  local float = M._saved.diag.float

  if type(float) ~= "table" then
    float = {}
  end

  vim.diagnostic.config({
    virtual_text = false,
    float = vim.tbl_extend(
      "force",
      float,
      {
        border = float.border or "single",
        max_width = 50,
        max_height = 10,
        wrap = true,
      }
    ),
  })

  -- Only disable blame if it was actually enabled before entering
  -- narrow mode.
  M._saved.blame_was_on =
    blame_enabled() == true

  if M._saved.blame_was_on then
    set_blame(false)
  end
end

local function leave_narrow()
  local saved = M._saved

  M._saved = nil

  if not saved then
    return
  end

  -- Restore globals exactly.
  for key, value in pairs(saved.global) do
    try_set(vim.go, key, value)
  end

  -- Restore diagnostics exactly.
  if saved.diag then
    pcall(
      vim.diagnostic.config,
      saved.diag
    )
  end

  -- Restore each normal window to its own state.
  restore_windows(saved)

  -- Restore floating-window geometry.
  restore_floats(saved)

  -- Re-enable blame only when we were the ones who disabled it.
  if saved.blame_was_on then
    set_blame(true)
  end
end

------------------------------------------------------------------------
-- Apply
------------------------------------------------------------------------

local function refresh_lualine()
  pcall(function()
    require("lualine").refresh({
      place = {
        "statusline",
        "tabline",
        "winbar",
      },
    })
  end)
end

function M.apply()
  local narrow = M.is_narrow()

  ----------------------------------------------------------------------
  -- State transition
  ----------------------------------------------------------------------

  if narrow ~= M._state then
    local initial = M._state == nil

    M._state = narrow

    if narrow then
      enter_narrow()
    elseif not initial then
      leave_narrow()
    end

    refresh_lualine()

    return
  end

  ----------------------------------------------------------------------
  -- Already narrow
  --
  -- Windows/floats may have been created since the last apply().
  ----------------------------------------------------------------------

  if narrow then
    apply_win_opts(WIN_NARROW)
    apply_narrow_floats()
  end
end

------------------------------------------------------------------------
-- Smart split
------------------------------------------------------------------------

function M.smart_split()
  if M.is_narrow() then
    vim.cmd("split")
  else
    vim.cmd("vsplit")
  end
end

------------------------------------------------------------------------
-- Introspection API
------------------------------------------------------------------------

function M.get_config()
  return {
    threshold = M.threshold,
    win = vim.deepcopy(WIN_NARROW),
    global = vim.deepcopy(GLOBAL_NARROW),
  }
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function create_command(name, fn, desc)
  vim.api.nvim_create_user_command(
    name,
    function()
      fn()
      M.apply()
    end,
    {
      desc = desc,
    }
  )
end

function M.setup(opts)
  opts = opts or {}

  if opts.threshold ~= nil then
    assert(
      type(opts.threshold) == "number"
        and opts.threshold > 0,
      "narrow threshold must be a positive number"
    )

    M.threshold = opts.threshold
  end

  create_command(
    "NarrowOn",
    function()
      vim.g.narrow_force = true
    end,
    "Force narrow-screen UI"
  )

  create_command(
    "NarrowOff",
    function()
      vim.g.narrow_force = false
    end,
    "Force wide-screen UI"
  )

  create_command(
    "NarrowAuto",
    function()
      vim.g.narrow_force = nil
    end,
    "Follow window width automatically"
  )

  create_command(
    "NarrowToggle",
    function()
      vim.g.narrow_force = not M.is_narrow()
    end,
    "Toggle narrow-screen UI"
  )

  local group =
    vim.api.nvim_create_augroup(
      "NarrowScreen",
      { clear = true }
    )

  vim.api.nvim_create_autocmd(
    {
      "VimEnter",
      "VimResized",
      "VimResume",
      "WinNew",
      "WinClosed",
      "WinEnter",
      "BufWinEnter",
    },
    {
      group = group,

      callback = function()
        vim.schedule(function()
          M.apply()
        end)
      end,
    }
  )

  -- Handles lazy-loaded usage where VimEnter already happened.
  if vim.v.vim_did_enter == 1 then
    vim.schedule(M.apply)
  end
end

M.setup()

return M
