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
  vimgrep_arguments = {
    'grep',
    '--color=never',
    '--recursive',
    '--line-number',
  }
end

-- Last non-empty live-grep prompt, stored outside any nvim session so `\fg`
-- and `\fH` pre-fill the prompt across restarts.
local last_grep_path = vim.fn.stdpath('state') .. '/last_live_grep'

local function read_last_grep()
  local file = io.open(last_grep_path, 'r')
  if not file then
    return nil
  end
  local line = file:read('*l')
  file:close()
  if line ~= '' then
    return line
  end
  return nil
end

local function save_last_grep(prompt)
  if not prompt or prompt == '' then
    return
  end
  vim.fn.mkdir(vim.fn.stdpath('state'), 'p')
  local file = io.open(last_grep_path, 'w')
  if file then
    file:write(prompt)
    file:close()
  end
end

-- Open a grep result, highlight every occurrence of the prompt in the file and
-- centre it. Telescope's own edit action only moves to (row, col): it never
-- touches the search register, so `hlsearch` has nothing to draw and the match
-- can land at the bottom of the window.
local function open_grep_result(prompt_bufnr)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  -- Capture before select_default closes the prompt buffer.
  local prompt = action_state.get_current_line()
  save_last_grep(prompt)

  actions.select_default(prompt_bufnr)

  if not prompt or prompt == '' then
    return
  end

  -- Let Telescope finish opening the buffer and placing the cursor first.
  vim.schedule(function()
    vim.fn.setreg('/', prompt)
    vim.opt.hlsearch = true

    local ok, found = pcall(vim.fn.search, prompt, 'cW')
    if not ok or found == 0 then
      -- Ripgrep regex and Vim regex are not the same dialect (+ ? ( ) are
      -- literal here). Fall back to a literal search so a fancy prompt still
      -- highlights something instead of throwing E486.
      local literal = prompt:gsub('\\', '\\\\')
      pcall(vim.fn.search, '\\V' .. literal, 'cW')
    end

    vim.cmd('normal! zz')
  end)
end

local function grep_attach_mappings(_, map)
  local function close_and_save(prompt_bufnr)
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')

    -- Capture before close() tears down the prompt buffer.
    save_last_grep(action_state.get_current_line(prompt_bufnr))
    actions.close(prompt_bufnr)
  end

  map({ 'i', 'n' }, '<CR>', open_grep_result)
  -- Abandoning the picker (Esc / q / <C-c>) still remembers what was typed.
  map({ 'i', 'n' }, '<Esc>', close_and_save)
  map('n', 'q', close_and_save)
  map({ 'i', 'n' }, '<C-c>', close_and_save)
  return true
end

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
          prompt_prefix = '>',
          selection_caret = '>',
          path_display = { 'truncate' },
          history = {
            path = vim.fn.stdpath('data') .. '/telescope_history',
            limit = 100,
          },
          layout_strategy = 'flex',
          layout_config = {
            width = 0.99,
            height = 0.9,
            horizontal = { preview_cutoff = 55, prompt_position = 'bottom' },
            vertical = { preview_cutoff = 55, prompt_position = 'bottom' },
          },
file_ignore_patterns = {
  '%.git/',
  'node_modules',
  '%.venv/',
  '__pycache__',
  '%.mypy_cache/',
  '%.pytest_cache/',
  '%.cache/',
  '%.docker/',
  '%.terraform/',
  '%.aws/',
  'kube/',
  '%.sqlite',
  '%.db',
  '%.duckdb',
  'data/db/',
  'supabase/',
  '%.astro/',
  '%.remix/',
  '%.turbo/',
  '%.vercel/',
  '%.netlify/',
  'bin/',
  'obj/',
  '%.gopls/',
  'dist-newstyle/',
  '%.stack-work/',
  '%.docusaurus/',
  'site/',
  '_site/',
  '%.vitepress/dist/',
  '%.wrangler/',
  '%.dev/',
  '%.cloudflare/',
  '%.next/',
  '%.nuxt/',
  '%.output/',
  'dist/',
  'build/',
  'out/',
  '%.nitro/',
  '%.content-cache/',
  '%.mp4',
  '%.mov',
  '%.avi',
  '%.png',
  '%.jpg',
  '%.jpeg',
  '%.webp',
  '%.gif',
  '%.mp3',
  '%.wav',
  '%.flac',
  '%.zip',
  '%.tar%.gz',
  '%.rar',
  '%.7z',
},          mappings = {
            i = {
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
              ['<C-Down>'] = require('telescope.actions').cycle_history_next,
              ['<C-Up>'] = require('telescope.actions').cycle_history_prev,
            },
            n = {
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
              ['<C-Down>'] = require('telescope.actions').cycle_history_next,
              ['<C-Up>'] = require('telescope.actions').cycle_history_prev,
            },
          },
        },
      })
    end,
    keys = {
      -- VSCode-style Ctrl+P quick-open + Ctrl+Shift+P command  palette.
      -- <leader>1/ff/fo remain as fallbacks (some terminals send <C-p> for <C-S-p>).
      { '<C-p>',        '<cmd>Telescope find_files<CR>',                desc = 'Find files (Ctrl+P)' },
      { '<leader>p',        '<cmd>Telescope find_files<CR>',                desc = 'Find files (Leader+p)' },
      { '<C-S-p>',      '<cmd>Telescope commands<CR>',                 desc = 'Commands (Ctrl+Shift+P)' },
      { '<leader>P',      '<cmd>Telescope commands<CR>',                 desc = 'Commands (Leader+P)' },
      { '<leader>1',      '<cmd>Telescope find_files<CR>',                desc = 'Find files' },
      { '<leader>ff',   '<cmd>Telescope find_files hidden=true<CR>',    desc = 'Find files (hidden)' },
      {
        '<leader>fg',
        function()
          require('telescope.builtin').live_grep({
            default_text = read_last_grep(),
            attach_mappings = grep_attach_mappings,
          })
        end,
        desc = 'Live grep',
      },
      -- Hidden files, including gitignored ones (.env, local configs).
      -- --no-ignore is deliberate here; the normal <leader>fg stays fast.
      {
        '<leader>fH',
        function()
          require('telescope.builtin').live_grep({
            additional_args = { '--hidden', '--no-ignore', '--glob=!.git/*' },
            default_text = read_last_grep(),
            attach_mappings = grep_attach_mappings,
          })
        end,
        desc = 'Live grep (hidden + no ignore)',
      },
      { '<leader>fG',   '<cmd>Telescope grep_cword<CR>',                desc = 'Grep word under cursor' },
      { '<leader>f;',   '<cmd>Telescope grep_last_word<CR>',            desc = 'Grep last searched word' },
      { '<leader>fz',   '<cmd>Telescope current_buffer_fuzzy_find<CR>', desc = 'Fuzzy find in buffer' },
      { '<leader>fb',   '<cmd>Telescope buffers<CR>',                   desc = 'Buffers' },
      { '<leader>fh',   '<cmd>Telescope help_tags<CR>',                  desc = 'Help tags' },
      { '<leader>fr',   '<cmd>Telescope oldfiles<CR>',                  desc = 'Recent files' },
      { '<leader>fo',   '<cmd>Telescope commands<CR>',                  desc = 'Commands' },
      { '<leader>fR',   '<cmd>Telescope resume<CR>',                    desc = 'Resume last search' },
      { '<leader>gs',   '<cmd>Telescope git_status<CR>',                desc = 'Git status' },
      { '<leader>gb',   '<cmd>Telescope git_branches<CR>',              desc = 'Git branches' },
      { '<leader>gc',   '<cmd>Telescope git_commits<CR>',               desc = 'Git commits' },
      { '<leader>gC',   '<cmd>Telescope git_bcommits<CR>',              desc = 'Git buffer commits' },
    },
  },
}
