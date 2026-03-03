function addscheme -d 'Add a colorscheme to Neovim from a GitHub repo'
  set -l lua_file ~/.config/nvim/lua/plugins/colorscheme.lua
  set -l test_flag false
  set -l owner_repo

  for arg in $argv
    switch $arg
      case --test
        set test_flag true
      case '*'
        set owner_repo $arg
    end
  end

  if test -z "$owner_repo"
    echo "Usage: addscheme <owner/repo | vimcolorschemes URL> [--test]"
    return 1
  end

  set owner_repo (string replace -r '^https?://vimcolorschemes\.com/' '' $owner_repo)
  set owner_repo (string replace -r '/$' '' $owner_repo)

  if not string match -qr '^[^/]+/[^/]+$' $owner_repo
    echo "Error: expected owner/repo format, got '$owner_repo'"
    return 1
  end

  if grep -q "\"$owner_repo\"" $lua_file
    echo "$owner_repo is already in colorscheme.lua"
    return 1
  end

  echo "Fetching colorschemes from $owner_repo..."
  set -l raw_names (gh api "repos/$owner_repo/contents/colors" --jq '.[].name' 2>/dev/null)
  if test $status -ne 0; or test (count $raw_names) -eq 0
    echo "Error: could not fetch colors/ from $owner_repo"
    return 1
  end

  set -l scheme_names
  for name in $raw_names
    set -a scheme_names (string replace -r '\.(lua|vim)$' '' $name)
  end

  set -l selected
  if test (count $scheme_names) -eq 1
    set selected $scheme_names[1]
    echo "Single scheme found: $selected"
  else
    echo (count $scheme_names)" schemes available"
    set selected (printf '%s\n' $scheme_names | fzf --multi --prompt="scheme> ")
    if test (count $selected) -eq 0
      echo "No schemes selected"
      return 0
    end
  end

  echo
  echo "Will add to colorscheme.lua:"
  echo "  Dependency: \"$owner_repo\""
  echo "  Schemes:"
  for s in $selected
    echo "    \"$s\""
  end
  echo
  read -l -P "Proceed? [y/N] " confirm
  if test "$confirm" != y -a "$confirm" != Y
    return 0
  end

  set -l dep_close (awk '/dependencies = \{/{f=1} f && /^    \},/{print NR; exit}' $lua_file)
  set -l scheme_close (awk '/local schemes = \{/{f=1} f && /^      \}$/{print NR; exit}' $lua_file)

  if test -z "$dep_close"; or test -z "$scheme_close"
    echo "Error: could not find insertion points in colorscheme.lua"
    return 1
  end

  set -l scheme_tmp (mktemp)
  for s in $selected
    echo "        \"$s\"," >> $scheme_tmp
  end

  set -l out_tmp (mktemp)
  set -l dep_line "      \"$owner_repo\","

  awk -v dc=$dep_close -v dl="$dep_line" -v sc=$scheme_close -v sf="$scheme_tmp" '
    NR == dc { print dl }
    NR == sc { while ((getline line < sf) > 0) print line; close(sf) }
    { print }
  ' $lua_file > $out_tmp

  mv $out_tmp $lua_file
  rm -f $scheme_tmp

  echo "Added $owner_repo to colorscheme.lua"

  if test "$test_flag" = true
    echo "Installing with Lazy..."
    nvim --headless +"Lazy install" +qa 2>/dev/null
    for s in $selected
      printf "Testing colorscheme %s... " $s
      set -l err (nvim --headless +"colorscheme $s" +qa 2>&1 >/dev/null)
      if test -z "$err"
        echo "OK"
      else
        echo "FAILED"
      end
    end
  end
end
