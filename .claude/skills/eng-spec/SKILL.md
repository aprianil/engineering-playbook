---
name: eng-spec
description: Write a feature spec before building anything. Planning session — no code gets written.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, Skill, AskUserQuestion, EnterPlanMode, ExitPlanMode
argument-hint: [feature-name]
---

Turn a loose feature description into a spec that anyone — human or AI — can build from without follow-up questions. This is a planning session. No code gets written. This is where most of the value lives — if the spec is clear, execution is easy.

**Before anything else:**
- Read the project's CLAUDE.md for engineering principles and conventions. If none exists, suggest running `/eng-init` first.
- Explore the codebase enough to ground your work in real paths, patterns, and conventions.

**Assess whether the idea is ready to spec.**

Clear requirements indicators — Phase 0 may be brief, but still verify shared understanding before proceeding:
- User provides specific acceptance criteria or behavior
- References existing patterns to follow
- Describes exact expected behavior with constrained scope

Vague or exploratory indicators — full grill:
- "I want something like...", "what if we...", "I'm thinking about..."
- Multiple possible directions, unclear scope
- User seems unsure about what they actually want

## Phase 0: Reach shared design concept

The goal of this phase is **shared understanding** — not a saved file, not a plan asset. The design concept (Frederick Brooks's term for the invisible theory of what you're building) lives in the conversation between you and the user. It is not yet an artifact.

**Hard rules:**
- Do not call `Write`. Nothing gets saved this phase.
- Do not call `EnterPlanMode`. Plan mode produces a plan for approval; you don't yet know what to plan.
- Exit only when the *user* could explain the design to a teammate without scrolling back. Not when you understand it — when they do.

**If the user pushes to skip Phase 0** ("just write it, I know what I want"), ask one tripwire question: *"In one sentence — who is this for, and what does success look like?"* Hesitation, a paragraph, or a re-frame means Phase 0 still needs to happen. Don't skip on confidence alone.

**Walk the design tree.** Resolve dependencies one decision at a time. Earlier decisions constrain later ones — name the dependency before each question so the structure is visible ("B depends on A — let me lock A first"). One question at a time, via `AskUserQuestion` with concrete options. Batches break the dependency structure.

**Lead every question with your recommended answer** (Principle #10 — load context before suggesting), grounded in a specific CLAUDE.md principle, a file or pattern you found, or a prior `docs/solutions/` entry. The user agrees, redirects, or corrects — much faster than generating from scratch. Recommendations from vibes don't count; if you can't cite what's driving the recommendation, explore until you can.

**Explore before asking.** If the question is answerable by reading the codebase, an existing spec, or `docs/solutions/`, read it first. Only ask the user about what code can't tell you: product intent, priorities, trade-offs that depend on business context.

Probe through these lenses (skip what's already clear):
- What's the real problem? Is this the right framing, or a proxy for something more important?
- Who cares about this? What are they doing when they hit it?
- What triggered this? (customer feedback, bug, internal idea)
- What happens if we do nothing?
- Is there a simpler version that delivers most of the value?
- What would success look like?

When evaluating multiple approaches that need research (comparing APIs, libraries, architectural patterns), spawn parallel sub-agents to explore each option independently. Each sub-agent gets one option — read docs, check feasibility, identify trade-offs. The parent compares findings and recommends.

**Temporal shape (for user-facing surfaces).** Resolve the four perception milestones as a design-tree node before exiting:

- **Promise paint** (T=0): what does the user see the moment they trigger this? Shell, header, status copy that confirms the system heard them.
- **First-evidence paint**: what's the first piece of real content, and at what T?
- **First-actionable paint**: what's the earliest moment the user can act on partial results? What's gated on full load that doesn't have to be?
- **Full paint**: when is everything done?

This resolves *before* the data architecture is decided. Temporal shape constrains what data architecture is feasible (streaming events, cache layers, parallelism, partial state). Data architecture does not constrain temporal shape. The reverse ordering is the most common cause of "shipped, then re-architected for speed" rework: a feature that's correct end-to-end but blocks the user at stage boundaries because no one specced what the user sees in the first second.

**Exit criteria — all must hold (the fourth applies only to user-facing surfaces):**
1. Scope is bounded — you both know what's in and what's out.
2. Major branches of the design tree are resolved — no live question of the form "but what about X?"
3. The user can answer follow-up questions without scrolling. **Verify by asking one they haven't already been told.** If they hesitate or scroll, keep grilling. Don't proceed on "I think we're good."
4. **Temporal shape resolved (user-facing surfaces only).** All four perception milestones have concrete answers, and the user can name what's gated on partial vs full state.

Then transition to surfacing assumptions.

## Surface assumptions

Skipping this finds misalignments at build time, where they cost 10x. Before writing anything, list every assumption you're making — out loud. The assumptions that are right cost nothing to list; only the wrong ones cost time. Don't silently fill in ambiguity.

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

**Self-deception tripwire.** If you find yourself naming a library version, API signature, file path, function name, or pattern *from memory* rather than from a fetch or grep, stop and verify. Spec-from-vibes is the most common failure mode and the hardest to catch in review — the spec reads as confident even when the underlying claim is unchecked.

**When the feature involves external technologies** (APIs, libraries, frameworks, services), verify current state from official sources before writing the spec. Use `WebSearch` and `WebFetch` to check official documentation for: current stable versions, current API signatures and capabilities, deprecations or breaking changes, and recommended patterns. Training data goes stale. Official docs don't. Never spec against assumed API behavior when you can verify it in 30 seconds.

Gather evidence on up to three concerns -- through direct exploration, parallel sub-agents, or both. Use your judgment on the approach; what matters is that all relevant concerns are covered before writing the spec.

| Concern | What to find out | What you need |
| --- | --- | --- |
| **Codebase fit** | What existing patterns should this feature follow? What files will be touched or created? Is there code that already solves part of this? Also check `docs/solutions/` for prior art -- past problems and solutions related to this feature's domain. | File paths with line numbers, relevant code snippets, the pattern to follow, and any relevant prior solutions |
| **Edge cases & constraints** | What inputs or states could break this? What happens when external dependencies fail? Are any decisions irreversible (DB schema, public APIs)? | Prioritized list of risks with severity (blocks build vs. handle later) |
| **External tech** *(only when the feature touches external dependencies)* | What's the current stable version? Have APIs changed? Are there deprecations or new recommended patterns? What does the official docs say vs. what training data assumes? | Verified versions, confirmed API signatures, links to relevant docs, and any gaps between assumed and actual behavior |

**Use the findings to ground the spec** -- the "Proposed approach" section should reference the codebase agent's file paths and patterns. The "Edge cases & risks" section should incorporate the constraints agent's findings. Don't just append findings -- weave them into the spec so the builder gets one coherent document.

## Spec writing

### Decide spec topology

Before drafting, decide: is this a **solo spec** (one buildable feature, one PR) or a **parent + N sub-specs** (multi-slice feature, parent locks shared decisions, sub-specs ship as small parallel PRs)? This decides whether the build comes back as one mega-PR or as N parallel slices — get it right before any prose.

**Default to solo.** Most features fit one spec. Don't manufacture decomposition where none is needed.

**Choose parent + sub-specs when any of:**
- The feature crosses 2+ independent subsystems (a new agent skill + a UI surface + a shared infra primitive).
- The dependency graph has independent tracks (some work can run concurrently with no file overlap).
- A solo spec would produce a PR over ~500 lines / ~10 files (project's PR-size guideline; large PRs review-loop forever — see `feedback_upstream_spec_over_review.md`).
- Different layers have meaningfully different builders, stress-test concerns, or release cadences.

If unsure, sketch the file-structure map first (next step), then check: does it cluster into 2+ groups with no shared files? If yes, split.

**Vertical slices, never horizontal layers.** When splitting, each sub-spec ships *one thin capability end-to-end* (DB → API → UI for one flow). Layer-PRs (one for migrations, one for routes, one for UI) re-sequentialize the build and keep nothing testable until the last merge. Vertical slices keep every PR independently shippable. Same rule as task slicing within a single spec, hoisted to spec level.

### UX exploration (when the spec creates new UI)

Skip for backend-only, refactor, infra, migration, or doc-only specs. Skip for modifications to existing UI surfaces — the live app already is the sandbox; verify in the browser at build time.

For specs that create a **new** user-facing UI surface (new screen, new flow, new component category, new content surface), sandbox-first is the only path. Prose framings describe UX; sandboxes demonstrate it. Whole categories of UX failure (wrong density, wrong empty state, fake-feeling streaming, ambiguous primary action) only surface when you click through.

The purpose of this phase is **shared understanding of how it feels** — the UX equivalent of Phase 0. The prototype is the medium prose can't replace; the goal is not picking a framing, the goal is the user knowing what they're getting because they've clicked it.

Convert topology to multi-slice: parent + an `<feature>-exploration` sub-spec + an `<feature>-build` sub-spec, with `slice_depends_on: [exploration]` on the build slice.

**Exploration sub-spec workflow:**
1. Build 2-3 framings against real fixtures in the project's dev/exploration area (per CLAUDE.md).
2. The user clicks through each framing themselves. They form their own opinion on which wins, not just receive your recommendation.
3. Polish pass on the chosen winner — density, motion, hover states, optical alignment, micro-interactions. This is where `make-interfaces-feel-better` and `web-animation-design` earn their keep. One pass, then lock.
4. Write the winners doc — chosen framing, rejected alternatives, and why.

**Build sub-spec** links to the prototype as the canonical source for interaction states; prose describes only what the prototype can't show (state machines, side effects, error semantics, server-side behavior). No re-describing the UX — the prototype is already the spec.

**Real fixtures means real fixtures.** Domain text from the actual product, realistic volumes (50 items, not 3), every state the build will hit: empty, error, slow network, very-long content, very-short content, partial loads. Lorem ipsum and 3-item lists hide whole categories of failure.

**Exit criteria — both must hold:**
1. The winners doc captures the chosen framing, rejected alternatives, and why.
2. The user can articulate why the chosen framing wins without re-reading the doc. Not when you've made the case — when they've formed the opinion.

This rule overrides the topology default — a spec that would otherwise be solo becomes multi-slice when it creates new UI. The cost (one sandbox cycle) is paid upstream where UX decisions are still cheap.

### Map the file structure first

Lock which files get created, modified, or tested before writing prose. This forces decomposition decisions early — when they're cheap — and gives the builder a clear map. The codebase fit research should inform this directly. For multi-slice features the file map is also the **file-claim manifest**: each file belongs to exactly one sub-spec, declared at parent so collisions are caught at parent-write time, not sub-spec write time. See `## Multi-slice flow` for enforcement.

**What you need (ask only what's still missing after exploration):**
- What problem does this solve? (one sentence)
- Who is this for?
- What triggered this?
- How will you know this is done? (acceptance criteria — suggest defaults from CLAUDE.md principles if the user isn't sure)

Scale the spec to the task. Small feature → skip sections that don't apply. New initiative → full context.

**Apply the project's engineering principles while writing — the stress-test will catch what slips, but design-time awareness is cheaper:**
- Is this the simplest approach that solves the problem? (#1)
- Are we building for a real requirement or an imaginary one? (#2)
- Are any decisions irreversible — schema, public APIs, file formats? Those deserve extra scrutiny. (#5)
- How will we verify this works — tests, build checks, browser? (#8)
- Will the builder understand why the code is structured this way? (#9)
- Can this decompose into independent parallel pieces? (#11)

**The spec format:**

Each spec opens with YAML frontmatter (the machine-readable contract `/eng-spec` and `/eng-build` read) followed by the markdown body. Frontmatter shape:

```yaml
---
title: "<human-readable>"
status: specced            # specced | building | built
session: solo              # solo | parent | <slice-id>
summary: <2–4 sentence what + why>
depends_on: [<other features this build needs already shipped>]
references: [<paths the spec leans on>]

# Parent only:
build_specs: [specs/<feature>/<feature>-<slice-id>-<short>.md, ...]

# Sub-spec only:
slice_of: <parent feature name, no .md>
slice_id: <a | b | c | kebab-name>
slice_depends_on: [<sibling slice IDs that must merge first; empty = parallel-from-start>]
files_claimed:
  - <path or glob — exclusive to this slice>
---
```

Frontmatter is load-bearing. `/eng-build <sub-spec>` reads `slice_depends_on:` and refuses to start until those slices merge. `/eng-spec` reads sibling `files_claimed:` lists and refuses to save on overlap. Don't let the frontmatter drift from the body.

Then the markdown body:

```
## Feature: [name]

### Context
Why this exists. The background — enough that someone reading this 3 months from now understands the motivation without asking anyone.

### What
One-line description of what this feature does.

### Who
Who this is for and what they're doing when they encounter this.

### User flow
The steps a user takes. Happy path and sad path (errors, empty states, slow connections). For user-facing surfaces, annotate the four perception milestones (promise paint, first-evidence, first-actionable, full) with concrete T-values, and call out which actions gate on partial vs full state. Each milestone names what the user sees and what they can do at that moment.

### Interaction states
*Include for features with UI. Skip for backend-only or refactors.*

Document each distinct state the user can encounter and what triggers transitions between them. The goal: the builder never invents UX on the fly — every state they need to handle is already decided.

For each state: what the user sees, what causes it, and where it goes next. Use whatever format fits — a table, a list, a state diagram in words. What matters is that no state is left to the builder's imagination. Pay special attention to: what does "loading" look like? What does the user see when something fails? What happens on empty/first-use?

### Acceptance criteria
- [ ] [concrete, verifiable criteria]

**The vague-criterion test.** If a criterion contains words like *graceful*, *properly*, *as expected*, *fast*, *clean*, *intuitive* — it is not yet a criterion. Reframe to a measurable condition or delete it. This is the single highest-leverage check in the spec; vague acceptance is what lets a feature ship "done" while still being broken.

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

**Code contracts** *(required when the spec introduces new exported functions on the capability path — anything an external caller, agent, or orchestrator might invoke)*: Specify the signature with named input + output types using the project's contract convention (Zod, Pydantic, serde, OpenAPI — check CLAUDE.md), plus a 2–3 line pseudocode body. The stress-test gate is verdict-blocking on this — a "TypeScript interface" or "we'll add validation later" doesn't count. Write the contract now; deferring to build is a Type 1 decision, and that's what reshape PRs are made of.

**Data flow** *(include when the feature crosses 2+ system boundaries)*: Show how data moves from trigger to destination — a simple arrow chain like `user click → frontend handler → POST /api/foo → server handler → database → SSE event → frontend update`. Makes explicit who is responsible for what at each boundary. Prevents "I thought that happened on the other side."

### Rationalization check
The stress-test gate runs the full rationalization scan with explicit action. Self-check before firing it: scan the draft for "we can always refactor later," "it's just a prototype," "we might need this someday," "everyone does it this way," "no time to do it right." Each phrase is a placeholder for an unmade decision — name the decision now, or expect the gate to flag it.

### Out of scope
What this feature explicitly does NOT include.
```

## Stress-test (Principle #7) — mandatory before save, iterate until clean

`/eng-build` refuses to start on a spec whose `## Stress-test verdict` heading is anything other than `ready to build`. The spec hits disk only after the verdict is clean, with the clean verdict embedded in the same `Write`. Concerns surfaced during iteration live in conversation and never touch the file; the build session sees only the terminal state.

Once the spec body and task breakdown are drafted in conversation, call the `Skill` tool with `skill: eng-stress-test` and pass inline: the full draft, the engineering principles you're checking against, and the codebase paths/snippets you grounded the draft in. Do not save the spec yet — don't stop, don't ask, don't summarize first. Same call fires for parent drafts, each sub-spec draft, and any re-run after a material draft edit.

`/eng-stress-test` walks the engineering principles + first-of-kind patterns and returns the verdict as a chat response. It does **not** modify any file. The response is one of two shapes:

- **Clean verdict** — verdict is `ready to build`, followed by a short "What's load-bearing in this spec" paragraph.
- **Working verdict** — verdict is `address these first` or `rethink approach`, followed by 3–7 prioritized concerns. **This is transient and stays in conversation only.**

**Iterate until clean.** When the stress-test returns a working verdict:
1. Present the concerns to the user with your recommendation on which findings to address (group by P0/P1/P2 if useful).
2. Wait for the user's call. They may agree to fix all, dismiss some as low-value, or push back on framing — make the call together.
3. **Update the in-conversation draft.** Edit the relevant sections — What, User flow, Acceptance criteria, Edge cases, Key decisions, Tasks. The draft has no disk presence yet, so there is no file to patch — just the working draft you're iterating on.
4. Re-fire `/eng-stress-test` with the updated draft inline. New verdict comes back in chat.
5. Repeat from step 1 until the verdict is `ready to build`.

**Two-round tripwire.** If the same concerns reappear across two stress-test rounds, the spec has a structural problem, not a wording problem. Stop iterating; redo the design. Polishing prose around an unsound design produces a clean verdict on a spec that still ships bugs.

When the verdict is clean, save the spec to disk for the first time — body + task list + clean verdict heading + load-bearing paragraph in a single `Write` call. Then move to spec lock. The spec's terminal state on disk has exactly one verdict heading: the clean one. The iteration history never touches the file — that's the point.

Do not write code until the verdict is clean and the user has approved.

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

Add the task list to the in-conversation draft. The draft is now complete — body + tasks. Do not save to disk yet.

**Fire the stress-test gate per the Stress-test section above.** Only after the verdict is clean, save the complete spec to `specs/[feature-name].md` (kebab-case, create the directory if needed) in one `Write` call with the clean verdict heading embedded. This file is the contract between planning and execution.

**Lock the spec once saved. Specs you can't stop editing are specs no one builds from.** Refinement loops that don't close cause spec drift; resist re-opening every time a new article or idea arrives. Define a lock point in the Out-of-scope section as `re-spec trigger: [criterion]`. Candidates: "first task has been built," "non-AI reviewer has signed off," "no external input has changed the spec across N consecutive reads." Pick one per spec. Once locked, spec changes happen as targeted edits during build with commit messages explaining what evidence triggered the change — not as re-opened planning sessions.

For multi-slice features the lock cascades: parent locks before any sub-spec is written, and unlocks only when a sub-spec discovers something the parent got wrong (signal, not noise — better caught now than after sub-spec N+1 was written on the wrong contract). Each sub-spec locks per its own re-spec trigger.

**Promote cross-phase Type 1 decisions at lock time.** If the project maintains a living cross-phase decision log (e.g., `specs/eng-spec-overview.md` — check CLAUDE.md for the project's convention), scan the spec's Type 1 decisions before declaring lock. For any that affect later phases — schema changes, contract picks, protocol decisions, architectural commitments — confirm with the user and promote them to the log now. Lock-time catches what post-build promotion forgets: decisions are fresh, the spec hasn't shipped, the canonical text is still in flux. Type 2 (reversible) decisions stay inline only; not worth the log.

**Offer the next step.** Once locked, surface the build kickoff: *"Spec ready at `specs/<feature>.md`. Run `/eng-build specs/<feature>.md` now, or come back when you're ready."* For multi-slice features, point at the next sub-spec to write (continuous flow) or the first slice to build (resumed flow, per `slice_depends_on:`). Don't auto-fire — the spec/build session boundary is intentional, but the user shouldn't have to guess the next command.

## Multi-slice flow (when topology is parent + sub-specs)

The session(s) produce one parent.md and N sub-spec files, in a fixed order. Skip this section when topology is solo.

**1. Parent first.** Write the parent fully — context, what, who, user flow, acceptance criteria spread across slices, file-structure map, **shared code contracts** (types and key function signatures used by 2+ slices — defined once at parent, sub-specs reference, never restate), key cross-cutting decisions (D1, D2, …), build sequence + branch topology, sub-spec roster (per slice: scope claim + `files_claimed` reservation + `slice_depends_on`), migration-number reservations.

**2. Stress-test parent draft.** Parent's stress-test focuses on decomposition correctness (right slice boundaries? shared contracts complete enough that sub-specs need no parent edits? DAG actually parallel?) and architectural soundness. Run `/eng-stress-test` against the parent draft inline; iterate per the Stress-test section. Save the parent only after verdict is clean, with the clean verdict embedded.

**3. Lock parent.** Same lock rules as solo specs (re-spec trigger in Out of scope). Parent unlocks only when a sub-spec discovers something the parent got wrong.

**4. Sub-specs sequentially.** One sub-spec at a time, in dependency order (`slice_depends_on:` topological). Each sub-spec runs the full `/eng-spec` flow on its own scope: research → assumptions → spec format (acceptance, edge cases, code contracts specific to this slice) → task breakdown → stress-test until clean → save. Sub-specs reference parent's shared contracts; they do not restate them.

**5. File-claim conflict check.** After each sub-spec saves, verify no path in its `files_claimed:` appears in any sibling sub-spec's `files_claimed:`. Implementation: read every sibling's frontmatter, gather `files_claimed:` lists into one set, fail loudly on duplicate. Overlap is a slice problem, not a manifest problem — refactor sub-specs (move the contested file, or merge two slices that genuinely share state) to eliminate it. Don't paper over with a comment.

### Continuous vs resumed

Both timings are valid; pick whichever fits the work.

- **Continuous (default).** Same session writes parent + all sub-specs. Decisions compound in conversation, prefix cache stays warm, no re-priming. Right when one operator runs the whole feature in one sitting. Opus 4.7 (1M context) holds parent + ~5 sub-specs comfortably.
- **Resumed.** Session 1 ends after parent locks. Later sessions invoked as `/eng-spec <parent-spec-path>` — read parent, ask which slice, write one sub-spec, exit. Right when sub-specs span multiple days, multiple operators, or are parallelized across worktrees. Parent must be self-sufficient as input — that's enforced by parent's roster + shared contracts, both of which the continuous path also requires, so no extra work to support resumed. **Handoff messages between sessions:** output operational state only — skill invocation, branch, tree caveats. The spec carries the rest. Three lines is usually enough.

### Naming + filesystem

- Parent: `specs/<feature>/<feature>.md` — subdirectory per multi-slice feature (Phase 2 pattern: `specs/phase-2/phase-2-prompt-discovery.md`).
- Sub-spec: `specs/<feature>/<feature>-<slice-id>-<short-name>.md`.
- `<slice-id>`: letters when sequenced (`a`, `b`, `c` — order conveys build order); kebab-name when parallel-from-start (`shared-cache`, `cards-ux`).
- Solo specs stay at `specs/<feature>.md` — no subdirectory until split.

### Build flow integration

- `/eng-build <sub-spec-path>` reads `slice_depends_on:` and refuses to start if any listed slice is not yet merged into the integration branch (or main, if there is no integration branch for the feature).
- Parallel sub-spec builds **must** live in separate worktrees — shared lint/tsc hooks race on in-flight state even when file scopes are disjoint. See project memory `feedback_parallel_subagents.md`.
- Each sub-spec PR targets the integration branch (e.g., `phase-3-visibility-tracker`); the integration branch merges to main only after all sub-specs are green.
- Migration numbers are reserved at parent-write time (parent declares "migrations 026–028 reserved by 3a, 029 by 3b, …"); sub-specs use only what parent assigned them. Reservation does not depend on merge order.
