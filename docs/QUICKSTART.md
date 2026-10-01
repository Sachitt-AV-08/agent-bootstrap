# Quickstart

## 1. Install

```powershell
# Windows
pwsh -c "irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex"
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.sh | bash
```

Not sure which parts you want? Let it ask you:

```powershell
irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex -args --interactive
```

Preview first if you like — this changes nothing:

```powershell
./install.ps1 --dry-run
```

## 2. Verify

```bash
doctor
```

Healthy output looks like:

```
OK    opencode           opencode v2.0.20
OK    config             198.3 KB - 163 agents, 4 MCPs, 5 permission rules
OK    model              kilo/kilo-auto/free
OK    worktrees          .lane/trees
OK    commands           13 file(s)
OK    skills             50 pack(s), 48 with SKILL.md
OK    python-deps        scraping + memory + playback deps present
OK    mcp:browser-use    connected
OK    mcp:context7       connected
OK    mcp:vision         connected
```

Warnings are fine. `FAIL` lines are not.

## 3. Start

```bash
opencode
```

The TUI opens with the tokyonight theme. Ask *"what agents do you have?"* or run
`/help`.

## 4. First real task

Plan something small:

```
/plan-feature "add a /health endpoint that reports uptime"
```

Read `PLAN.md`. If the phases or gates look wrong, fix them before executing.

```
/exec-plan
/review-all
/test-all
/open-pr
```

## 5. Run a fleet

```
/fleet-spawn reviewer 3 audit the auth module
/fleet-status
/fleet-collect
```

Three reviewers, three worktrees, three lenses. `/fleet-collect` merges what is
verified and tells you what it kept.

---

## Adding your own agent

One file. Four fields. Nothing generated:

```yaml
# agents/core/my-agent.yaml
name: my-agent
domain: core
description: Review database migrations for lock and rollback risk.
mode: subagent
system: |
  You review database migrations for lock duration, rollback safety, and index
  impact. Quote the migration file and line for every finding. Never edit files.
permissions:
  - action: edit
    resource: "*"
    effect: deny
```

Re-run the installer to regenerate the config block. `doctor` confirms the count went up.

## Adding an MCP

```bash
opencode mcp add my-server --global --url https://example.com/mcp
# or a local stdio server:
opencode mcp add my-server --global -- npx -y some-mcp-server
```

OAuth servers show `needs authentication` until you run `/mcps` in the TUI and sign in.

## Troubleshooting

The installer prints a code like `[E_NO_PYTHON]` when it stops. Every code is
explained, with the exact command to fix it, in
[guides/troubleshooting.md](guides/troubleshooting.md).

| Symptom | Cause | Fix |
|---|---|---|
| `opencode: command not found` | npm global bin not on PATH | Reinstall Node, or add the npm global bin to PATH and open a new shell |
| `running scripts is disabled` (Windows) | PowerShell execution policy | Use the `irm \| iex` one-liner, or `pwsh -ExecutionPolicy Bypass -File .\install.ps1` |
| Config rejected as invalid | hand-edited the generated `agents` block | Restore from `opencode-backup-*`, or re-run the installer |
| Agents missing | installer not re-run after adding YAML | `./install.ps1 --all --skip-deps` |
| MCP shows `needs authentication` | OAuth not completed | `/mcps` in the TUI, select the server, sign in |
| MCP shows `Connection closed` (browser-use) | interpreter points at the wrong Python | See [MCP server will not start](guides/troubleshooting.md#mcp-server-will-not-start) |
| `doctor` reports missing Python packages | package name differs from import name | `python -m pip install newspaper3k mem0ai Pillow` |
| Worktrees fail | not a git repo | Worktrees need git; otherwise run agents sequentially |
| Paid model returns 402 | Kilo free-tier only | Use a `:free` model from `opencode models kilo` |
| Installer behaves oddly | an argument was ignored | Run `./install.ps1 --self-test`, then `--help` |

## Layout on your machine

```
~/.config/opencode/
  opencode.jsonc     generated config (agents inlined)
  tui.json           theme
  AGENTS.md          global instructions
  commands/          the 10 commands
  skills/            skill packs
  skills-src/        your own additions
~/.local/bin/        doctor, verify, new-project
```

Backups live next to the config as `opencode-backup-<timestamp>/`.
