# Personal Claude Code Preferences

**Before adding a rule here:** a rule earns a line only if removing it
would change observable behavior. Restatements do not qualify. A rule
that shapes what gets generated does, even when a linter would also
catch it after the fact.

## Data Privacy and PII Protection (ZERO TOLERANCE)

Overrides convenience in every case. Covers secrets and credentials as
well as personal data. When in doubt, do less.

- **Never fill the context window with PII, and never let PII leave the
  local machine.** Every source without exception: SQL, REPL output, API
  responses, file reads, log searches, clipboard.
- **Never read, print, or enumerate environment variables -- no
  exceptions, and no "just the names."** `env`, `printenv`, `export -p`,
  bare `set`, `echo $FOO`, `ENV.to_h`, and reading a `.env` file, a
  shell rc, or any private config holding exported values are all off
  limits, whatever filter is attached. A filtered listing is not a safe
  listing: a prefix match returns whatever else shares that prefix, and
  the value is in context before either of us sees it coming.
  Unconditional -- it holds when the environment is the obvious place
  to look, and when I think I already know what is in there.
  - **Passing a value in is unaffected.** `FOO=bar cmd` and
    `export PATH="$HOME/.rubies/ruby-<version>/bin:$PATH"` supply a value
    and read nothing back.
  - If a task appears to need an environment value, stop and ask -- do
    not probe, not even for set/unset.
- **SQL: never use `*`.** Determine an explicit allowlist of safe,
  non-PII columns first. An allowlist is required; a denylist (all-but-X)
  is not acceptable.
  - Never extract values from free-form / blob columns (JSONB
    `metadata`, free-text notes). To inspect shape without values,
    select key names only (`jsonb_object_keys(col)`).
  - **A named blocklist outranks that allowance.** Where a project config
    names columns as blocked, they must not appear in a query at all --
    not values, not shape, no key-name listing or existence probe. "I
    know what this particular row holds" is not grounds to reopen a
    block.
  - Prefer aggregates (`count`, `group by` over enums/timestamps): they
    answer most questions and structurally cannot leak row PII.
  - User-level identifiers (user UUIDs, actor ids, emails, phones,
    names, payment details) are PII. Customer/org identifiers are not
    personal PII but are still identifiers -- group by them, never dump
    lists of them.
- **Scope every query and every read to non-PII fields before running
  it.** Do not run a command and then hope the output is clean; never
  pull a whole record "just to look."
- If a task seems to require PII, stop and say so -- propose a PII-free
  alternative (aggregate, hashed/derived signal, or a check I run
  locally without sharing the output).
- **Driving a remote console: data moves file-to-file, and I observe only
  exit codes and non-PII boolean probes.** Do not scrape scrollback into
  tool results; do not capture `rails runner` stdout. Keep data on the
  remote side, write it to a file there, and check it out-of-band --
  present? non-empty? valid JSON? Prefer deny-by-default named
  operations emitting only minimum non-PII fields.

## General Behavior

### Communication Style
- Be direct and concise. Focus on completing the task efficiently.
- Present code changes without verbose commentary about what changed.
- **Lead with raw data and evidence, then offer a draft to react to.**
  I rework drafts in my own words as a deliberate comprehension
  exercise, so optimize for clear, well-organized source material rather
  than paste-ready output. Don't treat my adopting your wording as the
  goal.

### Use the vocabulary that already exists

**Scope: everywhere** -- prose to me, PR bodies, tickets, review
replies, Slack, docs, and identifiers in code.

- **Name the thing the code already names.** If the class is
  `Subscription`, call it `Subscription` -- not "the billing layer".
  An invented compound is unsearchable, and it asserts a boundary that
  may not exist in the code.
- **Renaming an existing identifier is its own change**, with its own
  justification. Never a side effect of editing nearby code.

### Explaining code and systems
- Simple Technical English: short sentences, one idea per sentence.
  Target under ~12 words per sentence; over ~18 is the tell. Never drop
  a fact, a caveat, or a confidence label to hit it -- split the hedge
  into its own sentence instead.
- State the point, then support it. No "it is not X, it is Y", and no
  sentence that withholds its payoff until the end.

### Answer first, then offer to verify
A question phrased as a quick yes/no gets a quick answer, even when the
honest answer is hedged. Do not silently convert it into a multi-minute
investigation -- that spends my time on a decision I was never offered.

- **Lead with the answer you already have, labelled by confidence**, in
  the first sentence. "Ranking needs no VPN; profile building probably
  does -- confident on the first, ~70% on the second" is a useful
  answer.
- **Then offer verification as a choice, with a time estimate.** Wait
  for the reply. Verify unasked only when acting on a wrong answer would
  be destructive or expensive.
- **Flag any command expected to run longer than ~60s before running
  it**, not after -- especially several in a row.
- **Escalating scope needs a checkpoint too.** Noticing mid-answer that
  the real question is bigger is a reason to come back and say so, not a
  licence to keep digging.

### Name the interpretation you chose
- When a request admits more than one reading and I proceed anyway, say
  in one line which reading I took and what I set aside -- rather than
  stopping to ask, which breaks "answer first". Same when reinterpreting
  a stated plan mid-task: say it as it happens, not in the summary
  afterward.

### Tooling preferences
- **Prefer CLI over MCP** wherever a task can be done either way; CLIs
  are dramatically cheaper in context. Fall back to MCP only when no CLI
  covers it.

### Uncertainty
- Never guess without labeling it a guess. Distinguish what you know,
  what you are inferring, and what you are guessing, in language that
  makes the confidence level obvious. This includes comparative claims
  about tools -- no definitive statements without sources.
- **Treat my accounts of what I have experienced as good faith.** If a
  claim sounds implausible, verify it or say plainly "I can't confirm
  this" -- never label it invented. Distinguish "implausible, therefore
  false" (a lazy error) from "I can't independently confirm this" (an
  honest limit). Especially for anything after your knowledge cutoff.
- **Don't dress generic advice as case-specific.** Check whether a
  setting's mechanism actually fires in the situation at hand; if you
  have not checked, label it untested standard advice. When I push back,
  re-derive from data rather than restating the argument -- and never
  cite the same example both for and against a recommendation.

### Push Back
- Push back on unnecessary complexity, footguns, or a better path. The
  bigger the danger, the harder you should push. Programmer-to-
  programmer directness is valued, in both directions.
- If overruled, note the objection and move on.
- If the objection is high-stakes or the back-and-forth has been
  extensive, offer to write a markdown plan file for follow-up.

### Service and Resource Availability
- Surface OS / Homebrew / container (Docker, Colima) unavailability. Do
  not attempt -- **nor offer to attempt** -- to start or troubleshoot
  them unless explicitly asked.

### Linting
- **Before committing, run the project's linter on every changed file it
  supports** -- derive the set from `git diff --name-only`, never from
  the files you consider the "real" change. Specs, factories and rake
  tasks are as in-scope as `app/` code. A passing test run, a
  code-review agent, or manual inspection is not a substitute.
- Fix all new-code violations before committing.
- **Pre-existing violations** surfaced in changed files: follow the
  ownership rules under "Existing Code That Violates Preferences".

### Verification Integrity
- **Never bypass a failing hook or check** (`--no-verify`, skipping CI,
  silencing an assertion) without first confirming the failure is
  pre-existing AND unrelated. A green run produced by silencing the
  check is not a green run. When it is genuinely unrelated debt, prefer
  restructuring so the check passes honestly.
- **Verify with the FULL, unfiltered check, never a scoped subset.** A
  filtered run can pass while the change breaks a file outside the
  filter. Scoped is fine for a fast inner loop; run the whole-project
  check before declaring a change verified.
- **Scale verification to what the changed thing can actually break.**
  Prose, comments, docs, PR bodies and markdown conflicts get
  read-the-hunk treatment: prove nothing was lost, then stop.
  - **A rebase or merge is a code change even when every conflict was
    prose.** The base moved under the branch.
  - **A checked-in file that code loads is code** -- a YAML catalog, a
    fixture, a JSON seed. "Docs" means prose nothing parses.
  - **Say in one clause why you ran or skipped.** The misattribution is
    the failure mode, not the run.
- **Code changed in response to review is unreviewed code.** Re-read the
  applied hunks before committing, especially prose the review told you
  to write. Every review pass examined the diff as originally authored.
- **A low-confidence finding's suggested wording is a draft, not a fix.**
  Rewrite it and verify the claim rather than pasting it in.
- **A review's coverage is a point in time, not a property of the
  branch.** Work arriving after the review has been examined by nothing
  -- re-run the review on the delta. If most of a branch was written
  after its last review pass, the branch is effectively unreviewed.

### Verify against the real consumer, not the stated cause
- **A fix built on a ticket's stated root cause, proven only by mocked
  specs, is unverified.** Mocks prove "we send X", never "X is
  accepted." Read the actual authorizer or consumer -- in another
  service or repo if that is where it lives -- and reproduce against a
  live environment before declaring a fix. A change shipped this way
  once left the bug completely unchanged after deploy.
- **Never silence an observability tool to make an error go away.** Fix
  the path that raises. Suppressing it globally hides real bugs.

### Completeness of enumerated output
- **Distinguish scanning from enumerating.** Truncating a log for
  brevity is fine. When output enumerates a set whose completeness
  determines correctness -- merge conflicts, failing tests, changed
  files, unresolved review threads, N+1 hits -- use the authoritative
  enumerator (`git diff --diff-filter=U`) and read all of it. Never
  narrow the output and then infer "that's all".
- **A search tool returning zero is not proof of absence.** `ug` has
  silently returned zero matches on a ~29,000-line `db/structure.sql`
  where `grep -nE` found three. When a negative would change a
  conclusion, confirm with a second tool.

### Commits
- **Record what changed, not what was debated.** No "Design note: I
  chose X over Y because..." paragraphs -- that belongs in the
  conversation, or the PR description at most.
- **No `Co-Authored-By` trailers for AI assistance.**

### Branch from an explicit start-point
- `git checkout -b <name>` with no start-point silently uses whatever is
  checked out, which is how an unrelated WIP commit gets swept into a
  PR. `git fetch origin <parent> && git checkout -b <name>
  origin/<parent>`.
- Confirm before the first commit: `git log origin/<parent>..HEAD` empty,
  `git status` showing only files you intend.

### Evaluating a merge's scope
- **"What will merging X into Y bring?" is directional**: `git log Y..X`
  or `git diff Y...X`. Never two-dot `git diff Y X` -- on a long-lived
  branch it is dominated by the target's own lead and reads as a huge,
  alarming delta unrelated to the merge.
- **Re-`fetch` shared branches right before reasoning about them.** A
  stale ref turns an accurate command into a confident wrong answer.
- **`git revert -m 1 <merge>` is a recovery trap.** The mark sticks
  through the downstream graph: later three-way merges keep the changes
  reverted even after the originals return by another path. Prefer
  reset, per-commit reverts, or rebuild-and-force-push.

### Review checkpoints
- **Show the full diff -- production and specs -- and wait for approval
  before committing or pushing.** Never commit speculatively. The risk
  is "the commit happened before I saw it," not the order the work was
  written in; spec-first TDD is fine and often preferred.
- **Run `git diff` as its own Bash call.** Bundled with lint or
  verification commands, one nonzero exit collapses the block behind an
  `Error` banner and truncates it mid-hunk. A zero-match `ug` exits 1,
  which is enough to do it. If output was hidden, I have not seen the
  diff -- paste the hunks into the reply.
- On PR branches, especially someone else's, confirm the approach before
  editing when the change is non-trivial.
- If a change spans concerns that could split across PRs, say so before
  committing.

### Existing Code That Violates Preferences
- **My code**: default to opportunistic cleanup when editing.
- **Someone else's code**: leave it alone unless directly related.

### Comments
- Aim for code that needs none: clear naming, obvious structure. Where
  complexity or counterintuitive logic demands explanation -- especially
  performance optimizations -- comments are welcome. 80 columns.

### Error Handling
- Prefer raising intentional exception classes over returning nil or
  error values. Defer to the surrounding code's pattern on conflict.

### Audit the class, not the batch
- When a bug fits "X + Y = broken" and both axes are enumerable, do not
  stop at the reported instance. Cross-product them and flag every
  triggering combination. The enumeration is the deliverable; batching
  into one PR or several is my call.

### Decision-Making Under Uncertainty
- Prioritize: security > performance > resources > maintainability >
  style.
- With no clear winner, present the options and their tradeoffs.

### Pull request descriptions
Audience is a reviewer who has not seen the change. Orient them; do not
retell the work.
- **Keep it shorter than the diff it describes.** A line of why, then a
  bullet per file with what to look at.
- **State the motivating incident neutrally.** "In another session this
  did not work" is enough. Do not dramatize.
- **Be certain of "bug".** If a reviewer could reasonably answer "works
  on my machine, you held it wrong", it is an issue, a fragility, or an
  unmet assumption -- say which. Check the diff for the same overclaim
  before publishing.
- **Pre-empt objections with settled decisions, not open questions.** A
  list of unresolved questions reads as grasping and invites churn.

### Addressing PR Feedback
- Use `/address-pr-feedback`, or follow its ordering: change, commit,
  push, *then* reply. Never tell a reviewer feedback is addressed before
  the commit has landed on the remote.
- **Reply format**: `"{Acknowledgment}, addressed in {short sha}. --
  {attribution}"`. The SHA is not needed for pure explanations.
- **Human reviewer `suggestion` blocks**: prompt me to use the "Commit
  suggestion" button, for contributor credit and exact wording. Do not
  apply locally.
- **Bot suggestions**: apply directly, batched into one edit pass.

### Attribution and Voice

**Scope: prose addressed to other people.** Ticket titles, descriptions
and comments; PR titles, bodies and review replies; Slack; shared docs.
Not commit messages, not source comments or strings, not chat replies.
This rule previously lived under "Addressing PR Feedback" and got read
as PR-only because of it; it governs **every** artifact in that list.

- **Attribution**: sign off "-- Claude & $USER" on any such text Claude
  drafted. Solo credit only when I drafted it and Claude merely edited.
- **Match the voice to the attribution**: co-credited text is
  first-person *plural* throughout. Never "I", "me", "my" -- including
  hedges: "we could not verify", "we did not read that code".
- **Two things keep singular voice**: a quoted voice that is not ours,
  and literal strings inside backticks. Do not blind-replace `I` -- it
  mangles both.
- **Write it plural from the start, and scan before filing.** Intention
  alone has proven unreliable -- four tickets once shipped singular with
  no attribution. Grep for `\bI\b`, `\bmy\b`, `\bme\b`, `I'm`, and
  confirm the sign-off.

### Whitespace and Formatting
- **Markdown prose**: semantic line breaks -- break at sentence and
  clause boundaries, not a fixed column, with an 80-column soft cap and
  2-space continuation indent inside bullets.
- Max 120 characters for code, all languages.
- **Opening characters**: start `[`, `(`, `{` on the same line as what
  they are passed to or assigned to.
- Strip trailing whitespace from every file you touch, every time, any
  file type. Ensure a final newline.

### Typography - ASCII Only
**Scope: shared artifacts** -- anything leaving the direct conversation:
tickets, Slack, PR titles and bodies, source strings and comments,
commit messages, docs. Unicode typography is fine in chat replies.
Intention alone has proven unreliable, so scan before claiming
compliance.
- No em dashes (use ` -- `), no smart or curly quotes, no Unicode
  ellipsis (use three dots), no Unicode bullets, no non-breaking spaces.
- **Do not modify content inside backticks.** Treat it as literal.
- Capitalize product and framework names in prose -- "Lambda", "Rails".
  The sole exception is a brand that styles itself lowercase.

## Claude Code Bash Tool

- **The `Bash` tool runs `/bin/zsh`, not bash.** No `declare -A` or
  `${!arr[@]}`. zsh does NOT word-split unquoted variables: `for x in
  $var` iterates once over the whole string. For list iteration use
  `printf '%s\n' a b c | while read x; do ...; done`. Verify a
  single-item case before looping over many.
- **Environment variables do NOT persist between calls** -- only the
  working directory does. Anything a command needs must be set in that
  same command.
- **The default timeout is 120s and kills longer waits silently.** Pass
  `timeout:` for anything slow. Block on the real artifact rather than
  polling, and confirm which file actually receives the output you mean
  to read -- a wrapper's log is not the redirect target. If an attempt
  yields no new information, change the approach; repeating an unchanged
  command cannot produce a different result.
- **Under `noclobber`, `>` onto an existing file fails** -- and the next
  command in the same invocation still runs, against the STALE file.
  `rm` first, use a fresh name, or force with `>|`, then verify the
  downstream effect rather than trusting the success output.

### Selecting a language version

The tool's shell inherits the login PATH, which carries the newest
installed version, not the project's pin. With a shim-less manager
(chruby) a pinned `.ruby-version` is quietly ignored and `bundle exec
rspec` fails with `bundler: command not found: rspec` -- which reads
like a missing gem rather than the wrong interpreter. Prefix every
invocation, reading the version from the project's own pin:

```bash
export PATH="$HOME/.rubies/ruby-<version>/bin:$PATH" && bundle exec rspec <path>
```

A shell function will not help: `fish -c 'setruby'` mutates a subshell
that exits immediately.

## Ruby

Match the culture of the Ruby community (MINASWAN).

### Idiomatic Ruby & TIMTOWTDI
- Prefer idioms native to the language: postfix conditionals, guard
  clauses, `unless`, blocks as first-class constructs, expressive
  one-liners where they read clearly.
- **TIMTOWTDI.** Where several idiomatic approaches exist, favor the one
  fitting the surrounding code's personality. Consistency comes from
  taste, not from always picking the same hammer -- so when enhancing
  existing code, match what the majority there already does.
- **Use the latest Ruby syntax** the project supports -- check
  `.rubocop.yml` target version, then Gemfile, then `.ruby-version` /
  `.tool-versions`.
- **Hash syntax**: Ruby 1.9 (`key: value`), except string keys, which
  take a hash rocket (`'key' => value`).
- **Strings**: interpolation over concatenation; single quotes unless
  interpolating, then double.
- **Block syntax**: `{}` when the primary purpose is to return a value,
  `do..end` when it is to execute code -- but defer to project RuboCop
  rules.
- **Collection size**: `#size` over `#length` or `#count` for arrays and
  hashes.
- **`allow_nil` over `nil` in inclusion validations**:
  `validates :field, inclusion: { in: [true, false] }, allow_nil: true`.
- **Extract at two occurrences, not three.** Applies to shared methods,
  `let` blocks, `before_action` callbacks, query scopes.

### Method Organization
- Standard Rails classes follow Rails conventions. Other classes: group
  by visibility, alphabetize within each group.

### Security
- **`sanitize_sql_like` does not prevent SQL injection** -- it escapes
  LIKE wildcards (`%`, `_`), not quotes. Use `?` bind placeholders for
  user input.
- **Never expose raw exceptions to API clients.** Log server-side,
  return a generic message.

### Database
- **Wrap multiple operations in `ActiveRecord::Base.transaction
  do..end`** -- everything that should succeed or fail together.
- **Push work to the database.** Prefer `DISTINCT ON`, `COUNT`,
  aggregate `WHERE` over loading records into Ruby to filter or dedup.
- **Prevent N+1 queries.** Any iteration touching associations must
  `includes`/`preload`. A hard gate, added proactively rather than after
  review feedback.
- **`#size` over `#count` on relations.** `count` always issues a SQL
  COUNT; `size` reuses already-loaded records or a counter cache;
  `length` loads the whole relation into memory. The exception is a
  loaded-but-stale relation, where `count` is what you want.
- **Park repeated computation in constants** -- a `.to_a` or `.freeze`
  on a static value during every invocation belongs in a constant.

### Rails Console Snippet Format
- Wrap multi-line chains in parentheses: IRB treats a leading `.` as a
  new statement. On assignment, the parens wrap the right-hand side.
- End with `;nil` to suppress echo.
- **A snippet that retrieves data must print or assign the result** --
  `(...);nil` alone silently discards it. `pp` preferred. Side-effect-
  only snippets need neither.

```ruby
pp(User.joins(:posts)
  .where(posts: { published: true })
  .limit(10)
  .pluck(:email));nil
```

### Testing Approach - Test-Driven Development (TDD)
- **The test diff alone should tell the complete story of the change.**
  Tests are the desired behavior -- get alignment there first.
- **Always write failing tests first.** For bugfixes they must
  explicitly fail against the unmodified code.
- Real object instantiation over mocking where possible. Follow the test
  patterns and conventions already in the codebase.
- Only the minimum code to pass, then refactor while keeping the tests
  green.
- **100% isolated coverage**: each `.rb` file hits 100% running only its
  own spec file.
- **Full branch coverage on changed code**: Codecov tracks each branch
  independently, so exercise both sides of every `if`/`unless`/ternary
  the change touches.

### Test Style
- **Minitest assertions in RSpec**: `assert`/`refute` over
  `expect().to be true/false`.
- **`be` over `eq`** for direct value comparisons.
- **Test both sides of filters.** Create data that should be excluded
  and verify it is -- matching-only data proves nothing about filtering.
- **Assert on specific records, not counts.** `include(expected_record)`
  over `results.size`; counts break under parallel test runs.
- **Be cautious with `let_it_be`** -- records survive across examples but
  `DatabaseCleaner` truncation can delete them between examples. Use
  `let!` when the cleaning strategy needs per-example setup.

### Test Naming & Easter Eggs
Descriptive variable names matching the object type; creative string
values from these:
- **Numbers**: 1138 (THX-1138), 8675309 (Jenny)
- **Characters**: The Wind in the Willows (Mole, Rat, Badger, Toad)
- **Animals**: foxes and tapirs
- **Bands**: New Order, The Cure, Human Tetris, Ministry
- **Comedy**: Monty Python, Still Game, Blackadder
- **Teas**: Ceylon, Nilgiri, Assam, Kenyan, Scottish/Irish/English
  Breakfast, Puerh, Darjeeling, Lao Cha Tou, Dragonwell, Oolong --
  unflavored, no oils
- e.g. `create(:school, name: 'Ratty Elementary')`,
  `let(:blend) { 'Lao Cha Tou' }`

### Code Review
- **Approve-with-suggestions over blocking** when the PR is a net
  improvement. Don't block on polish.
- **Check FE/BE contract alignment** when changing API responses, enum
  values, or category assignments.
- **Settle a cheap finding before filing it.** If a search or a grep
  would confirm it in minutes, do that first, then file a concrete
  defect or nothing. Passing a reviewer's "I could not verify this"
  through unchanged is not neutral -- on someone else's in-review ticket
  it reads as implied rework. Reserve unverified flags for what is
  genuinely out of reach, say what you tried, and post the close-out
  explicitly if it later clears.

## Fish Shell
- `set -l` inside `if`/`else`/`for` does NOT persist to the enclosing
  function scope. Declare before the conditional and assign inside, or
  use a command-prefix (`set -l cmd git --flag=value`, then `$cmd args`).
- Linting: `fish -n <file>` syntax, `fish_indent --check <file>` format.
- Custom fish functions are unavailable in plain bash -- invoke via
  `fish -c 'command args'`.

## Personal Preferences
- **Spelling**: "grey", not "gray".
- **Search**: `ug` (ugrep), not `grep`. Regex is the default; `-F` for
  fixed strings.
- **Pass `--no-line-number` when piping `ug` into another command.** A
  `~/.ugrep` config enabling `line-number` applies to stdin too, so
  `git diff --name-only | ug '\.rb$'` yields `3:app/foo.rb` and the next
  command gets a path that does not exist.
