-- Toggle word wrap (wrap + linebreak)
vim.keymap.set('n', '<leader>w', function()
  vim.opt.wrap = not vim.opt.wrap:get()
  vim.opt.linebreak = vim.opt.wrap:get()
end, { desc = 'Toggle word wrap' })
-- Edit vimrc
vim.keymap.set('n', '<leader>,', ':vs ~/.vimrc<CR>', { desc = 'Edit vimrc' })
-- Reload vimrc
vim.keymap.set('n', '<leader>5', ':source $MYVIMRC<CR>', { desc = 'Reload nvim config' })

-- Toggle between tabs and splits
local function toggle_tab()
  local bufs = vim.fn.tabpagebuflist()
  local num_windows = 0
  for _, b in ipairs(bufs) do
    if vim.fn.bufwinnr(b) ~= -1 then
      num_windows = num_windows + 1
    end
  end
  if num_windows > 1 then
    vim.cmd('tab split')
  else
    vim.cmd('tabclose')
  end
end
vim.keymap.set('n', '<C-k><C-m>', toggle_tab, { desc = 'Toggle tab/split' })

-- Highlight word under cursor
vim.keymap.set('n', '<leader>*', "<C-u>let @/ = expand('<cword>')<CR>", { desc = 'Highlight word' })

-- Disable highlight on <leader><cr>
vim.keymap.set('n', '<leader><CR>', ':noh<CR>', { desc = 'Clear search highlight' })

-- Buffers
vim.keymap.set('n', '<Leader>b', ':buffers<CR>:buffer<Space>', { desc = 'List buffers' })
vim.keymap.set('n', '<leader>ba', ':bufdo bd<CR>', { desc = 'Close all buffers' })
vim.keymap.set('n', '<leader>l', ':bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>h', ':bprevious<CR>', { desc = 'Previous buffer' })

-- lcd to the git root of the current file
local function git_root()
  local root = vim.fs.root(0, { '.git' })
  return root or vim.uv.cwd()
end

vim.keymap.set('n', '<leader>cr', function()
  vim.cmd.lcd(git_root())
  print('cwd → ' .. vim.fn.getcwd())
end, { desc = 'lcd to git root' })

vim.keymap.set('n', '<leader>cd', function()
  vim.cmd.lcd(vim.fn.expand('%:h'))
  print('cwd → ' .. vim.fn.getcwd())
end, { desc = 'lcd to current file directory' })

-- Visual-mode * / # search for the current selection
local function visual_selection()
  local saved_reg = vim.fn.getreg('"')
  vim.cmd('normal! gvy')
  local pattern = vim.fn.escape(vim.fn.getreg('"'), '\\/.*$^~[]')
  pattern = pattern:gsub('\n$', '')
  vim.fn.setreg('"', saved_reg)
  vim.fn.setreg('/', pattern)
  vim.fn.search(pattern, 'W')
end
vim.keymap.set('x', '*', visual_selection, { desc = 'Search selected' })
vim.keymap.set('x', '#', visual_selection, { desc = 'Search selected backward' })

-- Sudo save with :W
vim.cmd('command! W execute \'w !sudo tee % > /dev/null\' <bar> edit!')

-- Strip trailing whitespace on save (ported from vimrc)
local function clean_extra_spaces()
  local save_cursor = vim.fn.getpos('.')
  local old_query = vim.fn.getreg('/')
  vim.cmd('silent! %s/\\s\\+$//e')
  vim.fn.setpos('.', save_cursor)
  vim.fn.setreg('/', old_query)
end
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.txt,*.js,*.py,*.wiki,*.sh,*.coffee,*.php',
  callback = clean_extra_spaces,
})