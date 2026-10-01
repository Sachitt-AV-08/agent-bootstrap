---
description: Multi-agent review of the current changes — dedupe findings, rank by severity
agent: reviewer
---
Review the current changes for `$ARGUMENTS` (optional scope; defaults to the whole diff).

Procedure:
1. Establish what changed: `git status`, `git diff --stat`, and `git diff` against the base
   branch. If the diff is large, group by area and review each area deliberately.
2. Spawn 3–5 `reviewer` subagents in parallel, each with a distinct lens so their findings
   differ instead of repeating:
   - **correctness** — logic errors, off-by-one, null/undefined, error paths, concurrency
   - **security** — injection, authz/authn gaps, secret handling, unsafe deserialization, SSRF
   - **tests** — missing coverage, tests that assert nothing, flaky timing, weak assertions
   - **design** — duplication, leaky abstractions, wrong boundaries, naming, dead code
   - **operability** — logging, error messages, config handling, rollback safety
   Give each reviewer the same diff but only its own lens.
3. Collect all findings and **dedupe by (file, line, root cause)** — not by wording. Keep
   the most severe rating and the clearest evidence across duplicates.
4. Rank by severity: critical (data loss, security hole, broken build) → major (wrong
   behaviour, unhandled error) → minor (clarity, style, duplication).
5. Verify before reporting: for every critical and major finding, confirm it in the actual
   code. Drop any finding you cannot demonstrate — a false positive costs more trust than
   a missed nit.
6. Report:
   - **Findings** table: severity | file:line | issue | why it matters | lens
   - **Verified by reading** — the ones you confirmed, with the line
   - **Rejected** — plausible findings you checked and dismissed, with the reason
   - **Coverage** — which lenses ran, and what was not reviewed

Rules: no edits — you are read-only here; report precisely instead. Do not pad the list.
If the change is fine, say so plainly and name what you checked.