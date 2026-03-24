function setruby --description 'Switch Ruby version'
  set -l desired $argv[1]
  set -l quiet 0
  contains -- --quiet $argv; and set quiet 1

  if test -z "$desired"
    if test -e .ruby-version
      set desired (cat .ruby-version)
    else
      echo 'No .ruby-version file found here.'
      return 1
    end
  end

  if not string match -q 'jruby*' $desired
    and not string match -q 'ruby*' $desired
    set desired "ruby-$desired"
  end

  set -l bin_path ~/.rubies/$desired/bin
  if not test -d $bin_path
    echo "Can't set Ruby to $desired - is it installed?"
    return 1
  end

  # remove any previous ~/.rubies/*/bin from PATH
  set -l new_path
  for p in $PATH
    string match -q "$HOME/.rubies/*/bin" $p; or set -a new_path $p
  end
  set -gx PATH $bin_path $new_path

  test $quiet -eq 0; and echo "Ruby set to $desired"
end
