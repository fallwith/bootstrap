function rubyinstall --description 'Install a Ruby version via ruby-build'
  if test -z "$argv[1]"
    echo 'Usage: rubyinstall <version>'
    return 1
  end

  ruby-build $argv[1] ~/.rubies/ruby-$argv[1]
end
