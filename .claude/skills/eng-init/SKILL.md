---
name: eng-init
description: Scaffold a CLAUDE.md with engineering principles. Use when setting up a new project or initializing engineering conventions.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, WebFetch
---

Initialize a CLAUDE.md file in the current project with shared engineering principles.

First, check if a CLAUDE.md already exists in the current project root. If it does, ask before overwriting.

Then create a CLAUDE.md that includes:

1. **Project-specific section** — ask the user for:
   - What the project is (one line)
   - Tech stack
   - Any known gotchas

2. **Project structure section** — scan the current directory and document the folder structure. If the project is new or empty, suggest this feature-based structure based on the tech stack:

```
## Project structure
/app/api     — API routes (thin — validate input, delegate to lib/)
/lib         — business logic, organized by feature (e.g. lib/billing/)
/components  — shared UI components (no business logic)
/features    — feature-specific UI (components + hooks + types per feature)
```

For existing projects, document what's actually there but note any deviations from this pattern.

3. **How features are structured section** — always include:

```
## How features are structured
- API routes validate input and delegate — no business logic in route files
- Business logic lives in lib/{feature}/ — reusable from any entry point
- Schemas (Zod) defined once, shared between frontend and backend
- Auth handled via a shared wrapper — not copy-pasted per route
- Background work (webhooks, emails, analytics) runs after the response
- Errors use a custom AppError class with codes — handled once at the boundary
- Router/layout/config files compose pieces together — no business logic in wiring files
```

4. **Engineering principles section** — always include:

```
## Engineering principles

These guide how code is written and reviewed in this project:

1. Aim for simplicity. Cut as much as you can. Write code that reveals intentions and is easy to change.
2. YAGNI — don't build for imaginary future requirements.
3. Discover abstractions, don't design them. Wait for the pattern to repeat before extracting. Duplication is cheaper than the wrong abstraction.
4. Time is a design constraint. Shortcuts are okay if deliberate and documented.
5. Type 1 vs Type 2 decisions. Most decisions are reversible — move fast on those. Be careful with irreversible ones.

When writing or editing code:
- Organize by feature, not by file type. Start flat — don't create folders for one file. Let structure emerge as the feature grows.
- Dependencies flow one direction. Features don't import from other features. Shared code doesn't import from features.
- Each file should do one thing. Favor locality of behavior — if someone needs to open 5 files to understand one behavior, it's over-separated.
- Name things so the reader never has to open the body to understand what it does. Don't abbreviate, don't put the type in the name (e.g., `users` not `userList`), don't repeat context (e.g., `user.getName()` not `user.getUserName()`). Match name length to scope.
- Handle the sad path, not just the happy path.
- Keep files focused — favor readability over line count.
- Don't add complexity for hypothetical scenarios.
- If a component can be described with "and" (does X AND Y AND Z), suggest splitting it.
- Proactively flag when a file is growing beyond one responsibility — don't wait to be asked.
- Code you write is also context for AI tools. Clear naming, small files, and co-located features make AI assistance dramatically better.
```

5. **Do / Don't / Ask first sections** — always include:

```
## Do
- Validate all input at the API boundary with Zod schemas
- Keep route files thin — delegate to lib/
- Use the auth wrapper on every protected route
- Name features consistently across layers (api/billing/, lib/billing/, use-billing.ts)
- Run tests/build/lint to verify changes — don't just trust the code
- Comments explain *why*, not *what* — if the code needs a comment to explain what it does, the code isn't clear enough
- Use early returns to reduce nesting: `if (!user) return null;`
- Use descriptive errors with context: `Unable to create invoice: User ${userId} has no payment method`

## Don't
- Put business logic in API routes or layout files
- Copy-paste auth checks into individual routes
- Return raw database types to the frontend — transform first
- Skip input validation — even for internal APIs
- Let AI write code without a way to verify it works
- Use `as any` — find the real type instead
- Commit secrets, API keys, or .env files
- Add comments that restate the code (e.g. `// Get the user` above `getUser()`)

## Ask first
- Adding new dependencies (each one is a maintenance commitment)
- Changing the database schema (hard to reverse)
- Deleting files (might be someone's in-progress work)
- Changes that touch more than one feature boundary
```

6. **PR guidelines section** — always include:

```
## PR guidelines
- Keep PRs under 500 lines and 10 files — one responsibility per PR
- When a change is too big, split by layer (database → backend → frontend), by feature component (API → UI → integration), or by refactor vs feature (separate PRs)
- Fix type errors before test failures — types are often the root cause
```

7. **When stuck section** — always include:

```
## When stuck
- Ask a clarifying question before making large speculative changes
- Propose a short plan for complex tasks before coding
- Fix type errors first — they often cause cascading test failures
- If something seems wrong, investigate before deleting — it may be intentional
```

8. **Commands section** — detect package.json or similar and list available scripts.

9. **Documentation references section** — based on the tech stack from step 1, add a section with official doc URLs so the AI knows where to look things up.

   Use this lookup table for known stacks:

   | Stack | Docs URL |
   |-------|----------|
   | React | https://react.dev/reference |
   | Next.js | https://nextjs.org/docs |
   | Supabase | https://supabase.com/docs |
   | Tailwind CSS | https://tailwindcss.com/docs |
   | shadcn/ui | https://ui.shadcn.com/docs |
   | TypeScript | https://www.typescriptlang.org/docs |
   | Prisma | https://www.prisma.io/docs |
   | Drizzle | https://orm.drizzle.team/docs/overview |
   | Zod | https://zod.dev |
   | tRPC | https://trpc.io/docs |
   | Stripe | https://docs.stripe.com |
   | Vercel | https://vercel.com/docs |
   | Vite | https://vite.dev/guide |
   | Express | https://expressjs.com/en/5x/api.html |
   | Hono | https://hono.dev/docs |
   | Postgres | https://www.postgresql.org/docs/current |
   | Redis | https://redis.io/docs |

   Only include entries that match the project's stack. If a technology isn't in the table, ask the user for the docs URL. Output a section like:

   ```
   ## Documentation references

   When unsure about framework APIs, patterns, or best practices, look these up before guessing:

   - React: https://react.dev/reference
   - Next.js: https://nextjs.org/docs
   - Supabase: https://supabase.com/docs
   ```

10. **What to watch out for section** — include any gotchas from step 1.

11. **Contributing section** — add a short note:

```
## For contributors
- Read this file before making changes
- Follow the principles above — they apply to all code in this project
```
