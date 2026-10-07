# How the Skills Work Together

> A walkthrough of building a real feature using the full skill cycle, from vague idea to merged code. Shows how the playbook's engineering principles are embedded in every step.

---

## The feature: Citation Tracking

Track whether a brand appears in AI search results. This is the first feature for an AEO (Answer Engine Optimization) tool.

---

## Who does what

Three roles run through every step:

- **The orchestrator** (your main session) plans, reads every diff, and judges. It stays accountable even when it delegates.
- **One coder agent** writes the code. It stays alive across slices so it keeps its context instead of re-reading the repo each time.
- **Reviewers are always fresh agents** that never saw the build: the spec stress-tester, the `/eng-check` reviewer, the QA tester, `/deslop`. Safety-critical code (anything that can type into, close, or restart what you're using) gets a second fresh review that hasn't seen the first verdict.

The builder never judges its own work. That's Principle #7, and it shows up in every step below.

---

## Step 1: `/eng-init` (one-time setup)

Scaffolds a CLAUDE.md with engineering principles, Do/Don't rules, feature structure patterns, and doc references for your stack. Every future AI session in this project reads this file first.

Run once per project. The principles compound, and every session benefits.

---

## Step 2: `/eng-spec citation-tracking` (planning)

You describe a vague idea: "I want to track if a brand shows up in AI search results."

**Triage first.** The skill checks whether this is a feature or a fix. A fix (something broken, something QA caught) skips the spec entirely, because the bug is the spec: reproduce, root cause, guard test, `/eng-check`. Citation tracking is new surface, so it's a feature.

**Phase 0: shared understanding.** The skill asks focused questions one at a time, and it leads each one with its recommended answer. It doesn't enter plan mode and doesn't save anything yet. The goal is that *you* could explain the design to a teammate.

```
> Which AI platforms should we track in v1?
  Recommended: ChatGPT + Perplexity. Two platforms are enough to validate
  the approach (YAGNI).

> How should we check for citations?
  Not sure yet. Need to explore.
```

When a question needs research, the orchestrator looks up each option itself (from official docs, not memory), and one deep-reasoning agent weighs the trade-off:

```
Option A: DataForSEO AI Search API. They handle the prompting,
          you get structured responses. Simpler, dependency on third party.

Option B: Direct API calls to ChatGPT + Perplexity APIs.
          Full control, but more complexity to maintain.

Recommendation: Option A for v1.
Simplicity: DataForSEO handles the hard part.
Type 2 decision: you can switch to direct APIs later.
```

Phase 0 ends with a short list of assumptions you confirm ("results get a new table, not the existing one"). They go into the spec, and the build re-checks them after slice 1.

**Research, then the spec.** The orchestrator maps codebase fit itself (files, patterns, prior art in `docs/solutions/`), and one deep-reasoning agent covers edge cases and constraints. The spec gets written from those findings, so "Proposed approach" points at real file paths. Every acceptance criterion names its proof, and the work is cut into vertical slices, with slice 1 ordered to hit the riskiest assumption first.

**Stress test.** Then it **spawns one fresh sub-agent to stress-test the spec** (the builder shouldn't be the reviewer). It gets the spec, the principles, and the relevant code snippets inline, so it doesn't re-explore. It comes back with labeled concerns:

```
**address these first** · 3 concerns (2 crucial, 1 Type 2)

1. **30s target vs sequential queries** (AC6) [fact · blocking].
   DataForSEO queries take 5-15s each; 10 in sequence is 50-150s.
   Fix: fan out in parallel and name it in Performance architecture.
2. **API key handling unspecified** (Edge cases) [blocking]. Spec says
   "no auth" but DataForSEO needs a key. Fix: server-only env var.
3. **Prompt input limits** (User flow, step 1) [Type 2]. Empty input
   or 100 prompts? Fix: cap at 10 in the shared schema.
```

The loop runs on its own for up to 3 rounds. It patches the crucial concerns in the file, parks the Type 2 one as a build-time item, and spawns a fresh stress-tester on the new version. Round 2 comes back **ready to build**, and the spec flips from `drafting` to `specced` in `specs/citation-tracking.md`. It only stops to ask you if the verdict says "rethink approach" or the loop doesn't converge.

**Principles in play:** simplicity (chose the simpler approach), YAGNI (only two platforms, not three), Type 2 decision (reversible API choice), research grounded the spec in real file paths, fresh eyes on the spec, stress-test caught the latency gap before any code existed.

---

## Step 3: `/eng-build` (execution)

New session. Claude reads the CLAUDE.md and the approved spec. The planning is done, so execution should feel easy.

The whole spec ships in one session and one PR, slice by slice. The coder builds a slice, verifies it, and commits. Each slice ends in one green commit that builds and passes tests on its own. The orchestrator reads each slice's diff before the next one starts.

```
Building specs/citation-tracking.md (3 slices).

Slice 1: DataForSEO client + one prompt end-to-end · a1b2c3d · tests pass
  Assumptions check-in: response shape matches the docs, Type 1 decisions hold
Slice 2: parallel check + results table (migration) · e4f5a6b · tests pass
  Risk slice: range review (/eng-check a1b2c3d..e4f5a6b) clean
Slice 3: results UI · 0d1e2f3 · verified in the browser, QA agent: STATUS: pass

Acceptance: 6/6
- [x] AC1 brand name + up to 10 prompts, 11th rejected. Proof: `npx vitest run citation-input`, 4 passed
- [x] AC2 queries ChatGPT and Perplexity via DataForSEO. Proof: `npx vitest run check-citations`, 3 passed
- [x] AC3 cited/not cited per prompt per platform. Proof: browser, Citations page shows the 10 x 2 grid (qa-results.png)
- [x] AC4 API down, rate limit, no results each show a message. Proof: `npx vitest run citation-errors`, 3 passed
- [x] AC5 results stored for history. Proof: `npx vitest run citation-store`, rows match the run
- [x] AC6 under 30s for 10 prompts. Proof: timed run, 14.2s
```

A few things happen along the way:

- **After slice 1, an assumptions check-in.** The build re-reads the spec's assumptions against what slice 1 revealed. A changed Type 1 decision stops the build and goes back to the spec.
- **Risk slices get a range review mid-build.** Anything that touches auth, money, publishing, a migration, or safety-critical code gets `/eng-check <sha>..<sha>` before the next slice starts.
- **UI gets verified in a real browser**, then a fresh QA agent tries to break it like a real user would.
- **A tick needs a proof.** The checklist only marks a criterion done with the command, test, or screenshot beside it.

The feature follows the project's structure conventions: thin routes, business logic in `lib/`, shared Zod schema, feature-specific UI components.

While building, the skill holds judgment questions in mind. Am I discovering this abstraction or forcing it? What breaks if this fails? Can someone understand this without opening multiple files? These aren't steps, they're a lens. If something feels off, it pauses and flags.

If something actually breaks during the build (not a typo, an unexpected failure), the skill runs its debug loop: reproduce with runtime evidence, write out 3-5 hypotheses instead of committing to the first plausible cause, fix the root cause, and guard with a test. Then it resumes where it left off. Debugging inside a build session shouldn't become a separate track.

**Principles in play:** simplicity (6 focused files), vertical slices (testable at every step), documented trade-offs (in the spec), verified against acceptance criteria with proof.

---

## Step 4: `/eng-check` (local review, before you push)

`/eng-check` spawns **one fresh sub-agent** with no build-session bias. It gets the diff, the spec's acceptance criteria, and the slice map inline, and reviews slice by slice, then the whole diff once.

It always checks architecture: principles, feature structure, naming, spec alignment. Correctness, security, type safety, and performance only run here when no PR review bot owns them. If the project has a bot (declared in AGENTS.md or CLAUDE.md), the bot covers those on the PR and local review stays architecture-only. Range mode (`/eng-check <sha>..<sha>`, used on risk slices mid-build) always runs the full checklist.

This project has no bot, so the full checklist runs:

```
Verdict: has concerns

Slice 2 (parallel check + results table)
- important · Correctness: the rate-limit error from DataForSEO goes
  to the client raw. Fix: wrap it in an AppError with a friendly message.

Slice 3 (results UI)
- nit · Empty state has no next step. Fix: link to "add prompts".

Done well: queries fan out in parallel, exactly as the spec planned.

eng-check: has concerns @ 4f2a9c1
```

Findings get fixed inline by default, while the context is loaded. A follow-up issue for a small fix costs more than the fix. Re-run, and it comes back `eng-check: looks good @ 7b1e0d4`.

If the spec was good and the build followed it, the review should be mostly clean. Lots of issues here mean the planning was incomplete.

---

## Step 5: You review, then push (own what you ship)

You look at the code. You can trace the full flow:

1. User submits brand name + prompts
2. Zod validates the input
3. `check-citations.ts` calls DataForSEO in parallel
4. Parses responses for brand mentions
5. Stores results in the database
6. Frontend renders per-prompt per-platform results

You understand every file and every decision. You could explain it to someone. You could change it next week without fear.

Then you push and open the PR. The body carries the slice map (one line per slice: name, commit range, where the risk sits), a link to the spec, and the `eng-check: looks good @ 7b1e0d4` line from Step 4. That line tells the merge gate which commits it already reviewed.

That's the difference between shipping code and owning it.

---

## Step 6: `/eng-check <PR#>` (merge gate)

A review bot finds something on every commit forever. The gate decides when it's good enough to merge.

- **With a review bot:** run `/loop /eng-check <PR#>`. It waits for the bot to review the latest commit, re-classifies each open finding by its real blast radius, and keeps going until the call is decisive.
- **Without a bot:** one `/eng-check <PR#>` pass. A fresh reviewer reads only the commits after the recorded `eng-check: ... @ <sha>` line. Nothing new means nothing to re-read.

It returns one of three answers: `ship`, `fix-then-ship`, or `waiting`.

```
STATUS: ship · clean, local review @ 7b1e0d4 covers head

Pre-merge: /deslop
Merge: gh pr merge 12 --rebase
```

---

## Step 7: `/deslop`, then merge

```
Removed 3 unnecessary comments, one redundant try/catch,
replaced an `as any` cast with a proper type, inlined a
single-use helper. 4 changes.
```

`/deslop` runs right before merge, after the gate clears. Doing it last means the noise from review rounds doesn't land on main. It spawns a fresh sub-agent that reads the project's CLAUDE.md first, then cleans the branch without the build session's context or bias. It removes AI slop (comments that restate the obvious, defensive checks that can't trigger, type casts that hide real issues) and simplifies unnecessary complexity like redundant logic or single-use abstractions. It only removes noise. If it ever touches logic, re-run the gate.

Then merge with `--rebase`, so each slice commit survives on main. Squash would collapse them into one and lose per-slice revert.

---

## Step 8: Capture (after merge, only if something surprised you)

Most builds produce no learning, and that's fine. If something non-obvious came up (an API quirk, a misleading error, a pattern that wasn't googleable), the first question is whether the mistake can be made impossible or loud instead: a structure change, a type, a lint, a test. A doc comes last, for what can't be enforced. Then it goes into `docs/solutions/` so the team never pays the same cost again.

---

## The full cycle

```
/eng-init            Set up project principles (once)
     |
/eng-spec            Triage --> Phase 0 --> Research --> Spec --> Stress-test loop
     |               (fixes skip this: the bug is the spec)
/eng-build           Slice by slice, one green commit each, debug in place
     |
/eng-check           Local review before push (one fresh sub-agent)
     |
You review + push    Own what you ship; eng-check line goes in the PR body
     |
/eng-check <PR#>     Merge gate (/loop it when there's a review bot)
     |
/deslop              Final cleanup right before merge
     |
Merge --rebase       Slice commits survive on main
     |
Capture              Only if something surprised you
```

### Standalone uses

Most skills fit the cycle above, but these also work on their own:

- **`/eng-spec stress <path>`** runs just the stress test on any spec or plan. Useful when you've written a spec by hand or want to re-challenge one after changes.
- **`/eng-check <sha>..<sha>`** reviews one commit range. The build uses it on risk slices, but it works on any range.
- **`/deslop`** works on any branch with changes, not just after `/eng-build`. Good for cleaning up code from any session.

Learnings don't need their own command. `/eng-check` writes a draft to `docs/solutions/.drafts/` when it spots something non-obvious, and the Capture step after merge promotes it into `docs/solutions/` or drops it. Captured solutions feed back into `/eng-spec`'s research.

---

Most of the work happens before and after writing code. The spec forces planning. The research grounds it in real codebase evidence. The stress-test catches assumptions. The build ships in slices and proves every criterion. One fresh reviewer checks it before push, and the merge gate decides when it's good enough. Deslop takes out the noise last. And at the end, you understand what you shipped.

The principles aren't abstract. They're embedded in every step.
