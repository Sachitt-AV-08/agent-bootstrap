#!/usr/bin/env bash
# Verify agent-bootstrap installation

set -euo pipefail

VERBOSE=false
FIX=false

for arg in "$@"; do
    case $arg in
        --verbose) VERBOSE=true ;;
        --fix) FIX=true ;;
    esac
done

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check() {
    local name=$1
    local test_cmd=$2
    local fix_hint=$3
    
    printf "[%-25s] " "$name"
    if eval "$test_cmd" &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        [[ -n "$fix_hint" ]] && echo -e "  ${YELLOW}Fix: $fix_hint${NC}"
        return 1
    fi
}

all_passed=true

echo -e "${CYAN}"
echo "=========================================="
echo "  agent-bootstrap Verification"
echo "=========================================="
echo -e "${NC}"

# 1. OpenCode CLI
check "OpenCode CLI" "opencode --version | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'" "npm install -g @opencode/cli@latest" || all_passed=false

# 2. OpenCode Doctor
check "OpenCode Doctor" "opencode doctor 2>&1 | grep -qE 'OK|pass|healthy'" "Run 'opencode doctor'" || all_passed=false

# 3. MCP Config
MCP_PATH="${HOME}/.config/opencode/mcp.json"
check "MCP Config" "[[ -f '$MCP_PATH' ]]" "Run installer" || all_passed=false

# 4. browser-use Python
BU_PYTHON="${HOME}/agent-stack/browser-use-env/bin/python"
check "browser-use Python" "[[ -x '$BU_PYTHON' ]] && '$BU_PYTHON' -c 'import browser_use' 2>/dev/null" "Run scripts/setup-browser-use.sh" || all_passed=false

# 5. Playwright Chromium
check "Playwright Chromium" "'$BU_PYTHON' -m playwright install chromium 2>&1 | grep -qE 'already|installed|done'" "Run: $BU_PYTHON -m playwright install chromium" || all_passed=false

# 6. Python dependencies
for dep in playwright yt_dlp chromadb qdrant_client mem0 linkedin_api instagrapi; do
    check "Python: $dep" "'$BU_PYTHON' -c 'import $dep' 2>/dev/null" "Run: $BU_PYTHON -m pip install $dep" || all_passed=false
done

# 7. Node/npm
check "Node.js" "node --version | grep -qE '^v[0-9]+'" "Install Node LTS" || all_passed=false
check "npm" "npm --version | grep -qE '^[0-9]+'" "Reinstall Node" || all_passed=false

# 8. Git/GH
check "Git" "git --version | grep -q 'git version'" "Install git" || all_passed=false
check "GitHub CLI" "gh --version | grep -q 'gh version'" "Install gh" || all_passed=false

# 9. FFmpeg
check "FFmpeg" "ffmpeg -version | grep -q 'ffmpeg version'" "Install ffmpeg" || all_passed=false

# 10. uv
check "uv" "uv --version | grep -q 'uv [0-9]'" "Install uv" || all_passed=false

# 11. Config files
CONFIG_DIR="${HOME}/.config/opencode"
for cf in opencode.jsonc tui.json AGENTS.md; do
    check "Config: $cf" "[[ -f '$CONFIG_DIR/$cf' ]]" "Re-run installer" || all_passed=false
done

# 12. MCP Registrations
check "MCP: browser-use" "opencode mcp list 2>/dev/null | grep -q browser-use" "opencode mcp add browser-use" || all_passed=false
check "MCP: context7" "opencode mcp list 2>/dev/null | grep -q context7" "opencode mcp add context7" || all_passed=false
check "MCP: vision" "opencode mcp list 2>/dev/null | grep -q vision" "opencode mcp add vision" || all_passed=false

echo -e "${CYAN}"
echo "=========================================="
if $all_passed; then
    echo -e "  ${GREEN}ALL CHECKS PASSED${NC}"
else
    echo -e "  ${RED}SOME CHECKS FAILED${NC}"
fi
echo -e "${CYAN}==========================================${NC}"

$all_passed && exit 0 || exit 1