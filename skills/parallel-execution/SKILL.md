---
name: parallel-execution
description: Use when work splits into independent pieces that can run at the same time - running several subagents in one turn, splitting file ownership, and collecting results without merge conflicts.
---

# Parallel execution

Independent work runs concurrently. Dependent work runs in order. Getting this
backwards is the most common way a fleet wastes tokens and produces conflicts.

## Decide first: parallel or sequential?

Ask one question: **can two agents finish without seeing each other's output?**

| Situation | Run |
|---|---|
| Two files, no shared interface | parallel |
| Caller and callee in the same change | sequential |
| A test depends on the code it tests | sequential |
| Same file, different regions | parallel but one file — assign one owner |
| Research three unrelated libraries | parallel |

If you cannot state what each agent owns, do not parallelize. Do it sequentially
and be correct.

## Spawning

Use the `subagent` tool. Several calls in **one turn** run concurrently; calls in
separate turns run one after another. That distinction is the whole mechanism.

```
subagent { agent: "coder", prompt: "<worktree>, <task>, <files you own>, <files you must not touch>, <verify command>, report back as: summary + files changed + verify output" }
subagent { agent: "coder", prompt: "<different worktree>, <different task>, <disjoint files> ..." }
subagent { agent: "reviewer", prompt: "<lens>, <diff>" }
```

Rules that keep parallel runs clean:

- **One owner per file.** List the owned files in the prompt. Repeat "you must not
  touch X" explicitly — agents do not infer it.
- **One worktree per agent** for anything that writes. See `worktree-manager`.
- **Give the verify command.** An agent that cannot verify its own work guesses.
- **Require evidence.** Ask for the real command output, not "tests pass".
- **Cap the batch.** 8 concurrent agents is the practical local ceiling. Past that,
  memory pressure turns agents slow and flaky.

## Collecting

Every `subagent` call returns a `sessionID`. Keep it — you need it to continue an
agent, ask a follow-up, or recover its result.

When results come back:

1. Compare each agent's claimed files against `git status` in its worktree. Trust the
   diff, not the summary.
2. Find scope violations first. An agent that edited outside its ownership is a
   failure even if its work is good.
3. Dedupe findings by `(file, line, root cause)` — not by wording. Five agents
   reporting the same bug is one bug.
4. Merge independent work first, then anything that depends on it. Run tests between
   merges.
5. Never discard an agent's work silently. Either merge it or say why you did not.

## Failure handling

- **Agent failed / no result**: continue its session with the same `sessionID` and
  ask what happened. Do not silently re-spawn — you may get a different answer twice.
- **Two agents conflicted**: stop merging. Show both diffs and let a human decide.
- **Everything is blocked on one question**: collect the questions, ask the user once
  with all of them, rather than stalling N agents on N separate prompts.
- **Context too large to finish**: split the scope by file and re-fleet. Do not let
  agents read each other's work to stay in sync — that is what worktrees prevent.

## Anti-patterns

- Spawning sequentially in separate turns and calling it a fleet.
- Letting agents read each other's branches to "stay consistent".
- Asking one agent to do everything "in parallel" internally.
- Collecting without checking `git status` in each worktree.
- Merging all results before running the test suite.
