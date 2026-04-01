---
name: eng-build
description: Build a feature from an approved spec file. Execution session — the planning is already done.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
argument-hint: [spec-file]
---

Build a feature from an approved spec file. This is an execution session — the planning is already done. If the spec was thorough, this should be the easy part.

**What you need before starting:**
- Read the project's CLAUDE.md for engineering principles and conventions.
- Ask the user which spec to build from. Look in the `specs/` directory for available specs, or accept a file path.
- Read the spec file completely.

Trust the spec. The planning session already explored the codebase, identified relevant files, and made architectural decisions. If something in the spec seems outdated or wrong, flag it to the user — don't go off-script.

**Your goal:**
Build the feature described in the spec. The acceptance criteria are your definition of done. The project's CLAUDE.md conventions are your constraints. You have access to the codebase, tools, and everything you need — figure out the best way to get there.

Before writing code, give the user a brief summary of what you're about to build and flag anything that looks outdated or unclear. Wait for the go-ahead.

After that, execute. Break the work into whatever chunks make sense, briefly state progress at natural milestones, and use the tools available to verify your work as you go.

**While building, hold these in mind:**
- Am I discovering this abstraction or forcing it?
- Am I building for a real requirement or an imaginary one?
- Can someone understand this behavior without opening multiple files?
- What happens when this input is empty, null, or unexpected?
- What else does this change touch? What breaks if it fails?

These aren't steps — they're judgment. If something feels off, pause and flag it.

**When you think you're done, check:**
- Does every acceptance criterion in the spec pass?
- Does the code follow the project's conventions (from CLAUDE.md)?
- Are edge cases from the spec handled?
- Can someone understand this without opening multiple files?
- Have you verified the code works (tests, build, lint, browser — whatever's appropriate)?

Be honest about what's done and what isn't. Present the result referencing the spec's acceptance criteria as a checklist.

**Verify with fresh eyes (Principle #8).** If the feature has a UI or user-facing behavior, spawn a sub-agent to try to break it. Pass the context directly -- don't make it re-read the spec or explore the codebase. Run it in the background (`run_in_background: true`) so you can present the build results while QA runs.

The sub-agent prompt should include:

1. The acceptance criteria (inline, not a file path)
2. The URL to test
3. What was built -- which files changed and what they do (brief summary)
4. Any relevant edge cases from the spec

Example prompt structure:

"You are a QA tester with fresh eyes. You did not build this feature.

Here are the acceptance criteria:
[paste acceptance criteria from spec]

The app is running at: [URL]

Here is what was built:
[brief summary of changes -- files modified, what each does]

Edge cases to watch for:
[paste edge cases from spec]

Your job is to verify the feature works and try to break it. Test the happy path first, then try edge cases: empty inputs, rapid clicks, unexpected values, browser back button, refresh mid-flow.

Report what works, what breaks, and what feels off. Be specific -- include what you did and what happened."

If the sub-agent finds issues, fix them before marking as done. Skip this step for backend-only changes or when there's no running app to test against.

**Mark the spec as built.** Add `status: built` and the date to the top of the spec file. This keeps `specs/` clean -- you can tell at a glance what's pending vs done.

**After shipping — reflect (only if something surprised you):**
Skip this if the build was straightforward. Most sessions won't produce a learning. But if something unexpected came up, ask the user:
- What trade-off did we make? What did we choose, what did we reject?
- What would we do differently next time?
- Did anything break or feel harder than expected? Why?

**Where learnings go depends on scope:**
- **`/eng-compound`** — non-obvious solutions that would save a teammate's AI session from hitting the same problem. "Would someone benefit from knowing this before they encounter it?" If yes, run `/eng-compound`.
- **CLAUDE.md** — conventions or constraints that affect how all code should be written in this project. Keep it lean.
- **Engineering Learnings & Playbook** (via `/sync-playbook`) — timeless insights that change how you think about building, not just this project.

Before adding, check for duplicates. Update an existing entry rather than adding a new one if the topic is already covered.
