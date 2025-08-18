# https://github.com/mattmc3/fishconf/blob/main/functions/which.fish
function fishwhich --description 'better `which`'
  if abbr --query $argv
    echo "$argv is an abbreviation with definition"
    abbr --show | command grep "abbr -a -- $argv"
    type --all $argv 2>/dev/null
    return 0
  else
    type --all $argv
  end
end
