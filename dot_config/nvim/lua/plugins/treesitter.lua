return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- Deferred so parser builds don't block first paint; runs right after startup.
    event = 'VeryLazy',
    config = function()
      -- Modern API: the old require('nvim-treesitter.config') module and the
      -- ensure_installed / highlight.enable options were removed from master.
      -- install() compiles missing parsers with cc (no tree-sitter CLI needed)
      -- and is a no-op for already-installed ones.
      require('nvim-treesitter').setup()
      require('nvim-treesitter').install {
        'gotmpl',
        'bash',
        'toml',
      }
    end,
  },
}