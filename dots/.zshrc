# vim:fileencoding=utf-8:ft=conf:foldmethod=marker

# zmodload zsh/zprof

# Prompt {{{
# %F{} = set foreground color
#   - 098 = lavender
#   - 172 = orange
#   - 031 = green (last command succeeded)
#   - 174 = red (last command failed)
#   - reset = revert to the default foreground color
# %1~ = basename of pwd, replace $HOME with '~'
# %* = HH::MM::SS
# $ = literal '$'
# %(?.<success>.<failed>) = ternary conditional for the last command
PROMPT='%F{098}%1~ %F{172}%* %(?.%F{031}.%F{174})$ %F{reset}'
# }}}

# History {{{
# history env vars (man zshparam)
HISTSIZE=10000      # max entries for the history file
SAVEHIST=$HISTSIZE  # max entries for any given zsh session

# history options (man zshoptions)
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_FUNCTIONS
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

function _fuzzy_history {
  zle push-input
  BUFFER=$(fc -ln -1 0 | fzf --height 40%)

  # place the command on the command line with the cursor at the end of the line
  zle vi-fetch-history -n $BUFFER
  zle end-of-line
  zle reset-prompt

  # or... just execute the history command immediately
  # zle accept-line
}
zle -N _fuzzy_history
bindkey '^r' _fuzzy_history
# }}}

# Misc config / env vars {{{
VISUAL=nvim
EDITOR=$VISUAL
HISTEDIT=$EDITOR
MANWIDTH=80
LESSHISTFILE=-
if (( ${+KITTY_PID} )); then
  TERM=xterm-kitty
else
  TERM=xterm-256color
fi
PATH=~/bin:$PATH
setopt NOCLOBBER  # disable file clobbering
# }}}

# Misc aliases {{{
# prevent cp/mv from overwriting existing files
alias cp='cp -i'
alias mv='mv -i'

alias fd='fd --color never' # fd doesn't offer a config file
alias dirs='fd -td' # find . -type d -not -name .
alias font="kitty @ set-font-size"
alias matrix='cxxmatrix -c \#FFC0CB -s rain-forever --frame-rate=40 --preserve-background --no-twinkle --no-diffuse'
alias reload='. ~/.zshrc'
alias xattrdel='xattr -c -r'
alias z='cd $HOME/$(fd -td -d1 . ~ ~/.config ~/git/public ~/git/private | sed "s|$HOME/||g" | fzf +m --height 33% --border --layout=reverse)'
# }}}

# Functions {{{
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
  # alias port='sudo lsof -n -i | grep '
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

function keepemptydirs {
  root="$1"
  echo "Placing .keep files in any empty directories beneath '$root'..."
  find "$root" -type d -empty -exec touch {}/.keep \;
}

# }}}

# Python {{{
# pyver=$(ls ~/Library/Python|sort|tail -1)
PATH=~/Library/Python/3.9/bin:$PATH
# }}}

# Ruby {{{
alias b='bundle exec'
alias brake='noglob bundle exec rake'
alias bspec='b rspec'
alias defaultgems='cat $HOME/.default-gems | xargs -n 1 gem install'

function gemcd {
  cd `bundle info --path $1`
}
alias cdgem=gemcd

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

[[ -e ~/.ruby-version ]] && setruby $(<~/.ruby-version) >/dev/null
# }}}

# Go {{{
GOPATH=~/.go
PATH=$GOPATH/bin:$PATH
alias gom="gometalinter --enable-all --line-length=120 --deadline=180s ./..."
alias got='go test -v ./...'
# }}}

# FZF {{{
FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# https://github.com/rose-pine/fzf/blob/main/fzf-dawn.sh
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
 --color=fg:#575279,bg:#fffaf3,hl:#9893a5
 --color=fg+:#797593,bg+:#faf4ed,hl+:#797593
 --color=info:#56949f,prompt:#56949f,pointer:#907aa9
 --color=marker:#d7827e,spinner:#b4637a,header:#d7827e"
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

function rcopy {
  rclone sync --progress --transfers 8 --size-only "$1" "$2"
}
# }}}

# Rust {{{
[[ -e "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
# }}}

# Node {{{
# PATH="./node_modules/.bin:$PATH"
# }}}

# exa {{{
# --long: extended details and attributes
# --all: show hidden and dot files
# --group: display group owner
# --numeric: display the numeric id of each object's owner
# --classify: display type indicators (show a trailing slash for directories)
# --git: display the current git status for each object
# --time-style log-iso: desired timestamp format (default, iso, long-iso, full-iso)
## --colour-scale: color code the various file size ranges (best with dark backgrounds)
# --extended: reveal extended file attributes
alias ll='exa --long --all --group --numeric --classify --git --time-style long-iso'
alias lle='ll --extended'
# }}}

# Vim / Neovim {{{
function nvim_launch {
  if [[ -n $NVIM ]]; then
    if [[ $# -eq 0 ]]; then
      echo "you're already in Neovim..."
    else
      nvr -o "$@"
    fi
  else
    \nvim "$@"
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

# Docker {{{
alias dockerclean='docker ps -aq |xargs docker container stop; docker ps -aq |xargs docker container rm; docker images | grep latest | awk '"'"'{print $3}'"'"' | xargs docker image rm'
function pants {
  docker run --rm -it --mount "type=bind,source=$(pwd),target=/app" --name pants $1 bash
}
function rubypants {
  pants ruby:$1
}
# }}}

# Homebrew {{{
alias brewtaps='brew list --full-name | grep /'
alias servicesstart='brew services --all start'
alias servicesstop='brew services --all stop'
# }}}

# GPG {{{
# after any gpg software updates, run: gpgconf --kill gpg-agent
alias gpgtest='echo testing | gpg --clearsign'
export GPG_TTY=$(tty)
# }}}

# .zshrc_private {{{
[[ -e ~/.zshrc_private ]] && . ~/.zshrc_private
# }}}

# zprof
