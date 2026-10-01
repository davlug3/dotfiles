vim.filetype.add({
  extension = {
    jsonc = "json",
  },
})

return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',

    config = function()
      require('nvim-treesitter').setup()

      require('nvim-treesitter').install {
        -- Systems
        'c',
        'cpp',
        'rust',
        'go',
        'java',
        'kotlin',
        'c_sharp',
        'swift',

        -- Web
        'javascript',
        'typescript',
        'tsx',
        'html',
        'css',
        'scss',
        'vue',
        'svelte',
        'astro',

        -- Backend / scripting
        'python',
        'ruby',
        'php',
        'lua',
        'bash',
        'fish',
        'perl',
        'r',
        'sql',

        -- Data / config
        'json',
        'yaml',
        'toml',
        'xml',
        'graphql',
        'hcl',

        -- Templates
        'gotmpl',
        'jinja',

        -- DevOps
        'dockerfile',

        -- Documentation
        'markdown',
        'markdown_inline',
        'rst',

        -- Git
        'gitcommit',
        'git_rebase',

        -- Misc
        'vim',
        'regex',
      }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  {
    'martineausimon/nvim-lilypond-suite',
    ft = { 'lilypond', 'tex', 'texinfo' },
    opts = {},
  },
}
