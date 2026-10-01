---
description: Show every running fleet, worktree, and agent session
agent: fleet-commander
---
Report fleet status for `$ARGUMENTS` (a fleet name, an agent type, or empty for all).

Produce a table with these columns:
fleet | agent type | count | worktrees | active sessions | phase | tokens so far | status

Then report, in this order:
1. **Blocked** — any agent waiting on a permission ask, a failed tool call, or a
   user decision. Name the agent and the exact decision needed.
2. **Finished** — agents that completed, with their one-line result.
3. **Working** — agents still running and what they are doing right now.
4. **Worktree footprint** — total disk used by `.lane/trees/`, and which worktrees are
   safe to prune.

For each finished agent, include its sessionID so it can be continued or collected.

If no fleet table exists yet, say that no fleet is running and print the command to
start one: `/fleet-spawn <agent> <count> <task>`. Do not invent status for agents you
cannot see evidence of — if you have to check, check with `git worktree list` and
`git log` rather than guessing.