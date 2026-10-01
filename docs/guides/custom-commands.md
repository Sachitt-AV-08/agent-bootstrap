# Custom Commands Guide

## What are Custom Commands?

Slash commands (`/command-name`) that trigger predefined workflows. They're Markdown files with frontmatter.

## Command Structure

Create `.md` files in:
- `~/.config/opencode/commands/` (global)
- `<project>/.opencode/commands/` (project)

```markdown
---
name: command-name
description: Brief description shown in help
arguments:
  - name: arg-name
    description: Argument description
    required: true
  - name: optional-arg
    description: Optional argument
    required: false
---

# Command Title

Instruction for the agent when this command is invoked.

## Context

`{{arg-name}}` — The value of the argument.

## Steps

1. First step
2. Second step
3. ...

## Output

What the command should produce.
```

## Examples

### Generate Tests

**File:** `commands/generate-tests.md`

```markdown
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
```

### Refactor Code

**File:** `commands/refactor.md`

```markdown
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
```

### Create PR Description

**File:** `commands/pr-description.md`

```markdown
---
name: pr-description
description: Generate a pull request description from commits
arguments:
  - name: base
    description: Base branch (default: main)
    required: false
---

# Generate PR Description

Create a comprehensive PR description based on commits since `{{base || "main"}}`.

## Process

1. Get commit log: `git log {{base || "main"}}..HEAD --oneline`
2. Get diff summary: `git diff --stat {{base || "main"}}..HEAD`
3. Categorize changes: features, fixes, refactors, docs, tests
4. Write description following conventional commits

## Output Format

```markdown
## Summary
<One paragraph summary>

## Changes
### Features
- <feat: ...>

### Fixes
- <fix: ...>

### Refactoring
- <refactor: ...>

### Tests
- <test: ...>

### Documentation
- <docs: ...>

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing done

## Checklist
- [ ] No breaking changes (or documented)
- [ ] Documentation updated
- [ ] Changelog updated (if applicable)
```
```

### Security Audit

**File:** `commands/security-audit.md`

```markdown
---
name: security-audit
description: Perform security audit on codebase
arguments:
  - name: target
    description: File or directory to audit
    required: true
---

# Security Audit

Perform a security audit on `{{target}}`.

## Checklist

### Input Validation
- [ ] All user inputs validated/sanitized
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] Path traversal prevention
- [ ] File upload validation

### Authentication & Authorization
- [ ] Proper authentication on all endpoints
- [ ] Authorization checks (RBAC/ABAC)
- [ ] Session management secure
- [ ] Password handling (bcrypt/argon2)
- [ ] JWT validation (signature, expiry, claims)

### Secrets Management
- [ ] No hardcoded secrets/API keys
- [ ] Secrets in environment variables/vault
- [ ] .env files in .gitignore

### Dependencies
- [ ] No known vulnerabilities (run `npm audit` / `pip-audit`)
- [ ] Dependencies pinned to specific versions
- [ ] Unused dependencies removed

### Data Protection
- [ ] Encryption at rest (sensitive data)
- [ ] Encryption in transit (TLS)
- [ ] PII handling compliant (GDPR, CCPA)
- [ ] Logging doesn't leak sensitive data

### Error Handling
- [ ] No stack traces in production responses
- [ ] Generic error messages for users
- [ ] Detailed errors logged server-side

## Output

Report with findings categorized by severity:
- **Critical**: Immediate exploit possible
- **High**: Significant risk
- **Medium**: Moderate risk
- **Low**: Minor risk
- **Info**: Best practice violations
```

## Using Commands

```bash
# In OpenCode session
/generate-tests file=src/api/users.py framework=pytest
/refactor target=src/utils/ goal=simplify
/pr-description base=main
/security-audit target=src/
```

## Command Discovery

Commands are loaded from:
1. Global: `~/.config/opencode/commands/*.md`
2. Project: `<project>/.opencode/commands/*.md`

Project commands override global with same name.

## Best Practices

1. **Clear names** — Verb-noun format: `generate-tests`, `refactor-code`
2. **Descriptive descriptions** — Shown in `/help`
3. **Required vs optional args** — Minimize required args
4. **Structured output** — Consistent format for parsing
5. **Idempotent** — Safe to run multiple times
6. **Document assumptions** — What the command expects

## Advanced: Dynamic Commands

Commands can invoke other commands or skills:

```markdown
---
name: full-review
description: Run complete code review pipeline
arguments:
  - name: target
    description: Target to review
    required: true
---

# Full Code Review

Run complete review pipeline on `{{target}}`.

## Pipeline

1. `/security-audit target={{target}}`
2. `/refactor target={{target}} goal=simplify`
3. `/generate-tests file={{target}}`
4. Run all tests and report
```