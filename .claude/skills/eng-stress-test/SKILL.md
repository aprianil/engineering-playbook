---
name: eng-stress-test
description: Stress-test a spec or plan with fresh eyes. Challenges assumptions, surfaces risks, catches overengineering. Mandatory before /eng-build can start — appends a verdict heading to the spec that /eng-build checks for.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Bash
argument-hint: [spec-file]
---

Stress-test a spec or plan. You are a fresh pair of eyes — you did not write this and you have no attachment to its decisions. Catching issues here is far cheaper than catching them during or after building.

## Context modes

This skill runs in one of two modes depending on what context the caller provides:

**Fast mode (context provided inline).** When the caller passes the spec content, engineering principles, and codebase context directly in the prompt — use that. Do NOT re-read CLAUDE.md, the spec file, or explore the codebase. The caller already did the research. Go straight to challenging.

**Cold mode (file path only).** When invoked standalone with just a spec file path and no inline context:
- Read the project's CLAUDE.md for engineering principles and conventions.
- Read the spec file completely.
- Explore the codebase enough to challenge concretely — reference real files, real patterns, real constraints. Generic feedback ("have you considered error handling?") is useless.

**How to tell which mode you're in:** if your prompt contains the spec content and a "Context bundle" or equivalent section with file paths, code snippets, and principles — you're in fast mode. If you only have a file path to read — you're in cold mode.

**Challenge through the project's engineering principles:**

*Simplicity (Principle #1) — simple = readable, changeable, few things to think about*
- Is there a simpler approach that solves the same problem?
- Could anything be cut — not lines of code, but concepts, dependencies, or indirection?
- Can someone new read this and understand it without a guided tour?

*YAGNI (Principle #2)*
- Is anything being built for an imaginary future requirement?
- Is the spec adding complexity for scenarios that may never happen?

*Abstractions (Principle #3)*
- Are abstractions being designed upfront that should be discovered later?
- Is duplication being forced into a shared pattern prematurely?

*Quality (Principle #4) — never trade quality for speed*
- Are assumptions treated as verified facts? (API response shapes from docs but not tested, constraints described but not enforced, "we'll figure it out during build" on decisions that are cheaper to get right now)
- If shortcuts are proposed, are they scope cuts or quality cuts? Scope cuts are fine if documented. Quality cuts compound.
- Are any trade-offs being ignored or hidden?

*Reversibility (Principle #5) — Type 1 = hard to undo, Type 2 = easy to undo*
- Are any decisions hard to reverse? (Database schema, public API contracts, data migrations) Flag these explicitly.
- Are reversible decisions being over-planned? "Can I undo this next week?" If yes, move fast.

*Compounding (Principle #6)*
- Is the spec investing in things that compound, or front-loading one-time concerns?

*Verification (Principle #8) — every change needs a way to prove it works*
- Does the spec define how to verify the feature works? Tests, build checks, browser validation?
- Are there behaviors that would be hard to test or verify? Flag them.

*Ownership (Principle #9) — if you can't explain it, you can't maintain it*
- Is anything in the proposed approach so complex that the person building it won't understand why it's structured that way?
- Would this require deep framework knowledge that the team doesn't have?

*What good vs bad looks like*
- Does the proposed structure match the project's "good" column — thin routes, shared schemas, auth wrappers, feature-name mirroring, side effects after response, structured errors, wiring files with zero logic?
- Are there patterns from the "bad" column sneaking in?

*Spec coverage — can you trace each acceptance criterion to the proposed approach?*
- For each acceptance criterion, can you point to where in the file structure and approach it gets implemented?
- Are there criteria with no clear home? That's a gap in the plan.
- Are there files or components in the approach that don't map to any criterion? That's scope creep.

*Rationalization red flags*
- Scan for common rationalizations that hide bad decisions:
  - "We can always refactor later" / "It's just a prototype" / "We might need this someday" / "It's only a small addition" / "Everyone does it this way" / "We don't have time to do it right" / "It's too late to change"
- If the spec uses any of these (explicitly or implicitly), call it out. These aren't reasons, they're avoidance patterns.

*Edge cases that matter*
- What would hurt users or corrupt data if missed?
- What happens when external dependencies fail?
- Are there concurrency issues — race conditions, double submits, stale data?
- Would a developer building from this spec need to ask follow-up questions? Where?
- Security — does user input reach the database or UI without validation? Are new routes missing auth? Could secrets leak?

*First-of-kind detection*

Some patterns deserve extra scrutiny on first introduction because they're hard to retrofit. Grep to determine whether the spec is the first to introduce any of:
- A new agent skill (`skills/<name>/`) — verify SKILL.md frontmatter, role/tools/output contract, layering boundary
- A new agent tool (`tool({ ... })`) — verify load-bearing description, `rationale: z.string()` in inputSchema, naming convention
- A migration with a new pattern (`RETURNS TABLE`, RLS on a new table, partial unique index, NOT NULL backfill)
- A cron / scheduled workflow — verify cadence, overlap idempotency, failure alert
- A webhook handler — verify signature verification *before* body read
- A new MCP tool surface — verify inline spec-fetch, context-gap-shaped inputs, per-org rate limits

If first-of-kind, raise it in the verdict — even well-handled patterns deserve a "first-of-kind, extra eyes" flag so a reviewer reads the section with that frame.

**Prioritize ruthlessly.** Not every edge case is worth handling. Apply the same judgment as the playbook's trade-off muscle: handle what would hurt users, force a rewrite, or create security/data issues. Explicitly dismiss what's not worth the complexity — "this is a Type 2 concern, skip for now" is a valid call.

**What NOT to do:**
- Don't generate generic checklists. Only raise concerns specific to this feature.
- Don't suggest adding complexity for hypothetical scenarios. That violates the principles you're checking against.
- Don't challenge things that are clearly appropriate for the task size.
- Don't repeat what the spec already addresses well.

**Output:**

Append (or replace) a `## Stress-test verdict` section at the end of the spec with:

- One-line verdict on its own line: **ready to build** / **address these first** / **rethink approach**
- Prioritized list (3-7 items for most specs). Each item:
  - The concern (one line)
  - Why it matters (what breaks or what's expensive to fix later)
  - A specific question that would resolve it (not a fix — your job is to challenge, not to prescribe solutions)
- End with what the spec got right — one or two lines. Prevents the stress-test from being pure criticism
- Stress-test run timestamp + sub-agent context (fast/cold mode)

If you found nothing meaningful: "spec is solid, no concerns" is a valid verdict body.

The verdict heading is what `/eng-build` checks for as its precondition — no separate receipt file.
