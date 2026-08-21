-- Special-key icons which-key uses by default (Nerd Font glyphs).
-- On a terminal without a Nerd Font these render as empty boxes, so we
-- blank them for an ASCII-only popup. Group/mapping icons are disabled too.
local special_keys = {
  'Up', 'Down', 'Left', 'Right', 'C', 'M', 'D', 'S', 'CR', 'NL', 'Esc', 'BS',
  'ScrollWheelDown', 'ScrollWheelUp', 'Space', 'Tab',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
}
local blank_keys = {}
for _, k in ipairs(special_keys) do
  blank_keys[k] = ''
end

-- Detect whether a Nerd Font is active so which-key can use icons when
-- possible (pretty glyphs) and fall back to plain ASCII otherwise (no boxes).
--
-- Signals:
--   * $NERD_FONT=1 / vim.g.has_nerd_font = true  -> force icons on
--   * $NERD_FONT=0 / vim.g.has_nerd_font = false -> force icon-free
--   * Termux default: icon-free. A Nerd Font file (~/.termux/font.ttf) can be
--     installed but only becomes active when the terminal app restarts, so
--     auto-enabling icons here briefly produces boxes. Turn them on once your
--     terminal actually renders the glyphs.
--   * Desktop default: icons-on (the installer provisions a Nerd Font).
local function nerd_font_available()
  if os.getenv('NERD_FONT') == '1' or vim.g.has_nerd_font == true then
    return true
  end
  if os.getenv('NERD_FONT') == '0' or vim.g.has_nerd_font == false then
    return false
  end
  if os.getenv('TERMUX_VERSION') ~= nil then
    return false
  end
  return true
end

return {
  {
    -- Interactive keymap discovery: shows pending mappings in a popup
    -- as you type (e.g. press <Space> and see all leader-prefixed keys).
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      local icons = {}
      if not nerd_font_available() then
        icons = {
          mappings = false, -- no icons before mappings / group icons
          rules = false,    -- no icon rules
          keys = blank_keys, -- blank special-key icons (Esc, arrows, F-keys)
        }
      end
      require('which-key').setup { icons = icons }
    end,
  },
}
