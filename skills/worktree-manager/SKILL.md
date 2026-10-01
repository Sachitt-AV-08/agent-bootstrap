---
name: worktree-manager
description: Use when running multiple agents that each write files - creating isolated git worktrees under .lane/trees, mapping agents to worktrees, and pruning safely.
---

# Worktree manager

One agent, one worktree. This is what makes parallel agents safe: each writes to its
own checkout of the same repo, so nothing overwrites anything.

Configured via `worktree.directory` in `opencode.json` (agent-bootstrap sets
`.lane/trees`).

## Create

```bash
# from the repo root
git worktree add .lane/trees/reviewer-1 -b fleet/reviewer-1
git worktree add .lane/trees/coder-1    -b fleet/coder-1
```

Name them `<agent-type>-<n>` so `git worktree list` is self-documenting. Branch as
`fleet/<agent-type>-<n>` so merges back to the base branch are obvious.

Not a git repo? Worktrees are unavailable. Say so and either run sequentially or have
agents work read-only. Do not fake isolation with copies.

## Map

Keep a table you can read at a glance:

| agent | worktree | branch | owns | sessionID |
|---|---|---|---|---|
| reviewer-1 | `.lane/trees/reviewer-1` | `fleet/reviewer-1` | (read-only) | `ses_...` |
| coder-1 | `.lane/trees/coder-1` | `fleet/coder-1` | `src/api/**` | `ses_...` |

The `sessionID` column is what lets you continue an agent after the fact.

## Inspect

```bash
git worktree list                       # every worktree and its branch
git -C .lane/trees/coder-1 status        # did it touch what it said?
git -C .lane/trees/coder-1 log --oneline # what did it actually commit?
```

Always inspect with `git`. An agent's summary is a claim; the worktree is evidence.

## Merge

Order matters: independent agents first, then agents that depend on their output.

```bash
git -C .lane/trees/coder-1 diff main...fleet/coder-1   # review the actual diff
# run tests, then:
git merge --no-ff fleet/coder-1
```

Run the test suite **between** merges, not once at the end. Ten merged branches with
one final test run means you cannot tell which merge broke things.

## Prune

```bash
git worktree remove .lane/trees/coder-1   # only after its work is merged
git branch -d fleet/coder-1               # only after the branch is merged
git worktree prune                         # clear stale administrative files
```

Never prune a worktree whose work is unmerged, failing, or unverified. List those
instead and say they are kept.

## Pitfalls

- `.lane/` must be gitignored — worktrees inside a tracked path confuse tooling.
- Never `git worktree remove --force` on a worktree with uncommitted work.
- Nested worktrees of the same repo are not supported; keep them flat under one dir.
- On Windows, keep paths short — deep `.lane/trees/<long-agent-name>` paths hit the
  260-character limit in some tools.
- Deleting the parent directory out from under git leaves stale entries; run
  `git worktree prune` afterwards.
