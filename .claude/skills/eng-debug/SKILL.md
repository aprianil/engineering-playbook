---
name: eng-debug
description: Systematic debugging methodology for unexpected failures. Use when investigating a bug, reproducing an error, a failing test, or when a build breaks in a way that needs investigation. Forms 3-5 hypotheses, isolates the root cause with runtime evidence, and writes a guard test.
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
argument-hint: [optional: error message or description of what broke]
---

Systematically debug an unexpected failure. This skill exists because "something broke" is a different starting point than "build this feature" or "review this code." The methodology prevents the two most expensive debugging mistakes: guessing randomly, and fixing symptoms instead of root causes.

This skill owns the **workflow**: when to trigger, how to loop back to eng-build, when to hand off to eng-compound. For deeper methodology (common bug patterns, debugging tools, the hypothesis-driven mindset), see the project's Debugging Mindset deep dive if available.

**Before anything else:**
- Read the project's CLAUDE.md for conventions and known gotchas.
- If invoked from eng-build, you already have the build context. Don't re-read the spec or re-explore the codebase. Use what's in front of you.

## The debug loop

### 1. Stop and preserve evidence

Before touching anything, capture the current state:
- The exact error message or unexpected behavior
- The stack trace (if available)
- What changed right before this broke (your recent edits, a dependency update, environment change)
- The expected vs actual behavior

Don't skip this. Errors you "remember" drift from errors that actually happened.

### 2. Reproduce

Make the failure repeatable. Run the failing test, hit the broken endpoint, trigger the UI bug. If you can't reproduce it, you can't verify a fix.

Never propose a fix from code inspection alone. You need to see the failure happen, then see it stop. Code-only reasoning is where agents hallucinate confident wrong answers.

- If the error is intermittent, identify the conditions that make it more likely (concurrency, specific input, timing)
- Reduce to the smallest reproduction case you can

### 3. Localize

Narrow down where the failure originates. Work from the error backward, not from the code forward.

- Read the stack trace. The answer is usually in the first frame you own.
- If no stack trace, use binary search: comment out or bypass half the code path, see if it still breaks, narrow from there.
- Check what changed recently: `git diff` and `git log --oneline -5` are your friends.
- Don't read the entire codebase looking for clues. Follow the evidence.

### 4. Understand the root cause

This is the step people skip. You found where it breaks, now understand *why*.

- Generate 3-5 specific hypotheses before investigating any single one. Breadth prevents tunnel vision — the first plausible cause is often wrong.
- Test them in parallel when possible. One well-placed set of debug logs can confirm or reject several hypotheses in one reproduction run.
- Wrap temporary debug logs in `// #region debug log` / `// #endregion` markers (or the language equivalent). Cleanup becomes a grep-and-delete instead of a hunt.
- Common shapes to consider: logic error, wrong API assumption, race condition, stale dependency, environment drift.
- Would this have broken before your changes, or did your changes introduce it?
- Are there other places in the code with the same assumption that haven't broken yet?

If the root cause isn't clear after focused investigation, ask the user. Don't spiral.

### 5. Fix the root cause

Fix the actual problem, not the symptom. If a function returns null when it shouldn't, don't add a null check at the call site. Fix why it returns null.

- Keep the fix minimal. Don't refactor surrounding code while debugging.
- If the fix requires a design change that's bigger than the current task, flag it to the user and apply a minimal correct fix for now.
- If you added speculative code or guards while testing hypotheses that turned out to be wrong, revert them. Only changes backed by runtime evidence should survive. Debugging shouldn't leave the code more defensive than it started.

### 6. Guard against recurrence

Write a test that fails without your fix and passes with it. This is non-negotiable for anything that cost more than 5 minutes to debug.

- The test should encode the root cause, not just the symptom
- If the failure was in integration (two systems interacting), write an integration test, not a unit test that mocks away the interaction

### 7. Verify

Run the full relevant test suite, not just your new test. Confirm:
- The original error is gone
- Your fix doesn't break anything else
- The new guard test passes

## When auto-triggered from eng-build

eng-build shifts into eng-debug when it hits an unexpected error (not a typo or simple mistake, but something that requires investigation). The flow:

1. eng-build hits an error it can't resolve in one attempt
2. Shift into eng-debug methodology (this skill)
3. Run the debug loop
4. Fix and guard
5. If the finding was non-obvious (not just a typo or missing import), note it for eng-compound after the build ships
6. Resume eng-build from where it left off

Don't context-switch back and forth. Complete the debug loop before resuming the build.

## When to hand off to eng-compound

After fixing, ask: "Would a teammate's AI session benefit from knowing this before hitting the same problem?"

- **Yes** if: the root cause was non-obvious, the error message was misleading, the fix required understanding an undocumented behavior, or the same bug could easily recur in a different part of the codebase
- **No** if: it was a typo, a missing import, a straightforward logic error visible from the code

If yes, flag it to the user: "This was non-obvious. Worth running `/eng-compound` after the PR merges to capture it."

## What NOT to do

- Don't guess and check randomly. Each attempt should test a specific hypothesis.
- Don't add defensive code to suppress the error without understanding it.
- Don't expand scope. You're here to fix this bug, not improve the surrounding code.
- Don't skip the guard step because "it's obvious." If it were obvious, you wouldn't have needed to debug it.
- Don't debug for more than 20 minutes without updating the user on where you are and what you've tried.
- Don't use `setTimeout`, `sleep`, or artificial delays as a fix. They paper over race conditions without solving them. Use proper events, lifecycles, or reactivity — see the Race Conditions deep dive in the playbook.
