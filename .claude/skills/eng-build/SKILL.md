---
name: eng-build
description: Build a feature from an approved spec file. Execution session — the planning is already done.
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
argument-hint: [spec-file]
---

Build a feature from an approved spec file. This is an execution session — the planning is already done. If the spec was thorough, this should be the easy part.

**What you need before starting:**
- Read the project's CLAUDE.md for engineering principles and conventions.
- Ask the user which spec to build from. Look in the `specs/` directory for available specs, or accept a file path.
- Read the spec file completely.

**Preconditions.** Pass silently — only speak to halt or ask.

1. Spec has `## Stress-test verdict` followed by `**ready to build**`. If absent, halt: "spec missing clean verdict — re-run `/eng-spec <spec-path>` to iterate the draft to clean and re-save." If verdict is `address these first` / `rethink approach` (legacy specs only — new specs never reach disk in that state), halt: "verdict is `<verdict>` — re-run `/eng-spec <spec-path>` to iterate to clean." Pre-rule specs without the heading: skip silently.
2. Sub-specs only (frontmatter has `slice_of:`): every entry in `slice_depends_on:` must be `status: built` in its sibling sub-spec. If not, halt: "depends on unbuilt slices: [<ids>]."

Trust the spec. The stress-test gate signed off on it; second-guessing now is what re-opens planning sessions, and that's exactly what /eng-spec's lock rule prevents. If something seems outdated or wrong, flag it; otherwise start.

**Keep the spec alive.** The spec is a living document, not a frozen artifact. When things change during the build:
- If the approach shifts (different data model, different API shape), update the spec first, then implement. A spec that doesn't match the code actively misleads the next person.
- If scope changes (features cut or added), reflect it in the spec.
- Reference the spec section in PRs — link back to what each PR implements.

**When to stop and re-spec.** A build session shouldn't become a planning session. **Tripwire:** if you find yourself updating 3+ acceptance criteria, multiple key decisions, or the proposed approach itself in the same session, you're not editing the spec — you're re-specifying. Stop, surface the gap to the user: "the spec has a gap in [area], update it or re-spec?" Small scope adjustments where the architecture holds are fine to update inline. Fundamental changes need a fresh planning pass.

**Your goal:** acceptance criteria = definition of done; CLAUDE.md = constraints. Figure out the best way to get there.

Before writing code, flag anything in the spec that looks outdated or unclear. If the spec is clean, proceed without summarizing. The user wrote and locked it; they don't need it read back.

After that, execute. Follow the task list in the spec. Each task is a vertical slice — a complete path through the feature (e.g., schema + API + UI for one flow), not a horizontal layer. This keeps the feature testable and working at every step. When tasks are marked independent (no dependencies on each other), they can be built in parallel (e.g., in separate worktrees). Respect dependency order for the rest.

**Checkpoint at natural boundaries** -- after completing a vertical slice, or when multiple tasks connect. Stop and verify:
- Tests pass
- Application builds without errors
- Core user flow works end-to-end

For UI or user-facing tasks, "works" means it works *in a real browser* — not "the build compiled" or "the tests are green." Drive the feature with the Playwright MCP tools (`mcp__playwright__browser_navigate`, `_click`, `_fill_form`, `_snapshot`, `_console_messages`, `_network_requests`) and click through as a user would. Types and tests prove code correctness; browsers prove feature correctness — and they surface a whole class of bugs the compiler can't see (hydration mismatches, runtime console errors, failed network calls, broken nav, stale cache). Make sure the dev server is running first (check `package.json` scripts — commonly `npm run dev`); after server-side changes (API routes, middleware, server components, env vars, config), re-navigate to force a fresh fetch before re-verifying, otherwise stale RSC/middleware responses will make a correct change look broken.

Don't push through many tasks hoping they all work together at the end. Catch breakage early while the cause is obvious. Briefly state progress at each checkpoint.

**When something breaks unexpectedly:** If you hit an error that isn't a simple typo or missing import and you can't resolve it in one attempt, shift into the eng-debug methodology: stop, preserve the error evidence, reproduce, localize, understand the root cause, fix it, and write a guard test. Don't guess randomly or suppress the error. Complete the debug loop before resuming the build. If the root cause was non-obvious, flag it for `/eng-compound` after the PR merges.

**Scope discipline.** Only touch what the task requires. Don't refactor adjacent code, add unspecified features, or "improve" things you notice along the way. If something genuinely needs fixing, flag it — don't silently fix it mid-task.

**While building, hold these in mind:**
- **Abstraction tripwire:** if you're extracting an abstraction with one current use, inline it. Wait for the third instance — discover, don't design.
- Am I building for a real requirement or an imaginary one?
- Can someone understand this behavior without opening multiple files?
- **Input tripwire:** if you wrote a function and didn't think about empty/null/unexpected input, you didn't finish writing it.
- What else does this change touch? What breaks if it fails?

These aren't steps — they're judgment. If something feels off, pause and flag it.

**When you think you're done, check:**
- Does every acceptance criterion in the spec pass?
- Does the code follow the project's conventions (from CLAUDE.md)?
- Are edge cases from the spec handled?
- Can someone understand this without opening multiple files?
- Have you verified the code works (tests, build, lint, browser — whatever's appropriate)?

Be honest about what's done and what isn't. Present the result as the spec's acceptance-criteria checklist with each item marked `[x]` (pass) or `[ ]` (unmet). Lead with `Acceptance: <pass>/<total>` for the scan-glance. Annotate any unmet criterion with `file:line` and the gap. The checklist is the durable record; the count line is the headline.

**Verify with fresh eyes (Principle #8).** If the feature has a UI or user-facing behavior, spawn a sub-agent to try to break it. Pass the context directly -- don't make it re-read the spec or explore the codebase. Run it in the background (`run_in_background: true`) so you can present the build results while QA runs.

Confirm the dev server is running before spawning the sub-agent — it can't test what isn't serving. If it isn't, start it (e.g. `npm run dev`) via a backgrounded Bash call first. The sub-agent uses the Playwright MCP browser tools to drive the app as a real user would — no direct API hits, no internal-only routes, no reasoning from the source code.

The sub-agent prompt should include:

1. The acceptance criteria (inline, not a file path)
2. The URL to test
3. What was built -- which files changed and what they do (brief summary)
4. Any relevant edge cases from the spec

Example prompt structure:

"You are a QA tester with fresh eyes. You did not build this feature.

Drive the browser directly with the Playwright MCP tools — `mcp__playwright__browser_navigate` to load pages, `_snapshot` to see what's on screen, `_click` / `_fill_form` / `_type` / `_select_option` / `_press_key` to interact, `_console_messages` to catch runtime errors, `_network_requests` to spot failed API calls, `_take_screenshot` when the user-visible rendering matters. Do NOT write Playwright test files or spawn a test runner — drive the live browser, observe, and report.

Test like a real user. Navigate through the UI the way someone would actually use it. Don't go to internal URLs directly, don't call APIs, don't use knowledge of the code. If a user would click a nav link to get to a page, you click the nav link. Users don't know about your internal tools — test the experience they'll actually have.

Beyond verifying acceptance criteria, flag anything that feels off from a user's perspective: missing loading states, no feedback after actions, confusing copy, weird sizing or layout, empty states with no guidance, buttons that don't look clickable, unclear what just happened. If it's technically working but the experience feels unfinished, call it out.

Here are the acceptance criteria:
[paste acceptance criteria from spec]

The app is running at: [URL]

Here is what was built:
[brief summary of changes -- files modified, what each does]

Edge cases to watch for:
[paste edge cases from spec]

Your job is to verify the feature works and try to break it. Test the happy path first, then try edge cases: empty inputs, rapid clicks, unexpected values, browser back button, refresh mid-flow. Check `browser_console_messages` for runtime errors and `browser_network_requests` for failed or 4xx/5xx calls — a UI can render fine while logging errors or silently failing.

Report shape: STATUS line + findings + nothing else.

If everything passes, the entire output is `STATUS: pass`. Otherwise: `STATUS: breaks` (or `STATUS: feels-off`) followed by one bullet per finding:

- **break** or **feels-off** · <page or component> · <one-line concern> · <what you did to surface it>

Include screenshots inline when the visual rendering is the point of the bug. No traversal logs ('I clicked X, then Y, then Z'); the findings are the report, the steps you took are not."

If the sub-agent finds issues, fix them before marking as done. Skip this step for backend-only changes or when there's no running app to test against.

**Mark the spec as built.** Add `status: built` and the date to the top of the spec file. This keeps `specs/` clean -- you can tell at a glance what's pending vs done.

**Before pushing, run /deslop, then /eng-check.** /deslop strips slop from the diff first: dead defensive checks that can't fire, single-use abstractions, AI-comment noise, stray `as any` casts. Then /eng-check reviews architecture on a clean diff. The build session shouldn't review its own work — fresh eyes catch what the author can't (Principle #7), and the review isn't distracted by surface slop. Once both pass and you've pushed, `/loop /eng-check <PR#>` self-paces against Codex until the merge gate is decisive.

**After shipping — reflect (only if something surprised you):**
Skip this if the build was straightforward. Most sessions won't produce a learning. But if something unexpected came up, ask the user:
- What trade-off did we make? What did we choose, what did we reject?
- What would we do differently next time?
- Did anything break or feel harder than expected? Why?

**Where learnings go depends on scope:**
- **CLAUDE.md** — conventions or constraints that affect how all code should be written in this project. Keep it lean.
- **Engineering Learnings & Playbook** (via `/sync-playbook`) — timeless insights that change how you think about building, not just this project.
- **`/eng-compound`** — non-obvious solutions that would save a teammate from hitting the same problem. Run this after the PR is merged, not now -- the solution needs to survive reviews and testing before it's worth capturing.

Before adding, check for duplicates. Update an existing entry rather than adding a new one if the topic is already covered.
