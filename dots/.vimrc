" vim:fdm=marker
" fallwith's .vimrc - 2014-04-04

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
" vundle: keep Vundle itself up to date with Vundle
Bundle 'gmarik/vundle'
" airline: a lightweight provider of a fancy status line
Bundle 'bling/vim-airline'
" fugitive: allows for the use of Git from within Vim
Bundle 'tpope/vim-fugitive'
" commentary: allows for the commenting/uncommenting of text
Bundle 'tpope/vim-commentary'
" syntastic: a linter / code syntax checker wrapper
Bundle 'scrooloose/syntastic'
" surround: add, remove, swap surroundings like quotes or braces
Bundle 'tpope/vim-surround'
" tabular: automatically align blocks of text based on a delimiter
Bundle 'godlygeek/tabular'
" sneak: jump around the current buffer easily and precisely
Bundle 'justinmk/vim-sneak'
" delimitMate: automatically provides closing quotes and braces
Bundle 'Raimondi/delimitMate'
" vimproc: offers async processing for other plugins
"   after bundling vimproc: cd ~/.vim/bundle/vimproc.vim && make
Bundle 'Shougo/vimproc.vim'
" neomru: interface to the most recently used files
Bundle 'Shougo/neomru.vim'
" unite: unites a variety of functionality with a common interface
"   async fuzzy find, mru, buffer list, yank register list, dir browsing, etc.
Bundle 'Shougo/unite.vim'
" themes
Bundle 'nanotech/jellybeans.vim'
Bundle 'morhetz/gruvbox'
Bundle 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Bundle 'w0ng/vim-hybrid'
if bundleInstallNeeded == 1
  echo 'Running :BundleInstall to install Vundle bundles...'
  echo ''
  :BundleInstall
endif
" }}}
" {{{ basic configuation
let mapleader = ","         " use a comma as the <Leader> character
set nocompatible            " disable vi compatibilty
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
colorscheme jellybeans      " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
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
:hi ColorColumn guibg=grey13 ctermbg=246  " apply the desired visual styling to the colorcolumn
set grepprg=ag\ --nogroup\ --nocolor      " use ag instead of grep
set viminfo+=n~/.vim/.viminfo             " store the vim info file beneath ~/.vim
" }}}
" gui specific {{{
if has('gui_running')
  set transparency=10                 " transparent background
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles

  "set guifont=Inconsolata:h14        " specify font family and size
  "set guifont=Monaco:h12
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

" Unite
" <C-p> = interactive file finder
map <C-p> :<C-u>Unite -start-insert -buffer-name=files file_rec/async:!<CR>
" default to using fuzzy matching
call unite#filters#matcher_default#use(['matcher_fuzzy'])
" default to using the 'sorter_rank' rank logic
call unite#filters#sorter_default#use(['sorter_rank'])
call unite#custom#source('file_rec/async','sorters','sorter_rank')
" <Leader>b = list buffers in an interactive menu
:noremap <Leader>b :Unite buffer<CR>
" <C-n> = interactive filesystem browser
map <C-n> :Unite file<CR>
" <Leader>y = search through yank history
let g:unite_source_history_yank_enable = 1
nnoremap <leader>y :<C-u>Unite history/yank<CR>
" most recently used files
:noremap <Leader>m :Unite -start-insert file_mru<CR>
" use ag for searching
let g:unite_source_grep_command = 'ag'
let g:unite_source_grep_default_opts = '--nocolor --nogroup --column'
let g:unite_source_grep_recursive_opt = ''
" <Leader>ag = interactive front-end to ag searching
nno <leader>ag :<C-u>Unite grep -start-insert -default-action=above -auto-preview<CR>
" settings
function! s:unite_settings()
  " use C-k and C-j for up/down navigation
  imap <buffer> <C-k>   <Plug>(unite_select_previous_line)
  imap <buffer> <C-j>   <Plug>(unite_select_next_line)
  " use C-h, C-v, and C-t to open the selection in a split or a tab
  imap <silent><buffer><expr> <C-h> unite#do_action('split')
  imap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
  imap <silent><buffer><expr> <C-t> unite#do_action('tabopen')
  " exit if ESC is pressed
  nmap <buffer> <ESC> <Plug>(unite_exit)
endfunction
" }}}
" {{{ .vimrc.last overrides
"if filereadable($HOME . "/.vimrc.last")
"  source $HOME/.vimrc.last
"else
"  call system("touch $HOME/.vimrc.last")
"endif
" }}}
