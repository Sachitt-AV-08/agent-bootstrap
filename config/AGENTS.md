# Global agent instructions

Installed by `agent-bootstrap`. Edit freely — OpenCode hot-reloads this file
mid-session, so changes apply on your next prompt without a restart.

## Environment

- Windows 11 / macOS / Linux. Prefer cross-platform-safe commands.
- In this environment the shell is PowerShell 7 (`pwsh`): use full cmdlet names
  (`Get-ChildItem`, `Set-Content`) rather than aliases in scripts.
- Python 3.12 (`python`), Node 24, uv, git, gh, winget are available.
- Scratch/temp work: use a dedicated temp dir (e.g. `$env:TEMP/opencode`).

## How to work here

- **Skills first.** If a skill matches the task, load it before acting.
- **Fleet for parallel work.** Independent work goes to separate subagents via
  `subagent` (different files) or `/fleet-spawn` (different worktrees).
  Never run two agents that write the same file.
- **Plans are files.** Track multi-step work in a markdown plan, with a verify
  gate per phase. Keep the gates honest — a gate that was not run is not passing.
- **Verify before claiming done.** Run the command, show the output, then report.

## Hard rules

- **No video or rendering work** unless explicitly requested in the current message.
- Never print, log, or commit API keys (`.env`, `auth.json`, `auth.toml`).
- Only commit or push when explicitly asked. `git push` always asks first.
- Ask before any destructive or outward-facing action: deleting files, sending
  messages, posting to social platforms, publishing, or running against production.
- Prefer editing existing files over creating new ones. Match surrounding style.
- No gratuitous comments; only comment what the code cannot say for itself.

## Fleet conventions

- Worktrees live under `.lane/trees/<agent>-<task>/` (see the `worktree` config key).
- One agent per worktree. Merge with `/fleet-collect`, never by hand-copying files.
- Report fleet results as a table: agent, worktree, status, finding, next step.

## Provider notes

- Kilo gateway is **free-tier only** — paid model IDs return HTTP 402.
- If a model call 402s, swap to an explicit `:free` model from `opencode models kilo`.
