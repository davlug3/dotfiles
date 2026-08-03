-- mobile.lua
-- Central setup for Termux mobile IDE enhancements.
-- Loaded only when is_termux() returns true (from init.lua).

local M = {}

function M.setup()
  vim.notify("mobile.setup() called", vim.log.levels.INFO)
  require('clipboard')

  vim.opt.mouse = 'a'
  require('bottombar').setup({ winbar = false })
  require('floatingbar').setup()
end


return M
