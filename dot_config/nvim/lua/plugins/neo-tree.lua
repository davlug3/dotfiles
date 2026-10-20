-- Sizes for the *unexpanded* Neo-tree window.
--
-- Neo-tree's container truncates every row to `window.width` *before* writing
-- the buffer (sources/common/container.lua -> merge_content calls
-- utils.truncate_by_cell). The characters are gone by the time Vim sees them,
-- so Vim's `wrap` can never re-flow a long filename. There is no option to
-- disable that truncation on the v3.x branch, so the caps below are the only
-- lever. Names longer than the cap are still cut; press `e` to expand.
--
-- Neo-tree measures a sidebar in columns and a top/bottom tree in rows: the
-- window options read `window.width` for left/right and `window.height` for
-- top/bottom (ui/renderer.lua acquire_window). So each axis carries its own
-- pair of caps.
local CAPS = {
  width = { narrow = 30, wide = 50 },
  height = { narrow = 10, wide = 18 },
}

-- Positions Neo-tree can be driven to by :NeotreePos. float/current are left
-- out on purpose: they are not splits, and auto-close ignores them.
local POSITIONS = { left = true, right = true, top = true, bottom = true }

local function axis_for(pos)
  return (pos == "top" or pos == "bottom") and "height" or "width"
end

-- The axis the other end of a split is flipped to by :NeotreePos toggle.
local FLIPPED_POSITION = {
  left = "top",
  right = "bottom",
  top = "left",
  bottom = "right",
}

-- Persisted manual sizes (set by dragging / :vertical resize / :resize).
-- Keyed by axis and by mode so a wide-screen drag does not leak onto a narrow
-- terminal. Stored outside chezmoi: this is runtime state, not a dotfile.
local MANUAL_SIZE = {
  width = { narrow = nil, wide = nil },
  height = { narrow = nil, wide = nil },
}

local function is_narrow()
  local ok, narrow = pcall(require, "config.narrow")
  if ok and narrow.is_narrow then
    return narrow.is_narrow()
  end
  return vim.o.columns < 55
end

local function current_mode()
  return is_narrow() and "narrow" or "wide"
end

local function state_file()
  return vim.fn.stdpath("state") .. "/neo-tree-size.json"
end

-- Pre-axis filename. Read once on migration so an existing drag survives the
-- switch to per-axis storage.
local function legacy_state_file()
  return vim.fn.stdpath("state") .. "/neo-tree-width.json"
end

local function position_file()
  return vim.fn.stdpath("state") .. "/neo-tree-position.json"
end

local function read_json(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)

  if not ok then
    return nil
  end

  return data
end

local function write_json(path, payload)
  local ok, encoded = pcall(vim.json.encode, payload)
  if not ok then
    return
  end

  pcall(function()
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile(vim.split(encoded, "\n"), path)
  end)
end

local function load_position()
  local data = read_json(position_file())
  if type(data) == "string" and POSITIONS[data] then
    return data
  end
  return "left"
end

local function save_position(pos)
  write_json(position_file(), pos)
end

-- The live position. Neo-tree reads it through the `position` function in
-- opts.window below; :NeotreePos changes it.
local POSITION = load_position()

local function position()
  return POSITION
end

local function load_manual_sizes()
  local data = read_json(state_file())

  if data == nil then
    -- Nothing at the new path: fall back to the width-only file, which held
    -- plain numbers under narrow/wide.
    data = read_json(legacy_state_file())
  end

  if type(data) ~= "table" then
    return
  end

  -- The old file stored plain numbers under narrow/wide; treat those as
  -- widths so an existing drag is not lost.
  if type(data.narrow) == "number" or type(data.wide) == "number" then
    data = { width = data }
  end

  for _, axis in ipairs({ "width", "height" }) do
    local bucket = data[axis]

    if type(bucket) == "table" then
      for _, mode in ipairs({ "narrow", "wide" }) do
        local value = bucket[mode]
        -- 10 was the old width-only floor; the height axis needs less room
        -- to be useful, so both axes share the lower bound here.
        if type(value) == "number" and value >= 5 then
          MANUAL_SIZE[axis][mode] = math.floor(value)
        end
      end
    end
  end
end

local function save_manual_sizes()
  local path = state_file()

  if not MANUAL_SIZE.width.narrow
      and not MANUAL_SIZE.width.wide
      and not MANUAL_SIZE.height.narrow
      and not MANUAL_SIZE.height.wide then
    pcall(vim.fn.delete, path)
    return
  end

  -- Only axes that actually hold a value are written. vim.json.encode turns
  -- an empty Lua table into `[]`, not `{}`, so an always-present but empty
  -- bucket would come back as an array rather than an object on load.
  local payload = {}
  for _, axis in ipairs({ "width", "height" }) do
    if MANUAL_SIZE[axis].narrow or MANUAL_SIZE[axis].wide then
      payload[axis] = {
        narrow = MANUAL_SIZE[axis].narrow,
        wide = MANUAL_SIZE[axis].wide,
      }
    end
  end

  write_json(path, payload)
end

-- A manual size must never be able to crush the file window.
local function clamp_size(size, axis)
  if axis == "height" then
    -- Leave the file window something to live in, plus cmdline/status lines.
    local max_height = math.max(5, vim.o.lines - 5)
    return math.max(5, math.min(math.floor(size), max_height))
  end

  local max_width = math.max(20, vim.o.columns - 20)
  return math.max(10, math.min(math.floor(size), max_width))
end

local function desired_size(axis)
  local manual = MANUAL_SIZE[axis][current_mode()]
  if manual then
    return clamp_size(manual, axis)
  end
  return CAPS[axis][current_mode()]
end

load_manual_sizes()

-- Windows whose filetype is Neo-tree's tree buffer.
local function neo_tree_window_ids()
  local result = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok
        and vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].filetype == "neo-tree" then
      result[#result + 1] = win
    end
  end
  return result
end

-- Shortcut hint above the tree.
--
-- Only keys that are actually worth advertising:
--   e: expands the window so long filenames are not truncated
--   ?: Neo-tree's own keymap help
--   i: file details
--
-- `W` (wrap) is deliberately not advertised: Neo-tree drops characters at
-- render time, so wrap cannot re-flow a truncated filename. It still exists
-- for the long lines printed by `i`.
local function winbar_text()
  return " e:expand  ?:help  i:details  P:position "
end

local function apply_winbar()
  for _, win in ipairs(neo_tree_window_ids()) do
    pcall(function()
      vim.wo[win].winbar = winbar_text()
    end)
  end
end

-- Neo-tree forces `nowrap` on buffer_enter / window_after_open, so the
-- toggled wrap state has to be re-applied after its own setup runs.
local function apply_wrap_state()
  if not vim.g.neotree_wrap_on then
    return
  end

  for _, win in ipairs(neo_tree_window_ids()) do
    pcall(function()
      vim.wo[win].wrap = true
      vim.wo[win].linebreak = true
      vim.wo[win].breakindent = true
      vim.wo[win].showbreak = "↪ "
    end)
  end
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      filesystem = {
        follow_current_file = {
            enabled = true,
            leave_dirs_open = false
        }
      },
      window = {
        -- `width`/`height`/`position` accept a function
        -- (utils.resolve_config_option), so the unexpanded tree follows the
        -- screen and the position follows :NeotreePos. See CAPS above for why
        -- these are caps rather than wrap settings.
        -- A size you set by hand wins over the caps and persists.
        --
        -- Neo-tree reads `height` only for top/bottom positions and `width`
        -- only for left/right, so each function is simply ignored when it does
        -- not apply to the live position.
        width = function()
          return desired_size("width")
        end,
        height = function()
          return desired_size("height")
        end,
        position = function()
          return position()
        end,
        auto_expand_width = false,
        mappings = {
          -- Neo-tree-only wrap toggle (applies to the Neo-tree window).
          ["W"] = { "toggle_wrap", desc = "toggle wrap" },
          -- `/` back to native Vim search; Neo-tree fuzzy finder moves to `g/`.
          ["/"] = "none",
          ["g/"] = "fuzzy_finder",
          -- Toggle between sidebar (left/right) and horizontal (top/bottom).
          ["P"] = { "neotree_pos_toggle", desc = "Toggle position" },
        },
      },
      default_component_configs = {
        container = {
          enable_character_fade = false,
        },
      },
      commands = {
        toggle_wrap = function()
          vim.g.neotree_wrap_on = not vim.g.neotree_wrap_on

          for _, win in ipairs(neo_tree_window_ids()) do
            pcall(function()
              vim.wo[win].wrap = vim.g.neotree_wrap_on
              vim.wo[win].linebreak = vim.g.neotree_wrap_on
              vim.wo[win].breakindent = vim.g.neotree_wrap_on
              vim.wo[win].showbreak = vim.g.neotree_wrap_on and "↪ " or ""
            end)
          end

          -- Keep the hint in step with the new state.
          apply_winbar()

          print("Neo-tree wrap " .. (vim.g.neotree_wrap_on and "ON" or "OFF"))
        end,
        neotree_pos_toggle = function()
          vim.cmd("NeotreePos toggle")
        end,
      },
      -- Neo-tree forces `nowrap` on buffer_enter / window_after_open, so the
      -- toggled state has to be re-applied after its own setup runs. The
      -- winbar hint is rebuilt from live state each time.
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.schedule(function()
              apply_winbar()
              apply_wrap_state()
            end)
          end,
        },
        {
          event = "neo_tree_window_before_close",
          handler = function()
            -- Record any manual size before the window disappears.
            local ok, manager = pcall(require, "neo-tree.sources.manager")
            if not ok or type(manager.get_state) ~= "function" then
              return
            end
            local state = manager.get_state("filesystem")
            if type(state) == "table"
                and state.window ~= nil
                and state.window.auto_expand_width == true then
              return
            end

            local winid = state and state.winid
            if not winid or not vim.api.nvim_win_is_valid(winid) then
              return
            end

            -- Take the axis from the window that is closing rather than from
            -- POSITION: Neo-tree has not re-resolved the configured position
            -- for this window, so POSITION may already name the next axis.
            local pos
            if type(state.bufnr) == "number" and vim.api.nvim_buf_is_valid(state.bufnr) then
              pos = vim.b[state.bufnr].neo_tree_position
            end
            local axis = axis_for(pos or POSITION)

            local size
            if axis == "height" then
              size = vim.api.nvim_win_get_height(winid)
            else
              size = vim.api.nvim_win_get_width(winid)
            end

            -- desired_size() already folds in the stored manual value (and
            -- clamping), so matching it means there is nothing to record.
            if size == desired_size(axis) then
              return
            end

            MANUAL_SIZE[axis][current_mode()] = size
            save_manual_sizes()
          end,
        },
        {
          event = "neo_tree_window_after_open",
          handler = function()
            vim.schedule(function()
              apply_winbar()
              apply_wrap_state()
            end)
          end,
        },
      },
    },
    config = function(_, opts)
      vim.g.neotree_wrap_on = vim.g.neotree_wrap_on or false
      require("neo-tree").setup(opts)

      -- True while we are the ones changing a window's size, so our own
      -- resize is not mistaken for a manual drag.
      local applying = false

      local function neo_tree_windows()
        local result = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
          if ok
              and vim.api.nvim_buf_is_valid(buf)
              and vim.bo[buf].filetype == "neo-tree" then
            result[#result + 1] = win
          end
        end
        return result
      end

      -- `e` (toggle_auto_expand_width) is a temporary action, not a manual
      -- choice, so it must not be persisted. Ask the filesystem state.
      local function auto_expand_active()
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if not ok or type(manager.get_state) ~= "function" then
          return false
        end
        local state = manager.get_state("filesystem")
        return type(state) == "table"
          and state.window ~= nil
          and state.window.auto_expand_width == true
      end

      -- The position a live Neo-tree window actually sits at.
      --
      -- Reading the window rather than the configured position matters:
      -- :NeotreePos changes POSITION, but Neo-tree caches the resolved
      -- position on its source state (renderer.lua acquire_window) and only
      -- re-resolves when a tree is opened afresh.
      local function live_position()
        for _, win in ipairs(neo_tree_windows()) do
          local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
          if ok and vim.api.nvim_buf_is_valid(buf) then
            local pos = vim.b[buf].neo_tree_position
            if POSITIONS[pos] then
              return pos
            end
          end
        end
        return position()
      end

      -- The axis the live tree occupies: "height" for top/bottom, else "width".
      local function live_axis()
        return axis_for(live_position())
      end

      -- Read a window's size along the given axis.
      local function window_size(win, axis)
        if axis == "height" then
          return vim.api.nvim_win_get_height(win)
        end
        return vim.api.nvim_win_get_width(win)
      end

      -- Resize a window along the given axis.
      local function set_window_size(win, size, axis)
        if axis == "height" then
          vim.cmd("resize " .. size)
        else
          vim.cmd("vertical resize " .. size)
        end
      end

      --------------------------------------------------------------------
      -- Terminal resized: re-apply the active size.
      --
      -- Neovim equalises windows itself on VimResized, so a tree that no
      -- longer fits keeps whatever share equalisation handed it. A manual
      -- size wins over the caps; `e`-expanded trees are left alone.
      --------------------------------------------------------------------
      -- One group for every handler below. Creating it once matters: calling
      -- create_augroup with clear = true again would wipe the autocmds
      -- registered before it.
      local size_group = vim.api.nvim_create_augroup("NeoTreeResponsiveSize", {
        clear = true,
      })

      vim.api.nvim_create_autocmd("VimResized", {
        group = size_group,
        callback = function()
          vim.schedule(function()
            if auto_expand_active() then
              return
            end

            local axis = live_axis()
            local size = desired_size(axis)

            -- Neovim re-equalises windows after a VimResized and hands the
            -- tree whatever share fills the screen, which discards the size
            -- we just set. Suppress it for the duration of our own resize.
            local equalalways = vim.o.equalalways
            vim.o.equalalways = false

            applying = true
            for _, win in ipairs(neo_tree_windows()) do
              if window_size(win, axis) ~= size then
                pcall(vim.api.nvim_win_call, win, function()
                  set_window_size(win, size, axis)
                end)
              end
            end
            applying = false

            vim.o.equalalways = equalalways
          end)
        end,
      })

      --------------------------------------------------------------------
      -- Window resized: record a manual size.
      --
      -- WinResized also fires for our own VimResized corrections and for
      -- `:vertical resize` / `:resize`, so those are filtered out rather than
      -- persisted.
      --------------------------------------------------------------------
      vim.api.nvim_create_autocmd("WinResized", {
        group = size_group,
        callback = function()
          if applying then
            return
          end

          local win = vim.api.nvim_get_current_win()
          local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
          if not ok
              or not vim.api.nvim_buf_is_valid(buf)
              or vim.bo[buf].filetype ~= "neo-tree" then
            return
          end

          if auto_expand_active() then
            return
          end

          local axis = live_axis()
          local size = window_size(win, axis)
          local mode = current_mode()

          -- Ignore changes we caused (e.g. equalisation after a split) so a
          -- drag is the only thing that writes the file.
          if size == (MANUAL_SIZE[axis][mode] or -1)
              or size == desired_size(axis) then
            return
          end

          MANUAL_SIZE[axis][mode] = size
          save_manual_sizes()
        end,
      })

      --------------------------------------------------------------------
      -- Capture the live size when the tree closes and when nvim exits.
      --
      -- WinResized is the precise signal for a drag, but it only fires with a
      -- real UI attached. These two hooks cover the headless/edge cases and
      -- mean a resize still survives even if WinResized is missed.
      --------------------------------------------------------------------
      local function capture_manual_size()
        if auto_expand_active() then
          return
        end

        local axis = live_axis()
        local size
        for _, win in ipairs(neo_tree_windows()) do
          size = window_size(win, axis)
          break
        end

        if not size then
          return
        end

        local mode = current_mode()

        if size == desired_size(axis) then
          return
        end

        MANUAL_SIZE[axis][mode] = size
        save_manual_sizes()
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = size_group,
        callback = capture_manual_size,
      })

      --------------------------------------------------------------------
      -- Narrow screens: close the tree once a file is opened.
      --
      -- On a narrow terminal a split eats a large share of the screen --
      -- a sidebar takes columns, a top/bottom tree takes rows -- so once a
      -- file has been picked there is no benefit in keeping it around;
      -- `<leader>e` brings it back. Only real splits (position left/right/
      -- top/bottom) are closed; a floating tree, or one that has taken over
      -- the current window, is left alone.
      --------------------------------------------------------------------
      local function has_split_tree()
        for _, win in ipairs(neo_tree_windows()) do
          local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
          if ok and vim.api.nvim_buf_is_valid(buf) then
            if POSITIONS[vim.b[buf].neo_tree_position] then
              return true
            end
          end
        end
        return false
      end

      local narrow_group = vim.api.nvim_create_augroup("NeoTreeNarrowAutoClose", {
        clear = true,
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        group = narrow_group,
        callback = function(args)
          -- Never react to Neo-tree's own buffers.
          local ft = vim.bo[args.buf].filetype
          if ft == "neo-tree" or ft == "neo-tree-popup" then
            return
          end

          -- Ignore special buffers (scratch, terminal, help, quickfix, ...).
          if vim.bo[args.buf].buftype ~= "" then
            return
          end

          -- Ignore unnamed buffers: nothing was really "opened".
          if vim.api.nvim_buf_get_name(args.buf) == "" then
            return
          end

          local ok_narrow, narrow = pcall(require, "config.narrow")
          if not ok_narrow or not narrow.is_narrow() then
            return
          end

          if not has_split_tree() then
            return
          end

          -- Schedule so this runs after Neo-tree's own BufEnter handling
          -- (follow_current_file) has finished.
          vim.schedule(function()
            local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
            if not ok_mgr or type(manager.close_all) ~= "function" then
              return
            end
            for _, pos in ipairs({ "left", "right", "top", "bottom" }) do
              pcall(manager.close_all, pos)
            end
          end)
        end,
      })

      --------------------------------------------------------------------
      -- Reset back to the automatic caps.
      --------------------------------------------------------------------
      vim.api.nvim_create_user_command("NeotreeWidthReset", function()
        MANUAL_SIZE.width.narrow = nil
        MANUAL_SIZE.width.wide = nil
        MANUAL_SIZE.height.narrow = nil
        MANUAL_SIZE.height.wide = nil
        save_manual_sizes()

        local axis = live_axis()
        local size = desired_size(axis)

        local equalalways = vim.o.equalalways
        vim.o.equalalways = false

        applying = true
        for _, win in ipairs(neo_tree_windows()) do
          pcall(vim.api.nvim_win_call, win, function()
            set_window_size(win, size, axis)
          end)
        end
        applying = false

        vim.o.equalalways = equalalways

        print(
          "Neo-tree size reset ("
            .. CAPS.width.narrow
            .. "/"
            .. CAPS.width.wide
            .. " cols, "
            .. CAPS.height.narrow
            .. "/"
            .. CAPS.height.wide
            .. " rows)"
        )
      end, {
        desc = "Forget manually set Neo-tree size and use automatic caps",
      })

      --------------------------------------------------------------------
      -- :NeotreePos [left|right|top|bottom|toggle]
      --
      -- Neo-tree caches the resolved position on each source state
      -- (renderer.lua acquire_window: `state.current_position = state.
      -- current_position or default_position`), so a new position only takes
      -- effect for a tree opened afterwards. The command therefore closes
      -- first and reopens if the tree was on screen.
      --------------------------------------------------------------------
      -- Neither `manager.close_all` nor the `:Neotree show` command path
      -- clears that cache -- only manager.show/focus do -- so it has to be
      -- cleared by hand or the reopen would silently reuse the old axis.
      local function clear_cached_positions()
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if not ok or type(manager._get_all_states) ~= "function" then
          return
        end
        for _, state in ipairs(manager._get_all_states()) do
          state.current_position = nil
        end
      end

      local function apply_position(target)
        local was_open = #neo_tree_windows() > 0

        if was_open then
          local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
          if ok_mgr and type(manager.close_all) == "function" then
            pcall(manager.close_all)
          end
        end

        POSITION = target
        save_position(POSITION)
        clear_cached_positions()

        if was_open then
          -- Deferred so the close above has fully unwound before Neo-tree
          -- resolves the new position.
          vim.schedule(function()
            pcall(vim.cmd, "Neotree show")
          end)
        end

        print("Neo-tree position: " .. POSITION)
      end

      vim.api.nvim_create_user_command("NeotreePos", function(args)
        local arg = args.args

        if arg == "" or arg == "toggle" then
          apply_position(FLIPPED_POSITION[POSITION] or "top")
          return
        end

        if not POSITIONS[arg] then
          vim.notify(
            "NeotreePos: expected left, right, top, bottom or toggle",
            vim.log.levels.ERROR
          )
          return
        end

        apply_position(arg)
      end, {
        nargs = "?",
        desc = "Set Neo-tree position (left/right/top/bottom), or flip the axis",
        complete = function(arg_lead)
          local choices = { "left", "right", "top", "bottom", "toggle" }
          return vim.tbl_filter(function(choice)
            return choice:find("^" .. vim.pesc(arg_lead)) ~= nil
          end, choices)
        end,
      })
    end,
  },
  {
    "Crysthamus/nvim-file-operations",
    -- branch = "compat" -- if you are on Neovim <= 0.10
    dependencies = {
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("nvim-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
