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

2. **Engineering principles section** — always include these:

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

3. **Documentation references section** — based on the tech stack from step 1, add a section with official doc URLs so the AI knows where to look things up.

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

4. **Project structure section** — scan the current directory and document the folder structure. If the project is new or empty, suggest a feature-based structure based on the tech stack.

5. **Commands section** — detect package.json or similar and list available scripts.

6. **Contributing section** — add a short note:

```
## For contributors
- Read this file before making changes
- Follow the principles above — they apply to all code in this project
```
