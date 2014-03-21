" fallwith's .vimrc - 2014-03-19

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
Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-commentary'
Bundle 'techlivezheng/vim-plugin-minibufexpl'
Bundle 'scrooloose/syntastic'
Bundle 'tpope/vim-surround'
Bundle 'godlygeek/tabular'
Bundle 'majutsushi/tagbar'
Bundle 'justinmk/vim-sneak'
Bundle 'vim-scripts/YankRing.vim'
Bundle 'kshenoy/vim-signature'
Bundle 'Yggdroot/indentLine'
" themes
Bundle 'nanotech/jellybeans.vim'
Bundle 'morhetz/gruvbox'
Bundle 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Bundle 'w0ng/vim-hybrid'
" Vundle bundles that only apply to / only work well with the gui
if has('gui_running')
  Bundle 'Raimondi/delimitMate'
endif
if bundleInstallNeeded == 1
  echo 'Running :BundleInstall to install Vundle bundles...'
  echo ''
  :BundleInstall
endif

set nocompatible            " disable vi compatibilty
filetype plugin on          " enable plugins related to the opened file's type

syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
colorscheme jellybeans      " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
set bg=dark                 " use dark background

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
set nojoinspaces          " don't use extra space when joining lines (with J)

let mapleader = ","

:noremap <Leader>i :set nolist!<CR>   " toggle display of invisibles

map w!! %!sudo tee > /dev/null %      " force a write if vim was launched without sudo

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

" Autocompletion
imap <S-Tab> <C-P>

" Convert arrow key presses into instructions
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Rulers (column highlights)
set cc=120
:hi ColorColumn guibg=grey13 ctermbg=246

" Markdown
command! Mou :silent :!open -a Mou.app '%:p'

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
" vertical and horizontal split to new buffer
:noremap <Leader>v :below vnew<CR>
:noremap <Leader>h :below new<CR>
" instead of ctrl+w, letter, just do ctrl+letter
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" open new horizonal split panes to the bottom and vertical panes to the right
set splitbelow
set splitright

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

" Tagbar
nmap <F8> :TagbarOpen fj<CR>

" Ctags
" create a Ruby project ctags file by passing the current file's path to the
" external 'rubyctags' script. (see https://gist.github.com/fallwith/9383650)
:command! Rubyctags !rubyctags %:p<CR>
:command! Rtags Rubyctags

" Tabular
" use tabular to align on equals signs and on colons (ruby 1.9+ style hashes)
nmap <Leader>a= :Tab/=<CR>
vmap <Leader>a= :Tab/=<CR>
nmap <Leader>a: :Tab/:\zs<CR>
vmap <Leader>a: :Tab/:\zs<CR>

"if filereadable($HOME . "/.vimrc.last")
"  source $HOME/.vimrc.last
"else
"  call system("touch $HOME/.vimrc.last")
"endif

" :S to quickly re-enable syntax highlighting
:command! S syntax on<CR>

" Syntastic
" bypass checking if :wq (or ZZ) is used
let g:syntastic_check_on_wq = 0
" specify which ruby to use (enforces MRI in JRuby projects)
let g:syntastic_ruby_mri_exec = '~/bin/ruby21'

" VimSneak
let g:sneak#streak = 1

" YankRing
let g:yankring_replace_n_pkey = '<leader>['
let g:yankring_replace_n_nkey = '<leader>]'
nmap <leader>y :YRShow<cr>
let g:yankring_history_dir = '~/.vim'
