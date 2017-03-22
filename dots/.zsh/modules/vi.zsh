# enable vi key bindings (ESC+0, ESC+$ for start/end of line)
bindkey -v

# time to wait before assuming that key input is complete (allows more time for 'jk' input)
export KEYTIMEOUT=15

# function to indicate the current vi mode (i = insert, n = normal)
# VIMODE='i'
function zle-line-init zle-keymap-select {
 if [[ "$KEYMAP" = "vicmd" ]]; then
   VIMODE=n
 elif [[ "$KEYMAP" = "vivis" ]]; then
   VIMODE=v
 else
   VIMODE=i
 fi
 # VIMODE="${${KEYMAP/vicmd/n}/(main|viins)/i}"
 zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init

# use 'jk' to switch to normal/command mode from insert mode
bindkey -M viins jk vi-cmd-mode

# emacs bindings
# ctrl-r/s for history searching
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward
bindkey -M viins '^s' history-incremental-search-forward
bindkey -M vicmd '^s' history-incremental-search-forward
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
# ctrl-f for forward movement
bindkey -M viins '^f' forward-char
# ctrl-o for backward movement (to not conflict with tmux's own ctrl-b)
bindkey -M viins '^o' backward-char
# alt-f/b/d to move forward/backward/delete a word
bindkey -M viins '\ef' forward-word
bindkey -M vicmd '\ef' forward-word
bindkey -M viins '\eb' backward-word
bindkey -M vicmd '\eb' backward-word
bindkey -M viins '\ed' kill-word
bindkey -M vicmd '\ed' kill-word

# allow ctrl-c to behave the same in normal mode as in insert mode
bindkey -M vicmd '^c' self-insert

# make backspace and ^h work after returning from command mode http://dougblack.io/words/zsh-vi-mode.html
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# visual mode support, adapted from https://github.com/b4b4r07/zsh-vimode-visual
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bindkey -N vivis

function vi-visual-highlight() {
  integer CURSOR_HL MARK_HL

  if [[ $CURSOR -gt $MARK ]];then
    (( CURSOR_HL = CURSOR + 1 ))
    __regstart=$MARK
    __regend=$CURSOR_HL
    region_highlight=("${MARK} ${CURSOR_HL} standout")
  elif [[ $MARK -gt $CURSOR ]];then
    (( MARK_HL = MARK + 1 ))
    __regstart=$CURSOR
    __regend=$MARK_HL
    region_highlight=("${CURSOR} ${MARK_HL} standout")
  elif [[ $MARK -eq $CURSOR ]];then
    __regstart=$CURSOR
    __regend=$MARK
    region_highlight=("${CURSOR} ${MARK} standout")
  fi
}
zle -N vi-visual-highlight

function vi-visual-mode() {
  zle -K vivis
  MARK=$CURSOR
  zle vi-visual-highlight
}
zle -N vi-visual-mode

function vi-visual-exit() {
  region_highlight=("0 0 standout")
  (( CURSOR = CURSOR + 1 ))
  MARK=0
  __regstart=0
  __regend=0
  zle .vi-cmd-mode
}
zle -N vi-visual-exit

function vi-visual-forward-word-end() {
  zle .vi-forward-word-end
  zle vi-visual-highlight
}
zle -N vi-visual-forward-word-end

function vi-visual-find-next-char() {
  zle .vi-find-next-char
  zle vi-visual-highlight
}
zle -N vi-visual-find-next-char

function vi-visual-backward-char() {
  zle .vi-backward-char
  zle vi-visual-highlight
}
zle -N vi-visual-backward-char

function vi-visual-forward-char() {
  zle .vi-forward-char
  zle vi-visual-highlight
}
zle -N vi-visual-forward-char

function vi-visual-find-next-char-skip() {
  zle .vi-find-next-char-skip
  zle vi-visual-highlight
}
zle -N vi-visual-find-next-char-skip

function vi-visual-yank() {
  if [[ $__regstart == $__regend ]]; then
    zle .vi-yank
    zle vi-visual-exit
  else
    zle .copy-region-as-kill "$BUFFER[${__regstart}+1,${__regend}]"
    zle vi-visual-exit
  fi
  printf -- "$CUTBUFFER" | pbcopy
}
zle -N vi-visual-yank

function vi-visual-eol() {
  zle .vi-end-of-line
  zle .vi-backward-char
  zle vi-visual-highlight
}
zle -N vi-visual-eol

bindkey -M vicmd 'v'  vi-visual-mode
bindkey -M vivis '\$' vi-visual-eol
bindkey -M vivis '^M' vi-visual-yank
bindkey -M vivis 'f'  vi-visual-find-next-char
bindkey -M vivis 't'  vi-visual-find-next-char-skip
bindkey -M vivis 'h'  vi-visual-backward-char
bindkey -M vivis 'l'  vi-visual-forward-char
bindkey -M vivis 'e'  vi-visual-forward-word-end
bindkey -M vivis 'y'  vi-visual-yank
