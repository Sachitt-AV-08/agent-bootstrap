# macOS Installation Guide

## Prerequisites

- macOS 12+ (Monterey or later)
- Homebrew (auto-installed if missing)
- Terminal (iTerm2 recommended)

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/<your-repo>/agent-bootstrap/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/<your-repo>/agent-bootstrap.git
cd agent-bootstrap
chmod +x install.sh
./install.sh
```

## What Gets Installed

| Tool | Method | Notes |
|------|--------|-------|
| Git | brew | `git` |
| Node.js 24 LTS | brew | `node` |
| Python 3.12 | brew | `python@3.12` |
| uv | brew | `uv` |
| GitHub CLI | brew | `gh` |
| FFmpeg | brew | `ffmpeg` |
| jq | brew | `jq` |
| OpenCode V2 | npm | `@opencode/cli@latest` |
| Python deps | uv | playwright, yt-dlp, chromadb, qdrant, mem0, linkedin-api, instagrapi |

## Browser-use Environment

Created at:
```
~/agent-stack/browser-use-env/
```

## Post-Install

1. **Restart Terminal** (or `source ~/.zshrc` / `source ~/.bashrc`)
2. **Verify**: `opencode doctor`
3. **Check MCPs**: `opencode mcp list`
4. **Start coding**: `opencode`

## Troubleshooting

### "Homebrew not found"
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "Python not found"
```bash
brew install python@3.12
```

### "OpenCode command not found"
```bash
npm install -g @opencode/cli@latest
```

### "Permission denied" on install.sh
```bash
chmod +x install.sh
```

### MCP connection failures
```bash
# Re-run browser-use setup
./scripts/setup-browser-use.sh

# Verify
~/agent-stack/browser-use-env/bin/python -c "import browser_use; print('OK')"
```

### Apple Silicon (M1/M2/M3) notes
All tools install natively via Homebrew. No Rosetta needed.

## Uninstall

```bash
# Remove configs
rm -rf ~/.config/opencode

# Remove repo
rm -rf ~/.local/share/agent-bootstrap

# Remove OpenCode
npm uninstall -g @opencode/cli
```