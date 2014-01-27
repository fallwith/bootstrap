# show history with yyyy-mm-dd date/time stamps
alias history='fc -il 1'

# history
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt bang_hist                # treat the '!' character specially during expansion
setopt extended_history         # write the history file in the ':start:elapsed;command' format
setopt inc_append_history       # write to the history file immediately, not when the shell exits
setopt share_history            # share history across all sessions
setopt hist_expire_dups_first   # expire a duplicate event first when trimming history
setopt hist_ignore_dups         # ignore duplicated commands already known in history
setopt hist_ignore_all_dups     # delete an old recorded event if a new event is a duplicate
setopt hist_find_no_dups        # do not display a previously found event
setopt hist_ignore_space        # do not record an event starting with a space
setopt hist_save_no_dups        # do not write a duplicate event to the history file
setopt hist_verify              # do not execute immediately upon history expansion
alias hist10="history|awk '{print \$4}'|sort|uniq -c|sort -nr|head" # top 10 list
