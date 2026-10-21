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
    set -l prompt "PWD has repo $repo PR $pr_num checked out, targeting branch $target_branch.

If this repository provides a review-pr skill, use \$review-pr $pr_num and follow its workflow and report format.
Otherwise, review this PR directly without requiring or installing a skill:
- Read applicable AGENTS.md instructions and inspect the complete PR diff against the target branch's merge base.
- Trace changed behavior through relevant callers, consumers, and tests.
- Focus on actionable defects introduced by this PR: correctness, security, performance,
  and missing regression coverage.
- Verify candidate findings against the code. Exclude unsupported guesses and personal style preferences.
- Do not modify source files or post anything to GitHub.

For the fallback review, use this Markdown format:
- Start with '## Findings'.
- Include a Markdown table with columns 'Severity' and 'Count', with Critical, High, Medium, Low, and Total rows.
- Group numbered findings under '### Critical', '### High', '### Medium', or '### Low'; omit empty groups.
- Number findings consecutively. Each needs a title, file and line source link pinned to the PR head commit,
  the triggering condition, concrete consequence, and suggested correction. Counts must match numbered findings.
- If there are no findings, keep the zero-count table and explicitly state what was reviewed and the bar applied.

For either review path, return the complete Markdown report in your final response, even if the skill also writes
report files. A report link or summary alone is insufficient: the caller saves only your final response.

Then append a section titled '## Review gaps and low-severity notes' covering:
- What you could not verify and why, including checks not run.
- Any review lane you skipped or that failed, if the workflow uses lanes.
- Every low-severity or low-confidence observation considered but not promoted to a numbered finding, one line each.
Include this section even when there are no numbered findings. Say 'none' only when true.
State whether the repository skill or the fallback review was used.

Return only that Markdown -- no tool logs or progress notes."

    # Keep the session transcript to distinguish a completed review with no
    # findings from a review that stopped early.
    set -l transcript_file (string replace -r '\\.md$' '' -- "$findings_file")"_transcript.log"

    codex exec \
        --profile review \
        -C "$reviewdir" \
        -o "$findings_file" \
        "$prompt" >"$transcript_file" 2>&1

    echo "Findings:   $findings_file"
    echo "Transcript: $transcript_file"
end
