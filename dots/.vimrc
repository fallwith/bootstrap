" vim:fdm=marker
if has('nvim')
  let $VIMHOME = $HOME.'/.config/nvim'
else
  let $VIMHOME = $HOME.'/.vim'
endif

" minpac {{{
let $pacpath = $VIMHOME.'/pack/minpac/opt/minpac'
if empty(glob($pacpath))
  silent !mkdir -p $pacpath
  silent !git clone https://github.com/k-takata/minpac.git $pacpath
endif
packadd minpac
call minpac#init()
" minpac: minimal package manager
call minpac#add('k-takata/minpac', {'type': 'opt'})
" lightline: a lightweight provider of a fancy status line
call minpac#add('itchyny/lightline.vim')
" vim-commentary: allows for the commenting/uncommenting of text
call minpac#add('tpope/vim-commentary')
" vim-surround: add, remove, swap surroundings like quotes or braces
call minpac#add('tpope/vim-surround')
" vim-endwise: add helpful closing structures (like 'end') for Ruby and others
call minpac#add('tpope/vim-endwise')
" vim-go: functionality for go programming development
call minpac#add('fatih/vim-go')
" fzf: fuzzy finder integration for Vim
call minpac#add('junegunn/fzf.vim')
" ale is an async linter
call minpac#add('w0rp/ale')
" vim-grepper provides async grepping
call minpac#add('mhinz/vim-grepper')
" vim-test: run unit tests
call minpac#add('janko-m/vim-test')
" vim-wiki: offline wiki system for notes
call minpac#add('vimwiki/vimwiki')
" vim-vinegar: enhanced netrw file browsing
call minpac#add('tpope/vim-vinegar')

" themes
call minpac#add('Lokaltog/vim-distinguished', {'branch': 'develop'})
call minpac#add('challenger-deep-theme/vim', { 'as': 'challenger-deep'})
" TODO: minpac can't yet handle subdirectories
" call minpac#add('sonph/onehalf', {'rtp': 'vim/'})
" call minpac#add('chriskempson/tomorrow-theme, {'rtp': 'vim/colors', 'as': 'tomorrow-theme'})
call minpac#add('felipesousa/rupza')
call minpac#add('TroyFletcher/vim-colors-synthwave')
call minpac#add('nightsense/seabird')
call minpac#add('morhetz/gruvbox')
call minpac#add('NLKNguyen/papercolor-theme')
call minpac#add('chriskempson/base16-vim')

call minpac#update()
" remove packages with :call minpac#clean()
" }}}
" {{{ configuration
let mapleader = ","         " use a comma as the <Leader> character
set nocompatible            " disable vi compatibilty
let g:ruby_path='~/bin/ruby25'
let g:python_path='python3'
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
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
" set rnu                     " enable relative line numbers
set numberwidth=5           " specify line numbers column width
set vb t_vb=                " disable bell
"set tags=.tags;/            " look for a .tags ctags file and keep looking all the way up to /
set cursorline              " highlight the line the cursor resides on
set shiftround              " round indentation to a multiple of 'shiftwidth'
set wildmenu                " when tab completing commands, show available matches in a menu
set display+=lastline       " display as much as possible of the last (overly long) line
set history=1000            " increase the default number of remembered items from 20
set nojoinspaces            " don't use extra space when joining lines (with J)
set nrformats=              " treat all numerals as decimal (leading zeroes won't signify octal)
set pastetoggle=<F2>        " set a key to toggle paste mode
set cc=120                  " (ruler) colorcolumn. column 120 is visually styled
set complete-=i             " remove 'included files' from the list of autocomplete sources
set clipboard=unnamed       " yank to / put from the operating system clipboard
set list                    " show invisibles
set ff=unix                 " unix fileformat
set tgc                     " enable gui colors in the terminal (true 24 bit color support)
set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles
hi ColorColumn guibg=grey13 ctermbg=246  " apply the desired visual styling to the colorcolumn
" colorscheme challenger_deep
" colorscheme seagull
colorscheme gruvbox
let g:gruvbox_contrast_dark = "hard"

" disable the colorscheme's background (permits opacity with alacritty)
" highlight Normal ctermbg=NONE
" highlight nonText ctermbg=NONE
" highlight Normal guibg=NONE
" highlight nonText guibg=NONE

" }}}
" hooks / filetype specific {{{

" automatically leave paste mode after having pasted in text
au InsertLeave * silent! set nopaste

" Markdown files
au BufRead,BufNewFile *.md set cc=80

" Git commit messages
autocmd Filetype gitcommit setlocal spell textwidth=72 cc=50,72
if has('nvim') && executable('nvr')
  let $VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
endif

" }}}
" packages {{{
" fzf
set rtp+=/usr/local/opt/fzf
:noremap <Leader>f :FZF<CR>
:noremap <Leader>b :Buffers<CR>

" vim-grepper
let g:grepper = {}
let g:grepper.tools = ['rg']
nno <leader>g :Grepper -tool rg -highlight <CR>
cabbrev rg Grepper -tool rg -highlight <CR>

" vim-test
let g:test#runner_commands = ['RSpec']

" Lightline
" let g:lightline = { 'colorscheme': 'challenger_deep' }
let g:lightline = { 'colorscheme': 'wombat' }

" ale
" check health with :ALEInfo
let g:ale_linters = {
\ 'javascript': ['eslint'],
\ 'ruby': ['ruby', 'rubocop'],
\ 'go': ['gofmt', 'golint', 'go vet']
\}
" \ 'go': ['gofmt', 'golint', 'go vet']
" \ 'go': [],
let g:ale_ruby_rubocop_executable = 'bundle'
let g:ale_ruby_ruby_executable = expand("<sfile>:p:h").'/../../bin/ruby'
" let g:ale_java_javac_classpath = expand("<sfile>:p:h").'/../../.m2/repository'

" let g:ale_go_metalinter_executable = expand("<sfile>:p:h").'/../../.go/bin/gometalinter'
" let g:ale_go_golint_executable = expand("<sfile>:p:h").'/../../.go/bin/golint'
" let g:ale_go_gofmt_executable = '/usr/local/bin/gofmt'
" let g:ale_go_govet_executable = expand("<sfile>:p:h").'/../../.go/bin/govet'
" let g:ale_go_fmt_options = '-s'

" vim-go
let g:go_fmt_options = '-s'

" vimwiki
let g:vimwiki_list = [{'path': '~/.vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]

" }}}
" packages {{{
" fzf
set rtp+=/usr/local/opt/fzf
:noremap <Leader>f :FZF<CR>
:noremap <Leader>b :Buffers<CR>

" vim-grepper
let g:grepper = {}
let g:grepper.tools = ['rg']
nno <leader>g :Grepper -tool rg -highlight <CR>
cabbrev rg Grepper -tool rg -highlight <CR>

" vim-test
let g:test#runner_commands = ['RSpec']

" Lightline
" let g:lightline = { 'colorscheme': 'challenger_deep' }
let g:lightline = { 'colorscheme': 'wombat' }

" ale
" check health with :ALEInfo
let g:ale_linters = {
\ 'javascript': ['eslint'],
\ 'ruby': ['ruby', 'rubocop'],
\ 'go': ['gofmt', 'golint', 'go vet']
\}
" \ 'go': ['gofmt', 'golint', 'go vet']
" \ 'go': [],
let g:ale_ruby_rubocop_executable = 'bundle'
let g:ale_ruby_ruby_executable = $HOME.'/bin/ruby'
" let g:ale_ruby_ruby_executable = expand("<sfile>:p:h").'/../../bin/ruby'
" let g:ale_java_javac_classpath = expand("<sfile>:p:h").'/../../.m2/repository'

" let g:ale_go_metalinter_executable = expand("<sfile>:p:h").'/../../.go/bin/gometalinter'
" let g:ale_go_golint_executable = expand("<sfile>:p:h").'/../../.go/bin/golint'
" let g:ale_go_gofmt_executable = '/usr/local/bin/gofmt'
" let g:ale_go_govet_executable = expand("<sfile>:p:h").'/../../.go/bin/govet'
" let g:ale_go_fmt_options = '-s'

" vim-go
let g:go_fmt_options = '-s'

" vimwiki
let g:vimwiki_list = [{'path': '~/.vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]
" }}}
" {{{ custom mappings
:noremap <Leader>i :set list!<CR>       " toggle display of invisibles
map w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting
map <Leader>r ;redraw!<CR>              " re-render the current window
" alias ctrl-p to shift-tab for autocompletion
imap <S-Tab> <C-P>

" TODO: use the arrow keys for something useful
" nnoremap <Left> :echoe "Use h"<CR>
" nnoremap <Right> :echoe "Use l"<CR>
" nnoremap <Up> :echoe "Use k"<CR>
" nnoremap <Down> :echoe "Use j"<CR>

" use jk for Esc
imap jk <Esc>
vmap jk <Esc>

" immediately reselect text after indenting/outdenting
vnoremap < <gv
vnoremap > >gv

" flip ; and : to enter command mode more easily
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" splits resizing
nnoremap <Right> :vertical resize +2<CR>
nnoremap <Left> :vertical resize -2<CR>
nnoremap <Up> :resize +2<CR>
nnoremap <Down> :resize -2<CR>

" terminal
" C-o to switch to normal mode
tmap <C-o> <C-\><C-n>
" map <Leader>t ;split\|terminal<CR>
map <Leader>t ;terminal<CR>
" }}}
" {{{ tabs and splits

" tn to open a new tab
nnoremap <Leader>n :tabnew<CR>

" vertical and horizontal split to new buffer
:noremap <Leader>v :below vnew<CR>
:noremap <Leader>h :below new<CR>

" instead of ctrl+w, letter, just do ctrl+letter
nnoremap <C-H> <C-W><C-H>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>

" navigate away from a terminal window, escaping (C-O) first
" tnoremap <M-h> <C-O><C-W><C-H>
" tnoremap <M-j> <C-O><C-W><C-J>
" tnoremap <M-k> <C-O><C-W><C-K>
" tnoremap <M-l> <C-O><C-W><C-L>
" tnoremap <A-h> <C-O><C-W><C-H>
" tnoremap <A-j> <C-O><C-W><C-J>
" tnoremap <A-k> <C-O><C-W><C-K>
" tnoremap <A-l> <C-O><C-W><C-L>

" open new horizonal split panes to the bottom and vertical panes to the right
set splitbelow
set splitright

" }}}

" Z - cd to recent / frequent directories {{{
command! -nargs=* Z :call Z(<f-args>)
function! Z(...)
  if a:0 == 0
    let list = split(system('fasd -dlR'), '\n')
    let path = tlib#input#List('s', 'Select one', list)
  else
    let cmd = 'fasd -d -e printf'
    for arg in a:000
      let cmd = cmd . ' ' . arg
    endfor
    let path = system(cmd)
  endif
  if isdirectory(path)
    echo path
    exec 'cd ' . path
  endif
endfunction " }}}

" set pwd to the dir path for the file in the current buffer
" autocmd BufEnter * if expand('%:p:h') !~ '^/tmp' && expand('%:p:h') !~ '^scp://' | lcd %:p:h | endif
