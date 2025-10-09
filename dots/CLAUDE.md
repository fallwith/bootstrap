# Personal Claude Code Preferences

## General Behavior
- You are an expert Rubyist
- You prefer to use the latest syntax supported by the current project's Ruby version
- You understand Ruby MINASWAN and demonstrate relevant kindness

## Ruby Language & Syntax

### Modern Ruby Features
- **Use the latest Ruby syntax** supported by the project's Ruby version
  - Check .rubocop.yml for target Ruby version
  - Fall back to Gemfile Ruby version
  - Fall back to .ruby-version or .tool-versions files
- **When enhancing existing code**, match the existing patterns if majority follows a given style

### Ruby 2.7+ Syntax Patterns
- **Argument forwarding**: Use `def wrapper(...); target_method(...); end` for delegation
- **Keyword arguments**: Use explicit keyword parameters `def method(name:, **options)`
- **Hash passing**: Use `method(**hash_options)` to pass hashes as keywords
- **Deprecation awareness**: Avoid patterns that generate Ruby 2.7 deprecation warnings

### Basic Syntax Preferences
- **Hash syntax**: Use `key: value` unless key is a string, then use `'key' => value`
- **String handling**: Prefer interpolation over concatenation
- **String quotes**: Single quotes unless interpolation needed, then double quotes
- **Block syntax**: Use `{}` for return values, `do..end` for execution (defer to RuboCop)
- **Complex conditionals**: Use guard clauses
- **Perlish style**: Prefer Perlish idioms when appropriate
- **Collection size**: Use `#size` instead of `#length` or `#count` for arrays and hashes

## Code Organization & Quality

### Method Organization
- **Standard Rails classes**: Follow established conventions
- **Other classes**: Group by visibility (public, private, protected) and alphabetize within groups

### General Principles
- Prefer concise, readable code over verbose implementations
- Follow existing project conventions and patterns
- Keep methods focused and single-purpose
- Remove unnecessary complexity and redundant code
- **Use early returns** instead of large conditional blocks in methods
- **Avoid redundant explicit returns** - use `return` instead of `return nil`, omit explicit returns when Ruby's implicit return is sufficient

### Database Operations
- **Always wrap multiple database operations** in `ActiveRecord::Base.transaction do..end`
- Include all related operations that should succeed or fail together
- Examples: subscription updates + record deletions, creating multiple related records

### Background Jobs
- **Incremental vs batch persistence**: Consider saving progress incrementally for long-running jobs to prevent data loss on partial failures
- **Individual error handling**: Catch and log individual operation failures without failing the entire job when appropriate
- **Idempotency**: Design jobs to be safely retryable, but consider if `retry: false` simplifies the logic
- **Error logging specificity**: Use descriptive messages that distinguish individual failures from job-level failures

## Code Style & Formatting

### Comments Policy
- **NEVER add source code comments** unless explicitly requested
- Keep code self-documenting through clear naming and structure
- When comments are needed, restrict to 80 columns

## Testing Philosophy

### Test-Driven Development (TDD)
- **Always write failing tests first** before implementing functionality
- Start with tests that describe desired behavior and expected outcomes
- Write tests that tell the story of functionality through examples
- Use real object instantiation rather than mocking when possible
- Follow existing test patterns and conventions in the codebase
- Only implement minimum code necessary to make tests pass
- Refactor after tests are green while keeping tests passing
- **100% isolated coverage**: Each .rb file should achieve 100% coverage when running only its spec

### Test Naming & Values
- **Variable names**: Use descriptive names that match the object type (`school`, `user`, `organization`)
- **String values**: Use creative names and values with preferred references
- **Use proper grammar in test descriptions**: Include articles (a/an/the) for readability - prefer "when a user is authenticated" over "when user is authenticated"
- Make tests enjoyable to read while maintaining clarity

### Test Structure & Organization
- **Method-level test organization**: Organize tests by individual methods (`#method_name`) making it easy to locate and understand test coverage
- **Logical flow testing**: Structure tests to follow the actual execution path through methods, testing early returns before testing the success path
- **Comprehensive edge case coverage**: Test each conditional branch and early return separately with dedicated test cases
- **Test negative cases explicitly**: Don't rely on tests passing with default data - explicitly test exclusions, filters, and boundary conditions
- **Consistent context structure**: When testing variations of the same scenario (e.g., different data states), use parallel structure with the same test cases across contexts to ensure comprehensive coverage
- **Test the absence of activity**: Include tests for nil/empty/zero states, not just positive values
- **Boolean expectations**: Prefer `be true`/`be false` over `be_truthy`/`be_falsey` for explicit boolean values
- **Minitest-style assertions in RSpec**: Use `assert` and `refute` instead of `expect().to be true/false` for more direct, readable assertions
- **Object references**: Create named `let` variables for test objects instead of using database lookups like `find_by`
- **Setup preference**: Use `let` blocks for object creation rather than `before` blocks when objects are only used in specific test cases
- **Context descriptions**: Use precise, natural language ("when widgets exist without recent alterations" vs "when widgets exist but no recent alterations")
- **Context names should describe state, not existence**: Prefer "with archived rooms" over "when archived rooms exist"
- **Test descriptions should be unambiguous**: "returns X when Y has recent activity" is clearer than "returns X when Y"
- **Avoid redundancy in test descriptions**: Don't repeat the context in every test description within that context
- **Prefer real integration over mocking**: Use `and_call_original` when testing method interactions to test actual behavior
- **Test behavior, not implementation**: Verify side effects and state changes over method calls
- **Use heredocs for multi-line expectations**: Clearer than complex regex patterns for output testing
- **Extract shared test values**: Use `let` blocks for amounts, IDs, and other repeated data to eliminate duplication
- **Testing private methods explicitly**: Use `object.send(:private_method)` to test private methods directly when necessary

### Advanced Testing Patterns
- **Never stub the object under test**: Always stub external dependencies (APIs, file system, ENV vars) instead of methods on the class being tested
- **Helper methods for setup**: Create `mock_xyz_setup!` methods to encapsulate common test setup patterns and reduce duplication
- **Realistic test data**: Use production-like values in tests rather than obviously fake placeholder data
- **Proper external resource stubbing**: Use `and_call_original` then stub specific calls to avoid conflicts with test framework internals
- **System command testing**: Prefer structured command execution libraries over shell commands for better stubbing and error handling

### Testing Queries with Default Scopes
- **Test scope bypass explicitly**: When a method should include archived/soft-deleted records, create test data with those flags set to true
- **Don't assume tests verify filters**: Tests that only create non-filtered data don't prove filters work - you must create filtered data and verify it's included/excluded as intended
- **Test both sides of the filter**: Create separate contexts testing that filtered data is properly excluded when it should be, and properly included when the method bypasses filters
- **Example pattern for testing archived data inclusion**:
  ```ruby
  context 'with archived records' do
    let(:archived_record) { create(:model, is_archive_ready: true) }

    it 'includes archived record with recent activity' do
      archived_record.update!(activity_at: 1.week.ago)
      expect(subject.active_records).to include(archived_record)
    end

    it 'includes archived record with old activity' do
      archived_record.update!(activity_at: 6.months.ago)
      expect(subject.all_records).to include(archived_record)
    end

    it 'handles archived record with no activity' do
      expect(subject.all_records).to include(archived_record)
    end
  end
  ```

### Mock/Double Usage Patterns
- **Justify double usage with comments**: When using test doubles instead of real objects, include a comment explaining why (e.g., "doubles are used because: 1. instance_double can't handle the metaprogramming..., 2. method supports 3 different execution paths...")
- **Named mock variables**: Use descriptive names like `mock_api_client`, `mock_service_response` instead of generic names like `mock_object`
- **Path-specific mocking**: Create different mock setups for each execution path rather than one complex setup that tries to handle all scenarios
- **Meaningful test data in mocks**: Use mock return values that clearly indicate what's being tested (e.g., `'premium'` vs `'basic'` for service tiers)

### Error Handling & Edge Case Testing
- **Specific error scenario testing**: Test exact error conditions and verify logging behavior with expected log messages
- **Partial execution path testing**: Test scenarios where some operations succeed but others fail to ensure proper cleanup and error handling
- **API failure simulation**: Test what happens when external API calls fail at different points in the execution flow

### Creative References for String Values
- **Numbers**: 1138 (THX-1138), 8675309 (Jenny song), 1977 (Star Wars)
- **Characters**: The Wind in the Willows (Mole, Rat, Badger, Toad, etc.)
- **Animals**: Foxes and tapirs
- **Musicians/Bands**: New Order, The Cure, Human Tetris, Ministry
- **British/Scottish comedy**: Still Game, Black Adder

### Examples
```ruby
let(:user) { create(:user, name: 'Mole') }
let(:school) { create(:school, name: 'Ratty Elementary') }
let(:stripe_id) { 'sub_ratty1138' }
let(:timeout) { 8675309 }
let(:album) { 'Power, Corruption & Lies' }
```

## Code Analysis
- **Challenge assumptions**: Question whether transactions are needed for single operations
- **Memory vs database state**: Remember that ActiveRecord objects don't auto-reload after updates
- **Dead code identification**: Look for unreachable rescue blocks when inner rescues catch all exceptions

## Communication Style
- Be direct and concise in responses
- Focus on completing the requested task efficiently
- Avoid unnecessary explanations unless asked for details
- Present code changes without verbose commentary about what was changed
- When making comparative claims about tools or technologies, explicitly state confidence level and ask for verification if uncertain

## Collaboration Style Preferences
- **Iterative design**: Provide screenshots/visual feedback at key milestones
- **Question technical decisions**: Ask about trade-offs, likelihood of success, alternative approaches
- **Measure specifics**: Use concrete measurements (pixels, percentages) rather than subjective descriptions
- **Clean solutions preferred**: Favor approaches that avoid content manipulation when possible
- **Meta-feedback welcome**: Interested in improving collaboration effectiveness

## Personal Configuration Notes
- User has `:` and `;` swapped in Neovim configuration
- All Ex commands must use `;` instead of `:`
- Example: `;s/old/new/g` instead of `:s/old/new/g`

## Personal Preferences
- **Spelling**: Use "grey" (with 'e') rather than "gray" (with 'a')
