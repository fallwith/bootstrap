# a green or red promptchar (%#) to signify the success/failure of the last operation
local ret_status="%(?:%{$green112%}%#:%{$red124%}%#%s)"
eval emkoala=`echo -e '\xF0\x9F\x90\xA8'`
GIT_BRANCH_PREFIX=" %{$reset_color%}%{$fg[white]%}["
GIT_BRANCH_SUFFIX="]%{$reset_color%}"

PROMPT='%{$blue039%}%c%{$reset_color%} %{$grey242%}%T%{$reset_color%}$(git_branch) %{$voilet013%}${VIMODE} %{$reset_color%}${emkoala}  ${ret_status}%{$green112%}%p%{$reset_color%} '
