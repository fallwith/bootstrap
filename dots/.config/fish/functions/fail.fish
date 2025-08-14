function fail --description 'Keep running a command until it fails'
  while eval $argv
    # continue looping
  end
end
