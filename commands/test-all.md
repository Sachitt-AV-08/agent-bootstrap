---
description: Test the current changes — write missing tests, prove they fail without the fix, report coverage gaps
agent: tester
---
Test the changes for `$ARGUMENTS` (optional scope; defaults to the whole diff).

1. **Establish the baseline.** Find the project's real test command and run it on the
   clean tree. If it already fails, stop and report that — you cannot attribute
   failures to the change on top of a broken baseline.
2. **Map the risk.** For each changed file, classify: pure refactor, new behaviour,
   bug fix, or interface change. New behaviour and bug fixes need new tests. Pure
   refactors need the existing suite to stay green — not new tests.
3. **Find what is untested.** Run coverage on the changed paths if the project supports
   it (`pytest --cov`, `go test -cover`, `npm test -- --coverage`). Report the delta
   before/after, not just the absolute number.
4. **Write the missing tests** with the `tester` agent (test files only — never source):
   - **bug fix** → a test that fails without the fix. Prove it: temporarily revert the
     fix, run the test, show it fail, restore. This is the only honest proof.
   - **new behaviour** → happy path, boundary values, and the error path.
   - **interface change** → a test that pins the new contract so callers cannot drift.
5. **Run everything.** Full suite, not just the new tests. Report pass/fail counts and
   the actual failing output if anything fails.
6. **Report:**
   - Coverage: before → after, per changed area
   - Tests added: file, what it pins, and (for fixes) proof it fails without the fix
   - Failing: the real output, and whether it is pre-existing
   - Still untested: what you deliberately did not cover and why

Rules: never modify source files to make a test pass — that is the bug, not the fix.
Never write an assertion that cannot fail. Never mark a suite green without having run
it. If the change is not testable in this repo (a docs change, a config change), say so
plainly instead of inventing coverage theatre.