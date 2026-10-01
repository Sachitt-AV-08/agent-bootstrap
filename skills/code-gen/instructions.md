# Code Generation Skill

Generate boilerplate code from specifications or patterns.

## When to Use

- Creating new modules/classes/functions from a spec
- Scaffolding project structure
- Generating repetitive code patterns (CRUD, API endpoints, etc.)
- Converting specs (OpenAPI, GraphQL, Protobuf) to code

## Prerequisites

- Clear specification or pattern to follow
- Target language/framework conventions known
- Existing codebase patterns to match

## Instructions

### 1. Understand the Request

- What needs to be generated? (class, function, module, project)
- What language/framework?
- What patterns exist in the codebase?
- Any specific conventions? (naming, structure, testing)

### 2. Analyze Existing Patterns

```bash
# Find similar code in the project
grep -r "pattern" src/ --include="*.ts" --include="*.py"
# Check project conventions
cat AGENTS.md
cat .opencode/settings.jsonc
```

### 3. Generate Code

Follow the project's:
- **Naming conventions** (PascalCase, camelCase, snake_case)
- **File organization** (one class per file, barrel exports, etc.)
- **Type annotations** (strict, optional, inference)
- **Error handling** (exceptions, Result types, Option)
- **Documentation** (docstrings, JSDoc, comments)
- **Testing patterns** (unit, integration, mocking)

### 4. Verify

- Run linter/formatter
- Run type checker
- Run tests (generate tests if needed)
- Ensure imports work

## Templates

### Python Class

```python
"""{{MODULE_DOCSTRING}}"""

from __future__ import annotations

from dataclasses import dataclass
from typing import {{TYPE_IMPORTS}}


@dataclass(frozen=True, slots=True)
class {{CLASS_NAME}}:
    """{{CLASS_DOCSTRING}}"""
    
    {{FIELDS}}
    
    def {{METHOD_NAME}}(self, {{PARAMS}}) -> {{RETURN_TYPE}}:
        """{{METHOD_DOCSTRING}}"""
        {{METHOD_BODY}}
```

### TypeScript Interface + Class

```typescript
/**
 * {{INTERFACE_DOCSTRING}}
 */
export interface {{INTERFACE_NAME}} {
  {{PROPERTIES}}
}

/**
 * {{CLASS_DOCSTRING}}
 */
export class {{CLASS_NAME}} implements {{INTERFACE_NAME}} {
  constructor(
    {{CONSTRUCTOR_PARAMS}}
  ) {}
  
  {{METHODS}}
}
```

### React Component

```tsx
/**
 * {{COMPONENT_DOCSTRING}}
 */
interface {{COMPONENT_NAME}}Props {
  {{PROPS}}
}

export function {{COMPONENT_NAME}}({{PROPS_DESTRUCTURED}}: {{COMPONENT_NAME}}Props) {
  return (
    {{JSX}}
  );
}
```

## Common Patterns

| Pattern | Python | TypeScript |
|---------|--------|------------|
| Data class | `@dataclass` | `interface` + `class` |
| Protocol/Interface | `Protocol` | `interface` |
| Factory | `@classmethod` | `static create()` |
| Builder | Separate class | Fluent builder |
| Repository | Abstract base class | Interface + impl |

## Examples

### Generate a Repository

Input: "Create a UserRepository for PostgreSQL with CRUD operations"

Output:
1. `src/repositories/user_repository.py` (protocol + implementation)
2. `tests/repositories/test_user_repository.py`
3. Update `src/repositories/__init__.py`

### Generate API Endpoint

Input: "Add GET /users/:id endpoint with validation"

Output:
1. Route handler with validation
2. Service method
3. Tests for success/error cases

## Related Skills

- `refactor` - For improving generated code
- `generate-tests` - For creating tests
- `writing-plans` - For complex generation tasks