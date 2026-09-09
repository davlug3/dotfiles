return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'mocha',
      background = { light = 'latte', dark = 'mocha' },
      integrations = {
        gitsigns = true,
        telescope = true,
        neotree = true,
        which_key = true,
        treesitter = true,
        mason = true,
        native_lsp = { enabled = true },
      },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme('catppuccin')
    end,
  },
}
