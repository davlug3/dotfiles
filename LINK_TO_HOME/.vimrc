" Hello 
"
" My vimrc settings. I am just starting out using vim and tmux. be cool
"
" Aayusin ko pa to pag nagka time

set nocompatible
filetype plugin on

"install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tpope/vim-commentary'
Plug 'majutsushi/tagbar'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'christoomey/vim-tmux-navigator'

Plug 'neoclide/coc.nvim' , {'branch':'release'}
" Plug 'preservim/vimux'

" Plug 'prabirshrestha/vim-lsp'
" Plug 'mattn/vim-lsp-settings'
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Plug 'Quramy/tsuquyomi'

Plug 'mattn/emmet-vim'
"Plug 'Shougo/ddc.vim'
"Plug 'shun/ddc-vim-lsp'

Plug 'NLKNguyen/papercolor-theme'

call plug#end()

" function! s:on_lsp_buffer_enabled() abort
"     setlocal omnifunc=lsp#complete
"     setlocal signcolumn=yes
"     if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
"     nmap <buffer> gd <plug>(lsp-definition)
"     nmap <buffer> gs <plug>(lsp-document-symbol-search)
"     nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
"     nmap <buffer> gr <plug>(lsp-references)
"     nmap <buffer> gi <plug>(lsp-implementation)
"     nmap <buffer> gt <plug>(lsp-type-definition)
"     nmap <buffer> <leader>rn <plug>(lsp-rename)
"     nmap <buffer> <leader>g <plug>(lsp-document-diagnostics)
"     nmap <buffer> [g <plug>(lsp-previous-diagnostic)
"     nmap <buffer> ]g <plug>(lsp-next-diagnostic)
"     nmap <buffer> K <plug>(lsp-hover)
"    " nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
"    " nnoremap <buffer> <expr><c-d> lsp#scroll(-4)
"     nnoremap <buffer> <leader>f <expr> lsp#scroll(+4)
"     nnoremap <buffer> <leader>d <expr> lsp#scroll(-4)
"     nnoremap <buffer> <leader>d <expr> lsp#scroll(-4)
" 
"     let g:lsp_format_sync_timeout = 1000
"     autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
"     
"     " refer to doc to add more commands
" endfunction
" 
" augroup lsp_install
"     au!
"     " call s:on_lsp_buffer_enabled only for languages that has the server registered.
"     autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
" augroup END


" asyncmplete
" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"

" vim-lsp foldmethod
" set foldmethod=expr
"  \ foldexpr=lsp#ui#vim#folding#foldexpr()
"  \ foldtext=lsp#ui#vim#folding#foldtext()

""""""""""""""""""""""""""""""""""
"start here
""""""""""""""""""""""""""""""""""
set history=500
set autoread
au FocusGained,BufEnter * silent! checktime


" Saving shortcut
nmap <leader>w :w!<cr>

" Settings shortcut
nmap <leader>, :vs ~/.vimrc<cr>

" refresh haha
nmap <F5> :source ~/.vimrc<CR>


" Define a function to toggle between tabs and splits
function! ToggleTab()
    let num_windows = len(filter(tabpagebuflist(), 'bufwinnr(v:val) != -1'))
    
    if num_windows > 1
        tab split
    else
        tabclose
    endif
endfunction

" Map Ctrl+K Ctrl+M to call the ToggleTab function
nnoremap <C-k><C-m> :call ToggleTab()<CR>

" Map <leader>fs to fzf vs
nnoremap <leader>fs :Files<CR>:vertical split<CR>

" Map <leader>* to highlight word under cursor
" Hindi stable yung Lsp ehhh diko pa alam bakit
nnoremap <leader>* :<C-u>let @/ = expand('<cword>')<cr>

" change vsplit open in fzf window to ctrl s instead of ctrl v
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-s': 'vsplit' }

" sudo save with :W
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!


"""""""""""""""""""""""""""""""""""""""
" UI
""""""""""""""""""""""""""""""""""""
set scrolloff=3
set number
set wildmenu
set ruler
set cmdheight=1
set cursorline


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

set hidden

""""""""""""""""""""""""
syntax enable
set regexpengine=0

if $COLORTERM == 'gnome_terminal'
	set t_Co=256
endif

try
	colorscheme PaperColor
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





set tags=$HOME/.vim/system.tags,tags

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

nnoremap <Leader>b :buffers<CR>:buffer<Space>
"close current buffer
" map <leader>bd :Bclose<cr>:tabclose<cr>gT

"close all buffers
map <leader>ba :bufdo bd<cr>

map <leader>l :bnext<cr>
map <leader>h :bprevious<cr>



"Enable vim-tmux-navigator shortcuts 
"when on NERDtree
let g:NERDTreeMapJumpPrevSibling=""
let g:NERDTreeMapJumpNextSibling=""


"disable folding for vim-lsp
  let g:lsp_fold_enabled = 0
" let g:lsp_document_highlight_enabled = 1

" vim-lsp again
"      let g:lsp_diagnostics_signs_error = {'text': 'X'}
"      let g:lsp_diagnostics_signs_insert_mode_enabled = 1
"      let g:lsp_diagnostics_enabled = 1 
"      let g:lsp_diagnostics_echo_delay = 100
"      let g:lsp_diagnostics_echo_cursor = 1
"      let g:lsp_diagnostics_float_delay = 100
"      let g:lsp_diagnostics_float_cursor = 1
"      let g:lsp_diagnostics_virtual_text_enabled = 1
"      let g:lsp_diagnostics_virtual_text_delay = 200
"      let g:lsp_diagnostics_virtual_text_prefix = ">> "

" allow modifying the completeopt variable, or it will
" be overridden all the time
let g:asyncomplete_auto_completeopt = 0
set completeopt=menuone,noinsert,noselect,preview




highlight link LspErrorVirtualText DiffDelete
highlight link LspWarningVirtualText WildMenu
highlight link LspInformationVirtualText WarningMsg
highlight link LspHintVirtualText Conceal





let g:lsp_settings_filetype_vue = ['typescript-language-server', 'vls', 'html-languageserver']


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


nmap <F8> :TagbarToggle<CR>
nmap <F1> :Files<CR>
nmap <silent> <leader>1 :NERDTreeToggle<CR>

source ~/.vim/coc.nvim.vim


"""""""""""""""""""""""""""""""""""""
"Themes
"""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""
"Maps
"""""""""""""""""""""""""""""""""""""
