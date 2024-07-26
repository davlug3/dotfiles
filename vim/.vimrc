" Hello 
set history=500

filetype plugin on
filetype indent on

set autoread
au FocusGained,BufEnter * silent! checktime


" Saving shortcut
nmap <leader>w :w!<cr>

" sudo save with :W
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!


"""""""""""""""""""""""""""""""""""""""
" UI
""""""""""""""""""""""""""""""""""""
"
set scrolloff=3
set number
set wildmenu
set ruler
set cmdheight=1


" set hid

set backspace=eol,start,indent
set whichwrap+=<,>,h,l

set ignorecase
set smartcase
set hlsearch
set incsearch

"dont redraw while executing macros 
"i dont know this haha
set lazyredraw

"set magic for regex
set magic

set showmatch
set mat=2

set noerrorbells
set novisualbell
set t_vb=
set tm=500
"for macVim daw
if (has("gui_macvim"))
	autocmd GUIEnter * set vb t_vb=
endif

set foldcolumn=1




"""""""""""""""""""""""""""
"colors and fonts
""""""""""""""""""""""""
syntax enable
set regexpengine=0

if $COLORTERM == 'gnome_terminal'
	set t_Co=256
endif

try
	colorscheme slate
endtry

set background=dark


" Set extra options in GUI mode
if has("gui_running")
	set guioptions-=T
	set guioptions-=e
	set t_Co=256
	set guitablabel=%M\ %t
endif

set encoding=utf8

set ffs=unix,dos,mac


"""""""""""""""""""""""""
" files, backups and undo
"""""""""""""""""""""""""
set nobackup
set nowb
set noswapfile


"""""""""""""""""""""""""
" text, tab, indent
"""""""""""""""""""""""
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4

set lbr
set tw=500

set ai
set si
set wrap




"""""""""""""""""""""""""""""
" visual mode
"""""""""""""""""""""""""""""

"pressing * or # in visual mode searches for 
"current selection
vnoremap <silent> * : <C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # : <C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>


""""""""""""""""""""""""""""
" moving around, tabs, windows, buffers
""""""""""""""""""""""""""""

"disable highlight when leader-cr is pressed
map <silent> <leader><cr> :noh<cr>

"close current buffer
map <leader>bd :Bclose<cr>:tabclose<cr>gT

"close all buffers
map <leader>ba :bufdo bd<cr>

map <leader>l :bnext<cr>
map <leader>h :bprevious<cr>




""""""""""""""""""""""""""""""""
"status line""""""""
""""""""""""""""""""""""""

"always show status line
set laststatus=2
"
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

"""""""""""""""""""""""""
" editing mappings 
""""""""""""""""""
" Delete trailing whitespace on save
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

if has("autocmd")
    autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee,*.php :call CleanExtraSpaces()
endif





""""""""""""""""""""""""
"helper functions
""""""""""""""""


"returns true is paste mode is enabled

function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction 


function! CmdLine(str)
    call feedkeys(":" . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("Ack '" . l:pattern . "' " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

"""""""""""""""""""""""""""
"persistent undo""
""""""""""""""""""""""
try
    let undodir = '~/.vim/undo'

    " Check if the undo directory exists
    if !isdirectory(undodir)
        " Create the undo directory
        silent! call mkdri(undodir, 'p')
    endif

    " Set the undo directory and enable persistent undo
    execute 'set undodir=' . undodir
    set undofile

catch
endtry



"""""""""""""""""""""""""""""""""""""""
"plugins
"""""""""""""""""""""""""""""""""""""""

