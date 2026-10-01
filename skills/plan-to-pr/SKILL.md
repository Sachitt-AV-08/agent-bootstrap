---
name: plan-to-pr
description: Use when turning a feature request into shipped work - writing PLAN.md with phased scopes and verify gates, executing phases in waves, and opening the PR.
---

# Plan to PR

Five commands, one pipeline: `/plan-feature` → `/exec-plan` → `/review-all` →
`/test-all` → `/open-pr`.

## 1. Plan (`/plan-feature`)

A plan is a file, not a promise. `PLAN.md` must contain, per phase:

- **Scope** — the exact files. `src/auth/session.ts`, not "the auth layer".
- **Change** — what concretely changes.
- **Verify** — the command that proves it, and what output proves it.
- **Rollback** — how to undo this phase alone.
- **Parallel** — which phases can run alongside it, which must wait.

No phase without a verify gate. Phases with overlapping file scope must be
sequential. The critical path gets called out by name.

## 2. Execute (`/exec-plan`)

Gate wave 0 on a clean tree first — if the baseline is already red you cannot tell
your breakage from the existing breakage.

Then run each wave of independent phases as concurrent subagents, one worktree each.
Between waves: collect diffs, check scope violations, run the wave's gates. A failed
gate stops the pipeline. Report it; do not proceed and hope.

## 3. Review (`/review-all`)

3–5 reviewers, each with a **different lens** — correctness, security, tests, design,
operability. Same diff, different question. Then dedupe by root cause and verify every
critical and major finding in the actual code before reporting it. An unverified
finding costs more trust than a missed nit.

## 4. Test (`/test-all`)

Test what changed and what it touches. Prefer a test that fails without the fix — prove
it by reverting the change mentally, or by actually running the new test against the
old code when that is cheap. Report coverage before and after, and name what is still
untested.

## 5. Ship (`/open-pr`)

Only when the tree is green:

- Run the CI-equivalent checks locally first.
- Title states the outcome, not the mechanism: "Fix token refresh race" beats "Update auth".
- Body: what changed, why, how it was verified, what was deliberately not done.
- Link the issue and the `PLAN.md` phase list.
- Never push a branch with failing tests or unreviewed scope violations.

## The rule that matters

A phase is done when its verify command passed **in that phase's worktree**, and you
have the output. "Should work" is not a gate result. If you did not run it, it is not
done — say so.
