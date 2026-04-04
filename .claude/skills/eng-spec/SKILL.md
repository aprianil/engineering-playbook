---
name: eng-spec
description: Write a feature spec before building anything. Planning session — no code gets written.
disable-model-invocation: false
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

**Exit exploration when:** the problem is clear, the scope is bounded, and you could write acceptance criteria. Then transition to research.

## Research (ground the spec in evidence)

Before writing the spec, gather concrete evidence from the codebase. This prevents the spec from being written on vibes -- the proposed approach should reference real files, real patterns, and real constraints.

**Skip this step when the feature is small and the codebase is familiar enough that you already know the relevant files and patterns.** Don't launch agents to confirm what's obvious.

Launch two parallel sub-agents, each focused on one concern:

| Agent | What it researches | What it returns |
| --- | --- | --- |
| **Codebase fit** | What existing patterns should this feature follow? What files will be touched or created? Is there code that already solves part of this? Also search `docs/solutions/` for prior art -- past problems and solutions related to this feature's domain. | File paths with line numbers, relevant code snippets, the pattern to follow, and any relevant prior solutions |
| **Edge cases & constraints** | What inputs or states could break this? What happens when external dependencies fail? Are any decisions irreversible (DB schema, public APIs)? | Prioritized list of risks with severity (blocks build vs. handle later) |

Each agent gets:
- The feature description and direction from exploration (inline)
- The project's CLAUDE.md conventions (inline)
- The project root path

The agents explore the codebase independently. Wait for both to return before writing the spec.

**Use the findings to ground the spec** -- the "Proposed approach" section should reference the codebase agent's file paths and patterns. The "Edge cases & risks" section should incorporate the constraints agent's findings. Don't just append findings -- weave them into the spec so the builder gets one coherent document.

## Spec writing

**Before writing, check scope.** If the feature touches multiple independent subsystems, suggest separate specs. Each spec should produce independently working, testable software. A bloated spec that tries to do everything leads to a bloated build.

**Then map the file structure first.** Lock which files get created, modified, or tested before writing the rest of the spec. This forces decomposition decisions early — when they're cheap to change — and gives the builder a clear map. The codebase fit research should inform this directly -- follow the patterns it found.

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
- Can this be decomposed into independent pieces that can be built in parallel? (Principle #11)

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
- Quality: are assumptions treated as verified facts? Are constraints described but not enforced? Is anything deferred that would be cheaper to get right now than to fix later?
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

## Decompose for parallelism (Principle #11)

After approval, check whether the work can be split into independent pieces that can be built in parallel. Not every spec needs splitting — small features ship as one spec.

**When to split:** the spec has a dependency graph where some work can happen concurrently. Look for files with no dependencies on each other, or groups of work that only connect at defined interfaces.

**How to split:**
- Map the dependency graph. The shape varies — it might be "foundation → parallel tracks → integration" or "three parallel tracks from the start" or "two tracks that merge halfway." Let the work dictate the shape
- Write all build specs sequentially in the main conversation. Each spec benefits from decisions made in the previous ones. Do not farm out spec writing to parallel agents — they lose the accumulated context and the specs drift from each other
- Each build spec is self-contained: buildable with only that spec + CLAUDE.md
- Each build spec states what's being built alongside it — not for coordination, but so the builder understands the boundaries. What they own, what's off-limits, and what they can expect to exist when the tracks merge
- No file overlap between specs
- Each build spec gets its own stress-test (parallel sub-agents are fine here — stress-testing benefits from fresh eyes)
- The parent spec stays as the decision document. Add a build status section listing all split specs with their dependencies and status

Save build specs as `specs/[parent-name]-[letter]-[short-name].md`.
