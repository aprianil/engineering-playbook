---
name: eng-spec
description: Write a feature spec before building anything. Planning session — no code gets written.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, EnterPlanMode, ExitPlanMode
argument-hint: [feature-name]
---

Turn a loose feature description into a spec that anyone — human or AI — can build from without follow-up questions. This is a planning session. No code gets written. This is where most of the value lives — if the spec is clear, execution is easy.

**Before anything else:**
- Read the project's CLAUDE.md for engineering principles and conventions. If none exists, suggest running `/eng-init` first.
- Explore the codebase enough to ground your work in real paths, patterns, and conventions.

**Assess whether the idea is ready to spec.**

Clear requirements indicators — skip to spec writing:
- User provides specific acceptance criteria or behavior
- References existing patterns to follow
- Describes exact expected behavior with constrained scope

Vague or exploratory indicators — explore first:
- "I want something like...", "what if we...", "I'm thinking about..."
- Multiple possible directions, unclear scope
- User seems unsure about what they actually want

## Exploration mode

When the idea is still forming, be a thinking partner — not an interviewer. Challenge assumptions, propose alternatives, surface risks. Use `AskUserQuestion` to keep the conversation focused — one question at a time, with concrete options when possible.

**Walk the decision tree, not a flat list.** Earlier decisions constrain later ones — resolve them in order, so each question builds on the last answer and narrows scope. Don't dump a batch of open questions at the end; interrogate to shared understanding, branch by branch.

**Lead every question with your recommended answer**, grounded in a specific CLAUDE.md principle, a file or pattern you found, or a prior `docs/solutions/` entry (Principle #10 — load context before suggesting). The user agrees, redirects, or corrects — that's much faster than generating from scratch. Recommendations from vibes don't count; if you can't cite what's driving the recommendation, explore until you can.

**Explore before asking.** If the question is answerable by reading the codebase, an existing spec, or `docs/solutions/`, read it first. Only ask the user about what the code can't tell you: product intent, priorities, trade-offs that depend on business context.

Probe through these lenses (skip what's already clear):
- What's the real problem? Is this the right framing, or a proxy for something more important?
- Who cares about this? What are they doing when they hit it?
- What triggered this? (customer feedback, bug, internal idea)
- What happens if we do nothing?
- Is there a simpler version that delivers most of the value?
- What would success look like?

When the exploration involves trade-offs, architectural choices, or multiple valid approaches — use `EnterPlanMode` to think it through properly. Write out the options, pros/cons, and your recommendation. Exit plan mode when you have a clear direction.

When evaluating multiple approaches that need research (e.g., comparing APIs, libraries, or architectural patterns), spawn parallel sub-agents to explore each option independently. Each sub-agent gets one option to research — read docs, check feasibility, identify trade-offs. The parent compares findings and recommends. This is faster and each sub-agent goes deeper than sequential exploration.

**Exit exploration when:** the problem is clear, the scope is bounded, and you could write acceptance criteria. Then transition to surfacing assumptions.

## Surface assumptions

Before writing anything, list every assumption you're making. Don't silently fill in ambiguity — the spec's entire purpose is to surface misunderstandings before code gets written.

```
ASSUMPTIONS I'M MAKING:
1. [e.g., This extends the existing billing module, not a new one]
2. [e.g., Auth uses the withAuth wrapper from lib/auth]
3. [e.g., We're adding a new table, not modifying the existing one]
4. [e.g., This is internal-only, no public API surface]
→ Correct me now or I'll proceed with these.
```

Use `AskUserQuestion` to present these. Keep it one message — the user corrects what's wrong, confirms what's right, and you move on. Only the assumptions that are wrong cost time. The ones that are right cost nothing to list.

Then transition to research.

## Research (ground the spec in evidence)

Before writing the spec, gather concrete evidence from the codebase. This prevents the spec from being written on vibes -- the proposed approach should reference real files, real patterns, and real constraints.

**Skip this step when the feature is small and the codebase is familiar enough that you already know the relevant files and patterns.** Don't launch agents to confirm what's obvious.

**When the feature involves external technologies** (APIs, libraries, frameworks, services), verify current state from official sources before writing the spec. Use `WebSearch` and `WebFetch` to check official documentation for: current stable versions, current API signatures and capabilities, deprecations or breaking changes, and recommended patterns. Training data goes stale. Official docs don't. Never spec against assumed API behavior when you can verify it in 30 seconds.

Gather evidence on up to three concerns -- through direct exploration, parallel sub-agents, or both. Use your judgment on the approach; what matters is that all relevant concerns are covered before writing the spec.

| Concern | What to find out | What you need |
| --- | --- | --- |
| **Codebase fit** | What existing patterns should this feature follow? What files will be touched or created? Is there code that already solves part of this? Also check `docs/solutions/` for prior art -- past problems and solutions related to this feature's domain. | File paths with line numbers, relevant code snippets, the pattern to follow, and any relevant prior solutions |
| **Edge cases & constraints** | What inputs or states could break this? What happens when external dependencies fail? Are any decisions irreversible (DB schema, public APIs)? | Prioritized list of risks with severity (blocks build vs. handle later) |
| **External tech** *(only when the feature touches external dependencies)* | What's the current stable version? Have APIs changed? Are there deprecations or new recommended patterns? What does the official docs say vs. what training data assumes? | Verified versions, confirmed API signatures, links to relevant docs, and any gaps between assumed and actual behavior |

**Use the findings to ground the spec** -- the "Proposed approach" section should reference the codebase agent's file paths and patterns. The "Edge cases & risks" section should incorporate the constraints agent's findings. Don't just append findings -- weave them into the spec so the builder gets one coherent document.

## Spec writing

**Before writing, check scope.** If the feature touches multiple independent subsystems, suggest separate specs. Each spec should produce independently working, testable software. A bloated spec that tries to do everything leads to a bloated build.

**Then map the file structure first.** Lock which files get created, modified, or tested before writing the rest of the spec. This forces decomposition decisions early — when they're cheap to change — and gives the builder a clear map. The codebase fit research should inform this directly -- follow the patterns it found.

**What you need (ask only what's still missing after exploration):**
- What problem does this solve? (one sentence)
- Who is this for?
- What triggered this?
- How will you know this is done? (acceptance criteria — suggest defaults from CLAUDE.md principles if the user isn't sure)

Scale the spec to the task. Small feature → skip sections that don't apply. New initiative → full context.

**Apply the project's engineering principles throughout:**
- Is this the simplest approach? Readable, changeable, few things to think about? (Principle #1)
- Are we building for a real requirement or an imaginary one? (Principle #2 — YAGNI)
- Are we designing abstractions upfront, or discovering them? (Principle #3)
- If we're taking shortcuts, do they have a concrete plan to revisit? (Principle #4)
- Are any decisions here irreversible (database schema, public APIs)? Those deserve extra scrutiny. Reversible ones — just decide. (Principle #5)
- Does what we're adding compound over time, or is it a one-time need? (Principle #6)
- How will we verify this works? What tests, checks, or browser validation should the spec require? (Principle #8)
- Will the user understand why the code is structured this way after building? Flag anything that needs explanation in the spec. (Principle #9)
- Can this be decomposed into independent pieces that can be built in parallel? (Principle #11)

**The spec format:**

```
## Feature: [name]

### Context
Why this exists. The background — enough that someone reading this 3 months from now understands the motivation without asking anyone.

### What
One-line description of what this feature does.

### Who
Who this is for and what they're doing when they encounter this.

### User flow
The steps a user takes. Happy path and sad path (errors, empty states, slow connections).

### Interaction states
*Include for features with UI. Skip for backend-only or refactors.*

Document each distinct state the user can encounter and what triggers transitions between them. The goal: the builder never invents UX on the fly — every state they need to handle is already decided.

For each state: what the user sees, what causes it, and where it goes next. Use whatever format fits — a table, a list, a state diagram in words. What matters is that no state is left to the builder's imagination. Pay special attention to: what does "loading" look like? What does the user see when something fails? What happens on empty/first-use?

### Acceptance criteria
- [ ] [concrete, verifiable criteria]

When requirements are vague, reframe them into measurable conditions before writing criteria:
```
Requirement: "Make the dashboard faster"
→ Dashboard LCP < 2.5s on 4G connection
→ Initial data load < 500ms
→ No layout shift during load (CLS < 0.1)
Are these the right targets?
```
This turns fuzzy goals into things you can actually verify. Confirm the reframed criteria with the user before proceeding.

### Edge cases & risks
The prioritized list — what actually matters. For each:
- What could go wrong
- How to handle it
- What's explicitly not worth handling yet, and why

For user-facing errors, be specific about the UX: what does the user see (toast, inline message, modal, chat message), what system action happens (retry, skip, abort), and how the user recovers. "Handle gracefully" is not a spec — it's a wish.

### Proposed approach
- Existing code: relevant files and patterns already in use (reference real paths)
- File structure: exact files to create or modify, following project conventions
- Key decisions: what was chosen, what was rejected, and why (this is the decision record; future you will thank present you for writing the "why"). Label each decision **Type 1** (hard to reverse: schemas, public APIs, protocol choices, file formats that others will consume) or **Type 2** (reversible: naming, tool cardinality, internal ordering, anything a grep-and-edit fixes in an hour). Type 1 deserves extra scrutiny in the rationalization check; Type 2 can change during build without pulling the builder back to the spec table
- Dependencies: what could block this (external APIs, other teams, migrations)

**Code contracts** *(include when adding new functions or modifying existing signatures)*: For each new function, specify the signature with types, a 2-3 line pseudocode body, and the return value. Not the full implementation — just enough that the builder doesn't have to guess the interface. The builder should never wonder "what does this function take and return?"

**Data flow** *(include when the feature crosses 2+ system boundaries)*: Show how data moves from trigger to destination — a simple arrow chain like `user click → frontend handler → POST /api/foo → server handler → database → SSE event → frontend update`. Makes explicit who is responsible for what at each boundary. Prevents "I thought that happened on the other side."

### Rationalization check
Before finalizing, scan the spec for these red flags. If any feel true, revisit the decision:
- "We can always refactor later" (translation: we won't)
- "It's just a prototype" (prototypes ship)
- "We might need this someday" (YAGNI)
- "It's only a small addition" (small additions compound into big complexity)
- "Everyone does it this way" (appeal to popularity, not evidence)
- "We don't have time to do it right" (you don't have time to do it twice)
- "It's too late to change" (sunk cost; if the direction is wrong, changing now is cheaper than later)

### Out of scope
What this feature explicitly does NOT include.
```

## Stress-test (Principle #7)

After writing the spec, spawn a sub-agent to challenge it with fresh eyes. The sub-agent follows the `/eng-stress-test` methodology — pass it the spec content, relevant CLAUDE.md principles, key file paths from research, and the project root so it doesn't waste time re-discovering what you already know. It reads the spec cold with no knowledge of how it was written.

Wait for its findings, then present to the user:
1. The spec
2. The stress-test findings
3. Your recommendation on which findings to address

Wait for approval or adjustments. Do not write code.

Once approved, break the spec into tasks before saving.

## Task breakdown

Break the approved spec into discrete, buildable tasks. Each task should be completable in a single focused session.

```
- [ ] Task: [description]
  - Acceptance: [what must be true when done]
  - Verify: [how to confirm — test command, build, browser check]
  - Files: [which files will be created or modified]
  - Depends: [which tasks must complete first, or "none" if independent]
```

Mark independent tasks explicitly — these can run in parallel (e.g., in separate worktrees). When 3+ tasks exist and some are independent, the dependency info is what enables parallel builds.

**Slice vertically, not horizontally.** Each task should deliver a working, testable path through the feature — not a horizontal layer.

Bad: Task 1 = all database tables, Task 2 = all API endpoints, Task 3 = all UI components, Task 4 = connect everything.
Good: Task 1 = user can create account (schema + API + UI), Task 2 = user can log in, Task 3 = user can create a task.

Vertical slices keep the feature working and testable at every step. Horizontal layers leave you with nothing testable until the last task.

**When to break a task down further:**
- You can't describe acceptance criteria in 3 or fewer bullets
- It touches 2+ independent subsystems (e.g., auth and billing)
- You wrote "and" in the task title — that's two tasks
- It would take more than one focused session

Guidelines:
- Order tasks by dependency, then by risk — build foundations first, but put high-risk tasks early. Fail fast before investing in the easy parts
- Each task should touch a small number of files (aim for ~5 or fewer)
- Every task has a verify step — no task is "done" without proof
- For small features, 2-3 tasks is fine. Don't over-decompose

This task list becomes what `/eng-build` reads. The clearer it is, the less judgment the builder needs to apply.

Append the task list to the spec, then save to `specs/[feature-name].md` (kebab-case, create the directory if needed). This file is the contract between planning and execution.

**Lock the spec once saved.** Resist re-opening every time a new article or idea arrives — refinement loops that don't close cause spec drift, and specs you can't stop editing are specs no one builds from. Define a lock point in the Out-of-scope section as `re-spec trigger: [criterion]`. Candidates: "first task has been built," "non-AI reviewer has signed off," "no external input has changed the spec across N consecutive reads." Pick one per spec. Once locked, spec changes happen as targeted edits during build with commit messages that explain what evidence triggered the change — not as re-opened planning sessions.

## Decompose for parallelism (Principle #11)

After approval, check whether the work can be split into independent pieces that can be built in parallel. Not every spec needs splitting — small features ship as one spec.

**When to split:** the spec has a dependency graph where some work can happen concurrently. Look for files with no dependencies on each other, or groups of work that only connect at defined interfaces.

**How to split:**
- Map the dependency graph. The shape varies — it might be "foundation → parallel tracks → integration" or "three parallel tracks from the start" or "two tracks that merge halfway." Let the work dictate the shape
- Write all build specs sequentially in the main conversation. Each spec benefits from decisions made in the previous ones. Do not farm out spec writing to parallel agents — they lose the accumulated context and the specs drift from each other
- Each build spec runs the full `/eng-spec` process — same spec format, research, acceptance criteria, edge cases, stress-test. Not a task list carved from the parent, but a standalone spec
- Each build spec states what's being built alongside it — not for coordination, but so the builder understands the boundaries. What they own, what's off-limits, and what they can expect to exist when the tracks merge
- No file overlap between specs
- Each build spec gets its own stress-test (parallel sub-agents are fine here — stress-testing benefits from fresh eyes)
- The parent spec stays as the decision document. Add a build status section listing all split specs with their dependencies and status

Save build specs as `specs/[parent-name]-[letter]-[short-name].md`.

## Build sequence + branch topology (conditional — only when the slice makes sense)

When a spec decomposes into multiple build specs that will run in parallel, the specs need explicit branch topology + build sequence guidance. When it doesn't, a single branch name is enough — don't over-apply.

**When to include a full topology section:**
- Two or more build specs that can genuinely run concurrently (parallel tracks from the "Decompose for parallelism" step above).
- Any build that will run alongside another in-progress build on the same repo.

**When to include just a branch-name callout (skip topology section):**
- Single-track spec (one build, sequential).
- Follow-on cleanup PR after the main build merges (it runs alone).
- Doc-only or purely additive change that piggybacks on an existing branch.

**When in doubt, skip the topology section.** A single-track spec with a full topology template is noise — the reader has to figure out it doesn't apply. Only write it when a reader would genuinely need the isolation + sequence instructions.

**Stay tool-agnostic.** Builders pick their own isolation mechanism (`git worktree`, `conductor.build`, an IDE feature, a separate clone). The spec cares that the isolation happens, not how. Don't prescribe `git worktree add` command templates — they're noise for everyone not using the git CLI directly.

**Where it lives:** short `## Branch + separate working tree` block near the top of each build spec (right after the title, before `## Context`), plus a full `## Build sequence + branch topology` section in the parent spec. Build specs point back to the parent for the topology + coordination rules.

**What a full parent-spec section includes:**
- Branch topology diagram (integration branch + child branches + cleanup branches), showing merge direction.
- Build sequence (what ships first, what runs in parallel, what merges last, what triggers cleanup).
- Coordination rules that hold regardless of mechanism: `PORT=NNNN` overrides if multiple builds may run dev servers; rebase-before-PR when one build merges before another opens its PR; never build two specs in the same checkout.
- Rationale for requiring isolation: shared pre-commit/tsc/lint hooks race on concurrent in-flight state across trees — even with disjoint file scopes, isolation must be at the filesystem level, not the hook level. Cite the project's own memory / solutions note if one exists.

**What a minimal child-spec block includes (when the parent has the full section):**
- Branch name for this build.
- One-line note on whether isolation is required (parallel build) or recommended (sequential build), pointing back to the parent section for the topology.
- PR target branch.

**What a single-track spec's branch block includes:**
- Just the branch name + PR target. No topology content. ~2 lines.
