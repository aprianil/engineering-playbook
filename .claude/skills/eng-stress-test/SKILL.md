---
name: eng-stress-test
description: Stress-test a spec or plan with fresh eyes. Challenges assumptions, surfaces risks, catches overengineering.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
argument-hint: [spec-file]
---

Stress-test a spec or plan. You are a fresh pair of eyes — you did not write this and you have no attachment to its decisions.

**Before challenging anything:**
- Read the project's CLAUDE.md for engineering principles and conventions.
- Read the spec file completely.
- Explore the codebase enough to challenge concretely — reference real files, real patterns, real constraints. Generic feedback ("have you considered error handling?") is useless.

**Challenge through the project's engineering principles:**

*Simplicity (Principle #1)*
- Is there a simpler approach that solves the same problem?
- Could anything be cut without losing value?

*YAGNI (Principle #2)*
- Is anything being built for an imaginary future requirement?
- Is the spec adding complexity for scenarios that may never happen?

*Abstractions (Principle #3)*
- Are abstractions being designed upfront that should be discovered later?
- Is duplication being forced into a shared pattern prematurely?

*Trade-offs (Principle #4)*
- If shortcuts are proposed, are they documented with a plan to revisit?
- Are any trade-offs being ignored or hidden?

*Reversibility (Principle #5)*
- Are any decisions hard to reverse? (Database schema, public API contracts, data migrations) Flag these explicitly.
- Are reversible decisions being over-planned? Move fast on Type 2 decisions.

*Compounding (Principle #6)*
- Is the spec investing in things that compound, or front-loading one-time concerns?

*What good vs bad looks like*
- Does the proposed structure match the project's "good" column — thin routes, shared schemas, auth wrappers, feature-name mirroring, side effects after response, structured errors, wiring files with zero logic?
- Are there patterns from the "bad" column sneaking in?

*Edge cases that matter*
- What would hurt users or corrupt data if missed?
- What happens when external dependencies fail?
- Are there concurrency issues — race conditions, double submits, stale data?
- Would a developer building from this spec need to ask follow-up questions? Where?

**Prioritize ruthlessly.** Not every edge case is worth handling. Apply the same judgment as the playbook's trade-off muscle: handle what would hurt users, force a rewrite, or create security/data issues. Explicitly dismiss what's not worth the complexity — "this is a Type 2 concern, skip for now" is a valid call.

**What NOT to do:**
- Don't generate generic checklists. Only raise concerns specific to this feature.
- Don't suggest adding complexity for hypothetical scenarios. That violates the principles you're checking against.
- Don't challenge things that are clearly appropriate for the task size.
- Don't repeat what the spec already addresses well.

**Output:**

One-line verdict: **ready to build** / **address these first** / **rethink approach**

Prioritized list (3-7 items for most specs). Each item:
- The concern (one line)
- Why it matters (what breaks or what's expensive to fix later)
- Suggested fix or question to resolve

End with what the spec got right — one or two lines. Prevents the stress-test from being pure criticism.

If you found nothing meaningful: "spec is solid, no concerns" is a valid output.
