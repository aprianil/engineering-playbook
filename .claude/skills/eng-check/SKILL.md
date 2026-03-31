---
name: eng-check
description: Review code against engineering principles. Spawns a fresh sub-agent so the reviewer has no build-session bias.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Agent
---

Review code against the project's engineering principles. This spawns a sub-agent with fresh context -- the builder shouldn't review their own work (Principle #7).

**How it works:**

1. Read the project's CLAUDE.md for conventions and principles.
2. Get the changed files: detect the base branch, then `git diff $(git merge-base <base> HEAD) --name-only`.
3. If a spec exists in `specs/` for this feature, read it.
4. Spawn a sub-agent (Agent tool) with the CLAUDE.md, the list of changed files, the spec (if any), and everything below as the review instructions.

---

**Review instructions for sub-agent:**

You are reviewing code with fresh eyes. You did not write this code.

Read the project's CLAUDE.md first -- that's the source of truth. Everything below is a fallback for projects without one.

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

**Correctness:**
- Does it handle the sad path, not just the happy path?
- Edge cases covered (empty, null, unexpected input)?
- Error handling useful, not silent?
- Concurrency issues -- race conditions, double submits?
- Security -- unsanitized user input rendered in UI (XSS), raw SQL queries (injection), secrets in code, missing auth on routes?
- For UI: loading, error, and empty states handled?

**Tests:**
- Tests exist for changed behavior
- Testing behavior, not implementation details
- Would actually fail if the code broke

**Comments & PR hygiene:**
- Comments explain why, not what
- TODOs reference a ticket or have a name
- PR is small and focused (<500 lines, <10 files, one responsibility)

**Calibration:** Approve once the code improves overall code health -- even if it isn't perfect. The bar is: is this better than what we had before? Too strict and nothing ships. Too lenient and quality degrades one compromise at a time.

**Output:**
- One-line verdict: **looks good** / **has concerns** / **needs rework**
- Specific issues found, referencing the principle or pattern violated
- Label each: **blocker** (must fix) or **nit** (optional, won't block approval)
- Concrete fix for each issue
- Keep it concise -- flag what matters, skip what's fine
