# Agent Configuration Reference

## Agent Definition

Agents are defined in `opencode.jsonc` or project `.opencode/settings.jsonc`:

```jsonc
{
  "agents": {
    "default": "main",
    "main": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are an expert software engineer...",
      "permissions": {
        "tools": ["read", "write", "edit", "grep", "glob", "shell", "execute", "skill"],
        "shell": true,
        "network": true
      }
    }
  }
}
```

## Fields

### `model` (optional)
Override default model. Format: `provider/model-id`

```jsonc
"model": "kilo/kilo-auto/free"
"model": "openai/gpt-4o"
"model": "anthropic/claude-3-5-sonnet-20241022"
```

### `systemPrompt` (required)
Instructions for the agent. Be specific and actionable.

**Good:**
```
You are a backend engineer specializing in REST APIs, PostgreSQL, and Redis.
Follow SOLID principles. Write comprehensive tests. Use dependency injection.
Error handling: return Result types, never throw for expected failures.
```

**Bad:**
```
You are a helpful assistant.
```

### `permissions.tools` (optional)
Array of allowed tool names. Default: all tools.

**Available tools:**
- `read` — Read files
- `write` — Write files
- `edit` — Edit files
- `grep` — Search content
- `glob` — Find files
- `shell` — Run shell commands
- `execute` — Run JavaScript in sandbox
- `skill` — Load skills
- `webfetch` — Fetch URLs
- `websearch` — Search web

**Examples:**
```jsonc
"tools": ["*"]                    // All tools
"tools": ["read", "write", "edit"] // Only file ops
"tools": ["read", "grep", "skill"] // Read-only + skills
```

### `permissions.shell` (optional)
Allow shell command execution. Default: `false`.

```jsonc
"shell": true
```

### `permissions.network` (optional)
Allow network requests (webfetch, websearch). Default: `false`.

```jsonc
"network": true
```

## Complete Example: Specialized Agents

```jsonc
{
  "agents": {
    "default": "main",
    
    "main": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are an expert software engineer. Follow AGENTS.md. Use TDD. Write clean, tested code.",
      "permissions": { "tools": ["*"], "shell": true, "network": true }
    },
    
    "planner": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a planning agent. Create detailed implementation plans with clear steps, verification gates, and rollback strategies. Output structured plans only.",
      "permissions": { "tools": ["read", "write", "edit", "grep", "glob", "skill"] }
    },
    
    "backend": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a backend engineer. Expertise: REST/GraphQL APIs, SQL/NoSQL, caching, message queues, auth, observability. Principles: SOLID, clean architecture, proper error handling, comprehensive testing, security first.",
      "permissions": { "tools": ["*"], "shell": true, "network": true }
    },
    
    "frontend": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a frontend engineer. Expertise: React, TypeScript, Tailwind, Vite, testing (Vitest/RTL), accessibility (WCAG), performance. Principles: component composition, proper state management, responsive design, bundle optimization.",
      "permissions": { "tools": ["*"], "shell": true, "network": true }
    },
    
    "devops": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a DevOps engineer. Expertise: CI/CD (GitHub Actions), Docker, Kubernetes, Terraform, AWS/GCP/Azure, monitoring (Prometheus/Grafana), logging, security hardening. Principles: IaC, immutable infrastructure, GitOps, least privilege.",
      "permissions": { "tools": ["*"], "shell": true, "network": true }
    },
    
    "data-scientist": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a data scientist. Expertise: Python (pandas, numpy, scikit-learn, PyTorch), SQL, statistics, ML pipelines, experimentation (A/B testing), visualization, MLOps. Principles: reproducible research, proper validation, feature engineering, model monitoring.",
      "permissions": { "tools": ["*"], "shell": true, "network": true }
    },
    
    "reviewer": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a code reviewer. Apply rigorous technical scrutiny. Check for: correctness, security, performance, maintainability, and test coverage. Be thorough but constructive. Don't approve code with issues.",
      "permissions": { "tools": ["read", "grep", "glob", "skill"] }
    },
    
    "debugger": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a systematic debugger. Use the systematic-debugging skill. Form hypotheses, test them, find root causes. Don't guess — verify. One change at a time. Run tests after each change.",
      "permissions": { "tools": ["read", "write", "edit", "grep", "glob", "shell", "execute", "skill"] }
    },
    
    "tech-writer": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a technical writer. Create clear, accurate documentation: API docs, tutorials, ADRs, runbooks. Follow Diátaxis: tutorial, how-to, reference, explanation. Use consistent terminology, include examples, keep updated.",
      "permissions": { "tools": ["read", "write", "edit", "grep", "glob", "skill"] }
    }
  }
}
```

## Project-Specific Agents

Create `.opencode/agents/<name>.json` in project:

```json
{
  "name": "project-api",
  "model": { "provider": "kilo", "model": "kilo/kilo-auto/free" },
  "systemPrompt": "You are working on the Project API. Follow AGENTS.md. Stack: FastAPI + SQLAlchemy 2.0 + Pydantic v2 + asyncpg. Conventions: async throughout, dependency injection, comprehensive tests with pytest-asyncio, repository pattern.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

## Agent Discovery Order

1. Project agents: `<project>/.opencode/agents/*.json`
2. Project config: `<project>/.opencode/settings.jsonc`
3. Global config: `~/.config/opencode/opencode.jsonc`

## Using Agents

```bash
# Start with agent
opencode --agent backend

# Switch in session
/agent backend

# List agents
opencode agent list

# Show agent config
opencode agent show backend
```

## Best Practices

1. **Single responsibility** — One agent per domain
2. **Specific prompts** — Include conventions, stack, principles
3. **Minimal permissions** — Only grant needed tools
4. **Model selection** — Small model for simple tasks
5. **Document** — Comment why each agent exists
6. **Version control** — Track agent configs in git