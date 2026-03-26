# Engineering Playbook

For designers, PMs, and product builders who ship code and want to build engineering judgment.

## Who this is for

You build products. You ship features. You work with engineers daily — maybe you even write code yourself. But most engineering resources assume a traditional engineering background.

This playbook is written from the other side: a designer who codes, learning to think like a staff engineer. A collection of principles, checklists, and field guides for developing the engineering eye — built from real projects, real mistakes, and real conversations with engineers and AI tools. Not a textbook — a practical reference for someone who builds products and wants to make better engineering decisions.

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

**Skills (Claude Code slash commands):**

Install the skills into your project with one command:

```bash
npx degit aprianil/engineering-playbook/.claude/skills .claude/skills
```

Or copy the `.claude/skills/` folder manually. Once in your project, the skills are available immediately.

- **[eng-init](.claude/skills/eng-init/SKILL.md)** — `/eng-init` — scaffold a CLAUDE.md with playbook principles baked in. Run once per project.
- **[eng-spec](.claude/skills/eng-spec/SKILL.md)** — `/eng-spec` — planning session. Captures context, user flow, acceptance criteria, and saves a spec file. No code.
- **[eng-build](.claude/skills/eng-build/SKILL.md)** — `/eng-build` — execution session. Reads a spec file and builds from it.
- **[eng-check](.claude/skills/eng-check/SKILL.md)** — `/eng-check` — review code against engineering principles. Auto-triggers when you ask Claude to review code.
- **[deslop](.claude/skills/deslop/SKILL.md)** — `/deslop` — remove AI-generated slop: unnecessary comments, defensive checks, `any` casts, style inconsistencies. Run after AI writes code, before `/eng-check`.
- **[sync-playbook](.claude/skills/sync-playbook/SKILL.md)** — `/sync-playbook` — sync playbook, deep dives, and skills from Obsidian to GitHub.

## How it's built

Written in Markdown, managed in Obsidian, synced to GitHub. Notes link to each other using `[[bidirectional links]]`. The playbook is the root — everything branches out from it.

Built with the help of Claude Code.
