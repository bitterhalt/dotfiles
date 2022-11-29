call plug#begin("~/.config/vim/plugged")
Plug 'ap/vim-css-color'
Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'
Plug 'mhinz/vim-startify'
Plug 'vifm/vifm.vim'
Plug 'vimwiki/vimwiki'
Plug 'PotatoesMaster/i3-vim-syntax'
call plug#end()

" The lightline.vim theme
let g:lightline = {
      \ 'colorscheme': 'one',
      \ }
" Tweaks for Onedark
if (empty($TMUX))
  if (has("nvim"))
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
 if (has("termguicolors"))
    set termguicolors
  endif
endif


" highlight syntax
let mapleader="," "Maps Leader to space
syntax on
colorscheme onedark

" show line numbers 
set number 
" disable the swapfile
set noswapfile

" highlight all results
set hlsearch 

" ignore case in search
set ignorecase 
" show search results as you type
set incsearch

" Speed up scrolling in Vim
set ttyfast

" Status bar
set laststatus=2
" 
set history=50
 
" Set combatibility to Vim only
set nocompatible

" No auto backups
set nobackup

" Enable mouse
set mouse=a
set clipboard=unnamedplus
set t_Co=256

 " Vifm 
map <Leader>vv :Vifm<CR>
map <Leader>vs :VsplitVifm<CR>
map <Leader>sp :SplitVifm<CR>
map <Leader>dv :DiffVifm<CR>
map <Leader>tb :TabVifm<CR>

" Buffer helpers
nnoremap <Leader>b :ls<CR>:b<Space>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Move to the next buffer
nmap <Leader>l :bnext<CR>

" Move to the previous buffer
nmap <leader>h :bprevious<CR>

set wildmenu
set wildmode=full
set wildoptions+=pum

" session helper
let g:sessions_dir = '~/vim-sessions'
exec 'nnoremap <Leader>ss :mks! ' . g:sessions_dir. '/*.vim<C-D><BS><BS><BS><BS><BS>'
exec 'nnoremap <Leader>sr :so ' . g:sessions_dir. '/*.vim<C-D><BS><BS><BS><BS><BS>'

