---@class wk.Opts
local defaults = {
  ---@type false | "classic" | "modern" | "helix"
  preset = "classic",

  --- Delay before showing the popup
  ---@type number | fun(ctx: { keys: string, mode: string, plugin?: string }):number
  delay = function(ctx)
    return ctx.plugin and 0 or 200
  end,

  ---@param mapping wk.Mapping
  filter = function(mapping)
    return true
  end,

  ---@type wk.Spec
  spec = {},

  notify = true,

  ---@type wk.Spec
  triggers = {
    { "<auto>", mode = "nxso" },
  },

  ---@param ctx { mode: string, operator: string }
  defer = function(ctx)
    return ctx.mode == "V" or ctx.mode == "<C-V>"
  end,

  plugins = {
    marks = true,
    registers = true,

    spelling = {
      enabled = true,
      suggestions = 20,
    },

    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },

  win = {
    no_overlap = true,
    padding = { 1, 1 },
    title = true,
    title_pos = "center",
    zindex = 1000,

    bo = {},

    wo = {},
  },

  layout = {
    width = {
      min = 20,
      max = 50,
    },
    spacing = 2,
  },

  keys = {
    scroll_down = "<c-d>",
    scroll_up = "<c-u>",
  },

  ---@type (string|wk.Sorter)[]
  sort = {
    "local",
    "order",
    "group",
    "alphanum",
    "mod",
  },

  ---@type number|fun(node: wk.Node):boolean?
  expand = 0,

  replace = {
    key = {
      function(key)
        return require("which-key.view").format(key)
      end,
    },

    desc = {
      { "<Plug>%(?(.*)%)?", "%1" },
      { "^%+", "" },
      { "<[cC]md>", "" },
      { "<[cC][rR]>", "" },
      { "<[sS]ilent>", "" },
      { "^lua%s+", "" },
      { "^call%s+", "" },
      { "^:%s*", "" },
    },
  },

  icons = {
    breadcrumb = "»",
    separator = "➜",
    group = "+",
    ellipsis = "…",

    mappings = true,
    rules = {},
    colors = true,

    keys = {
      Up = " ",
      Down = " ",
      Left = " ",
      Right = " ",

      C = "󰘴 ",
      M = "󰘵 ",
      D = "󰘳 ",
      S = "󰘶 ",

      CR = "󰌑 ",
      Esc = "󱊷 ",

      ScrollWheelDown = "󱕐 ",
      ScrollWheelUp = "󱕑 ",

      NL = "󰌑 ",
      BS = "󰁮",

      Space = "󱁐 ",
      Tab = "󰌒 ",

      F1 = "󱊫",
      F2 = "󱊬",
      F3 = "󱊭",
      F4 = "󱊮",
      F5 = "󱊯",
      F6 = "󱊰",
      F7 = "󱊱",
      F8 = "󱊲",
      F9 = "󱊳",
      F10 = "󱊴",
      F11 = "󱊵",
      F12 = "󱊶",
    },
  },

  show_help = true,
  show_keys = true,

  disable = {
    ft = {},
    bt = {},
  },

  debug = false,
}

-- Special-key icons used by which-key.
local special_keys = {
  "Up",
  "Down",
  "Left",
  "Right",
  "C",
  "M",
  "D",
  "S",
  "CR",
  "NL",
  "Esc",
  "BS",
  "ScrollWheelDown",
  "ScrollWheelUp",
  "Space",
  "Tab",
  "F1",
  "F2",
  "F3",
  "F4",
  "F5",
  "F6",
  "F7",
  "F8",
  "F9",
  "F10",
  "F11",
  "F12",
}

local blank_keys = {}

for _, key in ipairs(special_keys) do
  blank_keys[key] = ""
end

-- Detect whether a Nerd Font is available.
local function nerd_font_available()
  -- Explicitly enabled.
  if os.getenv("NERD_FONT") == "1" or vim.g.has_nerd_font == true then
    return true
  end

  -- Explicitly disabled.
  if os.getenv("NERD_FONT") == "0" or vim.g.has_nerd_font == false then
    return false
  end

  -- Termux defaults to ASCII until the terminal has actually restarted
  -- with the Nerd Font enabled.
  if os.getenv("TERMUX_VERSION") ~= nil then
    return false
  end

  -- Desktop defaults to Nerd Font.
  return true
end

-- Apply ASCII fallback when Nerd Font isn't available.
if not nerd_font_available() then
  defaults.icons = {
    mappings = false,
    rules = false,
    keys = blank_keys,
  }
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = defaults,
  },
}
