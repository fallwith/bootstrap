function keepemptydirs --description 'Place .keep files in empty directories'
  if test (count $argv) -eq 0
    echo "Usage: keepemptydirs <root_directory>"
    return 1
  end

  set root $argv[1]
  echo "Placing .keep files in any empty directories beneath '$root'..."
  find $root -type d -empty -exec touch {}/.keep \;
end
