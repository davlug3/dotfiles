-- clipboard.lua
-- Bridges Neovim y/d/p to the system clipboard.
-- On Termux: shells out to termux-clipboard-get/set (Android clipboard).
-- On desktop: delegates to termux-bridge.lua (xclip/xsel/pbcopy).
--
-- Requirements on Termux:
--   pkg install termux-api
--   Install the "Termux:API" app from F-Droid
--   Test: echo "hi" | termux-clipboard-set && termux-clipboard-get

local function is_termux_env()
  if os.getenv("TERMUX_VERSION") then return true end
  if os.getenv("SHELL") and os.getenv("SHELL"):find("termux") then return true end
  if os.getenv("TERMUX_MODE") == "1" then return true end
  if vim.g.termux == 1 then return true end
  return false
end

local has_termux_api = is_termux_env() and vim.fn.executable("termux-clipboard-set") == 1

if has_termux_api then
  vim.g.clipboard = {
    name = "termux-clipboard",
    copy = {
      ["+"] = "termux-clipboard-set",
      ["*"] = "termux-clipboard-set",
    },
    paste = {
      ["+"] = "termux-clipboard-get",
      ["*"] = "termux-clipboard-get",
    },
    cache_enabled = 0,
  }
else
  require('termux-bridge')
end

vim.opt.clipboard = "unnamedplus"

return {}
