# Troubleshooting

Every fatal error the installer can print has a code like `[E_NO_PYTHON]`.
Look up the code below. If your error is not listed, it came from somewhere
other than the installer — see [Something else went wrong](#something-else-went-wrong).

**Your configuration is never half-written.** If the installer stops, either it
changed nothing, or it made a backup first and printed where that backup is. You
can always go back:

```powershell
# find the most recent backup
Get-ChildItem "$HOME/.config" -Directory -Filter 'opencode-backup-*' |
  Sort-Object Name -Descending | Select-Object -First 1

# restore it
Copy-Item -Recurse -Force "<that folder>\*" "$HOME/.config/opencode\"
```

---

## Table of contents

- [Before you do anything else](#before-you-do-anything-else)
- [Missing tools](#missing-tools)
  - [`E_NO_NODE` — Node.js not found](#e_no_node--nodejs-not-found)
  - [`E_NO_PYTHON` — Python not found](#e_no_python--python-not-found)
  - [`E_PATH_MISSING` — opencode installed but not on PATH](#e_path_missing--opencode-installed-but-not-on-path)
- [Installer bugs (please report these)](#installer-bugs-please-report-these)
  - [`E_CONFIG_INVALID` — generated config is not valid JSON](#e_config_invalid--generated-config-is-not-valid-json)
  - [`E_DUPLICATE_AGENT` — two agents have the same name](#e_duplicate_agent--two-agents-have-the-same-name)
  - [`E_NO_TEMPLATE` — config template is missing](#e_no_template--config-template-is-missing)
  - [`E_NO_SELFTEST` — self-test script is missing](#e_no_selftest--self-test-script-is-missing)
- [Package installation failed](#package-installation-failed)
  - [`E_NETWORK` — could not reach the internet](#e_network--could-not-reach-the-internet)
  - [`E_NPM_INSTALL` — npm failed](#e_npm_install--npm-failed)
  - [`E_PYTHON_INSTALL` — pip failed](#e_python_install--pip-failed)
- [Permissions and locked files](#permissions-and-locked-files)
  - [`E_PERMISSION_DENIED` — cannot write where we need to](#e_permission_denied--cannot-write-where-we-need-to)
  - [`E_CONFIG_LOCKED` — your config file is open in another program](#e_config_locked--your-config-file-is-open-in-another-program)
- [Wrong flags](#wrong-flags)
  - [`E_UNKNOWN_FLAG`](#e_unknown_flag)
  - [`E_UNKNOWN_DOMAIN`](#e_unknown_domain)
  - [`E_MISSING_VALUE`](#e_missing_value)
  - [`E_CONFLICTING_FLAGS`](#e_conflicting_flags)
- [MCP server will not start](#mcp-server-will-not-start)
- [Something else went wrong](#something-else-went-wrong)
- [Verify your install](#verify-your-install)

---

## Before you do anything else

Run the self-test. It checks the installer's own code without installing
anything or touching your config:

```powershell
./install.ps1 --self-test
```

Then check your current state:

```powershell
doctor
```

Both are safe to run at any time. If either passes, your install is fine and
the problem is something narrower.

---

## Missing tools

### `E_NO_NODE` — Node.js not found

OpenCode is a Node program, so nothing can be installed without Node.

```powershell
winget install OpenJS.NodeJS.LTS     # Windows
brew install node@20                 # macOS
sudo apt install nodejs npm          # Debian/Ubuntu
```

Then **close your terminal and open a new one** — `node` will not appear until
you do, because PATH is set when the terminal starts. Confirm with `node -v`.

### `E_NO_PYTHON` — Python not found

Some domains (scraping, video, memory, data) import Python libraries. The
installer refuses to skip this silently, because a config whose skills all fail
at run time is much harder to diagnose than a stop at install time.

```powershell
winget install Python.Python.3.12
brew install python@3.12
sudo apt install python3-venv python3-pip
```

Or install the agent setup with no Python at all:

```powershell
./install.ps1 --minimal
```

### `E_PATH_MISSING` — opencode installed but not on PATH

OpenCode installed correctly, but a fresh shell cannot find it. Close the
terminal and open a new one. If that does not help, npm's global folder is not
on your PATH:

```powershell
# Windows
$env:PATH += ";$env:APPDATA\npm"
# macOS / Linux - add this line to ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/.local/bin"
```

Reinstalling Node.js is the blunt but reliable fix.

---

## Installer bugs (please report these)

These mean agent-bootstrap itself is wrong, not your machine. Nothing was
changed on your system.

### `E_CONFIG_INVALID` — generated config is not valid JSON

A config that fails to parse loses **every** skill, agent, MCP server and
permission rule at once. The installer therefore validates the file before
writing it and refuses to continue.

The generated file is saved to `%TEMP%\agent-bootstrap-invalid.jsonc`. Please
[open an issue](https://github.com/Sachitt-AV-08/agent-bootstrap/issues) and
attach it.

### `E_DUPLICATE_AGENT` — two agents have the same name

Two files declare the same `name:`. Only one agent can exist under a given name,
and the loser used to disappear without a word — leaving you with fewer agents
than the docs promised. The installer now stops and prints both file paths.

Rename one file **and** the `name:` inside it. See
[custom-agents.md](custom-agents.md).

### `E_NO_TEMPLATE` — config template is missing

`config/opencode.jsonc` is missing from the source tree, so there is nothing to
generate from. Re-clone the repo, or use the one-liner install which downloads a
complete copy.

### `E_NO_SELFTEST` — self-test script is missing

`scripts/selftest.ps1` is missing. Same fix as above.

---

## Package installation failed

### `E_NETWORK` — could not reach the internet

npm and pip both need the internet. Check your connection, then:

```powershell
# proxy or firewall
$env:HTTPS_PROXY = 'http://your-proxy:port'

# corporate network blocking the default registry
npm config set registry https://registry.npmjs.org/
```

### `E_NPM_INSTALL` — npm failed

The real npm error is printed under **What to do**. Common causes:

- **Wrong Node version.** Node 20 or newer is required. Check with `node -v`.
- **Corrupt npm cache.** Try `npm cache clean --force` and re-run.
- **A dependency conflict.** Install OpenCode by hand to see the full error:
  `npm install -g @opencode/cli@latest`

### `E_PYTHON_INSTALL` — pip failed

The real pip error is printed under **What to do**. Common causes:

- **Permission denied.** You are installing into the system Python. Use a
  virtual environment instead:
  ```powershell
  python -m venv ~/.venvs/agent-bootstrap
  ```
- **A package has no wheel for your Python.** Upgrade Python, or skip that
  domain: `./install.ps1 --minimal`
- **A dependency conflict.** Some packages here pin older versions of
  `transformers` and `numpy`. Installing into a fresh virtual environment
  avoids conflicts with other tools on your machine.

---

## Permissions and locked files

### `E_PERMISSION_DENIED` — cannot write where we need to

Either the target folder needs admin rights, or npm's global folder does.

```powershell
# run as Administrator, or redirect to a folder you own
npm config set prefix "$env:APPDATA\npm"
./install.ps1 --target-config "$HOME/.config/opencode"
```

### `E_CONFIG_LOCKED` — your config file is open in another program

Windows locks files that are open elsewhere, and so does a synced folder
occasionally. The installer refuses to overwrite a config it could not back up,
because that overwrite would be unrecoverable.

1. Close OpenCode.
2. Close any editor showing `opencode.jsonc`.
3. If you are using OneDrive/Dropbox/iCloud, pause syncing on that folder.
4. Run the installer again.

If a stale backup folder is in the way, delete it:

```powershell
Remove-Item -Recurse -Force "$HOME/.config/opencode-backup-<timestamp>"
```

---

## Wrong flags

Every spelling of a flag works: `--dry-run`, `-DryRun` and `-dryrun` are the
same flag. `doctor` and `./install.ps1 --help` both list what is available.

### `E_UNKNOWN_FLAG`

That flag does not exist. Run `./install.ps1 --help`. Note that unknown flags are
an **error**, not a warning — silently ignoring one produced installs that looked
fine but were missing what you asked for.

### `E_UNKNOWN_DOMAIN`

That domain name is not real. Common near-misses: `websraping` (web-scraping),
`ml` (data-ml), `docs` (docs-dx), `infra` (backend-infra), `infra` (security).

```powershell
./install.ps1 --help          # or
Get-ChildItem ./agents -Directory | Select-Object -ExpandProperty Name
```

### `E_MISSING_VALUE`

A flag that needs a value had none after it. Add it, or use the `=` form:

```powershell
./install.ps1 --domains research
./install.ps1 --domains=research
```

### `E_CONFLICTING_FLAGS`

`--minimal` means "core only" and `--domains` means "these specific extras".
They contradict. Pick one.

---

## MCP server will not start

MCP servers are optional add-ons. **Everything else installed fine even if these
fail**, and agents that need a broken server will tell you which one when they
run. To see the current state:

```powershell
opencode mcp list
```

Common causes:

| Symptom | Cause | Fix |
|---|---|---|
| `needs authentication` | OAuth server not yet authorized | Start `opencode`, run `/mcps` |
| `Connection closed` on browser-use | Interpreter path points at the wrong Python | See below |
| `command not found` | The MCP's binary is not installed | Install it, or remove that server from your config |
| Server times out | It needs network and the network is blocked | Allow the host through your firewall |

### browser-use points at the wrong Python

This is the most common MCP failure, and it has a specific fix. browser-use must
run from a virtual environment that has it installed — the system Python does
not have it, and pointing at the system Python produces `Connection closed`.

Check what your config says:

```powershell
Select-String -Path "$HOME/.config/opencode/opencode.jsonc" -Pattern 'browser-use' -Context 0,6
```

It should point at a real venv interpreter, for example:

```
"command": ["C:\\Users\\<you>\\agent-stack\\browser-use-env\\Scripts\\python.exe",
            "-m", "browser_use.mcp.cli_mcp"]
```

Then create the environment if you do not have one:

```powershell
python -m venv "$HOME/agent-stack/browser-use-env"
& "$HOME/agent-stack/browser-use-env/Scripts/python.exe" -m pip install -U browser-use
```

and update the path in your config to match.

**Why the installer does not do this for you:** it cannot know where your venv
is. If it guessed a path, it would overwrite a working local setup with a broken
generic one — which is exactly the bug that shipped once. The installer's
template therefore only fills in MCP servers you do not already have, and never
overwrites a definition you have set up.

---

## Something else went wrong

If the installer crashed without an `[E_...]` code, it is a bug. Get the details:

```powershell
$ErrorActionPreference = 'Continue'
./install.ps1 --all 2>&1 | Tee-Object install.log
```

Please [open an issue](https://github.com/Sachitt-AV-08/agent-bootstrap/issues)
with the log attached. Note that the log may contain your home directory path —
review it before posting.

---

## Verify your install

```powershell
doctor
```

A healthy install reports:

- OpenCode v2.x
- your config present and non-empty
- agents present (you should have 163)
- 6 skill packs
- MCP servers connected (or a clear note for any that need auth)

To confirm the agent count and modes directly:

```powershell
$cfg = (opencode debug config | ConvertFrom-Json)[0].info
$cfg.agents.PSObject.Properties |
  Group-Object { $_.Value.mode } |
  Select-Object Name, Count
```

You want every agent at `mode = subagent`. If they show as `primary`, they will
all appear in your Tab / Shift+Tab cycle — see
[keyboard-shortcuts.md](../reference/keyboard-shortcuts.md).
