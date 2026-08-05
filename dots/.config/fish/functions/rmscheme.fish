function rmscheme -d 'Remove a colorscheme installed via addscheme, everywhere it appears'
    set -l packages_file ~/.config/nvim/lua/config/packages.lua
    set -l schemes_file ~/.config/nvim/after/plugin/colorscheme.lua
    set -l lock_file ~/.config/nvim/nvim-pack-lock.json
    set -l forks_file ~/git/bootstrap/dots/bin/update_colorscheme_forks.fish
    set -l opt_dir ~/.local/share/nvim/site/pack/core/opt

    if test (count $argv) -lt 1
        echo "Usage: rmscheme <scheme|plugin|owner/repo>..."
        echo "  a target may be a scheme name from the rotation (nightSyscall),"
        echo "  a vim.pack plugin name (themeinitnvim), an owner/repo, or a"
        echo "  github.com / vimcolorschemes.com URL"
        return 1
    end

    # colorscheme packages as `line<TAB>owner/repo<TAB>plugin-name` rows,
    # scoped to the `-- colorschemes` block of packages.lua so that a target
    # can never resolve to an unrelated plugin (`folk` vs folke/flash.nvim)
    set -l pkg_rows (__rmscheme_packages $packages_file)
    if test (count $pkg_rows) -eq 0
        echo "Error: found no colorscheme entries in $packages_file" >&2
        return 1
    end

    # `plugin-name<TAB>scheme` rows for every scheme on disk. this is the
    # authoritative scheme -> package mapping: names diverge often enough
    # (themeinitnvim -> nightSyscall, folk-nvim -> folk-ushirogami) that
    # prefix guessing cannot be trusted
    set -l provided_rows (__rmscheme_provided $opt_dir)
    set -l provided_schemes
    for row in $provided_rows
        set -a provided_schemes (string split \t -- $row)[2]
    end

    # `line<TAB>scheme` rows for the rotation array in colorscheme.lua
    set -l array_rows (__rmscheme_array $schemes_file)
    if test (count $array_rows) -eq 0
        echo "Error: could not read the schemes table in $schemes_file" >&2
        return 1
    end

    set -l rm_names # vim.pack plugin names
    set -l rm_repos # owner/repo, index-aligned with rm_names
    set -l rm_pkg_lines # packages.lua line numbers
    set -l rm_schemes # scheme names to drop from the rotation
    set -l rm_provided # every scheme the removed plugins provide, in or out
    set -l dead_schemes # rotation entries no installed plugin provides

    for arg in $argv
        set -l target (string replace -r '^https?://vimcolorschemes\.com/r/' '' -- $arg)
        set target (string replace -r '^https?://github\.com/' '' -- $target)
        set target (string replace -r '/$' '' -- $target)

        set -l hits (__rmscheme_match_packages $target $pkg_rows)

        # no package matched by name/repo, so try resolving through the
        # schemes the installed plugins actually provide
        if test (count $hits) -eq 0
            set -l owners (__rmscheme_owning_plugins $target $provided_rows)
            for owner in $owners
                for row in $pkg_rows
                    if test (string split \t -- $row)[3] = "$owner"
                        set -a hits $row
                    end
                end
            end
        end

        if test (count $hits) -eq 0
            # nothing installed matches: the target may be a stale rotation
            # entry whose package is already gone (a scheme that was renamed
            # or dropped upstream). those crash the rotation when picked, so
            # removing the lines is the whole job
            set -l stale (__rmscheme_match_schemes $target $array_rows $provided_schemes)
            if test (count $stale) -eq 0
                echo "Error: '$arg' matched no package or rotation entry" >&2
                return 1
            end
            set -a rm_schemes $stale
            set -a dead_schemes $stale
            continue
        end

        if test (count $hits) -gt 1
            echo "Error: '$arg' is ambiguous. Matching packages:" >&2
            for row in $hits
                set -l parts (string split \t -- $row)
                echo "  $parts[2] (plugin '$parts[3]')" >&2
            end
            echo "Re-run with an exact plugin name or owner/repo." >&2
            return 1
        end

        set -l parts (string split \t -- $hits[1])
        if contains -- $parts[3] $rm_names
            continue
        end
        set -a rm_pkg_lines $parts[1]
        set -a rm_repos $parts[2]
        set -a rm_names $parts[3]

        # every rotation entry this plugin provides, duplicates included
        # (the array weights favored schemes by repeating them)
        set -l target_schemes
        for row in $provided_rows
            set -l provided (string split \t -- $row)
            if test $provided[1] != "$parts[3]"
                continue
            end
            set -a rm_provided $provided[2]
            for entry in $array_rows
                if test (string split \t -- $entry)[2] = "$provided[2]"
                    set -a target_schemes $provided[2]
                end
            end
        end

        # plus rotation entries that look like this package's but that no
        # installed plugin provides -- variants renamed or dropped upstream
        # (e.g. aurora-dark alongside aurora). leaving one behind leaves the
        # rotation able to pick a scheme that no longer exists
        set -l base (string split -r -m1 / -- $parts[2])[-1]
        for prefix in $target $parts[3] $base $target_schemes
            for stale in (__rmscheme_match_schemes $prefix $array_rows $provided_schemes)
                if not contains -- $stale $dead_schemes
                    set -a target_schemes $stale
                    set -a dead_schemes $stale
                end
            end
        end
        set -a rm_schemes $target_schemes
    end

    if test (count $rm_schemes) -gt 0
        set rm_schemes (printf '%s\n' $rm_schemes | sort -u)
    end

    if test (count $rm_schemes) -gt 0
        echo "Will remove from "(basename $schemes_file)":"
        for s in $rm_schemes
            if contains -- $s $dead_schemes
                echo "  \"$s\" (dead entry -- no installed plugin provides it)"
            else
                echo "  \"$s\""
            end
        end
        echo
    end

    if test (count $rm_repos) -gt 0
        echo "Will remove from "(basename $packages_file)", "(basename $forks_file)":"
        for r in $rm_repos
            echo "  $r"
        end
        echo
        echo "Will call vim.pack.del() for (clears on-disk dir + lockfile entry):"
        for n in $rm_names
            if test -d $opt_dir/$n
                echo "  $n"
            else
                echo "  $n (not on disk -- will try anyway)"
            end
        end
        echo
    end

    read -l -P "Proceed? [y/N] " confirm
    if test "$confirm" != y -a "$confirm" != Y
        return 0
    end

    # colorscheme.lua: drop the rotation entries by line number, which keeps
    # a scheme name from matching anything outside the schemes table
    if test (count $rm_schemes) -gt 0
        set -l scheme_lines
        for row in $array_rows
            set -l parts (string split \t -- $row)
            if contains -- $parts[2] $rm_schemes
                set -a scheme_lines $parts[1]
            end
        end
        if not __rmscheme_drop_lines $schemes_file (string join , -- $scheme_lines)
            echo "Error: refusing to write an empty $schemes_file" >&2
            return 1
        end
        echo "Removed "(count $scheme_lines)" rotation line(s) from "(basename $schemes_file)
    end

    # the header comment tracks schemes that are installed but deliberately
    # left out of the rotation, so it has to be pruned against everything the
    # removed plugins provide, not just the array lines that went away
    if test (count $rm_schemes) -gt 0 -o (count $rm_provided) -gt 0
        __rmscheme_prune_comments $schemes_file $rm_schemes $rm_provided
    end

    # packages.lua and the forks list: also by line number
    if test (count $rm_pkg_lines) -gt 0
        if not __rmscheme_drop_lines $packages_file (string join , -- $rm_pkg_lines)
            echo "Error: refusing to write an empty $packages_file" >&2
            return 1
        end
        echo "Removed package(s) from packages.lua"
    end

    set -l fork_lines
    for repo in $rm_repos
        set -l repo_re (string escape --style=regex -- $repo)
        set -a fork_lines (grep -nE '^[[:space:]]+'$repo_re'([[:space:]]|\\\\|$)' $forks_file | cut -d: -f1)
    end
    if test (count $fork_lines) -gt 0
        if not __rmscheme_drop_lines $forks_file (string join , -- $fork_lines)
            echo "Error: refusing to write an empty $forks_file" >&2
            return 1
        end
        __rmscheme_fix_forks_continuation $forks_file
        echo "Removed entries from "(basename $forks_file)
    end

    if test (count $rm_names) -eq 0
        __rmscheme_report_orphans $schemes_file $opt_dir
        echo Done
        return 0
    end

    # vim.pack.del drops the on-disk plugin dir AND the lockfile entry in one
    # shot. it must run AFTER packages.lua has been edited so the plugin is no
    # longer active (del refuses to remove active plugins without force).
    # per-name pcall so a missing entry doesn't abort the rest. `command nvim`
    # because our own nvim is a function that reroutes to `nvr` inside a
    # Neovim terminal, which would send these commands to the live session
    set -l names_quoted
    for n in $rm_names
        set -a names_quoted "\"$n\""
    end
    set -l del_lua "lua for _,n in ipairs({"(string join , -- $names_quoted)"}) do pcall(vim.pack.del, {n}) end"
    echo "Removing plugin(s) from disk and lockfile via vim.pack.del..."
    command nvim --headless -c $del_lua -c qa 2>&1

    for n in $rm_names
        if test -d $opt_dir/$n
            echo "Warning: $opt_dir/$n still exists" >&2
        end
        if grep -qF "\"$n\": {" $lock_file
            echo "Warning: $n still has a "(basename $lock_file)" entry" >&2
        end
    end

    # the fork this package was synced from is left behind on GitHub; report it
    # rather than deleting it, since repo deletion is irreversible. the fork is
    # found by parent rather than by name -- a name collision, a rename, or an
    # upstream transfer all break the assumption that a fork is named after the
    # repo basename. `gh repo list` with no argument uses the authenticated
    # user and nameWithOwner carries the owner, so no handle is hardcoded
    if type -q gh
        __rmscheme_report_forks $rm_repos
    end

    __rmscheme_report_orphans $schemes_file $opt_dir

    echo Done
end

function __rmscheme_report_forks -d 'report forks of the removed repos, matched by parent then by name'
    set -l my_full
    set -l my_names
    set -l my_parents
    for row in (gh repo list --limit 1000 --json nameWithOwner,name,parent \
            --jq '.[] | "\(.nameWithOwner)\t\(.name)\t\(if .parent then .parent.owner.login + "/" + .parent.name else "-" end)"' 2>/dev/null)
        set -l parts (string split \t -- $row)
        set -a my_full $parts[1]
        set -a my_names (string lower -- $parts[2])
        set -a my_parents (string lower -- $parts[3])
    end
    if test (count $my_full) -eq 0
        return 0
    end
    for repo in $argv
        set -l idx (contains -i -- (string lower -- $repo) $my_parents)
        if test -z "$idx"
            # a renamed or deleted upstream no longer parents its fork, so fall
            # back to a repo of mine that still carries the old name
            set idx (contains -i -- (string lower -- (string split -r -m1 / -- $repo)[-1]) $my_names)
        end
        if test -n "$idx"
            echo "Fork left on GitHub: https://github.com/$my_full[$idx]"
        end
    end
end

function __rmscheme_report_orphans -d 'warn about rotation entries nothing on disk provides'
    # a rotation entry with no colorscheme behind it raises when the random
    # pick lands on it, so surface it while the context is fresh
    set -l still_provided
    for row in (__rmscheme_provided $argv[2])
        set -a still_provided (string split \t -- $row)[2]
    end
    set -l orphans
    for row in (__rmscheme_array $argv[1])
        set -l scheme (string split \t -- $row)[2]
        if not contains -- $scheme $still_provided; and not contains -- $scheme $orphans
            set -a orphans $scheme
        end
    end
    if test (count $orphans) -eq 0
        return 0
    end
    echo
    echo "Warning: rotation entries no installed plugin provides:" >&2
    for o in $orphans
        echo "  \"$o\"" >&2
    end
end

function __rmscheme_packages -d 'print line<TAB>owner/repo<TAB>name for colorscheme packages'
    # the block ends at the next SECTION header, which is a comment preceded by
    # a blank line. a comment without one is an inline note about the entry
    # below it, and must not be treated as the end of the colorschemes
    awk '
    /^[[:space:]]*-- colorschemes[[:space:]]*$/ { inblock = 1; next }
    !inblock { next }
    /^[[:space:]]*$/ { blank = 1; next }
    /^[[:space:]]*--/ { if (blank) inblock = 0; next }
    /^[[:space:]]*}\)/ { inblock = 0; next }
    { blank = 0 }
    match($0, /github\.com\/[^"]+/) {
      repo = substr($0, RSTART + 11, RLENGTH - 11)
      sub(/\/$/, "", repo)
      name = ""
      if (match($0, /name[[:space:]]*=[[:space:]]*"[^"]+"/)) {
        name = substr($0, RSTART, RLENGTH)
        sub(/^name[[:space:]]*=[[:space:]]*"/, "", name)
        sub(/"$/, "", name)
      }
      if (name == "") { name = repo; sub(/^.*\//, "", name) }
      printf "%d\t%s\t%s\n", NR, repo, name
    }
  ' $argv[1]
end

function __rmscheme_provided -d 'print plugin<TAB>scheme for every scheme on disk'
    # depth is pinned to <plugin>/colors/<file> on purpose: plugins ship
    # unrelated files deeper down (extras/wezterm/colors, colors/themes)
    for file in (find $argv[1] -mindepth 3 -maxdepth 3 -path '*/colors/*' \( -name '*.lua' -o -name '*.vim' \) 2>/dev/null)
        set -l parts (string split / -- $file)
        printf '%s\t%s\n' $parts[-3] (string replace -r '\.(lua|vim)$' '' -- $parts[-1])
    end
end

function __rmscheme_array -d 'print line<TAB>scheme for the rotation array'
    # comment lines are skipped before the quote match, so a commented-out
    # entry or a note listing scheme names is never mistaken for a live one
    awk '
    /^local schemes = \{/ { inblock = 1; next }
    inblock && /^\}/ { exit }
    inblock && /^[[:space:]]*--/ { next }
    inblock && match($0, /"[^"]+"/) {
      scheme = substr($0, RSTART + 1, RLENGTH - 2)
      printf "%d\t%s\n", NR, scheme
    }
  ' $argv[1]
end

function __rmscheme_match_packages -d 'print package rows matching a target'
    set -l target (string lower -- $argv[1])
    set -l exact
    set -l prefixed
    for row in $argv[2..-1]
        set -l parts (string split \t -- $row)
        set -l repo (string lower -- $parts[2])
        set -l name (string lower -- $parts[3])
        set -l base (string split -r -m1 / -- $repo)[-1]
        if test "$target" = "$repo" -o "$target" = "$name" -o "$target" = "$base"
            set -a exact $row
        else if string match -q -- "$target*" $name; or string match -q -- "$target*" $base
            set -a prefixed $row
        end
    end
    set -l matches $prefixed
    if test (count $exact) -gt 0
        set matches $exact
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches
    end
end

function __rmscheme_owning_plugins -d 'print plugins providing a scheme matching a target'
    set -l target (string lower -- $argv[1])
    set -l exact
    set -l prefixed
    for row in $argv[2..-1]
        set -l parts (string split \t -- $row)
        set -l scheme (string lower -- $parts[2])
        if test "$target" = "$scheme"
            set -a exact $parts[1]
        else if string match -q -- "$target*" $scheme
            set -a prefixed $parts[1]
        end
    end
    set -l matches $prefixed
    if test (count $exact) -gt 0
        set matches $exact
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches | sort -u
    end
end

function __rmscheme_match_schemes -d 'print rotation entries matching a target that nothing provides'
    set -l target (string lower -- $argv[1])
    set -l rows
    set -l provided
    for arg in $argv[2..-1]
        if string match -q -- '*'\t'*' $arg
            set -a rows $arg
        else
            set -a provided $arg
        end
    end
    set -l matches
    for row in $rows
        set -l scheme (string split \t -- $row)[2]
        if contains -- $scheme $provided; or contains -- $scheme $matches
            continue
        end
        if test "$target" = (string lower -- $scheme); or string match -q -- "$target*" (string lower -- $scheme)
            set -a matches $scheme
        end
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches
    end
end

function __rmscheme_drop_lines -d 'delete the given line numbers from a file'
    set -l file $argv[1]
    set -l lines $argv[2]
    if test -z "$lines"
        return 0
    end
    # write back through `cat` so the destination file's inode (and therefore
    # its permissions) is preserved
    set -l tmp (mktemp)
    awk -v lines="$lines" '
    BEGIN { n = split(lines, wanted, ","); for (i = 1; i <= n; i++) drop[wanted[i]] = 1 }
    !(NR in drop)
  ' $file >$tmp
    if not test -s $tmp
        rm -f $tmp
        return 1
    end
    cat $tmp >$file
    rm -f $tmp
end

function __rmscheme_prune_comments -d 'drop removed scheme names from comments above the array'
    set -l file $argv[1]
    set -l schemes $argv[2..-1]
    set -l array_start (grep -n '^local schemes = {' $file | head -1 | cut -d: -f1)
    if test -z "$array_start"
        return 0
    end
    for n in (seq 1 (math $array_start - 1))
        set -l line (sed -n "$n"p $file)
        if not string match -qr '^\s*--' -- $line
            continue
        end
        set -l updated $line
        for s in $schemes
            set updated (string replace -ra '"'(string escape --style=regex -- $s)'",?\s*' '' -- $updated)
        end
        if test "$updated" = "$line"
            continue
        end
        if not string match -qr '"' -- $updated
            echo "Note: $file line $n now lists no schemes; tidy it by hand:" >&2
            echo "  $line" >&2
            continue
        end
        set updated (string replace -r '[,[:space:]]+$' '' -- $updated)
        set -l tmp (mktemp)
        awk -v ln="$n" -v new="$updated" 'NR == ln { print new; next } { print }' $file >$tmp
        if test -s $tmp
            cat $tmp >$file
            echo "Updated the not-in-rotation comment in "(basename $file)
        end
        rm -f $tmp
    end
end

function __rmscheme_fix_forks_continuation -d 'strip a stranded trailing backslash from the repo list'
    set -l file $argv[1]
    set -l last_line (grep -n '^\s\+\S\+/\S\+' $file | tail -1 | cut -d: -f1)
    if test -z "$last_line"
        return 0
    end
    set -l current (sed -n "$last_line"p $file)
    if not string match -qr '\\\\$' -- $current
        return 0
    end
    set -l fixed (string replace -r '\s*\\\\$' '' -- $current)
    set -l tmp (mktemp)
    awk -v ln="$last_line" -v new="$fixed" 'NR == ln { print new; next } { print }' $file >$tmp
    if test -s $tmp
        cat $tmp >$file
    end
    rm -f $tmp
end
