# Engineering Playbook

A living playbook for building engineering taste and judgment — from a designer and product builder who ships code, toward thinking like a staff engineer.

## What this is

A collection of principles, checklists, and field guides for developing the engineering eye. Not a textbook — a practical reference for someone who builds products and wants to make better engineering decisions.

This is a living document — I'm still early in this journey. It grows as I learn.

## What's inside

**Start here:**
- **[Engineering Learnings & Playbook.md](<Engineering Learnings & Playbook.md>)** — the hub. Principles, checklists, learning path, and a running log of lessons learned.

**Deep dives:**
- **[How to Read and Navigate an Unfamiliar Codebase.md](<How to Read and Navigate an Unfamiliar Codebase.md>)** — finding your way through code you didn't write
- **[How to Learn From Your Engineer's Code.md](<How to Learn From Your Engineer's Code.md>)** — using PRs and code review as a learning tool
- **[Debugging Mindset.md](<Debugging Mindset.md>)** — a systematic approach to fixing bugs
- **[Git Workflow Fundamentals.md](<Git Workflow Fundamentals.md>)** — commits, branches, PRs, and shipping mechanics
- **[Testing - When and What to Test.md](<Testing - When and What to Test.md>)** — what's worth testing and how to think about it
- **[Communicating Technically With Engineers.md](<Communicating Technically With Engineers.md>)** — asking the right questions, translating between product and engineering
- **[Logging in Production.md](<Logging in Production.md>)** — production logging, structured logs, request IDs, and logging AI calls
- **[Race Conditions.md](<Race Conditions.md>)** — timing bugs that show up when things happen at the same time
- **[Working Effectively With AI.md](<Working Effectively With AI.md>)** — prompting patterns, context engineering, and verification for AI coding tools
- **[Code Review - What to Look For and How to Do It.md](<Code Review - What to Look For and How to Do It.md>)** — Google's code review guide distilled — what to look for, how to comment, speed, handling pushback
- **[Choosing a Tech Stack.md](<Choosing a Tech Stack.md>)** — reference stack for web apps (2026) — boring, AI-fluent, zero-ops
- **[Anatomy of a Well-Structured Feature.md](<Anatomy of a Well-Structured Feature.md>)** — seven timeless patterns for how a feature should be structured across layers
- **[Building Engineering Taste.md](<Building Engineering Taste.md>)** — reading path for developing the eye — from code quality vocabulary to systems thinking
- **[Open Source Maintainership.md](<Open Source Maintainership.md>)** — building trust, community design, release mechanics, saying no — for a product person's first open source project
- **[Designing Frontends for Performance.md](<Designing Frontends for Performance.md>)** — three decisions that determine ~90% of frontend performance — rendering location, data arrival, bundle size

**Skills (Claude Code slash commands):**

Install the skills into your project with one command:

```bash
npx degit aprianil/engineering-playbook/.claude/skills .claude/skills
```

Or copy the `.claude/skills/` folder manually. Once in your project, the skills are available immediately.

| Phase | Skill | What it does |
|---|---|---|
| Setup | [`/eng-init`](.claude/skills/eng-init/SKILL.md) | Scaffold a CLAUDE.md with playbook principles baked in. Run once per project. |
| Plan | [`/eng-spec`](.claude/skills/eng-spec/SKILL.md) | Explore a vague idea or write a spec for a clear one. Researches the codebase with parallel agents, then stress-tests the spec before presenting. No code. |
| Plan | [`/eng-stress-test`](.claude/skills/eng-stress-test/SKILL.md) | Stress-test any spec or plan with fresh eyes. Auto-triggered by `/eng-spec`, or run standalone. |
| Build | [`/eng-build`](.claude/skills/eng-build/SKILL.md) | Build a feature from an approved spec. Auto-triggers `/eng-debug` when something breaks unexpectedly. |
| Build | [`/eng-debug`](.claude/skills/eng-debug/SKILL.md) | Systematic debugging: reproduce, localize, root cause, fix, guard test. Auto-triggered from `/eng-build` or run standalone. Hands off non-obvious findings to `/eng-compound`. |
| Build | [`/web-animation-design`](.claude/skills/web-animation-design/SKILL.md) | Design and implement web animations that feel natural — easing, timing, springs, transitions, accessibility. Triggers on motion-related work. |
| Review | [`/deslop`](.claude/skills/deslop/SKILL.md) | Remove AI-generated slop: unnecessary comments, defensive checks, `any` casts. Run before `/eng-check`. |
| Review | [`/eng-check`](.claude/skills/eng-check/SKILL.md) | Check code against engineering principles. Last gate before shipping. |
| Learn | [`/eng-compound`](.claude/skills/eng-compound/SKILL.md) | Capture non-obvious solutions so the team never solves the same problem twice. Feeds back into `/eng-spec`'s research phase. |

**See it in action:** [How the Skills Work Together](<How the Skills Work Together.md>) — a full walkthrough from vague idea to shipped code, showing how each skill and principle connects.

## How it's built

These are my actual Obsidian notes, synced to GitHub. If you use Obsidian, you can clone this repo into your vault and everything just works — `[bidirectional links](bidirectional%20links.md)`, flat file structure, no subfolders. The playbook is the root note that links out to everything else.

Built with the help of Claude Code.
