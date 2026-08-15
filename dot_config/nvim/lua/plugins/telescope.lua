--- Detect ripgrep for Telescope's grep pickers.
--- live_grep prefers rg when it is on $PATH; when rg is absent Telescope
--- falls back to vimgrep/grep using the arguments below, so the fallback
--- is deterministic on every machine without requiring the user to act.
local has_ripgrep = vim.fn.executable('rg') == 1

local vimgrep_arguments
if has_ripgrep then
  vimgrep_arguments = {
    'rg',
    '--color=never',
    '--no-heading',
    '--with-filename',
    '--line-number',
    '--column',
    '--smart-case',
  }
else
  --- grep fallback: works on both GNU and BSD/macOS grep without --column.
  vimgrep_arguments = {
    'grep',
    '--color=never',
    '--recursive',
    '--line-number',
  }
end

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
          prompt_prefix = '❯ ',
          selection_caret = '❯ ',
          path_display = { 'truncate' },
          file_ignore_patterns = {
            '%.git/',
            'node_modules',
            '%.venv/',
            '__pycache__',
            '%.mypy_cache/',
            '%.pytest_cache/',
            '%.cache/',
          },
          mappings = {
            i = {
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
            },
            n = {
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
            },
          },
        },
      })
    end,
    keys = {
      { '<F1>',         '<cmd>Telescope find_files<CR>',                desc = 'Find files' },
      { '<leader>ff',   '<cmd>Telescope find_files hidden=true<CR>',    desc = 'Find files (hidden)' },
      { '<leader>fg',   '<cmd>Telescope live_grep<CR>',                 desc = 'Live grep' },
      { '<leader>fG',   '<cmd>Telescope grep_cword<CR>',                desc = 'Grep word under cursor' },
      { '<leader>f;',   '<cmd>Telescope grep_last_word<CR>',            desc = 'Grep last searched word' },
      { '<leader>fz',   '<cmd>Telescope current_buffer_fuzzy_find<CR>', desc = 'Fuzzy find in buffer' },
      { '<leader>fb',   '<cmd>Telescope buffers<CR>',                   desc = 'Buffers' },
      { '<leader>fh',   '<cmd>Telescope help_tags<CR>',                  desc = 'Help tags' },
      { '<leader>fr',   '<cmd>Telescope oldfiles<CR>',                  desc = 'Recent files' },
      { '<leader>fo',   '<cmd>Telescope commands<CR>',                  desc = 'Commands' },
      { '<leader>fR',   '<cmd>Telescope resume<CR>',                    desc = 'Resume last search' },
    },
  },
}
