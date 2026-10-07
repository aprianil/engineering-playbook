# Choosing a Tech Stack

> A deep dive from the [[Engineering Learnings & Playbook]]. Applying the "Choose Boring Technology" principles to pick a concrete stack. This note is perishable: tools change, principles don't. Last reviewed: 2026-10-08.

---

## The Principles (timeless)

These live in the playbook's "Choosing Your Stack" checklist:

- Am I spending innovation tokens on product or infrastructure?
- Is AI fluent in this technology? (adoption = training data = better AI help)
- Do I know this tool's failure modes, or am I about to discover them?
- Can I solve this with what I already have before adding something new?
- Ship first, switch later. Portability concerns before users are a procrastination vector.

---

## Reference Stack for Web Apps (2026)

Applying the principles above. Boring, AI-fluent, zero-ops:

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Next.js 16.4 (App Router) | Most adopted React framework. Server Components handle data fetching natively. Cache Components (`"use cache"`) is on by default in new apps. Massive AI training data |
| Language | TypeScript | One language front-to-back. Type safety catches bugs before runtime |
| Database + Auth | Supabase | Postgres underneath (portable). Auth, storage, realtime included. One platform, not five. Use the new publishable and secret API keys; the legacy anon and service_role keys are being retired |
| Styling | Tailwind + shadcn/ui | AI generates Tailwind fluently. shadcn is copy-paste components you own, no dependency lock-in. It can sit on Base UI (the default now) or Radix underneath |
| Hosting | Vercel | Zero ops. Preview deploys on every PR. Push to git, it's live |

Five pieces. Nothing redundant. Every innovation token saved for product.

---

## Decisions and Reasoning

### Why not a separate backend?
Next.js App Router gives you Server Components and Server Actions: data fetching and mutations built in. Adding a separate API server is an innovation token spent on plumbing. Start fullstack-in-one, split only when you have evidence you need to.

### When TanStack Query, and when not?
Default to server fetching. Next.js App Router already handles data fetching (Server Components) and cache invalidation: `revalidateTag(tag, 'max')` takes a cacheLife profile as its second argument, `updateTag` in a Server Action gives read-your-own-writes (the user sees their change right away), and `revalidatePath` still covers whole routes. For most pages, TanStack Query would solve problems the framework already handles.

Reach for it only on client-heavy pages: lots of client-side fetching, polling, or optimistic updates (a live dashboard, an inbox, an editor). There it earns its place, because the framework's server cache doesn't help with data that changes while the user is sitting on the page.

### Why not a separate ORM (Drizzle, Prisma)?
Supabase's client SDK auto-generates TypeScript types from your database schema. Adding an ORM on top means two ways to talk to your database. Start with one, add an ORM only if the Supabase client genuinely can't do what you need.

### Why Vercel despite lock-in concerns?
Ship first, switch later. The cost of worrying about portability before you have users is higher than the cost of migrating when you actually need to. Vercel is the zero-ops choice for Next.js. If you outgrow it or want to leave, alternatives exist (Cloudflare Workers, Railway, Fly.io).

### Why not Remix / React Router?
Remix v2 merged into React Router v7, and React Router v8 shipped in June 2026. Remix 3 is a ground-up rewrite that just hit 3.0 (October 2026, after a beta in April and a release candidate in August), and it isn't React-based anymore: it has its own component model. Through the boring tech lens: brand new + a different model = unknown unknowns, and far less AI training data. Next.js is the more battle-tested choice today.

---

## What You Don't Add Until You Need It

- **Redis**: Postgres handles caching, queues, and pub/sub until it can't
- **Message queues**: start with simple async functions or Postgres-based queues
- **Microservices**: one repo, one deployment
- **A component library**: build with Tailwind + shadcn first, extract patterns later (discover abstractions, don't design them)

---

*This note is a snapshot. The principles in the playbook are timeless; the specific tools here will age. Revisit when something feels outdated.*
