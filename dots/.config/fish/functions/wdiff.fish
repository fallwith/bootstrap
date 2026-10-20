# wdiff -- display a git diff for a work.fish project
#
# Usage:
#   wdiff <UNIQUE_START_OF_PROJECT_DIRECTORY_NAME> perform a git diff against
#                                                  the current worktree(s)
#
# Options:
#   -l/--list      list the files involved with the diff
#   -r/--revision  the revision for the diff 

function wdiff --description 'Provide a git diff for a work.fish project'
    set -l dirstart $argv[1]
    argparse 'l/list' 'r/revision' -- $argv
    for path in (find ~/projects/{$dirstart}* -name .git)
      set -l dir (dirname $path)
      echo -e "$dir\n======"
      if set -q _flag_list
        git -C $dir diff --cached --stat
      else if set -q _flag_revision
        # git -C $dir rev-parse HEAD
        git -C $dir write-tree
      else
        git -C $dir diff --cached
      end
      echo -e "\n\n"
    end
end
