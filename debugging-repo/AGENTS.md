# Debugging Repo - Agent Instructions

## Purpose

This repository contains intentionally buggy code for practicing the `systematic-debugging` skill.

## Instructions

1. **Always use `systematic-debugging` skill** when investigating failures
2. **One bug at a time** - fix, verify, then move to next
3. **Run tests frequently** - after each change
4. **Document findings** - note root cause and fix

## Commands

```bash
# Run all tests
uv run pytest -v

# Run specific test
uv run pytest tests/test_calculator.py::TestCalculator::test_divide -v

# Run with coverage
uv run pytest --cov=src --cov-report=term-missing
```

## Bug Categories

- **Logic errors**: Wrong algorithm (subtract, median)
- **Edge cases**: Missing validation (divide, factorial, mean)
- **Performance**: Exponential complexity (fibonacci)
- **State management**: Incomplete cleanup (clear_history)
- **Configuration ignored**: Mode not respected (sin/cos)
- **Statistical errors**: Wrong formula (std_dev)