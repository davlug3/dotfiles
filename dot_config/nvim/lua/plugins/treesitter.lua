return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- Deferred so parser builds don't block first paint; runs right after startup.
    event = 'VeryLazy',
    config = function()
      -- Modern API: the old require('nvim-treesitter.config') module and the
      -- ensure_installed / highlight.enable options were removed from master.
      -- install() downloads each grammar and shells out to the `tree-sitter`
      -- CLI (`generate` + `build`), so the CLI must be on $PATH (installed
      -- via run_once_install-tree-sitter-cli; `:checkhealth nvim-treesitter`
      -- reports it). Already-installed parsers are a no-op.
      require('nvim-treesitter').setup()
      require('nvim-treesitter').install {
        'go',
        'gomod',
        'gosum',
        'gowork',
        'gotmpl',
        'bash',
        'toml',
      }
    end,
  },
}