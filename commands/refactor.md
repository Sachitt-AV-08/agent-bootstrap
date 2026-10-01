---
name: refactor
description: Refactor code with safety checks
arguments:
  - name: target
    description: File or directory to refactor
    required: true
  - name: goal
    description: Refactoring goal (extract, simplify, modernize, etc.)
    required: true
---

# Refactor Code

Refactor `{{target}}` with the goal: `{{goal}}`.

## Safety Requirements

1. **Tests first**: Ensure tests exist and pass before refactoring
2. **Incremental**: Make small, verifiable changes
3. **Verify**: Run tests after each change
4. **Rollback**: Be prepared to revert if tests fail

## Process

1. Run existing tests to establish baseline
2. Analyze the target code for:
   - Complexity hotspots
   - Duplication
   - Violations of SOLID/DRY/KISS
   - Type safety issues
3. Plan refactoring steps
4. Execute one step at a time
5. Run tests after each step
6. Update documentation if needed

## Common Goals

- `extract`: Extract function/class/module
- `simplify`: Reduce complexity, remove dead code
- `modernize`: Update to current language idioms
- `type-safety`: Add/improve type annotations
- `performance`: Optimize hot paths
- `testability`: Make code easier to test

## Output

Show diff of changes and test results.