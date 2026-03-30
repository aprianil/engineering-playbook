---
name: eng-init
description: Scaffold a CLAUDE.md with engineering principles. Use when setting up a new project or initializing engineering conventions.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, WebFetch
---

Initialize a CLAUDE.md file in the current project with shared engineering principles.

First, check if a CLAUDE.md already exists in the current project root. If it does, ask before overwriting.

Then create a CLAUDE.md. Ask the user for:
- What the project is (one line)
- Tech stack
- Any known gotchas

Scan the current directory to understand the existing structure, commands (package.json scripts, Makefile, etc.), and patterns.

The CLAUDE.md should be concise — every line earns its place. Principles and behavioral rules go first (they guide every action). Structure and reference material go after (they're looked up when needed).

Use this template, adapting to what you found in the project:

```markdown
# [Project Name]

[One-line description of what this is and who it's for.]

## Tech stack
- [Framework, language, database, styling, deployment — whatever applies]

## Engineering principles

Most of the work happens before and after writing code — not during. Plan thoroughly, review to catch issues, codify knowledge so it's reusable, keep quality high so future changes are easy. If execution feels hard, the planning was incomplete.

1. Aim for simplicity. Simple = readable, changeable, few things to think about. A self-contained 200-line file is simpler than a 50-line file that imports from 8 others.
2. YAGNI — don't build for requirements that don't exist yet.
3. Discover abstractions, don't design them. Wait until the pattern repeats before extracting. Duplication is cheaper than the wrong abstraction.
4. Time is a design constraint. Shortcuts are fine if deliberate and documented. "I'll fix it later" without a ticket is a wish, not a decision.
5. Type 1 vs Type 2 decisions. Type 1 = hard to reverse (database schema, public APIs) — proceed carefully. Type 2 = reversible (UI, naming, library choice) — just decide. Most decisions are Type 2.
6. Invest in what compounds. If it makes the next 10 sessions better, add it now. If it's a one-time need, add it when needed.
7. The builder shouldn't be the reviewer. Fresh eyes catch what the author can't. Have someone (or a separate agent) challenge your work before committing.
8. Verify, don't trust. Every change needs a way to prove it works — tests, build, lint, browser. Applies to your own code and AI-generated code equally.
9. Own what you ship. If you can't explain why the code is structured this way, you don't understand it enough to maintain it.

## Do
- Validate all input at the API boundary with Zod schemas
- Keep route files thin — validate and delegate to lib/. No business logic in routes.
- Use the auth wrapper on every protected route
- Name features consistently across layers (api/billing/, lib/billing/, use-billing.ts)
- Run tests/build/lint to verify changes — don't just trust the code
- Write integration tests over unit tests. Test behavior, not implementation. "Write tests. Not too many. Mostly integration."
- Log intentionally in production: structured logs with labels (`[POST /api/billing]`), context (userId, action), and outcome. Never log secrets.
- Use early returns to reduce nesting: `if (!user) return null;`
- Use descriptive errors with context: `Unable to create invoice: User ${userId} has no payment method`
- Disable submit buttons after click to prevent double submissions
- Comments explain *why*, not *what* — if the code needs a comment to explain what it does, the code isn't clear enough

## Don't
- Put business logic in API routes or layout files
- Copy-paste auth checks into individual routes
- Return raw database types to the frontend — transform first
- Skip input validation — even for internal APIs
- Let AI write code without a way to verify it works
- Use `as any` — find the real type instead
- Commit secrets, API keys, or .env files
- Add comments that restate the code (e.g. `// Get the user` above `getUser()`)
- Refactor and add features in the same PR — if something breaks, you won't know which change caused it
- Remove code without checking `git blame` first — it may be there for a reason

## Ask first
- Adding new dependencies (each one is a maintenance commitment)
- Changing the database schema (hard to reverse)
- Deleting files (might be someone's in-progress work)
- Changes that touch more than one feature boundary
- Refactoring working code that isn't actively slowing you down

## When writing or editing code
- Organize by feature, not by file type. Start flat — one file is fine. Split when a file does too many things, not before.
- Dependencies flow one direction. Features don't import from other features. Shared code doesn't import from features.
- Each file should do one thing. Favor locality of behavior — if someone needs to open 5 files to understand one behavior, it's over-separated.
- Name things so the reader never has to open the body to understand what it does. Don't abbreviate, don't put the type in the name (`users` not `userList`), don't repeat context (`user.getName()` not `user.getUserName()`). Match name length to scope.
- Handle the sad path, not just the happy path.
- If a component can be described with "and" (does X AND Y AND Z), suggest splitting it.
- Proactively flag when a file is growing beyond one responsibility.
- Side effects (webhooks, emails, analytics) run after the response — the user doesn't wait for work they didn't ask for.
- Code you write is also context for AI tools. Clear naming, small files, and co-located features make AI assistance dramatically better.

## How features are structured
- API routes validate input and delegate — no business logic in route files
- Business logic lives in lib/{feature}/ — reusable from any entry point
- Schemas (Zod) defined once, shared between frontend and backend
- Auth handled via a shared wrapper — not copy-pasted per route
- Background work (webhooks, emails, analytics) runs after the response
- Errors use a custom AppError class with codes — handled once at the boundary
- Router/layout/config files compose pieces together — no business logic in wiring files

## Project structure
[Document what's actually in the project. For new/empty projects, suggest:]

/app/api     — API routes (thin — validate input, delegate to lib/)
/lib         — business logic, organized by feature (e.g. lib/billing/)
/components  — shared UI components (no business logic)
/features    — feature-specific UI (components + hooks + types per feature)

## Context loading guide
When working on a feature, load these files — nothing else:
- Backend: app/api/{feature}/ + lib/{feature}/
- Frontend: features/{feature}/
- Shared: lib/{feature}/schema.ts (the contract between frontend and backend)
- Auth: lib/auth/ (only if changing auth behavior)
Don't load unrelated features. The structure is designed so each feature is self-contained.

## PR guidelines
- Keep PRs under 500 lines and 10 files — one responsibility per PR
- When a change is too big, split by layer (database → backend → frontend), by feature component (API → UI → integration), or by refactor vs feature (separate PRs)
- Fix type errors before test failures — types are often the root cause

## When stuck
- Ask a clarifying question before making large speculative changes
- Propose a short plan for complex tasks before coding
- Fix type errors first — they often cause cascading test failures
- If something seems wrong, investigate before deleting — it may be intentional

## Commands
[Detect from package.json, Makefile, etc. and list available scripts]

## Documentation references

When unsure about framework APIs, patterns, or best practices, look these up before guessing:

[Include only what matches the project's stack, using this lookup:]

- React: https://react.dev/reference
- Next.js: https://nextjs.org/docs
- Supabase: https://supabase.com/docs
- Tailwind CSS: https://tailwindcss.com/docs
- shadcn/ui: https://ui.shadcn.com/docs
- TypeScript: https://www.typescriptlang.org/docs
- Prisma: https://www.prisma.io/docs
- Drizzle: https://orm.drizzle.team/docs/overview
- Zod: https://zod.dev
- tRPC: https://trpc.io/docs
- Stripe: https://docs.stripe.com
- Vercel: https://vercel.com/docs
- Vite: https://vite.dev/guide
- Express: https://expressjs.com/en/5x/api.html
- Hono: https://hono.dev/docs
- Postgres: https://www.postgresql.org/docs/current
- Redis: https://redis.io/docs

[If a technology isn't in this table, ask the user for the docs URL.]

## What to watch out for
[Include any gotchas from the user]

## For contributors
- Read this file before making changes
- Follow the principles above — they apply to all code in this project
```

After generating, suggest the user set up hooks for mechanical enforcement:
- A lint hook that runs on file edits catches style issues automatically
- A test hook that runs on commits catches regressions automatically
- These enforce what CLAUDE.md guides — belt and suspenders
