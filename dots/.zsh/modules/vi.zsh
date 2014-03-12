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

# allow ctrl-r to search across history, as in emacs mode
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

# allow ctrl-c to behave the same in normal mode as in insert mode
bindkey -M vicmd '^c' self-insert

# make backspace and ^h work after returning from command mode http://dougblack.io/words/zsh-vi-mode.html
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
