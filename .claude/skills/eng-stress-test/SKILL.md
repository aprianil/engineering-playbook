---
name: eng-stress-test
description: Stress-test a spec or plan with fresh eyes. Challenges assumptions, surfaces risks, catches overengineering, labels each concern Type 1 or Type 2 so the caller patches only what's irreversible, and checks that every acceptance criterion names its proof, slice 1 fails fast, and forced-split items aren't bundled. Mandatory before /eng-build can start. Returns the verdict as a chat response; eng-spec embeds the clean verdict in the spec on save.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash
argument-hint: [spec-file]
---

Stress-test a spec or plan. You are a fresh pair of eyes. You did not write this and you have no attachment to its decisions. Catching issues here is far cheaper than catching them during or after building.

## What you're given

`/eng-spec` invokes you with the spec saved to disk as `status: drafting`, and passes inline:
- The spec file path or full content (spec body + task list).
- The engineering principles to check against.
- The codebase paths and snippets the draft is grounded in.

Don't re-read CLAUDE.md, and don't explore the codebase in general. The caller already did that work, so go straight to challenging. Targeted grepping is allowed where a check needs it (high-yield check 5, first-of-kind patterns). If only a path was passed, read the file once, then proceed.

## High-yield checks: lead with these

These catch most real issues. Run them before the principle pass.

**1. Acceptance ↔ approach traceability.** For each acceptance criterion, point to where in the file structure and approach it gets implemented. Criteria with no clear home = gap in the plan. Files or components in the approach that don't map to any criterion = scope creep. Either is verdict-affecting. Also check that every criterion names its proof (a test name, a command and its expected result, or a browser step). A criterion with no proof can't be ticked honestly at build time; flag each one.

**2. Type 1 (irreversible) decisions.** Database schemas, public API contracts, data migrations, file formats other systems consume. Are they explicit and locked, or hidden inside "we'll figure it out"? Type 1 decisions deferred to build are the most expensive thing a spec can do: flag every one that isn't pinned down. Also cross-check the spec's `### Assumptions` against the approach: an assumption the Proposed approach contradicts, or a Type 1 decision resting on an assumption nobody confirmed, is verdict-affecting.

**3. I/O contract on capability functions (verdict-blocking).** If the spec introduces new exported functions on the capability path (anything an external caller, agent, or orchestrator might invoke), the spec must name input + output contract inline using the project's convention (Zod, Pydantic, serde, OpenAPI, dataclass; check CLAUDE.md / AGENTS.md). What passes:

```
runFoo(input: FooInput) → FooResult
  FooInput  = Zod schema { jobId: string, mode: 'sync' | 'async', payload: JobPayload }
  FooResult = Zod schema { status: 'ok', data: ResultData } | { status: 'error', code: ErrorCode, message: string }
```

What fails (verdict = `address these first`):
- "TypeScript interface" or "we'll add validation at the boundary later": not a contract.
- Project has a Zod-everywhere convention; spec just says "typed inputs": ambiguous.
- Contract definition deferred to "during build": input/output shapes are Type 1; cheaper to lock now.

Skip for pure infra (caches, auth wrappers, deterministic helpers consumed inside the same library). The check applies to functions producing user-facing or agent-facing capability, meaning anything crossing a layer boundary.

**4. Edge cases that matter.**
- What would hurt users or corrupt data if missed?
- What happens when external dependencies fail (API down, partial migration, malformed LLM JSON, duplicate webhook delivery)?
- Concurrency: race conditions, double submits, stale data?
- Would a builder need to ask follow-up questions? Where?
- Security: user input reaching DB/UI without validation, new routes missing auth, secrets leaking?

Specs that handle the happy path and mumble through failure are the specs that ship bugs.

**5. First-of-kind patterns.** Some patterns are hard to retrofit, so first introduction deserves extra scrutiny. Grep to determine whether the spec is the first to introduce any of these, and check the named failure mode against the spec:

These are examples; the project's CLAUDE.md may list its own first-of-kind patterns.

- New agent skill (`skills/<name>/`): layering boundary gets wrong on first try; verify SKILL.md frontmatter, role/tools/output contract.
- New agent tool (`tool({ ... })`): `rationale: z.string()` gets dropped, load-bearing description gets skipped, naming convention drifts.
- Migration with a new pattern (`RETURNS TABLE`, RLS on a new table, partial unique index, NOT NULL backfill): first one sets the precedent.
- Cron / scheduled workflow: overlap idempotency and failure alerting get skipped.
- Webhook handler: signature verification *before* body read gets reversed.
- New MCP tool surface: inline spec-fetch, context-gap-shaped inputs, per-org rate limits get omitted.

Even well-handled first-of-kind patterns deserve a flag in the verdict so a reviewer reads the section with that frame.

**6. Performance architecture.** For features with user-perceived latency or non-trivial data flow, the spec must name: where work happens (server/edge/client/background), critical-path round trips (counted, with serial-vs-parallel justified), data arrival shape (streamed/batched/prefetched/lazy), caching boundary (pre-computed/per-request/per-session/per-user), optimistic vs pessimistic UI, backpressure/failure on streams when streams exist. Missing or hand-waved sections are verdict-affecting. Performance is hardest to retrofit; spec time is the cheapest place to lock it. Also flag any API-behavior claim that reads as memory-based rather than verified from official docs (rate limits, batch endpoints, latency characteristics, parallelism support).

**7. Outcome ↔ acceptance criteria.** Does the spec's `### Outcome` statement have a measurable verification path in the acceptance criteria? Outcome says "first paint <2s on the dashboard" but acceptance criteria don't include LCP measurement = misalignment. The Outcome is the goal; acceptance criteria prove it shipped. If they don't connect, the spec ships looking done while leaving the goal unverified. Vague criteria on a measurable outcome is verdict-affecting; rewrite the criteria to verify the outcome before passing.

**8. Slice order and split.** Two checks on the task breakdown:
- **Slice 1 fails fast.** Slice 1 should surface the riskiest assumption or the Type 1 decision most likely to be wrong (the unverified API behavior, the new schema, the streaming path). The build re-checks assumptions after slice 1, so a slice 1 that only builds the easy parts wastes that check-in. Name the riskier slice that should go first.
- **No bundled forced-split items.** Flag anything from the forced-split list that this spec bundles instead of splitting into its own spec linked by `depends_on:`: a schema migration with backfill or any destructive or irreversible data change; a change to the auth, money, or publish mechanism itself (auth flow or permission model, payment or billing logic, the publish or deploy pipeline; a feature that only *uses* them stays in the spec as a risk slice); an acceptance criterion that depends on a post-deploy action (manual step, env change, external config); a cross-repo change; a refactor bundled with the feature; a change to something the user is actively running where a restart or deploy is its own gate. Everything else belongs in the one spec, so don't push to split for size alone.

## Principle pass (faster)

Run after the high-yield checks. Most specs do fine here; raise only specific concerns, not generic ones.

- **Simplicity (#1).** Simpler approach? Anything cuttable (concepts, dependencies, indirection, not lines)? Can someone new read this without a tour?
- **YAGNI (#2).** Building for an imaginary future requirement? Adding complexity for scenarios that may never happen?
- **Abstractions (#3).** Abstractions designed upfront that should be discovered later? Premature shared patterns?
- **Quality (#4).** Are assumptions treated as verified facts (API shapes "from docs," constraints described but not enforced)? If shortcuts are proposed, are they *scope cuts* (fine, document them) or *quality cuts* (they compound, call them out)? Trade-offs hidden?
- **Reversibility, Type 2 side (#5).** Are reversible decisions over-planned? Naming, tool cardinality, internal ordering: if it's grep-and-edit-fixable in an hour, push to move fast.
- **Compounding (#6).** Investing in things that compound, or front-loading one-time concerns?
- **Verification (#8).** How will the feature be proven to work: tests, build checks, browser validation? Anything hard to test? Flag it.
- **Ownership (#9).** Anything so complex the builder won't understand why it's structured that way? Deep framework knowledge the team doesn't have?
- **Project shape.** Match the project's "good" column (thin routes, shared schemas, auth wrappers, feature-name mirroring, side effects after response, structured errors, wiring files with zero logic)? Anything from the "bad" column sneaking in?

## Rationalization red flags

Scan for phrases that hide unmade decisions:
- "We can always refactor later" / "It's just a prototype" / "We might need this someday" / "It's only a small addition" / "Everyone does it this way" / "We don't have time to do it right" / "It's too late to change."

If you spot any (explicit or implicit), restate the rationalization as a real decision: what's being chosen, what's being given up. The phrase is a placeholder for an unmade decision, so name the decision. If the hidden decision is Type 1, the verdict is not clean. If it's genuinely reversible, "fix it later" is a legitimate deferral: report it as a Type 2 concern with the decision named.

## Anti-rubber-stamp

If the spec passes on first read with no concerns at all, re-read once more: first-pass clean is suspicious unless the spec is genuinely small. Bias toward reporting judgment-call findings rather than dropping them, each labeled by type. A judgment call on something irreversible is Type 1 and earns `address these first`; passing a Type 1 issue too readily is worse than one extra round of iteration. A judgment call on something reversible is Type 2: report it, but it doesn't hold back `ready to build`, because an extra round spent polishing reversible choices is waste.

## Specificity requirement

Every concern must cite a specific section, line, claim, or file in this spec. Concerns that could apply to any spec are noise; delete them before sending the verdict. Don't repeat what the spec already addresses well; don't suggest adding complexity for hypothetical scenarios; don't challenge things that are clearly appropriate for the task size.

## Output

Return the verdict as a chat response. Never write to the spec file: eng-spec owns the file, this skill only evaluates.

**Label every concern.** eng-spec triages on these labels, patching crucial concerns and parking reversible ones, so get them right:
- **Type 1**: hard to undo once shipped. Schemas, public contracts, file formats others consume, data loss or corruption, security exposure, money.
- **Type 2**: a grep-and-edit fix at build time with no lasting harm. Naming, copy, internal structure, minor edge-case handling, over-planning.
- Add **fact** when the concern contradicts something measured or verified (official docs, a grep, a benchmark).
- Add **blocking** when the build can't start correctly without it resolved: a missing I/O contract (check 3), a criterion with no home or no proof (check 1), an outcome no criterion verifies (check 7), a bundled forced-split item (check 8).

Crucial = Type 1, fact, or blocking. The verdict follows from the crucial concerns alone. Three shapes:

- **Clean**: `**ready to build**` when no crucial concern is open. List any Type 2 concerns under a `Build-time items:` header after it, same one-bullet format. Append a short "What's load-bearing in this spec" paragraph only when something would surprise a re-reader: a non-obvious coupling, a Type 1 decision encoded in a non-obvious place, a constraint that lives outside the spec body. Most clean specs don't need it; default to omitting.
- **Concerns**: `**address these first**` when at least one crucial concern is open, with 3–7 prioritized items, one tight bullet each. Crucial items first; Type 2 items can follow, labeled, so the caller can park them.
- **Rethink**: `**rethink approach**` when the architecture itself is wrong, not the prose.

**One-liner per bullet.** Each concern is one bullet, one flow: bold concern name, citation (file:line, AC#, task ID, or section heading), then the label in brackets, then diagnosis + fix in continuous prose. No multi-paragraph expansion, no sub-fields, no narration of the failure mechanism. Don't write `so when X, then Y, then Z`; the citation lets the reader verify the chain themselves. Match the example below in tightness.

Example:

```
**address these first** · 3 concerns (2 crucial, 1 Type 2), 1 verdict-blocking (Type 1 backward compat)

1. **Migration drops index without rebuild** (migration 0042, line 18) [Type 1 · blocking]. New `users.email_lower` column referenced by old `idx_users_email`, but the migration drops the index without recreating it; production queries fall back to seq scan. Fix: rebuild the index in the same migration, concurrently if the table is large.
2. **Auth middleware bypasses on CORS preflight** (T2) [Type 1]. OPTIONS requests skip the auth check entirely, letting attackers probe authenticated routes by issuing OPTIONS. Fix: serve preflight headers but block non-CORS OPTIONS on auth-required routes.
3. **Invite-failure toast copy unspecified** (User flow, step 4) [Type 2]. The sad path names a toast but not its text. Fix: pick the copy while building the slice that owns the invite form.

Flags:
- **First-of-kind webhook handler** (T4). Verify signature is checked before body parsing, not after.
```

**One verdict-blocking flag at the top, not per-item P-levels.** If exactly one concern is verdict-blocking, name it in the header (as above). Don't tag every item with P1/P2 priorities; list order is the priority, and the Type labels carry the triage.

**First-of-kind flags (skill check #5)** belong on non-clean verdicts when relevant. Same one-bullet format as concerns, listed below the numbered concerns under a `Flags:` header. No paragraphs.

**No "what slipped through clean" / passing-item footer.** The builder reads concerns to fix them; passing-item roll calls are noise. Save passing-item commentary for clean verdicts via the load-bearing paragraph above.

Concerns are transient. The caller patches crucial concerns in place via `Edit`, parks Type 2 ones as build-time items, and re-fires until no crucial concern is open.
