return {
  'tpope/vim-commentary',
  {
    -- Lazy: Neovim's core already detects terraform/hcl filetypes on its own,
    -- so this trigger fires without the plugin's ftdetect being loaded.
    'hashivim/vim-terraform',
    ft = { 'terraform', 'hcl' },
  },
  {
    -- Lazy: loaded on the filetypes it supports, plus its own commands so
    -- :Emmet still works.
    'mattn/emmet-vim',
    ft = {
      'html',
      'css',
      'scss',
      'sass',
      'less',
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'vue',
      'php',
      'haml',
      'slim',
    },
    cmd = { 'Emmet', 'EmmetInstall' },
  },
  {
    -- Must stay eager: this plugin registers its own filetype detection for
    -- chezmoi's *.tmpl files, so an ft trigger would be circular. It already
    -- defers its heavy work internally.
    'dpezto/chezmoi-template.nvim',
    lazy = false,
    opts = {},
  },
}