# sandbox_sync -- merge the current branch into a shared integration
# branch (default: sandbox) via an ephemeral detached worktree.
#
# Replaces the parked ~/git/web/sandbox worktree flow: no shared
# local state, so concurrent projects can't wedge each other. The
# remote branch itself is the serialization point -- a rejected
# (non-fast-forward) push triggers fetch + re-merge + retry.
#
# Run from inside the feature branch checkout (a ~/projects/<name>/
# <repo> worktree, a legacy ~/git/web sibling, any clone). On merge
# conflict the ephemeral worktree is left in place for resolution
# (inside the project dir when run from ~/projects, else a temp
# dir); reruns refuse until it is finished or removed.
#
# Usage:
#   sandbox_sync [target-branch]    # default target: sandbox

function sandbox_sync -d 'Merge the current branch into sandbox via an ephemeral worktree'
    set -l target sandbox
    if set -q argv[1]
        set target $argv[1]
    end

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "sandbox_sync: not inside a git checkout" >&2
        return 1
    end
    set -l branch (git branch --show-current)
    if test -z "$branch"
        echo "sandbox_sync: detached HEAD; check out the feature branch first" >&2
        return 1
    end
    if test "$branch" = "$target"
        echo "sandbox_sync: already on $target; nothing to merge" >&2
        return 1
    end
    set -l gitdir (git rev-parse --path-format=absolute --git-common-dir)

    # Warn (not block) when local commits haven't been pushed: the
    # sync includes them, briefly putting $target ahead of the PR.
    set -l TAB (printf '\t')
    set -l counts (
        git rev-list --left-right --count "$branch@{upstream}...$branch" 2>/dev/null \
            | string split $TAB
    )
    if test (count $counts) -eq 2; and test $counts[2] -gt 0
        echo "Warning: $branch has $counts[2] commit(s) not on its upstream; syncing them too." >&2
    end

    # Ephemeral worktree location: inside the project when run from a
    # ~/projects checkout so conflicts resolve with project context.
    set -l syncdir
    set -l tmp_parent
    set -l pfile (__work_project_file (pwd))
    if test -n "$pfile"
        set syncdir (dirname $pfile)/.sandbox-sync
    else
        set tmp_parent (mktemp -d)
        set syncdir $tmp_parent/sync
    end
    if test -e $syncdir
        echo "sandbox_sync: $syncdir already exists -- a previous sync is unfinished." >&2
        echo "Finish it (add + commit, then push origin HEAD:refs/heads/$target)" >&2
        echo "or discard it:" >&2
        echo "  git -C $gitdir worktree remove --force $syncdir" >&2
        return 1
    end

    git -C $gitdir fetch origin $target
    or begin
        echo "sandbox_sync: could not fetch origin/$target" >&2
        return 1
    end
    git -C $gitdir worktree add --detach $syncdir origin/$target
    or return 1

    set -l attempt 0
    while true
        set attempt (math $attempt + 1)
        if not git -C $syncdir merge $branch --no-edit
            echo "" >&2
            echo "Merge conflict merging $branch into $target." >&2
            echo "Sync worktree left at $syncdir -- resolve there (union /" >&2
            echo "keep-both is the default when both sides added content), then:" >&2
            echo "  git -C $syncdir add -A" >&2
            echo "  git -C $syncdir commit --no-edit" >&2
            echo "  git -C $syncdir push origin HEAD:refs/heads/$target" >&2
            echo "  git -C $gitdir worktree remove $syncdir" >&2
            echo "If the push is rejected ($target moved while resolving):" >&2
            echo "  git -C $syncdir fetch origin $target" >&2
            echo "  git -C $syncdir merge --no-edit origin/$target" >&2
            echo "then push again (repeat if needed)." >&2
            return 1
        end
        if git -C $syncdir push origin HEAD:refs/heads/$target
            break
        end
        if test $attempt -ge 3
            echo "sandbox_sync: push rejected $attempt times; giving up." >&2
            git -C $gitdir worktree remove --force $syncdir
            test -n "$tmp_parent"; and rmdir $tmp_parent 2>/dev/null
            return 1
        end
        echo "Push rejected ($target moved); re-merging onto the new tip..." >&2
        git -C $syncdir fetch origin $target
        git -C $syncdir reset --hard origin/$target
    end

    git -C $gitdir worktree remove $syncdir
    test -n "$tmp_parent"; and rmdir $tmp_parent 2>/dev/null
    echo "Synced $branch into origin/$target."
end
