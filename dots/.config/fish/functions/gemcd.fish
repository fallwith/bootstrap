function gemcd --description 'Change directory to a gem installation path'
  if test (count $argv) -eq 0
    echo "Usage: gemcd <gem_name>"
    return 1
  end

  cd (bundle info --path $argv[1])
end
