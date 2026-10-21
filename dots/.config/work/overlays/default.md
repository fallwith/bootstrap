For any non-trivial task, ensure that the plan includes instructions
to repeatedly make use of the `/simplify` command
until it yields diminishing returns.
After `/simplify`, and before the PR is opened,
the plan must run **`/review-pr`**, if the repository offers
that command -- it is the only repo-level review skill;
do not look for another.
Act on its findings.
Check its documented flags first.
If it supports `--second-opinion` (or `--model both`),
run it with that switch.
The independent second opinion then arrives with this pre-PR pass,
tagged by model, and is triaged like any other `/review-pr` finding.
If the repository offers no `/review-pr`, run the built-in
`code-review` skill on the local changes instead and act on
its findings the same way; it has no `--second-opinion`, so
the Codex review below then provides the second opinion.

Whatever gets changed in response to a review --
`/review-pr`'s or `code-review`'s findings, Codex's, or a
human reviewer's --
re-read the applied hunks before committing.
Review fixes are themselves unreviewed code:
every review pass examined the diff as originally authored,
and a passing spec run does not check the edits that came after
for accuracy, or for consistency with the lines around them.

In a coordinated worker project
(this project's AGENTS.md names a coordinator),
the approval flow described there governs:
the initial commit, every push, PR creation,
and any Sandbox write go through the staged-tree approval
and the routing in AGENTS.md.
The steps below are the mechanics; those gates come first.

After that review pass, the plan should:

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
re-run the review pass (`/review-pr`, or its `code-review`
fallback) against the last gated commit,
so the delta gets reviewed too.
Re-reading the applied hunks does not cover this case:
that work has been examined by nothing at all.
The gates cover the tree at the moment they ran,
so a branch whose scope grew afterwards is effectively
unreviewed however many passes ran before the growth.
`reviewcodex` still runs at most once; `/simplify` and that review
pass (with the same flags as before) are the two to repeat on the
delta.
