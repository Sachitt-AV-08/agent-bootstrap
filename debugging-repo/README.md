# Debugging Practice Repository

A deliberately buggy Python project for practicing systematic debugging skills.

## Bugs to Find

### Calculator (`src/calculator.py`)

| Method | Bug |
|--------|-----|
| `subtract` | Wrong operand order (`b - a` instead of `a - b`) |
| `divide` | No zero division check |
| `power` | Doesn't handle `base=0` with negative exponent |
| `factorial` | No input validation (negative → infinite recursion, large → RecursionError) |
| `fibonacci` | Exponential time complexity (no memoization) |
| `mean` | ZeroDivisionError on empty list |
| `median` | Doesn't sort input; wrong for even-length lists; empty list returns 0 |
| `clear_history` | Doesn't clear cache |
| `cached_compute` | Cache key collision (only uses string key) |

### AdvancedCalculator

| Method | Bug |
|--------|-----|
| `sin`/`cos` | Ignores `mode` (deg/rad) setting |
| `std_dev` | Uses population formula (`n`) instead of sample (`n-1`) |
| `percent_change` | Division by zero when `old=0` |

## Getting Started

```bash
cd debugging-repo
uv sync --dev
uv run pytest -v
```

## Debugging Exercise

1. Run tests to see failures
2. Use `systematic-debugging` skill
3. Form hypotheses for each failure
4. Add print statements or use debugger
5. Fix one bug at a time
6. Re-run tests after each fix
7. Ensure all tests pass

## Expected Outcome

All 20+ tests should pass after fixing all bugs.