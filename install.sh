#!/usr/bin/env bash
# agent-bootstrap - Complete OpenCode V2 development environment setup for macOS/Linux
#
# This is a bootstrap, not a second installer. Everything of substance lives in
# install.ps1 so that macOS, Linux and Windows share one implementation; two
# installers is how the platforms silently drift apart and macOS ends up with
# half the agents Linux has.
#
# Run: curl -fsSL https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.sh | bash
# Or:  bash install.sh
#
# The script you get is self-contained: it fetches its own repo copy into
# ~/.local/share/agent-bootstrap, then hands off to the PowerShell installer
# running natively on macOS/Linux.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m';  GRAY='\033[0;90m';  BOLD='\033[1m'; NC='\033[0m'

REPO_URL="https://github.com/Sachitt-AV-08/agent-bootstrap.git"
REPO_RAW="https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main"
INSTALL_DIR="${HOME}/.local/share/agent-bootstrap"

success(){ echo -e "${GREEN}$*${NC}"; }
warn()   { echo -e "${YELLOW}$*${NC}" >&2; }
error()  { echo -e "${RED}$*${NC}" >&2; }
info()   { echo -e "${CYAN}$*${NC}"; }
step()   { echo -e "\n${BOLD}${CYAN}$*${NC}"; }

usage() {
    cat <<EOF
${BOLD}agent-bootstrap${NC} - one command to a full AI agent environment

${BOLD}USAGE${NC}
    bash install.sh [options]
    curl -fsSL $REPO_RAW/install.sh | bash

${BOLD}WHAT TO INSTALL${NC}
    (no options)              everything: 163 agents, 10 commands, 6 skill packs, MCP servers
    --all                     same as no options
    --minimal                 core agents and commands only, no Python packages
    --domains a,b,c           install specific domains
    --with orvima,parley      also register these project MCP servers

${BOLD}SAFETY${NC}
    --dry-run                 show what would happen, change nothing
    --skip-deps               do not install system or Python packages
    --skip-mcp                do not touch MCP server configuration
    --force                   overwrite an existing checkout without asking

${BOLD}OTHER${NC}
    --self-test               verify the installer's own code, install nothing
    --help                    this message

${BOLD}EXAMPLES${NC}
    bash install.sh --dry-run
    bash install.sh --minimal
    bash install.sh --domains research,debugging
EOF
}

# --- locate the source tree ---------------------------------------------
# When piped from curl there is no local copy, so fetch one. When run from a
# clone, use the clone as-is.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
FETCHED=0
if [[ ! -f "$SCRIPT_DIR/install.ps1" ]]; then
    info "Downloading agent-bootstrap..."
    if command -v git &>/dev/null; then
        if [[ -d "$INSTALL_DIR" ]]; then
            info "updating existing checkout at $INSTALL_DIR"
            git -C "$INSTALL_DIR" pull --ff-only 2>&1 | sed 's/^/    /' || \
                { warn "could not update; re-cloning"; rm -rf "$INSTALL_DIR"; git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | sed 's/^/    /'; }
        else
            mkdir -p "$(dirname "$INSTALL_DIR")"
            git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | sed 's/^/    /'
        fi
        SCRIPT_DIR="$INSTALL_DIR"
        FETCHED=1
    else
        error "git is required to download agent-bootstrap, but was not found."
        echo -e "\n  Install it and try again:" >&2
        echo "    macOS:         brew install git" >&2
        echo "    Debian/Ubuntu: sudo apt install git" >&2
        echo -e "\n  Or clone it yourself and re-run:" >&2
        echo "    git clone $REPO_URL" >&2
        echo "    cd agent-bootstrap && bash install.sh" >&2
        exit 1
    fi
fi

PS1="$SCRIPT_DIR/install.ps1"
if [[ ! -f "$PS1" ]]; then
    error "install.ps1 not found in $SCRIPT_DIR - the download was incomplete."
    echo "  Try again: rm -rf $INSTALL_DIR && bash install.sh" >&2
    exit 1
fi

# --- ensure PowerShell 7 -------------------------------------------------
# PowerShell 7 runs natively on macOS and Linux, so delegating to install.ps1
# gives this platform byte-identical behaviour to Windows - same agents, same
# MCP handling, same error messages, same self-test. Writing a second installer
# in bash would mean maintaining every future fix twice.
have_pwsh() { command -v pwsh &>/dev/null; }

# Only a bare integer counts. Some pwsh builds print banners or warnings before
# the version, and a non-numeric result would make the arithmetic test below
# either error out or silently pass.
pwsh_major() {
    pwsh -NoProfile -Command '$PSVersionTable.PSVersion.Major' 2>/dev/null \
        | tr -d '[:space:]' | grep -E '^[0-9]+$' | tail -n1
}

# Authoritative: does a usable pwsh 7 actually run here? Never infer this from
# an installer's exit code - the Microsoft script exits 0 while printing
# "not supported by PowerShell", which reads as a successful install and then
# fails much later with a confusing error.
pwsh_ok() {
    have_pwsh || return 1
    local major
    major="$(pwsh_major || true)"
    [[ -n "$major" && "$major" -ge 7 ]] 2>/dev/null
}

if pwsh_ok; then
    success "PowerShell $(pwsh -NoProfile -Command '$PSVersionTable.PSVersion' 2>/dev/null) found"
else
    if have_pwsh; then
        warn "PowerShell 5 found, but 7 or newer is required."
    else
        step "Installing PowerShell 7 (required to run the installer)"
    fi

    installed_ps=0

    # Homebrew: no sudo, the path macOS users expect.
    if command -v brew &>/dev/null; then
        info "installing powershell via homebrew"
        brew install --cask powershell 2>&1 | sed 's/^/    /' || true
        # cask installs to /opt/homebrew/bin or /usr/local/bin; refresh PATH
        for d in /opt/homebrew/bin /usr/local/bin; do
            [[ -d "$d" ]] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$PATH:$d" ;; esac
        done
        export PATH
    fi

    # Microsoft's own installer: works without sudo, falls back to a local
    # install under ~/.local when a system-wide one is not permitted.
    if ! pwsh_ok && command -v curl &>/dev/null; then
        info "installing powershell via Microsoft's official script"
        if curl -fsSL -o /tmp/agent-bootstrap-install-powershell.sh https://aka.ms/install-powershell.sh 2>/dev/null; then
            chmod +x /tmp/agent-bootstrap-install-powershell.sh
            # Its own output is suppressed: it can print "not supported by
            # PowerShell" and still exit 0, and we verify with pwsh_ok below.
            /tmp/agent-bootstrap-install-powershell.sh -DestinationPath /tmp/agent-bootstrap-pwsh >/dev/null 2>&1 || true
            if [[ -x /tmp/agent-bootstrap-pwsh/pwsh ]]; then
                export PATH="/tmp/agent-bootstrap-pwsh:$PATH"
            fi
            rm -f /tmp/agent-bootstrap-install-powershell.sh
        fi
    fi

    # Distro packages, last resort.
    if ! pwsh_ok && command -v sudo &>/dev/null && command -v apt-get &>/dev/null; then
        warn "trying the distribution package; this needs sudo"
        sudo apt-get update -qq 2>/dev/null || true
        sudo apt-get install -y powershell 2>&1 | sed 's/^/    /' || true
    fi

    if ! pwsh_ok; then
        error "Could not install PowerShell 7 automatically."
        echo -e "\n  ${BOLD}What happened:${NC}  the installer runs on PowerShell 7, which was not" >&2
        echo "  found and could not be installed automatically." >&2
        echo -e "\n  ${BOLD}Why it matters:${NC}  without it there is no way to install the agents." >&2
        echo -e "\n  ${BOLD}What to do:${NC}  install it yourself, then re-run this script." >&2
        echo "    macOS:         brew install --cask powershell" >&2
        echo "    Debian/Ubuntu: see https://aka.ms/install-powershell.sh" >&2
        echo "    Any Linux:     curl -sSL https://aka.ms/install-powershell.sh | bash" >&2
        echo -e "\n  ${BOLD}More help:${NC}  $REPO_URL/blob/main/docs/guides/troubleshooting.md" >&2
        exit 1
    fi
    success "PowerShell 7 installed and verified"
fi

# --- hand off -----------------------------------------------------------
step "Running the agent-bootstrap installer"
exec pwsh -NoProfile -File "$PS1" "$@"
