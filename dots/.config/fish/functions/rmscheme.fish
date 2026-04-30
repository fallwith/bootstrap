function rmscheme -d 'Remove a colorscheme that was installed via addscheme'
    set -l packages_file ~/.config/nvim/lua/config/packages.lua
    set -l schemes_file ~/.config/nvim/after/plugin/colorscheme.lua
    set -l forks_file ~/git/bootstrap/dots/bin/update_colorscheme_forks.fish

    if test (count $argv) -ne 1
        echo "Usage: rmscheme <name-prefix>"
        return 1
    end

    set -l prefix $argv[1]
    set -l prefix_re (string escape --style=regex -- $prefix)
    set -l scheme_pattern '^[[:space:]]*"'$prefix_re'([^a-zA-Z0-9]|$)'

    # collect "scheme-name" entries in colorscheme.lua matching the prefix
    set -l matching_schemes
    for line in (grep -E $scheme_pattern $schemes_file)
        set -a matching_schemes (string trim $line)
    end

    if test (count $matching_schemes) -eq 0
        echo "No schemes matching '$prefix' found in $schemes_file"
        return 1
    end

    # collect owner/repo URLs in packages.lua matching the prefix
    set -l owner_repos
    for line in (grep -iE 'github\.com/[^"]*'$prefix_re $packages_file)
        set -l m (string match -r 'github\.com/([^"]+)' -- $line)
        if test (count $m) -eq 2
            set -a owner_repos (string replace -r '/$' '' -- $m[2])
        end
    end
    set owner_repos (printf '%s\n' $owner_repos | sort -u | string match -er '.')

    if test (count $owner_repos) -eq 0
        echo "No package URLs matching '$prefix' found in $packages_file"
        return 1
    end

    echo "Will remove from $schemes_file:"
    for s in $matching_schemes
        echo "  $s"
    end
    echo
    echo "Will remove from $packages_file:"
    for r in $owner_repos
        echo "  https://github.com/$r"
    end
    echo
    echo "Will remove from $forks_file (if present):"
    for r in $owner_repos
        echo "  $r"
    end
    echo
    read -l -P "Proceed? [y/N] " confirm
    if test "$confirm" != y -a "$confirm" != Y
        return 0
    end

    # write tmp content back through `cat` so the destination file's
    # inode (and therefore its permissions) is preserved
    set -l tmp (mktemp)

    # colorscheme.lua: drop matching scheme lines
    grep -vE $scheme_pattern $schemes_file >$tmp
    cat $tmp >$schemes_file
    echo "Removed schemes from colorscheme.lua"

    # packages.lua: drop the package URL line(s); the trailing ["/] anchor
    # prevents accidentally clobbering a sibling repo whose name shares a prefix
    for repo in $owner_repos
        set -l repo_re (string escape --style=regex -- $repo)
        grep -vE 'github\.com/'$repo_re'["/]' $packages_file >$tmp
        cat $tmp >$packages_file
    end
    echo "Removed package URLs from packages.lua"

    # update_colorscheme_forks.fish: drop the repo entry
    set -l touched_forks false
    for repo in $owner_repos
        set -l repo_re (string escape --style=regex -- $repo)
        set -l forks_pattern '(^|[[:space:]])'$repo_re'([[:space:]]|\\\\|$)'
        if grep -qE $forks_pattern $forks_file
            set touched_forks true
            grep -vE $forks_pattern $forks_file >$tmp
            cat $tmp >$forks_file
        end
    end

    # if the deletion left a stranded `\` continuation on the new last
    # repo line, strip it so the fish list parses correctly
    if test "$touched_forks" = true
        set -l last_line (grep -n '^\s\+\S\+/\S\+' $forks_file | tail -1 | cut -d: -f1)
        if test -n "$last_line"
            set -l current (sed -n "$last_line"p $forks_file)
            if string match -qr '\\\\$' -- $current
                set -l fixed (string replace -r '\s*\\\\$' '' -- $current)
                awk -v ln="$last_line" -v new="$fixed" 'NR == ln { print new; next } { print }' $forks_file >$tmp
                cat $tmp >$forks_file
            end
        end
        echo "Removed entries from update_colorscheme_forks.fish"
    end

    rm -f $tmp

    echo "Updating nvim-pack-lock.json..."
    nvim --headless +qa 2>/dev/null
    echo Done
end
