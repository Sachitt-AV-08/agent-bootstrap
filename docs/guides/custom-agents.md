# Custom Agents Guide

## What are Custom Agents?

Agents are specialized AI personas with:
- Custom system prompts
- Specific model configurations
- Tailored permissions
- Focused capabilities

## Agent Configuration

Add to `opencode.jsonc` or project `.opencode/settings.jsonc`:

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
    },
    "backend": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a backend engineer specializing in APIs, databases, and distributed systems. Follow REST best practices, use proper error handling, and write tests.",
      "permissions": {
        "tools": ["read", "write", "edit", "grep", "glob", "shell", "execute", "skill"],
        "shell": true,
        "network": true
      }
    },
    "frontend": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a frontend engineer specializing in React, TypeScript, and modern CSS. Write accessible, performant components with proper testing.",
      "permissions": {
        "tools": ["read", "write", "edit", "grep", "glob", "shell", "execute", "skill"],
        "shell": true,
        "network": true
      }
    },
    "reviewer": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a code reviewer. Apply rigorous technical scrutiny. Check for: correctness, security, performance, maintainability, and test coverage. Be thorough but constructive.",
      "permissions": {
        "tools": ["read", "grep", "glob", "skill"]
      }
    },
    "debugger": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a systematic debugger. Use the systematic-debugging skill. Form hypotheses, test them, find root causes. Don't guess — verify.",
      "permissions": {
        "tools": ["read", "write", "edit", "grep", "glob", "shell", "execute", "skill"]
      }
    }
  }
}
```

## Agent Fields

| Field | Required | Description |
|-------|----------|-------------|
| `model` | No | Override default model (provider/model) |
| `systemPrompt` | Yes | Instructions for the agent |
| `permissions.tools` | No | Allowed tools (default: all) |
| `permissions.shell` | No | Allow shell commands |
| `permissions.network` | No | Allow network requests |

## Using Agents

```bash
# Start with specific agent
opencode --agent backend

# Switch agent in session
/agent backend

# List available agents
opencode agent list
```

## Agent Templates

### Backend Engineer
```jsonc
"backend": {
  "model": "kilo/kilo-auto/free",
  "systemPrompt": "You are a backend engineer. Expertise: REST/GraphQL APIs, SQL/NoSQL databases, caching, message queues, authentication, observability. Principles: SOLID, clean architecture, proper error handling, comprehensive testing, security first.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

### Frontend Engineer
```jsonc
"frontend": {
  "model": "kilo/kilo-auto/free",
  "systemPrompt": "You are a frontend engineer. Expertise: React, TypeScript, Tailwind, Vite, testing (Vitest/RTL), accessibility (WCAG), performance (Core Web Vitals). Principles: component composition, proper state management, responsive design, bundle optimization.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

### DevOps Engineer
```jsonc
"devops": {
  "model": "kilo/kilo-auto/free",
  "systemPrompt": "You are a DevOps engineer. Expertise: CI/CD (GitHub Actions, GitLab CI), Docker, Kubernetes, Terraform, AWS/GCP/Azure, monitoring (Prometheus/Grafana), logging, security hardening. Principles: infrastructure as code, immutable infrastructure, gitops, least privilege.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

### Data Scientist
```jsonc
"data-scientist": {
  "model": "kilo/kilo-auto/free",
  "systemPrompt": "You are a data scientist. Expertise: Python (pandas, numpy, scikit-learn, PyTorch), SQL, statistics, ML pipelines, experimentation (A/B testing), visualization (matplotlib, plotly), MLOps. Principles: reproducible research, proper validation, feature engineering, model monitoring.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

### Technical Writer
```jsonc
"tech-writer": {
  "model": "kilo/kilo-auto/free",
  "systemPrompt": "You are a technical writer. Create clear, accurate documentation: API docs, tutorials, architecture decision records, runbooks. Follow Diátaxis framework: tutorial, how-to, reference, explanation. Use consistent terminology, include examples, keep updated.",
  "permissions": { "tools": ["read", "write", "edit", "grep", "glob", "skill"] }
}
```

## Project-Specific Agents

Create `.opencode/agents/<name>.json` in project:

```json
{
  "name": "project-api",
  "model": { "provider": "kilo", "model": "kilo/kilo-auto/free" },
  "systemPrompt": "You are working on the Project API. Follow the project's AGENTS.md. Key conventions: FastAPI + SQLAlchemy + Pydantic v2, async throughout, dependency injection, comprehensive tests with pytest-asyncio.",
  "permissions": { "tools": ["*"], "shell": true, "network": true }
}
```

## Best Practices

1. **Single responsibility** — One agent per domain
2. **Clear system prompts** — Specific, actionable instructions
3. **Minimal permissions** — Only grant what's needed
4. **Model selection** — Use smaller models for simple tasks
5. **Document purpose** — Comment why each agent exists

## Agent Discovery

Agents are discovered from:
1. Global config: `~/.config/opencode/opencode.jsonc`
2. Project config: `<project>/.opencode/settings.jsonc`
3. Project agents: `<project>/.opencode/agents/*.json`

Priority: Project agents > Project config > Global config