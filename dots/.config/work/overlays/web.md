For any non-trivial task, ensure that the plan includes instructions
to repeatedly make use of the `/simplify` command
until it yields diminishing returns.
If the repository offers a `/review-pr` command,
the plan must make use of it after `/simplify`.

After `/review-pr`, the plan should:

1. Push the branch and open the PR.
2. Determine the repo slug via
   `gh repo view --json nameWithOwner --jq .nameWithOwner`
   and the PR number via `gh pr view --json number --jq .number`.
3. Invoke the `reviewcodex` fish function
   (it is a fish function, so call it through `fish -c`)
   with three arguments -- the repo slug, the PR number,
   and a findings output file named `codex_review.md`
   placed in the PROJECT root, not the repo worktree
   (when your working directory is the repo worktree,
   that is `../codex_review.md`) --
   to obtain an independent Codex review of the PR.
   Keeping it outside the repo checkout means it never
   shows up as an untracked file and it gets swept into
   the project archive at teardown.
4. Read that findings file, triage each finding,
   address the valid ones
   (skipping or pushing back on any that are wrong),
   and commit and push the fixes.
   Run `reviewcodex` once;
   do not re-run it after addressing its findings.
