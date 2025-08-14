function fuzzy_history --description 'Search and select from command history with fzf'
    # pipe history to fzf
  set -l selected (history | fzf +s -x -e --preview-window=hidden --height 40%)

  if test -n "$selected"
    # replace current command line with selected history item
    commandline -r "$selected"
    commandline -f end-of-line
  end

  commandline -f repaint
end
