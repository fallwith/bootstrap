# ~/.zshrc
# with content borrowed from prezto: https://github.com/sorin-ionescu/prezto
# with content borrowed from oh-my-zsh: https://github.com/robbyrussell/oh-my-zsh

zsh_modules_dir="${ZDOTDIR:-$HOME}/modules"
if [[ -e "$zsh_modules_dir/init.zsh" ]]; then
  source "$zsh_modules_dir/init.zsh"
fi

# [[ -z $ZPROFILE_LOADED ]] && source "${ZDOTDIR:-$HOME}/.zprofile"

# TODO: how to supply `--login` to neovim's zsh instances?
# if [[ -n $MYVIMRC ]]; then
#   source "${ZDOTDIR:-$HOME}/.zprofile"
# fi
