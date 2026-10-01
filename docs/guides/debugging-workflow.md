# Systematic Debugging Workflow

## The Skill

Always load this skill when debugging:
```bash
skill systematic-debugging
```

## Debugging Process

### 1. Reproduce

```bash
# Get minimal reproduction
# What input causes the failure?
# What is the expected vs actual output?
# Can you reproduce in isolation?
```

### 2. Form Hypotheses

List possible causes, ordered by likelihood:
1. **Most likely** — Recent changes, common patterns
2. **Plausible** — Edge cases, environmental factors
3. **Unlikely but possible** — Race conditions, hardware issues

### 3. Test Hypotheses

For each hypothesis:
- Design a test that confirms or refutes
- Run the test
- Observe results
- Eliminate or confirm

### 4. Isolate Root Cause

Narrow down to:
- Specific line of code
- Specific condition
- Specific interaction

### 5. Fix

- Minimal fix for root cause
- Add regression test
- Verify fix works

### 6. Verify

- Run all related tests
- Check for regressions
- Test edge cases

## Debugging Commands

```bash
# Run specific failing test
uv run pytest tests/test_calculator.py::TestCalculator::test_divide -v

# Run with verbose output
uv run pytest -vv --tb=long

# Debug with pdb
uv run pytest --pdb tests/test_calculator.py::TestCalculator::test_divide

# Run with coverage to see what's executed
uv run pytest --cov=src --cov-report=term-missing
```

## Common Debugging Patterns

### Off-by-One Errors
```python
# Check loop boundaries
for i in range(len(items)):  # 0 to len-1
    items[i]  # OK

for i in range(1, len(items)):  # 1 to len-1
    items[i]  # Skips first!
```

### Null/None Handling
```python
# Always check before access
if user is not None:
    user.name  # Safe

# Or use Optional with proper handling
def get_name(user: User | None) -> str:
    return user.name if user else "Unknown"
```

### Async Issues
```python
# Missing await
result = async_function()  # Returns coroutine!
result = await async_function()  # Correct

# Race condition
async def bad():
    tasks = [fetch(i) for i in range(10)]
    return await asyncio.gather(*tasks)  # All at once

async def good():
    sem = asyncio.Semaphore(5)
    async def limited(i):
        async with sem:
            return await fetch(i)
    return await asyncio.gather(*[limited(i) for i in range(10)])
```

### Floating Point
```python
# Never compare floats directly
assert abs(a - b) < 1e-9  # Use epsilon

# Or use decimal for money
from decimal import Decimal
price = Decimal("19.99")
```

## Debugging Tools

| Tool | Use Case |
|------|----------|
| `print()` / `logging` | Quick inspection |
| `pdb` / `ipdb` | Interactive debugging |
| `pytest --pdb` | Drop into debugger on failure |
| `pytest -vv` | Verbose output |
| `coverage` | See what code runs |
| `objgraph` | Find reference leaks |
| `py-spy` | Profile running Python |
| `viztracer` | Trace execution flow |

## Debugging in OpenCode

### Using the Debugger Agent
```bash
/agent debugger
"Debug why test_divide fails. The test expects ZeroDivisionError but test crashes."
```

### Systematic Approach
1. **Read the failing test** — Understand expected behavior
2. **Read the implementation** — Find the bug
3. **Form hypothesis** — "divide() doesn't check for zero"
4. **Verify** — Add print or check code
5. **Fix** — Add zero check
6. **Test** — Run test again

### Using Browser-Use for Web Debugging
```bash
# In session
"Use browser-use to reproduce the UI bug on localhost:3000"
```

## Debugging the Debugging Repo

The `debugging-repo` has intentional bugs for practice:

```bash
cd debugging-repo
uv sync --dev
uv run pytest -v

# Pick a failing test
uv run pytest tests/test_calculator.py::TestCalculator::test_subtract -v

# Apply systematic debugging
skill systematic-debugging
```

### Bug Categories in Debugging Repo

| Category | Methods | Practice |
|----------|---------|----------|
| Logic errors | `subtract`, `median` | Wrong algorithm |
| Edge cases | `divide`, `factorial`, `mean` | Missing validation |
| Performance | `fibonacci` | Exponential complexity |
| State management | `clear_history` | Incomplete cleanup |
| Config ignored | `sin`, `cos` | Mode not respected |
| Formula errors | `std_dev` | Population vs sample |

## Post-Fix Checklist

- [ ] All tests pass
- [ ] No regressions (full suite passes)
- [ ] Edge cases covered
- [ ] Documentation updated if needed
- [ ] Root cause documented for future reference

## Debugging Mindset

1. **Assume you're wrong** — Question your assumptions
2. **One change at a time** — Isolate variables
3. **Trust the data** — Tests, logs, metrics over intuition
4. **Binary search** — Halve the problem space
5. **Rubber duck** — Explain to someone (or yourself)
6. **Take breaks** — Fresh eyes find bugs faster