# fixes ^? issues when using delete within vim
stty ek

export PS1="\u@\h \W:\$ "
alias ll="ls -lApG --color=always"

export HISTSIZE=10000
export HISTCONTROL=ignoreboth
