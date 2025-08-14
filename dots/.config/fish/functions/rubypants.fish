function rubypants --description 'Run a Ruby Docker container with the current directory mounted'
  if test (count $argv) -eq 0
    echo "Usage: rubypants <ruby_version>"
    return 1
  end

  pants ruby:$argv[1]
end
