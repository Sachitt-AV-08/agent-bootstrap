# Windows Installation Guide

## Prerequisites

- Windows 10/11
- PowerShell 7+ (`pwsh`)
- Administrator privileges (recommended)

The one-liner below installs PowerShell's prerequisites for you, but you need
PowerShell 7 itself already. If `pwsh` is not found, install it first:

```powershell
winget install Microsoft.PowerShell
```

Then close the terminal, open a new one, and confirm `pwsh --version` reports 7
or higher.

## Quick Install

```powershell
irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex
```

To be asked what to install instead of getting everything:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1))) --interactive
```

Preview without changing anything:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1))) --dry-run
```

> **Why the longer form?** `Invoke-Expression` cannot take arguments — there is no
> `iex -args`, and `irm ... | iex --interactive` silently ignores the flag and
> installs everything. `& ([scriptblock]::Create(...))` runs the downloaded text
> with arguments attached, which is why these two lines are shaped differently.
> The plain `irm ... | iex` above needs no flags, so it stays short.

Or clone and run locally:

```powershell
git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git
cd agent-bootstrap
.\install.ps1 --interactive
```

## "running scripts is disabled on this system"

This is PowerShell's execution policy blocking `.\install.ps1`, and it is the
single most common reason a first run fails on Windows. It affects running the
file directly — it does **not** affect the `irm ... | iex` one-liner, because
that pipes text rather than loading a script file. If you hit it, either use the
one-liner, or bypass it for that one command:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install.ps1
```

`Bypass` here applies only to that process. It does not change any setting on
your machine. If you would rather change the policy for your user account:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

`RemoteSigned` allows local scripts you wrote and blocks downloaded unsigned ones,
which is the sensible default on a development machine. You can see the current
settings with `Get-ExecutionPolicy -List`.

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