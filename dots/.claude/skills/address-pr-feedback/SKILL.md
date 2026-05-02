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
it targets the current repo. If a URL is given, extract owner/repo/number. If no
argument is given, detect the PR from the current branch:

```bash
gh pr view --json number,headRepositoryOwner,headRepository
```

If the current branch has no associated PR, stop and ask the user.

## Procedure

### Step 0 -- Preflight

Verify the GitHub CLI is authenticated:

```bash
gh auth status
```

If not authenticated, stop and tell the user to run `gh auth login`. Don't try
to proceed -- API calls will fail with confusing 401s.

Then fetch the PR metadata you'll reference throughout the rest of the
procedure:

```bash
gh pr view <number> --json number,title,url,headRefName,baseRefName,headRepositoryOwner,headRepository
```

Store these values. Specifically:

- `headRepositoryOwner.login` and `headRepository.name` -- used in every
  `repos/<owner>/<repo>/...` API path
- `headRefName` -- used in Step 5 to verify the PR branch is checked out
- `title`, `url` -- useful for the Step 9 summary

### Step 1 -- Fetch review comments

Use `--paginate` on every fetch -- without it the GitHub API caps responses at
30 items and silently truncates. PRs with more than 30 comments (or reviews,
or issue comments) will appear shorter than they really are.

```bash
gh api --paginate repos/<owner>/<repo>/pulls/<number>/comments \
  --jq '.[] | {id, in_reply_to_id, path, line: (.line // .original_line), body, user: .user.login}'
```

Also fetch top-level PR issue comments. These are routinely used by bots
(CodeRabbit, etc.) to post review findings, often packing multiple findings
into one comment body:

```bash
gh api --paginate repos/<owner>/<repo>/issues/<number>/comments \
  --jq '.[] | {id, body, user: .user.login}'
```

And fetch top-level review bodies -- the summary text attached to "Request
changes" or "Comment" reviews. These often carry the highest-priority feedback
and are distinct from line-level review comments:

```bash
gh api --paginate repos/<owner>/<repo>/pulls/<number>/reviews \
  --jq '.[] | select(.body != null and .body != "") | {id, body, state, user: .user.login}'
```

### Step 2 -- Group into threads

Group review comments by thread. A comment is a thread root if
`in_reply_to_id` is null. Replies share the same `in_reply_to_id` as the root's
`id`. For each thread, track:

- **Root comment**: the original feedback
- **Replies**: any existing responses (to avoid duplicating prior discussion)
- **File and line**: where the comment targets
- **Suggested change**: if the comment includes a ` ```suggestion ` block

Tag each thread with `isResolved` and `isOutdated` so you can apply the right
handling later:

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
            nodes { databaseId author { login } }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
  | {threadId: .id, isResolved, isOutdated,
     rootCommentId: .comments.nodes[0].databaseId,
     author: .comments.nodes[0].author.login}'
```

**Filtering rules:**

- **Resolved threads** (any author): skip entirely. They're already handled.
- **Outdated threads from humans**: include in the assessment. Reviewer effort
  deserves a response, even when GitHub considers the line gone -- ghosting is
  rude. They get a reply (often a courtesy ack like "addressed in <sha>") even
  if no further code change is needed.
- **Outdated threads from bots** (`*[bot]` user.login): skip. Bots don't notice
  silence and outdated bot findings are usually stale.

**Bot issue comments**: Some bots (e.g., CodeRabbit) post their findings as
top-level issue comments rather than line-level review comments, often packing
multiple findings into one comment body. Parse these into separate assessment
rows -- treat each finding as its own thread, not the whole comment as one
item.

Map each thread ID to its root comment ID so you can resolve threads later.

### Step 3 -- Assess each comment

For each thread that needs a response, read the feedback and the targeted code.
Produce an assessment with one of these verdicts:

| Verdict | Meaning |
|---|---|
| **Agree -- will fix** | The feedback is correct and actionable. A code change is needed. |
| **Agree -- already addressed** | Valid point but already handled (e.g., by a prior commit). Just reply. |
| **Answer -- no code change** | The reviewer asked a question or requested context. Reply with the answer; no code change. |
| **Disagree -- will explain** | The feedback is incorrect or based on a misunderstanding. Reply with rationale. |
| **Subjective -- needs your input** | Reasonable people could disagree. Present both sides to the user. |
| **Unclear -- needs your input** | The comment is ambiguous; you need clarification before deciding how to respond. |
| **Outdated -- courtesy ack** | The thread is marked outdated but is human-authored. Reply briefly to acknowledge; no code change, no resolve. |

**Important:** Include ALL comments in the assessment table -- even ones that have
already been replied to by the user or are otherwise handled. Use a verdict like
"Already addressed" so the user can confirm nothing was missed. Never silently
skip a comment.

**Emoji reactions on comments** (e.g., +1, thumbs up) from other reviewers
indicate additional support for the feedback. Note these in the assessment -- a
comment with multiple supporters carries more weight than one without.

For each comment, read the relevant code context. If you have the PR branch
checked out, use the Read tool on the file directly. Otherwise:

```bash
# Get the head SHA of the PR
gh pr view <number> --json headRefOid --jq '.headRefOid'

# Read the file at the comment's targeted line (with surrounding context)
git show <head_sha>:<path> | sed -n '<line-10>,<line+10>p'
```

Read ~20 lines of surrounding context, not just the targeted line, so the
verdict is grounded in the actual current state of the code rather than the
comment's description of it. The line referenced in a comment may have moved
or been replaced; always confirm what's actually there now.

When a comment includes a ` ```suggestion ` block, evaluate whether the suggested
change is correct and an improvement. Suggestions are not automatically right --
assess them with the same rigor as any other feedback.

**Bot vs. human suggestions:** Check the `user` field to determine if a comment
came from a bot (e.g., `github-actions[bot]`, `reviewdog[bot]`, any `[bot]`
suffix). This distinction matters for how suggestions are handled:

- **Human reviewer suggestions**: Prompt the user to click the "Commit
  suggestion" button in the browser. This gives the reviewer contributor credit
  and guarantees their exact wording is captured. Do not apply these locally.
- **Bot suggestions** (linters, formatters, static analysis): Apply these
  directly in code -- there is no contributor credit concern. When multiple bot
  suggestions target the same file or follow the same pattern (e.g., several
  RuboCop alignment fixes), batch them into a single edit pass and a single
  commit rather than handling each individually.

### Step 4 -- Present the assessment to the user

Show a summary table:

```
| # | File:Line | Verdict | Summary |
|---|-----------|---------|---------|
| 1 | path:42   | Agree -- will fix | Description of the issue and planned fix |
| 2 | path:87   | Disagree -- will explain | Why the current code is correct |
| 3 | path:15   | Subjective -- needs your input | The tradeoff involved |
```

For "Subjective" and "Unclear" items, present the details and ask the user how
to proceed before taking action. Wait for their input.

For "Agree -- will fix" and "Agree -- already addressed" items, briefly describe
the planned response and ask the user to confirm before proceeding. Something
like: "I'll make the fixes for items 1, 4, 5 and reply to all threads. Items 3
and 6 need your input. Sound good?"

### Step 5 -- Make code changes

**Verify the PR branch is checked out** before editing anything. Compare the
current branch against the PR's `headRefName` from Step 0:

```bash
test "$(git branch --show-current)" = "<headRefName>"
```

If they don't match, check out the PR branch (`gh pr checkout <number>`) or
stop and ask the user. Editing files on the wrong branch silently lands the
fix in the wrong place.

For each "Agree -- will fix" item, edit the code. Follow these principles:

- Read the file before editing.
- Make the minimum change that addresses the feedback.
- Don't introduce unrelated changes.

**Group edits by file.** When multiple "Agree -- will fix" items target the same
file, address them in a single pass: read the file once, apply all edits
together, save. This produces a cleaner diff and avoids re-reading the same
file. Track which comments each edit addresses so the commit message and
replies remain accurate.

### Step 6 -- Verify, commit, and push

**Pre-commit gate (hard requirement):**

1. **Lint every changed file** using the project's configured linter. Examples:
   - Ruby: `bundle exec rubocop <changed_files>`
   - Fish: `fish -n <file>` and `fish_indent --check <file>`
   - TypeScript / JS: the project's eslint command on the changed paths
   Fix any lint violations introduced by the change before committing.
2. **Run relevant specs.** Any change to `app/**` or `spec/**` triggers a spec
   run. For a Rails project, run the spec file(s) corresponding to each changed
   app file plus any spec files that were directly modified:
   `bundle exec rspec <spec_files>`. Don't commit if specs fail.

Both gates must pass. If either fails, fix the issue or escalate to the user --
never `--no-verify` or skip the spec run.

**Commit:**

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

### Step 7 -- Draft, approve, and post replies

For each thread (regardless of verdict), draft a reply matching the templates
below. Don't post anything yet -- the user reviews drafts as a batch first.

#### Reply templates

**Agree -- will fix / already addressed:**
> "{Acknowledgment phrase}, addressed in {short sha}. -- {attribution}"

Use varied acknowledgment phrases: "Good call", "Agreed", "Yep", "Good catch",
"Fair point", etc. Don't use the same phrase for every comment.

**Answer -- no code change:**
> A direct, concise answer to the reviewer's question. End with an offer for
> follow-up if appropriate.

**Disagree -- will explain:**
> A concise, respectful explanation of why the current approach was chosen.
> Not dismissive -- acknowledge the reviewer's perspective, then explain.

**Subjective -- needs your input:**
> Whatever the user decided in Step 4, phrased as a collaborative response.

**Unclear -- needs your input:**
> The answer, if the user provided one in Step 4.

**Outdated -- courtesy ack:**
> Brief acknowledgment. If you can identify the SHA where the relevant code
> was reworked (e.g., via `git log --oneline <path>` or `git log -p <path>`),
> reference it: "Got reworked in {short sha} -- the original concern no
> longer applies. -- {attribution}". If the SHA isn't readily findable
> (older PR, code moved across renames, etc.), degrade gracefully:
> "The surrounding code was reworked since this comment -- original concern
> no longer applies. -- {attribution}". Don't spend effort hunting for a SHA
> that won't materially help the reviewer.

#### Approval gate

Once all drafts are written, present them as a batch:

```
| # | Thread (file:line) | Verdict | Draft reply |
|---|--------------------|---------|-------------|
| 1 | foo.rb:42          | Agree -- will fix | Good catch, addressed in <sha>. -- Claude & James |
| 2 | bar.rb:88          | Disagree -- will explain | We're keeping the current approach because... |
| 3 | baz.rb:15          | Answer -- no code change | The reason this uses a class method is... |
```

**Wait for the user to approve, edit, or skip specific drafts.** Never post
without explicit approval -- these go to human reviewers and can misrepresent
reasoning if the draft is off. The user may want to rephrase Disagree/Answer
replies in particular.

#### Posting

After approval, post each approved reply. Skip any the user removed.

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  -f body="<reply text>" -F in_reply_to=<root_comment_id>
```

For issue-level comments (not review comments), reply with:

```bash
gh api repos/<owner>/<repo>/issues/<number>/comments \
  -f body="<reply text>"
```

### Step 8 -- Resolve threads

**Reply must succeed before resolve.** If a reply call from Step 7 failed
(network blip, body too long, API error), do not resolve that thread -- you'd
end up with a resolved thread that has no response. Resolve only threads whose
reply was confirmed posted.

Resolve threads where the feedback was addressed -- the explicit list of
which verdicts get resolved is below. Use the thread IDs gathered in Step 2:

```bash
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<threadId>"}) {
      thread { isResolved }
    }
  }
'
```

**Resolve** threads with these verdicts after replying:
- Agree -- will fix
- Agree -- already addressed
- Answer -- no code change (when a definitive answer was given)
- Subjective -- needs your input (after the user-decided response)

**Do NOT resolve** threads where:
- The verdict was "Disagree -- will explain" (let the reviewer decide if they
  accept the explanation)
- The verdict was "Unclear -- needs your input" and no definitive answer was given
- The verdict was "Outdated -- courtesy ack" (the thread is already outdated;
  GitHub treats it specially -- a resolve mutation is unnecessary)
- The user explicitly asked to leave it open

### Step 9 -- Summary

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
config) and "Claude". Example: "-- Claude & James"

If the user specifies a different attribution style, use that instead.

## Notes

- This skill works on any GitHub repository accessible via `gh`.
- It handles review comments (line-level), issue comments (PR-level), and
  top-level review bodies (the summary text attached to "Request changes" or
  "Comment" reviews).
- **Always reply to every human-authored thread, including outdated ones.**
  Reviewer effort deserves a response. Bot threads (`*[bot]` user) can be
  filtered when outdated.
- Bot issue comments may pack multiple findings into one comment body. Parse
  each finding as its own thread in the assessment rather than treating the
  whole comment as one item.
- When in doubt about a verdict, err toward "Subjective -- needs your input"
  and let the user decide. Don't auto-resolve things you're unsure about.
- If the PR has a very large number of comments (>20), process them in batches
  and check in with the user between batches.
