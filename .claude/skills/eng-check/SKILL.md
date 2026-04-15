---
name: eng-check
description: Review code against engineering principles before shipping. Use when asked to review code, audit a diff, check a change against project conventions, or determine if something is ready to ship. Spawns architecture and correctness sub-agents in parallel so the reviewer has no build-session bias.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, Agent
---

Review code against the project's engineering principles. This spawns a sub-agent with fresh context -- the builder shouldn't review their own work (Principle #7).

**How it works:**

1. Read the project's CLAUDE.md for conventions and principles.
2. Get the changed files: detect the base branch, then `git diff $(git merge-base <base> HEAD) --name-only`.
3. Read the actual content of changed files (use `git diff` for the full diff).
4. If a spec exists in `specs/` for this feature, read it.
5. Spawn two sub-agents in parallel. **Pass context directly** -- don't make them re-read CLAUDE.md or re-explore the codebase. Each sub-agent prompt should include:
   - The CLAUDE.md sections relevant to their review focus (inline, not a file path)
   - The full diff of changed files (inline)
   - The acceptance criteria from the spec (not the full spec -- the reviewer doesn't need exploration history or research findings)
   - The list of changed file paths
   - **Architecture reviewer** -- gets the Principles, Feature structure, Structure & naming, and Spec alignment sections below. Focuses on design, patterns, and structure.
   - **Correctness reviewer** -- gets the Correctness, Performance, Tests, and Comments & PR hygiene sections below. Focuses on bugs, edge cases, security, and testing.
6. Merge findings into a single report. Deduplicate if both flagged the same issue.

---

**Review instructions for sub-agent:**

You are reviewing code with fresh eyes. You did not write this code.

The CLAUDE.md principles and the full diff have been provided to you inline. Use them as your source of truth.

**Read the diff deeply first.** Don't skim the diff to go exploring. Read every changed function, understand what it does, how it handles errors, what it assumes. Form your assessment from the diff. This is where most of your findings should come from.

**Explore with purpose, not speculatively.** Only read files outside the diff when you've identified a specific concern that the diff alone can't resolve. Before reading any file, name the concern you're investigating (e.g., "this route doesn't check auth -- let me read one existing route to see if there's a wrapper"). To check a pattern, read one example of it, not every instance. Every file read should answer a specific question. If you're reading files without a concern to investigate, stop and write your findings from what you have.

**Review in this order.** Design problems found early save you from reviewing code that might get rewritten.

1. Zoom out -- read the PR description or spec. Does the approach make sense? If not, stop here and say so.
2. Review the main files first -- the biggest, most important changes. This is where design problems live.
3. Review the rest once the design is solid.

**Principles:**
- Is this as simple as it can be? Can someone new read, understand, and change it without breaking anything else? Cut concepts and dependencies, not just lines of code. (Principle #1)
- Is anything being built for an imaginary future requirement? (Principle #2 -- YAGNI)
- Are there forced abstractions that should stay as duplication? (Principle #3)
- If shortcuts were taken, are they documented with a concrete plan to revisit? A TODO without a ticket is a wish. (Principle #4)
- Are irreversible decisions (database schema, public APIs, data models) being treated with enough care? Are reversible decisions being over-planned? (Principle #5)
- Is what's being added worth its cost across future sessions, or is it one-time complexity? (Principle #6)
- Has every change been verified -- tests, build, lint, browser? (Principle #8)
- Can the person who ships this explain why it's structured this way? Is anything opaque or "it works but I don't know why"? (Principle #9)

**Feature structure (the seven patterns):**
- Thin routes -- validate and delegate, no business logic in route files
- Shared schema -- one definition, used by frontend and backend
- Auth wrapped once -- not copy-pasted per route
- Feature names mirrored across layers
- Side effects after the response -- user doesn't wait for webhooks, emails, analytics
- Structured errors with codes, handled at the boundary
- Wiring files (routers, layouts, configs) do zero logic

**Structure & naming:**
- Each file focused on one thing
- Organized by feature, not by type
- Naming reveals intent without reading the body
- Locality of behavior -- understand the feature without opening 5 files
- Dependencies flow one direction -- features don't import from each other
- Feature-specific components live in their feature folder, not in shared
- The "and" test -- if a component does X AND Y AND Z, suggest splitting

**Spec alignment (if a spec was provided):**
- Does the implementation match the spec?
- Were acceptance criteria missed or changed without reason?
- Were out-of-scope items accidentally included?

**Correctness (trace, don't skim):**

Don't just check whether edge case handling exists. Read each changed function, identify its inputs, and trace what actually happens at the boundaries:

- **Inputs at the edges:** what happens with empty strings, zero, negative numbers, single-item arrays, missing optional fields, extremely long strings? Pick the inputs that matter for this specific code and trace the path.
- **External failures:** what happens when a database query returns nothing, an API call times out, a third-party service returns an unexpected shape? Does the error surface clearly or fail silently?
- **Auth and permissions:** is there a path where an unauthorized user reaches this code? Are permission checks happening before data access, not after?
- **Concurrency:** can this be called twice at the same time? What happens with double submits, stale data, or race conditions between read and write?
- **Security:** unsanitized user input rendered in UI (XSS), raw SQL queries (injection), secrets in code?
- **UI states:** loading, error, and empty states handled? What does the user see during slow connections?

The goal is to find what actually breaks, not to confirm the code looks reasonable.

**Performance:**
- N+1 query patterns (fetching in a loop instead of batching)?
- Unbounded data fetching (no limit/pagination on list endpoints)?
- Synchronous operations that should be async?
- Unnecessary re-renders in UI components?
- Heavy work happening in the request path that should be backgrounded?

**Tests:**
- Tests exist for changed behavior
- Testing behavior, not implementation details
- Would actually fail if the code broke

**Comments & PR hygiene:**
- Comments explain why, not what
- TODOs reference a ticket or have a name
- PR is small and focused (target median ~100 lines, p90 <500, <10 files, one responsibility). Larger PRs OK only for migrations or generated code, and should be called out explicitly

**Calibration:** Approve once the code improves overall code health -- even if it isn't perfect. The bar is: is this better than what we had before? Too strict and nothing ships. Too lenient and quality degrades one compromise at a time.

**Output:**
- One-line verdict: **looks good** / **has concerns** / **needs rework**
- Specific issues found, referencing the principle or pattern violated
- Label each: **blocker** (must fix before merge), **important** (should fix before merge, won't block approval alone), or **nit** (optional improvement)
- Concrete fix for each issue
- End with one line on what the code does well -- specific, not generic praise
- If you're uncertain about something, say so and suggest investigation rather than guessing
- Keep it concise -- flag everything worth flagging, but keep each issue to 1-2 lines plus the fix. Don't pad with explanations the reader doesn't need

## Compound draft (automatic)

After the review, evaluate: **did this PR involve something non-obvious that a teammate would hit again?**

Non-obvious means: not findable from reading the code, docs, or error messages. API quirks, debugging insights that took real effort, integration gotchas, patterns that broke in unexpected ways.

**If nothing is worth capturing -- do nothing. Most PRs won't produce a draft. That's fine.**

If something is worth capturing, write a draft to `docs/solutions/.drafts/[descriptive-name].md`. Create the directory if needed.

Format:

```markdown
---
title: [descriptive title]
date: [YYYY-MM-DD]
tags: [relevant technology, pattern, or domain tags]
pr: [PR number or branch name -- used to look up full PR history after merge]
status: draft
---

## What was non-obvious

[What eng-check or the review surfaced that a teammate would benefit from knowing]

## Signal

[The specific review findings, edge cases, or patterns that flagged this as worth capturing]
```

Keep drafts short -- 10-20 lines. They're seeds, not finished docs. After the PR merges, `/eng-compound` enriches them with the full PR history (review comments, fixes, discussions) and presents the complete solution for the user to confirm.
