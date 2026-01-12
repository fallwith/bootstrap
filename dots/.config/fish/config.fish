# autocompletion
# ===
# alt-f - accept the next suggested word
# ctrl-f - accepts the entire suggestion
#
# variables
# ===
# `set <name> <value>` - set a variable
# `set -x <name> <value>` - export a variable: 
#
# control flow
# ===
# • redirection:
#   ```
#   make &> output.txt
#   ```
#
# • conditionals:
#   ```
#   if grep fish /etc/shells
#     echo fish
#   else if grep bash /etc/shells
#     echo bash
#   else
#     echo nothing found
#   end
#   ```
#
# • loops:
#   ```
#   for val in $PATH
#     echo $val
#   end
#   ```
#
# navigation
# ===
# • `<directory>/` - enter the name of a directory with a trailing slash to cd to
#                    that directory without typing 'cd'
# • `cdh` - view the cd history
# • `prevd` - go to the previous directory
# • `nextd` - go to the next directory
# 
# themes
# ===
# `fish_config theme show` - preview all themes
# `fish_config theme list` - list all themes
# `fish_config theme choose <theme>` - temporarily apply a theme
# `fish_config theme save :theme` - permanently apply a theme (writes to
#                                   fish_variables)
#
# utility
# ===
# • `fish -P` - create a private session (history won't be saved)
# • `fish --profile-startup=fishprof.txt -c exit` - profile fish's startup

set -g fish_greeting # disable the greeting
set -g fish_color_valid_path normal # don't mark up (underline) valid paths
set -g fish_term24bit 1 # force 24-bit color

if ! test -e ~/.hushlogin
  echo "Hushing 'last login' message via ~/.hushlogin"
  touch ~/.hushlogin
end

if status is-interactive
  set --global fish_key_bindings fish_vi_key_bindings
  # fish_vi_key_bindings # enable vi mode

  function fish_user_key_bindings
    # use 'jk' to switch to normal mode
    bind -M insert jk 'if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f backward-char force-repaint; end'
    
    #
    # enable emacs-style bindings while in vi mode
    #
    # ctrl-a for beginning of line
    bind -M insert \ca 'beginning-of-line'
    bind -M default \ca 'beginning-of-line'
    bind -M visual \ca 'beginning-of-line'
    # ctrl-e for end of line
    bind -M insert \ce 'end-of-line'
    bind -M default \ce 'end-of-line'
    bind -M visual \ce 'end-of-line'
    # ctrl-d for forward delete
    bind -M insert \cd 'delete-char'
    bind -M default \cd 'delete-char'
    bind -M visual \cd 'delete-char'
    # ctrl-f for forward movement
    bind -M insert \cf 'forward-char'
    bind -M default \cf 'forward-char'
    bind -M visual \cf 'forward-char'
    # ctrl-b for backward movement
    bind -M insert \cb 'backward-char'
    bind -M default \cb 'backward-char'
    bind -M visual \cb 'backward-char'
    # alt-f for forward word
    bind -M insert \ef 'forward-word'
    bind -M default \ef 'forward-word'
    bind -M visual \ef 'forward-word'
    # alt-b for backward word
    bind -M insert \eb 'backward-word'
    bind -M default \eb 'backward-word'
    bind -M visual \eb 'backward-word'
    # alt-d for delete word
    bind -M insert \ed 'kill-word'
    bind -M default \ed 'kill-word'
    bind -M visual \ed 'kill-word'
    # ctrl-w for backward kill word
    bind -M insert \cw 'backward-kill-word'
    bind -M default \cw 'backward-kill-word'
    bind -M visual \cw 'backward-kill-word'

    #
    # history
    #
    # ctrl-r for custom fuzzy history function
    bind -M insert \cr 'fuzzy_history'
    bind -M default \cr 'fuzzy_history'
    # ctrl-p for previous command
    bind -M insert \cp 'up-or-search' 
    bind -M default \cp 'up-or-search'
    # ctrl-n for next command
    bind -M insert \cn 'down-or-search'
    bind -M default \cn 'down-or-search'
    # ctrl-s for forward search
    bind -M insert \cs 'history-search-forward'
    bind -M default \cs 'history-search-forward'

    #
    # system clipboard
    #
    # 'y' copies to system clipboard in visual mode
    bind -M visual y 'fish_clipboard_copy; commandline -f end-selection repaint'
    # 'p' pastes from system cliboard in normal mode
    bind -M default p 'commandline -i (fish_clipboard_paste)'
  end
end

# customize the [I] / [N] vi mode indicators that appear in the prompt
function fish_mode_prompt
  switch $fish_bind_mode
    case default
      set_color --bold red
      echo '[N] '
    case insert
      # don't display anything
    case replace_one
      set_color --bold green
      echo '[R] '
    case visual
      set_color --bold brmagenta
      echo '[V] '
    case '*'
      set_color --bold red
      echo '[?] '
  end
  set_color normal
end

# set terminal title to the basename of PWD
function fish_title
  if test $PWD = $HOME # prefer '~' over basename($HOME)
    echo -n '~'
  else
    echo -n (basename $PWD)
  end
end

function fish_prompt
  set -l last_status $status

  echo -n ' 🦊 '

  # directory basename
  set_color 9DD6E7
  if test $PWD = $HOME # prefer '~' over basename($HOME)
    echo -n '~'
  else
    echo -n (basename $PWD)
  end
  set_color normal
  echo -n ' '

  # time
  set_color FE7EAA
  echo -n (date +%H:%M:%S)
  set_color normal

  # git branch
  set_color B8D59A
  echo -n (git_branch_name)
  set_color normal

  # last status based prompt (normal = succeeded, red = failed)
  if test $last_status -eq 0
    set_color BEB549
  else
    set_color FF3333
  end
  echo -n ' ❯ '
  set_color normal
end

function git_branch_name
  set -l bname (git branch --show-current 2>/dev/null)
  test -n "$bname" || return
  # truncate to n chars. if the name ends in 1-2 digits ("phase1", "v10", etc.)
  # then append the 1-2 digits to help differentiate between long branch names
  # that are identical except for the number.
  set -l truncated (string sub --length 15 $bname)
  set -l suffix (test (string length $bname) -gt 15; and string match -r '(?<!\d)\d{1,2}$' $bname)
  echo " $truncated$suffix"
end

set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx HISTEDIT $EDITOR
set -gx MANWIDTH 80
set -gx LESSHISTFILE -
set -gx MANPAGER 'nvim +Man!'
set -gx NOAA_GOV_STATION_ID 9410230

if test -n "$KITTY_PID"
  set -gx TERM xterm-kitty
else
  set -gx TERM xterm-256color
end

fish_add_path ~/bin
# pipx uses ~/.local/bin
fish_add_path ~/.local/bin
# fish_add_path ~/Library/Python/3.12/bin

# homebrew
if test -d /opt/homebrew
  set -gx HOMEBREW_PREFIX /opt/homebrew
  set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
  set -gx HOMEBREW_REPOSITORY /opt/homebrew
  fish_add_path /opt/homebrew/bin /opt/homebrew/sbin

  set -l homebrew_lib_path (brew --prefix)/lib

  if not contains -- "$homebrew_lib_path" $LIBRARY_PATH
    set -gx LIBRARY_PATH $homebrew_lib_path
  end

  if not contains -- "$homebrew_lib_path" $LD_LIBRARY_PATH
    set -gx LD_LIBRARY_PATH $homebrew_lib_path
  end
end

# go
set -gx GOPATH ~/.go
fish_add_path $GOPATH/bin

# asdf
if test -e /opt/homebrew/bin/asdf
  set -gx ASDF_DATA_DIR $HOME/.asdf
  mkdir -p $ASDF_DATA_DIR
  fish_add_path $ASDF_DATA_DIR/shims

  if not test -e $ASDF_DATA_DIR/completions
    mkdir -p $ASDF_DATA_DIR/completions
  end

  # auto-install plugins
  for plugin in ruby nodejs
    if not test -e $ASDF_DATA_DIR/plugins/$plugin
      asdf plugin add $plugin
    end
  end

  set -gx ASDF_NODEJS_AUTO_ENABLE_COREPACK 1
end

# rust
if test -e $HOME/.cargo/bin/cargo
  fish_add_path $HOME/.cargo/bin
end

# tex
if test -e /Library/TeX/texbin
  fish_add_path /Library/TeX/texbin
end

# fzf default command
set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'

# fzf base16 tomorrow night theme
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#282a2e,bg:#1d1f21,spinner:#8abeb7,hl:#81a2be \
--color=fg:#b4b7b4,header:#81a2be,info:#f0c674,pointer:#8abeb7 \
--color=marker:#8abeb7,fg+:#e0e0e0,prompt:#f0c674,hl+:#81a2be"

# fzf shell keybindings
type -q fzf && fzf --fish | source

# gpg
set -gx GPG_TTY (tty)

# load private config if it exists
if test -e ~/.config/fish/config_private.fish
  source ~/.config/fish/config_private.fish
end
