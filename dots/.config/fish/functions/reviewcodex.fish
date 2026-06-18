function reviewcodex --description 'Perform a PR review with Codex and write final findings only'
  if test (count $argv) -ne 3
    echo "usage: reviewcodex <repo> <pr-number> <output-file>" >&2
    return 2
  end

  set -l review_dir_root "$HOME/git/pr_reviews"
  set -l invocation_dir (pwd)

  set -l repo $argv[1]
  set -l pr_num $argv[2]
  set -l findings_file $argv[3]

  if not string match -q '/*' -- "$findings_file"
    set findings_file "$invocation_dir/$findings_file"
  end

  set -l findings_dir (dirname -- "$findings_file")
  mkdir -p "$review_dir_root" "$findings_dir"; or return 1

  set -l repo_slug (string replace -a "/" "_" -- "$repo")
  set -l reviewdir "$review_dir_root/"$repo_slug"_pr_"$pr_num"_"(uuidgen)

  echo "Using $reviewdir to review $repo PR $pr_num"

  gh repo clone "$repo" "$reviewdir"; or return 1
  cd "$reviewdir"; or return 1

  gh pr checkout "$pr_num"; or return 1

  set -l target_branch (gh pr view "$pr_num" --json baseRefName --jq .baseRefName); or return 1

  set -l prompt "PWD has repo $repo PR $pr_num checked out, targeting branch $target_branch. Please use \$review-pr to review the PR. Return all findings in Markdown format. Return only the PR feedback that should be saved to the findings file; do not include session context, tool logs, progress notes, or unrelated explanation."

  codex exec \
    --sandbox read-only \
    -C "$reviewdir" \
    -o "$findings_file" \
    "$prompt" >/dev/null
end
