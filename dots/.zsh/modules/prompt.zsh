# a green or red promptchar (%#) to signify the success/failure of the last operation
local ret_status="%(?:%{%F{green}%}%#:%{%F{red}%}%#%s)"

setopt prompt_subst # interpolate functions within the prompt string

# use emoji
# eval emkoala=`echo -e '\xF0\x9F\x90\xA8'`
# eval emkoala=`echo -e "\U1F428"`
# emkoala=$'\U1F428'

function git_branch(){
  [ -e $PWD/.git ] || return
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || return
  echo "[${ref#refs/heads/}] "
}

# conditionally alter the prompt when inside emacs or neovim
# if [[ -n $INSIDE_EMACS || -n $MYVIMRC ]]; then
# fi

# use a 256 color palette
# grey242="%F{242}"
# green112="%F{112}"
# red124="%F{124}"
# blue039="%F{039}"
# violet013="%F{013}"
# PROMPT='%{$blue039%}%c%{$reset_color%} %{$grey242%}%T%{$reset_color%} %{$violet013%}$(git_branch)%{$reset_color%}${ret_status}%{$green112%}%p%{$reset_color%} '

PROMPT='%{%F{cyan}%}%c%{$reset_color%} %{%F{yellow}%}%T%{$reset_color%} %{%F{magenta}%}$(git_branch)%{$reset_color%}${ret_status}%{%F{green}%}%p%{$reset_color%} '
