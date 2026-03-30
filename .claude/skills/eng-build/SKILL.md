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

**When you think you're done, check:**
- Does every acceptance criterion in the spec pass?
- Does the code follow the project's conventions (from CLAUDE.md)?
- Are edge cases from the spec handled?
- Can someone understand this without opening multiple files?
- Have you verified the code works (tests, build, lint, browser — whatever's appropriate)?

Be honest about what's done and what isn't. Present the result referencing the spec's acceptance criteria as a checklist.

**Capture learnings (only if something surprised you):**
Skip this if the build was straightforward. Only ask if something unexpected came up — a codebase quirk, an API behavior, a pattern that worked unusually well or poorly.

Where it goes depends on scope:
- **CLAUDE.md** — only if it's a convention or constraint that affects how all code should be written in this project. Keep CLAUDE.md lean.
- **docs/learnings.md** — codebase quirks, API gotchas, edge cases discovered. Accumulated knowledge that's useful but doesn't need to load every session.

Before adding, check `docs/learnings.md` for duplicates. Update an existing entry rather than adding a new one if the topic is already covered. Not every build session produces a learning — most won't.
