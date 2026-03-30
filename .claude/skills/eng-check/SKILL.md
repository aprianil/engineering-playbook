---
name: eng-check
description: Review code against engineering principles. Use when the user asks to review code, check quality, or wants a code review before shipping.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep
---

Review code against the project's engineering principles.

**First:** Read the project's CLAUDE.md. That's the source of truth for this project's conventions, structure, and principles. Everything below is a fallback for projects without one.

Review the code the user is pointing to (or the most recently edited files if not specified).

**Principles:**
- Is this as simple as it can be? (Principle #1)
- Is anything being built for an imaginary future requirement? (Principle #2 — YAGNI)
- Are there forced abstractions that should stay as duplication? (Principle #3)
- If shortcuts were taken, are they documented? (Principle #4)
- Are irreversible decisions being treated with enough care? (Principle #5)
- Is what's being added worth its cost across future sessions, or is it one-time complexity? (Principle #6)

**Feature structure (the seven patterns):**
- Thin routes — validate and delegate, no business logic in route files
- Shared schema — one definition, used by frontend and backend
- Auth wrapped once — not copy-pasted per route
- Feature names mirrored across layers
- Side effects after the response — user doesn't wait for webhooks, emails, analytics
- Structured errors with codes, handled at the boundary
- Wiring files (routers, layouts, configs) do zero logic

**Structure & naming:**
- Each file focused on one thing
- Organized by feature, not by type
- Naming reveals intent without reading the body
- Locality of behavior — understand the feature without opening 5 files
- Dependencies flow one direction — features don't import from each other
- Feature-specific components live in their feature folder, not in shared
- The "and" test — if a component does X AND Y AND Z, suggest splitting

**Spec alignment (if a spec exists in `specs/`):**
- Does the implementation match the spec?
- Were acceptance criteria missed or changed without reason?
- Were out-of-scope items accidentally included?

**Correctness:**
- Does it handle the sad path, not just the happy path?
- Edge cases covered (empty, null, unexpected input)?
- Error handling useful, not silent?
- Concurrency issues — race conditions, double submits?
- For UI: loading, error, and empty states handled?

**Tests:**
- Tests exist for changed behavior
- Testing behavior, not implementation details
- Would actually fail if the code broke

**Comments & PR hygiene:**
- Comments explain why, not what
- TODOs reference a ticket or have a name
- PR is small and focused (<500 lines, <10 files, one responsibility)

**Output:**
- One-line verdict: **looks good** / **has concerns** / **needs rework**
- Specific issues found, referencing the principle or pattern violated
- Concrete fix for each issue
- Keep it concise — flag what matters, skip what's fine
