# Personal Claude Code Preferences

## General Behavior

### Communication Style
- Be direct and concise. Focus on completing the task efficiently.
- Present code changes without verbose commentary about what was changed.
- When making comparative claims about tools or technologies,
  explicitly state confidence level and ask for verification if uncertain.
  Avoid definitive statements without sources.

### Uncertainty
- When you don't know something, say so.
  Never guess without labeling it as a guess.
  "I'm not sure -- let me check" is always acceptable.
- Distinguish between what you know, what you're inferring,
  and what you're guessing.
  Use language that makes the confidence level obvious.

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

### Linting
- **Before committing**, run the project's linter on all changed files
  (e.g., `bundle exec rubocop` for Ruby,
  `fish -n` / `fish_indent --check` for fish).
  Do not rely on code review agents or manual inspection
  as a substitute for the real tool.
- **New code**: Fix all lint violations before committing.
- **Pre-existing violations** surfaced in changed files:
  follow the ownership rules below.

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
- **Attribution**:
  When replying to PR threads (or any external-facing text not drafted by me),
  include attribution like "-- Claude & $USER" to make agent involvement clear.
  Solo credit is fine only when the text was originally drafted by me
  and Claude's role was limited to editing.

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
- Do not use em dashes (`---`). Use hyphens or ` -- ` instead.
- Do not use smart or curly quotes. Use straight quotes only.
- Do not use the Unicode ellipsis character (`...`).
  Use three dots (`...`) instead.
- Do not use Unicode bullets. Use hyphens or asterisks instead.
- Do not use non-breaking spaces.
- Do not modify content inside backticks. Treat it as literal.

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
- Use `pp` (preferred) or `puts` when console output is desired.
- Hold results in variables otherwise.
- Standalone chain:
  ```ruby
  (User.joins(:posts)
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

## Fish Shell
- `set -l` inside `if`/`else`/`for` blocks
  does NOT persist to the enclosing function scope.
  - Workaround: declare the variable before the conditional,
    then assign inside it.
  - Or use a command-prefix pattern:
    `set -l cmd git --flag=value` then `$cmd args`.
- Linting: `fish -n <file>` for syntax,
  `fish_indent --check <file>` for formatting.
- Prefer 2-space indentation in fish files.

## Personal Preferences
- **Spelling**: Use "grey" (with 'e') rather than "gray" (with 'a').
