function z --description 'Interactive directory selection using fzf'
  set -l selected_dir (fd -td -d1 . ~ ~/.config ~/git | sed "s|$HOME/||g" | fzf +m --height 33% --border --layout=reverse)
  if test -n "$selected_dir"
    cd $HOME/$selected_dir
  end
end