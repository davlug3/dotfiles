return {
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        theme = 'catppuccin',
        icons_enabled = false,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_b = { 'branch', 'diff', 'diagnostics' },
      },
    },
  },
}