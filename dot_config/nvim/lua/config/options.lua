-- General
vim.opt.history = 500
vim.opt.autoread = true
vim.cmd('autocmd FocusGained,BufEnter * silent! checktime')

-- Saving shortcuts (leader mappings live in keymaps.lua)

-- UI
vim.opt.scrolloff = 3
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wildmenu = true
vim.opt.ruler = true
vim.opt.cmdheight = 1
vim.opt.cursorline = true
vim.opt.foldcolumn = '1'
vim.opt.signcolumn = 'yes'
vim.opt.hidden = true
vim.opt.background = 'dark'

-- Editing / motion
vim.opt.backspace = 'eol,start,indent'
vim.opt.whichwrap = vim.opt.whichwrap + '<,>,h,l'

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.showmatch = true

-- Terminal feedback
vim.opt.lazyredraw = true
vim.opt.errorbells = false
vim.opt.visualbell = false
vim.opt.termguicolors = true

-- Files / backups / undo
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'

local undodir = vim.fn.stdpath('data') .. '/undo'
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end

-- Text / tabs / indent
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.linebreak = true
vim.opt.textwidth = 500
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = true
-- Wrap helpers (config/narrow.lua enables breakindent only when narrow,
-- so wide screens keep clean block indent)
vim.opt.breakindent = false
vim.opt.showbreak = ''
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 8
-- Window chrome (narrow.lua refines these on VimResized)
vim.opt.laststatus = 3 -- one global statusline, not one per split
vim.opt.showtabline = 1 -- only when >1 tab
vim.opt.splitkeep = 'screen'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.winminwidth = 10

-- Tags / completion
vim.opt.tags = vim.fn.stdpath('data') .. '/tags,tags'
vim.opt.completeopt = { 'menuone', 'noinsert', 'noselect', 'preview' }

-- Clipboard
vim.opt.clipboard = 'unnamedplus'