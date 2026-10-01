---
description: Open a PR from reviewed, tested work — green checks required, honest description
agent: pr-creator
---
Open a pull request for `$ARGUMENTS` (optional title hint).

Preconditions — verify each, do not assume:
1. Working tree is clean apart from the intended commits; nothing uncommitted or
   half-staged.
2. The branch is up to date with the base branch, or state clearly that it is behind.
3. Tests pass. Run them now. If they fail, stop — do not open the PR.
4. A review pass exists (`/review-all`) with no unresolved critical or major findings.
   If it has not run, say so and ask before continuing.
5. Tests exist for the new behaviour (`/test-all`), or the change is genuinely
   untestable (docs, config) — in which case say which.

Then:
6. Push the branch (`git push -u origin <branch>`). This triggers the permission ask;
   that is expected and correct. Never push to the base branch. Never force-push.
7. Compose the PR:
   - **Title** — the outcome, not the mechanism.
     "Fix token refresh race on concurrent requests" not "Update auth.ts".
   - **Body** — What changed, Why this way, How it was verified (paste the real test
     output, not a claim), What was deliberately not done, and any follow-ups.
   - Link the issue, and reference the `PLAN.md` phases this implements.
8. Open it:
   ```
   gh pr create --title "<title>" --body "<body>" --base <base>
   ```
   or, for multiple stacked branches, open them in dependency order and mark the
   later PRs as drafts until their base merges.
9. Report the PR URL, the checks that are pending, and the reviewers you would suggest.

Rules: never open a PR with failing tests. Never claim a check passed that you did not
run. Never include secrets, tokens, or `.env` content in the body. If the user asked
for a draft PR, create it as a draft. If preconditions fail, report which one and stop —
do not work around them.