# enable vi key bindings (ESC+0, ESC+$ for start/end of line)
bindkey -v

# 0.1 sec delay between switching modes
export KEYTIMEOUT=1

# function to indicate the current vi mode (i = insert, n = normal)
VIMODE='i'
function zle-line-init zle-keymap-select {
 VIMODE="${${KEYMAP/vicmd/n}/(main|viins)/i}"
 zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init

# emacs bindings
# ctrl-r for history searching
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward
# ctrl-p and ctrl-n for previous and next command history cycling
bindkey -M viins '^P' up-history
bindkey -M viins '^N' down-history
# ctrl-a for beginning of line
bindkey -M viins '^a' beginning-of-line
bindkey -M vicmd '^a' beginning-of-line
# ctrl-e for end of line
bindkey -M viins '^e' end-of-line
bindkey -M vicmd '^e' end-of-line
# ctrl-d for forward delete
bindkey -M viins '^d' delete-char
bindkey -M vicmd '^d' delete-char

# allow ctrl-c to behave the same in normal mode as in insert mode
bindkey -M vicmd '^c' self-insert

# make backspace and ^h work after returning from command mode http://dougblack.io/words/zsh-vi-mode.html
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# edit the command line text in vi (as with Bash's <Ctrl-X> e)
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line
