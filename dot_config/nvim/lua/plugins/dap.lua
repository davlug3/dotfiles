-- VSCode-like debugging: nvim-dap + launch.json support.
-- Minimal by default (signs + virtual-text + F-keys); full sidebar via <leader>du.
return {
  'mfussenegger/nvim-dap',
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio' },
  },
  'theHamsta/nvim-dap-virtual-text',
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = { 'williamboman/mason.nvim', 'mfussenegger/nvim-dap' },
  },
  {
    'nvim-telescope/telescope-dap.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap' },
  },
}
