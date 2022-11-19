# vim:fileencoding=utf-8:ft=conf:foldmethod=marker

# docs {{{
# ksh ('93)
#
# version info
# =
# To display the ksh version: ctrl-alt-v or ksh --version
#
# history
# =
# ctrl-p - previous command
# ctrl-n - next command (after hitting ctrl-p at least once)
# ctrl-r, <phrase> - recall most recent command containing the phrase
#                    for example: "ctrl-r, who" to find the last 'whoami'
# history - displays recorded history, with numbers
# r, space, <number> - re-execute the command for the given number
# }}}

# OS specific {{{
function running_debian {
  if [ -z $RUNNING_DEBIAN ]; then
    if (command -v apt-get >/dev/null); then
      export RUNNING_DEBIAN=1
    else
      export RUNNING_DEBIAN=0
    fi
  fi
  [[ $RUNNING_DEBUG -eq 1 ]]
}

# https://wilsonmar.github.io/maximum-limits/
if ! running_debian; then ulimit -n 12288; fi
# }}}

# Color {{{
# color  - bg - fg
# =
# black  - 40 - 30
# red    - 41 - 31
# green  - 42 - 32
# yellow - 43 - 33
# blue   - 44 - 34
# purple - 45 - 35
# cyan   - 46 - 36
# grey   - 47 - 37
# =
# use '\E[xxm' where xx is a foreground color, use '\E[0m' to reset
# echo '\E[35mpurple \E[32mgreen \E[36mcyan \E[0m'

# use tput setaf to access the base 16 colors
# RED=$(tput setaf 1)
# GRN=$(tput setaf 2)
# YLW=$(tput setaf 3)
# BLU=$(tput setaf 4)
# MGT=$(tput setaf 5)
# CYN=$(tput setaf 6)
# GRE=$(tput setaf 7)
# WHT=$(tput setaf 8)
# =
# REDBOLD=$(tput setaf 9)
# GRNBOLD=$(tput setaf 10)
# YLWBOLD=$(tput setaf 11)
# BLUBOLD=$(tput setaf 12)
# MGTBOLD=$(tput setaf 13)
# CYNBOLD=$(tput setaf 14)
# WHTBOLD=$(tput setaf 15)
# BLK=$(tput setaf 16)
# =
# RESET=$(tput sgr0)
# =
# echo "${MGT}magenta ${GRN}green ${CYN}cyan ${RESET}"
bgmode=dark
if [[ -e "$HOME/.bgmode" ]]; then
  bgmode=$(<~/.bgmode)
fi
# }}}

# Basics {{{
function _prompt_pwd {
  if [[ "$PWD" == "$HOME" ]]; then
    p='~'
  else
    p=${PWD##*/}
    p=${p:-/}
  fi
  echo $p
}
# export PS1=$'\E[35m$(_prompt_pwd) \E[32m$(date +%H:%M:%S) \E[36m$ \E[0m'
# BLU=$(tput setaf 39)
# BLU='[38;5;39m'
BLU='[38;5;6m'
# PNK=$(tput setaf 201)
# PNK='[38;5;201m'
PNK='[38;5;1m'
# PRP=$(tput setaf 105)
# PRP='[38;5;105m'
GRN='[38;5;2m'
# RESET=$(tput sgr0)
RESET='(B[m'
export PS1=$'${PNK}$(_prompt_pwd) ${GRN}$(date +%H:%M:%S) ${BLU}$ ${RESET}'

HISTFILE="$HOME/.ksh_history"
HISTSIZE=5000
export VISUAL="nvim"
export EDITOR="$VISUAL"
# constrain manpages to 80 columns
export MANWIDTH=80
# disable history for less
export LESSHISTFILE=-
if (command -v kitty >/dev/null); then
  export TERM=xterm-kitty
else
  export TERM=xterm-256color
fi
set -o emacs
set -o noclobber
export PATH=~/bin:$PATH
# }}}

# Aliases {{{
alias usage='du -sch .[!.]* * |sort -h'
# prevent cp/mv overwrites
alias cp='cp -i'
alias mv='mv -i'
# alias dirs='find . -type d -not -name .'
alias dirs='fd -td'
alias c=clear
alias h=fuzzy_history
if running_debian; then
  alias z='cd $HOME/$(fd -td -d1 . ~ ~/.config ~/git | sed "s|$HOME/||g" | fzf +m)'
else
  alias z='cd $HOME/$(fd -td -d1 . ~ ~/.config ~/git/public ~/git/private | sed "s|$HOME/||g" | fzf +m)'
fi
alias v='nvim_launch $(\nvim --headless --noplugin -co +q 2>&1 | grep -v "term://" | cut -d" " -f2- | tr -d "\r" | fzf +m)'
# BSD ls
# alias ll='ls -lGAFTh'
alias font="kitty @ set-font-size"
alias b='bundle exec'
alias brake='b rake'
alias bspec='b rspec'
# alias history='echo $(export FZF_DEFAULT_OPTS="--height 40% $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort +m"; fc -rnl 1 | perl -ne '\''print "$1\n" if!$u{/\s+(.*)/, $1}++'\'' | fzf)'
alias reload='. ~/.kshrc'
alias xattrdel='xattr -c -r'

# }}}

# Functions {{{
#
# fuzzy_history - use fzf for fuzzily searching through history and evaluating
#                 the selection made
#
#     NOTE: the ksh $HISTFILE file contains extra characters beyond what was
#           entered in on the command line, so fzf can't directly read in the
#           file contents with 'fzf <$HISTFILE'. instead, fc is used to list
#           the commands, which are then formatted and de-duped by awk before
#           being piped to fzf
#
#     typeset  = scope the $cmd variable to this function only
#
#     fc -rnl 1  = fc is a shell built-in alias for the shell built-in 'hist'
#                  history command
#                    -r = reverse the order of commands (so that the most
#                         recent command appears last)
#                    -n = suppress the line numbers from the output
#                    -l = list commands instead of supporting their editing
#                         and execution
#                     1 = the command number to start from on the list. 1 is
#                         the first command, so the complete recorded history
#                         will be listed
#
#     c=                 = assign the sub() result to variable c
#     gsub(/^\t/,"",$0)  = for each entire line of input referred to as $0,
#                          substitute (sub()) a replacement of an empty string
#                          ("") for a single leading tab character (^\t) if one
#                          is found at the start of the line
#     !x[$c]++           = "awk '!x[$0]++'" is a neat awk trick to remove
#                          duplicate lines from the given input which is
#                          modified here to operate on $c instead of $0, where
#                          $c holds the result of performing sub() on $0
#
#     fzf --no-sort --exact  = fzf (https://github.com/junegunn/fzf) is an
#                              interactive fuzzy finder tool
#                                --no-sort = don't apply any sorting to the
#                                            input, so that the chronological
#                                            command line history order is
#                                            preserved
#                                --exact = require an exact match within a list
#                                          item, so 'who' matches 'whoami' but
#                                          not '/web/host'
#
#     test -n  = ensure that the given string has a non zero length. if so,
#                evaluate (re-execute) the selected history command. if not,
#                finish without taking any action
#     
function fuzzy_history {
  typeset cmd=$(fc -rnl 1|awk '{c=sub(/^\t/,"",$0)}; !x[$c]++'|fzf --no-sort --exact)
  if test -n "$cmd"; then
    eval "$cmd"
  fi
}

function pidrunning {
  ps -p $1 >/dev/null
}

function fifteen {
  pid=$1
  for signal in 15 2 1 9; do
    cmd="kill -$signal $pid"
    echo $cmd
    eval $cmd
    for i in $(seq 20); do
      if ! (pidrunning $pid); then
        echo "pid $pid no longer exists"
        return 0
      fi
      sleep 0.1
    done
  done
  if (pidrunning $pid); then
    echo "pid $pid still exists"
  fi
}

# usage: upload <IP ADDRESS> <LOCAL PATH> <REMOTE PATH>
function upload {
  rsync --progress -avhLe ssh "$2" $1:"$3"
}

# usage: download <IP ADDRESS> <REMOTE PATH> <LOCAL PATH>
function download {
  rsync --progress --rsync-path="sudo rsync" -avhLe ssh $1:"$2" "$3"
}

# which process is using a port
function port {
  p=$1
  if [ "$p" == "" ]; then
    echo "port() - determine which process is using a port"
    echo "Usage: port <port number>"
    return
  fi
  lsof -i :$p
}

function fail {
  while "$@"; do :; done
}

function matrix {
  # color=$(shuf -i 1-255 -n 1)
  # cxxmatrix -s rain-forever -c $color
  cxxmatrix -c green -s rain-forever --rain-density=5 --frame-rate=40
}

function keepemptydirs {
  root="$1"
  echo "Placing .keep files in any empty directories beneath '$root'..."
  find "$root" -type d -empty -exec touch {}/.keep \;
}

# }}}

# Ruby {{{
function gemcd {
  cd `bundle info --path $1`
}
alias cdgem=gemcd

alias defaultgems='cat $HOME/.default-gems | xargs -n 1 gem install'

function __setrubypath {
  desired="$1"
  bin_path="$HOME/.rubies/$desired/bin"
  if [[ -e "$bin_path" ]]; then
    export PATH="$bin_path:$PATH"
    echo "Ruby set to $desired"
  else
    echo "Can't set Ruby to $desired - is it installed?"
  fi
  unset desired
  unset bin_path
}

function setruby {
  desired="$1"
  if [[ "$desired" == "" ]]; then
    if [[ -e .ruby-version ]]; then
      desired="$(cat .ruby-version)"
    else
      echo "No .ruby-version file found here."
      return
    fi
  fi
  if [[ $desired = jruby* ]] || [[ $desired = ruby* ]]; then
    __setrubypath "$desired"
  else
    __setrubypath "ruby-$desired"
  fi
  unset desired
}

setruby >/dev/null
# }}}

# python {{{
# pyver=$(ls ~/Library/Python|sort|tail -1)
export PATH=~/Library/Python/3.9/bin:$PATH
# }}}

# Go {{{
export GOPATH=~/.go
export PATH=$GOPATH/bin:$PATH
alias gom="gometalinter --enable-all --line-length=120 --deadline=180s ./..."
alias got='go test -v ./...'
# }}}

# FZF {{{
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
if [[ "$bgmode" == "light" ]]; then
  # paper color with an #eeeeee -> #ffffff bg swap
  # export FZF_DEFAULT_OPTS='--no-mouse
  #     --color=fg:#4d4d4c,bg:#ffffff,hl:#d7005f
  #     --color=fg+:#4d4d4c,bg+:#e8e8e8,hl+:#d7005f
  #     --color=info:#4271ae,prompt:#8959a8,pointer:#d7005f
  #     --color=marker:#4271ae,spinner:#4271ae,header:#4271ae'

  # base-16 black metal immortal
  # export FZF_DEFAULT_OPTS='--no-mouse
  #     --color=bg+:$#121212,bg:$#000000,spinner:$#aaaaaa,hl:$#888888
  #     --color=fg:$#999999,header:$#888888,info:$#556677,pointer:$#aaaaaa
  #     --color=marker:$#aaaaaa,fg+:$#999999,prompt:$#556677,hl+:$#888888'

  # base16 grayscale-dark
  # local color00='#101010'
  # local color01='#252525'
  # local color02='#464646'
  # local color03='#525252'
  # local color04='#ababab'
  # local color05='#b9b9b9'
  # local color06='#e3e3e3'
  # local color07='#f7f7f7'
  # local color08='#7c7c7c'
  # local color09='#999999'
  # local color0A='#a0a0a0'
  # local color0B='#8e8e8e'
  # local color0C='#868686'
  # local color0D='#686868'
  # local color0E='#747474'
  # local color0F='#5e5e5e'
  # export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"\
  # " --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D"\
  # " --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C"\
  # " --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"

  # base16 chalk
  local color00='#151515'
  local color01='#202020'
  local color02='#303030'
  local color03='#505050'
  local color04='#b0b0b0'
  local color05='#d0d0d0'
  local color06='#e0e0e0'
  local color07='#f5f5f5'
  local color08='#fb9fb1'
  local color09='#eda987'
  local color0A='#ddb26f'
  local color0B='#acc267'
  local color0C='#12cfc0'
  local color0D='#6fc2ef'
  local color0E='#e1a3ee'
  local color0F='#deaf8f'

  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"\
  " --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D"\
  " --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C"\
  " --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"
else
  export FZF_DEFAULT_OPTS='--no-mouse --color fg:-1,bg:-1,hl:230,fg+:3,bg+:233,hl+:229
      --color info:150,prompt:110,spinner:150,pointer:167,marker:174'
fi
# }}}

# ugrep {{{
alias eug='ug --perl-regexp'
alias eugrep=eug
# }}}

# rclone {{{
#   setup:
#      1. rclone config
#      2. n (new remote)
#      3. name the remote "dropbox"
#      4. type in "dropbox" for the type
#      5. blank for key
#      6. blank for secret
#      7. n to decline advanced setup
#      8. y for auto config
#      9. log in to Dropbox via webbrowser
#     10. grant permission to rclone
#     11. y to keep the new remote
#     12. q to quit config
function dropup {
  local src=$1
  local dest=$2

  cmd="rclone copy -P -vv $src dropbox:$dest"
  echo $cmd
  $cmd
}

function dropdown {
  local src=$1
  local dest=$2

  cmd="rclone copy -P -vv dropbox:$src $dest"
  echo $cmd
  $cmd
}
# }}}

# Rust {{{
[[ -e "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
# }}}

# Node {{{
# export PATH="./node_modules/.bin:$PATH"
# }}}

# exa {{{
# --long: extended details and attributes
# --all: show hidden and dot files
# --group: display group owner
# --numeric: display the numeric id of each object's owner
# --classify: display type indicators (show a trailing slash for directories)
# --git: display the current git status for each object
# --time-style log-iso: desired timestamp format (default, iso, long-iso, full-iso)
# --colour-scale: color code the various file size ranges
# --extended: reveal extended file attributes
alias ll='exa --long --all --group --numeric --classify --git --time-style long-iso --colour-scale'
alias lle='ll --extended'
# }}}

# Vim / Neovim {{{
if [ -n "$NVIM" ]; then
  nvim_target='nvr -o'
else
  nvim_target=\nvim
fi
function nvim_launch {
  if [[ -n $NVIM && "$#" -eq 0 ]]; then
    echo "you're already in neovim..."
  else
    $nvim_target "$@"
  fi
}
alias nvim=nvim_launch
alias n=nvim_launch
alias vi=nvim_launch
alias vim=nvim_launch
alias vimwiki="$nvim_target ~/.vimwiki/index.md"
alias vw=vimwiki
alias guide='$nvim_target ~/git/public/vim_guide/vim_guide.md'
alias no="nvr -o"
# }}}

# Memcached {{{
# alias memcachedstart='memcached -d -l localhost'
# function memcachedstop {
#   pid=$(ps auwx | grep 'memcached -d -l localhost' | grep -v grep | awk '{print $2}')
#   15 $pid
# }
# }}}

# Homebrew Services {{{
alias servicesstart='brew services --all start'
alias servicesstop='brew services --all stop'
# }}}

# GPG {{{

# after any gpg software updates, run: gpgconf --kill gpg-agent
alias gpgtest='echo testing | gpg --clearsign'
export GPG_TTY=$(tty)

# }}}

# Crostini {{{
# if (grep -q "^PRETTY_NAME=\"Debian" /etc/os-release 2>/dev/null); then
if running_debian; then
  # Linux ls
  alias ll='ls -lAFh --color --full-time'

  # https://snugug.com/musings/developing-on-chrome-os/
  function open {
    setsid nohup xdg-open $1 >/dev/null 2>/dev/null
  }
  # alias pbcopy='xclip -selection clipboard'
  # alias pbpaste='xclip -selection clipboard -o'
fi
# }}}

# .kshrc_private {{{
  if [ -e ~/.kshrc_private ]; then
    . ~/.kshrc_private
  fi
# }}}
