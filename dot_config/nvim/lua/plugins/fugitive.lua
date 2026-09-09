return {
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G', 'Gdiffsplit', 'Gvdiffsplit', 'Gwrite', 'Gread', 'Gblame', 'GBrowse' },
    keys = {
      { '<leader>gg', '<cmd>Git<CR>', desc = 'Git status' },
      { '<leader>gd', '<cmd>Gdiffsplit<CR>', desc = 'Git diff split' },
      { '<leader>gl', '<cmd>Git log --oneline -20<CR>', desc = 'Git log' },
      { '<leader>gL', '<cmd>0Gclog<CR>', desc = 'Git log current file' },
      { '<leader>gp', '<cmd>Git push<CR>', desc = 'Git push' },
      { '<leader>gP', '<cmd>Git pull --rebase<CR>', desc = 'Git pull --rebase' },
      { '<leader>gB', '<cmd>Git blame<CR>', desc = 'Git blame' },
      { '<leader>gw', '<cmd>Gwrite<CR>', desc = 'Git stage file' },
      { '<leader>gr', '<cmd>Gread<CR>', desc = 'Git checkout file' },
    },
  },
}
