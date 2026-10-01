# agent-bootstrap

**One command turns any machine into a 10/10 AI agent environment.**

Free-tier only. Local-first. No cloud dependency. MIT.

```powershell
# Windows
pwsh -c "irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex"

# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.sh | bash
```

From a clone:

```bash
git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git
cd agent-bootstrap
./install.ps1 --all --with orvima,parley,genesis
```

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
./install.ps1 --all                      # everything
./install.ps1 --minimal                  # core only, no Python deps
./install.ps1 --domains debugging,research
./install.ps1 --with orvima,parley,genesis
./install.ps1 --dry-run                  # show the plan, write nothing
```

`--dry-run` is the safe way to preview. Your existing `~/.config/opencode` is
backed up to `opencode-backup-<timestamp>` before anything is written, and the
rollback path is printed at the end.

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
