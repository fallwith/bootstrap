# Rich GitHub Review

Render comments from `pr_<number>_review.json` without using `review-report`.
That renderer's 50-word compression is intentionally excluded here.

Use `scripts/rearview_workflow.py` for the submission lifecycle. It delegates
schema validation and rendering to `scripts/review_submission.py`. The private
run's plan remains the single source for every byte sent to GitHub.

## Submission Plan

Author the complete plan while normalizing the sidecar after the duplicate
check. Store it under the sidecar's `publication_plan` key. Use this shape:

```json
{
  "publication_plan": {
    "agent": "Codex",
    "event_override": null,
    "review_body_override": null,
    "discussion_check": "rechecked",
    "comments": [
      {
        "finding_number": 1,
        "path": "app/example.rb",
        "line": 42,
        "side": "RIGHT",
        "body": "Exact inline comment without attribution"
      }
    ],
    "duplicates": [
      {
        "finding_number": 2,
        "thread_url": "https://github.com/ORG/REPO/pull/123#discussion_r456",
        "reason": "Same current-head defect and requested correction"
      }
    ],
    "replies": [
      {
        "thread_url": "https://github.com/ORG/REPO/pull/123#discussion_r456",
        "body": "+1, we concur. The caller reaches the same unguarded write."
      }
    ],
    "comment_length_exceptions": [],
    "additional_caveats": []
  }
}
```

Use `null` for `event_override` unless the user explicitly requests an event.
An explicit value must be `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`. The helper
selects the default event from finding severity when the value is `null`.

Use `null` for `review_body_override` unless the user explicitly requests a
high-level review body. Store the exact body without attribution. The helper
validates owned prose and appends attribution. Never infer this override from
the repository, finding, or pull request author.

Set `discussion_check` to `rechecked` for every new Rearview run. The mandatory
pre-lane snapshot read covers the complete discussion even when the review
finds nothing. Before preview, run `discussion-recheck`. `privacy-skipped` and
`not-needed` remain schema-compatible
for recovery of older prepared runs, but do not create either status in a new
run. When privacy rules prohibit complete reading, stop before lanes and
request a redacted discussion export.

Every Critical, High, and Medium finding appears exactly once in `comments` or
`duplicates`. A Low finding may appear in either when useful. Otherwise it
remains local. Stop when a publishable finding has no honest changed-line
anchor and no verified duplicate thread.

Comments outside the 60-120 word target require a
`comment_length_exceptions` entry with `finding_number` and a concrete
`reason`. Do not use an exception merely to avoid editing.

Use `additional_caveats` only for publisher-specific gaps absent from
`sidecar.not_verified`. The helper rejects duplicate additional caveats and
exact repeats of sidecar caveats.

The plan always omits attribution. The helper uses `review_body_override` when
present and otherwise generates a generic body. It appends
`-- <agent> & <configured-user-attribution>` exactly once
to the body and every comment.

## Semantic Duplicates

An existing thread is a duplicate when it already identifies the same
current-head defect, reachable mechanism, and requested correction. A thread
from any reviewer counts. A shared symptom, file, or feature alone does not.

The complete discussion was already read from a private snapshot before lanes.
Use it while verifying lane findings so an author explanation, prior reviewer
report, or bot finding is addressed rather than ignored. Record each
duplicate's finding number, thread URL, and reason in the plan.

For every verified duplicate, draft a short concurrence reply by default.
Address the draft to the existing thread.
Use one or two sentences: acknowledge agreement, then state the specific
mechanism or impact independently verified in this review.
For example: `+1, we concur. <Verified mechanism or impact>.`
Preserve uncertainty; do not claim runtime confirmation from code inspection.
Use first-person plural and append
`-- <agent> & <configured-user-attribution>`.

Store each exact draft and its `thread_url` under `publication_plan.replies`.
The helper appends attribution. Draft once per target, even when several
findings map to it. The preview includes every reply's exact submitted body.
Never leave a draft outside the package awaiting an implicit later decision.

Supported targets are this PR's `#discussion_r<ID>`, `#issuecomment-<ID>`, and
`#pullrequestreview-<ID>` links. Use the root comment for inline threads:
[GitHub does not support replies to replies](https://docs.github.com/en/rest/pulls/comments#create-a-reply-for-a-review-comment).
For an issue comment or review body, the publisher creates a top-level
[issue comment](https://docs.github.com/en/rest/issues/comments#create-an-issue-comment)
with a link to the target. That generated preamble appears in the preview too.

At the publication gate, offer **Publish all**, **Review only**, or **Edit**.
`Publish` and `Publish all` authorize the review and every previewed reply.
`Review only` authorizes the review and explicitly excludes every reply.
Both publication aliases also work when there are no replies.
Publish the selected package without another inclusion question.
The exact response `Approve instead` means `Publish all` for any proposed event,
with the revised review event set to `APPROVE`.
Recast blocking comments as suggestions without changing facts or severity.
Use an encouraging, upbeat tone.
Prepare the revised plan and digest without presenting another preview.
Do not ask another inclusion question.
Preserve every previewed reply body and target.
Pass `--decision "Approve instead"` only after preparing that `APPROVE` plan.
Do not publish anything while reply inclusion is unresolved.
Prose edits or an event change authorize the review
but do not silently include or discard undecided replies.

Run `discussion-recheck` before preview and again after approval. Read the
delta file only when the helper reports a
change, then remove it with `discussion-cleanup`. This catches threads added
during the review or approval pause without rereading unchanged prose. If a
new comment changes a finding or classification, regenerate the preview and
request approval again.

## Preview Artifact

Write `pr_<number>_github_review.md` beside the sidecar.
Use ASCII typography. Include these sections:

1. PR metadata and reviewed head commit.
2. Semantic discussion-check status.
3. Proposed GitHub event.
4. Exact review body.
5. One numbered entry per proposed inline comment.
6. Every extra reply with its exact body, target, and inclusion choices.
7. Unpublished Low and all low-confidence findings excluded from GitHub.
8. Measured review timing.
9. Failed-lane and unverified-work caveats.

Each inline entry names its path, line, and side. Put the exact comment in a
fenced `markdown` block. The helper chooses an outer fence longer than any
fence inside the comment, so Ruby and other code blocks remain intact.

Fetch the pull request's actual base branch before this step. Generate the
private run and preview together. Supply the complete timing log so the helper
can inject measured phase durations into the sidecar:

```sh
python3 <skill-dir>/scripts/rearview_workflow.py prepare-preview \
  --sidecar pr_<number>_review.json \
  --embedded-plan \
  --timing-log <timing-log>
```

This operation is local. It builds the approval diff from the fetched
`origin/<base>` and reviewed head. It copies the validated embedded plan into
a private run, renders the preview, and removes the consumed timing log.
Separate `--plan` files remain supported for recovery and compatibility. The
legacy `prepare` and `preview` commands remain for already prepared runs. Do
not use them to start a new run.

Render the local report from the validated sidecar after timing injection:

```sh
python3 <skill-dir>/scripts/rearview_workflow.py render-report \
  --sidecar pr_<number>_review.json
```

Do not hand-author or patch `pr_<number>_review.md`. Change the sidecar and
render again.

## Inline Findings

Post one thread for every Critical, High, and Medium finding.
Post a Low finding inline when it is useful to the author.
Keep one defect per thread. Do not post the complete report as one comment.

Each comment uses this order:

1. State the user or data impact in plain language.
2. Explain the reachable mechanism with existing identifiers.
3. Ask for the specific correction and its regression coverage.
4. Add code only when it makes the correction clearer.
5. End with `-- <agent> & <configured-user-attribution>`.

Match the request language to severity:

- Critical and High findings request a blocking correction.
- Medium findings request a non-blocking follow-up or an explicit accepted
  disposition.
- Low findings label the suggestion optional.

Do not call a correction optional in the review body while directly requesting
it inline. Do not soften a blocking finding with "consider" language.

Target 60-120 words, excluding code and attribution. Prefer three short
paragraphs. Keep every factual qualifier from the source finding.

Do not repeat a severity label. The review event carries that decision.

## Code Blocks

Use the language of the changed file for an illustrative implementation.
Derive the fence tag from the file extension and the actual syntax. Introduce
the block with `For example:`. The code may use existing identifiers only.
Label pseudocode as a sketch when a required class, method, or field does not
exist.

Use a GitHub `suggestion` block only for a byte-exact replacement. Match the
changed file's indentation. Limit a suggestion to two lines.

Omit code when the fix requires design agreement or a multi-file protocol.
Never present a fabricated class or schema field as an apply-ready fix.

## Review Body

The helper uses `review_body_override` only when the user explicitly supplied
it. Otherwise it derives the body from the event and the severities of findings
classified in comments or duplicate threads.

- Approval with one Medium finding:
  `Looks good overall. The review thread contains a follow-up request.`
- Approval with multiple Medium findings:
  `Looks good overall. The review threads contain follow-up requests.`
- Approval with one Low finding:
  `Looks good overall. The review thread contains an optional suggestion.`
- Approval with multiple Low findings:
  `Looks good overall. The review threads contain optional suggestions.`
- Approval without published findings: `Looks good.`
- Changes requested and comment-only reviews use the same singular/plural rule.
- Comment-only without published findings: `No findings.`

The helper appends attribution.

A custom body may briefly characterize findings already published inline or
recorded as verified duplicate threads. It must not become the sole home of a
finding or replace the required thread. The plan validator enforces that every
Critical, High, and Medium finding remains classified exactly once.

Use first-person plural for attributed prose. End with the attribution.

## Anchors

Anchor to the finding's changed line when it remains in the combined diff.
Use `RIGHT` for added or modified lines. Use `LEFT` for deleted lines.

When the fix belongs in an unchanged file, anchor the changed dependency.
Name the unchanged file in the comment.

Stop when no honest changed-line anchor exists and no verified duplicate
thread covers the finding. Never hide it in the review body.

## Publishing Checkpoint

Show the preview path, event, counts, digest, and exact excluded findings.
Link the preview instead of pasting its entire contents unless the user asks
to see them inline. Wait for explicit permission to publish that digest.

An unambiguous edit request authorizes the revised review once reply inclusion
is explicit; it does not require another routine approval. Clean the active run
before replacing the embedded plan. Preserve the measured
timings already injected into the sidecar. Regenerate with `prepare-preview
--embedded-plan` and no timing log, because the original log was consumed.

## Attribution Validation

Before approval and again before posting, scan the exact review body and every
comment for standalone `I`, `me`, `my`, and `I'm`. Inspect every match. Rewrite
owned prose in first-person plural. Preserve quoted voices, code, and literal
strings; never blind-replace matches.

Confirm the review body and every comment end with the required attribution.

## Posting

After approval, run `discussion-recheck`. Read only a reported delta. If
classifications change, abandon the old run,
re-normalize the sidecar, rerun `prepare-preview`, and request approval of the
new digest.

When the head changes, invalidate approval and review the entire new head.
Equivalent patches do not preserve approval. Present a new gate after the
complete review and freshness checks.

Publish with the approved digest:

```sh
python3 <skill-dir>/scripts/rearview_workflow.py publish \
  --run-dir <run-dir> \
  --approved-digest <digest> \
  --decision "<Publish|Publish all|Review only|Approve instead>"
```

Pass the exact publication decision.
`Publish` and `Publish all` select all previewed replies.
`Review only` excludes them.
The existing `--replies all` and `--replies none` switches remain supported.
`Approve instead` selects every reply and requires the revised `APPROVE` plan.
For other edits, resolve undecided replies first.
With no drafts, either publication alias authorizes the review alone.
The digest binds the review and
all proposed reply bodies and targets. The publisher records the user's
selection before posting and requires the same choice on recovery.

The workflow rechecks freshness and rejects changed artifacts. It verifies the
review before sending selected replies, checks exact bodies and targets before
each reply, and removes the run directory only after all selected items verify.
GitHub has separate review and reply requests: a partial failure can leave some
items posted. Never claim atomic delivery or silently discard the remainder.

If posting may have succeeded but verification stopped, inspect with:

```sh
python3 <skill-dir>/scripts/rearview_workflow.py verify \
  --run-dir <run-dir>
```

If verification reports a missing reply, retain the run. Recheck head and
discussion, then resume `publish` with the same digest and reply selection.
It skips the verified review and existing exact replies. If recovery is blocked,
report the posted links and missing items. Do not clean up an incomplete run.

Use this only to discard an abandoned, unposted run:

```sh
python3 <skill-dir>/scripts/rearview_workflow.py cleanup \
  --run-dir <run-dir>
```

Cleanup removes only named manifest-owned files under `/tmp`. It refuses
symbolic links and unknown entries. The preview, report, and sidecar remain.

Post verification reads `/pulls/<number>/comments` and filters by
`pull_request_review_id`. That preserves current anchor fields.

The report uses `Contributing lanes`. It deliberately does not calculate
`Review entries`. The sidecar does not preserve same-lane multiplicity.
