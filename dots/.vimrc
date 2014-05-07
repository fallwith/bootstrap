" vim:fdm=marker
" fallwith's .vimrc - 2014-05-07

" references {{{
"   twerth's .vimrc:        https://github.com/twerth/dotfiles/blob/master/etc/vim/vimrc
"   railsjedi's .vimrc:     https://github.com/railsjedi/vimconfig/blob/master/vimrc
"   thoughtbot's .vimrc:    https://github.com/thoughtbot/dotfiles/blob/master/vimrc
"   astrails' dotvim:       https://github.com/astrails/dotvim#installation
"   timss' .vimrc:          https://github.com/timss/vimconf/blob/master/.vimrc
"   tpope's sensibilities:  https://github.com/tpope/vim-sensible
" }}}
" vundle {{{
"
" :PluginList          - list configured plugins
" :PluginInstall(!)    - install (update) plugins
" :PluginSearch(!) foo - search (or refresh cache first) for foo
" :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"
" Automatic installation logic originally from:
"   http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
let pluginInstallNeeded=0
if !filereadable(expand('~/.vim/bundle/vundle/README.md'))
  echo 'Installing Vundle...'
  echo ''
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
  let pluginInstallNeeded=1
endif
set rtp+=~/.vim/bundle/vundle/
call vundle#begin()
" vundle: keep Vundle itself up to date with Vundle
Plugin 'gmarik/vundle'
" airline: a lightweight provider of a fancy status line
Plugin 'bling/vim-airline'
" fugitive: allows for the use of Git from within Vim
Plugin 'tpope/vim-fugitive'
" commentary: allows for the commenting/uncommenting of text
Plugin 'tpope/vim-commentary'
" syntastic: a linter / code syntax checker wrapper
Plugin 'scrooloose/syntastic'
" surround: add, remove, swap surroundings like quotes or braces
Plugin 'tpope/vim-surround'
" tabular: automatically align blocks of text based on a delimiter
Plugin 'godlygeek/tabular'
" sneak: jump around the current buffer easily and precisely
Plugin 'justinmk/vim-sneak'
" delimitMate: automatically provides closing quotes and braces
Plugin 'Raimondi/delimitMate'
" vim-ruby: power Vim's Ruby support, bundle to fetch newer code that what Vim shipped with
Plugin 'vim-ruby/vim-ruby'
" ctrl-p: fast, fuzzy finder for searching filesystems, buffers, and mru items
Plugin 'kien/ctrlp.vim'
" vim-vinegar: netrw file browsing improvements
Plugin 'tpope/vim-vinegar'
" vim-yankstack: more easily navigate through previous yanks
Plugin 'maxbrunsfeld/vim-yankstack'
" vim-endwise: add helpful closing structures (like 'end') for Ruby and others
Plugin 'tpope/vim-endwise'

" themes
Plugin 'nanotech/jellybeans.vim'
Plugin 'morhetz/gruvbox'
Plugin 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Plugin 'w0ng/vim-hybrid'
Plugin 'vim-scripts/wombat256.vim'
Plugin 'garybernhardt/dotfiles', {'rtp': '.vim/'}
Plugin 'Lokaltog/vim-distinguished'
call vundle#end()
if pluginInstallNeeded == 1
  echo 'Running :PluginInstall to install plugins with Vundle...'
  echo ''
  :PluginInstall
endif
" }}}
" {{{ basic configuation
let mapleader = ","         " use a comma as the <Leader> character
set nocompatible            " disable vi compatibilty
let g:ruby_path='~/bin/ruby21'  " dramatically improve Ruby syntax processing time by not using the system ruby
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
"colorscheme jellybeans      " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
"colorscheme Tomorrow-Night-Bright " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
colorscheme distinguished   " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
set bg=dark                 " use dark background
set autowrite               " save on shell commands
set noerrorbells            " don't make noise
set showcmd                 " always display the status line
set ruler                   " enable the ruler
set timeoutlen=250          " time to wait after ESC
set expandtab               " expand tabs to spaces
set ts=2                    " tabs are 2 spaces
set bs=2                    " backspace over everything in insert mode
set shiftwidth=2            " tabs under smart indent
set laststatus=2            " always show status line
set autoindent              " a new line is indented as far as the previous one
set smartindent             " enable intelligent indenting behavior
set hlsearch                " highlight located values being searched for
set ignorecase              " case insensitive searching
set smartcase               " trigger case sensitivity when an upper case char is used
set incsearch               " as-you-type searching
set nocindent               " disable c style indenting
set nobackup                " disable backups"
set nowritebackup           " disable backups"
set noswapfile              " disable the creation of .swp swap files
set nu                      " enable line numbers
set numberwidth=5           " specify line numbers column width
set vb t_vb=                " disable bell
set tags=.tags;/            " look for a .tags ctags file and keep looking all the way up to /
set cursorline              " highlight the line the cursor resides on
set shiftround              " round indentation to a multiple of 'shiftwidth'
set wildmenu                " when tab completing commands, show available matches in a menu
set display+=lastline       " display as much as possible of the last (overly long) line
set history=1000            " increase the default number of remembered items from 20
set nojoinspaces            " don't use extra space when joining lines (with J)
set nrformats=              " treat all numerals as decimal (leading zeroes won't signify octal)
set pastetoggle=<F2>        " (for non gui Vim) hit F2 to toggle paste mode (which won't attempt to apply indentation)
set cc=120                  " (ruler) colorcolumn. column 120 is visually styled
hi ColorColumn guibg=grey13 ctermbg=246  " apply the desired visual styling to the colorcolumn
set grepprg=ag\ --nogroup\ --nocolor      " use ag instead of grep
set viminfo+=n~/.vim/.viminfo             " store the vim info file beneath ~/.vim
" }}}
" gui specific {{{
if has('gui_running')
  set transparency=10                 " transparent background
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles

  "set guifont=Inconsolata:h14        " specify font family and size
  set guifont=Monaco:h11
  "set guifont=Menlo:h11
else
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
endif
" }}}
" {{{ filetype specific
au BufRead,BufNewFile *.md set filetype=markdown        " treat .md files as Markdown (not Modula)
" }}}
" {{{ custom mappings
:noremap <Leader>i :set nolist!<CR>     " toggle display of invisibles
map w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ :nohlsearch<CR> " clear currently displayed search highlighting

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

" Autocompletion
imap <S-Tab> <C-P>

" Convert arrow key presses into instructions
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>
" }}}
" {{{ splits
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
" }}}
" {{{ custom commands
" Markdown
command! Mou :silent :!open -a Mou.app '%:p'

" Ctags
" create a Ruby project ctags file by passing the current file's path to the
" external 'rubyctags' script. (see https://gist.github.com/fallwith/9383650)
:command! Rubyctags !rubyctags %:p<CR>
:command! Rtags Rubyctags

" :S to quickly re-enable syntax highlighting
:command! S syntax on<CR>

" :Tig to launch Tig
:command! Tig :silent :!tig

" :Vimrc to open ~/.vimrc
:command! Vimrc :silent :e ~/.vimrc

" :Double and :Single to resize the window in gvim
:command! Double :silent :set columns=252 lines=60
:command! Single :silent :set columns=126 lines=50

" <leader>ag to prep a quickfix window based ag (silver searcher) search
:command! -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
nno <leader>ag :Ag<SPACE>

" }}}
" {{{ plugins
" Airline
let g:airline_theme='powerlineish'

" Tabular
" use tabular to align on equals signs and on colons (ruby 1.9+ style hashes)
nmap <Leader>a= :Tab/=<CR>
vmap <Leader>a= :Tab/=<CR>
nmap <Leader>a: :Tab/:\zs<CR>
vmap <Leader>a: :Tab/:\zs<CR>
nmap <Leader>a> :Tab/=><CR>
vmap <Leader>a> :Tab/=><CR>

" Syntastic
" bypass checking if :wq (or ZZ) is used
let g:syntastic_check_on_wq = 0
" specify which ruby to use (enforces MRI in JRuby projects)
let g:syntastic_ruby_mri_exec = '~/bin/ruby21'

" VimSneak
let g:sneak#streak = 1

" Vinegar
autocmd FileType netrw nnoremap <silent> q :bd<CR>

" CtrlP
" list buffers
:noremap <Leader>b :CtrlPBuffer<CR>
" list mru
:noremap <Leader>m :CtrlPMRU<CR>
" let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""' " use ag for CtrlP for listing files
let g:ctrlp_use_caching = 0 " ag is fast enough for CtrlP not to have to cache
let g:ctrlp_user_command = {
  \ 'types': {
    \ 1: ['.git', 'cd %s && git ls-files'],
    \ },
  \ 'fallback': 'ag %s -l --nocolor -g ""'
  \ }

" Yankstack
call yankstack#setup()
let g:yankstack_map_keys = 0
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_newer_paste
:noremap <Leader>y :Yanks<CR>
" }}}
" {{{ .vimrc.last overrides
"if filereadable($HOME . "/.vimrc.last")
"  source $HOME/.vimrc.last
"else
"  call system("touch $HOME/.vimrc.last")
"endif
" }}}
