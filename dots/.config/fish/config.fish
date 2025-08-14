# Fish configuration - ported from ~/.zshrc

set -g fish_greeting # disable the greeting
set -g fish_color_valid_path normal # don't mark up (underline) valid paths

if status is-interactive
  fish_vi_key_bindings # enable vi mode

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

# disable the the [I] / [N] vi mode indicators
function fish_mode_prompt
end

function fish_prompt
  set -l last_status $status

  # directory basename (blue)
  set_color blue
  if test $PWD = $HOME # prefer '~' over basename($HOME)
    echo -n '~'
  else
    echo -n (basename $PWD)
  end
  set_color normal
  echo -n ' '

  # time (magenta)
  set_color magenta
  echo -n (date +%H:%M:%S)
  set_color normal

  # vi mode indicator (cyan) - not shown in insert mode
  set_color cyan
  switch $fish_bind_mode
  case default
    echo -n ' <N>'  # Normal mode shows <N>
  case visual
    echo -n ' <V>'  # Visual mode shows <V>
  end
  set_color normal

  # last status based '$' prompt (green = succeeded, red = failed)
  if test $last_status -eq 0
    set_color green
  else
    set_color red
  end
  echo -n ' $ '
  set_color normal
end

set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx HISTEDIT $EDITOR
set -gx MANWIDTH 80
set -gx LESSHISTFILE -
set -gx MANPAGER 'nvim +Man!'

if test -n "$KITTY_PID"
  set -gx TERM xterm-kitty
else
  set -gx TERM xterm-256color
end

fish_add_path ~/bin
fish_add_path ~/Library/Python/3.12/bin

# homebrew
if test -d /opt/homebrew
  set -gx HOMEBREW_PREFIX /opt/homebrew
  set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
  set -gx HOMEBREW_REPOSITORY /opt/homebrew
  fish_add_path /opt/homebrew/bin /opt/homebrew/sbin

  if test -z "$LIBRARY_PATH"
    set -gx LIBRARY_PATH (brew --prefix)/lib
  else
    set -gx LIBRARY_PATH "$LIBRARY_PATH:"(brew --prefix)/lib
  end

  if test -z "$LD_LIBRARY_PATH"
    set -gx LD_LIBRARY_PATH (brew --prefix)/include
  else
    set -gx LD_LIBRARY_PATH "$LD_LIBRARY_PATH:"(brew --prefix)/include
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

# gpg
set -gx GPG_TTY (tty)

# load private config if it exists
if test -e ~/.config/fish/config_private.fish
  source ~/.config/fish/config_private.fish
end
