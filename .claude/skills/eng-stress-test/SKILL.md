---
name: eng-stress-test
description: Stress-test a spec or plan with fresh eyes. Challenges assumptions, surfaces risks, catches overengineering. Mandatory before /eng-build can start — returns the verdict as a chat response; eng-spec embeds the clean verdict in the spec on save.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash
argument-hint: [spec-file]
---

Stress-test a spec or plan. You are a fresh pair of eyes — you did not write this and you have no attachment to its decisions. Catching issues here is far cheaper than catching them during or after building.

## What you're given

`/eng-spec` invokes you with the spec saved to disk as `status: drafting`, and passes inline:
- The spec file path or full content (spec body + task list).
- The engineering principles to check against.
- The codebase paths and snippets the draft is grounded in.

Don't re-read CLAUDE.md, don't explore the codebase. The caller already did that work — go straight to challenging. If only a path was passed, read the file once, then proceed.

## High-yield checks — lead with these

These five catch most real issues. Run them before the principle pass.

**When invoked on a sub-spec** (frontmatter has `slice_of:`): assume the parent's locked decisions hold. Don't re-evaluate parent's shared contracts, cross-cutting Type 1 decisions, decomposition correctness, or DAG structure. Those were validated when parent stress-tested clean. Focus the 5 checks at slice scope only: this slice's acceptance↔approach traceability, this slice's slice-internal Type 1 decisions, this slice's I/O contracts on slice-internal capability functions, this slice's edge cases, this slice's first-of-kind patterns. Sub-spec stress-tests are usually shorter than parent stress-tests; if yours isn't, you're probably re-checking inherited decisions.

**1. Acceptance ↔ approach traceability.** For each acceptance criterion, point to where in the file structure and approach it gets implemented. Criteria with no clear home = gap in the plan. Files or components in the approach that don't map to any criterion = scope creep. Either is verdict-affecting.

**2. Type 1 (irreversible) decisions.** Database schemas, public API contracts, data migrations, file formats other systems consume. Are they explicit and locked, or hidden inside "we'll figure it out"? Type 1 decisions deferred to build are the most expensive thing a spec can do — flag every one that isn't pinned down.

**3. I/O contract on capability functions (verdict-blocking).** If the spec introduces new exported functions on the capability path — anything an external caller, agent, or orchestrator might invoke — the spec must name input + output contract inline using the project's convention (Zod, Pydantic, serde, OpenAPI, dataclass; check CLAUDE.md / AGENTS.md). What passes:

```
runFoo(input: FooInput) → FooResult
  FooInput  = Zod schema { jobId: string, mode: 'sync' | 'async', payload: JobPayload }
  FooResult = Zod schema { status: 'ok', data: ResultData } | { status: 'error', code: ErrorCode, message: string }
```

What fails (verdict = `address these first`):
- "TypeScript interface" or "we'll add validation at the boundary later" — not a contract.
- Project has a Zod-everywhere convention; spec just says "typed inputs" — ambiguous.
- Contract definition deferred to "during build" — input/output shapes are Type 1; cheaper to lock now.

Skip for pure infra (caches, auth wrappers, deterministic helpers consumed inside the same library). The check applies to functions producing user-facing or agent-facing capability — anything crossing a layer boundary.

**4. Edge cases that matter.**
- What would hurt users or corrupt data if missed?
- What happens when external dependencies fail (API down, partial migration, malformed LLM JSON, duplicate webhook delivery)?
- Concurrency — race conditions, double submits, stale data?
- Would a builder need to ask follow-up questions? Where?
- Security — user input reaching DB/UI without validation, new routes missing auth, secrets leaking?

Specs that handle the happy path and mumble through failure are the specs that ship bugs.

**5. First-of-kind patterns.** Some patterns are hard to retrofit, so first introduction deserves extra scrutiny. Grep to determine whether the spec is the first to introduce any of these — and check the named failure mode against the spec:

- New agent skill (`skills/<name>/`) — layering boundary gets wrong on first try; verify SKILL.md frontmatter, role/tools/output contract.
- New agent tool (`tool({ ... })`) — `rationale: z.string()` gets dropped, load-bearing description gets skipped, naming convention drifts.
- Migration with a new pattern (`RETURNS TABLE`, RLS on a new table, partial unique index, NOT NULL backfill) — first one sets the precedent.
- Cron / scheduled workflow — overlap idempotency and failure alerting get skipped.
- Webhook handler — signature verification *before* body read gets reversed.
- New MCP tool surface — inline spec-fetch, context-gap-shaped inputs, per-org rate limits get omitted.

Even well-handled first-of-kind patterns deserve a flag in the verdict so a reviewer reads the section with that frame.

**6. Performance architecture.** For features with user-perceived latency or non-trivial data flow, the spec must name: where work happens (server/edge/client/background), critical-path round trips (counted, with serial-vs-parallel justified), data arrival shape (streamed/batched/prefetched/lazy), caching boundary (pre-computed/per-request/per-session/per-user), optimistic vs pessimistic UI, backpressure/failure on streams when streams exist. Missing or hand-waved sections are verdict-affecting. Performance is hardest to retrofit; spec time is the cheapest place to lock it. Also flag any API-behavior claim that reads as memory-based rather than verified from official docs (rate limits, batch endpoints, latency characteristics, parallelism support).

**7. Outcome ↔ acceptance criteria.** Does the spec's `### Outcome` statement have a measurable verification path in the acceptance criteria? Outcome says "first paint <2s on the dashboard" but acceptance criteria don't include LCP measurement = misalignment. The Outcome is the goal; acceptance criteria prove it shipped. If they don't connect, the spec ships looking done while leaving the goal unverified. Vague criteria on a measurable outcome is verdict-affecting; rewrite the criteria to verify the outcome before passing.

## Principle pass — faster

Run after the high-yield checks. Most specs do fine here; raise only specific concerns, not generic ones.

- **Simplicity (#1).** Simpler approach? Anything cuttable — concepts, dependencies, indirection — not lines? Can someone new read this without a tour?
- **YAGNI (#2).** Building for an imaginary future requirement? Adding complexity for scenarios that may never happen?
- **Abstractions (#3).** Abstractions designed upfront that should be discovered later? Premature shared patterns?
- **Quality (#4).** Are assumptions treated as verified facts (API shapes "from docs," constraints described but not enforced)? If shortcuts are proposed, are they *scope cuts* (fine, document them) or *quality cuts* (compound — call out)? Trade-offs hidden?
- **Reversibility — Type 2 side (#5).** Are reversible decisions over-planned? Naming, tool cardinality, internal ordering — if it's grep-and-edit-fixable in an hour, push to move fast.
- **Compounding (#6).** Investing in things that compound, or front-loading one-time concerns?
- **Verification (#8).** How will the feature be proven to work — tests, build checks, browser validation? Anything hard to test? Flag it.
- **Ownership (#9).** Anything so complex the builder won't understand why it's structured that way? Deep framework knowledge the team doesn't have?
- **Project shape.** Match the project's "good" column (thin routes, shared schemas, auth wrappers, feature-name mirroring, side effects after response, structured errors, wiring files with zero logic)? Anything from the "bad" column sneaking in?

## Rationalization red flags

Scan for phrases that hide unmade decisions:
- "We can always refactor later" / "It's just a prototype" / "We might need this someday" / "It's only a small addition" / "Everyone does it this way" / "We don't have time to do it right" / "It's too late to change."

If you spot any (explicit or implicit), the verdict is not clean. Restate the rationalization as a real decision: what's being chosen, what's being given up. The phrase is a placeholder for an unmade decision — name the decision.

## Anti-rubber-stamp

If the spec passes on first read with no concerns at all, re-read once more — first-pass clean is suspicious unless the spec is genuinely small. The default working verdict is faster to write than a default clean verdict; bias toward `address these first` on judgment-call findings. Passing too readily is worse than one extra round of iteration.

## Specificity requirement

Every concern must cite a specific section, line, claim, or file in this spec. Concerns that could apply to any spec are noise — delete them before sending the verdict. Don't repeat what the spec already addresses well; don't suggest adding complexity for hypothetical scenarios; don't challenge things that are clearly appropriate for the task size.

## Output

Return the verdict as a chat response. Never write to the spec file — eng-spec owns the file, this skill only evaluates. Two shapes:

- **Clean** — `**ready to build**`. Append a short "What's load-bearing in this spec" paragraph only when something would surprise a re-reader: a non-obvious coupling, a Type 1 decision encoded in a non-obvious place, a constraint that lives outside the spec body. Most clean specs don't need it; default to omitting.
- **Concerns** — `**address these first**` or `**rethink approach**` + 3–7 prioritized items, one tight bullet each.

**One-liner per bullet.** Each concern is one bullet, one flow: bold concern name, citation (file:line, AC#, task ID, or section heading), then diagnosis + fix in continuous prose. No multi-paragraph expansion, no sub-fields, no narration of the failure mechanism. Don't write `so when X, then Y, then Z`; the citation lets the reader verify the chain themselves. Match the example below in tightness.

Example:

```
**address these first** · 5 concerns, 1 verdict-blocking (Type 1 backward compat)

1. **Migration drops index without rebuild** (migration 0042, line 18). New `users.email_lower` column referenced by old `idx_users_email`, but the migration drops the index without recreating it; production queries fall back to seq scan. Fix: rebuild the index in the same migration, concurrently if the table is large.
2. **Auth middleware bypasses on CORS preflight** (T2). OPTIONS requests skip the auth check entirely, letting attackers probe authenticated routes by issuing OPTIONS. Fix: serve preflight headers but block non-CORS OPTIONS on auth-required routes.

Flags:
- **First-of-kind webhook handler** (T4). Verify signature is checked before body parsing, not after.
```

**One verdict-blocking flag at the top, not per-item P-levels.** If exactly one concern is verdict-blocking, name it in the header (as above). Don't tag every item with P1/P2 priorities — list order is the priority.

**First-of-kind flags (skill check #5)** belong on non-clean verdicts when relevant. Same one-bullet format as concerns, listed below the numbered concerns under a `Flags:` header. No paragraphs.

**No "what slipped through clean" / passing-item footer.** The builder reads concerns to fix them; passing-item roll calls are noise. Save passing-item commentary for clean verdicts via the load-bearing paragraph above.

Concerns are transient. The caller patches the spec file in place via `Edit` and re-fires until the verdict is clean.
