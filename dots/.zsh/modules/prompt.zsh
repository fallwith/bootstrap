grey242="%F{242}"
green112="%F{112}"
red124="%F{124}"
blue039="%F{039}"
violet013="%F{013}"

# a green or red promptchar (%#) to signify the success/failure of the last operation
local ret_status="%(?:%{$green112%}%#:%{$red124%}%#%s)"

setopt prompt_subst # interpolate functions within the prompt string

# eval emkoala=`echo -e '\xF0\x9F\x90\xA8'`
eval emkoala=`echo -e "\U1F428"`

GIT_BRANCH_PREFIX=" %{$reset_color%}%{$fg[white]%}["
GIT_BRANCH_SUFFIX="]%{$reset_color%}"

PROMPT='%{$blue039%}%c%{$reset_color%} %{$grey242%}%T%{$reset_color%}$(git_branch) %{$violet013%}${VIMODE} %{$reset_color%}${emkoala}  ${ret_status}%{$green112%}%p%{$reset_color%} '
