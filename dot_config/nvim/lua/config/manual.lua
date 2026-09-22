-- User manual shown when pressing ? in normal mode.
-- Renders as a scrollable floating window with markdown-style
-- headings, bold (**text**) and bullet (- item) support.
--
-- Content is organized by what you can still do when the UI
-- is in narrow mode (columns < 55) — see the "Narrow mode"
-- section for where to find hidden info.

local M = {}

local lines = {
  '== Neovim User Manual ==',
  '',
  'Press ? again to close. Arrow keys / jk to scroll. q to quit.',
  '',
  '-- Narrow mode (screen < 55 cols) --',
  'When the screen is narrow, some info is hidden to save space.',
  'It is not gone, just tucked away. :NarrowOff brings it all back.',
  '',
  '  Statusline info hidden:',
  '    git branch      -> <leader>gb',
  '    diff +- counts  -> <leader>hp (preview hunk), <leader>hd (diff)',
  '    error count     -> [d / ]d to jump; signs still in gutter',
  '    filetype/enc    -> :set ft? / :set ff? / :set fenc?',
  '',
  '  Error text next to code (virtual-text) is off; signs + float remain:',
  '    see error      -> [d / ]d',
  '    full message   -> :lua vim.diagnostic.open_float()',
  '',
  '  Git blame at end of line is off (wraps badly):',
  '    one-line blame -> <leader>hb',
  '    keep blame on  -> <leader>tb',
  '',
  '  Relative numbers (5j, 3k) hidden:',
  '    show them      -> :set rnu | :set nornu',
  '    or             -> :NarrowOff',
  '',
  '  Telescope preview pane is off (no room):',
  '    just press Enter to open the file.',
  '',
  '  Neo-tree / Aerial names are just narrower (22 wide).',
  '    widen the terminal to see full names.',
  '',
  '-- Keybindings --',
  '',
  '  General:',
  '    <leader>w      toggle word wrap',
  '    <leader>,      edit vimrc',
  '    <leader>5      reload config',
  '    <leader>?      show this manual',
  '    <leader>?      (which-key: all keymaps)',
  '    <leader>s      smart split (h-split when narrow)',
  '    <leader>zn    toggle narrow-screen UI',
  '    <leader>e      toggle Neo-tree file tree',
  '    <leader>8      toggle Aerial symbols',
  '    <C-k><C-m>     toggle tab / split',
  '',
  '  Buffers:',
  '    <leader>b      list buffers',
  '    <leader>ba    close all buffers',
  '    <leader>l    next buffer',
  '    <leader>h    previous buffer',
  '',
  '  Search:',
  '    <leader>*      highlight word under cursor',
  '    <leader><CR>   clear search highlight',
  '    * (visual)     search selected text',
  '    # (visual)     search selected backward',
  '',
  '  Git (gitsigns):',
  '    <leader>hs    stage hunk',
  '    <leader>hr    reset hunk',
  '    <leader>hS    stage whole buffer',
  '    <leader>hR    reset whole buffer',
  '    <leader>hp    preview hunk',
  '    <leader>hb    blame line',
  '    <leader>hd    diff file',
  '    <leader>tb    toggle blame',
  '    <leader>td    toggle deleted',
  '    ]c / [c      next / prev hunk',
  '',
  '  LSP:',
  '    gd      goto definition',
  '    gr      find references',
  '    gi      goto implementation',
  '    gt      goto type definition',
  '    K       hover docs',
  '    <leader>rn    rename',
  '    <leader>ca    code action',
  '    [d / ]d   prev / next diagnostic',
  '',
  '  Telescope (files, grep, buffers...):',
  '    <C-p> / <leader>1 / ff   find files',
  '    <C-S-p> / <leader>fo     commands',
  '    <leader>fg     live grep',
  '    <leader>fG     grep word under cursor',
  '    <leader>fb     buffers',
  '    <leader>fh     help tags',
  '    <leader>fr     recent files',
  '    <leader>gs    git status',
  '    <leader>gb    git branches',
  '',
  '  Navigation:',
  '    <leader>cr    lcd to git root',
  '    <leader>cd    lcd to current file dir',
  '',
  '-- Navigation in this manual --',
  '  j / k or arrow keys: scroll',
  '  ? or q: close',
  '',
}

-- Simple bold/italic marker parser -> no ANSI, just strip markers.
local function render(text)
  text = text:gsub('%*%*(.-)%*%*', '%1') -- **bold**
  text = text:gsub('%*(.-)%*', '%1')     -- *italic*
  text = text:gsub('`(.-)`', '%1')       -- `code`
  return text
end

function M.show()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.min(78, vim.o.columns - 4, vim.o.columns - (vim.opt.numberwidth:get() + 4))
  local height = math.min(#lines, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' User Manual ',
    title_pos = 'center',
  })

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'markdown'

  -- Try to use override for markdown to get basic highlighting
  pcall(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'ManualOpen' })
  end)

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  vim.keymap.set('n', '?', close, { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', close, { buffer = buf, silent = true })
  vim.keymap.set('n', '<Escape>', close, { buffer = buf, silent = true })
  vim.keymap.set('n', '<CR>', close, { buffer = buf, silent = true })

  -- Scrolling
  vim.keymap.set('n', 'j', function()
    if vim.api.nvim_win_get_cursor(win)[1] < #lines then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_win_get_cursor(win)[1] + 1, 0 })
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', 'k', function()
    if vim.api.nvim_win_get_cursor(win)[1] > 1 then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_win_get_cursor(win)[1] - 1, 0 })
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', '<Down>', function()
    if vim.api.nvim_win_get_cursor(win)[1] < #lines then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_win_get_cursor(win)[1] + 1, 0 })
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', '<Up>', function()
    if vim.api.nvim_win_get_cursor(win)[1] > 1 then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_win_get_cursor(win)[1] - 1, 0 })
    end
  end, { buffer = buf, silent = true })

  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

return M
