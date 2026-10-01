# agent-bootstrap

**One command turns any machine into a 10/10 AI agent environment.**

Free-tier only. Local-first. No cloud dependency. MIT.

```powershell
# Windows
pwsh -c "irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex"
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.sh | bash
```

Prefer to be asked? You get three plain-language questions instead of a flag
list. Press Enter to accept each recommendation.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1))) --interactive
```

The extra wrapping is not decoration: `Invoke-Expression` cannot take arguments,
so there is no `iex -args`. `& ([scriptblock]::Create(...))` attaches them
properly. The one-liner above needs no flags, which is why it stays short.

Not sure yet? Preview first — `--dry-run` changes nothing.

```bash
git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git
cd agent-bootstrap
./install.ps1 --dry-run      # see the plan
./install.ps1                # or just go
```

Windows only, and you see *"running scripts is disabled on this system"*? Use
the `irm | iex` one-liner above, or
`pwsh -ExecutionPolicy Bypass -File .\install.ps1`. See the
[Windows guide](docs/guides/windows-install.md).

macOS and Linux run the same installer as Windows. `install.sh` bootstraps
PowerShell 7 and then executes `install.ps1`, so all three platforms get
identical agents, error messages and tests from one implementation.

---

## What you get

| Piece | Count | What it is |
|---|---|---|
| **Agent definitions** | **163** | Role-scoped subagents across 20 domains |
| **Commands** | 10 | Fleet orchestration + the plan→PR pipeline |
| **Skill packs** | 6 | Parallel execution, plan-to-pr, worktrees, review |
| **MCP servers** | 6 | context7, browser-use, vision + your own projects |
| **Helper scripts** | 7 | doctor, verify, project scaffolding |

Nothing is a black box. Agents are plain YAML you can read in four lines. Commands are
plain Markdown. If you do not like an agent, delete its file.

---

## The pipeline

```
/plan-feature "add OAuth2 login"   →  PLAN.md with phases, gates, rollback
        ↓
/exec-plan                         →  parallel coders, one worktree per phase
        ↓
/review-all                        →  3–5 reviewers, different lenses each
        ↓
/test-all                          →  tests that provably fail without the fix
        ↓
/open-pr                           →  green checks required, honest description
```

Fleet commands sit alongside it:

```
/fleet-spawn reviewer 3 audit the auth module
/fleet-status
/fleet-collect
```

---

## Agent domains

| Domain | Count | Examples |
|---|--:|---|
| core | 8 | planner, coder, reviewer, tester, pr-creator, architect |
| meta | 6 | fleet-commander, result-aggregator, conflict-resolver |
| orchestration | 10 | subagent-spawner, worktree-manager, parallel-executor |
| debugging | 20 | log-correlator, git-bisect-orchestrator, postmortem-drafter |
| content | 22 | video-script-writer, subtitle-burner, platform-optimizer |
| research | 20 | paper-fetcher, gap-analyzer, competitor-monitor |
| web-scraping | 16 | yt-dlp-extractor, robots-checker, scrapy-crawler |
| social-media | 18 | linkedin-post-publisher, instagram-reel-uploader |
| memory | 12 | mem0-store, chromadb-upsert, memory-consolidator |
| docs-dx | 13 | tech-writer, readme-generator, seo-content-optimizer |
| security | 0+ | see `agents/security/` |
| projects | 18 | orvima, parley, genesis toolchains |

Agents marked read-only carry an explicit `edit "*" → deny` rule. Agents that touch
real accounts (LinkedIn, Instagram, WhatsApp) require per-action approval in the
current turn — they will draft, never silently send.

---

## Install options

```bash
./install.ps1                        # everything (the default)
./install.ps1 --interactive          # be asked what to install
./install.ps1 --minimal              # core only, no Python deps
./install.ps1 --domains debugging,research
./install.ps1 --with orvima,parley,genesis
./install.ps1 --dry-run              # show the plan, write nothing
./install.ps1 --self-test            # check the installer itself works
./install.ps1 --help                 # every flag
```

Every flag spelling works: `-dry-run`, `--dry-run` and `-SkipDeps` are the same
flag, and `--domains=a,b` and `--domains a,b` are equivalent. An unrecognised
flag is an error rather than a warning, so a typo can never quietly install less
than you asked for.

`--dry-run` is the safe way to preview. Your existing `~/.config/opencode` is
backed up to `opencode-backup-<timestamp>` before anything is written, and the
rollback path is printed at the end.

---

## When something goes wrong

Every installer error carries a code, and every code is explained in
[docs/guides/troubleshooting.md](docs/guides/troubleshooting.md):

```
  [E_NO_PYTHON]
  What happened:  Python is not installed, but these domains need Python packages.
  Why it matters: Agents will be installed but will fail when they run.
  What to do:     winget install Python.Python.3.12
```

Two commands that are safe to run at any time:

```bash
./install.ps1 --self-test    # 58 checks on the installer's own code
doctor                        # health check of your installed setup
```

Neither touches your configuration.

---

## Verify

```bash
doctor            # health check: opencode, config, agents, MCPs, deps
doctor -Json      # machine-readable
```

---

## Design rules

These are not suggestions; the agent YAML encodes them.

1. **One owner per file.** Parallel agents get disjoint file scopes, always.
2. **A gate is not passed until you ran it.** "Should work" is not a result.
3. **Dedupe by root cause, not wording.** Five agents on one bug is one bug.
4. **Verify before reporting.** Unverified findings go in a separate list or get cut.
5. **Ask before anything outward-facing.** Sending, posting, publishing, deleting.
6. **Never store or print secrets.** `.env` reads are denied in the global config.
7. **Respect scraping boundaries.** robots.txt, rate limits, real user agents. No
   CAPTCHA bypass, no paywall bypass, fail closed when robots.txt is unreachable.

---

## Layout

```
install.ps1 / install.sh     installers
config/                      opencode.jsonc template, tui.json, AGENTS.md
agents/<domain>/*.yaml       163 agent definitions (source of truth)
commands/*.md                10 commands
skills/*/SKILL.md            skill packs
mcp/*.json                   MCP server definitions
scripts/                     doctor, verify, new-project
debugging-repo/              standalone incident workspace
projects/                    overlays for orvima / parley / genesis
docs/                        quickstart, agent registry, customisation
```

`config/opencode.jsonc` is a **template**. The `agents` block is generated from the
YAML at install time — edit the YAML, never the generated block.

---

## Contributing

Add an agent as one YAML file with a name, description, system prompt, and explicit
permissions. Read-only is the default; grant write access deliberately and narrowly.
Run `./install.ps1 --dry-run` and `doctor` before opening a PR.

## License

MIT
