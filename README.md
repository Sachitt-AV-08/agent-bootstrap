# agent-bootstrap

**One command turns any machine into a fully-loaded AI agent environment.**

Free-tier only. Local-first. No cloud dependency. MIT.

```powershell
# Windows
irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.sh | bash
```

---

## Setup guide

### 1. Install

Run one of the commands at the top of this file. That's it.

The installer downloads itself, clones this repo to `~/.local/share/agent-bootstrap`,
and wires everything into your OpenCode config. Your existing config is backed up
first, and the rollback command is printed when it finishes.

****Requirements:** PowerShell 7 on Windows (`install.sh` installs it for you on
macOS/Linux), Node, Python 3.10+. Everything else is installed for you.

### Not sure what you want? Be asked

Instead of the full 163-agent install, get three plain-language questions — what
to install, which extra MCPs, which models. Press Enter to accept a
recommendation.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1))) --interactive
```

The wrapping is not decoration: `Invoke-Expression` cannot take arguments, so
there is no `iex -args`. `& ([scriptblock]::Create(...))` attaches them properly.
The one-liners above need no flags, which is why they stay short.

### 2. Open a new terminal

Config is only read at startup, so a terminal you already have open will not see
the new agents.

### 3. Start OpenCode

```bash
opencode
```

Type `/` to see the commands. Press `Shift+Tab` to cycle agents — you get exactly
`build` and `plan`. That is not a keybind restriction: every one of the 163
installed agents is `mode: subagent` and **none** is `primary`, so OpenCode's
agent cycle only ever contains its own two builtins. Subagents are chosen
automatically per task, which is the whole point.

### 4. Check it worked

```bash
doctor                    # health check of your installed setup
./install.ps1 --self-test # 76 checks on the installer itself
```

A healthy setup looks like this:

```
OK    opencode           opencode v2.0.20
OK    config             198.3 KB - 163 agents, 4 MCPs
OK    mcp:browser-use    connected
OK    mcp:context7       connected
OK    mcp:vision         connected
OK    mcp:openviking     connected
OK    python-deps        scraping + memory + playback deps present
```

---

## What you get

| Piece | Count |
|---|---|
| AI agents (all subagents, all auto-selected) | **163** |
| Slash commands | 10 |
| Skill packs | 6 |
| MCP server definitions | 6 |
| Helper scripts | 5 |

Every agent is `mode: subagent` with a `description`, so OpenCode picks the
right one per task on its own. You are never asked to choose.

---

## The 163 agents, by domain

163 agents live in 11 populated directories. The names do not always match the
directory — `tester` lives in `core`, `api-documenter` in `docs-dx` — so this is
what is actually on disk:

| Domain | Count | What they do |
|---|--:|---|
| **content** | 22 | video scripts, subtitles, thumbnails, blog posts, social copy |
| **debugging** | 20 | log correlation, bisecting, postmortems, flaky tests, race and leak hunts |
| **research** | 20 | paper fetching, citation mapping, prior-art search, trend spotting |
| **social-media** | 18 | LinkedIn/Instagram/WhatsApp drafting, analytics, scheduling |
| **projects** | 18 | toolchains for orvima, parley, genesis |
| **web-scraping** | 16 | yt-dlp, robots.txt checks, Scrapy crawls, dynamic scraping |
| **docs-dx** | 13 | tech writing, READMEs, changelogs, SEO, glossaries |
| **memory** | 12 | mem0, ChromaDB, Qdrant, FAISS stores and searchers |
| **orchestration** | 10 | subagent spawning, worktrees, parallel execution, gates |
| **core** | 8 | planner, coder, reviewer, tester, architect, pr-creator, release-manager, incident-commander |
| **meta** | 6 | fleet command, result aggregation, conflict resolution, consensus |

**Nine directories are empty placeholders** — `api`, `backend-infra`, `data-ml`,
`frontend`, `migration`, `performance`, `security`, `specialty`, `testing`. They
are reserved so `--domains testing` is a valid flag today, but they contain no
agents. The installer reports 163 because 163 is what exists.

---

## The 10 commands

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

Plus fleet orchestration, refactoring, and test generation:

```
/fleet-spawn reviewer 3 audit the auth module
/fleet-status
/fleet-collect
/refactor <scope>
/generate-tests <scope>
```

---

## The 6 skill packs

Skills are procedures the agent loads on demand, rather than agents it dispatches.

| Pack | What it covers |
|---|---|
| `parallel-execution` | running independent work concurrently, splitting by file ownership |
| `plan-to-pr` | the full phased pipeline with verify gates |
| `fleet-orchestration` | many agents, many worktrees, one collector |
| `worktree-manager` | git worktree lifecycle for isolated agent runs |
| `multi-agent-review` | deduplicating overlapping findings, ranking by severity |
| `code-gen` | implementing from a plan without losing the plot |

---

## The MCP servers

Six definitions ship in `mcp/`. **Three are registered automatically**; the
project ones are opt-in because they only make sense if you have those projects.

| Server | Registered | What it does |
|---|:--:|---|
| **context7** | auto | Current library docs and runnable examples for any framework |
| **browser-use** | auto | Real browser control over CDP — click, type, scrape JS-rendered pages |
| **vision** | auto | Image understanding and OCR, including images pasted straight into chat |
| **openviking** | auto | Context database: knowledge, memory and skills as a browsable `viking://` tree |
| **orvima** | `--with orvima` | Browser session attached to your already-running browser |
| **parley** | `--with parley` | WhatsApp Desktop session management |
| **genesis** | `--with genesis` | Video render pipeline |

```bash
./install.ps1 --with orvima,parley,genesis
```

**Your own MCP definitions always win.** The installer only fills gaps — if you
already have a `context7` block with a custom path, yours is kept untouched and
you are told which one was overridden.

`openviking` needs a running server. After installing, run
`openviking-server init` once to write `~/.openviking/ov.conf`, then start
`openviking-server`. If it is not running, doctor reports it as disabled rather
than as a failure.

---

## Install options

```bash
./install.ps1                        # everything (the default)
./install.ps1 --interactive          # be asked what to install
./install.ps1 --minimal              # core only, no Python deps
./install.ps1 --domains debugging,research
./install.ps1 --with orvima,parley,genesis
./install.ps1 --dry-run              # show the plan, write nothing
./install.ps1 --self-test            # 76 checks on the installer itself
./install.ps1 --help                 # every flag
```

Interactive mode asks three questions in plain language — what to install, which
extra MCPs, which models — and pressing Enter takes the recommendation.

Every flag spelling works: `-dry-run`, `--dry-run` and `-SkipDeps` are the same
flag, and `--domains=a,b` equals `--domains a,b`. An unrecognised flag is a hard
error, so a typo can never quietly install less than you asked for.

---

## What the installer does

```
[1] Source           fetch the agent files
[2] System deps      ffmpeg via winget / brew / apt / dnf / pacman
[3] OpenCode         @opencode/cli@2.0.20 if not already present
[4] Python deps      browser-use virtualenv + per-domain packages
[5] Backup           ~/.config/opencode → opencode-backup-<timestamp>
[6] Config write     merge 163 agents, keep your tui.json and MCPs
[7] Commands/skills  copy commands and skill packs
[8] Helper scripts   install to ~/.local/bin
[9] MCP register     template MCPs + any --with projects
[10] Verify          confirm agents, MCPs and dependencies
```

A run that produces zero agents fails loudly and exits non-zero, instead of
printing "Ready" and leaving you to find out later that nothing was installed.

---

## If something goes wrong

Every error carries a code, and every code is explained in
[docs/guides/troubleshooting.md](docs/guides/troubleshooting.md):

```
[E_NO_PYTHON]
  What happened:  Python is not installed, but these domains need Python packages.
  Why it matters: Agents will be installed but will fail when they run.
  What to do:     winget install Python.Python.3.12
```

Rollback is always one command, printed at the end of every install:

```powershell
Copy-Item -Recurse -Force "$HOME/.config/opencode-backup-<timestamp>/*" "$HOME/.config/opencode/"
```

On Windows, if you see *"running scripts is disabled on this system"*, use the
one-liner at the top of this file — it does not touch execution policy — or see
the [Windows guide](docs/guides/windows-install.md).

---

## Design rules

Encoded in the agent YAML, not just documented:

1. **One owner per file.** Parallel agents get disjoint file scopes, always.
2. **A gate is not passed until you ran it.** "Should work" is not a result.
3. **Dedupe by root cause, not wording.** Five agents on one bug is one bug.
4. **Verify before reporting.** Unverified findings get cut or listed separately.
5. **Ask before anything outward-facing.** Sending, posting, publishing, deleting.
6. **Never store or print secrets.**
7. **Respect scraping boundaries.** robots.txt, rate limits, real user agents. No
   CAPTCHA bypass, no paywall bypass, fail closed when robots.txt is unreachable.

Agents that touch real accounts (LinkedIn, Instagram, WhatsApp) require per-action
approval. They draft; they do not send.

---

## Repo layout

```
install.ps1 / install.sh     installers — the .ps1 is authoritative, .sh bootstraps it
config/
  opencode.jsonc             template; agents/MCP blocks are filled in at install time
  tui.json                   Tokyo Night theme, agent-cycle keybinds
  AGENTS.md                  agent reference for the model
agents/<domain>/*.yaml       163 agent definitions — the source of truth
commands/*.md                10 commands
skills/<pack>/SKILL.md       6 skill packs
mcp/*.json                   6 MCP server definitions
scripts/                     doctor, verify, new-project, selftest
projects/                    overlays for orvima / parley / genesis
docs/                        quickstart, agent registry, customisation, troubleshooting
```

`config/opencode.jsonc` is a **template**. Its `agents` block is generated from
the YAML at install time — edit the YAML, never the generated block.

---

## Contributing

An agent is one YAML file: a name, a description, a system prompt, and explicit
permissions. Read-only is the default; grant write access deliberately and
narrowly.

```bash
./install.ps1 --self-test   # 76 checks
./install.ps1 --dry-run     # preview
doctor                      # verify the installed result
```

## License

MIT
