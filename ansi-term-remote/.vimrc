" looseleaf's .vimrc for remote sessions

filetype plugin indent on   " enable plugins related to the opened file's type and enable indentation
syntax enable               " enable syntax highlighting
set autoindent              " a new line is indented as far as the previous one
set bs=2                    " backspace over everything in insert mode; same as ":set backspace=indent,eol,start"
set complete-=i             " remove 'included files' from the list of autocomplete sources
set smarttab                " tab inserts spaces according to shiftwidth, tabstop, or softtabstop"
set timeout                 " enforce a timeout while waiting for a mapped sequence to complete
set timeoutlen=100          " time in milliseconds to wait for a mapped sequence to complete
set ttimeout                " enforce a timeout while waiting for a terminal UI mapped sequence to complete
set ttimeoutlen=100         " time in milliseconds to wait for a terminal UI mapped sequence to complete
set nrformats=              " treat all numerals as decimal (leading zeroes won't signify octal)
set incsearch               " as-you-type incremental searching
set laststatus=2            " always show status line
set ruler                   " enable the ruler
set wildmenu                " when tab completing commands, show available matches in a menu
set scrolloff=1             " minimal number of lines to keep above and below the cursor while scrolling"
set sidescrolloff=5         " minimal number of columns to keep to the left and right of the cursor while scrolling
set display+=lastline       " display as much as possible of the last (overly long) line
set formatoptions+=j        " delete comment character when joining commented lines
set autoread                " automatically re-read a file if it has been changed outside of vim"
set t_Co=16                 " 16 colors
set showcmd                 " always display the status line
set expandtab               " expand tabs to spaces
set ts=2                    " tabs are 2 spaces
set shiftwidth=2            " tabs under smart indent
set shiftround              " round indentation to a multiple of 'shiftwidth'
set smartindent             " enable intelligent indenting behavior
set hlsearch                " highlight located values being searched for
set ignorecase              " case insensitive searching
set history=1000            " increase the default number of remembered items from 20
set smartcase               " trigger case sensitivity when an upper case char is used
set nocindent               " disable c style indenting
set nobackup                " disable backups"
set nowritebackup           " disable backups"
set noswapfile              " disable the creation of .swp swap files
set numberwidth=5           " specify line numbers column width
set vb t_vb=                " disable bell
set noerrorbells            " don't make noise
set shiftround              " round indentation to a multiple of 'shiftwidth'
set nojoinspaces            " don't use extra space when joining lines (with J)
set ff=unix                 " unix fileformat
set nolist                  " disable the display of invisible characters
set nonu                    " don't display line numbers
set listchars=tab:»·,trail:•,eol:¬  " characters to display when showing invisibles

let mapleader = ","         " use a comma as the <Leader> character
:noremap <Leader>i :set list!<CR>       " toggle display of invisible characters

" instead of ctrl+w, letter, just do ctrl+letter
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" automatically leave paste mode after having pasted in text
au InsertLeave * silent! set nopaste

map <Leader>r ;redraw!<CR>              " redraw the current buffer
map w!! %!sudo tee > /dev/null %        " force a write if vim was launched without sudo
nmap <silent> <Leader>/ ;nohlsearch<CR> " clear currently displayed search highlighting

" use jk for Esc
imap jk <Esc>
vmap jk <Esc>

" immediately reselect text after indenting/outdenting
vnoremap < <gv
vnoremap > >gv

" vertical and horizontal split to new buffer
:noremap <Leader>v :below vnew<CR>
:noremap <Leader>h :below new<CR>

" open new horizonal split panes to the bottom and vertical panes to the right
set splitbelow
set splitright

" flip ; and : to enter command mode more easily
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;
