function z --description 'Interactive directory selection using fzf'
  set -l search_roots ~ ~/.config ~/git

  for dir in ~/git/*/
    if test -d "$dir/.bare"
      set -a search_roots $dir
    end
  end

  set -l selected_dir (fd -td -tl -d1 . $search_roots | sed "s|$HOME/||g" | sort -u | fzf +m --height 33% --border --layout=reverse)
  if test -n "$selected_dir"
    cd $HOME/$selected_dir
  end
end
