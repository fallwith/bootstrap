function nvim_launch --description 'Enhanced Neovim launcher with line number support and nvr integration'
  set -l args
    
  if test (count $argv) -eq 0
    # when called from a Neovim terminal session, use `nvr -o <file>` instead
    # of `nvim <file>` to open the file in a new split within the existing
    # session. `nvr -o` requires an argument, so if there are no arguments present,
    # default to a single argument of '.' to have the Neovim split open a file
    # browser at PWD.
    if test -n "$NVIM"
      set args .
    end
  else
    set path_arg $argv[1]
    
    # if first argument starts with '-', pass all arguments through as-is
    if string match -q -- '-*' $path_arg
      set args $argv
    else
      set argv $argv[2..-1] # remove first argument
      set elements (string split ':' $path_arg)
      set file $elements[1]
      set args $file

      if test (count $elements) -gt 1
        set line_num $elements[2]
        if test -n "$line_num" -a "$line_num" -gt 0
          set args $args "+$line_num"
        end
      end

      set args $args $argv # add remaining arguments
    end
  end

  # if called within a Neovim session, use `nvr` and otherwise use `nvim`
  if test -n "$NVIM"
    nvr -o $args
  else
    command nvim $args
  end
end
