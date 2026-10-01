# Python Project Template Guide

## Template Location

```
templates/python-project/
├── pyproject.toml
├── .pre-commit-config.yaml
├── .gitignore
├── README.md
├── src/
│   └── {{PACKAGE_NAME}}/
│       ├── __init__.py
│       └── main.py
└── tests/
    ├── __init__.py
    └── test_main.py
```

## Creating a Project

```bash
# Using the script
./scripts/new-project.ps1 my-api python --description "REST API for my service"

# Or manually
cp -r templates/python-project projects/my-api
# Then replace {{VARIABLES}}
```

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{PROJECT_NAME}}` | Project name | `my-api` |
| `{{PACKAGE_NAME}}` | Python package (snake_case) | `my_api` |
| `{{PROJECT_DESCRIPTION}}` | Description | `REST API for my service` |
| `{{AUTHOR}}` | Author name | `Jane Doe` |
| `{{EMAIL}}` | Author email | `jane@example.com` |

## pyproject.toml Breakdown

### Project Metadata
```toml
[project]
name = "{{PROJECT_NAME}}"
version = "0.1.0"
description = "{{PROJECT_DESCRIPTION}}"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    # Runtime dependencies
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=4.1",
    "pytest-asyncio>=0.23",
    "ruff>=0.4",
    "mypy>=1.9",
    "pre-commit>=3.6",
]
```

### Build System
```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Ruff (Linting + Formatting)
```toml
[tool.ruff]
target-version = "py312"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "PT", "T20", "ARG", "PTH", "ERA", "PL", "TRY", "SIM", "RET", "PERF", "PD", "PGH", "PIE", "TID", "NPY", "RSE", "LOG", "INP", "ISC", "ICN", "ASYNC", "FLY", "AIR", "EXE"]
ignore = ["E501", "ARG001", "ARG002"]
fixable = ["ALL"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### MyPy (Type Checking)
```toml
[tool.mypy]
python_version = "3.12"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
no_implicit_optional = true
strict_optional = true
check_untyped_defs = true
```

### Pytest
```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"
addopts = "-v --tb=short"
```

### Coverage
```toml
[tool.coverage.run]
source = ["src"]
omit = ["tests/*", "*/__pycache__/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
]
```

## Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.9.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-json
      - id: check-merge-conflict
      - id: debug-logger
      - id: requirements-txt-fixer
```

## Development Commands

```bash
cd projects/my-api

# Install dependencies
uv sync --dev

# Run tests
uv run pytest

# Run with coverage
uv run pytest --cov=src --cov-report=term-missing

# Type check
uv run mypy src

# Lint
uv run ruff check src tests

# Format
uv run ruff format src tests

# All checks
uv run ruff check src tests && uv run ruff format --check src tests && uv run mypy src && uv run pytest

# Install pre-commit
uv run pre-commit install

# Run pre-commit manually
uv run pre-commit run --all-files
```

## Project Structure

```
my-api/
├── pyproject.toml          # Project config
├── uv.lock                 # Locked deps (commit this)
├── .pre-commit-config.yaml # Pre-commit hooks
├── .gitignore
├── README.md
├── src/
│   └── my_api/             # Package
│       ├── __init__.py     # Exports, version
│       ├── main.py         # CLI entry point
│       ├── models/         # Data models
│       ├── services/       # Business logic
│       ├── repositories/   # Data access
│       └── api/            # API routes (if web)
└── tests/
    ├── __init__.py
    ├── conftest.py         # Pytest fixtures
    ├── test_main.py
    ├── unit/               # Unit tests
    └── integration/        # Integration tests
```

## Adding Dependencies

```bash
# Runtime dependency
uv add fastapi uvicorn pydantic-settings

# Dev dependency
uv add --dev pytest-mock httpx

# With extras
uv add "fastapi[standard]"
```

## Virtual Environment

uv manages venv automatically:
- Location: `.venv/` in project root
- Python: Uses `requires-python` from pyproject.toml
- Activate: `source .venv/bin/activate` (or `uv run`)

## Publishing

```bash
# Build
uv build

# Test install
uv pip install dist/my_api-0.1.0.tar.gz

# Publish to PyPI
uv publish
```

## CI/CD Example (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: uv sync --dev
      - run: uv run ruff check src tests
      - run: uv run ruff format --check src tests
      - run: uv run mypy src
      - run: uv run pytest --cov=src --cov-report=xml
      - uses: codecov/codecov-action@v3
```

## Customizing the Template

1. Edit files in `templates/python-project/`
2. Add new template variables in `scripts/new-project.ps1` / `.sh`
3. Update `template.json` if adding custom variables
4. Test: `./scripts/new-project.ps1 test-project python`