# Linux Installation Guide

## Prerequisites

- Linux (Ubuntu 22.04+, Debian 12+, Fedora 38+, Arch, openSUSE)
- Package manager: apt, dnf, pacman, or zypper
- Bash shell

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

| Tool | apt | dnf | pacman | zypper |
|------|-----|-----|--------|--------|
| Git | `git` | `git` | `git` | `git` |
| Node.js 24 | `nodejs` | `nodejs` | `nodejs` | `nodejs20` |
| Python 3.12 | `python3.12` | `python3.12` | `python` | `python312` |
| uv | script | script | script | script |
| GitHub CLI | `gh` | `gh` | `github-cli` | `gh` |
| FFmpeg | `ffmpeg` | `ffmpeg` | `ffmpeg` | `ffmpeg` |
| jq | `jq` | `jq` | `jq` | `jq` |

Plus OpenCode V2 (npm) and Python deps (uv).

## Browser-use Environment

Created at:
```
~/agent-stack/browser-use-env/
```

## Post-Install

1. **Restart shell** (or `source ~/.bashrc` / `source ~/.zshrc`)
2. **Verify**: `opencode doctor`
3. **Check MCPs**: `opencode mcp list`
4. **Start coding**: `opencode`

## Distribution-Specific Notes

### Ubuntu/Debian
```bash
# Node.js 24 from NodeSource
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# Python 3.12 (Ubuntu 22.04)
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update && sudo apt install python3.12 python3.12-venv
```

### Fedora
```bash
# Node.js 24
sudo dnf module install nodejs:24

# Python 3.12 usually available
sudo dnf install python3.12
```

### Arch
```bash
# All packages in official repos or AUR
sudo pacman -S nodejs npm python uv git gh ffmpeg jq
# uv: curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh
```

### openSUSE
```bash
sudo zypper install nodejs20 python312 git gh ffmpeg jq
# uv: curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh
```

## Troubleshooting

### "Package manager not detected"
Ensure you have apt, dnf, pacman, or zypper installed.

### "Python 3.12 not available"
Install from source or use deadsnakes PPA (Ubuntu) / COPR (Fedora).

### "OpenCode command not found"
```bash
npm install -g @opencode/cli@latest
# Ensure npm global bin is in PATH
export PATH="$(npm prefix -g)/bin:$PATH"
```

### "playwright install fails"
```bash
# Install system dependencies
# Ubuntu/Debian:
sudo apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2

# Fedora:
sudo dnf install -y nss nspr atk at-spi2-atk cups-libs libdrm libxkbcommon libxcomposite libxdamage libxfixes libxrandr mesa-libgbm alsa-lib

# Then:
~/agent-stack/browser-use-env/bin/playwright install-deps chromium
```

### MCP connection failures
```bash
# Re-run browser-use setup
./scripts/setup-browser-use.sh

# Verify
~/agent-stack/browser-use-env/bin/python -c "import browser_use; print('OK')"
```

## Uninstall

```bash
# Remove configs
rm -rf ~/.config/opencode

# Remove repo
rm -rf ~/.local/share/agent-bootstrap

# Remove OpenCode
npm uninstall -g @opencode/cli
```