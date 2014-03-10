" fallwith's .vimrc - 2014-03-04

" references:
"   twerth's .vimrc:        https://github.com/twerth/dotfiles/blob/master/etc/vim/vimrc
"   railsjedi's .vimrc:     https://github.com/railsjedi/vimconfig/blob/master/vimrc
"   thoughtbot's .vimrc:    https://github.com/thoughtbot/dotfiles/blob/master/vimrc
"   astrails' dotvim:       https://github.com/astrails/dotvim#installation
"   timss' .vimrc:          https://github.com/timss/vimconf/blob/master/.vimrc
"   tpope's sensibilities:  https://github.com/tpope/vim-sensible

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
Bundle 'scrooloose/syntastic'
Bundle 'tpope/vim-surround'
Bundle 'godlygeek/tabular'
Bundle 'majutsushi/tagbar'
" Vundle bundles that only apply to / only work well with the gui
if has('gui_running')
  Bundle 'Raimondi/delimitMate'
endif
if bundleInstallNeeded == 1
  echo 'Running :BundleInstall to install Vundle bundles...'
  echo ''
  :BundleInstall
endif

set nocompatible          " disable vi compatibilty
filetype plugin on        " enable plugins related to the opened file's type

syntax enable             " enable syntax highlighting
set t_Co=256              " 256 colors
colorscheme jellybeans    " set default color scheme (ir_black, desert)
set bg=dark               " use dark background

" GUI specific features
if has('gui_running')
  set transparency=10                 " transparent background
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles

  "set guifont=Inconsolata:h14        " specify font family and size
  "set guifont=Monaco:h12
  "set guifont=Menlo:h11

  " indentation seems a bit odd outside of the gui
  filetype plugin indent on
else
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
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
set autoindent            " a new line is indented as far as the previous one
set smartindent           " enable intelligent indenting behavior
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
set tags=.tags;/          " look for a .tags ctags file and keep looking all the way up to /
set cursorline            " highlight the line the cursor resides on
set shiftround            " round indentation to a multiple of 'shiftwidth'
set wildmenu              " when tab completing commands, show available matches in a menu
set display+=lastline     " display as much as possible of the last (overly long) line
set history=1000          " increase the default number of remembered items from 20

let mapleader = ","

:noremap <Leader>i :set nolist!<CR>  " toggle display of invisibles

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

" Convert arrow key presses into instructions
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

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

" Rulers (column highlights)
set cc=120
:hi ColorColumn guibg=grey13 ctermbg=246

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

" CtrlP
" search for a fuzzily matching line within the current file
:noremap <Leader>l :CtrlPLine<CR>
" search for a fuzzily matching tag within the current buffer (method list)
:noremap <Leader>b :CtrlPBufTag<CR>

" ag (The Silver Searcher)
" https://github.com/ggreer/the_silver_searcher
if executable('ag')
  " use ag instead of grep
  set grepprg=ag\ --nogroup\ --nocolor

  " use ag for CtrlP for listing files
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough for CtrlP not to have to cache
  let g:ctrlp_use_caching = 0
endif

" Airline
let g:airline_theme='powerlineish'

" Startify
let g:startify_unlisted_buffer=0
let g:ctrlp_reuse_window = 'startify'
" put customizations in ~/.vimrc.last

" Tagbar
nmap <F8> :TagbarOpen fj<CR>

" Ctags
" create a Ruby project ctags file by passing the current file's path to the
" external 'rubyctags' script. (see https://gist.github.com/fallwith/9383650)
:command Rubyctags !rubyctags %:p<CR>
:command Rtags Rubyctags

" Tabular
" use tabular to align on equals signs and on colons (ruby 1.9+ style hashes)
nmap <Leader>a= :Tab/=<CR>
vmap <Leader>a= :Tab/=<CR>
nmap <Leader>a: :Tab/:\zs<CR>
vmap <Leader>a: :Tab/:\zs<CR>

if filereadable($HOME . "/.vimrc.last")
  source $HOME/.vimrc.last
else
  call system("touch $HOME/.vimrc.last")
endif

