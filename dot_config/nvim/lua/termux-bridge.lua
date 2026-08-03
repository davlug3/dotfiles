-- termux-bridge.lua
-- Desktop clipboard fallback. Provides the same interface as
-- termux-clipboard-get/set but uses xclip, xsel, or pbcopy/pbpaste.
-- Allows developing and testing the full stack on a desktop without
-- Termux installed.

local M = {}

local function detect_clipboard()
  if vim.fn.has('mac') == 1 then
    return { copy = "pbcopy", paste = "pbpaste" }
  elseif vim.fn.executable("xclip") == 1 then
    return { copy = "xclip -selection clipboard", paste = "xclip -selection clipboard -o" }
  elseif vim.fn.executable("xsel") == 1 then
    return { copy = "xsel --clipboard --input", paste = "xsel --clipboard --output" }
  end
  return nil
end

local cmds = detect_clipboard()
if cmds then
  vim.g.clipboard = {
    name = "termux-bridge",
    copy = {
      ["+"] = cmds.copy,
      ["*"] = cmds.copy,
    },
    paste = {
      ["+"] = cmds.paste,
      ["*"] = cmds.paste,
    },
    cache_enabled = 0,
  }
end

return M
