# Choosing a Tech Stack

> A deep dive from the [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md). Applying the "Choose Boring Technology" principles to pick a concrete stack. This note is perishable — tools change, principles don't. Last reviewed: 2026-03-25.

---

## The Principles (timeless)

These live in the playbook's "Choosing Your Stack" checklist:

- Am I spending innovation tokens on product or infrastructure?
- Is AI fluent in this technology? (adoption = training data = better AI help)
- Do I know this tool's failure modes — or am I about to discover them?
- Can I solve this with what I already have before adding something new?
- Ship first, switch later — portability concerns before users are a procrastination vector.

---

## Reference Stack for Web Apps (2026)

Applying the principles above — boring, AI-fluent, zero-ops:

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Next.js (App Router) | Most adopted React framework. Server Components handle data fetching natively. Massive AI training data |
| Language | TypeScript | One language front-to-back. Type safety catches bugs before runtime |
| Database + Auth | Supabase | Postgres underneath (portable). Auth, storage, realtime included. One platform, not five |
| Styling | Tailwind + shadcn/ui | AI generates Tailwind fluently. shadcn is copy-paste components you own — no dependency lock-in |
| Hosting | Vercel | Zero ops. Preview deploys on every PR. Push to git, it's live |

Five pieces. Nothing redundant. Every innovation token saved for product.

---

## Decisions and Reasoning

### Why not a separate backend?
Next.js App Router gives you Server Components and Server Actions — data fetching and mutations built in. Adding a separate API server is an innovation token spent on plumbing. Start fullstack-in-one, split only when you have evidence you need to.

### Why not TanStack Query?
Next.js App Router already handles data fetching (Server Components) and cache revalidation (`revalidatePath`/`revalidateTag`). TanStack Query solves problems the framework already handles. Adding it would be a solution looking for a problem.

### Why not a separate ORM (Drizzle, Prisma)?
Supabase's client SDK auto-generates TypeScript types from your database schema. Adding an ORM on top means two ways to talk to your database. Start with one, add an ORM only if the Supabase client genuinely can't do what you need.

### Why Vercel despite lock-in concerns?
Ship first, switch later. The cost of worrying about portability before you have users is higher than the cost of migrating when you actually need to. Vercel is the zero-ops choice for Next.js. If you outgrow it or want to leave, alternatives exist (Cloudflare Pages, Railway, Fly.io).

### Why not Remix / React Router v7?
Remix v2 merged into React Router v7. Remix 3 is a ground-up rewrite still in alpha. Through the boring tech lens: alpha = unknown unknowns. Next.js is the more battle-tested choice today.

---

## What You Don't Add Until You Need It

- **Redis** — Postgres handles caching, queues, and pub/sub until it can't
- **Message queues** — start with simple async functions or Postgres-based queues
- **Microservices** — one repo, one deployment
- **A component library** — build with Tailwind + shadcn first, extract patterns later (discover abstractions, don't design them)

---

*This note is a snapshot. The principles in the playbook are timeless; the specific tools here will age. Revisit when something feels outdated.*
