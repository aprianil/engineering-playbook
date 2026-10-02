---
name: eng-spec
description: Write a feature spec before building anything, then stress-test it with a fresh sub-agent until it's ready to build. Planning session, no code gets written. Every feature past fix triage gets a spec scaled to its size; default is one spec, one build session, one PR, with vertical slices as the unit of commit inside it. `/eng-spec stress <path>` runs only the fresh-eyes stress test on an existing spec or plan and returns the verdict in chat.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, WebSearch, WebFetch
argument-hint: [feature-name | stress <spec-or-plan-path>]
---

Turn a loose feature description into a spec that anyone (human or AI) can build from without follow-up questions. This is a planning session. No code gets written. If the spec is clear, execution is easy.

## Modes

- **`/eng-spec <feature>`** (default): triage, Phase 0, spec, stress-test loop, lock.
- **`/eng-spec stress <path>`**: stress-test an existing spec or plan. Read the file once, spawn the stress-test sub-agent (see Stress test), and return its verdict in chat. Don't edit the file. Skip checks that don't fit a plan that isn't in spec format.

## Triage: is this a feature, or a fix?

**Run this check first.** This skill is for greenfield work: new surface, new flow, new capability, new architectural decision. For known bugs, the bug is the spec; routing fixes through this pipeline manufactures ceremony where there's no design to make. This category mismatch is the single biggest source of session drag in fix-heavy phases.

Exit immediately if any signal fires:
- Branch name contains `fix/`, `hotfix/`, `bug/`, `followup/`.
- User describes it as "X is broken," "rerun found Y," "QA caught Z," "data quality issue," "this doesn't work," "fix the issue in N."
- No new surface, flow, or capability. Just a known-wrong behavior to make right.
- The would-be spec collapses to one paragraph: what's broken + what fix to apply. If you can't fill Outcome, User flow, and Edge cases distinctly, this isn't a feature.

Exit line: *"this looks like a fix, not a feature. fixing it directly (reproduce, root cause, guard test) + /eng-check. say 'spec it anyway' if you want the full pipeline."*

User override wins. Uncritical default-to-spec on fix work is the bug this triage exists to kill.

**Past triage:** read the project's CLAUDE.md (suggest `/eng-init` if none exists) and explore the codebase enough to ground the work in real paths, patterns, and conventions.

**Delegation.** Follow the orchestration policy in CLAUDE.md (user-level or project). Default when none is stated: the orchestrator does quick mechanical scans itself; one deep-reasoning agent handles trade-off evaluations; implementation and markup go to one long-lived coder agent kept alive with `SendMessage`. Use Codex only when the project's CLAUDE.md / AGENTS.md names it.

**How much Phase 0?** Brief when the user gives specific acceptance criteria, references patterns to follow, and bounds the scope (still verify shared understanding). Full grill when they say "something like...", "what if we...", or seem unsure what they want.

## Phase 0: Reach shared design concept

The goal is **shared understanding**, not a saved file. The design concept (Brooks's invisible theory of what you're building) lives in the conversation.

**Hard rules:**
- Do not call `Write`. Nothing gets saved this phase.
- Do not enter plan mode. You don't yet know what to plan.
- Exit only when the *user* could explain the design to a teammate without scrolling back. Not when you understand it.

**If the user pushes to skip** ("just write it, I know what I want"), ask one tripwire question: *"In one sentence: who is this for, and what does success look like?"* Hesitation, a paragraph, or a re-frame means Phase 0 still needs to happen.

**Walk the design tree.** Resolve dependencies one decision at a time, naming the dependency before each question ("B depends on A, let me lock A first"). One question at a time via `AskUserQuestion` with concrete options. Batches break the dependency structure.

**Lead every question with your recommended answer** (Principle #10), grounded in a specific CLAUDE.md principle, a file or pattern you found, or a prior `docs/solutions/` entry. If you can't cite what drives the recommendation, explore until you can.

**Explore before asking.** If the codebase, an existing spec, or `docs/solutions/` can answer it, read it. Ask the user only about product intent, priorities, and business trade-offs. Pin the end goal in concrete language ("first meaningful paint <2s on the prompts page", not "speed optimization"); it becomes the spec's `### Outcome`.

When comparing approaches that need research (APIs, libraries, architectural patterns), research each on its own terms, then compare and recommend. The trade-off evaluation goes to one deep-reasoning agent briefed with every option.

**For Type 1 decisions** (see Labels), get an independent second opinion before locking: the same question to two independent contexts in parallel (e.g. a fresh deep-reasoning agent and the coder agent), neither seeing the other's answer, then synthesize. Skip for Type 2; a second opinion on reversible choices is ceremony.

**Temporal shape (user-facing surfaces).** Resolve the four perception milestones as a design-tree node:
- **Promise paint** (T=0): what the user sees the moment they trigger this.
- **First-evidence paint**: the first piece of real content, and at what T.
- **First-actionable paint**: the earliest moment they can act on partial results. What's gated on full load that doesn't have to be?
- **Full paint**: when everything is done.

This resolves *before* the data architecture. Temporal shape constrains what data architecture is feasible, not the reverse. The reverse ordering is the most common cause of "shipped, then re-architected for speed."

**Performance architecture (features with non-trivial data flow).** Temporal shape names what the user sees when; this names how:
- **Where the work happens**: server, edge, client, background job.
- **Critical path**: count round trips from user action to first-evidence paint. Separate serial-because-dependent from serial-because-someone-wrote-it-that-way, and fan out the second.
- **Data arrival shape**: streamed, batched, prefetched, lazy.
- **Caching boundary**: pre-computed, per-request, per-session, per-user. Pick deliberately.
- **Optimistic vs pessimistic UI**: optimistic for likely-success actions (name how it reconciles), pessimistic for low-success or destructive ones.
- **Backpressure / failure on streams**: what the user sees when the consumer is slow, the stream stalls, or it errors mid-flight.

**Verify external API behavior from official docs, not memory.** When a decision depends on rate limits, batch endpoints, parallelism, streaming, latency, or response shape, fetch the docs now with `WebSearch` / `WebFetch`. Same for library versions, signatures, and deprecations at Research time. A spec reads just as confident on a memory-based claim, and the build is where the missing batch endpoint shows up.

**Surface implementation assumptions before exiting.** One message via `AskUserQuestion`, one round:

```
ASSUMPTIONS I'M MAKING:
1. [e.g., This extends the existing billing module, not a new one]
2. [e.g., Auth uses the withAuth wrapper from lib/auth]
3. [e.g., We're adding a new table, not modifying the existing one]
4. [e.g., This is internal-only, no public API surface]
→ Correct me now or I'll proceed with these.
```

The confirmed list goes into the spec as `### Assumptions`. Chat doesn't survive into the build session, and the build re-reads this list after slice 1.

**Exit criteria (all must hold):**
1. Scope is bounded: in and out are both known.
2. Major branches of the design tree are resolved; no live "but what about X?"
3. The user can answer follow-up questions without scrolling. **Verify by asking one they haven't been told.** Don't proceed on "I think we're good."
4. Temporal shape resolved (user-facing surfaces only).
5. Implementation assumptions surfaced and confirmed.

## After Phase 0: always a spec

Every feature past triage gets a spec file, scaled to the task: a small feature gets Outcome, acceptance criteria with proofs, file map, one slice; a new initiative gets the full format. Spec and build are separate sessions. The build starts from the file, `/eng-check` reviews the diff against it, and the builder logs deviations in it.

## Research

Ground the spec in evidence before writing. Skip when the feature is small and you already know the relevant files and patterns.

**Self-deception tripwire.** If you're naming a library version, API signature, file path, function name, or pattern *from memory*, stop and verify with a fetch or grep. Spec-from-vibes is the most common failure mode and the hardest to catch in review.

Cover up to three concerns. Codebase fit and external tech are mechanical (the orchestrator does them); edge cases need judgment (the deep-reasoning agent).

| Concern | What to find out | What you need |
| --- | --- | --- |
| **Codebase fit** | Patterns to follow, files touched or created, code that already solves part of this, prior art in `docs/solutions/` | File paths with line numbers, the pattern to follow, relevant prior solutions |
| **Edge cases & constraints** | Inputs or states that break it, external dependency failures, irreversible decisions | Prioritized risks: blocks build vs. handle later |
| **External tech** *(only when external dependencies are involved)* | Current stable version, API changes, deprecations, docs vs. training data | Verified versions and signatures, doc links, gaps between assumed and actual |

Weave the findings into Proposed approach and Edge cases rather than appending them.

## Spec writing

### Decide spec topology

**Default: one spec file, one build session, one PR.** Inside the build, the vertical slice is the unit of commit and verification, not a separate PR, spec, or session.

Why one PR: separate slice PRs don't reduce total review load. They take more review rounds, still land as one big integration merge, and cost integration branches, sub-spec files, and a re-primed session per slice. Per-slice commits keep the reviewability small PRs were buying.

**Forced-split list.** Anything on this list becomes its own spec and its own PR, sequenced with `depends_on:`:
- Schema migration with backfill, or any destructive or irreversible data change. Ship the migration first, expand then contract.
- Changes to the auth, money, or publish mechanism itself: the auth flow or permission model, payment or billing logic, the publish or deploy pipeline. A feature that only *uses* existing auth, payments, or publishing stays in the one spec; the build treats those slices as risk slices and range-reviews them mid-build.
- Any acceptance criterion that depends on a post-deploy action (manual step, env change, external config).
- Cross-repo changes.
- A refactor bundled with a feature.
- Changes to something the user is actively running, where a restart or deploy is its own gate (the project's CLAUDE.md / AGENTS.md declares which systems these are).

Each carries its own gate or blast radius (a deploy, a data state, a security review, another repo's CI) that shouldn't hide inside a feature PR or block it. A split item gets its own spec at `specs/<item>.md`, listed in the feature spec's `depends_on:`. `/eng-build` refuses to start until every `depends_on:` spec is built and merged. Everything not on the list stays in the one spec, however large.

**Vertical slices, never horizontal layers.** Each slice ships one thin capability end-to-end (DB → API → UI for one flow), so every step is testable. Layer splits keep nothing testable until the last piece lands. The forced-split migration is the one deliberate layer split: it ships first.

### UX exploration (when the spec creates new UI)

Skip for backend-only, refactor, infra, migration, or doc-only specs, and for changes to existing UI (the live app is already the sandbox; verify in the browser at build time).

For a **new** user-facing surface (screen, flow, component category, content surface), sandbox-first is the only path. Prose describes UX; sandboxes demonstrate it. Wrong density, wrong empty state, fake-feeling streaming, and ambiguous primary actions only surface when you click through. The goal is the user knowing what they're getting because they've clicked it. Exploration happens inside this spec session and doesn't change topology.

Each framing is the final shipped experience, not a fragment: every screen the build will produce is reachable by navigation, at shipping fidelity (type, spacing, color, motion, hover states). If the user has to ask "can you also build X?" to evaluate it, it was incomplete.

1. The coder agent builds 2-3 framings against real fixtures in the project's dev/exploration area, composed from the project's component library. The orchestrator directs and judges; it never writes markup. Distill the project's design-quality skills into each build prompt, or run a polish pass with them, before showing.
2. The user clicks through each framing and forms their own opinion.
3. Apply cross-framing tweaks they surfaced (a hover state from B that beats A's), then lock.
4. Write the result into `### UX exploration`: chosen framing, rejected alternatives, why, path to the prototype.

**Real fixtures means real fixtures:** actual product text, realistic volumes (50 items, not 3), and every state the build will hit: empty, error, slow network, very long and very short content, partial loads.

The prototype is the canonical source for interaction states; the spec's prose covers only what it can't show (state machines, side effects, error semantics, server behavior). Exit when the section is written and the user can say why the chosen framing wins without re-reading it.

### Map the file structure first

Lock which files get created, modified, or tested before writing prose. This forces decomposition early, when it's cheap. Scale the spec to the task; skip sections that don't apply.

Apply the project's principles while writing (the stress test catches what slips): simplest approach (#1)? real requirement (#2)? irreversible decisions (#5)? how it's verified (#8)? will the builder understand the structure (#9)? vertical slices, forced-split items pulled out (#11)?

### The spec format

YAML frontmatter (the machine-readable contract `/eng-build` reads), then the markdown body:

```yaml
---
title: "<human-readable>"
status: drafting           # exactly one word: drafting | specced | building | built
built: <YYYY-MM-DD>        # omit until /eng-build sets it
summary: <2-4 sentence what + why>
depends_on: [<specs that must be built and merged first>]
references: [<paths the spec leans on>]
---
```

`/eng-build` reads `status:`: `specced` starts a build, `building` resumes one, `built` halts, anything else halts. It reads `depends_on:` and refuses to start until every listed spec shows `status: built` on the base branch.

**`status:` is exactly one word from that list and nothing else.** No dates, slice progress, measurements, or notes after it, not even in parentheses. A status line with anything after the word fails the build's check. History goes in `### Deviations`, progress goes in `## Current state`.

```
## Feature: [name]

### Outcome
One or two concrete sentences: if this ships and works, what's better? "First meaningful paint <2s on the dashboard, no layout shift during data load," not "make it feel fast."

### Context
Why this exists, enough that someone reading it in 3 months understands the motivation.

### What
One-line description.

### Who
Who this is for and what they're doing when they hit it.

### User flow
Happy path and sad path (errors, empty states, slow connections). For user-facing surfaces, annotate the four perception milestones with concrete T-values and what gates on partial vs full state.

### Interaction states
*UI features only.* Every state the user can hit: what they see, what causes it, where it goes next. Loading, failure, and empty/first-use especially. The builder never invents UX on the fly.

### UX exploration
*New UI only.* Chosen framing, rejected alternatives, why, path to the prototype.

### Acceptance criteria
- [ ] [concrete, verifiable criterion]. Proof: [test name, command + expected result, or browser step]

**Every criterion names its proof.** The build reports each criterion ticked with that proof, and a tick without proof is not a pass, so a criterion that can't name a proof isn't done being written.

**The vague-criterion test.** If a criterion contains *graceful*, *properly*, *as expected*, *fast*, *clean*, *intuitive*, it is not yet a criterion. Reframe to a measurable condition (confirm the target with the user) or delete it. This is the single highest-leverage check in the spec.

### Edge cases & risks
Prioritized. For each: what could go wrong, how to handle it, what's explicitly not worth handling yet and why. For user-facing errors name what the user sees, what the system does (retry, skip, abort), and how they recover.

### Proposed approach
- Existing code: relevant files and patterns (real paths)
- File structure: exact files to create or modify
- Key decisions: what was chosen, what was rejected, and why. Label each **Type 1** or **Type 2** (see Labels). Type 2 can change during build without pulling the builder back to the spec
- Dependencies: what could block this

**Code contracts** *(required for new exported functions on the capability path: anything an external caller, agent, or orchestrator might invoke)*: signature with named input + output types in the project's contract convention (Zod, Pydantic, serde, OpenAPI; check CLAUDE.md), plus a 2-3 line pseudocode body. A "TypeScript interface" or "validation later" doesn't count; the stress test blocks on it.

**Data flow** *(when the feature crosses 2+ system boundaries)*: an arrow chain like `user click → frontend handler → POST /api/foo → server handler → database → SSE event → frontend update`.

### Performance architecture
*Features with non-trivial data flow only.* The Phase 0 answers: where work happens, critical-path round trips (serial vs parallel), data arrival shape, caching boundary, optimistic vs pessimistic UI, stream failure behavior. `/eng-check` checks the code against this section.

### Assumptions
The implementation assumptions confirmed at the end of Phase 0, one numbered line each. The build re-reads these, with the Type 1 key decisions, after slice 1.

### Out of scope
What this feature explicitly does NOT include.

### Deviations
*Empty at spec time.* The builder appends one bullet per deviation: what changed, and the evidence that forced it.
```

## Task breakdown

Group tasks into slices. Each slice ends in one commit that builds and passes tests on its own, so the PR can be reviewed, bisected, and reverted slice by slice.

```
#### Slice 1: [name: the capability it delivers]
- [ ] Task: [description]
  - Acceptance: [what must be true when done, with its proof]
  - Verify: [test command, build, browser check]
  - Files: [created or modified]
  - Depends: [tasks that must complete first, or "none"]

#### Slice 2: [name]
- [ ] Task: ...
```

The `#### Slice N: <name>` headings are the whole mechanism: the build reads slices in order and the PR body's slice map is built from them.

**Order slice 1 to fail fast.** Slice 1 surfaces the riskiest assumption or the Type 1 decision most likely to be wrong: the unverified API behavior, the new schema, the streaming path. The build runs an assumptions check-in after slice 1, and a slice 1 that only builds the easy parts wastes it.

One coder builds the slices in order. Parallelism happens only across separate specs linked by `depends_on:`, and only if the orchestration policy allows parallel coders.

Break a task down further when its acceptance needs more than 3 bullets, it touches 2+ independent subsystems, its title has "and" in it, or its slice can't end in one green commit. For small features, one slice with 2-3 tasks is fine.

Save body + task list to `specs/<feature-name>.md` (kebab-case) with `status: drafting`. From here the file is the durable artifact; iterate with `Edit`, not by re-drafting in chat.

## Stress test (Principle #7): mandatory before lock

The builder shouldn't review their own plan. Spawn one fresh sub-agent with the `Agent` tool (it hasn't seen this conversation). Pass inline: the spec path or content, the engineering principles to check against, the codebase paths and snippets the draft is grounded in, and the stress-test instructions below. It returns a verdict in chat and never edits the file.

### Labels

Used by Phase 0, Key decisions, the stress test, and the loop. Defined once here:
- **Type 1**: hard to undo once shipped. Schemas, public contracts, protocol choices, file formats others consume, data loss or corruption, security exposure, money.
- **Type 2**: a grep-and-edit fix at build time with no lasting harm. Naming, copy, tool cardinality, internal structure and ordering, minor edge-case handling, over-planning.
- **fact**: the concern contradicts something measured or verified (official docs, a grep, a benchmark).
- **blocking**: the build can't start correctly without it resolved (missing I/O contract, a criterion with no home or no proof, an outcome no criterion verifies, a bundled forced-split item).

**Crucial** = Type 1, fact, or blocking.

### Stress-test instructions for the sub-agent

You are a fresh pair of eyes. You did not write this spec and have no attachment to its decisions. Don't re-read CLAUDE.md or explore the codebase in general; the caller did that. Grep only where a check needs it (checks 5 and 8). If only a path was passed, read the file once.

**High-yield checks, lead with these:**

1. **Acceptance ↔ approach traceability.** Point each criterion to where the approach implements it. A criterion with no home is a gap; an approach file that maps to no criterion is scope creep. Every criterion names its proof (test name, command + expected result, or browser step); flag each one that doesn't.
2. **Type 1 decisions.** Schemas, public API contracts, migrations, file formats others consume: explicit and locked, or hidden in "we'll figure it out"? Flag each one deferred to build. Cross-check `### Assumptions` against the approach: a contradicted assumption, or a Type 1 decision resting on an unconfirmed one, is verdict-affecting.
3. **I/O contract on capability functions (blocking).** New exported functions on the capability path must name input + output contracts inline in the project's convention. This passes:
   ```
   runFoo(input: FooInput) → FooResult
     FooInput  = Zod schema { jobId: string, mode: 'sync' | 'async', payload: JobPayload }
     FooResult = Zod schema { status: 'ok', data: ResultData } | { status: 'error', code: ErrorCode, message: string }
   ```
   "TypeScript interface," "validation later," "typed inputs" on a Zod-everywhere project, or a contract deferred to build all fail. Skip for pure infra consumed inside the same library.
4. **Edge cases that matter.** What hurts users or corrupts data if missed? External dependency failures (API down, partial migration, malformed LLM JSON, duplicate webhook delivery)? Concurrency? Where would a builder need to ask a follow-up? Security: unvalidated input, new routes without auth, leaking secrets?
5. **First-of-kind patterns.** Grep for whether this spec is first to introduce one, and check its known failure mode. Examples (the project's CLAUDE.md may list its own): new agent skill (layering boundary, frontmatter, role/tools/output contract); new agent tool (`rationale: z.string()` dropped, description skipped, naming drift); a migration with a new pattern (`RETURNS TABLE`, RLS on a new table, partial unique index, NOT NULL backfill); cron (overlap idempotency, failure alerting); webhook handler (signature verified *before* body read); new MCP tool surface (inline spec-fetch, context-gap-shaped inputs, per-org rate limits). Flag first-of-kind even when handled well.
6. **Performance architecture.** For user-perceived latency or non-trivial data flow, `### Performance architecture` must name every item from Phase 0. Missing or hand-waved is verdict-affecting. Flag API-behavior claims that read as memory rather than verified docs.
7. **Outcome ↔ acceptance.** The Outcome needs a measurable verification path in the criteria ("first paint <2s" needs an LCP measurement). Vague criteria on a measurable outcome are verdict-affecting.
8. **Slice order and split.** Slice 1 should surface the riskiest assumption; if not, name the slice that should go first. Flag any forced-split item bundled instead of split into its own spec. Don't push to split for size alone.

**Principle pass (faster, raise only specific concerns):** simplicity (#1, cut concepts and dependencies, not lines), YAGNI (#2), designed-upfront abstractions (#3), quality (#4: assumptions treated as verified facts; scope cuts are fine, quality cuts compound), over-planned Type 2 decisions (#5), compounding (#6), verification (#8), ownership (#9), project shape (the "good" and "bad" columns of the project's CLAUDE.md).

**Rationalization red flags.** "We can always refactor later," "it's just a prototype," "we might need this someday," "it's only a small addition," "everyone does it this way," "no time to do it right," "too late to change." Each hides an unmade decision. Name the decision. Type 1 means the verdict isn't clean; genuinely reversible means a legitimate Type 2 deferral.

**Anti-rubber-stamp.** A first-pass clean read is suspicious unless the spec is small; re-read once. Report judgment calls with their label rather than dropping them. Passing a Type 1 issue too readily is worse than one more round; a Type 2 judgment call never holds back `ready to build`.

**Specificity.** Every concern cites a section, line, AC#, task ID, or file. Concerns that could apply to any spec are noise; delete them. Don't repeat what the spec handles well or push complexity the task size doesn't need.

**Output.** Label every concern (see Labels). The verdict follows from crucial concerns alone:
- **Clean**: `**ready to build**` when no crucial concern is open. Type 2 concerns go under `Build-time items:`. Add a short "What's load-bearing in this spec" paragraph only when something would surprise a re-reader; default to omitting.
- **Concerns**: `**address these first**` with 3-7 items, crucial first, Type 2 after.
- **Rethink**: `**rethink approach**` when the architecture itself is wrong, not the prose.

One bullet per concern: bold name, citation, label in brackets, then diagnosis + fix in one flow. No sub-fields, no narrated failure chains. List order is the priority; name a single verdict-blocking item in the header. First-of-kind flags go under `Flags:` in the same format. No passing-item roll call.

```
**address these first** · 2 concerns (1 crucial, 1 Type 2), 1 verdict-blocking (Type 1 backward compat)

1. **Migration drops index without rebuild** (migration 0042, line 18) [Type 1 · blocking]. Old `idx_users_email` is dropped and not recreated; production queries fall back to seq scan. Fix: rebuild it in the same migration, concurrently if the table is large.
2. **Invite-failure toast copy unspecified** (User flow, step 4) [Type 2]. Fix: pick the copy in the slice that owns the invite form.

Flags:
- **First-of-kind webhook handler** (T4). Verify signature is checked before body parsing.
```

### The loop (default mode)

Run it autonomously, up to 3 patch rounds. Asking the user to approve each round is friction without judgment.

1. Sort the verdict's concerns into crucial and Type 2.
2. Patch the crucial ones in the saved file with `Edit`. Keep a ledger: concern + section patched.
3. Park Type 2 ones without patching: a build-time item (one line on which slice handles it) or a skip (one line why).
4. If step 2 patched anything, re-spawn a fresh stress-test sub-agent on the updated file.
5. If the verdict is `ready to build`, or its only open concerns are Type 2, exit and promote.
6. If a crucial concern is still open, go to step 1.

**Escalate to the user** instead of continuing when the verdict is `rethink approach`, when 3 patch rounds haven't converged, or when the same crucial concern reappears in two consecutive rounds (a structural problem, not a wording one). Present the unresolved concerns, the rounds run, what each patched, and your recommendation.

**Digest on clean exit:** 2-4 lines in chat: rounds run, each concern patched and where, Type 2 items parked vs skipped, and the load-bearing line from the verdict. It doesn't gate progression.

**Promote** in a single `Edit`: `status: drafting` → `status: specced`, plus this block:

```
## Stress-test verdict
**ready to build**

<load-bearing paragraph, only when something would surprise a re-reader>

Build-time items:
- <Type 2 concern> (<cited section>). <which slice or section handles it at build time>
```

`/eng-build` starts only on `status: specced` with that heading reading `**ready to build**`. Don't commit the file until promotion is done, and don't write code until the verdict is clean.

## Lock and hand off

**Lock the spec once it's `specced`.** Specs you can't stop editing are specs no one builds from. After lock, changes happen as targeted edits during build, logged in `### Deviations` with the evidence, not as re-opened planning sessions.

**Promote cross-phase Type 1 decisions.** If the project keeps a cross-phase decision log (check CLAUDE.md / AGENTS.md), confirm with the user and promote Type 1 decisions that affect later phases now, while they're fresh.

**Offer the next step:** *"Spec ready at `specs/<feature>.md`. Run `/eng-build specs/<feature>.md` now, or come back when you're ready."* If `depends_on:` entries aren't built, name the one to do first. Don't auto-fire; the session boundary is intentional.

**Handoff messages carry operational state only:** the skill invocation, the branch, and tree caveats (uncommitted files, a dev server that must be running). The spec carries the rest; restating decisions creates a second source that drifts.
