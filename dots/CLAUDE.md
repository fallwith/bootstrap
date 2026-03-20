# Personal Claude Code Preferences

## General Behavior

### Communication Style
- Be direct and concise. Focus on completing the task efficiently.
- Present code changes without verbose commentary about what was changed.
- When making comparative claims about tools or technologies, explicitly state confidence level and ask for verification if uncertain. Avoid definitive statements without sources.

### Push Back
- Push back when you see unnecessary complexity, footguns, or a better path. The bigger the danger, the harder you should push.
- Welcome push back in return. Programmer-to-programmer directness is valued here. "That which can be destroyed by the truth, should be."
- If overruled, note the objection and move on.
- If the objection is high-stakes, the danger of proceeding is significant, or the back-and-forth has been extensive, offer to write a markdown plan file for future follow-up.

### Existing Code That Violates Preferences
- **My code**: Default to opportunistic cleanup when editing.
- **Someone else's code**: Leave it alone unless directly related to the change being made.

### Comments
- The goal is code that never needs comments: clear naming, obvious structure, self-evident intent. When complexity or counterintuitive logic demands explanation — especially for performance optimizations — comments are welcome and should be included. Restrict to 80 columns.

### Error Handling
- Prefer raising with intentional exception classes over returning nil or error values. Defer to the surrounding code's established pattern when it conflicts.

### Decision-Making Under Uncertainty
- Prioritize: security > performance > resources > maintainability/clarity > style.
- When there is no clear winner, say so. Present the options and their tradeoffs for collaborative decision-making.

### Whitespace and Formatting
- **Line length**: Maximum 120 characters for code in all languages.
- **Trailing whitespace**: Strip all trailing whitespace from every file you touch, every time, regardless of file type.
- **Final newline**: Ensure all files end with one.
- Maintain consistent indentation using the project's existing style.
- **Opening characters**: Start `[`, `(`, `{`, etc. on the same line as what they're passed to or assigned to.

## Ruby

Match the culture of the Ruby community (MINASWAN).

### Idiomatic Ruby & TIMTOWTDI
- Write Ruby that honors its heritage. Prefer idioms native to the language: postfix conditionals, guard clauses, `unless`, blocks as first-class constructs, expressive one-liners where they read clearly.
- Embrace TIMTOWTDI (There Is More Than One Way To Do It). When multiple idiomatic approaches exist, favor the one that best fits the surrounding code's personality. Experimentation and expressiveness are welcome — consistency comes from taste, not from always picking the same hammer.
- **Use the latest Ruby syntax** supported by the project's Ruby version.
  - Check .rubocop.yml for target Ruby version
  - Fall back to Gemfile Ruby version
  - Fall back to .ruby-version or .tool-versions files
- **When enhancing existing code**, match the existing patterns if the majority follows a given style.
- **Hash syntax**: Use Ruby 1.9 syntax (`key: value`) unless the key is a string, then use hash rocket (`'key' => value`).
- **String handling**: Prefer string interpolation over concatenation.
- **String quotes**: Use single quotes unless interpolation is needed, then use double quotes.
- **Block syntax**: Use `{}` when the primary purpose is to return a value, `do..end` when the primary purpose is to execute code (but defer to project RuboCop rules).
- **Collection size**: Use `#size` over `#length` or `#count` for arrays and hashes.

### Method Organization
- **Standard Rails classes**: Follow established conventions (controllers, models, etc.).
- **Other classes**: Group methods by visibility (public, private, protected) and alphabetize within each group.

### Database Transactions
- **Always wrap multiple database operations in `ActiveRecord::Base.transaction do..end`**.
- Include all related operations that should succeed or fail together.
- Examples: subscription updates + record deletions, creating multiple related records.

### Rails Console Snippet Format
- Wrap multi-line chains in parentheses for paste-friendly leading-dot style. IRB treats a leading `.` as a new statement, so parentheses are required for multi-line chains to paste correctly.
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
- Assignment with chain — parentheses wrap the **right-hand side**:
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
- The test diff alone should tell the complete story of the code change. Tests represent the desired behavior — get alignment on that first, then implement.
- **Always write failing tests first** before implementing any functionality. For bugfixes, the new tests must explicitly fail against the unmodified code.
- Use real object instantiation rather than mocking when possible.
- Follow existing test patterns and conventions in the codebase.
- Only implement the minimum code necessary to make tests pass.
- Refactor code after tests are green while keeping tests passing.
- **100% isolated coverage**: Each .rb file should achieve 100% coverage when running only its corresponding spec file.

### Test Style
- **Minitest assertions in RSpec**: Use `assert` and `refute` instead of `expect().to be true/false`.
- **`be` over `eq`**: Use `be` for direct value comparisons (e.g., `expect(result[:amount]).to be 100`).
- **Test both sides of filters**: Don't just create data that matches — create data that should be excluded and verify it is. Tests that only create matching data prove nothing about filtering.

### Test Naming & Easter Eggs
- **Variable names**: Use descriptive names that match the object type (e.g., `school`, `user`, `organization`).
- **String values**: Use creative names and values with a mix of preferred references.
- Make tests enjoyable to read while maintaining clarity.
- **Preferred numbers**: 1138 (THX-1138), 8675309 (Jenny song)
- **Character names**: The Wind in the Willows (Mole, Rat, Badger, Toad, etc.)
- **Animals**: Foxes and tapirs
- **Musicians/Bands**: New Order, The Cure, Human Tetris, Ministry
- **Comedy**: Monty Python, Still Game, Blackadder
- **Teas**: Ceylon, Nilgiri, Assam, Kenyan, Scottish/Irish/English Breakfast, Puerh, Darjeeling, Lao Cha Tou, Dragonwell, Oolong - stick to ones without flavorings or oils
- **Examples**:
  - `let(:user) { create(:user, name: 'Mole') }`
  - `let(:school) { create(:school, name: 'Ratty Elementary') }`
  - `let(:stripe_id) { 'sub_ratty1138' }`
  - `let(:timeout) { 8675309 }`
  - `let(:album) { 'Power, Corruption & Lies' }`
  - `let(:blend) { 'Lao Cha Tou' }`

## Fish Shell
- `set -l` inside `if`/`else`/`for` blocks does NOT persist to the enclosing function scope.
  - Workaround: declare the variable before the conditional, then assign inside it.
  - Or use a command-prefix pattern: `set -l cmd git --flag=value` then `$cmd args`.
- Linting: `fish -n <file>` for syntax, `fish_indent --check <file>` for formatting.
- Prefer 2-space indentation in fish files.

## Personal Preferences
- **Spelling**: Use "grey" (with 'e') rather than "gray" (with 'a').
