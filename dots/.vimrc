" vim:fdm=marker
scriptencoding utf-8

let $VIMHOME = $HOME.'/.vim'
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
" vim-repeat: use . to repeat plugin based operations
call minpac#add('tpope/vim-repeat')
" fzf: fuzzy finder integration for Vim
call minpac#add('junegunn/fzf.vim')
" ale is an async linter
call minpac#add('dense-analysis/ale')
" vim-wiki: offline wiki system for notes
call minpac#add('vimwiki/vimwiki')
" vim-vinegar: enhanced netrw file browsing
call minpac#add('tpope/vim-vinegar')

" colorschemes
call minpac#add('Lokaltog/vim-distinguished', {'branch': 'develop'})
call minpac#add('nightsense/seabird')
call minpac#add('morhetz/gruvbox')
call minpac#add('ayu-theme/ayu-vim')
call minpac#add('lifepillar/vim-solarized8')
call minpac#add('nightsense/cosmic_latte')
call minpac#add('jaredgorski/fogbell.vim')
call minpac#add('jsit/toast.vim')
call minpac#add('chriskempson/base16-vim')
call minpac#add('aonemd/kuroi.vim')
call minpac#add('zaki/zazen')
" }}}
" {{{ configuration
let mapleader = ','         " use a comma as the <Leader> character
let g:python_path='python3'
filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
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
set nocindent               " disable c style indenting
set nobackup                " disable backups"
set nowritebackup           " disable backups"
set noswapfile              " disable the creation of .swp swap files
set number                  " enable line numbers
set numberwidth=5           " specify line numbers column width
set visualbell t_vb=        " disable bell
set tags=.tags;/            " look for a .tags ctags file and keep looking all the way up to /
set shiftround              " round indentation to a multiple of 'shiftwidth'
set wildmenu                " when tab completing commands, show available matches in a menu
set display+=lastline       " display as much as possible of the last (overly long) line
set history=1000            " increase the default number of remembered items from 20
set nojoinspaces            " don't use extra space when joining lines (with J)
set nrformats=              " treat all numerals as decimal (leading zeroes won't signify octal)
set pastetoggle=<F2>        " set a key to toggle paste mode
set colorcolumn=80,120      " (ruler) colorcolumn - (comma delimited) list of columns to visually style
set complete-=i             " remove 'included files' from the list of autocomplete sources
set clipboard^=unnamed,unnamedplus  " cross-platform selection + system clipboard support
set list                    " show invisibles
set fileformat=unix         " unix fileformat
set termguicolors           " enable gui colors in the terminal (true 24 bit color support)
set shell=ksh\ -l
set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles
set spell                   " enable the spell checker
setglobal commentstring=#\ %s
" }}}
" {{{ colorscheme settings
set background:dark
colorscheme cosmic_latte

" allow alacritty/kitty to retain transparency with (n)vim
" https://github.com/jwilm/alacritty/issues/1082
" highlight Normal ctermbg=NONE guibg=NONE
" highlight Normal ctermbg=NONE guibg=black
highlight Normal ctermbg=NONE guibg=NONE

" colors for the terminal
let g:terminal_ansi_colors = [
            \ '#000000', '#d54e53', '#b9ca4a', '#e6c547',
            \ '#7aa6da', '#c397d8', '#70c0ba', '#ffffff',
            \ '#666666', '#ff3334', '#9ec400', '#e7c547',
            \ '#7aa6da', '#b77ee0', '#54ced6', '#ffffff'
            \]
" }}}
" hooks / filetype specific {{{
" Git commit messages
augroup gitcommit
  autocmd Filetype gitcommit setlocal spell textwidth=72 colorcolumn=50,72
augroup END

" Golang
" on save, replace the contents of the buffer with the result
" of passing them to gofmt. do so silently so that vim doesn't
" present the results of the external command. run 'edit' (:e)
" afterwards to refresh
augroup golang
  function! s:gofmt()
    !gofmt -w %
    edit
  endfunction
  autocmd BufWritePost *.go silent! call s:gofmt()
augroup END
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

" ale
" check health with :ALEInfo
" fix issues with :ALEFix
let g:ale_linters = {
\ 'ruby': ['ruby', 'rubocop'],
\ 'typescript': ['eslint', 'prettier'],
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
" lint on save
let g:ale_fixers = {
\ 'typescript': ['eslint', 'prettier'],
\}
let g:ale_fix_on_save = 1
let g:ale_linters_explicit = 1
" rubocop config
let g:ale_ruby_rubocop_executable = 'bundle'

" vimwiki
let g:vimwiki_list = [{'path': '~/.vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]
" }}}
" {{{ custom mappings
:noremap <Leader>i :set list!<CR>       " toggle display of invisibles
:noremap w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting
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

" vertical and horizontal split to new buffer
:noremap <Leader>v :below vnew<CR>
:noremap <Leader>h :below new<CR>

" instead of ctrl+w, letter, just do ctrl+letter
nnoremap <C-H> <C-W><C-H>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>

" open new horizonal split panes to the bottom and vertical panes to the right
set splitbelow
set splitright

" }}}
" {{{ functions

" adapted from vim-rooter
" function! ChangeDirectoryToProjectRoot()
"   let b:path = expand('%:p')
"   if empty(b:path) | let b:path = getcwd() | endif
"   let root_path = getbufvar('%', 'rootPath')
"   if !empty(root_path)
"     execute 'lcd ' . root_path
"     return
"   endif
"   let root_path = finddir('.git', escape(b:path, ' ').';')
"   if empty(root_path) | return | endif
"   let root_path = fnamemodify(root_path, ':p:h:h')
"   if empty(root_path) | return | endif
"   if root_path =~? '^term' | return | endif
"   let root_path = fnameescape(root_path)
"   call setbufvar('%', 'rootPath', root_path)
"   execute 'lcd ' . root_path
" endfunction
" autocmd BufEnter * :call ChangeDirectoryToProjectRoot()

command! Rtags :! rubyctags
" }}}
