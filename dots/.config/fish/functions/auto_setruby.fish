function auto_setruby --on-variable PWD \
  --description 'Set the Ruby version desired by PWD'
  # walk upward from PWD looking for .ruby-version
  set -l dir $PWD
  set -l desired
  while true
    if test -e "$dir/.ruby-version"
      set desired (cat "$dir/.ruby-version")
      break
    end
    set -l parent (string replace -r '/[^/]+$' '' $dir)
    if test -z "$parent"; or test "$parent" = "$dir"
      break
    end
    set dir $parent
  end

  # fall back to the cached default version (see config.fish)
  if test -z "$desired"
    if set -q DEFAULT_RUBY_VERSION
      set desired $DEFAULT_RUBY_VERSION
    else
      return
    end
  end

  # check current version from PATH (no subprocess)
  set -l switching false
  for p in $PATH
    if string match -q "$HOME/.rubies/*/bin" $p
      set -l current (string replace "$HOME/.rubies/ruby-" '' \
        (string replace '/bin' '' $p))
      test "$current" = "$desired"; and return
      set switching true
      break
    end
  end

  # silent on first set (fresh shell), echo on switch
  if $switching
    setruby $desired
  else
    setruby $desired --quiet
  end
end
