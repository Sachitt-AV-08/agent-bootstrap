---
description: Turn a feature request into a phased plan with parallel phases and verify gates
agent: planner
---
Plan the feature described in `$ARGUMENTS`.

Before planning, establish the ground truth:
1. Read the repo's `AGENTS.md`, README, and build/test commands so the plan matches reality.
2. Find the real files involved. Name them. A plan that says "update the auth layer"
   instead of `src/auth/session.ts` is not finished.
3. Note the constraints that actually bind: existing patterns, public interfaces that
   other code depends on, migrations, feature flags, backwards compatibility.

Then write the plan to `PLAN.md` in the repo root (or the path the user names) with:

## Goal
One paragraph, in the user's terms. What is true when this is done?

## Constraints
Explicit non-goals, interfaces that must not break, and anything requiring approval.

## Phases
Each phase gets:
- **Scope** — the exact files owned by this phase
- **Change** — what actually changes, concretely
- **Verify** — the exact command that proves it works, and what output proves it
- **Rollback** — how to undo this phase alone
- **Parallel** — which other phases this one can run alongside, and which must wait

Order phases so that independent ones share a `parallel:` marker and dependent ones
come later. Call out the critical path explicitly.

## Risks
What could go wrong, how you would notice, and the mitigation.

## Done criteria
The exact checklist that must be true for this feature to be called complete.

Rules: no phase without a verify gate; no phase whose scope overlaps another phase's scope
(overlapping scopes must be sequential); prefer the smallest plan that actually works;
do not plan refactors the feature does not require — list them as follow-ups instead.
After writing, print a summary table: phase | files | parallel-with | verify command,
and end by telling the user the next command: `/exec-plan`.