-- Netrw stays disabled (see init.lua top: g:loaded_netrw / g:loaded_netrwPlugin
-- must be set before lazy.setup()); Neo-tree handles directory browsing.
-- The defaults below are kept for documentation but have no effect.
vim.g.netrw_browse_split = 0
vim.g.netrw_alternate = ''
vim.g.netrw_liststyle = 0
vim.g.netrw_winsize = 25

-- When running `nvim .` (or `nvim <dir>`): skip netrw, show an empty
-- buffer (splash) with Neo-tree open on the side instead.
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = function()
    for _, arg in ipairs(vim.v.argv) do
      if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
        -- Drop the directory buffer netrw would have shown
        local dir_buf = vim.api.nvim_get_current_buf()
        vim.cmd("enew")
        pcall(vim.api.nvim_buf_delete, dir_buf, { force = true })
        -- cd so pickers (Telescope) work relative to the target dir
        pcall(vim.cmd, "cd " .. vim.fn.fnameescape(arg))
        -- Defer so that lazy.nvim has fully initialized and the
        -- Neotree command (via cmd proxy) is guaranteed to exist.
        -- `show` (not `reveal`/`focus`) keeps the cursor on the splash.
        vim.defer_fn(function()
          if vim.fn.exists(":Neotree") == 2 then
            vim.cmd("Neotree show")
          end
        end, 50)
        break
      end
    end
  end,
})


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
