# Test-Driven Development Workflow

## TDD Cycle

```
RED → GREEN → REFACTOR
```

1. **RED** — Write a failing test
2. **GREEN** — Make it pass (minimum code)
3. **REFACTOR** — Improve code while tests pass

## OpenCode TDD Workflow

### 1. Start with a Test

```bash
# In OpenCode session
"Write a test for a new UserService.get_user(email) method that:
- Returns user if found
- Raises NotFoundError if not found
- Uses the existing UserRepository protocol"
```

### 2. Run Test (Should Fail)

```bash
uv run pytest tests/services/test_user_service.py -v
# RED: Test fails - UserService doesn't exist
```

### 3. Implement Minimum Code

```bash
# In OpenCode session
"Implement UserService.get_user(email) to make the test pass.
Use UserRepository protocol. Keep it minimal."
```

### 4. Run Test (Should Pass)

```bash
uv run pytest tests/services/test_user_service.py -v
# GREEN: Test passes
```

### 5. Refactor

```bash
# In OpenCode session
"Refactor UserService to add caching with TTL.
Keep all tests passing."
```

### 6. Run Tests Again

```bash
uv run pytest tests/services/test_user_service.py -v
# GREEN: Tests still pass
```

## Best Practices

### Test Structure

```python
# tests/services/test_user_service.py
import pytest
from src.services.user_service import UserService
from src.repositories.user_repository import UserRepository
from src.exceptions import NotFoundError

class TestUserService:
    """Tests for UserService."""
    
    def test_get_user_returns_user_when_found(self):
        # Arrange
        mock_repo = Mock(spec=UserRepository)
        mock_repo.get_by_email.return_value = User(email="test@example.com")
        service = UserService(mock_repo)
        
        # Act
        user = service.get_user("test@example.com")
        
        # Assert
        assert user.email == "test@example.com"
        mock_repo.get_by_email.assert_called_once_with("test@example.com")
    
    def test_get_user_raises_not_found_when_missing(self):
        # Arrange
        mock_repo = Mock(spec=UserRepository)
        mock_repo.get_by_email.return_value = None
        service = UserService(mock_repo)
        
        # Act & Assert
        with pytest.raises(NotFoundError):
            service.get_user("missing@example.com")
```

### Test Naming

| Pattern | Example |
|---------|---------|
| `test_<method>_<scenario>_<expected>` | `test_get_user_returns_user_when_found` |
| `test_<feature>_<expected>` | `test_user_registration_sends_welcome_email` |
| `given_<context>_when_<action>_then_<outcome>` | `given_user_exists_when_get_then_returns_user` |

### Mocking Guidelines

- **Mock at boundaries** — Repositories, external APIs, time
- **Don't mock internals** — Test behavior, not implementation
- **Use spec** — `Mock(spec=Interface)` catches API changes
- **Verify interactions** — `assert_called_once_with(...)`

## Running Tests

```bash
# All tests
uv run pytest

# Specific test
uv run pytest tests/services/test_user_service.py::TestUserService::test_get_user_returns_user_when_found -v

# With coverage
uv run pytest --cov=src --cov-report=term-missing

# Watch mode
uv run pytest --watch
```

## Integration with Skills

### test-driven-development skill

Load when starting TDD:
```bash
skill test-driven-development
```

Provides:
- TDD cycle reminders
- Test structure templates
- Refactoring guidelines

### generating-tests skill

For generating tests after implementation:
```bash
skill generate-tests
```

## TDD for Different Layers

| Layer | Test Type | Tools |
|-------|-----------|-------|
| Domain/Entities | Unit | pytest, hypothesis |
| Services | Unit + Integration | pytest, pytest-asyncio |
| Repositories | Integration | pytest, testcontainers |
| API Endpoints | Integration | pytest, httpx, TestClient |
| UI Components | Unit + E2E | Vitest, React Testing Library, Playwright |

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Writing too much code in GREEN | Make minimal change to pass |
| Skipping REFACTOR | Schedule refactoring time |
| Testing implementation details | Test behavior/outcomes |
| Slow tests | Mock externals, use in-memory DB |
| Flaky tests | Fix root cause, don't retry |
| No edge cases | Add boundary tests explicitly |

## TDD with OpenCode Agents

### Planner Agent
```
/agent planner
"Create TDD plan for implementing user authentication with JWT"
```

### Backend Agent
```
/agent backend
"Follow TDD: write test first, then implement UserService.authenticate()"
```

### Reviewer Agent
```
/agent reviewer
"Review the TDD implementation for UserService. Check test coverage and quality."
```

## Measuring TDD Success

- **Test coverage** > 80% (aim for 90%+ on business logic)
- **Test speed** < 10s for unit suite
- **Red-Green-Refactor cycles** per feature: 3-10
- **Defect rate** — Should decrease over time
- **Refactoring confidence** — Tests catch regressions