---
name: eng-check
description: Review code architecture before shipping, OR gate an open PR for merge against Codex review findings. Use when asked to review code, audit a diff, check a change against project conventions, determine if something is ready to ship, or decide whether an open PR is mergeable. Two modes — local-diff (default, architecture lens) and PR-gate (`/eng-check <PR#>`, merge call against Codex history). Spawns a fresh sub-agent so the reviewer has no build-session bias.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, Agent
---

Review code against the project's engineering principles — **architecture lens** for local mode, **merge-gate lens** for PR mode. Correctness, security, type safety, and performance are Codex's lens, configured by `AGENTS.md` and run automatically on every PR open/sync. The split is documented in `docs/agent-workflows/review-lens.md`; both files link there to prevent drift.

This skill spawns a fresh sub-agent — the builder shouldn't review their own work (Principle #7).

## Modes

- **Local-diff mode (default, no args):** architecture review of pending changes against CLAUDE.md principles. Author runs pre-push as the architecture lens.
- **PR-gate mode (`/eng-check <PR#>`):** merge call on an open PR. Pulls Codex review findings + commit history, maps fix commits to findings via the project's commit-message convention, applies the AGENTS.md severity rubric, and returns a structured verdict (`ship` / `fix-then-ship` / `waiting`). Designed to compose with `/loop /eng-check <PR#>` so the loop self-pacing waits for Codex async review and exits when the merge call is decisive.

The two modes share the fresh-sub-agent pattern, the AGENTS.md severity rubric, and the CLAUDE.md context. They differ in input (local diff vs. PR + Codex history) and output shape (architecture findings vs. merge call).

---

## Local-diff mode (default)

**How it works:**

1. Read the project's CLAUDE.md for conventions and principles.
2. Get the changed files: detect the base branch, then `git diff $(git merge-base <base> HEAD) --name-only`.
3. Read the actual content of changed files (use `git diff` for the full diff).
4. If a spec exists in `specs/` for this feature, read it.
5. **Diff-filtered context loading.** Walk these knowledge sources and pull only entries relevant to the diff:
   - **Gotcha index** (`docs/solutions/README.md`) — match entries by tag/path. A touched file in `src/lib/supabase/` pulls Supabase gotchas; a new migration pulls migration gotchas; a new agent tool pulls AI SDK / agent-tool gotchas. Inline the matched entries' problem + solution into the sub-agent prompt
   - **Library-function checklist** (`docs/agent-workflows/library-function-checklist.md`) — pre-merge checklist for new `src/lib/<feature>/` functions. If the diff touches `src/lib/`, inline the relevant checklist items
6. Spawn one architecture sub-agent. **Pass context directly** — don't make it re-read CLAUDE.md or re-explore the codebase. The sub-agent prompt should include:
   - The CLAUDE.md sections relevant to architecture review (inline, not a file path)
   - The full diff of changed files (inline)
   - The acceptance criteria from the spec (not the full spec — no exploration history needed)
   - The list of changed file paths
   - Diff-relevant gotchas + checklist items pulled in step 5 (inline)
   - The architecture review instructions below
7. Use the sub-agent's findings as your report.

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

**High-yield principles — lead with these:**
- **Simplicity (#1).** Is this as simple as it can be? Can someone new read, understand, and change it without breaking anything else? Cut concepts and dependencies, not just lines of code.
- **Quality (#4).** If shortcuts were taken, are they documented with a concrete plan to revisit? **A TODO without a ticket is a wish.** Deferred quality without an owner compounds — flag every unowned TODO.
- **Ownership (#9).** Can the person who ships this explain why it's structured this way? Anything opaque or "it works but I don't know why"?

**Quick pass:**
- YAGNI (#2) — building for an imaginary future requirement?
- Abstractions (#3) — forced patterns that should stay as duplication?
- Reversibility (#5) — irreversible decisions (schema, public APIs) treated with enough care? Reversible ones over-planned?
- Compounding (#6) — worth its cost across future sessions, or one-time complexity?
- Verification (#8) — tests, build, lint, browser?

**Reviewer-bias tripwire.** If your only finding is a stylistic preference and the code clearly works, that's taste, not architecture — drop it. Architecture findings name a real downstream consequence (someone gets paged, a future change breaks, a class of bugs is enabled). "I'd write it differently" is not a finding.

**Feature structure (seven patterns) — most-violated lead:**
- **Thin routes** -- validate and delegate, no business logic in route files. Most common violation.
- **Side effects after the response** -- user doesn't wait for webhooks, emails, analytics. Easy to miss in review.
- **Structured errors with codes**, handled at the boundary. Naked throws or string errors flag.
- Shared schema -- one definition, used by frontend and backend
- Auth wrapped once -- not copy-pasted per route
- Feature names mirrored across layers
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

**Comments & PR hygiene:**
- Comments explain why, not what
- TODOs reference a ticket or have a name
- PR is small and focused (target median ~100 lines, p90 <500, <10 files, one responsibility). Larger PRs OK only for migrations or generated code, and should be called out explicitly

**Calibration:** Approve once the code improves overall code health -- even if it isn't perfect. The bar is: is this better than what we had before? Too strict and nothing ships. Too lenient and quality degrades one compromise at a time.

**Output:**
- One-line verdict: **looks good** / **has concerns** / **needs rework**
- Specific issues found, referencing the principle or pattern violated
- Surface diff-relevant gotchas inline (`docs/solutions/<entry>.md` applies — verify the diff handles X)
- Surface diff-relevant checklist items inline (library-function-checklist item N applies — verify Y)
- Label each: **blocker** (must fix before merge), **important** (should fix before merge, won't block approval alone), or **nit** (optional improvement)
- Concrete fix for each issue
- End with one line on what the code does well — specific, not generic praise
- If you're uncertain about something, say so and suggest investigation rather than guessing
- Keep it concise — flag everything worth flagging, but keep each issue to 1-2 lines plus the fix

**Lens reminder.** Don't flag correctness, security, type safety, or performance — those are Codex's lens (`AGENTS.md`). If a finding fits that lens, leave it for Codex on PR open. Double-coverage burns reviewer cycles and breeds noise. The lens split is documented in `docs/agent-workflows/review-lens.md`.

---

## PR-gate mode (`/eng-check <PR#>`)

Decisive merge call on an open PR. Codex finds something on every commit indefinitely; this mode is the converging gate that decides when to merge.

**How it works:**

1. Parse args. If args contain a numeric PR number, run PR-gate mode. Otherwise fall through to local-diff mode.
2. Fetch PR state via `gh`:
   - `gh pr view <n> --json number,title,state,isDraft,mergeable,additions,deletions,changedFiles,headRefName,baseRefName,reviewDecision,statusCheckRollup,url,body,commits`
   - `gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate` — all inline review comments (per-line findings).
   - `gh pr view <n> --json reviews` — review-level entries (round summaries).
   - `gh pr view <n> --json comments` — issue-level conversation, including author scope-out declarations and `@codex review` pings.
   - `gh api repos/<owner>/<repo>/issues/<n>/reactions` — reactions on the PR body. Codex (`chatgpt-codex-connector[bot]`) leaves a `+1` reaction here when a review found zero issues, instead of posting an empty review comment. Without fetching reactions, the gate sits in `waiting` indefinitely on clean reviews.
3. Read AGENTS.md and CLAUDE.md from the repo root. Pull the **Severity calibration**, **Convergence across review rounds**, **PR-scope honoring**, and **P0/P1 — blast-radius rules** sections from AGENTS.md verbatim. These are the rubric the sub-agent applies.
4. **Parse fix commits.** For each commit on the PR branch, regex-match the subject against the project convention:
   `fix\(([^)]+)\): T[0-9]+ PR review round (\d+) P([0-2]) #(\d+) — (.+)`
   Capture (scope, round, severity, finding-index, summary). Build a `fix_map`: keyed by `(round, severity, index)` → fix commit SHA + subject.
5. **Identify open findings.** For each Codex inline comment:
   - Record (commit reviewed, round-number heuristic by submission order, file, line, body, P-level Codex assigned).
   - Look up whether a fix commit addresses this finding via the `fix_map`. Author convention is `round N P1 #M` where M is the 1-indexed position of the finding within round N's comments. Use submission timestamp ordering within a round.
   - If a fix commit exists with a SHA that postdates the finding's review submission time, treat as **addressed**. Otherwise **open**.
6. **Identify scope-outs.** Parse the PR body for `## Out of scope`, `## Deferred`, or `## Follow-up issues` headings. List items under those headings, including any linked issue references (`#123`) or file-path/feature mentions. Findings matching scope-outs are **suppressed**.
7. **Determine waiting state.** A Codex "review signal" on the latest commit is any of: (a) an inline comment from `chatgpt-codex-connector[bot]` postdating the latest commit, (b) a formal review submission from Codex postdating the latest commit, or (c) a `+1` reaction from `chatgpt-codex-connector[bot]` on the PR body postdating the latest commit (Codex's "zero findings" shorthand — no inline comments, no formal review, just a thumbs-up on the body). If none of (a)/(b)/(c) is present AND the latest commit was pushed less than 30 minutes ago, status is `waiting` (Codex hasn't had a chance yet). If older than 30 minutes and still no signal, surface that as a separate concern (Codex may have stalled; flag for user, but proceed with classification). When the only signal is (c), record it as "Codex review: 👍 reaction (no findings)" — there are no inline comments to classify.
8. Spawn one merge-gate sub-agent. **Pass everything inline** — don't make it re-fetch:
   - The CLAUDE.md product/engineering principles relevant to severity (Principles #1, #4, #8, #9; product principle #1 "data collection never flexes" for data-corruption framing).
   - The AGENTS.md severity rubric and convergence rules (verbatim, sections from step 3).
   - The full list of open findings (file, line, Codex's body, Codex's P-label, the round it appeared in).
   - The fix-commit mapping (which findings have been addressed and by which commit).
   - The PR scope-out section verbatim.
   - The waiting-state determination.
   - The merge-gate review instructions below.
9. Use the sub-agent's verdict as the report output.

---

**Merge-gate review instructions for sub-agent:**

You are the deciding merge gate for an open PR. Your job is to return a decisive verdict — `ship`, `fix-then-ship`, or `waiting` — based on the open findings, the project's severity rubric, and the addressed/scope-out classifications already done by the harness.

**Inputs you've been given:**

- AGENTS.md severity rubric and convergence rules (the source of truth for P0/P1/P2 calibration).
- The list of **open findings** (Codex inline comments without a corresponding fix commit).
- The list of **addressed findings** (Codex inline comments mapped to fix commits) — informational, do not re-evaluate.
- The PR's `## Out of scope` / `## Deferred` declarations — items there are out of scope for this verdict.
- The waiting-state signal, including which Codex review channel produced the signal: inline comments, formal review, or `+1` reaction on the PR body. A `+1` reaction with no inline comments = "Codex reviewed and found zero issues" — there are no findings to classify and the verdict is `ship`.

**Your task:**

1. **If status is `waiting`** — return verdict `waiting` immediately. Don't classify anything. The latest commit hasn't been reviewed by Codex yet; come back later. State the gap (latest commit SHA + minutes since push, last reviewed SHA).

2. **For each open finding** — apply the AGENTS.md severity rubric **to this diff specifically**. Codex's P-label is a hint, not the final answer; you re-classify based on actual blast radius:
   - **Real P0** — merging now causes a concrete bad outcome: data corruption in flight, security exploit (auth bypass, unsigned webhook on prod path, exposed secret), money-loss vector with realistic trigger frequency, RLS missing on tenant data. Treat as ship-blocker.
   - **Real P1** — real bug with narrow blast radius: edge-case correctness, observability gap, partial-state risk on a recoverable path, type laundering on a CLI/fixture path. Worth tracking; not strictly merge-blocking if filed as a follow-up.
   - **P2** — architectural taste, sibling instance of an addressed pattern, future-cleanup ("this could be moved to lib", "this could be a DTO"). Suppress unless the finding has concrete blast radius the rule list misses.

3. **Pattern-dedup.** If multiple open findings describe the same pattern across different files, count them as one for the verdict (file the suppressed siblings under the deduplicated finding). Inflated counts shouldn't block merge.

4. **Verdict logic:**
   - If **no real P0 and no real P1** open findings → `ship`. The author can merge.
   - If **real P0** open → `fix-then-ship`. List each P0 with file:line and a concrete fix.
   - If **real P1** open and the finding is significant enough that a follow-up issue is the wrong place → `fix-then-ship`. List each P1.
   - If **real P1** open but each is fine to defer → `ship`, with a recommendation to file follow-up issues for the deferred P1s before merging (the act of filing closes the deferral loop).

5. **Don't be lenient AND don't be strict.** The lens is "what would actually break or harm if this merged right now". Codex over-flags taste; you correct for that. But if Codex caught a genuine money-loss path, that's a P0 regardless of what label Codex used.

**Calibration:** This gate exists to break the asymptotic-review trap. Round 5+ Codex findings are usually taste/sibling-instance noise — you're the layer that says "good enough, merge". But also: a real security hole found at round 8 is still a real security hole. Judge per-finding, not by round number.

**Output format (machine-parseable for `/loop` integration):**

```
STATUS: ship | fix-then-ship | waiting

VERDICT: <one-line summary, e.g., "All P1s addressed; 2 P2 architectural items suppressed as out-of-scope (linked to follow-up issues #N, #M).">

PR: #<n> · <title> · <additions>/<deletions> across <changedFiles> files
Latest commit: <sha-short> "<subject>" (<time>)
Latest Codex review: <reviewed-sha-short> (<time>) · <delta minutes since latest commit> | OR | 👍 reaction on PR body (<time>) — zero findings | OR | none yet
<Devin review line if present>

## Open findings

<for fix-then-ship: list real P0 first, then real P1>
- **P0** `<file:line>` — <one-line concern>
  Fix: <concrete one-line action>
- **P1** `<file:line>` — <one-line concern>
  Fix: <concrete one-line action>

<for ship: write "None — clear to merge.">

## Addressed (informational)

<count> findings addressed by fix commits across rounds <range>. Examples:
- Round N P1 #M `<file:line>` — fixed in <sha> "<subject>"
<keep this section to ~5 examples; no need to enumerate all>

## Suppressed as P2 / scope-out

<list each suppressed item with one-line reason: "P2 architectural — out of merge-gate scope" / "Listed in PR body ## Out of scope" / "Pattern-deduped under <file:line>">

## Recommended action

<for ship: "Run `npm run lint && npm run build && npm run test` if not already green, then `gh pr merge <n> --rebase`. Optionally file follow-up issues for: <list any P1s being deferred>.">
<for fix-then-ship: "Address the open P0/P1 above, then re-run `/eng-check <n>`. Or file follow-up issues for items you intentionally defer and re-run.">
<for waiting: "Codex hasn't reviewed the latest commit yet. Wait ~5 minutes and re-run, or use `/loop /eng-check <n>` to auto-recheck.">
```

The `STATUS:` line on its own at the top is the loop-integration contract — `/loop` reads it to decide whether to schedule the next wakeup (`waiting` → reschedule; `ship`/`fix-then-ship` → exit and surface).

**Lens reminder.** PR-gate mode applies severity to existing Codex findings; it does not generate new architecture or correctness findings of its own. Architecture concerns belong in local-diff mode (run pre-push); correctness/security/types/perf are Codex's lens. The PR-gate's job is *judgment over existing findings*, not a fresh review.

---

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
