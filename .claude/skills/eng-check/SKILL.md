---
name: eng-check
description: Review code before shipping, OR gate an open PR for merge. Use when asked to review code, audit a diff, check a change against project conventions, determine if something is ready to ship, or decide whether an open PR is mergeable. Three entry points. Local-diff (default; architecture lens, plus correctness, security, type safety and performance when no PR review bot owns them; reads a slice map and reviews slice by slice). Range (`/eng-check <sha>..<sha>`, one commit range, e.g. a risk slice mid-build, always with the correctness checklist). PR-gate (`/eng-check <PR#>`, merge call against the review bot's findings, or a fresh review when the project has no bot). Spawns a fresh sub-agent so the reviewer has no build-session bias.
disable-model-invocation: false
allowed-tools: Read, Write, Glob, Grep, Bash, Agent
---

Review code against the project's engineering principles. A fresh sub-agent does the review: the builder shouldn't review their own work (Principle #7).

**Parse args first.** An argument containing `..` is a commit range: range mode. A numeric argument is a PR number: PR-gate mode. No args: local-diff mode.

**Who owns correctness.** Check AGENTS.md / CLAUDE.md for a declared automated PR reviewer (e.g. Codex) that owns correctness, security, type safety, and performance, and follow any lens split the project documents.
- **Bot declared:** local mode stays architecture-only. Double coverage burns reviewer cycles and breeds noise.
- **No bot:** local mode also runs the correctness checklist below. Nothing else will.
- **Range mode always runs the checklist.** It runs mid-build on risk slices, before the bot has seen the code.

---

## Local-diff mode (default) and range mode

1. Read the project's CLAUDE.md, and AGENTS.md if present (review-bot declaration, severity rubric, commit convention).
2. Get the changed files: detect the base branch, then `git diff $(git merge-base <base> HEAD) --name-only`. **Range mode:** use `git diff <sha>..<sha>` and `git log <sha>..<sha>` and review only that range.
3. Read the full diff.
4. **On a fix branch (`fix/`, `hotfix/`, `bug/`, `followup/`), skip spec lookup**; the bug is the spec. Otherwise read the feature's spec in `specs/` if one exists.
5. **Slice map (local mode).** If the spec has `#### Slice N:` headings, or the PR body has a slice map, and the commits line up with slices, map each slice to its commit range. The sub-agent reviews slice by slice, then the whole diff. A large diff read one capability at a time is reviewable; read as one blob it hides which slice a problem belongs to. Range mode skips this: the range is one slice.
6. **Diff-filtered context.** Pull only entries relevant to the diff:
   - **Gotcha index** (`docs/solutions/README.md`, if present): match entries by tag or path (a touched database client pulls database gotchas, a new migration pulls migration gotchas). Inline each match's problem + solution.
   - **Library-function checklist** (if CLAUDE.md / AGENTS.md names one): inline the items for the layer the diff touches.
7. Spawn one review sub-agent. **Pass everything inline** so it doesn't re-read CLAUDE.md or re-explore:
   - The CLAUDE.md sections relevant to review
   - The full diff and the changed file paths
   - The spec's acceptance criteria, `### Outcome`, `### Performance architecture`, and `### Deviations`
   - The slice map with commit ranges, when step 5 found one
   - The gotchas and checklist items from step 6
   - Whether a bot owns correctness, and the review instructions below (with the checklist when no bot owns it, or in range mode)
8. Use the sub-agent's findings as your report. **Local mode only:** end with `eng-check: <verdict> @ <short-sha>`, the HEAD that was reviewed. Once no blockers or importants are open, that line goes in the PR body (`gh pr edit` if the PR exists; otherwise the author adds it when opening). The no-bot PR gate reads it to review only the commits after that SHA.

**After the report**, when the build session is still open: fix blockers and importants inline if the fix is single-file, needs no new test scaffold, and has no design decision pending. Otherwise surface it to the user in one line and ask. Don't quietly file a follow-up or spec it.

---

**Review instructions for sub-agent:**

You are reviewing code with fresh eyes. You did not write it. The CLAUDE.md principles and the full diff are inline; use them as your source of truth.

**Read the diff deeply first.** Read every changed function: what it does, how it handles errors, what it assumes. Most findings come from here.

**Explore with purpose.** Read a file outside the diff only for a named concern the diff can't resolve ("this route doesn't check auth, let me read one existing route for a wrapper"). To check a pattern, read one example. If you're reading without a concern, stop and write findings.

**Order:** zoom out first (spec or PR description: does the approach make sense? if not, stop and say so), then the main files, then the rest. **With a slice map,** review each slice's commits in order (one capability end-to-end? builds on its own? leaks into another slice's scope?), then the whole diff once for cross-slice problems. Tag each finding with its slice.

**High-yield principles:**
- **Simplicity (#1).** Could someone new read and change this without breaking anything? Cut concepts and dependencies, not just lines.
- **Quality (#4).** Shortcuts documented with a plan to revisit? **A TODO without a ticket is a wish.** Flag every unowned TODO.
- **Ownership (#9).** Anything opaque, "works but I don't know why"?

**Quick pass:** YAGNI (#2), forced abstractions (#3), irreversible decisions handled with care and reversible ones not over-planned (#5), compounding (#6), verification (#8). Check the project shape rules from CLAUDE.md, leading with the most-violated: thin routes, side effects after the response, structured errors handled at the boundary.

**Reviewer-bias tripwire.** If your only finding is a stylistic preference and the code clearly works, drop it. Architecture findings name a real downstream consequence (someone gets paged, a future change breaks, a class of bugs is enabled). "I'd write it differently" is not a finding. A correctness or security finding names the caller, input, or sequence that reaches it. Drop a hypothetical with no reachable path, unless data loss, security, or money is at stake: then report it as unverified.

**Spec alignment (skip on fix branches):**
- Does the implementation match the spec? Missed or changed acceptance criteria are justified only by a `### Deviations` entry with evidence. Could each criterion's named proof fail? A test that still passes if the code under test did nothing is not proof; flag it.
- Out-of-scope items included?
- **Architecture fidelity.** If `### Performance architecture` names decisions (parallel fan-out, caching boundary, streaming vs batched, optimistic UI, where work happens), does the code reflect them? Spec said parallel, code shipped serial = drift. Flag as spec drift.

**Correctness, security, type safety, performance (no bot, or range mode).** In range mode, also state the one fact the slice is safe because of, and whether you read it in code, traced it, or ran it. Skip only in local mode on a project with a bot:
- **Correctness.** Wrong conditionals; unhandled null, empty, or unexpected input; error paths that swallow failures or leave partial state; async misuse (unawaited promises, races, double submits); an acceptance criterion the code doesn't meet.
- **Security.** Input validated at the boundary; every new route or action has authentication *and* authorization (ownership or tenant checks, not just "logged in"); no secrets in code or logs; no injection (SQL, shell, HTML, prompt) through interpolated untrusted data; webhook signatures verified before the body is trusted.
- **Type safety.** No `as any`, unchecked casts, or non-null assertions papering over a real type; external data (API responses, DB rows, LLM output) parsed through a schema before use.
- **Performance.** N+1 queries; serial awaits that could be parallel; unbounded queries or loops over user-controlled sizes; request-path work that belongs after the response; new query shapes with no index.

**Prompt-injection lens (only when the diff builds prompts, registers agent or MCP tools, imports an LLM SDK, or consumes LLM output).** Check: untrusted input (user text, scraped pages, RAG results, tool outputs, DB records, email bodies) interpolated into prompts without marking it untrusted; LLM output rendered as HTML, executed, used in SQL, fed to another LLM, or trusted for authorization; and cross-privilege flow, where a lower-privileged user's data plants instructions a higher-privileged AI session consumes (admin reads an uploaded doc, agent reads another tenant's records). Each permission check can look correct while the AI layer escalates privilege.

**PR hygiene:**
- Comments explain why; TODOs reference a ticket or a name.
- A large PR is fine with a slice map and green per-slice commits; flag a large PR with neither.
- Flag any bundled item from `/eng-spec`'s forced-split list: a migration with backfill or a destructive data change; a change to the auth, money, or publish mechanism itself (auth flow or permission model, payment or billing logic, the publish or deploy pipeline; code that only *uses* them stays); an acceptance criterion that needs a post-deploy action; a cross-repo change; a refactor bundled with a feature; a change to something the user is actively running where a restart or deploy is its own gate. Each belongs in its own PR.

**Calibration:** approve once the change improves overall code health, even if it isn't perfect. Too strict and nothing ships; too lenient and quality degrades one compromise at a time.

**Output:**
- One-line verdict: **looks good** / **has concerns** / **needs rework**
- Each issue: the principle or pattern violated, labeled **blocker** (must fix before merge), **important** (should fix, won't block approval alone), or **nit**, with a concrete fix, 1-2 lines plus the fix
- Matched gotchas and checklist items inline ("`docs/solutions/<entry>.md` applies, verify the diff handles X")
- Say so when uncertain, and suggest what to investigate
- End with one specific line on what the code does well

---

## PR-gate mode (`/eng-check <PR#>`)

The converging merge call. A review bot finds something on every commit forever; this gate decides when to merge. Read AGENTS.md / CLAUDE.md for a declared bot: bot flow if declared, no-bot flow if not. Both return the same STATUS templates.

### With a review bot

Written for Codex (`chatgpt-codex-connector[bot]`). For another bot, swap in its login and signal channels.

1. Fetch PR state:
   - `gh pr view <n> --json number,title,state,isDraft,mergeable,additions,deletions,changedFiles,headRefName,baseRefName,reviewDecision,statusCheckRollup,url,body,commits`
   - `gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate` (inline findings)
   - `gh pr view <n> --json reviews` (round summaries)
   - `gh pr view <n> --json comments` (scope-out declarations, `@codex review` pings)
   - `gh api repos/<owner>/<repo>/issues/<n>/reactions`. Codex leaves a `+1` reaction on the PR body when a review found zero issues, instead of posting a review. Without fetching reactions, the gate sits in `waiting` forever on clean reviews.
2. Pull AGENTS.md's severity rubric and convergence rules verbatim. If it has none, use the P0/P1/P2 definitions below.
3. **Map fix commits to findings.** With a project fix-commit convention (e.g. a subject naming round, severity, index), regex-match commit subjects into a `fix_map` keyed `(round, severity, index)` → SHA + subject; index M is the finding's 1-indexed position within round N, by submission time. Without one, a finding is **likely addressed** when a later commit touches the same file within ~10 lines or the same function; the sub-agent confirms by reading the code.
4. **Open findings.** For each bot inline comment record commit reviewed, round (by submission order), file, line, body, and the bot's P-level. A fix commit that postdates it makes it **addressed** (or **likely addressed**); otherwise **open**.
5. **Scope-outs.** Items under `## Out of scope`, `## Deferred`, or `## Follow-up issues` in the PR body (including `#123` links and file or feature mentions). Matching findings are **suppressed**.
6. **Waiting state.** A Codex review signal on the latest commit is any of: (a) an inline comment, (b) a formal review, or (c) a `+1` reaction on the PR body, each postdating the latest commit. No signal and the commit is under 30 minutes old: `waiting`. No signal past 30 minutes: flag a possible stalled bot to the user and classify anyway. If the only signal is (c), record "Codex review: 👍 reaction (no findings)".
7. Spawn one merge-gate sub-agent with everything inline: severity-relevant CLAUDE.md principles (#1, #4, #8, #9, plus any product principle about data corruption or user harm), the rubric from step 2, open findings (file, line, body, P-label, round), the fix mapping (flagging likely-addressed ones), the scope-out section verbatim, the waiting state, and the merge-gate instructions below.
8. Use its verdict as the report.

### Without a review bot

1. Fetch PR state with the first `gh pr view` above, plus `gh pr diff <n>`.
2. Read CLAUDE.md and AGENTS.md for principles, severity rubric, and merge convention.
3. Map the slice map (PR body or spec) to commit ranges, and parse scope-outs as in bot step 5.
4. **Find the recorded local verdict.** If the PR body has `eng-check: <verdict> @ <sha>` and that SHA is in the PR's history, review only `git diff <sha>..<head>` and pass the recorded verdict as context. No commits after it: skip the sub-agent and return `ship` with gist "clean, local review @ <sha> covers head". No line, or the SHA is gone (e.g. a force-pushed rebase): full review. This avoids reading the same diff twice.
5. Spawn one fresh review sub-agent that hasn't seen the build or any earlier review. Pass inline: the diff from step 4, the slice map, relevant CLAUDE.md sections, the spec's acceptance criteria, Outcome, and Deviations, diff-relevant gotchas, the scope-outs, the local-mode review instructions (architecture plus the checklist), and the merge-gate instructions below. It reviews slice by slice, then the whole.
6. **One output contract.** The local-mode instructions say what to look for; the output is the STATUS template. Map blocker → P0, important → P1, nit → P2, re-check each against the definitions below, and return `ship` or `fix-then-ship`. `waiting` doesn't apply.

---

**Merge-gate instructions for sub-agent:**

You are the deciding merge gate. Return `ship`, `fix-then-ship`, or `waiting` from the open findings, the severity rubric, and the harness's addressed and scope-out classifications. Addressed findings are informational; don't re-evaluate them. Confirm **likely addressed** ones by reading the code at the flagged location, and treat them as open if the problem is still there. Scope-out items are out of this verdict. A `+1` reaction with no inline comments means the bot found zero issues: verdict `ship`. In the no-bot flow you generated the findings; skip the waiting step.

1. **If status is `waiting`**, return `waiting` immediately with the gap (latest SHA + minutes since push, last reviewed SHA).
2. **Re-classify each open finding by actual blast radius on this diff.** The bot's P-label is a hint:
   - **Real P0**: merging now causes a concrete bad outcome: data corruption in flight, a security exploit (auth bypass, unsigned webhook on a prod path, exposed secret), a money-loss vector with realistic trigger frequency, RLS missing on tenant data. Ship-blocker.
   - **Real P1**: real bug, narrow blast radius: edge-case correctness, observability gap, partial state on a recoverable path, type laundering on a CLI or fixture path.
   - **P2**: taste, a sibling instance of an addressed pattern, future cleanup. Suppress unless it has concrete blast radius the rubric misses.
3. **Pattern-dedup.** Findings describing the same pattern across files count as one. Inflated counts shouldn't block merge.
4. **Verdict:**
   - No real P0 or P1 open → `ship`.
   - Real P0 open → `fix-then-ship`, each with file:line and a concrete fix.
   - Real P1 open with a small fix (single file, no design decision, no new test scaffold) → `fix-then-ship`. Fix inline: a follow-up issue costs more in an AI workflow, because the next session re-loads the code, re-reads the finding, and re-learns the deferral.
   - Real P1 open that needs its own scope (cross-file refactor, new test scaffold, design decision pending) → `ship`, recommending follow-up issues be filed before merging. The bar for deferral is "needs its own scope," not "is a P1."
5. **Judge per finding, not by round.** Round 5+ findings are usually taste and sibling noise, and you're the layer that says "good enough, merge." A real security hole found at round 8 is still a real security hole, and a genuine money-loss path is P0 whatever the bot labeled it.

**Output: exactly one of the three templates.** No extra sections, no PR or round recap, no prose restating the STATUS. "Codex" stands for the project's bot; in the no-bot flow the `ship` gist names the fresh review (e.g. "clean", "fresh review, 3 nits").

**`fix-then-ship`:**

```
STATUS: fix-then-ship · <count> P<sev>s, <one-line gist (e.g., "both sibling instances of just-fixed patterns")>

**P<sev>** `<file:line>` · <one-line concern, with sibling-pattern reference if relevant>
   Fix: <concrete one-line action with LOC estimate when meaningful>

**P<sev>** `<file:line>` · <one-line concern>
   Fix: <concrete one-line action>

Apply <all|both|the fix> inline?
```

**`ship`:**

```
STATUS: ship · <gist (e.g., "clean", "2 P1s deferred to #94, #95", "18 Codex findings, all taste/dedup")>

Pre-merge: /deslop  (final cleanup; may be no-op if pre-commit deslop already caught it)
Merge: <merge command>
```

`<merge command>` is the project's merge convention from CLAUDE.md / AGENTS.md. Default: `gh pr merge <n> --rebase`, so per-slice commits survive on main (squash loses per-slice revert).

**`waiting`:**

```
STATUS: waiting · Codex hasn't reviewed <sha-short> yet (<delta minutes since push>)

Re-run in ~5 min or use `/loop /eng-check <n>`.
```

**Machine-parseable contract (`/loop` parses this):**
- `STATUS:` is the first thing on the first line, followed by a space and the token (`ship` / `fix-then-ship` / `waiting`).
- The gist after ` · ` is never empty; write `clean` if there's nothing else to say.
- In `fix-then-ship`, every finding is a bold P-level + `file:line` + one-line concern with an indented Fix line, no headings between findings, and the apply prompt is the last line.

With a bot, the gate judges existing findings; it doesn't generate new ones. Architecture belongs to local mode, the rest to the bot. Without a bot, the fresh review is the only reviewer and covers both lenses.

---

## Compound draft (automatic)

After the review, ask: **did this change involve something non-obvious a teammate would hit again?** Non-obvious means not findable from the code, docs, or error messages: API quirks, hard-won debugging insights, integration gotchas, patterns that broke unexpectedly. Most reviews produce nothing; then do nothing.

If something is worth capturing, write a 10-20 line seed to `docs/solutions/.drafts/<descriptive-name>.md`:

```markdown
---
title: [descriptive title]
date: [YYYY-MM-DD]
tags: [technology, pattern, or domain tags]
pr: [PR number or branch name]
status: draft
---

## What was non-obvious

[What the review surfaced that a teammate would benefit from knowing]

## Signal

[The findings, edge cases, or patterns that flagged it]
```

After the PR merges, the draft gets promoted into `docs/solutions/` (see `/eng-build`'s Capture step).
