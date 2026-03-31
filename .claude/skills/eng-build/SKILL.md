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

**After shipping — reflect (only if something surprised you):**
Skip this if the build was straightforward. Most sessions won't produce a learning. But if something unexpected came up, ask the user:
- What trade-off did we make? What did we choose, what did we reject?
- What would we do differently next time?
- Did anything break or feel harder than expected? Why?

**Where learnings go depends on scope:**
- **CLAUDE.md** — conventions or constraints that affect how all code should be written in this project. Keep it lean.
- **docs/learnings.md** — codebase quirks, API gotchas, edge cases. Useful knowledge that doesn't need to load every session.
- **Engineering Learnings & Playbook** (via `/sync-playbook`) — timeless insights that change how you think about building, not just this project.

Before adding, check for duplicates. Update an existing entry rather than adding a new one if the topic is already covered.
