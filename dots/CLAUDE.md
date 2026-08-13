# Personal Claude Code Preferences

## Data Privacy and PII Protection (ZERO TOLERANCE)

This section overrides convenience in every case. When in doubt, do less.
It covers secrets and credentials as well as personal data.

- **Never, under any circumstances, fill the context window with PII,
  and never let PII leave the local machine.** This applies to every
  data source without exception: SQL, REPL/console output, API
  responses, file reads, log searches, clipboard, anything.
- **Never read, print, or enumerate environment variables -- no
  exceptions, and no "just the names."** `env`, `printenv`, `export -p`,
  a bare `set`, `echo $FOO`, `ENV.to_h` in a REPL, and reading a `.env`
  file, a shell rc, or any private config holding exported values are
  all off limits, whatever filter is attached. A filtered listing is
  not a safe listing: a prefix match returns whatever else happens to
  share that prefix, and the value is in context before either of us
  sees it coming. This is unconditional -- it holds when the
  environment is the obvious place to look, and when I think I already
  know what is in there.
  - **Passing a value in is unaffected.** Prefixing a command with
    `FOO=bar cmd`, or with
    `export PATH="$HOME/.rubies/ruby-<version>/bin:$PATH"`, supplies a
    value and reads nothing back. The rules requiring those stand.
  - If a task appears to need an environment value, stop and ask --
    do not probe, not even for set/unset. Ask me to check locally and
    report back only the part that is needed.
- **SQL: never use `*`.** Before running any query, proactively
  determine an explicit allowlist of safe, non-PII columns and SELECT
  only those. An allowlist (name each safe column) is required; a
  denylist (SELECT all-but-X) is not acceptable.
  - Never extract values from free-form / blob columns (e.g. JSONB
    `metadata`, free-text notes) into output. To inspect a JSONB
    column's shape without its values, select key names only
    (e.g. `jsonb_object_keys(col)`), never the values.
  - **A named blocklist outranks this allowance.** Where a project
    config names specific columns as blocked, they must not appear in
    a query at all -- not their values, not their shape, no key-name
    listing or existence probe. The key-names allowance is for columns
    nobody has ruled on, and "I know what this particular row holds"
    is not grounds to reopen a block.
  - Prefer aggregates (`count`, `group by` over enums/timestamps):
    they answer most questions and structurally cannot leak row PII.
  - Treat user-level identifiers (user UUIDs, actor ids, emails,
    phone numbers, names, payment details) as PII. Customer/org
    identifiers (e.g. UUIDs) are not personal PII but are still
    identifiers -- use for grouping, do not dump lists of them.
- **REPL / console output you will consume: take extreme measures with
  zero tolerance for error to ensure PII is not exposed.** Scope every
  query to non-PII fields before running it; do not run a command and
  then hope the output is clean.
- **Any other source (API calls, file reads, etc.): same standard.**
  Project/select only the safe fields; never pull a whole record
  "just to look."
- If a task seems to require PII to proceed, stop and say so rather
  than pulling it -- surface the conflict and propose a PII-free
  alternative (aggregate, hashed/derived signal, or a check the user
  runs locally without sharing the output).
- **Driving a remote console: data moves file-to-file, and I observe
  only exit codes and non-PII boolean probes.** Do not scrape terminal
  scrollback into tool results, and do not capture `rails runner`
  stdout. Keep the data on the remote side, write it to a file there,
  and check it out-of-band -- file present? non-empty? valid JSON? --
  rather than reading it. Prefer deny-by-default named operations that
  emit only the minimum non-PII fields.

## General Behavior

### Communication Style
- Be direct and concise. Focus on completing the task efficiently.
- Present code changes without verbose commentary about what was changed.
- When making comparative claims about tools or technologies,
  explicitly state confidence level and ask for verification if uncertain.
  Avoid definitive statements without sources.
- **Lead with raw data and evidence, then offer a draft to react to.**
  I rework drafts in my own words as a deliberate comprehension exercise,
  so optimize for clear, well-organized source material rather than
  paste-ready output. Don't treat my adopting your wording as the goal.

### Tooling preferences
- **Prefer CLI tools over MCP** wherever a task can be done either way.
  CLIs are dramatically cheaper in tokens and context than MCP
  round-trips. Fall back to MCP only when no CLI covers it.

### Uncertainty
- When you don't know something, say so.
  Never guess without labeling it as a guess.
  "I'm not sure -- let me check" is always acceptable.
- Distinguish between what you know, what you're inferring,
  and what you're guessing.
  Use language that makes the confidence level obvious.
- **Treat my accounts of what I've experienced or observed as good faith.**
  If a claim sounds implausible, verify it with the tools you have, or say
  plainly "I can't confirm this" -- never label it invented. "This sounds
  unlikely" is not evidence of falsehood, especially for anything after
  your knowledge cutoff. Distinguish "implausible, therefore false" (a lazy
  error) from "I can't independently confirm this" (an honest limit).
- **Don't dress generic advice as case-specific.** Before recommending a
  setting, tool, or practice, check whether its mechanism actually fires in
  the situation at hand; if you haven't checked, label it as untested
  standard advice. When I push back, re-derive from data rather than
  restating the argument -- and never cite the same example both for and
  against a recommendation.

### Push Back
- Push back when you see unnecessary complexity, footguns, or a better path.
  The bigger the danger, the harder you should push.
- Welcome push back in return.
  Programmer-to-programmer directness is valued here.
  "That which can be destroyed by the truth, should be."
- If overruled, note the objection and move on.
- If the objection is high-stakes, the danger of proceeding is significant,
  or the back-and-forth has been extensive,
  offer to write a markdown plan file for future follow-up.

### Service and Resource Availability
- Surface any issues related to OS services, Homebrew services,
  or containers (Docker, Colima, etc.) being unavailable. Do not
  attempt -- nor offer to attempt -- to start, restart, or
  troubleshoot them unless explicitly asked to.

### Linting
- **Before committing**, run the project's linter on every changed file
  the linter supports -- derive the set from `git diff --name-only`,
  never from the files you consider the "real" change. There is no
  second-class changed file: specs, factories, and rake tasks are as
  in-scope as `app/` code (e.g., `bundle exec rubocop` for Ruby,
  `fish -n` / `fish_indent --check` for fish). A passing test run, a
  code-review agent, or manual inspection is not a substitute for the
  linter.
- **New code**: Fix all lint violations before committing.
- **Pre-existing violations** surfaced in changed files:
  follow the ownership rules below.

### Verification Integrity
- **Never bypass a failing hook or check to move past it**
  (`--no-verify`, skipping a CI step, silencing an assertion) without
  first confirming the failure is pre-existing AND unrelated to the
  change. A green run produced by silencing the check is not a green
  run. When the failure is genuinely pre-existing, unrelated debt,
  prefer restructuring the work so the check passes honestly -- e.g.
  rebasing to avoid a merge commit that makes a staged-file linter lint
  the whole merged set -- over bypassing it.
- **Verify with the FULL, unfiltered check, never a scoped subset.**
  A filtered type-check / lint / test run gives false confidence: it can
  pass while the change breaks a file not in the filter (e.g. an
  exhaustive map or enum consumer elsewhere in the tree). A scoped run
  is fine for a fast inner loop, but run the whole-project check before
  declaring a change verified.
- **That rule is for code with consumers. Scale verification to what the
  changed thing can actually break.** Prose, comments, docs, PR bodies and
  markdown conflicts get read-the-hunk treatment: prove nothing was lost,
  then stop. A `.md` file cannot fail a spec, so running a suite against
  one buys nothing.
  - **A rebase or merge is a code change even when every conflict was
    prose.** The base moved under the branch, so the risk is what moved,
    not what you edited.
  - **A checked-in file that code loads is code**, however data-like --
    a YAML catalog, a fixture, a JSON seed. "Docs" means prose nothing
    parses.
  - **Say in one clause why you ran or skipped.** The misattribution is
    the failure mode, not the run.
- **Code changed in response to review is unreviewed code.**
  After applying review findings, re-read the applied hunks before
  committing -- especially any prose the review told you to write.
  A passing test run proves the fix did not break anything; it does not
  prove the fix is correct, or consistent with the lines around it.
  Every review pass examines the diff as originally authored, so
  whatever is edited afterwards ships without having been looked at.
- **A low-confidence finding's suggested wording is a draft, not a fix.**
  If the reviewer hedged, the text it proposed has not been checked
  against the surrounding context either. Rewrite it and verify the
  claim rather than pasting it in.
- **A review's coverage is a point in time, not a property of the
  branch.** Re-reading the applied hunks handles the fixes a review
  produced, but not work that merely *arrives* after it: new scope, or a
  decision that lands mid-session. That work has been examined by
  nothing, so re-run the review on the delta rather than only re-reading
  it. Watch for the case where the review ran early and the branch kept
  growing: if most of a branch was written after its last review pass,
  the branch is effectively unreviewed no matter how many passes ran.

### Verify against the real consumer, not the stated cause
- **A fix built on a ticket's stated root cause, proven only by mocked
  specs, is unverified.** Mocks prove "we send X"; they cannot prove "X
  is accepted." Read the actual authorizer or consumer -- in the other
  service or repo if that is where it lives -- and reproduce against a
  live environment before declaring something fixed. A change shipped
  this way once left the bug completely unchanged after deploy.
- **Never silence an observability tool to make an error go away.**
  If a path raises an expected exception, fix that path to handle it.
  Suppressing it globally in the monitoring config hides real bugs --
  a query expected to succeed is exactly the thing you want to keep
  noticing.

### Completeness of enumerated output
- **Distinguish scanning from enumerating.** Truncating a log with
  `head`/`tail`/grep for brevity is fine. But when output enumerates a
  set whose completeness determines correctness -- merge conflicts,
  failing tests, changed files, unresolved review threads, N+1 hits --
  use the authoritative enumerator (`git diff --diff-filter=U`, etc.)
  and read all of it. Never narrow the output and then infer "that's
  all"; a missed item is a silent, confident wrong answer.
- **A search tool returning zero is not proof of absence.** `ug` can
  silently return zero matches on very large or generated files
  (observed on a ~29,000-line `db/structure.sql`, where `grep -nE`
  found three matches it missed). When a negative result would change
  a conclusion, confirm it with a second tool.

### Commit messages record what changed, not what was debated
- When a design trade-off has already been discussed and settled, do not
  add a "Design note: I chose X over Y because..." paragraph to the
  commit body. The debate belongs in the conversation, or in the PR
  description at most -- not in the permanent log.

### Commit authorship
- **Do not add `Co-Authored-By` trailers for AI assistance.** Agent
  involvement is recorded elsewhere -- session history, API usage -- and
  does not belong in commit metadata.

### Branch from an explicit start-point
- `git checkout -b <name>` with no start-point silently uses whatever is
  currently checked out, which is how an unrelated WIP commit gets swept
  into a PR. Fetch first and name the base:
  `git fetch origin <parent> && git checkout -b <name> origin/<parent>`.
- Confirm it before the first commit: `git log origin/<parent>..HEAD`
  must be empty and `git status` must show only files you intend.

### Evaluating a merge's scope
- **"What will merging X into Y bring?" is a directional question,
  so use a directional view**: `git log Y..X`, or the three-dot
  `git diff Y...X`. Never the symmetric two-dot `git diff Y X` --
  on a long-lived branch that is dominated by the target's own
  lead and reads as a huge, alarming delta that has nothing to do
  with what the merge would actually introduce.
- **Re-`fetch` shared branches right before reasoning about
  them.** They move under you between steps, and a stale ref
  turns an accurate command into a confident wrong answer.
- **`git revert -m 1 <merge>` is a recovery trap.** It anti-applies
  everything the merge introduced, and that mark sticks through the
  whole downstream graph: later three-way merges keep the changes
  reverted even after the original commits return by another path.
  Prefer reset, per-commit reverts, or rebuild-and-force-push. See
  git's own "revert a faulty merge" how-to.

### Review checkpoints
- **Show the full diff -- production and specs -- and wait for approval
  before committing or pushing.** Never commit speculatively. The risk
  being managed is "the commit happened before I saw it," not the order
  the work was written in; spec-first TDD is perfectly fine and often
  preferred.
- **Run `git diff` as its own Bash call.** Tool output renders fine on
  a clean exit, but bundled with lint or verification commands, a
  single nonzero exit collapses the whole block behind an `Error`
  banner and truncates it mid-hunk -- so the diff never reaches me.
  Note that a zero-match `ug`/`grep` exits 1, which is enough to do
  it. If output was hidden or truncated, I have not seen the diff, and
  saying "the diff is above" does not make it so: paste the hunks into
  the reply instead.
- Take extra care on PR branches, especially someone else's: confirm the
  approach before editing when the change is non-trivial, on top of the
  pre-commit diff review.
- If a change spans concerns that could be split across PRs, say so
  before committing rather than bundling them.

### Existing Code That Violates Preferences
- **My code**: Default to opportunistic cleanup when editing.
- **Someone else's code**: Leave it alone
  unless directly related to the change being made.

### Comments
- The goal is code that never needs comments:
  clear naming, obvious structure, self-evident intent.
  When complexity or counterintuitive logic demands explanation
  -- especially for performance optimizations --
  comments are welcome and should be included.
  Restrict to 80 columns.

### Error Handling
- Prefer raising with intentional exception classes
  over returning nil or error values.
  Defer to the surrounding code's established pattern when it conflicts.

### Audit the class, not the batch
- When a reported bug fits a pattern of the form "X + Y = broken" and both
  X and Y are enumerable in the codebase, don't stop at the reported
  instance. Enumerate both axes, cross-product them, and flag every
  combination that triggers the pattern. Then get buy-in on whether to fix
  them in one PR or split -- the enumeration is the deliverable, the
  batching is my call.

### Decision-Making Under Uncertainty
- Prioritize: security > performance > resources
  > maintainability/clarity > style.
- When there is no clear winner, say so.
  Present the options and their tradeoffs for collaborative decision-making.

### Addressing PR Feedback
- Use the `/address-pr-feedback` skill when asked to address PR review comments.
  If not using the skill directly, follow its ordering:
  make changes, commit, push, *then* reply to threads.
  Never tell a reviewer that feedback has been addressed
  before the commit has landed on the remote branch.
- **Reply format for addressed feedback**:
  `"{Acknowledgment phrase}, addressed in {short sha}. -- {attribution}"`.
  Always include the short SHA of the commit that contains the fix
  so reviewers can verify quickly.
  For threads that are pure explanations/answers with no code change,
  the SHA is not needed.
- **Human reviewer suggestions**:
  When a human reviewer provides a `suggestion` block,
  prompt me to use the "Commit suggestion" button in the browser.
  This gives the reviewer contributor credit
  and guarantees their exact wording is captured.
  Do not apply these locally.
- **Bot suggestions** (linters, formatters, CI bots):
  Apply directly in code.
  Batch multiple bot suggestions into a single edit pass and commit.
- **Attribution and voice**: replies to review threads are co-credited text.
  See "Attribution and Voice" below -- the rule is not specific to PRs.

### Attribution and Voice

**Scope: prose addressed to other people.** Ticket titles, descriptions and
comments; PR titles, bodies and review replies; Slack messages; shared docs.
Not commit messages (see the no-`Co-Authored-By` rule in the private config),
not source code comments or strings, and not direct chat replies.
This rule previously lived under "Addressing PR Feedback" and got read as
PR-only because of it; it governs **every** artifact in that list.

- **Attribution**: include a sign-off like "-- Claude & $USER" on any such text
  Claude drafted, to make agent involvement clear.
  Solo credit is fine only when the text was originally drafted by me
  and Claude's role was limited to editing.
- **Match the voice to the attribution**:
  co-credited text is first-person *plural* throughout --
  "we", "our", "us". Never "I", "me", or "my".
  This includes hedges and confidence statements:
  "we believe", "we could not verify", "we did not read that code".
  Only solo-credited text may use "I".
- **Two things legitimately keep singular voice**: a quoted voice that is not
  ours (a hypothetical user saying "show me who missed a checkout so I can
  chase it"), and literal strings inside backticks such as CLI flags or code.
  Do not blind-replace `I` across a draft -- it mangles both.
- **Write it plural from the start, and scan before filing.**
  Self-enforcement by intention alone has proven unreliable -- four
  tickets once shipped in singular voice with no attribution at all.
  Grep the draft for `\bI\b`, `\bmy\b`, `\bme\b`, `I'm`, and confirm the
  sign-off is present, rather than trusting that nothing slipped in.

### Whitespace and Formatting
- **Markdown prose**: Use semantic line breaks --
  break at sentence and clause boundaries, not at a fixed column.
  Apply an 80-column soft cap: if a clause runs past 80,
  break it at the nearest natural boundary.
  Use 2-space continuation indent for wrapped lines within a bullet.
- **Line length**: Maximum 120 characters for code in all languages.
- **Trailing whitespace**: Strip all trailing whitespace
  from every file you touch, every time, regardless of file type.
- **Final newline**: Ensure all files end with one.
- Maintain consistent indentation using the project's existing style.
- **Opening characters**: Start `[`, `(`, `{`, etc.
  on the same line as what they're passed to or assigned to.

### Typography - ASCII Only
**Scope: shared artifacts.** These rules govern anything that leaves the
direct conversation -- ticket titles, descriptions and comments, Slack
messages, PR titles and bodies, source code strings and comments, commit
messages, docs. Unicode typography is fine in direct chat replies.
Self-enforcement by intention alone has proven unreliable, so scan shared
text for violations before claiming compliance rather than trusting that
none slipped in.
- Do not use em dashes (`---`). Use hyphens or ` -- ` instead.
- Do not use smart or curly quotes. Use straight quotes only.
- Do not use the Unicode ellipsis character (`...`).
  Use three dots (`...`) instead.
- Do not use Unicode bullets. Use hyphens or asterisks instead.
- Do not use non-breaking spaces.
- Do not modify content inside backticks. Treat it as literal.
- Capitalize product and framework names in prose -- "Lambda" (the AWS
  product), "Rails" (the framework). The sole lowercase exception is a
  brand that styles itself that way.

## Claude Code Bash Tool

- The `Bash` tool executes commands via **`/bin/zsh`**, not bash, despite
  the tool's name. Write for zsh:
  - No bash associative arrays (`declare -A`) or `${!arr[@]}`.
  - zsh does NOT word-split unquoted variables: `for x in $var` iterates
    once over the whole string, not once per word. For list iteration use
    `printf '%s\n' a b c | while read x; do ...; done`, which works in
    both shells, rather than relying on splitting.
  - Prefer POSIX-portable constructs for bulk operations, and verify a
    single-item case before looping over many.
- **Environment variables do NOT persist between calls** -- only the
  working directory does. An `export` in one call is gone by the next, so
  anything a command needs in its environment must be set in that same
  command.
- **The default timeout is 120s and kills longer waits silently.** Pass
  `timeout:` explicitly for anything slow. Block on the real artifact
  rather than polling (`while ! grep -q done out.txt; do sleep 10; done`),
  and confirm which file actually receives the output you mean to read --
  a wrapper's log is not the redirect target. If an attempt yields no new
  information, change the approach instead of repeating it; repeating an
  unchanged command cannot produce a different result.
- **If your shell sets `noclobber`, `>` onto an existing file fails** --
  and the next command in the same invocation still runs, against the
  STALE file. When regenerating a temp file, `rm` it first, use a fresh
  name, or force with `>|`, then verify the downstream effect rather than
  trusting the command's success output.

### Selecting a language version

The tool's shell inherits the login PATH, which carries whatever version
manager entry sits there -- typically the **newest installed**, not the
version the project pins. With a shim-less manager (chruby and friends)
that means a pinned `.ruby-version` is quietly ignored, and
`bundle exec rspec` fails with `bundler: command not found: rspec` --
which reads like a missing gem rather than the wrong interpreter.

Prefix every invocation, since an export does not survive to the next
call, and read the version from the project's own pin rather than
hardcoding it:

```bash
export PATH="$HOME/.rubies/ruby-<version>/bin:$PATH" && bundle exec rspec <path>
```

A shell function that rewrites PATH will not help: invoked as
`fish -c 'setruby'` it mutates a subshell that exits immediately, leaving
the tool's PATH untouched.

## Ruby

Match the culture of the Ruby community (MINASWAN).

### Idiomatic Ruby & TIMTOWTDI
- Write Ruby that honors its heritage.
  Prefer idioms native to the language:
  postfix conditionals, guard clauses, `unless`,
  blocks as first-class constructs,
  expressive one-liners where they read clearly.
- Embrace TIMTOWTDI (There Is More Than One Way To Do It).
  When multiple idiomatic approaches exist,
  favor the one that best fits the surrounding code's personality.
  Experimentation and expressiveness are welcome --
  consistency comes from taste, not from always picking the same hammer.
- **Use the latest Ruby syntax** supported by the project's Ruby version.
  - Check .rubocop.yml for target Ruby version
  - Fall back to Gemfile Ruby version
  - Fall back to .ruby-version or .tool-versions files
- **When enhancing existing code**,
  match the existing patterns if the majority follows a given style.
- **Hash syntax**: Use Ruby 1.9 syntax (`key: value`)
  unless the key is a string, then use hash rocket (`'key' => value`).
- **String handling**: Prefer string interpolation over concatenation.
- **String quotes**: Use single quotes unless interpolation is needed,
  then use double quotes.
- **Block syntax**: Use `{}` when the primary purpose is to return a value,
  `do..end` when the primary purpose is to execute code
  (but defer to project RuboCop rules).
- **Collection size**: Use `#size` over `#length` or `#count`
  for arrays and hashes.
- **`allow_nil` over `nil` in inclusion validations** -- use
  `validates :field, inclusion: { in: [true, false] }, allow_nil: true`
  rather than putting `nil` in the inclusion array.
- **Extract at two occurrences, not three** --
  when the same logic appears twice, extract it immediately.
  This applies to shared methods, `let` blocks,
  `before_action` callbacks, and query scopes.
  Don't wait for a third occurrence.

### Method Organization
- **Standard Rails classes**:
  Follow established conventions (controllers, models, etc.).
- **Other classes**: Group methods by visibility
  (public, private, protected) and alphabetize within each group.

### Security
- **`sanitize_sql_like` does not prevent SQL injection** --
  it only escapes LIKE wildcards (`%`, `_`), not SQL quotes.
  Always use `?` bind placeholders for user input in query strings.
- **Never expose raw exceptions to API clients** --
  log the real error server-side
  and return a generic, safe message to the consumer.

### Database
- **Always wrap multiple database operations in
  `ActiveRecord::Base.transaction do..end`**.
  Include all related operations that should succeed or fail together.
  Examples: subscription updates + record deletions,
  creating multiple related records.
- **Push work to the database** --
  prefer SQL-level operations
  (`DISTINCT ON`, `COUNT`, aggregate `WHERE` clauses)
  over loading records into Ruby for filtering or dedup.
  Pulling data over the wire just to discard it in the VM is wasteful.
- **Prevent N+1 queries** --
  any code that iterates records and touches associations
  must `includes`/`preload` them.
  Treat this as a hard gate, not a nice-to-have.
  Proactively add eager loading rather than waiting for review feedback.
- **Park repeated computation in constants** --
  if `.to_a`, `.freeze`, or similar is called on a static value
  during every invocation (e.g., a validation inclusion list),
  store the result in a constant.

### Rails Console Snippet Format
- Wrap multi-line chains in parentheses for paste-friendly leading-dot style.
  IRB treats a leading `.` as a new statement,
  so parentheses are required for multi-line chains to paste correctly.
- End with `;nil` to suppress IRB echo.
- **When a snippet retrieves data, the result must be printed or
  assigned** -- `(...);nil` alone silently discards it.
  Use `pp` (preferred) or `puts` for output,
  or assign to a variable when the value is needed later.
  Side-effect-only snippets (enqueuing a job, toggling a flag)
  need neither.
- Standalone chain with output:
  ```ruby
  pp(User.joins(:posts)
    .where(posts: { published: true })
    .order(created_at: :desc)
    .limit(10)
    .pluck(:email));nil
  ```
- Assignment with chain -- parentheses wrap the **right-hand side**:
  ```ruby
  emails = (User.joins(:posts)
    .where(posts: { published: true })
    .pluck(:email));nil
  ```
- With output: `pp User.where(active: true).count`
- Multiple statements: put each on its own line or join with `;`
  ```ruby
  sub = Subscription.find(123)
  pp({ id: sub.id, status: sub.status });nil
  ```

### Testing Approach - Test-Driven Development (TDD)
- The test diff alone should tell the complete story of the code change.
  Tests represent the desired behavior --
  get alignment on that first, then implement.
- **Always write failing tests first** before implementing any functionality.
  For bugfixes, the new tests must explicitly fail against the unmodified code.
- Use real object instantiation rather than mocking when possible.
- Follow existing test patterns and conventions in the codebase.
- Only implement the minimum code necessary to make tests pass.
- Refactor code after tests are green while keeping tests passing.
- **100% isolated coverage**:
  Each .rb file should achieve 100% coverage
  when running only its corresponding spec file.
- **Full branch coverage on changed code**:
  Codecov tracks each branch of a conditional independently.
  Ensure both sides of every `if`/`unless`/ternary
  introduced or modified by the change are exercised by specs.

### Test Style
- **Minitest assertions in RSpec**:
  Use `assert` and `refute` instead of `expect().to be true/false`.
- **`be` over `eq`**:
  Use `be` for direct value comparisons
  (e.g., `expect(result[:amount]).to be 100`).
- **Test both sides of filters**:
  Don't just create data that matches --
  create data that should be excluded and verify it is.
  Tests that only create matching data prove nothing about filtering.
- **Assert on specific records, not counts** --
  use `expect(results).to include(expected_record)`
  over `expect(results.size).to be 3`.
  Count-based assertions break in parallel test environments
  when other tests create records in the same table.
- **Be cautious with `let_it_be`** --
  records persisted with `let_it_be` survive across examples
  but can be deleted by `DatabaseCleaner` truncation strategies
  between examples.
  Use `let!` when the cleaning strategy requires per-example setup.

### Test Naming & Easter Eggs
- **Variable names**: Use descriptive names that match the object type
  (e.g., `school`, `user`, `organization`).
- **String values**: Use creative names and values
  with a mix of preferred references.
- Make tests enjoyable to read while maintaining clarity.
- **Preferred numbers**: 1138 (THX-1138), 8675309 (Jenny song)
- **Character names**:
  The Wind in the Willows (Mole, Rat, Badger, Toad, etc.)
- **Animals**: Foxes and tapirs
- **Musicians/Bands**: New Order, The Cure, Human Tetris, Ministry
- **Comedy**: Monty Python, Still Game, Blackadder
- **Teas**: Ceylon, Nilgiri, Assam, Kenyan,
  Scottish/Irish/English Breakfast, Puerh, Darjeeling,
  Lao Cha Tou, Dragonwell, Oolong --
  stick to ones without flavorings or oils
- **Examples**:
  - `let(:user) { create(:user, name: 'Mole') }`
  - `let(:school) { create(:school, name: 'Ratty Elementary') }`
  - `let(:stripe_id) { 'sub_ratty1138' }`
  - `let(:timeout) { 8675309 }`
  - `let(:album) { 'Power, Corruption & Lies' }`
  - `let(:blend) { 'Lao Cha Tou' }`

### Code Review
- **Approve-with-suggestions over blocking** --
  when drafting review comments and the PR is a net improvement,
  approve it and note improvements for follow-up.
  Don't block on polish.
- **Check FE/BE contract alignment** --
  when changing API responses, enum values, or category assignments,
  verify that the frontend expects the new shape and values
  before shipping.
- **Settle a cheap finding before filing it.**
  If confirming a finding would take minutes -- a search, a grep,
  reading the source document it was transcribed from -- do that first,
  then file either a concrete defect or nothing.
  Passing a reviewer's "I could not verify this" through unchanged is
  not neutral: on someone else's in-review ticket it reads as implied
  rework. Reserve unverified flags for what is genuinely out of reach,
  and say what you tried.
  If one goes out and later clears, post the close-out explicitly
  rather than leaving it to decay.

## Fish Shell
- `set -l` inside `if`/`else`/`for` blocks
  does NOT persist to the enclosing function scope.
  - Workaround: declare the variable before the conditional,
    then assign inside it.
  - Or use a command-prefix pattern:
    `set -l cmd git --flag=value` then `$cmd args`.
- Linting: `fish -n <file>` for syntax,
  `fish_indent --check <file>` for formatting.
- **Fish functions from Bash**: Custom fish functions (e.g., `t`)
  are not available in plain `bash`. Invoke them with
  `fish -c 'command args'`.

## Personal Preferences
- **Spelling**: Use "grey" (with 'e') rather than "gray" (with 'a').
- **Search tool**: when using Bash for text search
  use `ug` (ugrep) instead of `grep`. By default
  valid regex syntax will be treated as such and
  `-F` (`--fixed-strings`) must be used if literal
  fixed string matching is preferred.
- **Pass `--no-line-number` when piping `ug` into another command.**
  A `~/.ugrep` config enabling `line-number`, `pretty`, or `heading`
  applies to stdin too, so `ug` prefixes every match with `N:` even
  mid-pipeline. That silently corrupts the next command:
  `git diff --name-only | ug '\.rb$'` yields `3:app/foo.rb`, and
  whatever consumes it gets a path that does not exist.
  Human-facing output is fine as-is; output feeding a command is not.
