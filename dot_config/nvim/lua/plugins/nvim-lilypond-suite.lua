return {
  {
    -- Lazy: only loads when a LilyPond / Tex buffer opens.
    -- This spec used to be duplicated in plugins/treesitter.lua; it lives here
    -- because it is a language suite, not a tree-sitter parser.
    'martineausimon/nvim-lilypond-suite',
    ft = { 'lilypond', 'tex', 'texinfo' },
    opts = {
      -- edit config here (see "Customize default settings" in wiki)
    },
  },
}
