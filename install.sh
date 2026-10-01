#!/usr/bin/env bash
# agent-bootstrap - Complete OpenCode V2 development environment setup for macOS/Linux
# Run: curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
# Or:  bash install.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

log()    { echo -e "${GRAY}[$(date +%H:%M:%S)]${NC} $*"; }
success(){ echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
warn()   { echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} $*"; }
error()  { echo -e "${RED}[$(date +%H:%M:%S)]${NC} $*" >&2; }
info()   { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }

FORCE=false
SKIP_DOCTOR=false
INSTALL_DIR="${HOME}/.local/share/agent-bootstrap"
CONFIG_DIR="${HOME}/.config/opencode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 [options]
Options:
  --force         Overwrite existing installation
  --skip-doctor   Skip final verification
  --install-dir   Custom install directory (default: ~/.local/share/agent-bootstrap)
  --config-dir    Custom config directory (default: ~/.config/opencode)
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true ;;
        --skip-doctor) SKIP_DOCTOR=true ;;
        --install-dir) INSTALL_DIR="$2"; shift ;;
        --config-dir) CONFIG_DIR="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

# Detect OS and package manager
detect_pm() {
    if command -v brew &>/dev/null; then echo "brew"
    elif command -v apt &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else echo "unknown"; fi
}

PM=$(detect_pm)
if [[ "$PM" == "unknown" ]]; then
    error "No supported package manager found (brew, apt, dnf, pacman, zypper)"
    exit 1
fi
info "Detected package manager: $PM"

install_pkg() {
    local name=$1 pkg=$2
    if command -v "$name" &>/dev/null; then
        success "$name already installed"
        return
    fi
    info "Installing $name..."
    case $PM in
        brew) brew install "$pkg" ;;
        apt)  sudo apt update && sudo apt install -y "$pkg" ;;
        dnf)  sudo dnf install -y "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        zypper) sudo zypper install -y "$pkg" ;;
    esac
    success "$name installed"
}

# --- MAIN ---
echo -e "${CYAN}"
echo "=========================================="
echo "  agent-bootstrap macOS/Linux Installer"
echo "=========================================="
echo -e "${NC}"

# 1. Core dependencies
info "[1/8] Installing core dependencies..."
install_pkg git git
install_pkg node node
install_pkg python3 python3
install_pkg uv uv
install_pkg gh gh
install_pkg ffmpeg ffmpeg
install_pkg jq jq
install_pkg curl curl

# 2. OpenCode V2
info "[2/8] Installing OpenCode V2..."
if command -v opencode &>/dev/null; then
    success "OpenCode already installed: $(opencode --version)"
else
    info "Installing OpenCode V2 via npm..."
    npm install -g @opencode/cli@latest
    success "OpenCode V2 installed"
fi

# 3. Python dependencies
info "[3/8] Installing Python dependencies..."
uv pip install playwright yt-dlp chromadb qdrant-client mem0ai linkedin-api instagrapi
playwright install chromium
success "Python dependencies installed"

# 4. Backup existing config
info "[4/8] Backing up existing OpenCode config..."
BACKUP_DIR="${CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
if [[ -d "$CONFIG_DIR" ]]; then
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
    success "Backed up to $BACKUP_DIR"
else
    info "No existing config to backup"
    mkdir -p "$CONFIG_DIR"
fi

# 5. Clone/Copy agent-bootstrap
info "[5/8] Setting up agent-bootstrap repo..."
if [[ -d "$INSTALL_DIR" ]]; then
    if [[ "$FORCE" == true ]]; then
        rm -rf "$INSTALL_DIR"
    else
        warn "Repo exists at $INSTALL_DIR. Use --force to overwrite."
        exit 1
    fi
fi
cp -r "$SCRIPT_DIR" "$INSTALL_DIR"
success "agent-bootstrap copied to $INSTALL_DIR"

# 6. Template configs
info "[6/8] Templating configuration files..."
export AGENT_BOOTSTRAP_ROOT="$INSTALL_DIR"
export AGENT_STACK_ROOT="${HOME}/agent-stack"
export BROWSER_USE_PYTHON="${HOME}/agent-stack/browser-use-env/bin/python"
export OPENVIKING_ROOT="${HOME}/agent-stack/OpenViking"

while IFS= read -r -d '' file; do
    # Replace ${VAR} and $VAR patterns
    sed -i "s|\${USERPROFILE}|${HOME}|g" "$file"
    sed -i "s|\${APPDATA}|${HOME}/.config|g" "$file"
    sed -i "s|\${LOCALAPPDATA}|${HOME}/.local|g" "$file"
    sed -i "s|\${TEMP}|/tmp|g" "$file"
    sed -i "s|\${AGENT_BOOTSTRAP_ROOT}|${AGENT_BOOTSTRAP_ROOT}|g" "$file"
    sed -i "s|\${AGENT_STACK_ROOT}|${AGENT_STACK_ROOT}|g" "$file"
    sed -i "s|\${BROWSER_USE_PYTHON}|${BROWSER_USE_PYTHON}|g" "$file"
    sed -i "s|\${OPENVIKING_ROOT}|${OPENVIKING_ROOT}|g" "$file"
    # Also handle $VAR format
    sed -i "s|\$USERPROFILE|${HOME}|g" "$file"
    sed -i "s|\$APPDATA|${HOME}/.config|g" "$file"
    sed -i "s|\$LOCALAPPDATA|${HOME}/.local|g" "$file"
    sed -i "s|\$TEMP|/tmp|g" "$file"
    sed -i "s|\$AGENT_BOOTSTRAP_ROOT|${AGENT_BOOTSTRAP_ROOT}|g" "$file"
    sed -i "s|\$AGENT_STACK_ROOT|${AGENT_STACK_ROOT}|g" "$file"
    sed -i "s|\$BROWSER_USE_PYTHON|${BROWSER_USE_PYTHON}|g" "$file"
    sed -i "s|\$OPENVIKING_ROOT|${OPENVIKING_ROOT}|g" "$file"
done < <(find "$INSTALL_DIR/config" -type f \( -name "*.jsonc" -o -name "*.json" -o -name "*.md" -o -name "*.sh" -o -name "*.py" \) -print0)

success "Config files templated"

# Deploy configs
cp -r "$INSTALL_DIR/config/"* "$CONFIG_DIR/"
success "Configs deployed to $CONFIG_DIR"

# 7. Register MCPs
info "[7/8] Registering MCP servers..."
MCP_CONFIG="${CONFIG_DIR}/mcp.json"
cat > "$MCP_CONFIG" <<EOF
{
  "mcpServers": {
    "browser-use": {
      "command": "${BROWSER_USE_PYTHON}",
      "args": ["-m", "browser_use.mcp.server"],
      "env": {
        "BH_AGENT_WORKSPACE": "${AGENT_BOOTSTRAP_ROOT}"
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "vision": {
      "command": "${BROWSER_USE_PYTHON}",
      "args": ["-m", "opencode_vision.server"],
      "env": {
        "PYTHONPATH": "${HOME}/.config/opencode/mcp"
      }
    }
  }
}
EOF
success "MCP config written to $MCP_CONFIG"

# Register with opencode
opencode mcp add browser-use --config "$MCP_CONFIG" 2>/dev/null || true
opencode mcp add context7 --config "$MCP_CONFIG" 2>/dev/null || true
opencode mcp add vision --config "$MCP_CONFIG" 2>/dev/null || true
success "MCPs registered"

# 8. Doctor verification
if [[ "$SKIP_DOCTOR" != true ]]; then
    info "[8/8] Running verification..."
    opencode doctor || warn "Doctor check had warnings"
fi

echo -e "${GREEN}"
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo -e "${NC}"
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. Run 'opencode' to start"
echo "  3. Check 'opencode mcp list' for MCP status"
echo ""
echo "Repo location: $INSTALL_DIR"
echo "Config location: $CONFIG_DIR"
echo "Backup location: $BACKUP_DIR"