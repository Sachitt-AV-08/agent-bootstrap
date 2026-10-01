# Environment Variables Reference

## Required for Core Functionality

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `KILO_API_KEY` | Kilo gateway API key | - | Yes (if using Kilo) |
| `OPENAI_API_KEY` | OpenAI API key | - | If using OpenAI |
| `ANTHROPIC_API_KEY` | Anthropic API key | - | If using Anthropic |

## OpenCode Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_CONFIG` | Config file path | `~/.config/opencode/opencode.jsonc` |
| `OPENCODE_SESSION_DIR` | Session storage | `~/.local/share/opencode/sessions` |
| `OPENCODE_LOG_LEVEL` | Log level | `info` |
| `OPENCODE_NO_MCP` | Disable MCPs | `0` |
| `OPENCODE_DEBUG` | Debug mode | `0` |

## Agent Bootstrap Paths

| Variable | Description | Windows Default | Unix Default |
|----------|-------------|-----------------|--------------|
| `AGENT_BOOTSTRAP_ROOT` | This repo root | `%USERPROFILE%\.local\share\agent-bootstrap` | `~/.local/share/agent-bootstrap` |
| `AGENT_STACK_ROOT` | Agent stack root | `%USERPROFILE%\agent-stack` | `~/agent-stack` |
| `BROWSER_USE_PYTHON` | Browser-use Python | `%USERPROFILE%\agent-stack\browser-use-env\Scripts\python.exe` | `~/agent-stack/browser-use-env/bin/python` |
| `OPENVIKING_ROOT` | OpenViking repo | `%USERPROFILE%\agent-stack\OpenViking` | `~/agent-stack/OpenViking` |

## Browser-Use / MCP

| Variable | Description | Default |
|----------|-------------|---------|
| `BH_AGENT_WORKSPACE` | Browser-use workspace | `${AGENT_BOOTSTRAP_ROOT}` |
| `BH_DOMAIN_SKILLS` | Enable domain skills | `0` |
| `BH_RECORD` | Enable recordings | `0` |
| `BH_TAB_MARKER` | Horse marker in titles | `1` |
| `BU_CDP_URL` | Chrome DevTools HTTP URL | - |
| `BU_CDP_WS` | Chrome DevTools WS URL | - |
| `BU_NAME` | Browser-use daemon name | `default` |

## Python / uv

| Variable | Description | Default |
|----------|-------------|---------|
| `UV_PYTHON` | Python executable for uv | auto-detect |
| `UV_CACHE_DIR` | uv cache directory | `~/.cache/uv` |
| `UV_INDEX_URL` | Custom PyPI index | - |
| `PYTHONPATH` | Python module path | - |
| `VIRTUAL_ENV` | Active venv path | auto-set |

## Node.js / npm

| Variable | Description | Default |
|----------|-------------|---------|
| `NPM_CONFIG_PREFIX` | Global npm prefix | `~/.npm-global` |
| `NODE_PATH` | Node module path | - |
| `NPM_REGISTRY` | Custom npm registry | `https://registry.npmjs.org` |

## Shell

| Variable | Description | Windows | Unix |
|----------|-------------|---------|------|
| `SHELL` | Default shell | `pwsh` | `bash`/`zsh` |
| `PROFILE` | PowerShell profile | `$PROFILE` | - |
| `PS1` | Bash prompt | - | user-defined |

## Editor / Tools

| Variable | Description | Default |
|----------|-------------|---------|
| `EDITOR` | Default editor | `code -w` / `vim` |
| `VISUAL` | Visual editor | same as EDITOR |
| `PAGER` | Pager program | `less` |
| `BROWSER` | Default browser | system default |

## Git / GitHub

| Variable | Description | Default |
|----------|-------------|---------|
| `GITHUB_TOKEN` / `GH_TOKEN` | GitHub CLI token | from `gh auth` |
| `GIT_AUTHOR_NAME` | Git author name | git config |
| `GIT_AUTHOR_EMAIL` | Git author email | git config |
| `GIT_COMMITTER_NAME` | Git committer name | same as author |
| `GIT_COMMITTER_EMAIL` | Git committer email | same as author |

## MCP Server Specific

### browser-use
```bash
BH_AGENT_WORKSPACE=/path/to/workspace
BH_DOMAIN_SKILLS=1
BH_RECORD=1
```

### context7
```bash
# No additional env vars needed
```

### vision
```bash
PYTHONPATH=/path/to/vision/adapter
```

## Setting Environment Variables

### Windows (PowerShell)
```powershell
# Current session
$env:KILO_API_KEY = "your-key"

# Persistent (user)
[Environment]::SetEnvironmentVariable("KILO_API_KEY", "your-key", "User")

# Persistent (machine, requires admin)
[Environment]::SetEnvironmentVariable("KILO_API_KEY", "your-key", "Machine")

# In profile ($PROFILE)
$env:KILO_API_KEY = "your-key"
```

### Unix (bash/zsh)
```bash
# Current session
export KILO_API_KEY="your-key"

# Persistent (~/.bashrc, ~/.zshrc, ~/.profile)
echo 'export KILO_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc
```

### .env File (gitignored)
```bash
# .env
KILO_API_KEY=your-key
OPENAI_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
```

Load with:
```bash
# bash/zsh
set -a; source .env; set +a

# PowerShell
$env:KILO_API_KEY = (Get-Content .env | Where-Object { $_ -match '^KILO_API_KEY=' }) -replace '^KILO_API_KEY=',''
```

### direnv (Per-Directory)
```bash
# .envrc
export KILO_API_KEY="your-key"
export OPENCODE_CONFIG="./.opencode/opencode.jsonc"

# Allow
direnv allow
```

## Verification

```bash
# Check all agent-bootstrap vars
env | grep -E 'AGENT_|BROWSER_|OPENVIKING|BH_|BU_'

# Check API keys (masked)
env | grep -E '_API_KEY|_TOKEN' | sed 's/=.*/=***MASKED***/'

# Check OpenCode config
opencode config show | grep -A5 -B5 "apiKey"
```

## Security Best Practices

1. **Never commit** `.env` or API keys to git
2. **Use `.gitignore`** for `.env`, `.env.local`, `.env.*.local`
3. **Rotate keys** periodically
4. **Use least privilege** — separate keys per service
5. **Use secret managers** for production:
   - AWS Secrets Manager
   - Azure Key Vault
   - GCP Secret Manager
   - 1Password CLI (`op read`)
   - Bitwarden CLI (`bw get`)
6. **Audit** with `git-secrets` or `truffleHog`