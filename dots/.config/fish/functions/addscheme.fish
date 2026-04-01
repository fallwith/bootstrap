function addscheme -d 'Add a colorscheme to Neovim from repo or vimcolorschemes URL'
    set -l packages_file ~/.config/nvim/lua/config/packages.lua
    set -l schemes_file ~/.config/nvim/after/plugin/colorscheme.lua
    set -l forks_file ~/git/bootstrap/dots/bin/update_colorscheme_forks.fish
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

    if grep -q "$owner_repo" $packages_file
        echo "$owner_repo is already in packages.lua"
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
    echo "Will add:"
    echo "  Package (packages.lua): \"$owner_repo\""
    echo "  Schemes (colorscheme.lua):"
    for s in $selected
        echo "    \"$s\""
    end
    echo
    read -l -P "Proceed? [y/N] " confirm
    if test "$confirm" != y -a "$confirm" != Y
        return 0
    end

    # insert repo URL into packages.lua before the "-- editing" section
    set -l editing_line (grep -n '  -- editing' $packages_file | head -1 | cut -d: -f1)
    if test -z "$editing_line"
        echo "Error: could not find '-- editing' marker in packages.lua"
        return 1
    end

    set -l pkg_tmp (mktemp)
    set -l pkg_line "  \"https://github.com/$owner_repo\","
    awk -v el="$editing_line" -v pl="$pkg_line" '
    NR == el - 1 { print pl; print ""; next }
    { print }
  ' $packages_file >$pkg_tmp
    mv $pkg_tmp $packages_file

    echo "Added $owner_repo to packages.lua"

    # insert scheme names into after/plugin/colorscheme.lua
    set -l schemes_close (awk '/^local schemes = \{/{f=1} f && /^\}$/{print NR; exit}' $schemes_file)
    if test -z "$schemes_close"
        echo "Error: could not find schemes table closing in colorscheme.lua"
        return 1
    end

    set -l scheme_tmp (mktemp)
    for s in $selected
        echo "  \"$s\"," >>$scheme_tmp
    end

    set -l out_tmp (mktemp)
    awk -v sc="$schemes_close" -v sf="$scheme_tmp" '
    NR == sc { while ((getline line < sf) > 0) print line; close(sf) }
    { print }
  ' $schemes_file >$out_tmp
    mv $out_tmp $schemes_file
    rm -f $scheme_tmp

    echo "Added schemes to colorscheme.lua"

    if grep -q "$owner_repo" $forks_file
        echo "$owner_repo is already in update_colorscheme_forks.fish"
    else
        set -l last_repo_line (grep -n '^\s\+\S\+/\S\+' $forks_file | tail -1 | cut -d: -f1)
        if test -n "$last_repo_line"
            set -l forks_tmp (mktemp)
            set -l before (math $last_repo_line - 1)
            set -l after (math $last_repo_line + 1)
            head -n $before $forks_file >$forks_tmp
            printf '%s %s\n' (sed -n "$last_repo_line"p $forks_file) "\\" >>$forks_tmp
            printf '  %s\n' $owner_repo >>$forks_tmp
            tail -n +$after $forks_file >>$forks_tmp
            mv $forks_tmp $forks_file
            chmod 755 $forks_file
            echo "Added $owner_repo to update_colorscheme_forks.fish"
        else
            echo "Error: could not find insertion point in update_colorscheme_forks.fish"
        end
    end

    if test "$test_flag" = true
        echo "Installing with vim.pack..."
        nvim --headless +"lua vim.pack.update(nil, {force=true})" +qa 2>/dev/null
        for s in $selected
            printf "Testing colorscheme %s... " $s
            set -l err (nvim --headless +"colorscheme $s" +qa 2>&1 >/dev/null)
            if test -z "$err"
                echo OK
            else
                echo FAILED
            end
        end
    end
end
