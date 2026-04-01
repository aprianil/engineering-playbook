---
name: eng-spec
description: Write a feature spec before building anything. Planning session — no code gets written.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, EnterPlanMode, ExitPlanMode
argument-hint: [feature-name]
---

Turn a loose feature description into a spec that anyone — human or AI — can build from without follow-up questions. This is a planning session. No code gets written. This is where most of the value lives — if the spec is clear, execution is easy.

**Before anything else:**
- Read the project's CLAUDE.md for engineering principles and conventions. If none exists, suggest running `/eng-init` first.
- Explore the codebase enough to ground your work in real paths, patterns, and conventions.

**Assess whether the idea is ready to spec.**

Clear requirements indicators — skip to spec writing:
- User provides specific acceptance criteria or behavior
- References existing patterns to follow
- Describes exact expected behavior with constrained scope

Vague or exploratory indicators — explore first:
- "I want something like...", "what if we...", "I'm thinking about..."
- Multiple possible directions, unclear scope
- User seems unsure about what they actually want

## Exploration mode

When the idea is still forming, be a thinking partner — not an interviewer. Challenge assumptions, propose alternatives, surface risks. Use `AskUserQuestion` to keep the conversation focused — one question at a time, with concrete options when possible.

Probe through these lenses (skip what's already clear):
- What's the real problem? Is this the right framing, or a proxy for something more important?
- Who cares about this? What are they doing when they hit it?
- What triggered this? (customer feedback, bug, internal idea)
- What happens if we do nothing?
- Is there a simpler version that delivers most of the value?
- What would success look like?

When the exploration involves trade-offs, architectural choices, or multiple valid approaches — use `EnterPlanMode` to think it through properly. Write out the options, pros/cons, and your recommendation. Exit plan mode when you have a clear direction.

When evaluating multiple approaches that need research (e.g., comparing APIs, libraries, or architectural patterns), spawn parallel sub-agents to explore each option independently. Each sub-agent gets one option to research — read docs, check feasibility, identify trade-offs. The parent compares findings and recommends. This is faster and each sub-agent goes deeper than sequential exploration.

**Exit exploration when:** the problem is clear, the scope is bounded, and you could write acceptance criteria. Then transition to spec writing.

## Spec writing

**Before writing, check scope.** If the feature touches multiple independent subsystems, suggest separate specs. Each spec should produce independently working, testable software. A bloated spec that tries to do everything leads to a bloated build.

**Then map the file structure first.** Lock which files get created, modified, or tested before writing the rest of the spec. This forces decomposition decisions early — when they're cheap to change — and gives the builder a clear map.

**What you need (ask only what's still missing after exploration):**
- What problem does this solve? (one sentence)
- Who is this for?
- What triggered this?
- How will you know this is done? (acceptance criteria — suggest defaults from CLAUDE.md principles if the user isn't sure)

Scale the spec to the task. Small feature → skip sections that don't apply. New initiative → full context.

**Apply the project's engineering principles throughout:**
- Is this the simplest approach? Readable, changeable, few things to think about? (Principle #1)
- Are we building for a real requirement or an imaginary one? (Principle #2 — YAGNI)
- Are we designing abstractions upfront, or discovering them? (Principle #3)
- If we're taking shortcuts, do they have a concrete plan to revisit? (Principle #4)
- Are any decisions here irreversible (database schema, public APIs)? Those deserve extra scrutiny. Reversible ones — just decide. (Principle #5)
- Does what we're adding compound over time, or is it a one-time need? (Principle #6)
- How will we verify this works? What tests, checks, or browser validation should the spec require? (Principle #8)
- Will the user understand why the code is structured this way after building? Flag anything that needs explanation in the spec. (Principle #9)

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
- Key decisions: what was chosen, what was rejected, and why
- Dependencies: what could block this (external APIs, other teams, migrations)

### Out of scope
What this feature explicitly does NOT include.
```

## Stress-test (Principle #7)

After writing the spec, spawn a sub-agent to stress-test it with fresh eyes. Pass the context directly -- don't make it re-discover what you already know. Use the Agent tool with a prompt that includes:

1. The full spec content (inline, not a file path to read)
2. The CLAUDE.md engineering principles (inline the relevant sections)
3. Key file paths and code snippets the spec references
4. The project root path

Example prompt structure:

"You are stress-testing this spec with fresh eyes. You did not write it. Your job is to catch issues now while they're cheap to fix.

Here is the spec:
[paste full spec content]

Here are the project's engineering principles:
[paste relevant CLAUDE.md sections]

Here are the key files and patterns referenced:
[paste file paths + relevant code snippets you already found during research]

The project root is [path]. You may explore the codebase further if needed, but the context above should cover most of what you need.

Challenge the spec through these lenses (skip what's clearly fine):
- Simplicity: is there a simpler approach? Could concepts, dependencies, or indirection be cut?
- YAGNI: is anything built for an imaginary future requirement?
- Abstractions: are abstractions designed upfront that should be discovered later?
- Trade-offs: are shortcuts documented with a concrete plan to revisit?
- Reversibility: are any decisions hard to reverse (DB schema, public APIs, migrations)? Flag these. Are reversible decisions being over-planned?
- Compounding: does this invest in things that compound, or front-load one-time concerns?
- Verification: does the spec define how to verify the feature works?
- Ownership: is anything so complex the builder won't understand why it's structured that way?
- Edge cases: what would hurt users or corrupt data if missed? Concurrency issues? Security gaps?

Do NOT generate generic checklists. Only raise concerns specific to this feature. Do NOT suggest complexity for hypothetical scenarios.

Prioritize ruthlessly -- handle what would hurt users, force a rewrite, or create security/data issues. Dismiss what's not worth the complexity.

YOUR OUTPUT (return this as your response):
1. One-line verdict: 'ready to build' / 'address these first' / 'rethink approach'
2. Prioritized list (3-7 items). Each item: the concern (one line), why it matters, suggested fix or question to resolve.
3. End with what the spec got right (one or two lines).
If you found nothing meaningful: 'spec is solid, no concerns' is valid."

The sub-agent reads the spec cold -- no knowledge of how it was written. But it doesn't waste time re-reading files the parent already has. Wait for its findings.

**Then present to the user:**
1. The spec
2. The stress-test findings
3. Your recommendation on which findings to address

Wait for approval or adjustments. Do not write code.

Once approved, save to `specs/[feature-name].md` (kebab-case, create the directory if needed). This file is the contract between planning and execution.
