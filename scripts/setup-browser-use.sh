#!/usr/bin/env bash
# Set up browser-use Python environment for MCP

set -euo pipefail

ENV_PATH="${HOME}/agent-stack/browser-use-env"
PYTHON_VERSION="3.12"

log()    { echo -e "\033[0;90m[$(date +%H:%M:%S)]\033[0m $*"; }
success(){ echo -e "\033[0;32m[$(date +%H:%M:%S)]\033[0m $*"; }
warn()   { echo -e "\033[1;33m[$(date +%H:%M:%S)]\033[0m $*"; }
error()  { echo -e "\033[0;31m[$(date +%H:%M:%S)]\033[0m $*" >&2; }

log "Setting up browser-use environment at $ENV_PATH..."

# Check Python
if ! command -v "python$PYTHON_VERSION" &>/dev/null && ! command -v python3 &>/dev/null; then
    error "Python $PYTHON_VERSION not found. Install via your package manager."
    exit 1
fi

PYTHON_CMD=$(command -v "python$PYTHON_VERSION" || command -v python3)

# Create venv
if [[ -d "$ENV_PATH" ]]; then
    warn "Environment exists. Removing..."
    rm -rf "$ENV_PATH"
fi

"$PYTHON_CMD" -m venv "$ENV_PATH"
success "Virtual environment created"

# Upgrade pip
"$ENV_PATH/bin/pip" install --upgrade pip

# Install browser-use and dependencies
packages=(
    'browser-use'
    'playwright'
    'lxml'
    'cssselect'
    'pydantic'
    'pydantic-settings'
    'python-dotenv'
    'requests'
    'aiohttp'
    'websockets'
)

for pkg in "${packages[@]}"; do
    log "Installing $pkg..."
    "$ENV_PATH/bin/pip" install "$pkg"
done

# Install Playwright browsers
log "Installing Playwright Chromium..."
"$ENV_PATH/bin/playwright" install chromium
"$ENV_PATH/bin/playwright" install-deps chromium 2>/dev/null || true

# Verify
log "Verifying installation..."
"$ENV_PATH/bin/python" -c "import browser_use; print('browser-use OK')"
"$ENV_PATH/bin/python" -c "import playwright; print('playwright OK')"

success "Browser-use environment ready at $ENV_PATH"
echo "Binary: $ENV_PATH/bin/python"