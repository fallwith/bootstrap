" vim:fdm=marker
scriptencoding utf-8        " encoding
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
" vim-diminactive: dim inactive windows
call minpac#add('blueyed/vim-diminactive')
" typescript-vim: functionality for TypeScript development
call minpac#add('leafgarland/typescript-vim')

" themes
call minpac#add('Lokaltog/vim-distinguished', {'branch': 'develop'})
" call minpac#add('challenger-deep-theme/vim', { 'as': 'challenger-deep'})
" TODO: minpac can't yet handle subdirectories
" call minpac#add('sonph/onehalf', {'rtp': 'vim/'})
" call minpac#add('chriskempson/tomorrow-theme, {'rtp': 'vim/colors', 'as': 'tomorrow-theme'})
" call minpac#add('felipesousa/rupza')
call minpac#add('nightsense/seabird')
call minpac#add('morhetz/gruvbox')
call minpac#add('NLKNguyen/papercolor-theme')
call minpac#add('nightsense/snow')
" call minpac#add('chriskempson/base16-vim')
" call minpac#add('arcticicestudio/nord-vim')
" call minpac#add('w0ng/vim-hybrid')
call minpac#add('KeitaNakamura/neodark.vim')

" nvim -c "call minpac#update('', {'do': 'quit'})"
"call minpac#update()

" remove packages with :call minpac#clean()
" }}}
" {{{ configuration
let mapleader = ','         " use a comma as the <Leader> character
" let g:ruby_path='~/bin/ruby'
let g:ruby_path='~/.asdf/shims/ruby'
let g:python_path='python3'
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set t_Co=256                " 256 colors
" set bg=dark                 " use dark background
set autowrite               " save on shell commands
set noerrorbells            " don't make noise
set showcmd                 " always display the status line
set ruler                   " enable the ruler
set timeoutlen=250          " time to wait after ESC
set expandtab               " expand tabs to spaces
set tabstop=2                    " tabs are 2 spaces
set backspace=2                    " backspace over everything in insert mode
set shiftwidth=2            " tabs under smart indent
set laststatus=2            " always show status line
set autoindent              " a new line is indented as far as the previous one
set hlsearch                " highlight located values being searched for
set ignorecase              " case insensitive searching
set smartcase               " trigger case sensitivity when an upper case char is used
set incsearch               " as-you-type searching
set nocindent               " disable c style indenting
set nobackup                " disable backups"
set nowritebackup           " disable backups"
set noswapfile              " disable the creation of .swp swap files
set number                  " enable line numbers
" set relativenumber          " enable relative line numbers
set numberwidth=5           " specify line numbers column width
set visualbell t_vb=        " disable bell
"set tags=.tags;/            " look for a .tags ctags file and keep looking all the way up to /
"set cursorline              " highlight the line the cursor resides on
set shiftround              " round indentation to a multiple of 'shiftwidth'
set wildmenu                " when tab completing commands, show available matches in a menu
set display+=lastline       " display as much as possible of the last (overly long) line
set history=1000            " increase the default number of remembered items from 20
set nojoinspaces            " don't use extra space when joining lines (with J)
set nrformats=              " treat all numerals as decimal (leading zeroes won't signify octal)
set pastetoggle=<F2>        " set a key to toggle paste mode
set colorcolumn=80,120      " (ruler) colorcolumn - (comma delimited) list of columns to visually style
set complete-=i             " remove 'included files' from the list of autocomplete sources
set clipboard=unnamed       " yank to / put from the operating system clipboard
set list                    " show invisibles
set fileformat=unix         " unix fileformat
set termguicolors           " enable gui colors in the terminal (true 24 bit color support)
set shell=/usr/local/bin/mksh
set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles
setglobal commentstring=#\ %s

" https://www.reddit.com/r/neovim/comments/ab01n8/improve_neovim_startup_by_60ms_for_free_on_macos/
let g:clipboard = {
  \ 'name': 'pbcopy',
  \ 'copy': {
  \    '+': 'pbcopy',
  \    '*': 'pbcopy',
  \  },
  \ 'paste': {
  \    '+': 'pbpaste',
  \    '*': 'pbpaste',
  \ },
  \ 'cache_enabled': 0,
  \ }

" hi ColorColumn guibg=grey13 ctermbg=246  " apply the desired visual styling to the colorcolumn
" colorscheme challenger_deep

set background=light
colorscheme seagull

" colorscheme gruvbox
" let g:gruvbox_contrast_dark = "hard"
" colorscheme hybrid

" colorscheme neodark
" let g:neodark#background = '#202020'
" let g:neodark#use_256color = 1
" let g:neodark#terminal_transparent = 1


" allow alacritty/kitty to retain transparency with (n)vim
" https://github.com/jwilm/alacritty/issues/1082
highlight Normal ctermbg=NONE guibg=NONE


" nvim colors the terminal with colorscheme values
" vim needs terminal_ansi_colors
if !has('nvim')
  let g:terminal_ansi_colors = [
              \ '#000000', '#d54e53', '#b9ca4a', '#e6c547',
              \ '#7aa6da', '#c397d8', '#70c0ba', '#ffffff',
              \ '#666666', '#ff3334', '#9ec400', '#e7c547',
              \ '#7aa6da', '#b77ee0', '#54ced6', '#ffffff'
              \]
endif

" }}}
" hooks / filetype specific {{{

" automatically leave paste mode after having pasted in text
" autocmd InsertLeave * silent! set nopaste

" Markdown files
" autocmd BufRead,BufNewFile *.md set colorcolumn=80

" Terraform templates
" autocmd FileType tf setlocal commentstring=#\ %s

" Git commit messages
augroup gitcommit
  autocmd Filetype gitcommit setlocal spell textwidth=72 colorcolumn=50,72
  if has('nvim') && executable('nvr')
    let $VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  endif
augroup END

" Terminal - close buffer on exit
autocmd TermClose * bd!

" }}}
" packages {{{
" fzf
set runtimepath+=/usr/local/opt/fzf
:noremap <Leader>f :FZF<CR>
:noremap <Leader>b :Buffers<CR>

" minpac
:noremap <Leader>m :call minpac#update()<CR>

" vim-grepper
let g:grepper = {}
let g:grepper.tools = ['rg']
nno <leader>g :Grepper -tool rg -highlight <CR>
cabbrev rg Grepper -tool rg -highlight <CR>

" vim-test
let g:test#runner_commands = ['RSpec']

" Lightline
" scheme list: https://github.com/itchyny/lightline.vim/tree/master/autoload/lightline/colorscheme
" let g:lightline = { 'colorscheme': 'challenger_deep' }
" let g:lightline = { 'colorscheme': 'wombat' }
" let g:lightline = { 'colorscheme': 'PaperColor_light' }
" let g:lightline = { 'colorscheme': 'nord' }
let g:lightline = { 'colorscheme': 'one' }

" ale
" check health with :ALEInfo
" fix issues with :ALEFix
let g:ale_linters = {
\ 'ruby': ['ruby', 'rubocop'],
\ 'vim': ['vint'],
\}
" Only run linters named in ale_linters settings.
let g:ale_linters_explicit = 1
" lint on text changed in Normal mode
let g:ale_lint_on_text_changed = 'normal'
" lint upon leaving Insert mode
let g:ale_lint_on_insert_leave = 1
" lint immediately
let g:ale_lint_delay = 0
" rubocop config
let g:ale_ruby_rubocop_executable = $HOME.'/.asdf/shims/rubocop'

" let g:ale_ruby_rubocop_options = '--parallel 4'
" \ 'javascript': ['eslint'],
" " \ 'ruby': ['ruby', 'rubocop'],
" \ 'go': ['gofmt', 'golint', 'go vet']
" let b:ale_fixers = {'javascript': ['prettier', 'eslint'],
" \                   'typescript': ['prettier', 'eslint']}
" let g:ale_fix_on_save = 1
" hi link ALEErrorLine ErrorMsg
" hi link ALEWarningLine WarningMsg
" let g:ale_lint_on_text_changed = 'normal'
" let g:ale_lint_on_insert_leave = 1
" let g:ale_lint_delay = 0

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

" vim-diminactive
let g:diminactive_use_syntax = 0

" }}}
" {{{ custom mappings
:noremap <Leader>i :set list!<CR>       " toggle display of invisibles
:noremap w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting
:noremap <Leader>r ;redraw!<CR>              " re-render the current window
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

" Z - cd to an fzf selected dir
function Zdir(path) abort
  exec 'cd ' . $HOME . '/' . a:path
endfunction
let Zfunc = function('Zdir')
command! -bang Z :call fzf#run({'source': 'fd -td -d1 . ~ ~/.config ~/git/public ~/git/private | sed "s|$HOME/||g"', 'sink': Zfunc})
