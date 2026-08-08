function reviewcodex --description 'Perform a PR review with Codex; write findings, gaps, and a transcript'
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

  # The review format routes findings to the artifact and everything softer --
  # gaps, skipped lanes, low-severity notes -- to the "chat handoff". Only the
  # final message reaches $findings_file, so the handoff material has to be
  # asked for inside it or it is never produced at all. Two clean reviews in a
  # row reported "no Medium-or-higher issues" while a human found ten Lows.
  set -l prompt "PWD has repo $repo PR $pr_num checked out, targeting branch $target_branch. Please use \$review-pr to review the PR. Return the findings as Markdown, following the skill's report format.

Then append a section titled '## Review gaps and low-severity notes' covering: what you could not verify and why; any lane you skipped or that failed; and every low-severity or low-confidence observation you considered but chose not to promote to a numbered finding, one line each. Include that section even when there are no numbered findings, and especially then: a zeroed findings table with no stated gaps is indistinguishable from a review that did not look, and the low-severity items are the ones this review loses most often.

Return only that Markdown -- no tool logs or progress notes."

  # Keep the session transcript. It is the only way to tell a review that ran
  # and found nothing from one that never loaded the skill.
  set -l transcript_file (string replace -r '\\.md$' '' -- "$findings_file")"_transcript.log"

  codex exec \
    --sandbox read-only \
    -C "$reviewdir" \
    -o "$findings_file" \
    "$prompt" >"$transcript_file"

  echo "Findings:   $findings_file"
  echo "Transcript: $transcript_file"
end
