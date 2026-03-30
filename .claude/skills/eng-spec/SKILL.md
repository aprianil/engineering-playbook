---
name: eng-spec
description: Write a feature spec before building anything. Planning session — no code gets written.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent
argument-hint: [feature-name]
---

Turn a loose feature description into a spec that anyone — human or AI — can build from without follow-up questions. This is a planning session. No code gets written.

**Before anything else:**
- Read the project's CLAUDE.md for engineering principles and conventions. If none exists, suggest running `/eng-init` first.
- Explore the codebase enough to ground your spec in real paths, patterns, and conventions — not guesses.

**What you need from the user (ask only what's missing):**
- What problem does this solve? (one sentence)
- Who is this for? What are they doing when they hit this?
- What triggered this? (customer feedback, bug, internal idea — the background)
- How will you know this is done? (acceptance criteria — suggest defaults from CLAUDE.md principles if the user isn't sure)

Scale the spec to the task. Small feature → skip sections that don't apply. New initiative → full context. The structure flexes — the thinking doesn't.

**Apply the project's engineering principles throughout:**
- Is this the simplest approach that solves the problem? (Principle #1)
- Are we building for a real requirement or an imaginary one? (Principle #2 — YAGNI)
- Are we designing abstractions upfront, or discovering them? (Principle #3)
- Are any decisions here irreversible? Those deserve extra scrutiny. Reversible ones — move fast. (Principle #5)
- Does what we're adding compound over time, or is it a one-time need? (Principle #6)

**The spec format:**

```
## Feature: [name]

### Context
Why this exists. The background — enough that someone reading this 3 months from now understands the motivation without asking anyone.

### What
One-line description of what this feature does.

### Who
Who this is for and what they're doing when they encounter this.

### User flow
The steps a user takes. Happy path and sad path (errors, empty states, slow connections).

### Acceptance criteria
- [ ] [concrete, verifiable criteria]

### Edge cases & risks
The prioritized list — what actually matters. For each:
- What could go wrong
- How to handle it
- What's explicitly not worth handling yet, and why

### Proposed approach
- Existing code: relevant files and patterns already in use (reference real paths)
- File structure: exact files to create or modify, following project conventions
- Key decisions: trade-offs with reasoning
- Dependencies: what could block this (external APIs, other teams, migrations)

### Out of scope
What this feature explicitly does NOT include.
```

**After writing the spec — stress-test with fresh eyes (Principle #7).**
Spawn a sub-agent to run `/eng-stress-test` on the spec. Use the Agent tool with the prompt:

"Read and stress-test this spec: [spec content]. Follow the /eng-stress-test skill instructions. The project root is [path]."

The sub-agent reads the spec cold with no knowledge of how it was written. It loads CLAUDE.md and explores the codebase independently. Wait for its findings.

**Then present to the user:**
1. The spec
2. The stress-test findings
3. Your recommendation on which findings to address

Wait for approval or adjustments. Do not write code.

Once approved, save to `specs/[feature-name].md` (kebab-case, create the directory if needed). This file is the contract between planning and execution.
