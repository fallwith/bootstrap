" james' .vimrc - 2014-03-02

" see twerth's .vimrc:     https://github.com/twerth/dotfiles/blob/master/etc/vim/vimrc
" see railsjedi's .vimrc:  https://github.com/railsjedi/vimconfig/blob/master/vimrc
" see thoughtbot's .vimrc: https://github.com/thoughtbot/dotfiles/blob/master/vimrc

" Vundle
"
" run :BundleInstall to install bundles, :BundleUpdate to update them, :BundleClean to remove them
"
" Automatic installation logic originally from:
"   http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
let bundleInstallNeeded=0
if !filereadable(expand('~/.vim/bundle/vundle/README.md'))
  echo 'Installing Vundle...'
  echo ''
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
  let bundleInstallNeeded=1
endif
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'rking/ag.vim'
Bundle 'wesgibbs/vim-irblack'
Bundle 'nanotech/jellybeans.vim'
Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-fugitive'
Bundle 'scrooloose/nerdcommenter'
Bundle 'mhinz/vim-startify'
Bundle 'techlivezheng/vim-plugin-minibufexpl'
if bundleInstallNeeded == 1
  echo 'Running :BundleInstall to install Vundle bundles...'
  echo ''
  :BundleInstall
endif

set nocompatible          " disable vi compatibilty
"filetype plugin indent on " autodetect file type, load plugins and indent settings
filetype plugin on        " autodetect file type, load appropriate plugins

syntax enable             " enable syntax highlighting
set t_Co=256              " 256 colors
colorscheme jellybeans    " set default color scheme (ir_black, desert)
set bg=dark               " use dark background

" GUI specific features
if has('gui_running')
  set transparency=10                 " transparent background
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles
  "set guifont=Inconsolata:h14         " specify font family and size
  "set guifont=Monaco:h12
  "set guifont=Menlo:h11
endif

set autowrite             " save on shell commands
set noerrorbells          " don't make noise
set showcmd               " always display the status line
set ruler                 " enable the ruler
set timeoutlen=250        " time to wait after ESC
set expandtab             " expand tabs to spaces
set ts=2                  " tabs are 2 spaces
set bs=2                  " backspace over everything in insert mode
set shiftwidth=2          " tabs under smart indent
set laststatus=2          " always show status line
"set autoindent            " a new line is indented as far as the previous one
"set smartindent           " enable intelligent indenting behavior
set hlsearch              " highlight located values being searched for
set ignorecase            " case insensitive searching
set smartcase             " trigger case sensitivity when an upper case char is used
set incsearch             " as-you-type searching
set nocindent             " disable c style indenting
set nobackup              " disable backups"
set nowritebackup         " disable backups"
set noswapfile            " disable the creation of .swp swap files
set nu                    " enable line numbers
set numberwidth=5         " specify line numbers column width
set vb t_vb=              " disable bell

let mapleader = ","

:noremap <Leader>i :set nolist!<CR>  " toggle display of invisibles

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

" Replicate textmate CMD-[ and CMD-] for indentation
nmap <D-[> <<
nmap <D-]> >>
vmap <D-[> <gv
vmap <D-]> >gv

" Replicate textmate shift arrow/movement in order to select stuff
nmap <S-up> vk
vmap <S-up> k
nmap <S-k> vk
vmap <S-k> k

nmap <S-right> vl
vmap <S-right> l
nmap <S-l> vl
vmap <S-l> l

nmap <S-down> vj
vmap <S-down> j
nmap <S-j> vj
vmap <S-j> j

nmap <S-left> v
vmap <S-left> h
nmap <S-h> vh
vmap <S-h> h

" Vertical and horizontal split then hop to a new buffer
:noremap <Leader>v :vsp^M^W^W<cr>
:noremap <Leader>h :split^M^W^W<cr>

" NERDTree
" don't autostart when vim is launched with a gui (only needed for vim-nerdtree-tabs)
" let g:nerdtree_tabs_open_on_gui_startup=0
" ctrl-n to toggle NERDTree
map <C-n> :NERDTreeToggle<CR>
" show hidden files
let NERDTreeShowHidden=1
" quit NERDTree if it is the last buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" splits
" instead of ctrl+w, letter, just do ctrl+letter
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

:noremap <Leader>l :CtrlPLine<CR>
:noremap <Leader>b :CtrlPBufTag<CR>

" use ag instead of grep
" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
if executable('ag')
" Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

" ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

let g:airline_theme='powerlineish'

let g:startify_unlisted_buffer=0

let g:startify_custom_header = [
\ '  \  /. _ _ ',
\ '   \/ || | |',
\ '',
\ '',
\ ]

