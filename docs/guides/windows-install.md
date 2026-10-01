# Windows Installation Guide

## Prerequisites

- Windows 10/11
- PowerShell 7+ (`pwsh`)
- Administrator privileges (recommended)

## Quick Install

```powershell
# Run from PowerShell 7+
irm https://raw.githubusercontent.com/<your-repo>/agent-bootstrap/main/install.ps1 | iex
```

Or clone and run locally:

```powershell
git clone https://github.com/<your-repo>/agent-bootstrap.git
cd agent-bootstrap
.\install.ps1
```

## What Gets Installed

| Tool | Method | Notes |
|------|--------|-------|
| Git | winget | `Git.Git` |
| Node.js 24 LTS | winget | `OpenJS.NodeJS.LTS` |
| Python 3.12 | winget | `Python.Python.3.12` |
| uv | winget | `astral-sh.uv` |
| GitHub CLI | winget | `GitHub.cli` |
| FFmpeg | winget | `Gyan.FFmpeg` |
| jq | winget | `jqlang.jq` |
| OpenCode V2 | npm | `@opencode/cli@latest` |
| Python deps | uv | playwright, yt-dlp, chromadb, qdrant, mem0, linkedin-api, instagrapi |

## Browser-use Environment

The installer creates a dedicated Python environment at:
```
%USERPROFILE%\agent-stack\browser-use-env\
```

This isolates browser-use dependencies from your system Python.

## Post-Install

1. **Restart PowerShell** (or run `. $PROFILE`)
2. **Verify**: `opencode doctor`
3. **Check MCPs**: `opencode mcp list`
4. **Start coding**: `opencode`

## Troubleshooting

### "Script execution disabled"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "winget not found"
Install from Microsoft Store or use Chocolatey/Scoop instead.

### "Python not found after install"
Restart shell. Python 3.12 adds to PATH on next session.

### "OpenCode command not found"
```powershell
npm install -g @opencode/cli@latest
```

### MCP connection failures
```powershell
# Re-run browser-use setup
.\scripts\setup-browser-use.ps1

# Verify
%USERPROFILE%\agent-stack\browser-use-env\Scripts\python.exe -c "import browser_use; print('OK')"
```

## Uninstall

```powershell
# Remove configs
Remove-Item "$env:USERPROFILE\.config\opencode" -Recurse -Force

# Remove repo
Remove-Item "$env:USERPROFILE\.local\share\agent-bootstrap" -Recurse -Force

# Remove OpenCode
npm uninstall -g @opencode/cli
```