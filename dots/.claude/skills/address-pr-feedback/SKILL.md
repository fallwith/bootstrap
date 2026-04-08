---
name: address-pr-feedback
description: Read PR review comments, assess each one, make code changes, reply to threads, and resolve them. Works across any repo.
allowed-tools: Bash(gh *), Bash(git *), Read, Edit, Write, Glob, Grep
---

# Address PR Feedback

Reads review comments on a pull request, assesses each one, presents a plan to
the user, makes agreed-upon changes, replies to every thread, and resolves
threads where the feedback was addressed.

## Arguments

The user provides a PR number, URL, or `gh` reference. If only a number is given,
it targets the current repo. If a URL is given, extract owner/repo/number.

## Procedure

### Step 1 — Fetch review comments

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  --jq '.[] | {id, in_reply_to_id, path, line: (.line // .original_line), body, user: .user.login}'
```

Also fetch any top-level PR issue comments (these are less common for code
feedback but sometimes used):

```bash
gh api repos/<owner>/<repo>/issues/<number>/comments \
  --jq '.[] | {id, body, user: .user.login}'
```

### Step 2 — Group into threads

Group review comments by thread. A comment is a thread root if
`in_reply_to_id` is null. Replies share the same `in_reply_to_id` as the root's
`id`. For each thread, track:

- **Root comment**: the original feedback
- **Replies**: any existing responses (to avoid duplicating prior discussion)
- **File and line**: where the comment targets
- **Suggested change**: if the comment includes a ` ```suggestion ` block

Filter out threads that are already resolved or outdated (the comment targets
code that has since been modified by a new commit). To check status:

```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <number>) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 1) {
            nodes { databaseId }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false and .isOutdated == false)
  | {threadId: .id, rootCommentId: .comments.nodes[0].databaseId}'
```

Map each active thread ID to its root comment ID so you can resolve threads
later. Skip threads that are resolved or outdated -- they don't need attention.

### Step 3 — Assess each comment

For each unresolved thread, read the feedback and the targeted code. Produce an
assessment with one of these verdicts:

| Verdict | Meaning |
|---|---|
| **Agree — will fix** | The feedback is correct and actionable. A code change is needed. |
| **Agree — already addressed** | Valid point but already handled (e.g., by a prior commit). Just reply. |
| **Disagree — will explain** | The feedback is incorrect or based on a misunderstanding. Reply with rationale. |
| **Subjective — needs discussion** | Reasonable people could disagree. Present both sides to the user. |
| **Question — needs clarification** | The comment is unclear or asks for input. Flag for the user. |

**Important:** Include ALL comments in the assessment table — even ones that have
already been replied to by the user or are otherwise handled. Use a verdict like
"Already addressed" so the user can confirm nothing was missed. Never silently
skip a comment.

**Emoji reactions on comments** (e.g., +1, thumbs up) from other reviewers
indicate additional support for the feedback. Note these in the assessment — a
comment with multiple supporters carries more weight than one without.

For each comment, read the relevant code context:

```bash
# Read the file at the current HEAD to understand context
```

When a comment includes a ` ```suggestion ` block, evaluate whether the suggested
change is correct and an improvement. Suggestions are not automatically right —
assess them with the same rigor as any other feedback.

**Bot vs. human suggestions:** Check the `user` field to determine if a comment
came from a bot (e.g., `github-actions[bot]`, `reviewdog[bot]`, any `[bot]`
suffix). This distinction matters for how suggestions are handled:

- **Human reviewer suggestions**: Prompt the user to click the "Commit
  suggestion" button in the browser. This gives the reviewer contributor credit
  and guarantees their exact wording is captured. Do not apply these locally.
- **Bot suggestions** (linters, formatters, static analysis): Apply these
  directly in code — there is no contributor credit concern. When multiple bot
  suggestions target the same file or follow the same pattern (e.g., several
  RuboCop alignment fixes), batch them into a single edit pass and a single
  commit rather than handling each individually.

### Step 4 — Present the assessment to the user

Show a summary table:

```
| # | File:Line | Verdict | Summary |
|---|-----------|---------|---------|
| 1 | path:42   | Agree — will fix | Description of the issue and planned fix |
| 2 | path:87   | Disagree — will explain | Why the current code is correct |
| 3 | path:15   | Subjective — needs discussion | The tradeoff involved |
```

For "Subjective" and "Question" items, present the details and ask the user how
to proceed before taking action. Wait for their input.

For "Agree — will fix" and "Agree — already addressed" items, briefly describe
the planned response and ask the user to confirm before proceeding. Something
like: "I'll make the fixes for items 1, 4, 5 and reply to all threads. Items 3
and 6 need your input. Sound good?"

### Step 5 — Make code changes

For each "Agree — will fix" item, edit the code. Follow these principles:

- Read the file before editing.
- Make the minimum change that addresses the feedback.
- Don't introduce unrelated changes.
- If multiple comments target the same file, batch the edits.

### Step 6 — Commit and push

Stage only the files that were changed to address feedback. Commit with a message
that references the feedback:

```
<TICKET>: address PR feedback

[<TICKET>]

<Summary of changes, grouped by theme if multiple comments were addressed>
```

If no ticket number is evident from the branch name or PR title, use a generic
prefix like "CHORE" or ask the user.

Push to the PR's head branch.

### Step 7 — Reply to every thread

For each thread (regardless of verdict), post a reply:

**Agree — will fix / already addressed:**
> "{Acknowledgment phrase}, addressed in {short sha}. — {attribution}"

Use varied acknowledgment phrases: "Good call", "Agreed", "Yep", "Good catch",
"Fair point", etc. Don't use the same phrase for every comment.

**Disagree — will explain:**
> A concise, respectful explanation of why the current approach was chosen.
> Not dismissive — acknowledge the reviewer's perspective, then explain.

**Subjective — needs discussion:**
> Whatever the user decided in Step 4, phrased as a collaborative response.

**Question — needs clarification:**
> The answer, if the user provided one in Step 4.

Reply using:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  -f body="<reply text>" -F in_reply_to=<root_comment_id>
```

For issue-level comments (not review comments), reply with:

```bash
gh api repos/<owner>/<repo>/issues/<number>/comments \
  -f body="<reply text>"
```

### Step 8 — Resolve threads

Resolve threads where the feedback was addressed ("Agree" verdicts and
user-decided "Subjective" items). Use the thread IDs gathered in Step 2:

```bash
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<threadId>"}) {
      thread { isResolved }
    }
  }
'
```

**Do NOT resolve** threads where:
- The verdict was "Disagree — will explain" (let the reviewer decide if they
  accept the explanation)
- The verdict was "Question" and no definitive answer was given
- The user explicitly asked to leave it open

### Step 9 — Summary

Print a final summary:

```
## Feedback addressed

- Committed: <short sha>
- Threads replied to: N
- Threads resolved: M
- Threads left open: K (with reasons)
```

## Attribution

The default attribution suffix for replies is the user's name (derived from git
config) and "Claude". Example: "— Claude & James"

If the user specifies a different attribution style, use that instead.

## Notes

- This skill works on any GitHub repository accessible via `gh`.
- It handles both review comments (line-level) and issue comments (PR-level).
- When in doubt about a verdict, err toward "Subjective — needs discussion" and
  let the user decide. Don't auto-resolve things you're unsure about.
- If the PR has a very large number of comments (>20), process them in batches
  and check in with the user between batches.
