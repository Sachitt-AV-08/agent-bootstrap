---
description: Spawn N agents of one type, each in its own worktree
agent: fleet-commander
---
Spawn a fleet from `$ARGUMENTS`.

Parse `$ARGUMENTS` as `<agent-type> <count> [task description]`. Example:
`/fleet-spawn reviewer 3 audit the auth module`

Procedure:
1. Validate the agent type exists (check the `agents` block in `~/.config/opencode/opencode.jsonc`,
   or `agents/<domain>/*.yaml` in the agent-bootstrap source). If it does not exist, list the
   closest matches and stop — do not invent an agent.
2. Confirm the task description is concrete enough to hand to a subagent. If `$ARGUMENTS`
   has no task text, ask for one before spawning anything.
3. Create one worktree per agent under `.lane/trees/<agent>-<n>/` (git worktree add).
   Skip worktrees if the workspace is not a git repo and say so.
4. Spawn each agent with the `subagent` tool: `agent: "<agent-type>"`, and a prompt that
   includes the worktree path, the task, the scope of files it owns, and the requirement
   to report back with a markdown summary ending in a status line.
5. Give each agent a disjoint file scope. Never let two agents write the same file.
6. Record every `sessionID` in a table so `/fleet-status` and `/fleet-collect` can find them:
   agent type, count, worktree path, task, sessionID, model, estimated cost.
7. Print the fleet table and the exact `/fleet-status` command to run next.

Rules: spawn agents in parallel (multiple `subagent` calls in one turn, not sequential
turns). Never spawn more than 8 at once locally — beyond that, say so and let the user
choose a smaller batch or use a cloud burst. Do not run agents that need file access to
the same path concurrently.