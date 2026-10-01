# OpenCode CLI Reference

## Global Commands

```bash
opencode [options] [command]

Options:
  -h, --help           Show help
  -v, --version        Show version
  -c, --config <path>  Config file path
  --agent <name>       Start with specific agent
  --session <id>       Resume session
  --no-mcp             Disable MCP servers
  --debug              Enable debug logging
```

## Session Management

```bash
# Start new session
opencode

# List sessions
opencode session list

# Create session
opencode session new [name]

# Resume session
opencode session resume <id>

# Delete session
opencode session delete <id>

# Export session
opencode session export <id> > session.json

# Import session
opencode session import < session.json
```

## Agent Commands

```bash
# List agents
opencode agent list

# Show agent config
opencode agent show <name>

# Switch agent in session
/agent <name>
```

## Model Commands

```bash
# List available models
opencode models list

# List models for provider
opencode models <provider>

# Show model info
opencode models info <model-id>

# Set default model
opencode models default <model-id>
```

## MCP Commands

```bash
# List MCP servers
opencode mcp list

# Add MCP server
opencode mcp add <name> --config <path>

# Remove MCP server
opencode mcp remove <name>

# Test MCP connection
opencode mcp test <name>

# View MCP logs
opencode mcp logs <name> [--follow]
```

## Skill Commands

```bash
# List skills
opencode skill list

# Show skill details
opencode skill show <name>

# Install skill from git
opencode skill install <git-url>

# Uninstall skill
opencode skill uninstall <name>

# Create skill scaffold
opencode skill create <name>
```

## Config Commands

```bash
# Validate config
opencode config validate

# Show effective config
opencode config show

# Edit config
opencode config edit

# Reset config
opencode config reset
```

## Doctor & Diagnostics

```bash
# Run diagnostics
opencode doctor

# Check specific component
opencode doctor --mcp
opencode doctor --models
opencode doctor --skills
```

## In-Session Commands

```bash
/help              Show help
/agent <name>      Switch agent
/skill <name>      Load skill
/model <model>     Switch model
/clear             Clear conversation
/exit              Exit session
/quit              Quit (alias)
```

## Keyboard Shortcuts (Default)

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Interrupt/quit |
| `Ctrl+P` | Command palette |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+L` | Toggle logs |
| `Ctrl+N` | New session |
| `Ctrl+Tab` | Next session |
| `Ctrl+Shift+Tab` | Previous session |
| `Enter` | Send message |
| `Shift+Enter` | New line |
| `PageUp` | Scroll up |
| `PageDown` | Scroll down |
| `Ctrl+R` | Regenerate response |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid usage |
| 3 | Config error |
| 4 | MCP connection failed |
| 5 | Model unavailable |
| 130 | Interrupted (Ctrl+C) |

## Environment Variables

```bash
OPENCODE_CONFIG        # Config file path
OPENCODE_SESSION_DIR   # Session storage
OPENCODE_LOG_LEVEL     # debug, info, warn, error
OPENCODE_NO_MCP        # Disable MCPs (1/0)
OPENCODE_DEBUG         # Debug mode (1/0)
```

## Examples

```bash
# Start with specific agent
opencode --agent backend

# Resume last session
opencode --session last

# Use custom config
opencode -c ~/my-config.jsonc

# Disable MCPs for quick start
opencode --no-mcp

# Debug mode
OPENCODE_DEBUG=1 opencode
```