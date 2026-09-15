-- Responsive UI for narrow screens (columns < 55, e.g. phone portrait,
-- Termux split, tmux side-pane).
--
-- What it does when narrow:
--   * reclaims ~5 columns: foldcolumn 0, signcolumn 1 col, numberwidth 2,
--     no relativenumber
--   * soft-wrap friendly: breakindent + showbreak, sidescroll 1/0
--   * less chrome: global statusline, tabline only with >1 tab
--   * diagnostics virtual-text off (signs + float only, no wrap spam)
--   * gitsigns eol blame off (wraps badly on 50 cols)
--   * refreshes lualine so its hide_in_width components update
--
-- Manual override:
--   :NarrowOn / :NarrowOff / :NarrowToggle  (sets vim.g.narrow_force)
--   unset with :NarrowAuto (follow vim.o.columns again)

local M = {}

M.threshold = 55

function M.is_narrow()
  if vim.g.narrow_force == true then
    return true
  end
  if vim.g.narrow_force == false then
    return false
  end
  return vim.o.columns < M.threshold
end

local diag_wide = {
  virtual_text = { prefix = '●', spacing = 2 },
  signs = true,
  underline = true,
  float = { border = 'single' },
}
local diag_narrow = {
  virtual_text = false,
  signs = true,
  underline = true,
  float = { border = 'single', max_width = 50,max_height = 10, wrap = true },
}

function M.apply()
  local narrow = M.is_narrow()

  if narrow then
    -- Gutter: number (2-wide) + 1 sign col, no fold col, no rnu.
    vim.opt.numberwidth = 2
    vim.opt.foldcolumn = '0'
    vim.opt.signcolumn = 'yes:1'
    vim.opt.number = true
    vim.opt.relativenumber = false
    -- Wrapping / sideways motion: every col counts.
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.breakindent = true
    vim.opt.showbreak = '↪ '
    vim.opt.sidescroll = 1
    vim.opt.sidescrolloff = 0
    vim.opt.scrolloff = 1
    -- Chrome: one global statusline, tabline only when needed.
    vim.opt.laststatus = 3
    vim.opt.showtabline = 1
    vim.opt.cmdheight = 1
    vim.opt.winminwidth = 10
    vim.opt.winwidth = 10
    vim.opt.splitkeep = 'screen'
    vim.diagnostic.config(diag_narrow)
  else
    vim.opt.numberwidth = 4
    vim.opt.foldcolumn = '1'
    vim.opt.signcolumn = 'yes'
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.breakindent = false
    vim.opt.showbreak = ''
    vim.opt.sidescrolloff = 8
    vim.opt.scrolloff = 3
    vim.opt.laststatus = 3
    vim.opt.showtabline = 1
    vim.opt.splitkeep = 'screen'
    vim.diagnostic.config(diag_wide)
  end

  -- Per-window options (future splits inherit vim.opt, fix open ones).
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.api.nvim_buf_is_valid(buf) then
      local bt = vim.bo[buf].buftype
      if bt ~= 'prompt' and bt ~= 'nofile' then
        vim.wo[win].number = true
        vim.wo[win].relativenumber = not narrow
        vim.wo[win].foldcolumn = narrow and '0' or '1'
        vim.wo[win].signcolumn = narrow and 'yes:1' or 'yes'
        vim.wo[win].wrap = true
        vim.wo[win].linebreak = true
        vim.wo[win].breakindent = narrow
      end
    end
  end

  -- Gitsigns eol blame wraps into mush on ~50 cols; toggle it with width.
  pcall(function()
    local gs = package.loaded.gitsigns
    if gs and gs.toggle_current_line_blame then
      -- toggle_current_line_blame(bool) forces state when arg given.
      gs.toggle_current_line_blame(not narrow)
    end
  end)

  -- Lualine caches `cond` results; force re-evaluation on resize.
  pcall(function()
    require('lualine').refresh()
  end)
end

-- Smart horizontal-first split: :vsplit on a 50-col screen gives two
-- unusable 25-col panes. <leader>s picks orientation by width.
function M.smart_split()
  if M.is_narrow() then
    vim.cmd('split')
  else
    vim.cmd('vsplit')
  end
end

vim.api.nvim_create_user_command('NarrowOn', function()
  vim.g.narrow_force = true
  M.apply()
end, { desc = 'Force narrow-screen UI' })
vim.api.nvim_create_user_command('NarrowOff', function()
  vim.g.narrow_force = false
  M.apply()
end, { desc = 'Force wide-screen UI' })
vim.api.nvim_create_user_command('NarrowAuto', function()
  vim.g.narrow_force = nil
  M.apply()
end, { desc = 'Follow window width for narrow UI' })
vim.api.nvim_create_user_command('NarrowToggle', function()
  vim.g.narrow_force = not M.is_narrow()
  M.apply()
end, { desc = 'Toggle narrow-screen UI' })

local grp = vim.api.nvim_create_augroup('NarrowScreen', { clear = true })
vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResized', 'WinEnter', 'BufWinEnter' }, {
  group = grp,
  callback = function()
    -- Defer on resize so vim.o.columns has settled (tmux/phone rotate).
    vim.schedule(M.apply)
  end,
})

return M
