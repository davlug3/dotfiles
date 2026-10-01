-- Dynamic Neovim user manual.
--
-- Generated at runtime from:
--   * actual keymaps
--   * current buffer/window state
--   * configured/active LSPs
--   * lazy.nvim plugins
--   * user/plugin commands
--   * options changed from their defaults
--   * narrow.lua runtime state/config
--
-- Open with your existing `?` mapping.

local M = {}

------------------------------------------------------------------------
-- Configuration
------------------------------------------------------------------------

local MAX_COMMANDS = 120
local MAX_OPTIONS = 120
local MAX_PLUGINS = 200

local MODE_NAMES = {
  n = "Normal",
  v = "Visual",
  x = "Visual (character)",
  s = "Select",
  i = "Insert",
  c = "Command-line",
  t = "Terminal",
  o = "Operator-pending",
}

local MODE_ORDER = {
  "n",
  "v",
  "x",
  "s",
  "i",
  "c",
  "t",
  "o",
}

local CATEGORY_ORDER = {
  "General",
  "Buffers",
  "Search",
  "Git",
  "LSP",
  "Telescope",
  "Navigation",
  "UI / Plugins",
  "Other",
}

------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------

local function safe(fn, default)
  local ok, value = pcall(fn)
  if ok then
    return value
  end
  return default
end

local function add(lines, ...)
  for i = 1, select("#", ...) do
    lines[#lines + 1] = select(i, ...)
  end
end

local function blank(lines)
  lines[#lines + 1] = ""
end

local function heading(lines, level, text)
  lines[#lines + 1] = string.rep("#", level) .. " " .. text
  blank(lines)
end

local function bullet(lines, text)
  lines[#lines + 1] = "- " .. text
end

local function code(value)
  return "`" .. tostring(value) .. "`"
end

local function truncate(value, max)
  value = tostring(value or "")
  value = value:gsub("\n", " "):gsub("%s+", " ")

  if #value <= max then
    return value
  end

  return value:sub(1, max - 3) .. "..."
end

local function pretty(value)
  if value == nil then
    return "nil"
  end

  if type(value) == "boolean" then
    return value and "true" or "false"
  end

  if type(value) == "string" then
    if value == "" then
      return '""'
    end
    return truncate(value, 90)
  end

  if type(value) == "table" then
    return truncate(vim.inspect(value), 90)
  end

  return truncate(tostring(value), 90)
end

local function sort_strings(values)
  table.sort(values, function(a, b)
    return a:lower() < b:lower()
  end)
  return values
end

local function normalize_key(lhs)
  lhs = tostring(lhs or "")

  local leader = vim.g.mapleader or "\\"
  local localleader = vim.g.maplocalleader or "\\"

  if leader ~= "" and lhs:sub(1, #leader) == leader then
    lhs = "<leader>" .. lhs:sub(#leader + 1)
  elseif localleader ~= ""
      and lhs:sub(1, #localleader) == localleader then
    lhs = "<localleader>" .. lhs:sub(#localleader + 1)
  end

  return lhs
end

------------------------------------------------------------------------
-- Classification
------------------------------------------------------------------------

local function classify_mapping(mapping)
  local haystack = table.concat({
    tostring(mapping.lhs or ""),
    tostring(mapping.desc or ""),
    tostring(mapping.rhs or ""),
  }, " "):lower()

  local function has(...)
    for i = 1, select("#", ...) do
      if haystack:find(select(i, ...), 1, true) then
        return true
      end
    end
    return false
  end

  if has(
    "gitsign",
    "git ",
    "git:",
    "hunk",
    "blame",
    "stage",
    "reset hunk",
    "deleted"
  ) then
    return "Git"
  end

  if has(
    "telescope",
    "find files",
    "live grep",
    "grep word",
    "help tags",
    "recent files",
    "git status",
    "git branches"
  ) then
    return "Telescope"
  end

  if has(
    "lsp",
    "definition",
    "references",
    "implementation",
    "type definition",
    "hover",
    "rename",
    "code action",
    "diagnostic",
    "format"
  ) then
    return "LSP"
  end

  if has(
    "buffer",
    "buffers",
    "next buffer",
    "previous buffer",
    "close all"
  ) then
    return "Buffers"
  end

  if has(
    "search",
    "highlight",
    "grep",
    "search word",
    "clear search"
  ) then
    return "Search"
  end

  if has(
    "navigation",
    "navigate",
    "git root",
    "current file",
    "directory",
    "split",
    "tab"
  ) then
    return "Navigation"
  end

  if has(
    "neo-tree",
    "neotree",
    "aerial",
    "lualine",
    "narrow",
    "which-key",
    "file tree",
    "symbols"
  ) then
    return "UI / Plugins"
  end

  if vim.startswith(mapping.lhs or "", "<leader>") then
    return "General"
  end

  return "Other"
end

------------------------------------------------------------------------
-- Keymaps
------------------------------------------------------------------------

local function collect_keymaps(mode, source_buf)
  local result = {}
  local seen = {}
  local undocumented = 0

  local function add_mapping(m, scope)
    local lhs = normalize_key(m.lhs)

    if lhs == ""
        or lhs:sub(1, 6) == "<Plug>"
        or lhs:sub(1, 5) == "<SNR>" then
      return
    end

    local desc = m.desc

    if not desc or desc == "" then
      undocumented = undocumented + 1
      return
    end

    local rhs = m.rhs or ""

    local key = table.concat({
      scope,
      lhs,
      tostring(desc),
      tostring(rhs),
    }, "\0")

    if seen[key] then
      return
    end

    seen[key] = true

    result[#result + 1] = {
      lhs = lhs,
      desc = desc,
      rhs = rhs,
      scope = scope,
      category = classify_mapping({
        lhs = lhs,
        desc = desc,
        rhs = rhs,
      }),
    }
  end

  local global_maps = safe(function()
    return vim.api.nvim_get_keymap(mode)
  end, {})

  for _, mapping in ipairs(global_maps) do
    add_mapping(mapping, "global")
  end

  if source_buf and vim.api.nvim_buf_is_valid(source_buf) then
    local local_maps = safe(function()
      return vim.api.nvim_buf_get_keymap(source_buf, mode)
    end, {})

    for _, mapping in ipairs(local_maps) do
      add_mapping(mapping, "buffer")
    end
  end

  table.sort(result, function(a, b)
    return a.lhs:lower() < b.lhs:lower()
  end)

  return result, undocumented
end

local function append_keymaps(lines, source_buf)
  heading(lines, 2, "Keybindings")

  bullet(lines, "Leader: " .. code(vim.g.mapleader or "\\"))
  bullet(lines, "Local leader: " .. code(vim.g.maplocalleader or "\\"))
  blank(lines)

  for _, mode in ipairs(MODE_ORDER) do
    local mappings, undocumented = collect_keymaps(
      mode,
      source_buf
    )

    if #mappings > 0 then
      heading(
        lines,
        3,
        MODE_NAMES[mode] or ("Mode " .. mode)
      )

      local by_category = {}

      for _, mapping in ipairs(mappings) do
        by_category[mapping.category] =
          by_category[mapping.category] or {}

        table.insert(
          by_category[mapping.category],
          mapping
        )
      end

      for _, category in ipairs(CATEGORY_ORDER) do
        local group = by_category[category]

        if group and #group > 0 then
          lines[#lines + 1] = "**" .. category .. "**"
          blank(lines)

          table.sort(group, function(a, b)
            return a.lhs:lower() < b.lhs:lower()
          end)

          for _, mapping in ipairs(group) do
            local scope = mapping.scope == "buffer"
                and " *(buffer-local)*"
              or ""

            bullet(
              lines,
              code(mapping.lhs)
                .. " — "
                .. truncate(mapping.desc, 110)
                .. scope
            )
          end

          blank(lines)
        end
      end

      if undocumented > 0 then
        bullet(
          lines,
          string.format(
            "%d additional mapping%s without descriptions",
            undocumented,
            undocumented == 1 and "" or "s"
          )
        )
        blank(lines)
      end
    end
  end
end

------------------------------------------------------------------------
-- Environment
------------------------------------------------------------------------

local function append_environment(lines, source_buf, source_win)
  heading(lines, 2, "Environment")

  local version = vim.version()

  local version_string = string.format(
    "%d.%d.%d",
    version.major,
    version.minor,
    version.patch
  )

  local filename = safe(function()
    return vim.api.nvim_buf_get_name(source_buf)
  end, "")

  if filename == "" then
    filename = "[No Name]"
  else
    filename = vim.fn.fnamemodify(filename, ":~:.")
  end

  local filetype = safe(function()
    return vim.bo[source_buf].filetype
  end, "")

  local buftype = safe(function()
    return vim.bo[source_buf].buftype
  end, "")

  local cwd = safe(function()
    return vim.fn.getcwd()
  end, "")

  local mode = safe(function()
    return vim.api.nvim_get_mode().mode
  end, "")

  bullet(lines, "Neovim: " .. code(version_string))
  bullet(lines, "Columns: " .. code(vim.o.columns))
  bullet(lines, "Rows: " .. code(vim.o.lines))
  bullet(lines, "Mode: " .. code(mode))
  bullet(lines, "File: " .. code(filename))
  bullet(lines, "Filetype: " .. code(filetype ~= "" and filetype or "[none]"))
  bullet(lines, "Buftype: " .. code(buftype ~= "" and buftype or "normal"))
  bullet(lines, "CWD: " .. code(cwd))
  bullet(lines, "Source window: " .. code(source_win))

  blank(lines)
end

------------------------------------------------------------------------
-- Narrow mode
------------------------------------------------------------------------

local function append_table(lines, tbl, indent)
  if type(tbl) ~= "table" then
    return
  end

  indent = indent or ""

  local keys = {}

  for key in pairs(tbl) do
    if type(key) == "string" then
      keys[#keys + 1] = key
    end
  end

  table.sort(keys)

  for _, key in ipairs(keys) do
    bullet(
      lines,
      indent
        .. code(key)
        .. " = "
        .. code(pretty(tbl[key]))
    )
  end
end

local function append_narrow(lines, source_buf, source_win)
  heading(lines, 2, "Narrow mode")

  local ok, narrow = pcall(require, "narrow")

  if not ok then
    bullet(lines, "narrow.lua is not currently available.")
    blank(lines)
    return
  end

  local threshold = narrow.threshold

  local state = safe(function()
    return narrow.is_narrow()
  end, nil)

  local forced = vim.g.narrow_force

  bullet(
    lines,
    "Threshold: " .. code(threshold or "?") .. " columns"
  )

  bullet(
    lines,
    "Current state: "
      .. code(
        state == nil
          and "unknown"
          or (state and "ON" or "OFF")
      )
  )

  if forced == true then
    bullet(lines, "Override: " .. code("forced narrow"))
  elseif forced == false then
    bullet(lines, "Override: " .. code("forced wide"))
  else
    bullet(lines, "Override: " .. code("automatic"))
  end

  blank(lines)

  local config

  if type(narrow.get_config) == "function" then
    config = safe(function()
      return narrow.get_config()
    end, nil)
  elseif type(narrow.config) == "table" then
    config = narrow.config
  elseif type(narrow._config) == "table" then
    config = narrow._config
  end

  if type(config) == "table" then
    if config.threshold ~= nil then
      bullet(
        lines,
        "Configured threshold: "
          .. code(config.threshold)
      )
    end

    local window_config = config.win or config.window

    if window_config then
      lines[#lines + 1] = "**Window settings**"
      blank(lines)
      append_table(lines, window_config, "  ")
      blank(lines)
    end

    if config.global then
      lines[#lines + 1] = "**Global settings**"
      blank(lines)
      append_table(lines, config.global, "  ")
      blank(lines)
    end
  else
    lines[#lines + 1] =
      "The module exposes live state, but not its target option tables."
    blank(lines)

    lines[#lines + 1] = "**Effective window options**"
    blank(lines)

    local options = {
      "number",
      "relativenumber",
      "numberwidth",
      "foldcolumn",
      "signcolumn",
      "wrap",
      "linebreak",
      "breakindent",
      "showbreak",
    }

    for _, name in ipairs(options) do
      local value = safe(function()
        return vim.api.nvim_get_option_value(name, {
          win = source_win,
        })
      end, nil)

      if value ~= nil then
        bullet(
          lines,
          code(name)
            .. " = "
            .. code(pretty(value))
        )
      end
    end

    blank(lines)
  end

  local diagnostics = safe(function()
    return vim.diagnostic.config()
  end, {})

  if type(diagnostics) == "table" then
    lines[#lines + 1] = "**Diagnostics**"
    blank(lines)

    if diagnostics.virtual_text ~= nil then
      bullet(
        lines,
        "virtual text = "
          .. code(pretty(diagnostics.virtual_text))
      )
    end

    if diagnostics.float ~= nil then
      bullet(
        lines,
        "float = "
          .. code(pretty(diagnostics.float))
      )
    end

    blank(lines)
  end

  if package.loaded.gitsigns then
    local blame = safe(function()
      local config = require("gitsigns.config")
      return config.config.current_line_blame == true
    end, nil)

    lines[#lines + 1] = "**Gitsigns**"
    blank(lines)

    bullet(lines, "Loaded: " .. code("yes"))

    if blame ~= nil then
      bullet(
        lines,
        "Current-line blame: "
          .. code(blame and "yes" or "no")
      )
    end

    blank(lines)
  end
end

------------------------------------------------------------------------
-- LSP
------------------------------------------------------------------------

local function append_lsp(lines, source_buf)
  heading(lines, 2, "LSP")

  if type(vim.lsp.get_clients) ~= "function" then
    bullet(
      lines,
      "LSP client introspection is unavailable."
    )
    blank(lines)
    return
  end

  local clients = safe(function()
    return vim.lsp.get_clients({
      bufnr = source_buf,
    })
  end, {})

  lines[#lines + 1] = "**Active clients for this buffer**"
  blank(lines)

  if #clients == 0 then
    bullet(lines, "None")
    blank(lines)
  else
    table.sort(clients, function(a, b)
      return a.name < b.name
    end)

    for _, client in ipairs(clients) do
      local detail = client.name

      if client.root_dir and client.root_dir ~= "" then
        detail = detail
          .. " — root "
          .. code(
            vim.fn.fnamemodify(
              client.root_dir,
              ":~:."
            )
          )
      end

      bullet(lines, detail)
    end

    blank(lines)
  end

  if type(vim.lsp.get_configs) == "function" then
    local configs = safe(function()
      return vim.lsp.get_configs()
    end, {})

    local names = {}

    if vim.islist(configs) then
      for _, config in ipairs(configs) do
        if config.name then
          names[#names + 1] = config.name
        end
      end
    else
      for name, config in pairs(configs) do
        if type(config) == "table" then
          names[#names + 1] = config.name or name
        else
          names[#names + 1] = name
        end
      end
    end

    sort_strings(names)

    lines[#lines + 1] = "**Configured LSPs**"
    blank(lines)

    if #names == 0 then
      bullet(lines, "None reported")
    else
      for _, name in ipairs(names) do
        bullet(lines, code(name))
      end
    end

    blank(lines)
  end
end

------------------------------------------------------------------------
-- Plugins
------------------------------------------------------------------------

local function append_plugins(lines)
  heading(lines, 2, "Plugins")

  local lazy_ok, lazy = pcall(require, "lazy")

  if not lazy_ok then
    bullet(lines, "lazy.nvim is not available.")
    blank(lines)
    return
  end

  local stats = safe(function()
    return lazy.stats()
  end, {})

  if type(stats) == "table" then
    if stats.count ~= nil then
      bullet(lines, "Plugins: " .. code(stats.count))
    end

    if stats.loaded ~= nil then
      bullet(lines, "Loaded: " .. code(stats.loaded))
    end

    if stats.startuptime ~= nil then
      bullet(
        lines,
        "Startup: "
          .. code(
            string.format(
              "%.2f ms",
              stats.startuptime
            )
          )
      )
    end
  end

  blank(lines)

  local plugins = {}

  local core_ok, core = pcall(
    require,
    "lazy.core.config"
  )

  if core_ok and type(core.plugins) == "table" then
    for _, plugin in pairs(core.plugins) do
      if type(plugin) == "table" then
        local name =
          plugin.name
          or plugin[1]
          or plugin.dir
          or plugin.url

        if name then
          plugins[#plugins + 1] = {
            name = name,
            loaded = plugin._ and plugin._.loaded == true,
            lazy = plugin.lazy == true,
            enabled = plugin.enabled ~= false,
          }
        end
      end
    end
  end

  if #plugins == 0 then
    bullet(
      lines,
      "Plugin registry is unavailable."
    )
    blank(lines)
    return
  end

  table.sort(plugins, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  lines[#lines + 1] = "**Configured plugins**"
  blank(lines)

  local shown = math.min(
    #plugins,
    MAX_PLUGINS
  )

  for i = 1, shown do
    local plugin = plugins[i]

    local state

    if not plugin.enabled then
      state = "disabled"
    elseif plugin.loaded then
      state = "loaded"
    elseif plugin.lazy then
      state = "lazy"
    else
      state = "not loaded"
    end

    bullet(
      lines,
      code(plugin.name)
        .. " — "
        .. code(state)
    )
  end

  if #plugins > shown then
    bullet(
      lines,
      string.format(
        "... %d more",
        #plugins - shown
      )
    )
  end

  blank(lines)
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function append_commands(lines)
  heading(lines, 2, "Commands")

  local commands = safe(function()
    return vim.api.nvim_get_commands({
      builtin = false,
    })
  end, {})

  local names = {}

  for name in pairs(commands) do
    names[#names + 1] = name
  end

  sort_strings(names)

  bullet(
    lines,
    "User/plugin commands: "
      .. code(#names)
  )
  blank(lines)

  local shown = math.min(
    #names,
    MAX_COMMANDS
  )

  for i = 1, shown do
    local name = names[i]
    local command = commands[name]

    local description = command.desc

    if description and description ~= "" then
      bullet(
        lines,
        code(":" .. name)
          .. " — "
          .. truncate(description, 100)
      )
    else
      bullet(lines, code(":" .. name))
    end
  end

  if #names > shown then
    bullet(
      lines,
      string.format(
        "... %d more commands",
        #names - shown
      )
    )
  end

  blank(lines)
end

------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------

local function get_option_value(
  name,
  info,
  source_buf,
  source_win
)
  if info.scope == "win" then
    return safe(function()
      return vim.api.nvim_get_option_value(name, {
        win = source_win,
      })
    end, nil)
  end

  if info.scope == "buf" then
    return safe(function()
      return vim.api.nvim_get_option_value(name, {
        buf = source_buf,
      })
    end, nil)
  end

  return safe(function()
    return vim.api.nvim_get_option_value(name, {})
  end, nil)
end

local function append_options(
  lines,
  source_buf,
  source_win
)
  heading(lines, 2, "Options")

  local all = safe(function()
    return vim.api.nvim_get_all_options_info()
  end, {})

  local changed = {}

  for name, info in pairs(all) do
    local value = get_option_value(
      name,
      info,
      source_buf,
      source_win
    )

    if value ~= nil
        and not vim.deep_equal(
          value,
          info.default
        ) then
      changed[#changed + 1] = {
        name = name,
        value = value,
        default = info.default,
        scope = info.scope,
      }
    end
  end

  table.sort(changed, function(a, b)
    return a.name < b.name
  end)

  bullet(
    lines,
    "Changed from defaults: "
      .. code(#changed)
  )
  blank(lines)

  local shown = math.min(
    #changed,
    MAX_OPTIONS
  )

  for i = 1, shown do
    local option = changed[i]

    local scope = ""

    if option.scope then
      scope =
        " *[" .. option.scope .. "]*"
    end

    bullet(
      lines,
      code(option.name)
        .. " = "
        .. code(pretty(option.value))
        .. scope
    )
  end

  if #changed > shown then
    bullet(
      lines,
      string.format(
        "... %d more changed options",
        #changed - shown
      )
    )
  end

  blank(lines)

  lines[#lines + 1] =
    "**Current UI-related options**"
  blank(lines)

  local ui_options = {
    "number",
    "relativenumber",
    "numberwidth",
    "signcolumn",
    "foldcolumn",
    "wrap",
    "linebreak",
    "breakindent",
    "showbreak",
    "scrolloff",
    "sidescroll",
    "sidescrolloff",
    "laststatus",
    "showtabline",
    "cmdheight",
    "winwidth",
    "winminwidth",
    "splitkeep",
    "termguicolors",
    "cursorline",
    "colorcolumn",
    "list",
    "conceallevel",
  }

  for _, name in ipairs(ui_options) do
    local info = all[name]

    if info then
      local value = get_option_value(
        name,
        info,
        source_buf,
        source_win
      )

      if value ~= nil then
        bullet(
          lines,
          code(name)
            .. " = "
            .. code(pretty(value))
        )
      end
    end
  end

  blank(lines)
end

------------------------------------------------------------------------
-- Features
------------------------------------------------------------------------

local function append_features(lines)
  heading(lines, 2, "Detected Features")

  local features = {
    {
      name = "Neo-tree",
      available =
        vim.fn.exists(":Neotree") == 2
        or package.loaded["neo-tree"] ~= nil,
    },
    {
      name = "Aerial",
      available =
        vim.fn.exists(":AerialToggle") == 2
        or package.loaded["aerial"] ~= nil,
    },
    {
      name = "Telescope",
      available =
        vim.fn.exists(":Telescope") == 2
        or package.loaded["telescope"] ~= nil,
    },
    {
      name = "Gitsigns",
      available =
        vim.fn.exists(":Gitsigns") == 2
        or package.loaded["gitsigns"] ~= nil,
    },
    {
      name = "Lualine",
      available =
        package.loaded["lualine"] ~= nil,
    },
    {
      name = "Which-key",
      available =
        package.loaded["which-key"] ~= nil,
    },
    {
      name = "Tree-sitter",
      available =
        vim.treesitter ~= nil,
    },
  }

  for _, feature in ipairs(features) do
    bullet(
      lines,
      code(feature.name)
        .. " — "
        .. code(
          feature.available
            and "available"
            or "not loaded"
        )
    )
  end

  blank(lines)
end

------------------------------------------------------------------------
-- Generation
------------------------------------------------------------------------

function M.generate(source_buf, source_win)
  source_buf =
    source_buf
    or vim.api.nvim_get_current_buf()

  source_win =
    source_win
    or vim.api.nvim_get_current_win()

  local lines = {}

  lines[#lines + 1] =
    "# Neovim User Manual"
  blank(lines)

  bullet(lines, "Press `r` to refresh.")
  bullet(lines, "Press `q`, `?`, `<Esc>`, or `<CR>` to close.")
  bullet(
    lines,
    "Use `j/k`, arrows, `Ctrl-d/u`, `Ctrl-f/b`, `gg/G` to scroll."
  )
  blank(lines)

  append_environment(
    lines,
    source_buf,
    source_win
  )

  append_keymaps(
    lines,
    source_buf
  )

  append_narrow(
    lines,
    source_buf,
    source_win
  )

  append_lsp(
    lines,
    source_buf
  )

  append_features(lines)
  append_plugins(lines)
  append_commands(lines)

  append_options(
    lines,
    source_buf,
    source_win
  )

  heading(lines, 2, "Navigation")

  bullet(lines, "`j` / `k` or arrows — scroll")
  bullet(lines, "`Ctrl-d` / `Ctrl-u` — half-page")
  bullet(lines, "`Ctrl-f` / `Ctrl-b` — full-page")
  bullet(lines, "`gg` / `G` — top / bottom")
  bullet(lines, "`r` — regenerate the manual")
  bullet(
    lines,
    "`?` / `q` / `<Esc>` / `<CR>` — close"
  )

  blank(lines)

  return lines
end

------------------------------------------------------------------------
-- Floating window
------------------------------------------------------------------------

local function get_dimensions()
  local columns = vim.o.columns
  local rows = vim.o.lines

  local width = math.min(
    86,
    math.max(1, columns - 4)
  )

  local height = math.min(
    40,
    math.max(1, rows - 4)
  )

  return width, height
end

local function center(width, height)
  return {
    row = math.max(
      0,
      math.floor((vim.o.lines - height) / 2)
    ),
    col = math.max(
      0,
      math.floor((vim.o.columns - width) / 2)
    ),
  }
end

local function apply_highlighting(buf)
  local ns = vim.api.nvim_create_namespace(
    "user_manual"
  )

  vim.api.nvim_buf_clear_namespace(
    buf,
    ns,
    0,
    -1
  )

  local buf_lines =
    vim.api.nvim_buf_get_lines(
      buf,
      0,
      -1,
      false
    )

  for row, line in ipairs(buf_lines) do
    local group

    if line:match("^# ") then
      group = "Title"
    elseif line:match("^## ") then
      group = "Function"
    elseif line:match("^### ") then
      group = "Statement"
    elseif line:match("^%*%*.*%*%*$") then
      group = "Keyword"
    end

    if group then
      vim.api.nvim_buf_add_highlight(
        buf,
        ns,
        group,
        row - 1,
        0,
        -1
      )
    end
  end

  for row, line in ipairs(buf_lines) do
    local start = 1

    while true do
      local s, e =
        line:find("`[^`]+`", start)

      if not s then
        break
      end

      vim.api.nvim_buf_add_highlight(
        buf,
        ns,
        "Identifier",
        row - 1,
        s - 1,
        e
      )

      start = e + 1
    end
  end
end

------------------------------------------------------------------------
-- Show
------------------------------------------------------------------------

function M.show()
  local source_win =
    vim.api.nvim_get_current_win()

  local source_buf =
    vim.api.nvim_get_current_buf()

  -- Don't open duplicates.
  for _, existing_win in ipairs(
    vim.api.nvim_list_wins()
  ) do
    if vim.api.nvim_win_is_valid(existing_win)
        and vim.w[existing_win].user_manual then
      vim.api.nvim_set_current_win(existing_win)
      return
    end
  end

  local width, height =
    get_dimensions()

  local pos =
    center(width, height)

  local buf =
    vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.bo[buf].filetype = "markdown"

  local win =
    vim.api.nvim_open_win(
      buf,
      true,
      {
        relative = "editor",

        width = width,
        height = height,

        row = pos.row,
        col = pos.col,

        style = "minimal",
        border = "rounded",

        title = " User Manual ",
        title_pos = "center",

        focusable = true,
        noautocmd = true,
      }
    )

  vim.w[win].user_manual = true

  -- The manual should ignore the user's normal editing UI.
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true

  vim.wo[win].cursorline = false
  vim.wo[win].scrolloff = 2

  local function render(preserve_cursor)
    local old_line = 1

    if preserve_cursor
        and vim.api.nvim_win_is_valid(win) then
      old_line =
        vim.api.nvim_win_get_cursor(win)[1]
    end

    local generated =
      M.generate(
        source_buf,
        source_win
      )

    vim.bo[buf].modifiable = true

    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      generated
    )

    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true

    apply_highlighting(buf)

    if vim.api.nvim_win_is_valid(win) then
      local line_count =
        vim.api.nvim_buf_line_count(buf)

      old_line =
        math.max(
          1,
          math.min(old_line, line_count)
        )

      pcall(
        vim.api.nvim_win_set_cursor,
        win,
        { old_line, 0 }
      )
    end
  end

  render(false)

  ----------------------------------------------------------------------
  -- Keymaps
  ----------------------------------------------------------------------

  local opts = {
    buffer = buf,
    silent = true,
    nowait = true,
  }

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(
        win,
        true
      )
    end
  end

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "?", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "<CR>", close, opts)

  vim.keymap.set(
    "n",
    "r",
    function()
      render(true)
    end,
    opts
  )

  ----------------------------------------------------------------------
  -- Resize
  ----------------------------------------------------------------------

  local group =
    vim.api.nvim_create_augroup(
      "UserManual_" .. buf,
      { clear = true }
    )

  vim.api.nvim_create_autocmd(
    "VimResized",
    {
      group = group,

      callback = function()
        if not vim.api.nvim_win_is_valid(win) then
          return true
        end

        local new_width, new_height =
          get_dimensions()

        local new_pos =
          center(
            new_width,
            new_height
          )

        vim.api.nvim_win_set_config(
          win,
          {
            width = new_width,
            height = new_height,
            row = new_pos.row,
            col = new_pos.col,
          }
        )
      end,
    }
  )

  vim.api.nvim_create_autocmd(
    "WinClosed",
    {
      group = group,

      callback = function(args)
        if tonumber(args.match) == win then
          pcall(
            vim.api.nvim_del_augroup_by_id,
            group
          )
        end
      end,
    }
  )

  vim.api.nvim_win_set_cursor(
    win,
    { 1, 0 }
  )
end

return M
