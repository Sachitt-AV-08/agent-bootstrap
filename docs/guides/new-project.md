# Creating New Projects

## Quick Start

```bash
# Python project
./scripts/new-project.ps1 my-project python

# Node.js project
./scripts/new-project.ps1 my-project node

# Basic template
./scripts/new-project.ps1 my-project basic
```

Or on macOS/Linux:
```bash
./scripts/new-project.sh my-project python
./scripts/new-project.sh my-project node
```

## What Happens

1. **Copies template** from `templates/<type>-project/`
2. **Replaces variables**:
   - `{{PROJECT_NAME}}` → `my-project`
   - `{{PACKAGE_NAME}}` → `my_project` (snake_case)
   - `{{PROJECT_DESCRIPTION}}` → "A python project: my-project"
   - `{{AUTHOR}}` → current user
   - `{{EMAIL}}` → user@users.noreply.github.com
3. **Initializes git** with initial commit
4. **Creates project** at `projects/my-project/`

## Customization

```bash
# With custom description
./scripts/new-project.ps1 my-api python --description "REST API for my service"

# With custom author
./scripts/new-project.ps1 my-lib node --author "Jane Doe" --email "jane@example.com"
```

## Project Structure After Creation

### Python Project
```
projects/my-project/
├── pyproject.toml          # uv config, deps, tools
├── uv.lock                 # Locked dependencies
├── .pre-commit-config.yaml # Pre-commit hooks
├── .gitignore
├── README.md
├── src/
│   └── my_project/         # Package (snake_case)
│       ├── __init__.py
│       └── main.py
└── tests/
    ├── __init__.py
    └── test_main.py
```

### Node.js Project
```
projects/my-project/
├── package.json
├── tsconfig.json
├── .eslintrc.cjs
├── .prettierrc
├── vitest.config.ts
├── .gitignore
├── README.md
├── src/
│   ├── index.ts            # Main entry
│   └── index.test.ts       # Tests
└── dist/                   # Build output (gitignored)
```

## Development Commands

### Python
```bash
cd projects/my-project

# Install deps
uv sync --dev

# Run tests
uv run pytest

# Type check
uv run mypy src

# Lint & format
uv run ruff check src tests
uv run ruff format src tests

# Run main
uv run my_project
```

### Node.js
```bash
cd projects/my-project

# Install deps
npm install

# Run tests
npm test

# Type check
npm run typecheck

# Lint & format
npm run lint
npm run format

# Build
npm run build

# Dev mode
npm run dev
```

## Adding to OpenCode

Create `.opencode/settings.jsonc` in project:

```jsonc
{
  "model": { "provider": "kilo", "model": "kilo/kilo-auto/free" },
  "agents": {
    "default": "project-main",
    "project-main": {
      "systemPrompt": "You are working on my-project. Follow AGENTS.md.",
      "permissions": { "tools": ["*"] }
    }
  }
}
```

Then from project root:
```bash
opencode
```

## Template Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `{{PROJECT_NAME}}` | Project name (as given) | `my-project` |
| `{{PACKAGE_NAME}}` | Snake_case package name | `my_project` |
| `{{PROJECT_DESCRIPTION}}` | Description | `A python project: my-project` |
| `{{AUTHOR}}` | Author name | `sachi` |
| `{{EMAIL}}` | Author email | `sachi@users.noreply.github.com` |

## Creating Custom Templates

1. Create directory: `templates/my-template/`
2. Add template files with `{{VARIABLES}}`
3. Add `template.json`:
   ```json
   {
     "name": "my-template",
     "description": "My custom template",
     "variables": {
       "PROJECT_NAME": "Project name",
       "CUSTOM_VAR": "Custom variable"
     }
   }
   ```
4. Use: `./scripts/new-project.ps1 my-project my-template`

## Best Practices

1. **Always use the script** — ensures consistency
2. **Customize AGENTS.md** — add project-specific instructions
3. **Add CLAUDE.md** — for Claude Code compatibility
4. **Configure pre-commit** — run `uv run pre-commit install` / `npm run prepare`
5. **Set up CI/CD** — GitHub Actions, GitLab CI, etc.