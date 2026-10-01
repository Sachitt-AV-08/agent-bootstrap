---
name: generate-tests
description: Generate unit tests for a given source file
arguments:
  - name: file
    description: Path to source file
    required: true
  - name: framework
    description: Test framework (pytest, vitest, jest)
    required: false
---

# Generate Tests

Generate comprehensive unit tests for `{{file}}` using `{{framework || "pytest"}}`.

## Requirements

1. **Coverage**: Aim for >80% coverage of the target file
2. **Test types**: Include happy path, edge cases, error conditions
3. **Style**: Follow project conventions (see AGENTS.md)
4. **Isolation**: Mock external dependencies
5. **Naming**: Use descriptive test names (given_when_then or feature_expected)

## Process

1. Read the source file and understand its public API
2. Identify all functions/classes/methods to test
3. Check existing tests for patterns
4. Generate test file with appropriate structure
5. Run tests to verify they pass

## Output

Create or update the corresponding test file:
- Python: `tests/test_<module>.py`
- TypeScript: `src/<module>.test.ts`
- Other: Follow project convention