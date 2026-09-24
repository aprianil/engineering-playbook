---
name: eng-spec
description: Write a feature spec before building anything. Planning session, no code gets written. Every feature past fix triage gets a spec scaled to its size; default is one spec, one build session, one PR, with vertical slices as the unit of commit inside it.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, Skill, AskUserQuestion, EnterPlanMode, ExitPlanMode
argument-hint: [feature-name]
---

Turn a loose feature description into a spec that anyone (human or AI) can build from without follow-up questions. This is a planning session. No code gets written. This is where most of the value lives: if the spec is clear, execution is easy.

## Triage: is this a feature, or a fix?

**Run this check first.** This skill is for greenfield work: new surface, new flow, new capability, new architectural decision. For known bugs, the bug is the spec; routing fixes through this pipeline manufactures ceremony where there's no design to make. Watching this category mismatch happen is the single biggest source of session drag in fix-heavy phases.

Exit immediately and route to `/eng-debug` if any signal fires:
- Branch name contains `fix/`, `hotfix/`, `bug/`, `followup/`.
- User describes it as "X is broken," "rerun found Y," "QA caught Z," "data quality issue," "this doesn't work," "fix the issue in N."
- No new surface, flow, or capability. Just a known-wrong behavior to make right.
- The would-be spec collapses to one paragraph: what's broken + what fix to apply. If you can't fill Outcome, User flow, and Edge cases distinctly, this isn't a feature.

Exit line: *"this looks like a fix, not a feature. routing to /eng-debug + fix + /eng-check. say 'spec it anyway' if you want the full pipeline."*

User override wins. Uncritical default-to-spec on fix work is the bug this triage exists to kill.

**Before anything else (past triage):**
- Read the project's CLAUDE.md for engineering principles and conventions. If none exists, suggest running `/eng-init` first.
- Explore the codebase enough to ground your work in real paths, patterns, and conventions.

**Delegation.** Follow the orchestration policy in CLAUDE.md (user-level or project). Default when none is stated: the orchestrator does quick mechanical scans itself (inventorying files, checking versions, confirming an API signature); one deep-reasoning agent handles trade-off evaluations; implementation and markup go to one long-lived coder agent, kept alive with `SendMessage` so it keeps its context. Use Codex only when the project's CLAUDE.md / AGENTS.md names it.

**Assess whether the idea is ready to spec.**

Clear requirements indicators (Phase 0 may be brief, but still verify shared understanding before proceeding):
- User provides specific acceptance criteria or behavior
- References existing patterns to follow
- Describes exact expected behavior with constrained scope

Vague or exploratory indicators (full grill):
- "I want something like...", "what if we...", "I'm thinking about..."
- Multiple possible directions, unclear scope
- User seems unsure about what they actually want

## Phase 0: Reach shared design concept

The goal of this phase is **shared understanding**, not a saved file or a plan asset. The design concept (Frederick Brooks's term for the invisible theory of what you're building) lives in the conversation between you and the user. It is not yet an artifact.

**Hard rules:**
- Do not call `Write`. Nothing gets saved this phase.
- Do not call `EnterPlanMode`. Plan mode produces a plan for approval; you don't yet know what to plan.
- Exit only when the *user* could explain the design to a teammate without scrolling back. Not when you understand it. When they do.

**If the user pushes to skip Phase 0** ("just write it, I know what I want"), ask one tripwire question: *"In one sentence: who is this for, and what does success look like?"* Hesitation, a paragraph, or a re-frame means Phase 0 still needs to happen. Don't skip on confidence alone.

**Walk the design tree.** Resolve dependencies one decision at a time. Earlier decisions constrain later ones, so name the dependency before each question to make the structure visible ("B depends on A, let me lock A first"). One question at a time, via `AskUserQuestion` with concrete options. Batches break the dependency structure.

**Lead every question with your recommended answer** (Principle #10: load context before suggesting), grounded in a specific CLAUDE.md principle, a file or pattern you found, or a prior `docs/solutions/` entry. The user agrees, redirects, or corrects, which is much faster than generating from scratch. Recommendations from vibes don't count; if you can't cite what's driving the recommendation, explore until you can.

**Explore before asking.** If the question is answerable by reading the codebase, an existing spec, or `docs/solutions/`, read it first. Only ask the user about what code can't tell you: product intent, priorities, trade-offs that depend on business context.

Probe through these lenses (skip what's already clear):
- What's the real problem? Is this the right framing, or a proxy for something more important?
- Who cares about this? What are they doing when they hit it?
- What triggered this? (customer feedback, bug, internal idea)
- What happens if we do nothing?
- Is there a simpler version that delivers most of the value?
- What would success look like?
- What's the end goal in one or two sentences? Concrete language, not categories: "first meaningful paint <2s on the prompts page" beats "speed optimization." Feeds the spec's `### Outcome` section so the rest of the body orients to the right thing.

When evaluating multiple approaches that need research (comparing APIs, libraries, architectural patterns), research each option on its own terms: read docs, check feasibility, identify trade-offs. Then compare and recommend. Route per Delegation above: quick scans the orchestrator does itself, and the trade-off evaluation goes to one deep-reasoning agent briefed with every option. Parallel research agents only if the orchestration policy allows fan-out.

**For Type 1 decisions** (hard to reverse: schemas, public API contracts, protocol and file-format choices), get an independent second opinion before locking: put the same question to two independent contexts in parallel (e.g. a fresh deep-reasoning agent and the coder agent), without showing either the other's answer, then synthesize. Two independent contexts catch what one context anchored on. Skip this for Type 2 decisions; a second opinion on reversible choices is ceremony.

**Temporal shape (for user-facing surfaces).** Resolve the four perception milestones as a design-tree node before exiting:

- **Promise paint** (T=0): what does the user see the moment they trigger this? Shell, header, status copy that confirms the system heard them.
- **First-evidence paint**: what's the first piece of real content, and at what T?
- **First-actionable paint**: what's the earliest moment the user can act on partial results? What's gated on full load that doesn't have to be?
- **Full paint**: when is everything done?

This resolves *before* the data architecture is decided. Temporal shape constrains what data architecture is feasible (streaming events, cache layers, parallelism, partial state). Data architecture does not constrain temporal shape. The reverse ordering is the most common cause of "shipped, then re-architected for speed" rework: a feature that's correct end-to-end but blocks the user at stage boundaries because no one specced what the user sees in the first second.

**Performance architecture (for features with non-trivial data flow).** Temporal shape names what the user sees when. This names how. Resolve as a design-tree node before exiting:

- **Where the work happens**: render/compute location (server, edge, client, background job). Mismatched location is the most common source of unnecessary latency.
- **Critical path**: count the round trips between user action and first-evidence paint. Each hop multiplies tail latency. Name what's serial because the dependency is real, vs serial because someone wrote it that way; convert the second case to parallel fan-out.
- **Data arrival shape**: streamed/progressive, batched, prefetched, lazy. For features with multiple data sources, fan-out + first-byte-stream beats wait-then-render.
- **Caching boundary**: pre-computed, per-request, per-session, per-user. Pick deliberately; don't default to per-request.
- **Optimistic vs pessimistic UI**: for actions likely to succeed, name what the UI assumes immediately and how it reconciles on response. For low-success or destructive actions, default to pessimistic.
- **Backpressure / failure on streams**: when streams exist, name what happens when the consumer is slow, when the stream stalls, when it errors mid-flight. User-visible behavior, not just technical handling.

**Verify external API behavior from official docs, not memory.** Performance decisions often hinge on API specifics: rate limits, batch endpoints, parallel call support, streaming availability, typical latency, response shape. When a performance choice depends on external API behavior, fetch official docs via `WebSearch` / `WebFetch` *now*, during the design tree (don't defer to Research). The spec reads confident on memory-based API claims; the build hits a missing batch endpoint or unexpected rate limit. Same self-deception tripwire as the Research section, surfaced earlier because performance specs are where memory-based guesses do the most damage.

Specs that mumble through performance ship features that "work but feel slow." Refactoring for performance after the fact is far more expensive than speccing it upfront.

**Surface implementation assumptions before exiting.** Skipping this finds misalignments at build time, where they cost 10x. Deliver a single message listing every implementation assumption you'll proceed with: which module/file you're extending, which patterns you'll follow, which is internal vs public surface, what's a new table vs a modified one. The right assumptions cost nothing to list; only the wrong ones cost time. Don't silently fill in ambiguity.

```
ASSUMPTIONS I'M MAKING:
1. [e.g., This extends the existing billing module, not a new one]
2. [e.g., Auth uses the withAuth wrapper from lib/auth]
3. [e.g., We're adding a new table, not modifying the existing one]
4. [e.g., This is internal-only, no public API surface]
→ Correct me now or I'll proceed with these.
```

Use `AskUserQuestion` to deliver. One round, not a multi-turn loop. The user corrects what's wrong and confirms what's right; you move on. The confirmed list goes into the spec as `### Assumptions`, right after Proposed approach. Chat doesn't survive into the build session, and the build re-reads this list after slice 1.

**Exit criteria (all must hold; the fourth applies only to user-facing surfaces):**
1. Scope is bounded: you both know what's in and what's out.
2. Major branches of the design tree are resolved, with no live question of the form "but what about X?"
3. The user can answer follow-up questions without scrolling. **Verify by asking one they haven't already been told.** If they hesitate or scroll, keep grilling. Don't proceed on "I think we're good."
4. **Temporal shape resolved (user-facing surfaces only).** All four perception milestones have concrete answers, and the user can name what's gated on partial vs full state.
5. **Implementation assumptions surfaced and confirmed.** The single-message list has been delivered and the user has corrected/confirmed.

## After Phase 0: write the spec

Phase 0 produced shared understanding. Every feature that made it past triage now gets a spec file, scaled to the task: a small feature gets a short spec (Outcome, acceptance criteria with proofs, file map, one slice), a new initiative gets the full format. Fixes already routed to `/eng-debug` at triage.

Why always a spec: spec and build are separate sessions. The build session starts from the file, not from this conversation, and the spec is also what `/eng-check` reviews the diff against and where the builder logs deviations. A short spec costs minutes; a build that re-derives the design from a half-remembered conversation costs the session.

Auto-spec on context pressure (below) is the safety net for any long session whose decisions would be lost to compaction. It is not a substitute for writing the spec here.

## Research (ground the spec in evidence)

Before writing the spec, gather concrete evidence from the codebase. This prevents the spec from being written on vibes. The proposed approach should reference real files, real patterns, and real constraints.

**Skip this step when the feature is small and the codebase is familiar enough that you already know the relevant files and patterns.** Don't launch agents to confirm what's obvious.

**Self-deception tripwire.** If you find yourself naming a library version, API signature, file path, function name, or pattern *from memory* rather than from a fetch or grep, stop and verify. Spec-from-vibes is the most common failure mode and the hardest to catch in review, because the spec reads as confident even when the underlying claim is unchecked.

**When the feature involves external technologies** (APIs, libraries, frameworks, services), verify current state from official sources before writing the spec. Use `WebSearch` and `WebFetch` to check official documentation for: current stable versions, current API signatures and capabilities, deprecations or breaking changes, and recommended patterns. Training data goes stale. Official docs don't. Never spec against assumed API behavior when you can verify it in 30 seconds.

Gather evidence on up to three concerns, through direct exploration, sub-agents, or both. Use your judgment on the approach; what matters is that all relevant concerns are covered before writing the spec. Route per Delegation above: codebase-fit and external-tech scans are mechanical (the orchestrator does them directly); edge-case and constraint analysis needs judgment (the deep-reasoning agent).

| Concern | What to find out | What you need |
| --- | --- | --- |
| **Codebase fit** | What existing patterns should this feature follow? What files will be touched or created? Is there code that already solves part of this? Also check `docs/solutions/` for prior art: past problems and solutions related to this feature's domain. | File paths with line numbers, relevant code snippets, the pattern to follow, and any relevant prior solutions |
| **Edge cases & constraints** | What inputs or states could break this? What happens when external dependencies fail? Are any decisions irreversible (DB schema, public APIs)? | Prioritized list of risks with severity (blocks build vs. handle later) |
| **External tech** *(only when the feature touches external dependencies)* | What's the current stable version? Have APIs changed? Are there deprecations or new recommended patterns? What does the official docs say vs. what training data assumes? | Verified versions, confirmed API signatures, links to relevant docs, and any gaps between assumed and actual behavior |

**Use the findings to ground the spec.** The "Proposed approach" section should reference the codebase agent's file paths and patterns. The "Edge cases & risks" section should incorporate the constraints agent's findings. Don't just append findings; weave them into the spec so the builder gets one coherent document.

## Spec writing

### Decide spec topology

**Default: one spec file, one build session, one PR.** The build ships the whole spec in one session. Inside that session the vertical slice (see Task breakdown) is the unit of commit and verification, not a separate PR, spec, or session.

Why one PR: splitting a feature into separate slice PRs doesn't reduce total review load. Several small slice PRs take more review rounds than one PR of similar total size, and they still land on main as one big integration merge. The real cost of splitting is integration branches, sub-spec files, and re-priming a session per slice. Large-context models remove the builder's context-budget reason to split. Per-slice commits keep the reviewability that small PRs were buying.

**Forced-split list.** Anything on this list becomes its own spec and its own PR, sequenced with `depends_on:`:
- Schema migration with backfill, or any destructive or irreversible data change. Ship the migration first, expand then contract.
- Changes to the auth, money, or publish mechanism itself: the auth flow or permission model, payment or billing logic, the publish or deploy pipeline. A feature that only *uses* existing auth, payments, or publishing stays in the one spec; the build treats those slices as risk slices and range-reviews them mid-build.
- Any acceptance criterion that depends on a post-deploy action (manual step, env change, external config).
- Cross-repo changes.
- A refactor bundled with a feature.
- Changes to something the user is actively running, where a restart or deploy is its own gate (the project's CLAUDE.md / AGENTS.md declares which systems these are).

Why these: each carries its own gate or blast radius (a deploy, a data state, a security review, another repo's CI) that shouldn't hide inside a feature PR or block it. A split item gets its own spec at `specs/<item>.md`, and the feature spec lists it in `depends_on:`. `/eng-build` refuses to start until every `depends_on:` spec is built and merged. Everything not on the list stays in the one spec, however large.

**Vertical slices, never horizontal layers.** Each slice ships *one thin capability end-to-end* (DB → API → UI for one flow). Layer splits (one piece for migrations, one for routes, one for UI) re-sequentialize the build and keep nothing testable until the last piece lands. Vertical slices keep every step independently testable. The forced-split migration is the one deliberate layer split: it ships first so the feature builds on the expanded schema.

### UX exploration (when the spec creates new UI)

Skip for backend-only, refactor, infra, migration, or doc-only specs. Skip for modifications to existing UI surfaces: the live app already is the sandbox; verify in the browser at build time.

For specs that create a **new** user-facing UI surface (new screen, new flow, new component category, new content surface), sandbox-first is the only path. Prose framings describe UX; sandboxes demonstrate it. Whole categories of UX failure (wrong density, wrong empty state, fake-feeling streaming, ambiguous primary action) only surface when you click through.

The purpose of this phase is **shared understanding of how it feels**, the UX equivalent of Phase 0. The prototype is the medium prose can't replace; the goal is not picking a framing, the goal is the user knowing what they're getting because they've clicked it.

Exploration is a step inside this spec session, before lock. It doesn't change topology: the feature is still one spec, one build, one PR, and the exploration's output becomes part of the spec.

**Exploration workflow:**

Each framing is the final shipped experience, not a fragment. Every screen the build will produce is reachable from within the prototype by navigation, not by asking. Visual fidelity matches what will ship: final type, spacing, color, motion, micro-interactions, hover states. If the user has to ask "can you also build X?" or "can you make Y match the design?" to evaluate a framing, it was incomplete; finish it before showing.

1. Build 2-3 framings against real fixtures in the project's dev/exploration area (per CLAUDE.md). The coder agent builds them, per the orchestration policy (see Delegation); parallel coders only if the policy allows. Markup volume is the pipeline's heaviest token sink and needs no orchestrator-tier reasoning: the orchestrator directs and judges, it never writes markup. Compose UI from the project's component library and conventions (per CLAUDE.md). Distill the relevant guidance from the project's design-quality skills into each build prompt (or run a polish pass with those skills after) to bring each framing to final fidelity before showing.
2. The user clicks through each framing themselves. They form their own opinion on which wins, not just receive your recommendation.
3. Apply any cross-framing tweaks the user surfaced while clicking through: a hover state from B that beats A's, a density choice worth porting, an optical-alignment fix the comparison made obvious. Most polish lived in step 1; this is the +1%. Lock after this pass.
4. Write the winners into the spec's `### UX exploration` section (or a linked file when it runs long): chosen framing, rejected alternatives, why, and the path to the prototype.

**The build links to the prototype** as the canonical source for interaction states. The spec's prose describes only what the prototype can't show (state machines, side effects, error semantics, server-side behavior). No re-describing the UX; the prototype is already the spec.

**Real fixtures means real fixtures.** Domain text from the actual product, realistic volumes (50 items, not 3), every state the build will hit: empty, error, slow network, very-long content, very-short content, partial loads. Lorem ipsum and 3-item lists hide whole categories of failure.

**Exit criteria (both must hold):**
1. The spec's UX exploration section captures the chosen framing, rejected alternatives, and why.
2. The user can articulate why the chosen framing wins without re-reading it. Not when you've made the case. When they've formed the opinion.

The cost (one sandbox cycle) is paid upstream where UX decisions are still cheap.

### Map the file structure first

Lock which files get created, modified, or tested before writing prose. This forces decomposition decisions early, when they're cheap, and gives the builder a clear map. The codebase fit research should inform this directly.

**What you need (ask only what's still missing after exploration):**
- What problem does this solve? (one sentence)
- Who is this for?
- What triggered this?
- How will you know this is done? (acceptance criteria; suggest defaults from CLAUDE.md principles if the user isn't sure)

Scale the spec to the task. Small feature → short spec, skip sections that don't apply. New initiative → full context.

**Apply the project's engineering principles while writing. The stress-test will catch what slips, but design-time awareness is cheaper:**
- Is this the simplest approach that solves the problem? (#1)
- Are we building for a real requirement or an imaginary one? (#2)
- Are any decisions irreversible (schema, public APIs, file formats)? Those deserve extra scrutiny. (#5)
- How will we verify this works: tests, build checks, browser? (#8)
- Will the builder understand why the code is structured this way? (#9)
- Does this decompose into vertical slices, with anything on the forced-split list pulled into its own spec? (#11)

**The spec format:**

Each spec opens with YAML frontmatter (the machine-readable contract `/eng-spec` and `/eng-build` read) followed by the markdown body. Frontmatter shape:

```yaml
---
title: "<human-readable>"
status: drafting           # exactly one word: drafting | specced | building | built
built: <YYYY-MM-DD>        # omit until /eng-build sets it (when status becomes built)
summary: <2–4 sentence what + why>
depends_on: [<specs that must be built and merged first, e.g. a forced-split migration spec>]
references: [<paths the spec leans on>]
---
```

Frontmatter is load-bearing. `/eng-build` reads `status:`: `specced` starts a build, `building` resumes one, `built` halts as already built, anything else halts. It reads `depends_on:` and refuses to start until every listed spec shows `status: built` on the base branch. `status:` is exactly one word. History and narrative go in the body (`### Deviations`), never in the status field. Don't let the frontmatter drift from the body.

Then the markdown body:

```
## Feature: [name]

### Outcome
What this spec is trying to achieve, in your own words. The end goal that frames everything that follows. Not acceptance criteria (those come later), not a category. One or two concrete sentences answering "if this ships and works, what's better?"

Concrete language anchors the rest of the spec to a real target. "First meaningful paint <2s on the dashboard, no layout shift during data load" beats "make it feel fast." "User completes checkout without hesitating on the payment-failed step" beats "improve checkout UX." Vague outcomes produce specs that drift; concrete ones produce specs that converge.

A spec without an outcome is a spec searching for one. The rest of the body fills in for whatever's missing at the top.

### Context
Why this exists. The background, enough that someone reading this 3 months from now understands the motivation without asking anyone.

### What
One-line description of what this feature does.

### Who
Who this is for and what they're doing when they encounter this.

### User flow
The steps a user takes. Happy path and sad path (errors, empty states, slow connections). For user-facing surfaces, annotate the four perception milestones (promise paint, first-evidence, first-actionable, full) with concrete T-values, and call out which actions gate on partial vs full state. Each milestone names what the user sees and what they can do at that moment.

### Interaction states
*Include for features with UI. Skip for backend-only or refactors.*

Document each distinct state the user can encounter and what triggers transitions between them. The goal: the builder never invents UX on the fly, because every state they need to handle is already decided.

For each state: what the user sees, what causes it, and where it goes next. Use whatever format fits: a table, a list, a state diagram in words. What matters is that no state is left to the builder's imagination. Pay special attention to: what does "loading" look like? What does the user see when something fails? What happens on empty/first-use?

### UX exploration
*Include when the spec creates new UI (see UX exploration above). Skip otherwise.*

Chosen framing, rejected alternatives, why, and the path to the prototype. The prototype is the canonical source for interaction states.

### Acceptance criteria
- [ ] [concrete, verifiable criterion]. Proof: [test name, command + expected result, or browser step]

**Every criterion names its proof.** The test that covers it, the command and what it should print, or the browser step that shows it. The build reports each criterion ticked with that proof, and a tick without proof is not a pass, so a criterion that can't name a proof isn't done being written.

**The vague-criterion test.** If a criterion contains words like *graceful*, *properly*, *as expected*, *fast*, *clean*, *intuitive*, it is not yet a criterion. Reframe to a measurable condition or delete it. This is the single highest-leverage check in the spec; vague acceptance is what lets a feature ship "done" while still being broken.

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
The prioritized list of what actually matters. For each:
- What could go wrong
- How to handle it
- What's explicitly not worth handling yet, and why

For user-facing errors, be specific about the UX: what does the user see (toast, inline message, modal, chat message), what system action happens (retry, skip, abort), and how the user recovers. "Handle gracefully" is not a spec. It's a wish.

### Proposed approach
- Existing code: relevant files and patterns already in use (reference real paths)
- File structure: exact files to create or modify, following project conventions
- Key decisions: what was chosen, what was rejected, and why (this is the decision record; future you will thank present you for writing the "why"). Label each decision **Type 1** (hard to reverse: schemas, public APIs, protocol choices, file formats that others will consume) or **Type 2** (reversible: naming, tool cardinality, internal ordering, anything a grep-and-edit fixes in an hour). Type 1 deserves extra scrutiny in the rationalization check; Type 2 can change during build without pulling the builder back to the spec table
- Dependencies: what could block this (external APIs, other teams, migrations)

**Code contracts** *(required when the spec introduces new exported functions on the capability path: anything an external caller, agent, or orchestrator might invoke)*: Specify the signature with named input + output types using the project's contract convention (Zod, Pydantic, serde, OpenAPI; check CLAUDE.md), plus a 2–3 line pseudocode body. The stress-test gate is verdict-blocking on this: a "TypeScript interface" or "we'll add validation later" doesn't count. Write the contract now; deferring to build is a Type 1 decision, and that's what reshape PRs are made of.

**Data flow** *(include when the feature crosses 2+ system boundaries)*: Show how data moves from trigger to destination with a simple arrow chain like `user click → frontend handler → POST /api/foo → server handler → database → SSE event → frontend update`. Makes explicit who is responsible for what at each boundary. Prevents "I thought that happened on the other side."

### Assumptions
The implementation assumptions confirmed at the end of Phase 0, one numbered line each (which module is extended, which patterns are followed, internal vs public surface, new vs modified table). The build re-reads this list, together with the Type 1 key decisions, after slice 1.

### Rationalization check
The stress-test gate runs the full rationalization scan with explicit action. Self-check before firing it: scan the draft for "we can always refactor later," "it's just a prototype," "we might need this someday," "everyone does it this way," "no time to do it right." Each phrase is a placeholder for an unmade decision. Name the decision now, or expect the gate to flag it.

### Out of scope
What this feature explicitly does NOT include.

### Deviations
*Empty at spec time.* The builder appends one bullet per deviation from this spec: what changed, and the evidence that forced it (failing test, API response, what slice 1 revealed).
```

## Stress-test (Principle #7): mandatory before lock, auto-loop until clean

`/eng-build` starts a build only on `status: specced` (and resumes one only at `status: building`), and only when the `## Stress-test verdict` heading is `ready to build`. The spec is saved to disk with `status: drafting` before the first stress-test fires. Iteration patches the file in place via `Edit`. The clean verdict promotes `status` to `specced` and embeds the verdict heading.

Once the spec body and task breakdown are drafted, write the file to disk with `status: drafting` in the frontmatter. Then call the `Skill` tool with `skill: eng-stress-test` and pass the saved spec path or content inline, alongside the engineering principles you're checking against and the codebase paths/snippets you grounded the draft in. Saving before stress-test protects the spec from context compaction and lets iteration use precise `Edit` calls instead of full re-drafts. Same flow fires for any re-run after a material draft edit.

`/eng-stress-test` walks the engineering principles + first-of-kind patterns and returns the verdict as a chat response. It does **not** modify any file. The response is one of two shapes:

- **Clean verdict:** verdict is `ready to build`, optionally followed by a short "What's load-bearing in this spec" paragraph and a `Build-time items:` list of Type 2 concerns.
- **Working verdict:** verdict is `address these first` or `rethink approach`, followed by 3–7 prioritized concerns.

Every concern carries a label: **Type 1** (hard to undo once shipped: schemas, public contracts, data loss, security exposure, money) or **Type 2** (a grep-and-edit fix at build time with no lasting harm), plus **fact** when it contradicts something measured or verified, and **blocking** when the build can't start correctly without it resolved. The labels are what the loop triages on.

**Auto-loop until clean.** Asking the user to approve each round is friction without judgment. The patches are spec edits the AI was already going to draft from prior context. Run the loop autonomously up to 3 patch rounds.

**Patch only what's crucial.** Crucial means Type 1, a contradiction of a measured or verified fact, or verdict-blocking. Reversible (Type 2) concerns don't earn extra patch rounds: anything a grep-and-edit fixes at build time can be fixed then. Don't run extra rounds chasing a spotless verdict. Quality still wins on irreversible things; this is about not gold-plating reversible ones.

1. **Triage the verdict by reversibility.** Sort its concerns into crucial (labeled Type 1, fact, or blocking) and Type 2.
2. **Patch the crucial concerns via `Edit`.** Update the relevant sections: Outcome, What, User flow, Acceptance criteria, Edge cases, Key decisions, Assumptions, Performance architecture, Tasks. Each round is one or more `Edit` calls against the saved file; the file at any moment reflects the current draft. Track per round in a running ledger (concern title + section patched), needed for the end-of-loop digest.
3. **Park the Type 2 concerns without patching.** For each, either keep it as a build-time item (one line on which slice or section handles it) or skip it with one line of reasoning. Both go in the ledger; the build-time items get embedded under the verdict at promotion.
4. **Re-fire `/eng-stress-test`** against the updated file, only if step 2 patched something. New verdict returns in chat.
5. **If the verdict is `ready to build`, or its only open concerns are Type 2**, exit the loop and continue to promotion + digest. A verdict whose open items are all reversible counts as clean enough to promote; its Type 2 items join the build-time list.
6. **If the verdict is `address these first` with a crucial concern open**, return to step 1. Counts against the round budget. Rounds that would only touch Type 2 items never run, so they never count.
7. **Otherwise, escalate to the user** (see escalation criteria below). Do not silently continue.

**Escalation criteria. Stop the loop and surface to the user when any of these hit:**
- **Verdict is `rethink approach`.** The stress-test thinks the architecture is wrong, not the prose. That's a structural disagreement that needs the user, not another patch round.
- **Round budget exhausted (3 patch rounds).** Three rounds of `address these first` on crucial concerns without converging usually means a concern is being papered over rather than fixed. Stop and ask.
- **Two-round tripwire.** If the same crucial concern (same citation or same diagnosis) reappears across two consecutive rounds, the spec has a structural problem, not a wording problem. Polishing prose around an unsound design produces a clean verdict on a spec that still ships bugs. Stop and redo the design with the user.

When escalating, present: the unresolved concerns, how many rounds ran, what was patched in each, and the recommendation (`rethink approach` → redesign; max-rounds → which concern is sticky and why; tripwire → which concern repeated and what structural change might fix it).

**End-of-loop digest (clean exit).** When the loop converges to `ready to build`, produce a 2–4 line summary in chat covering:
- How many rounds ran.
- Each concern addressed, one phrase per concern, with the section it was patched into.
- Type 2 items parked: how many became build-time items and how many were skipped (one phrase of reasoning each).
- One line on what's load-bearing (lifted from the clean verdict, not re-derived).

The digest is the audit trail. The user reads it in 5 seconds to confirm nothing landed they'd want to redirect, but it doesn't gate progression. Keep it terse.

When the verdict is clean, promote `status: drafting` to `status: specced` in the frontmatter and embed the verdict heading, the load-bearing paragraph (if any), and the `Build-time items:` list (if any) in a single `Edit` call. Shape:

```
## Stress-test verdict
**ready to build**

<load-bearing paragraph, only when something would surprise a re-reader>

Build-time items:
- <Type 2 concern> (<cited section>). <which slice or section handles it at build time>
``` Then move to spec lock. The `status: specced` file with one verdict heading is the contract; the build session reads only this.

Do not commit the file until promotion is done. The commit captures the clean state, not the iteration trail.

Do not write code until the verdict is clean.

## Auto-spec on context pressure

This is the safety net for any long session. When a session approaches its context limit, the AI auto-creates or updates the spec from accumulated decisions in the conversation, so re-priming after `/compact` or in a new session is fast and faithful.

**Applies to all sessions, not just `/eng-spec` invocations.** Build sessions, debug sessions, design conversations: any session whose decisions would be lost to compaction. For sessions that started without a spec (debug, design), the spec is AI memory, materialized lazily.

**Trigger conditions (any of):**
- **Context window crosses 75%.** Buffer before auto-compact (~85–90%) so the write completes before the source conversation is collapsed. The AI tracks its own context-window usage; act on it proactively, don't wait for the user to notice.
- **User invokes `/compact` or `/clear`.** Run the auto-spec write *before* the compaction, not after. After, the source conversation is gone.
- **User says "save the context" or equivalent.** Verbal trigger overrides any threshold; fire immediately.
- **Session-end signals from the runtime** (e.g., `SessionEnd` hook): catch genuine session ends, not just compaction.

**First creation vs subsequent updates need different friction:**

- **First creation.** Work was supposed to be single-session, but context filled up. The spec didn't exist yet. The AI now creates it for the first time, encoding the canonical decision set from the conversation. **Notify the user briefly with what's being encoded:**

  ```
  Creating spec at specs/<feature>.md. Context is approaching 75% and the work has outgrown one session. Capturing as canonical:
  - Outcome: <one line>
  - Locked decisions: <count, with one-phrase summaries>
  - Open questions: <count>
  Redirect now if anything looks wrong; otherwise proceeding.
  ```

  Don't block on user input. If the user wants to redirect, they will. If silence, proceed. The notification is the audit point: after `/compact` the source conversation is gone, so this is the user's only chance to catch a wrong encoding.

- **Subsequent updates.** Spec already exists. Run silently, then drop a 3–4 line diff summary in chat:

  ```
  Spec updated: locked D7 (chose <X> over <Y>), marked AC3 resolved, added "behavior under stale auth token" to open questions.
  ```

  No permission ask, no blocking. User reads, redirects if needed, otherwise work continues.

**Format: lean AI-memory shape.** Auto-spec writes produce the lean format below, not the heavy human-doc format from `## Spec writing`. The reader is the AI itself across boundaries; narrative sections are overhead.

```yaml
---
title: <human-readable>
status: building          # auto-spec creates at building, not drafting: work is already in flight
purpose: ai-memory        # signals lean format
references: [<paths>]
---
```

```
## Outcome
<one or two concrete sentences. What's better when this ships and works.>

## Locked decisions
- **D1**: <chose X over Y>. Why: <one-line reason>. Rejected: <one-phrase>.
- **D2**: ...

## Acceptance criteria
- [ ] <concrete, verifiable>
- [x] <ones already met>

## File map
- `path/to/file.ts`: <one line on purpose>
- ...

## Current state
<2–4 lines: what's built, what's next, any open thread (failing test, blocked decision, mid-refactor file).>

## Open questions
- <unresolved decision>
- ...
```

That's it. No Context, no Who, no User flow as prose, no Interaction states section, no Rationalization check section. The AI doesn't need them; they're optimization for human readers who aren't reading.

**What gets updated, not rewritten.** Subsequent updates patch sections that changed:
- Locked decisions: append new entries, don't rewrite old ones (the audit trail matters).
- Acceptance criteria: tick `[x]` on completed, append new criteria if discovered.
- Current state: rewrite (this section is always a snapshot).
- Open questions: remove resolved, append new.
- Outcome and File map: rarely change; touch only on real shifts.

**When a full-format spec already exists** (a build session running from a `specced` file): don't convert it to the lean format. Add or rewrite a `## Current state` section at the end of the spec (what's built, which slice is next, any open thread) and log any change from the spec in `### Deviations`. That section is the checkpoint a fresh session, or a fresh coder agent, resumes from.

**The failure mode to watch.** Silent miscoding: the AI writes the wrong decision into "locked decisions" and the user doesn't catch it before `/compact` collapses the source conversation. Mitigation: every update shows the diff inline (above). If the diff line says "locked D7 (chose X over Y)" and you remember choosing Y over X, redirect immediately. Worth being a little paranoid about reading the diff lines.

**No stress-test on auto-spec writes.** The lean format isn't the kind of artifact stress-test is designed for (no User flow to cross-check against acceptance, no full Edge cases section). The conversation already stress-tested the design implicitly through Phase 0 and back-and-forth. Auto-spec captures the result; it doesn't re-validate it.

**When the spec graduates.** If accumulated work is being handed to a teammate or open-sourced, auto-spec's lean format may need expansion to the heavy format for human readers. That's a one-time conversion the user invokes explicitly: *"expand specs/<feature>.md to full format for review."* Default is lean; expansion is the exception.

## Task breakdown

Break the approved spec into discrete, buildable tasks, grouped into slices. A slice is one thin capability end-to-end (schema + API + UI for one flow). The build ships every slice in one session and one PR; each slice ends in one commit that builds and passes tests on its own, so the PR can be reviewed, bisected, and reverted slice by slice.

```
#### Slice 1: [name: the capability it delivers]
- [ ] Task: [description]
  - Acceptance: [what must be true when done, with its proof]
  - Verify: [how to confirm: test command, build, browser check]
  - Files: [which files will be created or modified]
  - Depends: [which tasks must complete first, or "none" if independent]

#### Slice 2: [name]
- [ ] Task: ...
```

The `#### Slice N: <name>` headings are the whole mechanism. No extra frontmatter; the build reads the slices in order and the PR body's slice map is built from them.

**Order slice 1 to fail fast.** Slice 1 surfaces the riskiest assumption or the Type 1 decision most likely to be wrong: the unverified API behavior, the new schema, the streaming path. The build runs an assumptions check-in after slice 1, and a slice 1 that only builds the easy parts wastes it.

One coder builds the slices in order. Parallelism happens only across separate specs linked by `depends_on:` (e.g. two forced-split specs with no dependency on each other), and only if the orchestration policy allows parallel coders.

**Slice vertically, not horizontally.** Each task should deliver a working, testable path through the feature, not a horizontal layer.

Bad: Task 1 = all database tables, Task 2 = all API endpoints, Task 3 = all UI components, Task 4 = connect everything.
Good: Task 1 = user can create account (schema + API + UI), Task 2 = user can log in, Task 3 = user can create a task.

Vertical slices keep the feature working and testable at every step. Horizontal layers leave you with nothing testable until the last task.

**When to break a task down further:**
- You can't describe acceptance criteria in 3 or fewer bullets
- It touches 2+ independent subsystems (e.g., auth and billing)
- You wrote "and" in the task title (that's two tasks)
- Its slice can't end in one commit that builds and passes tests on its own (split the slice)

Guidelines:
- Order tasks by dependency, then by risk: build foundations first, but put high-risk tasks early. Fail fast before investing in the easy parts
- Each task should touch a small number of files (aim for ~5 or fewer)
- Every task has a verify step; no task is "done" without proof
- For small features, one slice with 2-3 tasks is fine. Don't over-decompose

This task list becomes what `/eng-build` reads. The clearer it is, the less judgment the builder needs to apply.

Save the spec file to disk with `status: drafting` in the frontmatter, body + task list together, at `specs/[feature-name].md` (kebab-case, create the directory if needed). The file is the durable artifact from this point on; iteration happens via `Edit`, not by re-drafting in conversation.

**Fire the stress-test gate per the Stress-test section above.** Iteration patches the file in place. Once the verdict is clean, the final `Edit` promotes `status: drafting` to `status: specced` and embeds the verdict heading. The `status: specced` file is the contract between planning and execution; `/eng-build` won't start a new build on anything else.

**Lock the spec once promoted to `status: specced`. Specs you can't stop editing are specs no one builds from.** Refinement loops that don't close cause spec drift; resist re-opening every time a new article or idea arrives. Define a lock point in the Out-of-scope section as `re-spec trigger: [criterion]`. Candidates: "first slice has been built," "non-AI reviewer has signed off," "no external input has changed the spec across N consecutive reads." Pick one per spec. Once locked, spec changes happen as targeted edits during build with commit messages explaining what evidence triggered the change. Not as re-opened planning sessions.

**Promote cross-phase Type 1 decisions at lock time.** If the project maintains a living cross-phase decision log (check CLAUDE.md / AGENTS.md for the project's convention), scan the spec's Type 1 decisions before declaring lock. For any that affect later phases (schema changes, contract picks, protocol decisions, architectural commitments), confirm with the user and promote them to the log now. Lock-time catches what post-build promotion forgets: decisions are fresh, the spec hasn't shipped, the canonical text is still in flux. Type 2 (reversible) decisions stay inline only; not worth the log.

**Offer the next step.** Once locked, surface the build kickoff: *"Spec ready at `specs/<feature>.md`. Run `/eng-build specs/<feature>.md` now, or come back when you're ready."* If the spec has `depends_on:` entries that aren't built yet, name the one to spec or build first. Don't auto-fire: the spec/build session boundary is intentional, but the user shouldn't have to guess the next command.

**Handoff messages carry operational state only:** the skill invocation, the branch, and any tree caveats (uncommitted files, a dev server that must be running). Three lines is usually enough. The spec carries the rest; restating decisions in the handoff creates a second source that drifts.
