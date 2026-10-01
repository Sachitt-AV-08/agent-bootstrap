---
name: multi-agent-review
description: Use when several agents reviewed the same change or codebase - deduplicating overlapping findings, ranking severity, and reporting only what was verified.
---

# Multi-agent review

Multiple reviewers on one diff is high recall and low precision. The value is in the
dedupe, not the volume.

## Run reviewers with different lenses

Same diff, one question each. Without distinct lenses you get the same finding five
times.

| Lens | Asks |
|---|---|
| correctness | Logic errors, null paths, error handling, concurrency, off-by-one |
| security | Injection, authz gaps, secret handling, SSRF, unsafe deserialization |
| tests | Missing coverage, assertions that assert nothing, flake, weak mocks |
| design | Duplication, leaky abstractions, wrong boundaries, dead code |
| operability | Logging, error messages, config handling, rollback safety |

## Dedupe by root cause

Merge on `(file, line, root cause)` — never on wording. Agents describe the same bug
in different vocabulary; surface-area proximity is a better key than phrasing.

Keep the **most severe** rating and the **clearest evidence** from the duplicates. Drop
the rest, but count them: "5 reviewers found this, deduped to 1" tells you how
important the coverage was.

## Rank by consequence

- **critical** — data loss, security hole, broken build, silent corruption
- **major** — wrong behaviour, unhandled failure path, missing validation
- **minor** — clarity, naming, duplication, style

Not "how confident you are". A certain nit is still a nit; an uncertain critical is
still worth reporting as unverified.

## Verify before reporting

For every critical and major finding: open the file, confirm the line, confirm the
behaviour. A finding you cannot demonstrate is a false positive — cut it, or move it
to an explicit "unverified, needs a second look" list. Never blend the two.

Dropping a false positive is free. Shipping one costs the reader's trust in every
other finding you reported.

## Report shape

```
Findings (verified)
| severity | file:line | issue | why it matters | lens | found-by |

Rejected
| file:line | claim | why it was dismissed |

Coverage
lenses run: correctness, security, tests
not reviewed: migrations, perf
```

Report "no findings" plainly when the code is clean, and name what you checked. A
review that invents something to look thorough is worse than no review.

## Loop it

After fixes, re-review the **fixes**, not the whole diff — unless the change was large
enough that the fix altered the design. Re-running all lenses on everything buries the
regression risk in noise.
