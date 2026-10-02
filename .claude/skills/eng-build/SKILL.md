---
name: eng-build
description: Build a feature from an approved spec file. Execution session, the planning is already done. Ships the whole spec in one session and one PR, slice by slice (one green commit per slice, an assumptions check-in after slice 1, range reviews on risk slices).
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
argument-hint: [spec-file]
---

Build a feature from an approved spec file. This is an execution session; the planning is already done. If the spec was thorough, this should be the easy part.

**What you need before starting:**
- Read the project's CLAUDE.md for engineering principles and conventions, and AGENTS.md if present. Between them and the user-level CLAUDE.md they declare the per-project facts this skill reads and never hardcodes: the orchestration policy (who codes), whether a PR review bot exists, the commit and merge conventions, and which systems are safety-critical.
- Ask the user which spec to build from. Look in the `specs/` directory for available specs, or accept a file path.
- Read the spec file completely.

**No spec?** Stop and route: features go to `/eng-spec` first (a small feature gets a short spec, minutes of work), fixes skip the spec (reproduce, root cause, guard test, then `/eng-check`). The build session starts from the file, and the spec is what the review checks the diff against and where deviations get logged. A build from conversation memory has none of that.

**Preconditions.** Pass silently. Only speak to halt or ask.

1. **Status decides the entry:**
   - `status: specced`: start a new build (the slice loop's step 0 marks it `building`).
   - `status: building`: resume. Read `## Current state` and `### Deviations` first, then continue at the slice `## Current state` names as next.
   - `status: built`: halt: "spec is already built (built: <date>). Nothing to build; start a new spec for new work."
   - Anything else (`drafting`, a missing value on a spec that has frontmatter): halt: "spec is `<status>`, not ready to build. Run `/eng-spec <spec-path>` to finish it."
   - `status:` must be exactly one word. If anything follows the word (a date, progress, notes), halt: "status must be one word; move the rest to `## Current state` or `### Deviations`."
2. **Verdict:**
   - Specs with frontmatter must have `## Stress-test verdict` followed by `**ready to build**`. If absent, halt: "spec missing clean verdict. Re-run `/eng-spec <spec-path>` to iterate the draft to clean and re-save." If verdict is `address these first` / `rethink approach`, halt: "verdict is `<verdict>`. Re-run `/eng-spec <spec-path>` to iterate to clean."
   - Pre-rule specs (no frontmatter, no verdict heading): skip silently.
   - **Legacy slice frontmatter** (`slice_of:`, `slice_id:`, `build_specs:` and similar from the old multi-slice flow): treat the file as a single spec. Say so in one line ("legacy slice frontmatter ignored, building as one spec") and continue.
3. **Dependencies.** Every spec in `depends_on:` must be built and merged: `git show <base>:<dep-spec-path>` shows `status: built` (fetch the base first). If not, halt: "depends on specs not yet built and merged: [<paths>]."

Trust the spec. Second-guessing it re-opens planning sessions. If something seems outdated or wrong, flag it; otherwise start.

**Build-time items.** Reversible (Type 2) concerns the stress-test raised and the spec parked sit under `## Stress-test verdict` as `Build-time items:`. Handle each in the slice it touches. If one turns out not to be worth doing, log that in `### Deviations` with one line of reasoning.

**Keep the spec alive.** The spec is a living document, not a frozen artifact. When things change during the build:
- If the approach shifts on a Type 2 decision (internal structure, naming, ordering), update the spec, add a `### Deviations` bullet, and continue. If it shifts on a Type 1 decision (data model, API shape, public contract), stop and go back to the spec: same path as the re-spec tripwire below. A spec that doesn't match the code actively misleads the next person.
- If scope changes (features cut or added), reflect it in the spec.
- Every change from the spec gets one bullet in the spec's `### Deviations` section (add the section if the spec predates it): what changed, and the evidence that forced it.
- Link the spec from the PR body.

**When to stop and re-spec.** A build session shouldn't become a planning session. **Tripwire:** if you find yourself updating 3+ acceptance criteria, multiple key decisions, or the proposed approach itself in the same session, you're not editing the spec, you're re-specifying. Stop, surface the gap to the user: "the spec has a gap in [area], update it or re-spec?" Small scope adjustments where the architecture holds are fine to update inline. Fundamental changes need a fresh planning pass.

**Forced-split tripwire.** If the build hits an item on `/eng-spec`'s forced-split list that the spec didn't split out, stop and ask. The list: a schema migration with backfill or any destructive or irreversible data change; a change to the auth, money, or publish mechanism itself (auth flow or permission model, payment or billing logic, the publish or deploy pipeline); an acceptance criterion that depends on a post-deploy action; a cross-repo change; a refactor riding along with the feature; a change to something the user is actively running where a restart or deploy is its own gate. Each has its own gate, and bundling it into the feature PR is how it skips that gate. A slice that only *uses* existing auth, payments, or publishing is not on this list; it's a risk slice (step 6 of the slice loop).

**Your goal:** acceptance criteria = definition of done; CLAUDE.md = constraints. Figure out the best way to get there.

Before writing code, flag anything in the spec that looks outdated or unclear. If the spec is clean, proceed without summarizing. The user wrote and locked it; they don't need it read back.

## Delegation

Follow the orchestration policy in CLAUDE.md (user-level or project). Default when none is stated:
- **The orchestrator stays lead:** integration, judgment calls, and reading every diff. Delegation moves token burn, not accountability.
- **One long-lived coder agent does the implementation**, kept alive across slices with `SendMessage` so it keeps its context instead of re-reading the repo each slice. No fan-out: every extra agent re-reads the context, which costs more than it saves.
- **Small mechanical edits** (a rename, a one-file tweak) the orchestrator does itself. A round trip costs more than the edit.
- **Codex** (and `/codex:rescue`) only when the project's CLAUDE.md / AGENTS.md declares Codex.

Pin agent models deliberately per the policy; unpinned sub-agents inherit the main model.

## The slice loop

The spec's task list is grouped into slices (`#### Slice N: <name>`). Each slice is a vertical path through the feature (e.g., schema + API + UI for one flow), not a horizontal layer, so the feature stays testable and working at every step. Build the slices in order, all in this session, all into one PR. Specs without slice headings: treat each task, or each run of dependent tasks, as a slice.

**0. Mark building.** On a new build (status `specced`), set `status: building` in the frontmatter before slice 1. On a resume it's already `building`.

Then, for each slice:

1. **Brief the coder.** Send slice N's spec section, acceptance criteria, and file list inline so it doesn't re-explore.
2. **Build and verify.** The coder builds, then runs the slice's Verify steps. Before moving on, confirm:
   - Tests pass
   - Application builds without errors
   - The slice's user flow works end-to-end

   For UI or user-facing slices, "works" means it works *in a real browser*, not "the build compiled" or "the tests are green." Drive the feature with the project's browser tools (e.g. Playwright MCP: `mcp__playwright__browser_navigate`, `_click`, `_fill_form`, `_snapshot`, `_console_messages`, `_network_requests`) and click through as a user would. Types and tests prove code correctness; browsers prove feature correctness, and they surface a whole class of bugs the compiler can't see (hydration mismatches, runtime console errors, failed network calls, broken nav, stale cache). Make sure the dev server is running first (check `package.json` scripts, commonly `npm run dev`); after server-side changes (API routes, middleware, server components, env vars, config), re-navigate to force a fresh fetch before re-verifying, otherwise stale RSC/middleware responses will make a correct change look broken.
3. **Commit.** One commit per slice (or a short run of commits that ends green), with a message that names the slice. The slice's last commit must build and pass tests on its own, so the PR can be bisected and reverted slice by slice. Use the project's commit convention if CLAUDE.md / AGENTS.md defines one.
4. **Read the diff.** The orchestrator reads the slice's diff before the next slice starts. Don't push through many slices hoping they all work together at the end. Catch breakage early while the cause is obvious.
5. **After slice 1 only: assumptions check-in.** Re-read the spec's `### Assumptions` section and the Type 1 entries under Key decisions against what slice 1 revealed. A changed Type 1 decision stops the build and goes back to the spec (same path as the re-spec tripwire). A Type 2 change gets a bullet in `### Deviations` and the build continues. Slice 1 was ordered to surface the riskiest assumption; this is where that pays off.
6. **Risk slices get a range review.** A slice that uses auth, money, or publish paths, adds a migration, or touches anything the project marks safety-critical (e.g. code that can type into, close, or restart what the user is using) gets `/eng-check <first-sha>^..<last-sha>` over that slice's commits before the next slice starts. If the risk slice is the last slice, skip the separate range review: the end review covers it. Every other slice is reviewed once at the end, not per slice: per-slice reviews on ordinary slices cost more round trips than they catch.
7. **Log deviations.** Anything that differs from the spec gets one bullet in `### Deviations` with the evidence that forced it.
8. **Coder context hygiene.** Reset the coder when its replies start dropping earlier details or contradicting the spec, or after about 5 slices, whichever comes first. Before it's replaced, the coder writes the checkpoint below. Start the fresh coder from the spec plus that checkpoint, with a handoff message that carries operational state only (the slice to start, the branch, tree caveats such as uncommitted files or a dev server that must be running), usually three lines. The spec carries the rest. A fresh coder reading a good checkpoint makes better edits than one deep in a saturated context.

State progress briefly after each slice: slice name, commit, verify result.

**Current state checkpoint.** Before a coder reset, before `/compact`, or when the session nears its compaction point, add or rewrite a `## Current state` section at the end of the spec: what's built, which slice is next, any open thread (failing test, blocked decision, mid-refactor file). Log any change from the spec in `### Deviations`. This is what a fresh session or a fresh coder resumes from.

**When something breaks unexpectedly:** If you hit an error that isn't a simple typo or missing import and you can't resolve it in one attempt, run the debug loop: stop, preserve the error evidence, reproduce, localize, understand the root cause, fix it, and write a guard test. Write 3-5 hypotheses out before testing any; a root cause that doesn't explain why this never broke before isn't the root cause yet. Revert speculative guards from rejected hypotheses. Don't guess randomly or suppress the error. Complete the loop before resuming the build. If the root cause was non-obvious, capture it at the end (see Capture).

**When the debug loop itself stalls** (hypotheses worked, root cause still unclear), stop grinding in one context: put the problem to two independent contexts in parallel (e.g. a fresh deep-reasoning agent and a second fresh agent per the orchestration policy; `/codex:rescue` when the project declares Codex), each with the error evidence and repro steps but not each other's answers, then compare diagnoses. A second independent context beats a third lap in a biased one.

**Scope discipline.** Only touch what the task requires. Don't refactor adjacent code, add unspecified features, or "improve" things you notice along the way. If something genuinely needs fixing, flag it. Don't silently fix it mid-task.

**In-session findings: default to inline-fix.** Different from the scope-discipline rule above: that rule prevents opportunistic refactoring of unrelated code. This rule is about findings on the work you just did. When `/eng-check` mid-build flags a blocker or important, when the QA sub-agent reports `STATUS: breaks` / `feels-off`, when browser-verify catches an issue, default to fixing it now in the same session if **all** of these hold:

- Single-file change.
- No new test scaffold required.
- No design decision pending user input.

Otherwise, surface the finding to the user with a one-line summary and ask. **Never auto-spec the fix. Never quietly file a follow-up issue.** The build session is where the context is loaded; fixing now amortizes that context. A "follow-up issue" or a new spec for a small fix costs more than the fix itself in an AI workflow: future sessions have to re-load the code, re-read the finding, re-understand the deferral. Filing the issue is the work, not a shortcut from it. The inline path is the cheap path.

This rule is the antidote to the spec-everything pattern: every finding does NOT need its own spec. Most don't even need their own commit.

**While building, hold these in mind:**
- **Abstraction tripwire:** if you're extracting an abstraction with one current use, inline it. Wait for the third instance. Discover, don't design.
- Am I building for a real requirement or an imaginary one?
- Can someone understand this behavior without opening multiple files?
- **Input tripwire:** if you wrote a function and didn't think about empty/null/unexpected input, you didn't finish writing it.
- What else does this change touch? What breaks if it fails?

These aren't steps; they're judgment. If something feels off, pause and flag it.

## Done

**When you think you're done, check:**
- Does every acceptance criterion in the spec pass?
- Does the code follow the project's conventions (from CLAUDE.md)?
- Are edge cases from the spec handled?
- Can someone understand this without opening multiple files?
- Have you verified the code works (tests, build, lint, browser, whatever's appropriate)?

Be honest about what's done and what isn't. Present the result as the spec's acceptance-criteria checklist, led by `Acceptance: <pass>/<total>` for the scan-glance. Tick a criterion `[x]` only with its proof beside it: the command and its result, the test name, or a screenshot reference. A tick without proof is not a pass. Mark unmet criteria `[ ]` with `file:line` and the gap. The checklist is the durable record; the count line is the headline.

```
Acceptance: 4/5
- [x] AC1 invite link expires after 7 days. Proof: `npx vitest run invite-expiry`, 3 passed
- [x] AC2 sender sees confirmation. Proof: browser, Settings > Team > Invite shows "Invite sent" (qa-ac2.png)
- [ ] AC5 resend is idempotent. Gap: src/lib/invites/send.ts:42 retries create a second token
```

**Verify with fresh eyes (Principle #8).** If the feature has a UI or user-facing behavior, spawn a sub-agent to try to break it. Pass the context directly; don't make it re-read the spec or explore the codebase. Run it in the background (`run_in_background: true`) so you can present the build results while QA runs. Run it as a fresh agent (not the coder) at the orchestration policy's default sub-agent tier: QA rigor lives in the prompt, not the tier, and browser QA is the most snapshot-heavy work in the pipeline. Pin it deliberately; an unpinned sub-agent inherits the expensive main model.

Confirm the dev server is running before spawning the sub-agent: it can't test what isn't serving. If it isn't, start it (e.g. `npm run dev`) via a backgrounded Bash call first. The sub-agent uses the project's browser tools (e.g. Playwright MCP) to drive the app as a real user would: no direct API hits, no internal-only routes, no reasoning from the source code.

The sub-agent prompt should include:

1. The acceptance criteria (inline, not a file path)
2. The URL to test
3. What was built: which files changed and what they do (brief summary)
4. Any relevant edge cases from the spec

Example prompt structure:

"You are a QA tester with fresh eyes. You did not build this feature.

Drive the browser directly with the project's browser tools (e.g. Playwright MCP: `mcp__playwright__browser_navigate` to load pages, `_snapshot` to see what's on screen, `_click` / `_fill_form` / `_type` / `_select_option` / `_press_key` to interact, `_console_messages` to catch runtime errors, `_network_requests` to spot failed API calls, `_take_screenshot` when the user-visible rendering matters). Do NOT write browser test files or spawn a test runner. Drive the live browser, observe, and report.

Test like a real user. Navigate through the UI the way someone would actually use it. Don't go to internal URLs directly, don't call APIs, don't use knowledge of the code. If a user would click a nav link to get to a page, you click the nav link. Users don't know about your internal tools, so test the experience they'll actually have.

Stay within the surfaces listed in the change summary plus the edge cases below; don't explore pages the change can't affect. When reading console or network output, filter with a pattern instead of dumping everything.

Beyond verifying acceptance criteria, flag anything that feels off from a user's perspective: missing loading states, no feedback after actions, confusing copy, weird sizing or layout, empty states with no guidance, buttons that don't look clickable, unclear what just happened. If it's technically working but the experience feels unfinished, call it out.

Perceived-performance check: time the critical path roughly. How long from the user's action to first meaningful content? How long until they can act on it? Watch for dead air, where the user stares at a spinner or empty state with nothing visibly happening. On streaming features (chat, real-time updates, progressive lists, server-sent events), watch for stalled streams, missing first-byte, content that arrives in one batch instead of progressively, or progressive content that feels jumpy. Use the network request log to count critical-path requests; flag avoidable serial round trips or fan-out that should have been parallel.

Here are the acceptance criteria:
[paste acceptance criteria from spec]

The app is running at: [URL]

Here is what was built:
[brief summary of changes: files modified, what each does]

Edge cases to watch for:
[paste edge cases from spec]

Your job is to verify the feature works and try to break it. Test the happy path first, then try edge cases: empty inputs, rapid clicks, unexpected values, browser back button, refresh mid-flow. Check the console messages for runtime errors and the network requests for failed or 4xx/5xx calls: a UI can render fine while logging errors or silently failing.

Report shape: STATUS line + findings + nothing else.

If everything passes, the entire output is `STATUS: pass`. Otherwise: `STATUS: breaks` (or `STATUS: feels-off`) followed by one bullet per finding:

- **break** or **feels-off** · <page or component> · <one-line concern> · <what you did to surface it>

Include screenshots inline when the visual rendering is the point of the bug. No traversal logs ('I clicked X, then Y, then Z'); the findings are the report, the steps you took are not."

If the sub-agent finds issues, fix them before marking as done. On re-verification after fixes, re-check only the criteria that failed, not the full pass. Skip this step for backend-only changes or when there's no running app to test against.

**Mark the spec as built.** Set `status: built` and add `built: <YYYY-MM-DD>` in the frontmatter. `status:` stays one word; what changed along the way lives in `### Deviations`, never in the status field. This keeps `specs/` scannable: you can tell at a glance what's pending vs done.

## Ship

**PR body.** Carry a slice map (one line per slice: name, commit range, where the risk sits), a link to the spec, and `## Out of scope`:

```
## Slices
1. invite schema + send API · a1b2c3d..e4f5a6b · risk: token generation (range-reviewed mid-build)
2. accept flow · f7a8b9c..0d1e2f3 · risk: none beyond UI states
3. resend + expiry · 4a5b6c7..8d9e0f1 · risk: idempotency on resend

## Out of scope
- ...
```

**Before pushing, run /eng-check.** Local mode, no args. It reads the slice map (from the spec's task list, or the PR body if it exists) and reviews slice by slice in order, then the whole. The build session shouldn't review its own work: fresh eyes catch what the author can't (Principle #7). Once the verdict has no open blockers or importants, put the line it reports (`eng-check: <verdict> @ <sha>`, the HEAD it reviewed) in the PR body. The PR gate reads it to skip re-reviewing those commits.

**After pushing.** If the project declares a PR review bot (AGENTS.md / CLAUDE.md), `/loop /eng-check <PR#>` self-paces against the bot until the merge gate is decisive. If it doesn't, the gate is the local `/eng-check` verdict plus one `/eng-check <PR#>` pass, which runs a fresh review over the commits after the recorded `eng-check: ... @ <sha>` line (a full review only if no local verdict was recorded).

**Judge independence.** Whoever wrote the code doesn't judge it. The reviewer is always a fresh agent that hasn't seen the build session. For safety-critical code (whatever the project marks as such, e.g. code that can type into, close, or restart what the user is using), add a second fresh review that hasn't seen the first verdict. When the project's coder and its review bot are the same vendor (e.g. Codex writes the code and Codex reviews the PR), the bot's findings on that code carry less weight, and the local `/eng-check` is the independent gate.

**Before merging, run /deslop.** Final gate after `/eng-check <PR#>` clears. Strips dead defensive checks, single-use abstractions, AI-comment noise, stray `as any` casts that crept in during fix iterations. Catching slop here (instead of pre-push) means iteration noise from review cycles doesn't land on main. Deslop should only remove dead/noise code; if it ever edits logic, re-run `/eng-check <PR#>` before merging.

**Merge** per the project's convention (CLAUDE.md / AGENTS.md). Default when none is stated: `gh pr merge <n> --rebase`, so the slice commits survive on main. Squash collapses them into one and loses per-slice revert.

## Capture (after merge, only if something surprised you)

Most builds produce no learning; skip this then. Capture only what isn't findable from the code, docs, git history, or error messages: an API quirk, a misleading error, an integration gotcha, a root cause that took real digging. If you can't write why it was hard to find in 2-3 specific sentences, it's a normal solution; skip it.

**Where it goes:**
- **CLAUDE.md**: a convention or constraint for all code in this project. Keep it lean.
- **Engineering Learnings & Playbook** (via `/sync-playbook`): a timeless insight about building, not just this project.
- **`docs/solutions/<kebab-name>.md`**: a non-obvious solution a teammate's AI session should know before hitting the same problem. One problem per doc, 20-40 lines, frontmatter `title`, `date`, `tags`, `pr`, then `## Problem`, `## Why it's hard to find`, `## Solution`, `## Context`. Also promote any drafts `/eng-check` left in `docs/solutions/.drafts/` for this PR: combine the draft with the PR history (`gh pr view <n> --json title,body,comments,reviews,files`), write the doc, and delete the draft. If the project CLAUDE.md doesn't mention `docs/solutions/`, add a one-line Knowledge base entry pointing to it.

Search for an existing entry first and update it rather than adding a duplicate. Ask the user to confirm each entry before saving.
