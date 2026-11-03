return {
  {
    -- Native chezmoi source editing: target-language treesitter injection,
    -- apply-on-save, live preview, picker, target-aware icons.
    -- Must stay eager: it registers its own *.tmpl filetype detection.
    'dpezto/chezmoi-template.nvim',
    lazy = false,
    ---@module 'chezmoi-template'
    ---@type chezmoi-template.Config
    opts = {
      apply = { on_save = true, notify = true, force = false },
      preview = { diff = true },
      -- Telescope is lazy-loaded, so auto-detection would miss it.
      picker = { backend = 'telescope' },
      keymaps = { enabled = true, prefix = '<leader>C' },
    },
    keys = {
      { '<leader>fC', '<cmd>Chezmoi pick<cr>', desc = 'Chezmoi source files' },
    },
  },
}
