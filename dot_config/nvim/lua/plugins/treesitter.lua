vim.filetype.add({
  extension = {
    jsonc = "json",
  },
})

return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',

    config = function()
      require('nvim-treesitter').setup()

      -- Install parsers on demand as needed
      -- Add parsers here only if you use them frequently
      local parsers = {
        'lua',
        'vim',
        'vimdoc',
        'query',
        'markdown',
        'markdown_inline',
      }

      -- Try to install common parsers if missing (non-blocking)
      pcall(function()
        require('nvim-treesitter').install(parsers)
      end)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
