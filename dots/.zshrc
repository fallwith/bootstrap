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

  # fc
  # -l = display the command list
  # -1 0 = (when used with -l) build the list from the most recent command (-1)
  #        back to the oldest command (0)
  #
  # fzf
  # +s = sort the input (based on the zsh command number)
  # -x = extended-search mode
  # -e = enable exact match
  BUFFER=$(fc -l -1 0 | fzf +s -x -e --preview-window=hidden --height 40%)

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
alias z='cd $HOME/$(fd -td -d1 . ~ ~/.config ~/git | sed "s|$HOME/||g" | fzf +m --height 33% --border --layout=reverse)'
# }}}
alias running='ps auwx|egrep "memcache|mongo|mysql|rabbit|redis|postgres|ruby|rails|puma|node|\.rb|gradle"|egrep -v egrep'

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

# gitdiff
# gitdiff dev
# gitdiff d4a7b0d..519b30e
# gitdiff dev -- path/to/file
function gitdiff {
  nvim -c ":DiffviewOpen $@"
}

# convert *.cue/*.gdi/*.iso to *.chd
function chdit() {
  cue_file=$1
  chd_file=${cue_file:s/.cue/.chd}
  chd_file=${chd_file:s/.gdi/.chd}
  chd_file=${chd_file:s/.iso/.chd}
  chdman createcd -i "$cue_file" -o "$chd_file"
}

# convert any image to .png
function pngit() {
  file="$1"
  mogrify -format png "$file"
  rm -f "$file"
}
# }}}

# Homebrew {{{
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
if [ -z $LIBRARY_PATH ]; then
  export LIBRARY_PATH="$(brew --prefix)/lib"
else
  export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix)/lib"
fi
if [ -z $LD_LIBRARY_PATH ]; then
  export LD_LIBRARY_PATH="$(brew --prefix)/include"
else
  export LD_LIBRARY_PATH="$LD_LIBARY_PATH:$(brew --prefix)/include"
fi

# to start/stop a single service: brew services stop|start <service>
alias brewtaps='brew list --full-name | grep /'
alias servicesstart='brew services --all start'
alias servicesstop='brew services --all stop'
# }}}

# Python {{{
# pyver=$(ls ~/Library/Python|sort|tail -1)
PATH=~/Library/Python/3.12/bin:$PATH
# }}}

# asdf {{{
if [[ -e "/opt/homebrew/bin/asdf" ]]; then
  export ASDF_DATA_DIR="$HOME/.asdf"
  mkdir -p $ASDF_DATA_DIR
  export PATH="$ASDF_DATA_DIR/shims:$PATH"
  if [[ ! -e "$ASDF_DATA_DIR/completions/_asdf" ]]; then
    mkdir -p "$ASDF_DATA_DIR/completions"
    asdf completion zsh > "$ASDF_DATA_DIR/completions/_asdf"
  fi
  fpath=("$ASDF_DATA_DIR/completions" $fpath)
  plugins=('ruby' 'nodejs')
  for p in $plugins; do
    if [[ ! -e "$ASDF_DATA_DIR/plugins/$p" ]]; then
      asdf plugin add "$p"
    fi
  done
  export ASDF_NODEJS_AUTO_ENABLE_COREPACK=1
fi
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

if [[ ! -e "/opt/homebrew/bin/asdf" ]]; then
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

  function rubyinstall {
    ruby-install $1 -- --with-openssl-dir=$(brew --prefix openssl@3)
  }

  [[ -e ~/.ruby-version ]] && setruby $(<~/.ruby-version) >/dev/null
fi

function railsmin {
  bundle exec rails new $1 --api --minimal --skip-git \
  --skip-action-mailer --skip-action-cable \
  --skip-javascript --skip-test --skip-keeps \
  --skip-asset-pipeline --skip-hotwire --skip-jbuilder \
  --skip-decrypted-diffs
}

# installing Ruby from source...
# ./configure --with-opt-dir="$(brew --prefix openssl@3):$(brew --prefix readline):$(brew --prefix libyaml):$(brew --prefix gdbm)" --prefix="$HOME/.rubies/ruby-3.4.0-preview1" && make && make install
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
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
#  --color=fg:#575279,bg:#fffaf3,hl:#9893a5
#  --color=fg+:#797593,bg+:#faf4ed,hl+:#797593
#  --color=info:#56949f,prompt:#56949f,pointer:#907aa9
#  --color=marker:#d7827e,spinner:#b4637a,header:#d7827e"

# https://github.com/tinted-theming/tinted-fzf/blob/main/sh/base16-tomorrow-night.sh
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"\
" --color=bg+:#282a2e,bg:#1d1f21,spinner:#8abeb7,hl:#81a2be"\
" --color=fg:#b4b7b4,header:#81a2be,info:#f0c674,pointer:#8abeb7"\
" --color=marker:#8abeb7,fg+:#e0e0e0,prompt:#f0c674,hl+:#81a2be"
# }}}

# ugrep {{{
alias ug='noglob \ug'
alias eug='ug --perl-regexp'
alias aug'ug --all'
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

  rclone copy -P -vv --transfers 12 $src dropbox:"$dest"
}

function dropdown {
  local src=$1
  local dest=$2

  rclone copy -P -vv dropbox:$src "$dest"
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

# eza {{{
# --long: extended details and attributes
# --all: show hidden and dot files
# --group: display group owner
# --numeric: display the numeric id of each object's owner
# --classify: display type indicators (show a trailing slash for directories)
# --git: display the current git status for each object
# --time-style log-iso: desired timestamp format (default, iso, long-iso, full-iso)
## --colour-scale: color code the various file size ranges (best with dark backgrounds)
# --extended: reveal extended file attributes
alias ll='eza --long --all --group --numeric --classify --git --time-style long-iso'
alias lle='ll --extended'
# }}}

# Vim / Neovim {{{
function nvim_launch {
  declare -a args

  # if there were no arguments passed to this function...
  if [[ $# -eq 0 ]]; then
    # when called from a Neovim terminal session, use `nvr -o <file>` instead
    # of `nvim <file>` to open the file in a new split within the existing
    # session. `nvr` is the binary delivered by the neovim-remote Python egg.
    # `nvr -o`  requires an argument, so if there are no arguments present,
    # default to a single argument of '.' to have the Neovim split open a file
    # browser at PWD.
    if [[ -n $NVIM ]]; then args+=(.); fi
  else
    local path_arg="$1"               # grab the first argument
    shift                             # remove the first argument from $@
    elements=(${(s/:/)path_arg})      # split the first argument on ':'
    local file=${elements[@]:0:1}     # get the file value that precedes the ':' 
    args+=($file)                     # add the file to our args array
    local line_num=${elements[@]:1:1} # get the line value that follows the ':'
    if (( line_num )); then           # if the line value is set
      args+=("+$line_num")            #   add the '+' prefixed line to the
    fi                                #   args array
    args+=($@)                        # add original args 1..-1 to to args array
  fi

  # if called within a Neovim session, use `nvr` and otherwise use `\nvim`
  if [[ -n $NVIM ]]; then
    nvr -o $args
  else
    \nvim $args
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
alias dockerclean='docker ps -aq |xargs docker container stop; docker ps -aq |xargs docker container rm; docker images | grep latest | awk '"'"'{print $3}'"'"' | xargs docker image rm; docker volume prune --force; docker builder prune --force'
# TODO: 'docker volume ls' 
alias dockerwipe='docker images | awk '"'"'{print $3}'"'"' | xargs docker image rm --force; docker volume ls | tail -n+2 | awk '"'"'{print $2}'"'"'|xargs docker volume rm; dockerclean'
function pants {
  docker run --rm -it --mount "type=bind,source=$(pwd),target=/app" --name pants $1 bash
}
function rubypants {
  pants ruby:$1
}
# }}}

# GPG {{{
# after any gpg software updates, run: gpgconf --kill gpg-agent
alias gpgtest='echo testing | gpg --clearsign'
export GPG_TTY=$(tty)
# }}}

# TeX {{{
# brew install pandoc
# brew install basictex
# update PATH
# pandoc -V geometry:margin=1pt -s name.md -o name.pdf
if [[ -e /Library/TeX/texbin ]]; then
  export PATH=$PATH:/Library/TeX/texbin
fi
# }}}

# Completion {{{
zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' menu select

# https://thevaluable.dev/zsh-completion-guide-examples/
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''

# ssh
if [[ -f "$HOME/.ssh/config" ]]; then
  # build a list of hosts from the Host lines of ~/.ssh/config
  local hosts=(${${${(@M)${(f)"$(cat ~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
  # 'ssh <tab>' should assume the first argument is a host, not a username
  zstyle ':completion:*:ssh:argument-1:*' tag-order hosts
  # ignore all default host sources and user our hosts list instead
  zstyle ':completion:*:ssh:*' hosts $hosts
  unset hosts
fi

# cache
local zsh_cache_dir="$HOME/.cache/zsh"
local zsh_cache_file=.zcompdump
! [[ -e "$zsh_cache_dir" ]] && mkdir -p "$zsh_cache_dir"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$zsh_cache_dir/$zsh_cache_file"
autoload -Uz compinit
# if the cache file is younger than 24 hours, use it
if [[ -n $(find "$zsh_cache_dir" -name "$zsh_cache_file" -mtime -1d) ]]; then
  compinit -C -d "$zsh_cache_dir/$zsh_cache_file"
# else regenerate the cache file
else
  compinit -d "$zsh_cache_dir/$zsh_cache_file"
fi
unset zsh_cache_dir
unset zsh_cache_file
# }}}

# .zshrc_private {{{
[[ -e ~/.zshrc_private ]] && . ~/.zshrc_private
# }}}

# zprof
