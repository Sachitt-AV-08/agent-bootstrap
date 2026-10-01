# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Installation

```bash
uv sync --dev
```

## Development

```bash
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
```

## Project Structure

```
{{PROJECT_NAME}}/
├── pyproject.toml          # Project config
├── uv.lock                 # Locked dependencies
├── src/
│   └── {{PACKAGE_NAME}}/   # Main package
│       ├── __init__.py
│       └── main.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── .pre-commit-config.yaml
└── README.md
```

## Pre-commit

```bash
uv run pre-commit install
uv run pre-commit run --all-files
```

## License

MIT