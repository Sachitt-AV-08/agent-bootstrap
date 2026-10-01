# OpenCode Configuration Guide

## Configuration Files

OpenCode uses JSONC (JSON with comments) for configuration. Files are loaded in order:

1. **Global**: `~/.config/opencode/opencode.jsonc`
2. **Project**: `<project>/.opencode/settings.jsonc` (overrides global)

## Key Configuration Sections

### Providers & Models

```jsonc
{
  "providers": {
    "kilo": {
      "apiKey": "${KILO_API_KEY}",
      "baseURL": "https://api.kilo.ai/v1",
      "models": {
        "default": "kilo/kilo-auto/free",
        "small": "kilo/kilo-auto/small"
      }
    },
    "openai": {
      "apiKey": "${OPENAI_API_KEY}",
      "models": {
        "default": "gpt-4o",
        "small": "gpt-4o-mini"
      }
    }
  },
  "model": {
    "provider": "kilo",
    "model": "kilo/kilo-auto/free",
    "temperature": 0.3,
    "maxTokens": 8192
  }
}
```

### Agents

Define specialized agents for different tasks:

```jsonc
{
  "agents": {
    "default": "main",
    "main": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are an expert software engineer...",
      "permissions": {
        "tools": ["read", "write", "edit", "shell", "execute"],
        "shell": true,
        "network": true
      }
    },
    "planner": {
      "model": "kilo/kilo-auto/free",
      "systemPrompt": "You are a planning agent...",
      "permissions": { "tools": ["read", "write", "skill"] }
    }
  }
}
```

### MCP Servers

```jsonc
{
  "mcp": {
    "enabled": true,
    "servers": {
      "browser-use": {
        "command": "${BROWSER_USE_PYTHON}",
        "args": ["-m", "browser_use.mcp.server"],
        "env": { "BH_AGENT_WORKSPACE": "${AGENT_BOOTSTRAP_ROOT}" }
      },
      "context7": {
        "command": "npx",
        "args": ["-y", "@upstash/context7-mcp"]
      }
    }
  }
}
```

### Skills

```jsonc
{
  "skills": {
    "enabled": true,
    "autoLoad": true,
    "directories": [
      "${AGENT_BOOTSTRAP_ROOT}/skills",
      "${HOME}/.config/opencode/skills"
    ]
  }
}
```

### Tools

```jsonc
{
  "tools": {
    "shell": {
      "enabled": true,
      "defaultShell": "pwsh",  // or "bash", "zsh"
      "allowedCommands": ["*"]
    },
    "execute": { "enabled": true, "timeout": 120000 },
    "browser": { "enabled": true, "headless": true }
  }
}
```

### Permissions

```jsonc
{
  "permissions": {
    "default": "ask",      // "allow" | "deny" | "ask"
    "shell": "allow",
    "network": "allow",
    "filesystem": "allow"
  }
}
```

## Environment Variable Substitution

Use `${VAR_NAME}` or `$VAR_NAME` in configs:

```jsonc
{
  "model": { "provider": "${DEFAULT_PROVIDER:-kilo}" },
  "mcp": {
    "servers": {
      "custom": {
        "command": "${CUSTOM_PYTHON:-python}",
        "args": ["-m", "my_mcp"]
      }
    }
  }
}
```

## Project-Specific Config

Create `.opencode/settings.jsonc` in your project:

```jsonc
{
  "model": { "provider": "kilo", "model": "kilo/kilo-auto/free" },
  "agents": {
    "default": "project-agent",
    "project-agent": {
      "systemPrompt": "Work on this specific project. Follow AGENTS.md.",
      "permissions": { "tools": ["*"] }
    }
  },
  "skills": { "directories": ["${workspace}/.opencode/skills"] }
}
```

## Managing API Keys

**Never commit API keys to git.**

Options:
1. **Environment variables** (recommended):
   ```bash
   export KILO_API_KEY="your-key"
   export OPENAI_API_KEY="your-key"
   ```

2. **`.env` file** (gitignored):
   ```bash
   KILO_API_KEY=your-key
   ```

3. **Keychain/credential manager**:
   ```bash
   # macOS
   security add-generic-password -a $USER -s kilo-api-key -w "your-key"
   
   # Linux (libsecret)
   secret-tool store --label="Kilo API Key" service kilo user $USER
   ```

## Verifying Config

```bash
# Validate JSONC syntax
opencode config validate

# Show effective config
opencode config show

# Test MCP connections
opencode mcp list
opencode mcp test browser-use
```

## Common Patterns

### Multiple Model Profiles

```jsonc
{
  "agents": {
    "default": "main",
    "main": { "model": "kilo/kilo-auto/free" },
    "fast": { "model": "kilo/kilo-auto/small" },
    "powerful": { "model": "openai/gpt-4o" }
  }
}
```
Switch with: `opencode --agent fast`

### Per-Directory Config

```jsonc
{
  "projects": {
    "~/work/backend": { "model": { "provider": "anthropic" } },
    "~/work/frontend": { "model": { "provider": "openai" } }
  }
}
```

## Debugging Config Issues

1. **Syntax errors**: `opencode config validate`
2. **Env var not expanding**: Check spelling, use `${VAR:-default}`
3. **MCP not connecting**: `opencode mcp test <name>` + check logs
4. **Permission denied**: Check `permissions` section, run `opencode doctor`