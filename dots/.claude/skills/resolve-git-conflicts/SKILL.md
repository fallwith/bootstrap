---
name: resolve-git-conflicts
description: "Resolve in-progress git conflicts safely in any repo. Use whenever the user asks to fix/resolve merge conflicts, says a merge or rebase is conflicted, pastes a 'CONFLICT (content): Merge conflict in ...' message, or asks you to finish a stuck merge, rebase, cherry-pick, revert, or stash pop. Triages every conflict cheapest-test-first, auto-resolves only what a command can prove, gates on approval for judgment calls, proves no side was silently dropped, finishes the operation with the right command, and gates on approval before pushing."
---

# Resolve Git Conflicts

Resolve the conflicts of an in-progress git operation, with a hard rule:
**auto-resolve only what a command can prove, gate on approval for everything
else.** Never finish an operation with an unexplained deletion in it.

Invocation: `/resolve-git-conflicts [optional guidance]`

Optional guidance is free text the user may supply ("prefer the incoming side
for docs", "skip the tests, CI will catch it", "this branch's config is
authoritative"). It adjusts proposals and may waive a non-kernel check -- but a
waived check must still be **reported as unverified**, and guidance never
converts a judgment call into a provable one.

## The one rule that makes this safe

Your felt confidence is not evidence. Confidence must come from a **structural
property you can demonstrate with a command**, not from understanding what the
code means.

> If you cannot name the command that proves the resolution is correct, the
> conflict needs the user.

"Clearly the intent here is..." is the sound of a judgment call being misfiled
as a provable one.

## The kernel: five things you never skip

Everything else in this skill is routing and investigation. These five are the
trustworthiness, and they cost about five commands:

1. **Detect the operation** (Part 1) -- the finish command differs, and
   `--ours`/`--theirs` invert under rebase.
2. **Capture stages 1/2/3 before staging anything** (Part 1) -- `git add`
   destroys them and the nothing-lost proof becomes impossible.
3. **Prove the resolution** with a named command (Part 2 or Part 3).
4. **Prove nothing was lost**, per file, against both sides (Part 5).
5. **Verify the finish** -- no markers, no unmerged paths, right commit shape
   (Parts 5 and 6).

A kernel check either passes or is reported as
`UNVERIFIED: <check> -- <why>`. It is never silently omitted.

## Effort budget

Match effort to what triage proves, not to how the conflict feels.

| Situation | Budget |
|---|---|
| Single file, all mechanically provable | Under 10 commands, report under 10 lines |
| Several files, all mechanically provable | Under 20 commands, one short table |
| Any judgment call present | Investigate that file properly, **within its blast radius** -- a judgment call about wording in a doc is still a doc; still skip investigation on the provable ones |

Do not read full-file diffs, run blame archaeology, or narrate reasoning for a
conflict that a one-line test already resolved. **Reach Part 2's exit and
stop.**

## Precedence

Repos carry conventions this skill cannot guess: which files are CI-generated,
which branches deploy when pushed, what must happen after a push. Check the
contributor and agent instruction files (`CONTRIBUTING`, `AGENTS.md`,
`CLAUDE.md`, nested per-directory equivalents) and the CI config.

**The user's standing preferences outrank this skill. Project instructions
outrank this skill.** When either conflicts with a default here, follow it and
say so in the report. Notably: if the user has a standing "show me before you
commit" preference, honour it even though Part 2's fast path is otherwise
allowed to commit autonomously.

---

# Part 0: Configure once

Read this on first use, then never again. Both settings make every future
conflict cheaper, which matters if you hit conflicts regularly.

```bash
git config --global merge.conflictStyle zdiff3   # show the merge base inline
git config --global rerere.enabled true          # replay repeated resolutions
```

- **zdiff3** puts the merge base *inside* every conflict hunk, so you can see
  whether a side added or removed without any extra command. It supersedes
  `diff3` (it compacts common lines out of the hunk). This is the single
  highest-value one-time change.
- **rerere** records each resolution and replays it when the same conflict
  recurs. On a long-lived branch that repeatedly merges the same upstream, the
  same hunk conflicts every time; rerere kills that permanently.

**rerere cuts both ways.** When it is on, some hunks come back **already
resolved** from a previous resolution. A replayed resolution is a *claim*, not
a proof -- treat it as a judgment call (Part 3) and verify it, never trust it
silently. Audit with:

```bash
git rerere status   # paths rerere is tracking for this conflict
git rerere diff     # what it changed relative to the conflicted state
```

---

# Part 1: Orient [KERNEL]

## 1a. Detect the operation. Never assume it is a merge.

Conflicts come from five operations that **finish and abort with different
commands**. Use `--git-path` so this works in a worktree, where `.git` is a
file, not a directory:

```bash
git rev-parse -q --verify MERGE_HEAD        # non-empty  -> merge
git rev-parse -q --verify CHERRY_PICK_HEAD  # non-empty  -> cherry-pick
git rev-parse -q --verify REVERT_HEAD       # non-empty  -> revert
ls -d "$(git rev-parse --git-path rebase-merge)" \
      "$(git rev-parse --git-path rebase-apply)" 2>/dev/null  # exists -> rebase
```

If conflicts exist but none match, it is a `stash pop`, `git apply`, or
checkout conflict.

| Operation | Incoming ref | Finish with | Abort with | `--ours` | `--theirs` |
|---|---|---|---|---|---|
| merge | `MERGE_HEAD` | `git commit --no-edit` | `git merge --abort` | current branch (HEAD) | incoming branch |
| rebase | `REBASE_HEAD` | `git rebase --continue` | `git rebase --abort` | **upstream you are rebasing ONTO** | **your replayed commit** |
| cherry-pick | `CHERRY_PICK_HEAD` | `git cherry-pick --continue` | `git cherry-pick --abort` | HEAD (target) | the picked commit |
| revert | `REVERT_HEAD` | `git revert --continue` | `git revert --abort` | HEAD (target) | the revert result |
| stash pop | the stash entry | `git add` + ordinary commit | no abort; `git reset --hard HEAD` | working tree / HEAD | the stashed changes |

**`--ours` / `--theirs` invert under rebase.** This is the most expensive
mistake in this workflow: `git checkout --theirs` during a rebase takes *your*
commit, not the branch you are rebasing onto. The labels stay glued to the same
content while their meaning relative to "the branch I am working on" flips:

| Situation | `--ours` gives | `--theirs` gives |
|---|---|---|
| on `main`, merging `feature` | `main`'s -- the branch you are on | `feature`'s -- incoming |
| on `feature`, rebasing onto `main` | `main`'s -- **not** the branch you are on | `feature`'s -- your own replayed commit |

If you are unsure which side you are holding, confirm with a one-line check
against a known-unique string from each side. Do not guess.

**Aborting is a legitimate resolution.** If the conflict set is large, or the
shape suggests a wholesale reformat/rename, abort and re-approach (Part 3d)
rather than hand-resolving dozens of files.

**Two `stash pop` traps:**

- **It does not drop the stash entry when it conflicts.** After a successful
  resolution the entry is still on the stack; drop it explicitly with a
  re-resolved `stash@{N}`.
- **The stash stack is shared across all worktrees** of a repo -- it lives in
  `refs/stash` in the common git dir, not per-worktree. A bare `git stash pop`
  can apply *another* worktree's work in progress. Never pop without an
  explicitly re-resolved `stash@{N}` (`git stash list` first), and prefer not
  to stash at all mid-conflict.

## 1b. Enumerate. Stop if there is nothing to do.

```bash
git status --short
git diff --name-only --diff-filter=U
```

- **No conflicts and no operation in progress** -> say so and stop. Do not
  invent work.
- **No conflicts but an operation IS in progress** (everything already staged)
  -> report that and offer to finish at Part 6. Do not finish unprompted.

Read the status codes; not all are hunk conflicts:

| Code | Meaning | Route |
|---|---|---|
| `UU` | both modified | triage it (Part 2) |
| `AA` | both added | usually judgment (no common ancestor to reason from) |
| `DU` / `UD` | modify/delete | **always judgment** -- no hunk to merge; one side deleted a file the other edited. Only a human knows whether the deletion or the edit wins. |
| `DD` | both deleted | provable: accept the delete |

`git ls-files -u` confirms exactly which stages exist per path, if you need it.
Its raw output is noisy; pipe it: `git ls-files -u | awk '{print $3, $4}'`.

## 1c. Capture the three stages BEFORE staging anything

This is the step that makes everything downstream possible. `git add` destroys
the stages, and stage 1 (the merge base) is what makes an ambiguous hunk
legible.

```bash
git show ":1:<path>" > /tmp/base     # merge base
git show ":2:<path>" > /tmp/ours     # HEAD / current side
git show ":3:<path>" > /tmp/theirs   # incoming side
```

Two shell hazards, both of which silently produce wrong answers:

- **Quote the `":1:<path>"` argument.** Unquoted, some shells (zsh) read `:1`
  as a path modifier and mangle the ref.
- **If your shell has `noclobber` set, plain `>` onto an existing file fails**
  with "file exists". Use `>|` in zsh. A `set -e` script then dies, or worse
  continues comparing stale files and concludes the two sides are identical.

**Also declare a recovery point.** If you mangle a resolution mid-edit, you can
regenerate the conflict markers from the stages rather than starting over:

```bash
git checkout -m -- <path>          # restore the conflicted state
git checkout --conflict=zdiff3 -- <path>   # same, with the base inline
```

---

# Part 2: Triage, cheapest test first

Run these rungs in order. Each is a one-liner that is silent on success. **Stop
at the first rung that fires** -- a later rung cannot improve on an earlier
one's proof, and investigation (Part 3) becomes unnecessary.

For a single small hunk, reading the conflicted region directly is cheaper than
any diff. Do that first if the file is short.

## Rung 0: path-based -- is this file even hand-mergeable?

Cheapest possible test: look at the filename. No stage reads needed.

**Generated artifacts: regenerate, never hand-merge.** Hand-resolving a
generated file produces a plausible file that matches no source of truth. Take
one side wholesale, then regenerate:

| Artifact | Correct move |
|---|---|
| dependency lockfiles (`Gemfile.lock`, `yarn.lock`, `package-lock.json`, `poetry.lock`, ...) | take one side, re-run the installer |
| translation / string extracts | take one side, re-run the extractor |
| API schema dumps (OpenAPI, GraphQL) | regenerate via the repo's task |
| DB schema dumps / migration snapshots | regenerate by running migrations, or take one side and let CI regenerate |
| source-embedded schema/annotation comment blocks | regenerate with the annotating tool |
| minified / compiled / vendored bundles | rebuild from source |

**Some artifacts can only be regenerated by CI.** If the repo generates a file
in CI and cannot reproduce it locally, do **not** hand-merge it and do not
fabricate it: take one side wholesale, note it in the report, and let CI
produce the real one. Check the CI config and contributor docs to learn which
files these are.

**Binary and submodule conflicts have no hunks.** Images, PDFs, fixtures,
compiled assets, and submodule pointers cannot be merged textually --
`--ours`/`--theirs` is the only mechanism, so the choice is always a judgment
call. Route to Part 3.

## Rung 1: both sides identical

```bash
diff /tmp/ours /tmp/theirs
```

Empty output -> keep either side. (Common after a cherry-pick of a commit that
also landed upstream.)

## Rung 2: whitespace / line-endings / EOF newline only

```bash
diff -w /tmp/ours /tmp/theirs
```

Empty output -> keep the target repo's convention. Note that a
`\ No newline at end of file` difference is its own species and `diff -w` does
not always isolate it cleanly; if that is the only difference, match the repo's
prevailing convention.

## Rung 3: one side of the hunk is empty (adjacent-add)

Two changes landed on neighbouring lines, not the same line. Resolution is the
**union**: keep the non-empty side.

```bash
grep -n -e '^<<<<<<< ' -e '^=======$' -e '^>>>>>>> ' <path>
```

Adjacent marker line numbers (n, n+1) prove the empty side: every `=======`
immediately followed by `>>>>>>>` means the incoming side is empty, and
`<<<<<<<` immediately followed by `=======` means the target side is empty.

## Rung 4: one side subsumes the other

The most common shape on a long-lived branch that repeatedly merges upstream.
One side already contains everything the other side has, plus more -- typically
because a feature branch's content reached the other branch as a **squash
merge**, so the same change looks like two independent additions.

```bash
diff -u /tmp/theirs /tmp/ours | grep -c '^-[^-]'   # 0 -> ours contains all of theirs
diff -u /tmp/ours /tmp/theirs | grep -c '^-[^-]'   # 0 -> theirs contains all of ours
```

**Zero deletion lines proves subsumption**: every line of the subsumed side is
present in the superset, in order, with only additions. Keep the superset;
nothing from the other side can be lost.

**Beware the inverted exit code.** `grep -c` exits **1** when the count is zero,
and zero is the *success* case here. The same inversion applies to the marker
scan in Part 5a: clean output means exit 1. Read the printed count, not `$?`,
and never chain these with `&&` or run them under `set -e` -- the proof
succeeding is what would kill the script.

Then confirm no duplication, which subsumption alone does not rule out:

```bash
grep -c -F '<a distinctive line from the shared block>' <path>   # expect 1
```

**Why this check is mandatory and not belt-and-suspenders:** a duplicated block
appears in the diff as an *addition*, so the nothing-lost proof in Part 5
structurally **cannot** catch it. The two checks are complements.

**Because content, not shas, decides this.** A branch that landed upstream via
squash has a different sha but identical content. Never conclude a side is
missing something by comparing commit lists.

## Rung 5: everything else is a judgment call

Route to Part 3. Explicitly including cases where the answer feels obvious:

- the same line or same function edited on both sides
- one side reordered a list, the other edited it
- one side renamed a symbol, the other edited its body
- `DU` / `UD` modify-delete; `AA` both-added
- binary or submodule conflicts
- anything rerere pre-resolved
- version numbers where neither side is a generated lockfile
- any hunk whose resolution requires knowing product intent

## Whole-side takes

`git checkout --ours/--theirs <path>` resolves the **entire file**. That is
safe only when you have proven it for the whole file -- e.g. a single hunk, or
a subsumption proof that covers every line. With several hunks of different
shapes, it silently discards the other side's unrelated hunks. **Count the
hunks before reaching for it**; otherwise edit hunks individually.

Distinct and often confused: the **strategy** options `-X ours` / `-X theirs`
(passed to `git merge`/`git rebase`) apply only to *conflicting* hunks and keep
all non-conflicting changes from both sides. They are far less destructive than
the checkout flags of the same name, and are the right tool for a bulk
re-approach (Part 3d).

## Fast-path exit

If every conflicted path resolved at rungs 0-4:

1. Apply (Part 4).
2. Run the kernel proofs (Part 5).
3. Finish (Part 6).
4. Report in the short format.

**Do not run Part 3.** Do not read full-file diffs. Do not investigate history.

---

# Part 3: The judgment path

Skip this entirely unless Part 2 sent you here.

## 3a. Investigate (read-only, no approval needed)

Most clarifying first:

1. **Reveal the merge base** -- shows whether a side *added* or *removed*. Free
   if you configured zdiff3; otherwise:
   ```bash
   git checkout --conflict=zdiff3 -- <path>
   ```
   (Or read `/tmp/base` from Part 1c.)
2. **See who changed what on each side:**
   ```bash
   git log --oneline --left-right <target>...<incoming> -- <path>
   git log --merge -p -- <path>     # commits from both sides since the base
   ```
3. **Cleaner hunk boundaries:**
   ```bash
   git diff --diff-algorithm=histogram --diff-filter=U -- <path>
   ```

Form a proposed resolution per conflict, each with the evidence for it.

## 3b. Bound investigation of non-blocking findings

Investigation is cheap per command and expensive in aggregate. Before digging
into a defect you did not cause -- a pre-existing lint violation, a stale
comment, an odd pattern -- ask the gating question **first**:

> Can this defect reach a branch that matters?

```bash
git branch -a --contains <commit that introduced it>
```

If it exists only on a throwaway or integration branch and the
permanent-bound branch is clean, that is the whole answer: one line in the
report, no further archaeology. Investigate properly only when it can
propagate.

## 3c. Gate: one approval for all judgment calls

Present a single table and **wait**:

| File:line | What target did | What incoming did | Proposal | Confidence | Evidence |
|---|---|---|---|---|---|

Rules for this gate:

- Provable resolutions may already be applied; say which.
- Do **not** write judgment-call resolutions before approval.
- If something needs knowledge only the user has (product intent, which
  behaviour is wanted), ask it **in this same gate**. Do not spend a second
  round trip.
- State plainly if a proposal is a guess. A wrong-but-confident resolution is
  worse than an extra question.

## 3d. When to abort and re-approach instead

Hand-resolving does not scale, and a long conflict list usually means the merge
itself is the wrong shape. Consider aborting (Part 1a) and instead:

- **Re-run with a strategy option** -- `-X ours` / `-X theirs` resolves only
  conflicting hunks while keeping both sides' non-conflicting work.
- **Reverse the direction** -- rebase the short branch onto the long one rather
  than merging the long into the short.
- **Regenerate rather than merge** -- for a wholesale reformat or codemod,
  take one side and re-run the tool.
- **Merge in smaller steps** -- merge an intermediate commit first so each
  conflict set stays legible.

Raise this as an option at the Part 3c gate when the conflict count is high;
do not silently grind through 40 files.

---

# Part 4: Apply

- Strip every marker; edit hunks surgically.
- After any union or subsumption resolution, run the **duplicate check** from
  Rung 4. A silent duplicate becomes permanent, and it is detectable.

---

# Part 5: Prove it [KERNEL]

Report each check and its result. Do not assert "verified".

## 5a. No markers left

```bash
grep -rn -e '^<<<<<<< ' -e '^>>>>>>> ' .
```

Match on `<<<<<<< ` / `>>>>>>> ` **with the trailing space**, not on bare
`=======`, which false-positives on markdown setext headings and RST rules.

## 5b. No unmerged paths

```bash
git diff --name-only --diff-filter=U    # expect empty
```

## 5c. Nothing-lost proof -- mandatory, per file

This is the check that actually catches a dropped side. Diff the resolved file
against **both** sides:

```bash
git diff "<incoming-ref>:<path>" -- "<path>"
git diff "HEAD:<path>" -- "<path>"
```

Every **deletion** in either diff must be one you can explain out loud. An
unexplained deletion means a side was dropped -- go back to Part 3a.

Quote the arguments: unquoted `$ref:a...` is read by some shells as a `:a` path
modifier and silently mangles the ref.

**An empty diff is a valid result, not a failed check.** If the incoming side's
change was already present, the resolved file can be byte-identical to HEAD and
`git status --short` will show *nothing*. That is what an already-present squash
merge looks like. Confirm the operation is still live rather than assuming the
resolution vanished:

```bash
git rev-parse -q --verify MERGE_HEAD    # or the relevant *_HEAD
```

## 5d. Lint

Derive the set from the **conflicted paths**, not from `git diff --name-only`.
A no-op resolution has an empty diff but you still want the file's lint state.
Run whatever the project uses, and lint every conflicted file the linter
supports -- specs, fixtures, and config included.

**When lint fails on a pre-existing violation**, apply the gating question from
Part 3b: if it cannot reach a branch that matters, report it in one line and
leave it alone. Never fold an unrelated cleanup into the merge commit (Part 6).
Never silence a check to get past it.

## 5e. Tests -- the check that proves the two sides *compose*

Markers-gone plus nothing-lost proves you did not **drop** a side. It does not
prove the two sides work together. That is a different failure mode, and tests
are the only check for it -- **for files that execute.**

**If no conflicted file executes -- markdown, prose, docs, config the specs
already parse -- 5d and 5e are `N/A`, and `N/A` is a pass, not an
`UNVERIFIED`.** There is no composition to prove: a `.md` file cannot fail a
spec. Do not run a suite because the merge dragged in other commits; those were
tested where they landed. Prove nothing was lost, then finish.

- If a conflicted file **is** a test, run it.
- If a conflicted file **has** a corresponding test, run that.
- Scope to the **narrowest target** covering the resolved hunks. Never the full
  suite.
- A parse or type check (`ruby -c`, project `type-check`) is a useful cheap
  addition but is **not** a substitute.

If you cannot run them -- needs a service you do not have, too slow, the user
waived them -- report `UNVERIFIED: tests -- <why>` explicitly. Do not silently
downgrade to a parse check.

**Do not lean on CI as the backstop without checking that it is one.** On a
branch whose CI is routinely red for unrelated reasons, a green pipeline is not
available as a signal, so local verification matters *more* there, not less.

Never bypass a failing hook (`--no-verify`, skipping a CI step, silencing an
assertion) to reach this point. A green run produced by silencing the check is
not a green run. When a failure is genuinely pre-existing and unrelated, prefer
restructuring the work so the check passes honestly over bypassing it.

---

# Part 6: Finish the operation

Use the Part 1a table -- the finish command depends on the operation. For a
merge, honour the auto-generated message:

```bash
git commit --no-edit
```

For rebase/cherry-pick/revert, prevent an editor from blocking:
`GIT_EDITOR=true git rebase --continue`.

**You get exactly one commit.** A merge commit cannot be split, so anything a
future reader needs is either in this message or in a follow-up commit.
Corollary: **never fold an unrelated cleanup into the resolution commit.**
Chase it with a separate commit afterwards.

**When to add a note to the message.** Default is no edit. Add one only when a
judgment call cannot be re-derived from the diff -- e.g. "kept the target's
version of `foo` because the incoming change was reverted upstream in abc1234".
Mechanical resolutions never merit a note.

To append without losing git's conflict list, build from `MERGE_MSG`:

```bash
msg="$(git rev-parse --git-path MERGE_MSG)"
{ cat "$msg"; printf '\n%s\n' "Resolution note: ..."; } > /tmp/commit-msg
git commit -F /tmp/commit-msg
```

Never rewrite the auto-generated subject line or delete the `# Conflicts:`
list.

Then confirm the shape of what you created:

```bash
git log --format='%h parents=%p%n%s' -1   # a merge must show TWO parents
```

---

# Part 7: Push

**Always stop for explicit approval before pushing.** Show exactly what will
land, including commits swept in from the incoming side that the user may not
expect:

```bash
git fetch origin <branch>
git log --oneline origin/<branch>..HEAD
git rev-list --left-right --count origin/<branch>...HEAD
```

- If the remote moved, **re-merge**. Never force-push a shared branch to
  resolve a conflict.
- After pushing, confirm sync: `git status --short --branch`.

## Know what the push actually triggers

A push is not always just a push. Before pushing, establish what the target
branch does when it moves, and honour any project rules you find.

**Direction determines risk, even between the same two branches.** Pulling a
release branch *into* an integration branch and pushing the integration branch
is routine. Pushing the reverse may ship code. Establish which direction you
are pushing before deciding it is safe.

- **Does pushing this branch deploy, release, or notify anyone?** Many projects
  wire a branch to CI that deploys on merge, publishes a package, or announces
  to a chat channel. If the target is one of those, **stop and hand off** to the
  project's deploy process. A conflict resolution is not the moment to ship.
- **Does the project require a follow-up after every push?** Some repos expect
  a mirror or integration branch re-synced, a label or ticket updated, or a
  changelog entry added. Look in the contributor docs, agent instruction files,
  and CI config; a stale mirror silently misleads whoever relies on it.
- **Is the target shared or throwaway?** On a shared branch, prefer re-merging
  over any history rewrite. On a throwaway branch, cosmetic defects matter
  less -- but still check whether the same defect exists on a branch that *is*
  headed somewhere permanent (Part 3b).

---

# Report

Two formats. Use the short one whenever triage resolved everything at rungs
0-4.

## Short format (fast path)

Under 10 lines:

- **Cause** in one sentence (e.g. "squash artifact: the incoming change was
  already present via the pre-squash branch").
- **Table**: file -> resolution, rung that proved it.
- **Kernel checks**: one line, pass/fail/unverified each.
- **Recurrence**: will this conflict again, and what prevents it.

## Full format (judgment calls present)

1. **What the conflicts were** -- the underlying cause in one or two sentences.
2. **Table**: file:line -> resolution, and whether it was proven or decided.
3. **Verification**: each kernel check and its result, including the
   nothing-lost diffs, and any `UNVERIFIED:` lines.
4. **Recurrence** -- will this conflict recur on the next merge of these
   branches, and what would prevent it (an unlanded branch, a missing rerere
   entry, a generated file that should be gitignored).
5. **Anything pre-existing you noticed but deliberately left alone**, and why.

Write plainly and briefly. Prose only where a judgment needs explaining;
everything provable belongs in the table.

---

# Anti-patterns

Every other rule in this skill is stated where it applies. These two are worth
repeating because they are the ways a resolution goes wrong while looking
right:

- **Filing a judgment call as provable because the intent "is obvious".** If
  you cannot name the command, you cannot skip the gate.
- **Declaring done without the Part 5c nothing-lost diff.** It is the only
  check that catches a silently dropped side, and it is two commands.
