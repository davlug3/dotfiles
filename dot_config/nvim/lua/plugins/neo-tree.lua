-- Widths for the *unexpanded* Neo-tree window.
--
-- Neo-tree's container truncates every row to `window.width` *before* writing
-- the buffer (sources/common/container.lua -> merge_content calls
-- utils.truncate_by_cell). The characters are gone by the time Vim sees them,
-- so Vim's `wrap` can never re-flow a long filename. There is no option to
-- disable that truncation on the v3.x branch, so the caps below are the only
-- lever. Names longer than the cap are still cut; press `e` to expand.
local NARROW_WIDTH = 30
local WIDE_WIDTH = 50

-- Persisted manual widths (set by dragging / :vertical resize / <C-w>>).
-- Keyed by mode so a wide-screen drag does not leak onto a narrow terminal.
-- Stored outside chezmoi: this is runtime state, not a dotfile.
local MANUAL_WIDTH = { narrow = nil, wide = nil }

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
  return vim.fn.stdpath("state") .. "/neo-tree-width.json"
end

local function load_manual_widths()
  local path = state_file()
  if vim.fn.filereadable(path) ~= 1 then
    return
  end

  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)

  if not ok or type(data) ~= "table" then
    return
  end

  for _, mode in ipairs({ "narrow", "wide" }) do
    local value = data[mode]
    if type(value) == "number" and value >= 10 then
      MANUAL_WIDTH[mode] = math.floor(value)
    end
  end
end

local function save_manual_widths()
  if not MANUAL_WIDTH.narrow and not MANUAL_WIDTH.wide then
    pcall(vim.fn.delete, state_file())
    return
  end

  local ok, encoded = pcall(vim.json.encode, MANUAL_WIDTH)
  if not ok then
    return
  end

  pcall(function()
    vim.fn.mkdir(vim.fn.fnamemodify(state_file(), ":h"), "p")
    vim.fn.writefile(vim.split(encoded, "\n"), state_file())
  end)
end

-- A manual width must never be able to crush the file window.
local function clamp_width(width)
  local max_width = math.max(20, vim.o.columns - 20)
  return math.max(10, math.min(math.floor(width), max_width))
end

local function desired_width()
  local manual = MANUAL_WIDTH[current_mode()]
  if manual then
    return clamp_width(manual)
  end
  return is_narrow() and NARROW_WIDTH or WIDE_WIDTH
end

load_manual_widths()

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
  return " e:expand  ?:help  i:details "
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
        -- `width` accepts a function (utils.resolve_config_option), so the
        -- unexpanded tree follows the screen. See NARROW_WIDTH/WIDE_WIDTH above
        -- for why these are caps rather than wrap settings.
        -- A width you set by hand wins over the caps and persists.
        width = desired_width,
        auto_expand_width = false,
        mappings = {
          -- Neo-tree-only wrap toggle (applies to the Neo-tree window).
          ["W"] = { "toggle_wrap", desc = "toggle wrap" },
          -- `/` back to native Vim search; Neo-tree fuzzy finder moves to `g/`.
          ["/"] = "none",
          ["g/"] = "fuzzy_finder",
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
            -- Record any manual width before the window disappears.
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

            local ok_narrow, narrow = pcall(require, "config.narrow")
            local is_narrow = ok_narrow
                and narrow.is_narrow
                and narrow.is_narrow()
              or vim.o.columns < 55

            local width = vim.api.nvim_win_get_width(winid)
            local cap = is_narrow and NARROW_WIDTH or WIDE_WIDTH
            local manual = MANUAL_WIDTH[is_narrow and "narrow" or "wide"]

            if width == cap or width == manual then
              return
            end

            MANUAL_WIDTH[is_narrow and "narrow" or "wide"] = width
            save_manual_widths()
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

      -- True while we are the ones changing the width, so our own
      -- nvim_win_set_width is not mistaken for a manual drag.
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

      --------------------------------------------------------------------
      -- Terminal resized: re-apply the active width.
      --
      -- Neovim equalises windows itself on VimResized, so a tree that no
      -- longer fits keeps whatever share equalisation handed it. A manual
      -- width wins over the caps; `e`-expanded trees are left alone.
      --------------------------------------------------------------------
      -- One group for every handler below. Creating it once matters: calling
      -- create_augroup with clear = true again would wipe the autocmds
      -- registered before it.
      local width_group = vim.api.nvim_create_augroup("NeoTreeResponsiveWidth", {
        clear = true,
      })

      vim.api.nvim_create_autocmd("VimResized", {
        group = width_group,
        callback = function()
          vim.schedule(function()
            if auto_expand_active() then
              return
            end

            local width = desired_width()

            -- Neovim re-equalises windows after a VimResized and hands the
            -- tree whatever share fills the screen, which discards the width
            -- we just set. Suppress it for the duration of our own resize.
            local equalalways = vim.o.equalalways
            vim.o.equalalways = false

            applying = true
            for _, win in ipairs(neo_tree_windows()) do
              if vim.api.nvim_win_get_width(win) ~= width then
                pcall(vim.api.nvim_win_call, win, function()
                  vim.cmd("vertical resize " .. width)
                end)
              end
            end
            applying = false

            vim.o.equalalways = equalalways
          end)
        end,
      })

      --------------------------------------------------------------------
      -- Window resized: record a manual width.
      --
      -- WinResized also fires for our own VimResized corrections and for
      -- `:vertical resize`, so those are filtered out rather than persisted.
      --------------------------------------------------------------------
      vim.api.nvim_create_autocmd("WinResized", {
        group = width_group,
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

          local width = vim.api.nvim_win_get_width(win)
          local mode = current_mode()

          -- Ignore changes we caused (e.g. equalisation after a split) so a
          -- drag is the only thing that writes the file.
          if width == (MANUAL_WIDTH[mode] or -1)
              or width == desired_width() then
            return
          end

          MANUAL_WIDTH[mode] = width
          save_manual_widths()
        end,
      })

      --------------------------------------------------------------------
      -- Capture the live width when the tree closes and when nvim exits.
      --
      -- WinResized is the precise signal for a drag, but it only fires with a
      -- real UI attached. These two hooks cover the headless/edge cases and
      -- mean a resize still survives even if WinResized is missed.
      --------------------------------------------------------------------
      local function capture_manual_width()
        if auto_expand_active() then
          return
        end

        local width
        for _, win in ipairs(neo_tree_windows()) do
          width = vim.api.nvim_win_get_width(win)
          break
        end

        if not width then
          return
        end

        local mode = current_mode()

        if width == desired_width() then
          return
        end

        MANUAL_WIDTH[mode] = width
        save_manual_widths()
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = width_group,
        callback = capture_manual_width,
      })

      --------------------------------------------------------------------
      -- Reset back to the automatic caps.
      --------------------------------------------------------------------
      vim.api.nvim_create_user_command("NeotreeWidthReset", function()
        MANUAL_WIDTH.narrow = nil
        MANUAL_WIDTH.wide = nil
        save_manual_widths()

        local width = desired_width()

        local equalalways = vim.o.equalalways
        vim.o.equalalways = false

        applying = true
        for _, win in ipairs(neo_tree_windows()) do
          pcall(vim.api.nvim_win_call, win, function()
            vim.cmd("vertical resize " .. width)
          end)
        end
        applying = false

        vim.o.equalalways = equalalways

        print(
          "Neo-tree width reset ("
            .. NARROW_WIDTH
            .. " narrow / "
            .. WIDE_WIDTH
            .. " wide)"
        )
      end, {
        desc = "Forget manually set Neo-tree width and use automatic caps",
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
