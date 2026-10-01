---
description: Execute PLAN.md — parallel coders per independent phase, gates between dependent phases
agent: parallel-executor
---
Execute the plan in `PLAN.md` for `$ARGUMENTS` (or the plan file the user names).

Procedure:
1. Read `PLAN.md`. If it is missing, stop and say: run `/plan-feature <description>` first.
   If it has no verify gate for a phase, stop — a phase without a gate cannot be executed safely.
2. Build the dependency graph from each phase's `parallel:` marker. Identify the critical path.
3. **Gate wave 0:** run the first phase's verify command on the clean tree. If the baseline
   is already failing, stop and report that — do not build on a broken baseline.
4. For each wave of independent phases, spawn one `coder` subagent per phase with:
   - the worktree path (use `.lane/trees/<phase>-<n>/`, or the current tree for a single phase)
   - the phase's exact scope (the files it owns, and the files it must not touch)
   - the phase's change description, copied verbatim from the plan
   - the verify command it must make pass, and the requirement to paste the real output
   - the instruction to commit its own work in that worktree
   All phases in a wave run in parallel; the waves run in order.
5. **Between waves:** collect each phase's diff, check for scope violations (an agent that
   touched files outside its scope is a failure, not a nit), and run the wave's verify gates.
   If a gate fails, do not start the next wave — report which phase broke it and what the
   output said.
6. After the final wave: run the full test suite and the plan's "Done criteria" checklist,
   item by item, with evidence for each item.
7. Report: phase table (status, files, commits, verify output), scope violations, unmet
   done criteria, and the next command (`/review-all`, then `/test-all`, then `/open-pr`).

Rules: never mark a gate passed without having run it; never widen a phase's scope to
unstick a failure without saying so; never let two agents in the same wave touch the same
file; on repeated failure of the same phase, stop and bring the evidence to the user
instead of trying a third variation.