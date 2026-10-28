# wdiff -- display a git diff for a work.fish project
#
# Usage:
#   wdiff <UNIQUE_START_OF_PROJECT_DIRECTORY_NAME>
#
# Diffs the STAGED tree against the base it was actually built on, for each
# repo in each matching project directory.
#
# Options:
#   -l/--list      list the files involved with the diff
#   -r/--revision  print the staged tree hash, for approving a worker's tree
#   -b/--base      override the base ref (default: MERGE_HEAD mid-merge,
#                  else the merge-base with origin's default branch)

function wdiff --description 'Provide a git diff for a work.fish project'
    argparse -n wdiff l/list r/revision 'b/base=' -- $argv
    or return 1

    set -l dirstart $argv[1]
    if test -z "$dirstart"
        echo "wdiff: need a project directory prefix" >&2
        return 1
    end

    set -l projects ~/projects/$dirstart*
    if test (count $projects) -eq 0
        echo "wdiff: no project directory matching '$dirstart'" >&2
        return 1
    end

    for project in $projects
        set -l repos (find $project -maxdepth 2 -name .git | sort)
        if test (count $repos) -eq 0
            continue
        end

        # In --revision mode the output is meant to be read or copied as a
        # hash, so it carries the banner but no per-repo rules and no diffs.
        if set -q _flag_revision
            _wdiff_banner $project (count $repos)
            for path in $repos
                set -l dir (dirname $path)
                set -l unmerged (git -C $dir diff --name-only --diff-filter=U)
                if test (count $unmerged) -gt 0
                    printf '%-20s %s\n' (basename $dir) \
                        "cannot write tree: "(count $unmerged)" unmerged path(s)"
                else
                    printf '%-20s %s\n' (basename $dir) (git -C $dir write-tree)
                end
            end
            echo
            continue
        end

        _wdiff_banner $project (count $repos)

        for path in $repos
            set -l dir (dirname $path)
            set -l base (_wdiff_base $dir $_flag_base)

            _wdiff_repo_header (basename $dir) $base

            if not git -C $dir diff --quiet
                _wdiff_note "unstaged changes are present and are NOT shown below"
            end

            set -l unmerged (git -C $dir diff --name-only --diff-filter=U)
            if test (count $unmerged) -gt 0
                _wdiff_note (count $unmerged)" unmerged path(s) remain:"
                printf '    %s\n' $unmerged
            end

            if set -q _flag_list
                set -l stat (git -C $dir diff --cached --stat $base)
                if test (count $stat) -eq 0
                    _wdiff_note 'no staged changes'
                else
                    printf '%s\n' $stat
                end
            else
                if git -C $dir diff --cached --quiet $base
                    _wdiff_note 'no staged changes'
                else
                    git -C $dir diff --cached $base
                end
            end

            echo
        end
    end
end

# Resolve the base a staged tree was actually built on. Diffing against a live
# remote branch renders its newer commits as phantom deletions, so prefer a ref
# that cannot move: MERGE_HEAD during a merge, otherwise the merge-base.
function _wdiff_base --argument dir override
    if test -n "$override"
        echo $override
        return
    end

    if git -C $dir rev-parse --verify --quiet MERGE_HEAD >/dev/null
        echo MERGE_HEAD
        return
    end

    set -l default_head (git -C $dir symbolic-ref --quiet refs/remotes/origin/HEAD)
    set -l mb
    if test -n "$default_head"
        set mb (git -C $dir merge-base HEAD $default_head)
    end

    if test -n "$mb"
        echo $mb
    else
        echo HEAD
    end
end

function _wdiff_width
    if test -n "$COLUMNS"
        echo $COLUMNS
    else
        echo 80
    end
end

# Takes the project directory, not a label: the banner shows the basename so it
# fits the rule, and the full path on its own line so it can be copied into a
# `git -C` invocation.
function _wdiff_banner --argument project repo_count
    set -l width (_wdiff_width)
    set -l suffix "($repo_count repo"(test "$repo_count" -eq 1; and echo ''; or echo 's')")"

    if isatty stdout
        set_color --bold brcyan
    end
    string repeat -n $width '#'
    echo "# "(basename $project)" $suffix"
    string repeat -n $width '#'
    if isatty stdout
        set_color normal
    end

    if isatty stdout
        set_color brblack
    end
    echo "  $project"
    if isatty stdout
        set_color normal
    end
    echo
end

function _wdiff_repo_header --argument repo base
    set -l width (_wdiff_width)

    # Shorten a full object id; leave symbolic refs such as MERGE_HEAD intact,
    # because which mode the diff is in is the thing worth seeing.
    set -l label $base
    if string match -qr '^[0-9a-f]{40}$' -- $base
        set label (string sub -l 12 -- $base)
    end

    set -l text "== $repo [base: $label] "
    set -l pad (math "max(0, $width - "(string length -- $text)")")

    if isatty stdout
        set_color --bold yellow
    end
    echo $text(string repeat -n $pad '=')
    if isatty stdout
        set_color normal
    end
end

function _wdiff_note --argument text
    if isatty stdout
        set_color brblack
    end
    echo "   ($text)"
    if isatty stdout
        set_color normal
    end
end
