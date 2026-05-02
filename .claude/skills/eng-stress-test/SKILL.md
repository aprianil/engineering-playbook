---
name: eng-stress-test
description: Stress-test a spec or plan with fresh eyes. Challenges assumptions, surfaces risks, catches overengineering. Mandatory before /eng-build can start — returns the verdict as a chat response; eng-spec embeds the clean verdict in the spec on save.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash
argument-hint: [spec-file]
---

Stress-test a spec or plan. You are a fresh pair of eyes — you did not write this and you have no attachment to its decisions. Catching issues here is far cheaper than catching them during or after building.

## What you're given

`/eng-spec` invokes you while the spec is still a draft in conversation, and passes inline:
- The full draft (spec body + task list).
- The engineering principles to check against.
- The codebase paths and snippets the draft is grounded in.

Don't re-read CLAUDE.md, don't explore the codebase, don't read a spec file from disk. The caller already did that work — go straight to challenging. The only exception is a legacy spec handed over by file path with no inline context; in that case, read the file and the project's CLAUDE.md, then proceed normally.

## High-yield checks — lead with these

These five catch most real issues. Run them before the principle pass.

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

Return the verdict as a chat response. Never write to the spec file — eng-spec owns the spec, this skill only evaluates. Two shapes:

- **Clean** — `**ready to build**` + a short "What's load-bearing in this spec" paragraph (the bits that wouldn't be obvious from re-reading the spec). Timestamp.
- **Concerns** — `**address these first**` or `**rethink approach**` + 3–7 prioritized items (concern · why it matters · a question that resolves it). Timestamp.

Concerns are transient — the caller iterates the draft in conversation until clean. The spec hits disk only once, with the clean verdict embedded.
