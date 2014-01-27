" james' .vimrc - 2012-07-27

" see twerth's .vimrc:    https://github.com/twerth/dotfiles/blob/master/etc/vim/vimrc
" see railsjedi's .vimrc: https://github.com/railsjedi/vimconfig/blob/master/vimrc

" Vundle
" run :BundleInstall to install bundles, :BundleUpdate to update them, :BundleClean to remove them
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'rking/ag.vim'
Bundle 'wesgibbs/vim-irblack'
Bundle 'nanotech/jellybeans.vim'

" set runtimepath=$HOME/.vim,$VIMRUNTIME

" A vim function that keeps your state
" http://technotales.wordpress.com/2010/03/31/preserve
function! Preserve(command)
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " Do the business:
  execute a:command
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction

" Ruby: provide a clickable list of all lines in the current
" file that contain 'def '.
function! ListMethods()
  vimgrep /def /j %
  copen
endfunction
command! -bar -narg=0 Methods call ListMethods()

set nocompatible          " disable vi compatibilty
"filetype plugin indent on " autodetect file type, load plugins and indent settings

syntax enable             " enable syntax highlighting
set t_Co=256              " 256 colors
colorscheme jellybeans    " set default color scheme (ir_black, desert) 
" let g:solarized_termcolors=256
" let g:solarized_termtrans=1
" colorscheme solarized
set bg=dark               " use dark background

" GUI specific features
if has('gui_running')
  set transparency=10                 " transparent background (requires experimental renderer in MacVim)
  set list                            " show invisibles
  set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles
  set nu                              " enable line numbers
  set numberwidth=4                   " specify line numbers column width
  set guifont=Inconsolata:h14         " specify font family and size
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

" if /tmp is availabe, write backup/swap files there
if filewritable("/tmp")
  silent execute '!mkdir -p /tmp/vim'
  " delete any files older than n days
  silent execute '!find /tmp/vim -mtime +7 -exec rm {} \;'
  set directory=/tmp/vim
  set backupdir=/tmp/vim
endif

let mapleader = ","

:noremap <Leader>i :set nolist!<CR>  " toggle display of invisibles

set vb t_vb= " disable bell

" Leader-r reloads the vimrc -- making all changes active (have to save first)
map <silent> <Leader>r :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>:NERDTreeClose<CR>

map <S-Enter> O<ESC> " awesome, inserts new line without going into insert mode
map <Enter> o<ESC>

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

" strip away all trailing whitespace (hit shift + s quickly after the leader)
nmap <leader><S-s> :call Preserve("%s/\\s\\+$//e")<CR>

" pass the current script to ruby on F5
map <F5> :!ruby %<CR>

" Vertical and horizontal split then hop to a new buffer
:noremap <Leader>v :vsp^M^W^W<cr>
:noremap <Leader>h :split^M^W^W<cr>

