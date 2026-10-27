-- Hide chrome on <55 col screens: only filename + location survive.
local function wide()
  local ok, narrow = pcall(require, 'config.narrow')
  if ok and narrow.is_narrow then
    return not narrow.is_narrow()
  end
  return vim.o.columns >= 55
end

-- Mobile mode: bottombar owns the statusline, so lualine must not load
-- (it re-asserts its own statusline on VimEnter/UIEnter and would win).
local is_mobile = os.getenv('TERMUX_VERSION') or os.getenv('NVIM_MOBILE') == '1'

return {
  {
    'nvim-lualine/lualine.nvim',
    cond = not is_mobile,
    opts = {
      options = {
        theme = 'auto',
        icons_enabled = false,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '-', right = '-' },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {
          { 'branch', cond = wide },
          { 'diff', cond = wide },
          { 'diagnostics', cond = wide },
        },
        lualine_c = { { 'filename', path = 1, shorting_target = 20 } },
        lualine_x = {
          { 'encoding', cond = wide },
          { 'fileformat', cond = wide },
          { 'filetype', cond = wide },
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_c = { { 'filename', path = 1, shorting_target = 20 } },
        lualine_x = { 'location' },
      },
    },
  },
}
