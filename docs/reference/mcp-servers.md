# MCP Server Reference

## Configured Servers

### browser-use

| Property | Value |
|----------|-------|
| **Name** | `browser-use` |
| **Command** | `${BROWSER_USE_PYTHON} -m browser_use.mcp.server` |
| **Transport** | stdio |
| **Capabilities** | Browser automation, CDP control, scraping, testing |

**Tools Provided:**
- `browser_navigate` — Navigate to URL
- `browser_click` — Click element
- `browser_type` — Type text
- `browser_scroll` — Scroll page
- `browser_screenshot` — Capture screenshot
- `browser_get_text` — Extract text
- `browser_get_html` — Get HTML
- `browser_execute_js` — Run JavaScript
- `browser_wait` — Wait for condition

**Environment:**
```json
{
  "BH_AGENT_WORKSPACE": "${AGENT_BOOTSTRAP_ROOT}"
}
```

**Requirements:**
- Python env with browser-use
- Chromium via Playwright
- Chrome/Chromium with `--remote-debugging-port=9222`

---

### context7

| Property | Value |
|----------|-------|
| **Name** | `context7` |
| **Command** | `npx -y @upstash/context7-mcp` |
| **Transport** | stdio |
| **Capabilities** | Library documentation lookup |

**Tools Provided:**
- `resolve-library-id` — Resolve package to Context7 ID
- `query-docs` — Query library documentation

**Usage:**
- Automatically invoked for library questions
- Resolves: `react`, `next.js`, `pytorch`, `tensorflow`, etc.
- Returns: API docs, examples, version info

---

### vision

| Property | Value |
|----------|-------|
| **Name** | `vision` |
| **Command** | `${BROWSER_USE_PYTHON} -m opencode_vision.server` |
| **Transport** | stdio |
| **Capabilities** | Image analysis, OCR, visual description |

**Tools Provided:**
- `vision_analyze` — Full image analysis
- `vision_describe` — Visual description
- `vision_ocr` — Text extraction (PaddleOCR)

**Environment:**
```json
{
  "PYTHONPATH": "${HOME}/.config/opencode/mcp"
}
```

**Requirements:**
- Vision adapter at `~/.config/opencode/mcp/vision-adapter.py`
- Python: `pillow`, `paddleocr` (optional)

---

## Adding Custom MCP Servers

### 1. Server Structure

```
mcp/my-server/
├── server.py          # Main entry point
├── requirements.txt   # Python deps
├── pyproject.toml     # Or use uv
└── README.md
```

### 2. Minimal Server (Python)

```python
# mcp/my-server/server.py
import asyncio
import json
import sys
from mcp.server import Server
from mcp.types import Tool, TextContent

app = Server("my-server")

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="my_tool",
            description="Does something useful",
            inputSchema={
                "type": "object",
                "properties": {
                    "input": {"type": "string", "description": "Input text"}
                },
                "required": ["input"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, args: dict) -> list[TextContent]:
    if name == "my_tool":
        result = process(args["input"])
        return [TextContent(type="text", text=str(result))]
    raise ValueError(f"Unknown tool: {name}")

def process(input: str) -> str:
    return f"Processed: {input}"

if __name__ == "__main__":
    app.run()
```

### 3. Register in mcp.json

```json
{
  "mcpServers": {
    "my-server": {
      "command": "python",
      "args": ["${AGENT_BOOTSTRAP_ROOT}/mcp/my-server/server.py"],
      "env": {
        "MY_API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

### 4. Register with OpenCode

```bash
opencode mcp add my-server --config ~/.config/opencode/mcp.json
```

### 5. Test

```bash
opencode mcp test my-server
opencode mcp logs my-server --follow
```

---

## MCP Protocol Overview

### Message Types

**Initialize:**
```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}}}
```

**List Tools:**
```json
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}
```

**Call Tool:**
```json
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "tool_name", "arguments": {"arg": "value"}}}
```

**Response:**
```json
{"jsonrpc": "2.0", "id": 3, "result": {"content": [{"type": "text", "text": "Result"}]}}
```

---

## Debugging MCP Servers

### Run Directly

```bash
# Test server startup
python -m my_mcp.server

# Test with manual JSON-RPC
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python -m my_mcp.server
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check command/path, server starts |
| "Tool not found" | Verify `list_tools` returns correct names |
| "Timeout" | Increase `tools.execute.timeout` in config |
| "Import error" | Check PYTHONPATH, venv activation |
| "Permission denied" | Check `permissions.shell` in config |

### Logs

```bash
# View MCP logs
opencode mcp logs browser-use --follow

# Or check OpenCode logs
tail -f ~/.local/share/opencode/logs/opencode.log
```

---

## Security Considerations

1. **Run as your user** — MCP servers have your permissions
2. **Review code** — Before adding any MCP server
3. **Use env vars** — For secrets, never hardcode
4. **Network access** — Follows OpenCode permissions
5. **Filesystem access** — Follows OpenCode permissions
6. **Sandbox** — Consider Docker for untrusted servers

---

## Official MCP Servers

| Server | Package | Description |
|--------|---------|-------------|
| Filesystem | `@modelcontextprotocol/server-filesystem` | File operations |
| Git | `@modelcontextprotocol/server-git` | Git operations |
| SQLite | `@modelcontextprotocol/server-sqlite` | Database queries |
| Postgres | `@modelcontextprotocol/server-postgres` | PostgreSQL |
| Redis | `@modelcontextprotocol/server-redis` | Redis commands |
| Fetch | `@modelcontextprotocol/server-fetch` | HTTP requests |
| Brave Search | `@modelcontextprotocol/server-brave-search` | Web search |
| GitHub | `@modelcontextprotocol/server-github` | GitHub API |

Install:
```bash
opencode mcp add github --config '{"command":"npx","args":["-y","@modelcontextprotocol/server-github"]}'
```