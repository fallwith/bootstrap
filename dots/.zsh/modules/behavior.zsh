# disable file clobbering. use >! to override
setopt noclobber

# disable 'rm *' prompting
setopt rmstarsilent

# allow comments (prefixed by '#') to be used in interactive shells
setopt interactive_comments

# set desired zsh-syntax-highlighting highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
