# worktree - automation for git worktree flows
#
# Prerequisite: PWD must be a git repo clone directory or
# a directory with a .bare subdirectory (except `clone`).
#
# Usage:
#
# `worktree`
#   - fuzzy-find remote branches, create a worktree from
#     the selection
# `worktree <exact name> [base_branch]`
#   - if a worktree exists for the name, cd to it
#   - if a worktree doesn't exist, create it and cd to it
#   - if neither worktree nor branch exist, create both
#     (base_branch defaults to staging)
# `worktree clone <url> [dir]`
#   - bare-clone a repo to ~/git/<dir> with worktree setup
# `worktree list`
#   - list existing worktrees
# `worktree go`
#   - fuzzy-find and cd to an existing worktree
# `worktree rm <exact name>`
#   - remove the worktree and delete the local branch
function worktree --description 'Manage git worktrees'
  if test "$argv[1]" = clone
    if test (count $argv) -lt 2
      echo "Usage: worktree clone <url> [dir_name]"
      return 1
    end

    set -l url $argv[2]
    set -l dir_name
    if test (count $argv) -ge 3
      set dir_name $argv[3]
    else
      set dir_name (string replace -r '.*[:/](.+?)(?:\.git)?$' '$1' $url)
    end

    set -l repo_path ~/git/$dir_name

    if test -d $repo_path
      echo "Error: $repo_path already exists"
      return 1
    end

    mkdir -p $repo_path
    git clone --bare $url $repo_path/.bare
    or return 1

    set -l git git -C $repo_path/.bare

    $git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    $git config push.autoSetupRemote true
    $git fetch

    set -l default_branch (
      string replace 'refs/heads/' '' ($git symbolic-ref HEAD)
    )

    $git worktree add ../$default_branch $default_branch
    or return 1

    cd $repo_path/$default_branch
    return 0
  end

  set -l git git
  if test -d .bare
    for dir in */
      if test -f "$dir/.git"
        set git git -C (realpath $dir)
        break
      end
    end
  else if not git rev-parse --git-common-dir >/dev/null 2>&1
    echo "Error: not in a git repository"
    return 1
  end

  set -l repo_root (realpath ($git rev-parse --git-common-dir)/..)

  switch $argv[1]
    case ''
      $git fetch

      set -l selection (
        $git branch -r | sed 's|^ *origin/||' | grep -v HEAD |
        fzf --prompt="remote branch> "
      )
      if test -z "$selection"
        return 0
      end

      set -l sel_path $repo_root/$selection
      if test -d $sel_path
        cd $sel_path
        return 0
      end
      read -l -P "Create worktree for '$selection'? [y/N] " confirm
      if test "$confirm" != y -a "$confirm" != Y
        return 1
      end
      if $git rev-parse --verify $selection >/dev/null 2>&1
        $git worktree add $sel_path $selection
      else
        $git worktree add $sel_path --track -b $selection origin/$selection
      end
      or return 1
      cd $sel_path

    case go
      set -l selection (
        $git worktree list |
        sed "s|$repo_root/||" |
        fzf --prompt="worktree> " | awk '{print $1}'
      )
      if test -z "$selection"
        return 0
      end
      cd $repo_root/$selection

    case list ls
      $git worktree list | sed "s|$repo_root/||"

    case rm remove
      if test (count $argv) -lt 2
        echo "Usage: worktree rm <branch>"
        return 1
      end

      set -l branch $argv[2]
      set -l worktree_path $repo_root/$branch

      if not $git worktree remove $worktree_path
        echo "Hint: use 'git worktree remove --force $worktree_path' for uncommitted changes"
        return 1
      end

      if $git rev-parse --verify $branch >/dev/null 2>&1
        $git branch -d $branch
      end

    case '*'
      set -l branch $argv[1]
      set -l base_branch staging
      if test (count $argv) -ge 2
        set base_branch $argv[2]
      end

      set -l worktree_path $repo_root/$branch

      if test -d $worktree_path
        cd $worktree_path
        return 0
      end

      $git fetch

      if $git rev-parse --verify $branch >/dev/null 2>&1
        read -l -P "Create worktree for '$branch'? [y/N] " confirm
        if test "$confirm" != y -a "$confirm" != Y
          return 1
        end
        $git worktree add $worktree_path $branch
        or return 1
        cd $worktree_path
        return 0
      end

      if $git rev-parse --verify origin/$branch >/dev/null 2>&1
        read -l -P "Create worktree for '$branch'? [y/N] " confirm
        if test "$confirm" != y -a "$confirm" != Y
          return 1
        end
        $git worktree add $worktree_path --track -b $branch origin/$branch
        or return 1
        cd $worktree_path
        return 0
      end

      read -l -P "Create new branch '$branch' from $base_branch? [y/N] " confirm
      if test "$confirm" != y -a "$confirm" != Y
        return 1
      end
      set -l base_ref
      if $git rev-parse --verify origin/$base_branch >/dev/null 2>&1
        set base_ref origin/$base_branch
      else if $git rev-parse --verify $base_branch >/dev/null 2>&1
        set base_ref $base_branch
      else
        echo "Error: base branch '$base_branch' not found"
        return 1
      end
      $git worktree add $worktree_path -b $branch $base_ref
      or return 1
      cd $worktree_path
  end
end
