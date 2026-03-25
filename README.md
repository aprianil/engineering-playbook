# Engineering Playbook

A living playbook for building engineering taste and judgment — from a designer and product builder who ships code, toward thinking like a staff engineer.

## What this is

A collection of principles, checklists, and field guides for developing the engineering eye. Not a textbook — a practical reference for someone who builds products and wants to make better engineering decisions.

## Files

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

**Skills (Claude Code slash commands):**
- **[skills/eng-init.md](skills/eng-init.md)** — `/eng-init` — scaffold a CLAUDE.md with playbook principles baked in. Run once per project.
- **[skills/eng-spec.md](skills/eng-spec.md)** — `/eng-spec` — planning session. Captures context, user flow, acceptance criteria, and saves a spec file. No code.
- **[skills/eng-build.md](skills/eng-build.md)** — `/eng-build` — execution session. Reads a spec file and builds from it.
- **[skills/eng-check.md](skills/eng-check.md)** — `/eng-check` — review code against engineering principles in the project's CLAUDE.md.

## How it's built

Written in Markdown, managed in Obsidian, synced to GitHub. Notes link to each other using `[[bidirectional links]]`. The playbook is the root — everything branches out from it.

Built with the help of Claude Code.
