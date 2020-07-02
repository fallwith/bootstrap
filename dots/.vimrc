" vim:fdm=marker
scriptencoding utf-8

" {{{ VIMHOME
if has('nvim')
  let $VIMHOME = $HOME.'/.config/nvim'
else
  let $VIMHOME = $HOME.'/.vim'
endif
" }}}
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
" vim-commentary: allows for the commenting/uncommenting of text
call minpac#add('tpope/vim-commentary')
" vim-surround: add, remove, swap surroundings like quotes or braces
call minpac#add('tpope/vim-surround')
" vim-endwise: add helpful closing structures (like 'end') for Ruby and others
call minpac#add('tpope/vim-endwise')
" vim-go: functionality for go programming development
" call minpac#add('fatih/vim-go')
" fzf: fuzzy finder integration for Vim
call minpac#add('junegunn/fzf.vim')
" ale is an async linter
call minpac#add('w0rp/ale')
" vim-test: run unit tests
call minpac#add('janko-m/vim-test')
" vim-wiki: offline wiki system for notes
call minpac#add('vimwiki/vimwiki')
" vim-vinegar: enhanced netrw file browsing
call minpac#add('tpope/vim-vinegar')
" typescript-vim: functionality for TypeScript development
" call minpac#add('leafgarland/typescript-vim')
" vim-hexokinase: display color previews inline
" call minpac#add('RRethy/vim-hexokinase')
" vim-fugitive: 'may very well be the best Git wrapper of all time'
call minpac#add('tpope/vim-fugitive')

" colorschemes
" call minpac#add('Lokaltog/vim-distinguished', {'branch': 'develop'})
call minpac#add('nightsense/seabird')
" call minpac#add('morhetz/gruvbox')
" call minpac#add('KeitaNakamura/neodark.vim')
" call minpac#add('ayu-theme/ayu-vim')
" call minpac#add('tssm/fairyfloss.vim')
" call minpac#add('jacoborus/tender.vim')
" call minpac#add('cocopon/iceberg.vim')
" call minpac#add('lifepillar/vim-solarized8')
" call minpac#add('bluz71/vim-nightfly-guicolors')
" call minpac#add('nightsense/cosmic_latte')

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
set autowrite               " save on shell commands
set noerrorbells            " don't make noise
set showcmd                 " always display the status line
set ruler                   " enable the ruler
set timeoutlen=250          " time to wait after ESC
set expandtab               " expand tabs to spaces
set tabstop=2               " tabs are 2 spaces
set backspace=2             " backspace over everything in insert mode
set shiftwidth=2            " tabs under smart indent
set laststatus=2            " always show status line
set autoindent              " a new line is indented as far as the previous one
set hlsearch                " highlight located values being searched for
set ignorecase              " case insensitive searching
set smartcase               " trigger case sensitivity when an upper case char is used
set incsearch               " show incremental matches while searching ( /<pattern> )
if has('nvim')
  set inccommand=nosplit    " show incremental results during a command ( :%s/<pattern> )
end
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
set shell=/usr/local/bin/mksh\ -l
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

" }}}
" {{{ colorscheme settings

" time changing colorscheme experiment...
" let thehour = strftime("%H")
" if thehour < 6 || thehour > 19
"   set background=dark
"   colorscheme gruvbox
" elseif thehour >= 5 && thehour < 17
"   set background=light
"   colorscheme seagull
" else
"   set background=light
"   colorscheme gruvbox
" endif

" set background=light
" colorscheme seagull

" gruvbox
" let g:gruvbox_contrast_dark='soft'
" let g:gruvbox_improved_strings=1
" let g:gruvbox_improved_warnings=1
" let g:gruvbox_italic=1

" set bg=dark
" colorscheme tender
set bg:light
" colorscheme cosmic_latte
colorscheme greygull

" gui
" set guifont=mononoki:h13
" set guioptions=

" set guifont=menonoki:h5

" if filereadable($HOME.'/.config/kitty/vimcolorscheme')
"   source ~/.config/kitty/vimcolorscheme
" else
"   set background=dark
"   colorscheme gruvbox
" end

" allow alacritty/kitty to retain transparency with (n)vim
" https://github.com/jwilm/alacritty/issues/1082
" highlight Normal ctermbg=NONE guibg=NONE
" highlight Normal ctermbg=NONE guibg=black
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

" Terminal - disable line numbers
"   this allows nested Vim sessions to have the correct column count line up
"   with the color column
if has('nvim')
  autocmd TermOpen * setlocal nonumber norelativenumber
endif

" Terminal - close buffer on exit
" prevents vim-test from working
" autocmd TermClose * bd!

" }}}
" packages {{{
" fzf
set runtimepath+=/usr/local/opt/fzf
:noremap <Leader>f :FZF<CR>
:noremap <Leader>b :Buffers<CR>
:noremap <Leader>g :Rg 

" minpac
:noremap <Leader>m :call minpac#update()<CR>
command! Minpacupdate :call minpac#update()
command! Minpacclean :call minpac#clean()

" vim-test
" by default all test tools are loaded. load only these:
let g:test#runner_commands = ['RSpec']
if filereadable($HOME.'/.asdf/shims/bundle')
  let g:test#ruby#rspec#executable = $HOME.'/.asdf/shims/bundle exec rspec'
endif
if has('nvim')
  let g:test#strategy = "neovim"
endif
" mappings
nno <leader>n :TestNearest<CR>
nno <leader>r :TestFile<CR>
nno <leader>l :TestLast<CR>
" nno <leader>a :TestSuite<CR>
nno <leader>o :TestVisit<CR>

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
" let g:ale_ruby_rubocop_executable = $HOME.'/.asdf/shims/rubocop'
" let g:ale_ruby_rubocop_executable = $HOME.'/.asdf/shims/bundle exec rubocop'
let g:ale_ruby_rubocop_executable = $HOME.'/.asdf/shims/bundle'

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

" " vim-go
" let g:go_fmt_options = '-s'

" vimwiki
let g:vimwiki_list = [{'path': '~/.vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]

" " vim-hexokinase
" let g:Hexokinase_virtualText = '██████'
" }}}
" {{{ custom mappings
:noremap <Leader>i :set list!<CR>       " toggle display of invisibles
:noremap w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting
" :noremap <Leader>r ;redraw!<CR>              " re-render the current window
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
nnoremap <Leader><Right> :vertical resize +2<CR>
nnoremap <Leader><Left> :vertical resize -2<CR>
nnoremap <Leader><Up> :resize +2<CR>
nnoremap <Leader><Down> :resize -2<CR>

" terminal
" C-o to switch to normal mode
tmap <C-o> <C-\><C-n>
map <Leader>t ;terminal<CR>
" }}}
" {{{ tabs and splits

" open a new tab
" nnoremap <Leader>n :tabnew<CR>

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
" {{{ functions
" Z - cd to an fzf selected dir
" function Zdir(path) abort
"   exec 'cd ' . $HOME . '/' . a:path
" endfunction
" let Zfunc = function('Zdir')
" command! -bang Z :call fzf#run({'source': 'fd -td -d1 . ~ ~/.config ~/git/public ~/git/private | sed "s|$HOME/||g"', 'sink': Zfunc})

" alt
function! AltCommand(path, vim_command)
  let l:alternate = system("alt " . a:path)
  if empty(l:alternate)
    echo "No alternate file found for " . a:path
  else
    exec a:vim_command . " " . l:alternate
  endif
endfunction
nnoremap <leader>a :call AltCommand(expand('%'), ':e')<CR>

" adapted from vim-rooter
function! ChangeDirectoryToProjectRoot()
  let b:path = expand('%:p')
  if empty(b:path) | let b:path = getcwd() | endif
  let root_path = getbufvar('%', 'rootPath')
  if !empty(root_path)
    execute 'lcd ' . root_path
    return
  endif
  let root_path = finddir('.git', escape(b:path, ' ').';')
  if empty(root_path) | return | endif
  let root_path = fnamemodify(root_path, ':p:h:h')
  if empty(root_path) | return | endif
  if root_path =~? '^term' | return | endif
  let root_path = fnameescape(root_path)
  call setbufvar('%', 'rootPath', root_path)
  execute 'lcd ' . root_path
endfunction
autocmd BufEnter * :call ChangeDirectoryToProjectRoot()
" }}}
