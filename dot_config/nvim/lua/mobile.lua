-- mobile.lua
-- Central setup for the Termux mobile IDE enhancements.
-- Loaded from init.lua only when running under Termux (TERMUX_VERSION)
-- or when explicitly enabled for desktop testing (NVIM_MOBILE=1).

local M = {}

function M.setup()
  -- 1. Touch-friendly options
  require('config.mobile')

  -- 2. Gesture-emulating keymaps
  require('config.mobile_keymaps')

  -- 3. Clipboard: Android clipboard on Termux, xclip/xsel/pbcopy elsewhere
  require('clipboard')

  -- 4. Clickable button bar. Loaded LAST so it owns laststatus/statusline
  --    (Termux extra-keys handles hjkl/arrows; the bar handles operators,
  --    text objects and prefixes.)
  vim.opt.mouse = 'a'
  require('bottombar').setup({ winbar = false })
end

return M
