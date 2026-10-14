For any non-trivial task, ensure that the plan includes instructions
to repeatedly make use of the `/simplify` command
until it yields diminishing returns.
After `/simplify`, and before the PR is opened,
the plan must run the repository's own review skill,
chosen in this order:

1. **`review-work`**, if the repository offers that skill.
   It reviews the local changes and fixes what it finds, in one pass.
   Acting on it means re-reading the fixes it applied
   and settling the decisions it held back.
   If the repository's own instructions already call for `review-work`
   at the end of implementation, the run after `/simplify` satisfies them.
   Do not also run it before `/simplify`.
2. **`/review-pr`**, if the repository offers that command instead.
   Act on its findings.
   Check its documented flags first.
   If it supports `--second-opinion` (or `--model both`),
   run it with that switch.
   The independent second opinion then arrives with this pre-PR pass,
   tagged by model, and is triaged like any other `/review-pr` finding.

Whatever gets changed in response to a review --
the review skill's fixes or findings, Codex's, or a human reviewer's --
re-read the applied hunks before committing.
Review fixes are themselves unreviewed code:
every review pass examined the diff as originally authored,
and a passing spec run does not check the edits that came after
for accuracy, or for consistency with the lines around them.

After the review skill, the plan should:

1. Push the branch and open the PR.
   Steps 2-4 exist to obtain an independent Codex opinion;
   skip them entirely when `/review-pr` ran with `--second-opinion`,
   which already provided one.
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

If work lands after the gates that is not a review fix --
new scope, or a product decision arriving mid-session --
re-run the review skill against the last gated commit,
so the delta gets reviewed too.
Re-reading the applied hunks does not cover this case:
that work has been examined by nothing at all.
The gates cover the tree at the moment they ran,
so a branch whose scope grew afterwards is effectively
unreviewed however many passes ran before the growth.
`reviewcodex` still runs at most once; `/simplify` and the review skill
(with the same flags as before) are the two to repeat on the delta.
