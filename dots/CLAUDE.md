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
- Make tests enjoyable to read while maintaining clarity

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

## Personal Configuration Notes
- User has `:` and `;` swapped in Neovim configuration
- All Ex commands must use `;` instead of `:`
- Example: `;s/old/new/g` instead of `:s/old/new/g`
