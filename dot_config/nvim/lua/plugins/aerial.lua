return {
  {
    'stevearc/aerial.nvim',
    opts = {
      layout = {
        -- Default ~30 cols overwhelms a <55 col screen; clamp to 25/25%.
        max_width = { 25, 0.25 },
        min_width = 15,
        default_direction = 'prefer_right',
        placement = 'edge',
      },
    },
    keys = {
      { '<leader>8', '<cmd>AerialToggle<CR>', desc = 'Aerial (symbols)' },
    },
  },
}