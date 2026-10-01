---
description: Merge finished fleet results, dedupe findings, prune worktrees
agent: fleet-collector
---
Collect results from the fleet for `$ARGUMENTS` (fleet name or empty for all).

Procedure:
1. Gather evidence from every worktree under `.lane/trees/`: `git log --oneline`,
   `git diff --stat` against the base branch, and each agent's final summary
   (continue its session with `subagent` + `sessionID` if you need more than the summary).
2. **Dedupe findings.** The same issue is usually reported by several agents. Merge by
   (file, line, root cause) — not by wording. Keep the most severe rating and the clearest
   evidence.
3. **Conflict detection.** If two agents changed the same file, flag it as a conflict and
   show both diffs. Never silently take one side. Resolve only when the change is trivially
   non-overlapping, and say so explicitly when you do.
4. Merge in dependency order: independent agents first, then agents that depend on their
   output. Run the project's test suite between merges when one exists, and stop on failure.
5. Produce the report:
   - **Findings** table: severity | file:line | issue | found-by | status
   - **Merged** list: agent → branch → files → tests passing
   - **Conflicts** needing a human decision
   - **Rejected** (duplicate or out-of-scope) with a one-line reason
6. **Prune** worktrees for agents whose changes are merged and whose tests pass
   (`git worktree remove`). Never prune a worktree with unmerged or failing work —
   list those instead and say they are kept.
7. Suggest the next step: `/review-all` for a second pass, `/test-all` if coverage is thin,
   or `/open-pr` when the tree is green.

Never force-push, never discard an agent's work, and never delete a branch you did not
confirm. If anything is ambiguous, leave it in place and say so.