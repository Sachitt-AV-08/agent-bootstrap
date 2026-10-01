# MCP Server Setup Guide

## What are MCPs?

Model Context Protocol (MCP) servers extend OpenCode with external capabilities:
- **browser-use** — Browser automation via CDP
- **context7** — Up-to-date library documentation
- **vision** — Image analysis, OCR, visual description
- **Custom** — Your own tools/services

## Configured Servers

### browser-use

Direct browser control for automation, scraping, testing.

**Config:**
```jsonc
{
  "browser-use": {
    "command": "${BROWSER_USE_PYTHON}",
    "args": ["-m", "browser_use.mcp.server"],
    "env": { "BH_AGENT_WORKSPACE": "${AGENT_BOOTSTRAP_ROOT}" }
  }
}
```

**Requirements:**
- Python env at `~/agent-stack/browser-use-env/`
- Chromium installed via Playwright
- Chrome/Chromium with remote debugging (port 9222)

**Usage:**
```python
# In agent session
# The agent can now use browser tools automatically
```

**Troubleshooting:**
```bash
# Verify Python env
~/agent-stack/browser-use-env/bin/python -c "import browser_use; print('OK')"

# Check CDP port
lsof -i :9222

# Restart Chrome with debugging
# macOS: open -a "Google Chrome" --args --remote-debugging-port=9222
# Windows: chrome.exe --remote-debugging-port=9222
# Linux: chromium --remote-debugging-port=9222
```

### context7

Library documentation lookup for any package.

**Config:**
```jsonc
{
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp"]
  }
}
```

**Usage:**
- Automatically invoked when you ask about library APIs
- Resolves library IDs, fetches relevant docs
- Works with: React, Next.js, PyTorch, TensorFlow, etc.

### vision

Image analysis, OCR, visual description.

**Config:**
```jsonc
{
  "vision": {
    "command": "${BROWSER_USE_PYTHON}",
    "args": ["-m", "opencode_vision.server"],
    "env": { "PYTHONPATH": "${HOME}/.config/opencode/mcp" }
  }
}
```

**Requirements:**
- Vision adapter at `~/.config/opencode/mcp/vision-adapter.py`
- Python dependencies: `pillow`, `paddleocr` (optional)

## Adding Custom MCPs

### 1. Create Server Script

```python
# my_mcp/server.py
import json
import sys
from mcp.server import Server
from mcp.types import Tool

app = Server("my-mcp")

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="my_tool", description="Does something", inputSchema={...})
    ]

@app.call_tool()
async def call_tool(name: str, args: dict) -> list[TextContent]:
    if name == "my_tool":
        result = do_something(args)
        return [TextContent(type="text", text=str(result))]
    raise ValueError(f"Unknown tool: {name}")

if __name__ == "__main__":
    app.run()
```

### 2. Register in Config

```jsonc
{
  "mcp": {
    "servers": {
      "my-mcp": {
        "command": "python",
        "args": ["-m", "my_mcp.server"],
        "env": { "MY_API_KEY": "${MY_API_KEY}" }
      }
    }
  }
}
```

### 3. Register with OpenCode

```bash
opencode mcp add my-mcp --config ~/.config/opencode/mcp.json
```

## Managing MCPs

```bash
# List registered MCPs
opencode mcp list

# Add new MCP
opencode mcp add <name> --config <path>

# Remove MCP
opencode mcp remove <name>

# Test MCP connection
opencode mcp test <name>

# View MCP logs
opencode mcp logs <name>
```

## MCP Development

### Local Development

1. Create server in `mcp/my-server/`
2. Add to config with local path:
   ```jsonc
   {
     "my-server": {
       "command": "python",
       "args": ["${AGENT_BOOTSTRAP_ROOT}/mcp/my-server/server.py"]
     }
   }
   ```

### Debugging

```bash
# Run server directly to see output
python -m my_mcp.server

# Check stdin/stdout communication
echo '{"method":"initialize","params":{}}' | python -m my_mcp.server
```

### Protocol

MCP uses JSON-RPC 2.0 over stdio:
- **Initialize**: Handshake
- **ListTools**: Available tools
- **CallTool**: Execute tool
- **ListResources**: Available resources
- **ReadResource**: Read resource content

## Security

- MCPs run as your user with your permissions
- Only install trusted MCPs
- Review server code before adding
- Use env vars for secrets (never hardcode)
- Network access follows OpenCode permissions

## Common Issues

| Issue | Fix |
|-------|-----|
| "Connection refused" | Check command/path, server starts correctly |
| "Tool not found" | Verify `list_tools` returns correct names |
| "Timeout" | Increase `tools.execute.timeout` in config |
| "Import error" | Check PYTHONPATH, venv activation |
| "Permission denied" | Check `permissions.shell` in config |