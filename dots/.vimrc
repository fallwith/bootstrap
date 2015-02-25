" vim:fdm=marker
" fallwith's .vimrc - 2015-02-24

" references {{{
"   twerth's .vimrc:        https://github.com/twerth/dotfiles/blob/master/etc/vim/vimrc
"   railsjedi's .vimrc:     https://github.com/railsjedi/vimconfig/blob/master/vimrc
"   thoughtbot's .vimrc:    https://github.com/thoughtbot/dotfiles/blob/master/vimrc
"   astrails' dotvim:       https://github.com/astrails/dotvim#installation
"   timss' .vimrc:          https://github.com/timss/vimconf/blob/master/.vimrc
"   tpope's sensibilities:  https://github.com/tpope/vim-sensible
"   DanielFGray's guide:    https://gist.github.com/DanielFGray/6d81dbede41e93bbd803
"   Ben Klein's tricks:     http://blog.unixphilosopher.com/2015/02/five-weird-vim-tricks.html
" }}}
" vim-plug {{{

" :PlugInstall [name]  - install all / specified plugins
" :PlugUpdate          - install/update all / specified plugins
" :PlugClean[!]        - confirm (or auto-approve) removal of unused plugins
" :PlugUpgrade         - Upgrade vim-plug itself

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.vim/plugged')
" airline: a lightweight provider of a fancy status line
Plug 'bling/vim-airline'
" fugitive: allows for the use of Git from within Vim
Plug 'tpope/vim-fugitive'
" commentary: allows for the commenting/uncommenting of text
Plug 'tpope/vim-commentary'
" syntastic: a linter / code syntax checker wrapper
Plug 'scrooloose/syntastic', { 'for': 'ruby' }
" surround: add, remove, swap surroundings like quotes or braces
Plug 'tpope/vim-surround'
" tabular: automatically align blocks of text based on a delimiter
Plug 'godlygeek/tabular', { 'for': 'ruby' }
" delimitMate: automatically provides closing quotes and braces
Plug 'Raimondi/delimitMate'
" vim-ruby: powers Vim's Ruby editing support, bundle to fetch newer code that what Vim shipped with
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
" ctrl-p: fast, fuzzy finder for searching filesystems, buffers, and mru items
Plug 'kien/ctrlp.vim', { 'on': 'CtrlP' }
" vim-vinegar: netrw file browsing improvements
Plug 'tpope/vim-vinegar'
" vim-yankstack: more easily navigate through previous yanks
Plug 'maxbrunsfeld/vim-yankstack'
" vim-endwise: add helpful closing structures (like 'end') for Ruby and others
Plug 'tpope/vim-endwise'
" nerdtree: file explorer (netrw replacement)
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" vim-tmux-navigator: seamless navigation between Vim and Tmux splits
Plug 'christoomey/vim-tmux-navigator'
" vim-rspec: kick off rspec tests from within vim
Plug 'thoughtbot/vim-rspec', { 'for': 'ruby' }
" tslime: send output to a tmux session
Plug 'jgdavey/tslime.vim', { 'for': 'ruby' }

" themes
Plug 'nanotech/jellybeans.vim'
Plug 'morhetz/gruvbox'
Plug 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Plug 'w0ng/vim-hybrid'
Plug 'vim-scripts/wombat256.vim'
Plug 'garybernhardt/dotfiles', {'rtp': '.vim/'}
Plug 'Lokaltog/vim-distinguished'
Plug 'noahfrederick/vim-hemisu'
Plug 'zeis/vim-kolor'
Plug 'tomasr/molokai'
call plug#end()
" }}}
" {{{ basic configuation
let mapleader = ","         " use a comma as the <Leader> character
set nocompatible            " disable vi compatibilty
let g:ruby_path='~/bin/ruby22'  " dramatically improve Ruby syntax processing time by not using the system ruby
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
"colorscheme jellybeans      " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
"colorscheme Tomorrow-Night-Bright " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
"colorscheme distinguished   " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
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
set complete-=i             " remove 'included files' from the list of autocomplete sources
hi ColorColumn guibg=grey13 ctermbg=246  " apply the desired visual styling to the colorcolumn
set grepprg=ag\ --nogroup\ --nocolor      " use ag instead of grep
set viminfo+=n~/.vim/.viminfo             " store the vim info file beneath ~/.vim
" }}}
" gui specific {{{
if has('gui_running')
  colorscheme distinguished   " set default color scheme (ir_black, desert, jellybeans) :colorscheme<tab> for list
  set transparency=10                 " transparent background
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles

  "set guifont=Inconsolata:h14        " specify font family and size
  set guifont=Monaco:h11
  "set guifont=Menlo:h11
else
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
  " colorscheme Tomorrow-Night-Bright
  colorscheme distinguished
endif
" }}}
" {{{ filetype specific
au BufRead,BufNewFile *.md set filetype=markdown        " treat .md files as Markdown (not Modula)
" }}}
" {{{ custom mappings
:noremap <Leader>i :set nolist!<CR>     " toggle display of invisibles
map w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r ;source ~/.vimrc<CR>;filetype detect<CR>;exe ":echo 'vimrc reloaded'"<CR>

" Autocompletion
imap <S-Tab> <C-P>

" Convert arrow key presses into instructions
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" use jj for Esc
imap jj <Esc>

" immediately reselect text after indenting/outdenting
vnoremap < <gv
vnoremap > >gv

" flip ; and : to enter command mode more easily
nnoremap ; :
nnoremap : ;
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

" :Slate to open ~/.slate
:command! Slate :silent :e ~/.slate

" :Double and :Single to resize the window in gvim
:command! Double :silent :set columns=252 lines=60
:command! Single :silent :set columns=126 lines=50

" :Text / :Code behavior toggle
":command! Text :set wm=0 tw=119 fo+=walt wrap linebreak nolist
":command! Code :set wm=0 tw=0 fo-=walt nowrap nolinebreak list

" <leader>ag to prep a quickfix window based ag (silver searcher) search
:command! -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
nno <leader>ag :Ag<SPACE>
" }}}
" {{{ plugins / third-party tools
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
let g:syntastic_ruby_mri_exec = '~/bin/ruby22'
" use mri and rubocop checkers with ruby files
"let g:syntastic_ruby_checkers = ['mri', 'rubocop']

" VimSneak
let g:sneak#streak = 1

" Vinegar
autocmd FileType netrw nnoremap <silent> q :bd<CR>

" NERDTree
:noremap <C-n> :NERDTreeToggle<CR>

" CtrlP
" list buffers
:noremap <Leader>b :CtrlPBuffer<CR>
" list mru
:noremap <Leader>m :CtrlPMRU<CR>
" let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""' " use ag for CtrlP for listing files
let g:ctrlp_use_caching = 0 " ag is fast enough for CtrlP not to have to cache
let g:ctrlp_user_command = {
  \ 'types': {
    \ 1: ['.git', 'cd %s && git ls-files . --cached --exclude-standard --others'],
    \ },
  \ 'fallback': 'ag %s -l --nocolor -g ""'
  \ }

" Yankstack
let g:yankstack_map_keys = 0
call yankstack#setup()
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_newer_paste
:noremap <Leader>y :Yanks<CR>

" vim-rspec
let g:rspec_command = 'call Send_to_Tmux("bundle exec rspec {spec}\n")'
map <Leader>t ;call RunCurrentSpecFile()<CR>
map <Leader>s ;call RunNearestSpec()<CR>
map <Leader>l ;call RunLastSpec()<CR>
map <Leader>a ;call RunAllSpecs()<CR>
"let g:rspec_command = "!bundle exec rspec --tty --color --format documentation {spec}"

" Ranger
" from: http://www.reddit.com/r/vim/comments/2va2og/ranger_the_cli_file_manager_xpost_from/cog2ley
function! RangerChooser()
  let temp = tempname()
  exec 'silent !ranger --choosefiles=' . shellescape(temp)
  if !filereadable(temp)
    redraw!
    " Nothing to read.
    return
  endif
  let names = readfile(temp)
  if empty(names)
    redraw!
    " Nothing to open.
    return
  endif
  " Edit the first item.
  exec 'edit ' . fnameescape(names[0])
  " Add any remaning items to the arg list/buffer list.
  for name in names[1:]
    exec 'argadd ' . fnameescape(name)
  endfor
  redraw!
endfunction
nnoremap <leader>R :call RangerChooser()<CR>
" }}}
" {{{ .vimrc.last overrides
"if filereadable($HOME . "/.vimrc.last")
"  source $HOME/.vimrc.last
"else
"  call system("touch $HOME/.vimrc.last")
"endif
" }}}
