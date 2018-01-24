source /usr/local/opt/fzf/shell/completion.zsh
source /usr/local/opt/fzf/shell/key-bindings.zsh

# adapted from https://gist.github.com/vlymar/4e43dbeae70ff71f861d
function gitadd() {
  # ls-files -m lists files with modifications
  # fzf-tmux -m select multiple files
  # fzf-tmux -d 15 creates a 15 line high horizontal split below
  git add $(git ls-files -m | fzf-tmux -m -d 15)
}


# https://github.com/junegunn/fzf/wiki/examples
function fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings
function fzf-history-widget-accept() {
  fzf-history-widget
  zle accept-line
}
zle -N fzf-history-widget-accept
bindkey '^X^R' fzf-history-widget-accept

# http://owen.cymru/fzf-ripgrep-navigate-with-bash-faster-than-ever-before/
export FZF_ALT_C_COMMAND="cd ~/; bfs -type d -nohidden | sed s/^\./~/"
