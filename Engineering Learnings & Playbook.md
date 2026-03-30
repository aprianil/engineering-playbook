# Engineering Learnings & Playbook

> A living document for building engineering taste and judgment — from a designer and product builder who ships code, toward thinking like a staff engineer.

---

> [!info]- Context for AI (Claude Code)
> This section is for you, the AI editing this file. Read this before making any changes.
>
> **What this file is:** A living playbook that shapes how I (Apri) think about engineering before I direct you to write or edit code. The flow is: I think (using this playbook) → I set context (CLAUDE.md + project structure) → I direct you (prompt) → I judge what you produce (using the checklists here). You are the builder. I am the architect. This playbook is my blueprint.
>
> **How to edit this file:**
>
> - Timeless over trendy. This is the #1 rule. Principles should last. Resources, tools, and specific technology choices are perishable — they belong in deep dive notes, not the playbook. The playbook holds the thinking, not the tools.
> - Follow the playbook's own principles. Simplicity first. Don't bloat it.
> - Don't add sections preemptively. Add them when there's a real learning to capture.
> - No rigid rules. Guidelines that flex beat hard rules that fight you.
> - Walk me through your thinking before making edits. I want to approve the reasoning first.
> - Check for internal conflicts before adding anything new. Don't let new advice contradict existing principles.
> - Tone: practical, direct, written for a designer/product builder. Not academic, not CS-heavy.
> - Only use the principles and learnings documented here when writing or editing code in my projects. Don't guess or invent new philosophy — work with what's in this file.
> - **This playbook is the root, not the container.** When a topic needs a deep dive, suggest creating a new .md file in this vault (flat structure, no subfolders — all files live at the vault root) and link to it from here using `[Note Name](Note Name.md)`. Keep the playbook as a clean hub that links out — don't let it grow into a textbook.

---

## Where I'm Starting From
- Background in design and product
- I code, ship features, and work alongside engineers
- I understand the development lifecycle end-to-end through production
- What I'm building now: the judgment to know what good code looks like, how to separate concerns, how to think about system design, and how to keep things simple and maintainable

**The goal isn't to become a computer science expert. It's to develop the engineering eye — so I can shape better products, maintain code confidently, and avoid breaking things or creating unnecessary complexity.**

**Deep dives (linked notes):**

| Note | What it covers |
|------|---------------|
| [How to Read and Navigate an Unfamiliar Codebase](How to Read and Navigate an Unfamiliar Codebase.md) | Finding your way through a project you didn't build |
| [How to Learn From Your Engineer's Code](How to Learn From Your Engineer's Code.md) | Turning PRs and code review into a learning tool |
| [Debugging Mindset](Debugging Mindset.md) | A systematic approach to fixing bugs instead of guessing |
| [Git Workflow Fundamentals](Git Workflow Fundamentals.md) | Commits, branches, PRs, and the mechanics of shipping code |
| [Testing - When and What to Test](Testing - When and What to Test.md) | What's worth testing, what's not, and how to think about it |
| [Communicating Technically With Engineers](Communicating Technically With Engineers.md) | Asking the right questions, translating between product and engineering |
| [Logging in Production](Logging in Production.md) | Production logging is permanent code, not debugging leftovers |
| [Race Conditions](Race Conditions.md) | Timing bugs when things happen at the same time — common when vibe coding |
| [Working Effectively With AI](Working Effectively With AI.md) | How to communicate with AI coding tools — prompting, context engineering, and verification |
| [Code Review - What to Look For and How to Do It](Code Review - What to Look For and How to Do It.md) | Google's code review guide distilled — what to look for, how to comment, speed, handling pushback |
| [Choosing a Tech Stack](Choosing a Tech Stack.md) | Reference stack for web apps (2026) — boring, AI-fluent, zero-ops. Perishable — revisit when tools change |
| [Anatomy of a Well-Structured Feature](Anatomy of a Well-Structured Feature.md) | Seven timeless patterns for how a feature should be structured across layers — validated across five production codebases |
| [Building Engineering Taste](Building Engineering Taste.md) | Reading path for developing the eye — from code quality vocabulary to systems thinking |
| [Open Source Maintainership](Open Source Maintainership.md) | Building trust, community design, release mechanics, saying no — for a product person's first open source project |

---

## Part 0: Before You Write a Line of Code
The structure you set up before coding determines how clean or messy everything gets — for you, for your team, and for AI tools like Claude Code. This is the equivalent of an architect drawing the floor plan before laying bricks. Skip this, and you'll spend more time fighting your own codebase than building features.

Clean structure has a double purpose now: **humans can navigate it, and AI can reason about it.** When Claude Code reads your project, it loads files into a context window. Scattered code = noisy context = worse AI suggestions. Focused, well-separated code = clean context = AI that actually helps.

### The Core Idea: Organize by What It Does, Not What It Is
Most beginners organize code by file type — all components in one folder, all hooks in another, all utils in another. This feels tidy but falls apart fast because when you work on a feature, your files are scattered everywhere.

Senior engineers organize by feature. Everything related to one feature lives together. You open one folder, you see the full picture.

```
Avoid this (organized by type):
/components
  Button.tsx
  BillingCard.tsx
  UserProfile.tsx
/hooks
  useBilling.tsx
  useUser.tsx
/utils
  formatCurrency.ts
  formatDate.ts

Do this instead (organized by feature — this is what a mature project looks like, not what you start with. See "How Features Grow" below for the progression):
/app/api             ← API routes (thin — validate input, delegate to lib/)
  /billing
    route.ts         ← validates, calls lib/billing/, returns response
  /user
    route.ts
/lib                 ← business logic + integrations, organized by feature
  /billing
    create-invoice.ts  ← the actual logic (reusable from any entry point)
    billing.test.ts
  /user
    get-user.ts
  /integrations      ← third-party configs (Stripe, Supabase, etc.)
/features            ← feature-specific UI (components + hooks per feature)
  /billing
    /components
      BillingCard.tsx
      CreateInvoice.tsx
    useBilling.tsx
  /user
    /components
      UserProfile.tsx
    useUser.tsx
/components          ← shared, generic (Button, Form, Table — no business logic)
  /ui
    Button.tsx
    Form.tsx
    Table.tsx
  /layouts
    DashboardLayout.tsx
```

**Three layers, each with a clear job:**
- `app/api/billing/` — thin route. Validates input, delegates to `lib/billing/`, returns response. No business logic here.
- `lib/billing/` — business logic. The actual work. Reusable from any entry point (API route, background job, CLI script).
- `features/billing/` — feature-specific UI. Components, hooks, types. Composes shared components with feature-specific behavior.
- `components/` — shared, generic UI. Used across multiple features. Knows nothing about any business domain.

A component starts in its feature folder. It only "graduates" to shared when you discover it's genuinely needed by multiple features — not before (Principle #3).

**Dependencies flow one direction:** `components/` → `features/` → `app/` (routes/pages). Features never import from each other. `lib/` is available to any layer — it's pure logic with no UI dependencies. This keeps the blast radius small — changes to billing can't break user.

**Feature names mirror across layers:** if the feature is "billing," you'll find `app/api/billing/`, `lib/billing/`, `features/billing/`, and `useBilling.ts`. You always know where to look.

When you're working on billing, you touch three predictable locations. Context stays clean. No jumping across 6 folders to understand one feature.

This also means when AI helps you with billing, it reads the billing folders and gets the full picture — no noise from unrelated features polluting the context.

### Choosing Your Stack
Before you organize folders, you pick your tools. Apply the innovation token model:
```
Technology selection
- Am I spending innovation tokens on product or infrastructure?
- Is AI fluent in this technology? (adoption = training data = better AI help)
- Do I know this tool's failure modes — or am I about to discover them?
- Can I solve this with what I already have before adding something new?
- Ship first, switch later — portability concerns before users are a procrastination vector.
```

See [Choosing a Tech Stack](Choosing a Tech Stack.md) for a reference stack applying these principles.

### The Scaffolding Checklist
Before starting any new project, answer these:
```
Structure
- What are the 3-5 core features? Each one gets folders in lib/, features/, and app/api/.
- What's truly shared across features? That goes in /components.
- Where does business logic live? In lib/{feature}/ — not in API routes.
- Where does state live? As close to where it's used as possible.
- What's my naming convention? Pick one, write it down, stick to it.
- What framework conventions already exist? Use them before inventing your own.

File discipline
- Is each file focused on one thing? (Shorter is usually better, but a readable 300-line file beats a 50-line file that imports from 8 others)
- Would someone — or AI — understand this file without reading 3 other files first?

AI-readiness
- Do I have a rules file (CLAUDE.md or equivalent) at the project root?
- Are my conventions written down so I don't repeat myself every session?
- When I give AI a task, am I being specific enough that it doesn't have to guess the implementation?
- Does AI have a way to verify its own work (tests, build, lint, browser)?
- Am I breaking work into small, scoped tasks — or asking AI to do too much at once?
```

### The "Screaming Architecture" Test
Open your project folder. If a stranger looked at just the folder names, would they know what your app *does*? If they see `/features/billing`, `/features/onboarding`, `/features/dashboard` — they get it. If they see `/components`, `/utils`, `/hooks` — they know nothing about the product.

Your folder structure should scream the product, not the framework.

### How Features Grow
Start flat. A new feature might just be one file. That's fine. Don't create a folder for one file. As the feature grows:
```
Step 1 (start simple):
/features
  billing.tsx

Step 2 (it grows, now split):
/features
  /billing
    BillingPage.tsx
    useBilling.tsx

Step 3 (more complexity — split across layers):
/app/api/billing
  route.ts              ← thin: validates, delegates to lib/
/lib/billing
  create-invoice.ts     ← business logic (reusable)
  billing.schema.ts     ← shared Zod schema
  billing.test.ts
/features/billing
  BillingPage.tsx
  BillingCard.tsx
  useBilling.tsx         ← hook that calls the API
```

The rule: split when a file does too many things, not before. This is Principle #3 in action — discover the structure, don't over-design it upfront. Start with one file in `/features`. When it needs an API route and business logic, split across layers.

Once a feature has multiple files across layers (route, logic, hooks), there are seven patterns that keep it clean as it grows. See [Anatomy of a Well-Structured Feature](Anatomy of a Well-Structured Feature.md) for the full breakdown — thin routes, shared schemas, auth wrappers, and more.

### Setting Up CLAUDE.md — Your AI Onboarding Doc
A `CLAUDE.md` file at the project root is the first thing Claude Code reads when it enters your project. Think of it as a briefing doc — it tells AI who this project is, how it's built, and what rules to follow. Without it, you'll repeat the same context every conversation.

**One `CLAUDE.md` at the root is all you need.** Don't create multiple until a project genuinely grows into a complex monorepo. Keep it simple.

**What to put in your CLAUDE.md:**
```markdown
# Project Name

## What this is
One-line description of the product and who it's for.

## Tech stack
- Framework: [e.g. Next.js, app router]
- Styling: [e.g. Tailwind CSS]
- Database: [e.g. Supabase, Postgres]
- Language: [e.g. TypeScript]

## Project structure
/app/api     — API routes (thin — validate input, delegate to lib/)
/lib         — business logic, organized by feature (e.g. lib/billing/)
/components  — shared UI components (no business logic)
/features    — feature-specific UI (components + hooks + types per feature)

## How features are structured
- API routes validate input and delegate — no business logic in route files
- Business logic lives in lib/{feature}/ — reusable from any entry point
- Schemas (Zod) defined once, shared between frontend and backend
- Auth handled via a shared wrapper — not copy-pasted per route
- Background work (webhooks, emails, analytics) runs after the response
- Errors use a custom AppError class with codes — handled once at the boundary

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

## Conventions
- Naming: PascalCase for components, camelCase for functions/hooks
- Imports: use @/ alias for root-level imports
- Components: split when they do too much — favor readability over line count
- Errors: throw AppError with a code, never raw strings

## Commands
- npm run dev — start dev server
- npm run build — production build
- npm run test — run tests

## PR guidelines
- Keep PRs under 500 lines and 10 files — one responsibility per PR
- When a change is too big, split by layer (database → backend → frontend), by feature component (API → UI → integration), or by refactor vs feature (separate PRs)
- Fix type errors before test failures — types are often the root cause

## When stuck
- Ask a clarifying question before making large speculative changes
- Propose a short plan for complex tasks before coding
- Fix type errors first — they often cause cascading test failures
- If something seems wrong, investigate before deleting — it may be intentional

## What to watch out for
- [Any known gotchas, quirks, or things that break easily]
```

This takes 5 minutes to write and pays off in every AI session. Claude Code will follow these conventions automatically instead of guessing.

### Working With AI Coding Tools
Beyond rules files, there are principles that make AI consistently useful. These apply regardless of which tool you use.

**Goal + constraints, not step-by-step instructions** — give the model a clear outcome, the constraints it should respect, and access to the tools it needs. Let it figure out the path. Don't choreograph its execution — models are increasingly better at choosing their own approach than following yours.

**Context mindset** — every time you structure a file or name a function, you're writing for a future AI session that needs to understand this code fast. Clean naming, small files, and co-located features make AI assistance dramatically better. The same things that make code maintainable for humans make it navigable for AI.

**Give tools, not answers** — instead of pasting docs into prompts, give the model a URL it can fetch. Instead of describing the UI, give it a browser tool. Let the model pull context when it needs it rather than front-loading everything.

**Verify, don't trust** — the model should always have a way to prove its work: tests, build commands, browser checks, CI/CD. This is timeless regardless of how capable models get.

**Decompose for your thinking, not the model's** — breaking problems down is fundamental engineering. But you don't need to hand-feed each step to the model. Decompose to sharpen your understanding, then give the model the full picture.

**Let go of what models outgrow** — techniques that were necessary a year ago may be unnecessary scaffolding today. If something feels like hand-holding, test whether the model still needs it.

See [Working Effectively With AI](Working Effectively With AI.md) for the full deep dive on context engineering, tool-first thinking, and verification.

**Claude Code-specific practices:**

**Skills** — repeatable commands you can trigger with a slash. `/commit` writes a proper commit message. You can create custom skills for things you do often. Think of them as shortcuts that keep you in flow.

Custom skills built for this playbook (lives in `.claude/skills/` — the standard Claude Code location):
- `/eng-init` — scaffolds a CLAUDE.md in any project with the engineering principles from this playbook baked in. Run once per project. Team-friendly — any contributor benefits from it.
- `/eng-spec` — planning session. Captures context (who, why, what triggered this), defines user flow and acceptance criteria, and saves a spec file. No code gets written — just thinking.
- `/eng-build` — execution session. Reads a spec file and builds from it. Clean context, clear instructions. The spec is the contract.
- `/eng-check` — reviews code against the engineering principles in the project's CLAUDE.md. Auto-triggers when you ask Claude to review code.
- `/sync-playbook` — syncs the playbook and deep dive files from Obsidian to GitHub.

**Hooks** — automated actions that run before or after tool calls. For example, a hook that runs your linter every time Claude Code edits a file. This catches quality issues automatically without you having to remember.

**Essential resources:**
- [Bulletproof React](https://github.com/alan2207/bulletproof-react) — the single best reference for React project structure. Study the folder layout and read the docs explaining each decision.
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) — official docs on CLAUDE.md, skills, hooks, and best practices.

> [!tip]- Further reading
> - [Screaming Architecture](https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html) by Robert Martin — short blog post, 5 min read
> - [Next.js Project Structure docs](https://nextjs.org/docs/getting-started/project-structure)
> - [T3 Stack](https://create.t3.gg) — study the scaffolded project and its docs
> - [Feature-Sliced Design](https://feature-sliced.design) — read the overview only
> - [Shadcn/ui source code](https://github.com/shadcn-ui/ui)

---

## Part 1: The Mindset Shifts
Senior isn't about code. It's about how you think — and more specifically, how you approach problems.

Going from shipping code to engineering well is less about leveling up your code and more about leveling up your thinking.

### Most of the Work Happens Before and After Writing Code
The hard part of engineering isn't typing code — it's thinking clearly before and after.

- **Plan thoroughly before writing code.** An hour of planning saves days of rework. Explore the problem, challenge assumptions, stress-test the design. When you sit down to build, the path should be clear.
- **Review to catch issues and capture learnings.** Review is half the 80%, not an afterthought. Fresh eyes catch what the builder can't.
- **Codify knowledge so it's reusable.** Conventions, principles, and learnings that compound should be written down — in CLAUDE.md, in playbooks, in specs. Knowledge that stays in your head helps once. Knowledge that's codified helps every future session.
- **Keep quality high so future changes are easy.** The goal of quality isn't perfection — it's speed. Clean code changes fast. Messy code fights you.
- **Complexity is incremental.** No single decision makes a codebase complex. It's hundreds of small "just this once" compromises that compound. The same way conventions compound positively, shortcuts compound negatively.
- **The invisible work is engineering.** Specs, structure, conventions, context setup — the work that makes execution feel easy. If you spent a day on that and wrote zero code, you still shipped. This is glue work — it doesn't look like building, but nothing gets built well without it.

The ratio shifts by context — a small UI tweak doesn't need 80% planning, and a new system touching core infrastructure might need 90%. The principle behind the ratio is more durable than the numbers: **thinking is cheaper than fixing.**

**9 principles to internalize:**
1. **Aim for simplicity.** Simple = readable, changeable, few things to think about. Simple is not the same as easy — a framework can be easy to start with but complex to change. Prefer deep over shallow: a good function has a simple interface and does a lot behind it. A self-contained 200-line file is simpler than a 50-line file that imports from 8 others.
2. **YAGNI — You Aren't Going To Need It.** Don't build for requirements that don't exist yet. You are bad at predicting the future.
3. **Discover abstractions, don't design them.** Wait until the pattern repeats before extracting. Premature abstraction is worse than duplication.
4. **Think about time as a design constraint.** Shortcuts are fine if deliberate and documented. "I'll fix it later" without a ticket is a wish, not a decision.
5. **Type 1 vs Type 2 decisions.** Type 1 = hard to reverse (database schema, public APIs) — proceed carefully. Type 2 = reversible (UI, naming, library choice) — just decide. Most decisions are Type 2.
6. **Invest in what compounds.** If it makes the next 10 sessions better, add it now. If it's a one-time need, add it when you need it.
7. **The builder shouldn't be the reviewer.** Fresh eyes catch what the author can't. Have someone — or a separate agent — challenge your work before you commit.
8. **Verify, don't trust.** Every change needs a way to prove it works — tests, build, lint, browser. Applies to your own code and AI-generated code equally.
9. **Own what you ship.** If you can't explain why the code is structured this way, you don't understand it enough to maintain it. AI types, you think.

**Essential resources:**
- "A Philosophy of Software Design" by John Ousterhout — the best book on simplicity and complexity in code. Short, practical. Start here.
- [The Grug Brained Developer](https://grugbrain.dev) — funny, brutally honest essay on fighting complexity. 20 minutes.
- [Goodbye, Clean Code](https://overreacted.io/goodbye-clean-code/) by Dan Abramov — the moment he realized premature abstraction was worse than duplication. 5 min read.

> [!tip]- Further reading
> - [Simple Made Easy](https://www.infoq.com/presentations/Simple-Made-Easy/) by Rich Hickey (~60 min) — deeper take on why simple and easy are not the same
> - Jeff Bezos' 2015 shareholder letter on Type 1 vs Type 2 decisions — the original framing

---

## Part 2: Questions to Ask at Every Stage
These are the checklists that build judgment over time. Come back to these every time you build.

### Before Building
```
- What problem am I actually solving? For whom?
- What triggered this work? (customer feedback, bug, internal idea, strategic decision)
- Do I understand the existing codebase enough to plan? (folder structure, relevant files, patterns already in use)
- What does "done" look like?
- What's the simplest thing that could work?
- Is this reversible? (Type 1 vs Type 2 decision)
- Have I captured enough context that someone else — or AI — could build this without asking me 20 questions?
- Can I sketch the structure before writing code?
- What's my folder structure philosophy — and why?
```

### While Building
```
- Can someone with no context understand this in 6 months?
- Am I discovering this abstraction or forcing it?
- Am I building for a real requirement or an imaginary one?
- Does the naming reveal intent without reading the body? If I can't name it simply, is it doing too much?
- Can I understand this behavior without opening multiple files? (locality of behavior)
- Is this route thin? Does the logic live in lib/ where it's reusable?
- Is the user waiting for work they don't care about? (webhooks, analytics → background)
- What happens when this input is empty/null/unexpected?
- What else does this change touch? What breaks if it fails?
- Am I handling the sad path, not just the happy path?
```

### Before Shipping
```
Design
- Does the overall design make sense?
- Does it integrate well with the rest of the system?

Correctness
- Is it bug-free? Does it solve the intended problem?
- Are edge cases handled?
- Do the tests verify behavior, not just coverage?

Readability
- Can someone build a mental model of this code quickly?
- Is the "why" documented, not just the "what"?

Side Effects
- What are the side effects of this change?
- Is the failure mode graceful for the user?

PR Hygiene
- Is the PR small and focused on one thing? (aim for <500 lines, <10 files)
- If it's too big, can I split by layer (database → backend → frontend), by component (API → UI → integration), or by refactor vs feature?
- Does the commit history tell a story?
```

### After Shipping
```
- What broke? Why? Was it predictable?
- What trade-off did I make? What did I choose, what did I reject, and why?
- What would I do differently with hindsight?
- What did I learn that changes how I build next time?
```

**Essential resource:**
- [Google's Code Review Developer Guide](https://google.github.io/eng-practices/review/reviewer/) — the actual guide Google uses for code reviews. The "What to look for in a code review" section is gold.

> [!tip]- Further reading
> - [How to Make Your Code Reviewer Fall in Love with You](https://mtlynch.io/code-review-love/) by Michael Lynch
> - "The Checklist Manifesto" by Atul Gawande — why checklists work in high-stakes fields
> - "On Writing Software Well" by DHH (YouTube playlist) — experienced dev thinking out loud

---

## Part 3: What Good vs Bad Looks Like
Reference this when building or reviewing code. If something looks like the right column, stop and fix it.

### Code Structure & Readability
| Good | Bad |
|------|-----|
| Each file has a clear, single responsibility | One file doing five different things |
| Naming tells you what something does without reading the body | `handleClick2`, `tempFunc`, `data2` |
| Related code lives together, unrelated code is separated | Utility functions scattered across random files |
| Dependencies flow one direction — features don't import from each other | Feature A imports from Feature B which imports from Feature C — tangled web |
| Small, focused functions that do one thing | 200-line functions with nested if/else chains |
| API routes are thin — validate and delegate to business logic in `lib/` | All logic crammed into the route file (validation, database calls, side effects) |

### Error Handling & Logging
| Good | Bad |
|------|-----|
| Custom error types with codes, handled once at the boundary | Inline `res.status(400).json(...)` scattered across every route |
| Errors are caught and handled with useful feedback | `try/catch` that swallows errors silently |
| User sees a helpful message when something fails | Raw stack trace or silent failure |
| Production logs with context: who, what, where, why it failed | `console.log("here")` scattered everywhere |
| Structured logs with labels: `[POST /api/billing] Failed { userId, error }` | Unlabeled `console.log(data)` — no idea which flow it belongs to |
| Request IDs to trace one user's journey across the system | Logs from all users mixed together with no way to filter |
| Sensitive data (passwords, tokens, card numbers) never logged | Full credentials dumped into logs |

See [Logging in Production](Logging in Production.md) for deeper guidance.

### Auth & Security
| Good | Bad |
|------|-----|
| Auth enforced in one place (middleware) | Auth check copy-pasted in every route |
| Inputs validated at the API boundary | User content rendered without sanitization |
| Dependencies audited regularly | `npm audit` with critical vulnerabilities ignored |

### API Design
| Good | Bad |
|------|-----|
| Consistent naming, proper HTTP status codes | Mixed conventions, everything returns 200 |
| Validates input at the boundary with a shared schema (Zod, etc.) | No validation, or manual if-checks scattered through the route |
| One schema defines the contract — shared by frontend and backend | Frontend and backend disagree on field names, types drift silently |
| Designed for backward compatibility | Breaking changes deployed with no warning |

### Deployment & Shipping
| Good | Bad |
|------|-----|
| CI/CD with tests, preview deploys, rollback plan | Manual `git pull` on a VPS and pray |
| Zero-downtime deploys | "Deploy at 2am when no one's using it" |
| Deploy, verify, rollback in under 5 minutes | Rollback means reverting and redeploying for 20 minutes |

**Essential resource:**
- [Naming Things in Code](https://www.youtube.com/@CodeAesthetic) by CodeAesthetic (YouTube, ~8 min) — short video that clicks immediately. You'll start seeing bad naming everywhere after this.

> [!tip]- Further reading
> - "Clean Code" by Robert C. Martin — early chapters on naming and functions only. Later chapters get dogmatic.
> - [The Wrong Abstraction](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction) by Sandi Metz — duplication is cheaper than the wrong abstraction
> - [Cal.com GitHub repo](https://github.com/calcom/cal.com) — well-structured Next.js app to browse

---

## Part 4: The Trade-Off Muscle
This is the core skill. Not "always choose quality" or "always ship fast" — it's knowing when to switch gears.

| Situation | Lean Toward |
|-----------|-------------|
| Prototype / validating an idea | Speed. Ship ugly, learn fast. |
| Core infrastructure (auth, data model, payments) | Quality. You'll live with this for years. |
| Deadline pressure on a non-critical feature | Speed, but document the tech debt explicitly. |
| Anything touching user data or money | Quality. Always. No exceptions. |
| Choosing between two good options | Pick either one fast. Indecision is more expensive than a wrong call. |
| Choosing a tech stack for a new project | Boring. Pick the most adopted, most documented, most AI-fluent option. Save innovation tokens for the product. |
| Tempted to add a new tool or service | First ask: "How would we solve this with what we already have?" Only add if the unnatural acts are truly unbearable. |
| Task that needs your judgment (design, architecture, tradeoffs) | Do it yourself. This is where you compound. |
| Task that's mechanical execution (boilerplate, migrations, formatting) | Delegate. Your judgment isn't needed here — your attention is the scarce resource. |

**Essential resource:**
- [Choose Boring Technology](https://boringtechnology.club) by Dan McKinley — why you should default to proven, boring tools. Every new technology has a cost. You get a limited number of "innovation tokens."

> [!tip]- Further reading
> - "Thinking in Bets" by Annie Duke — every architecture choice is a bet under uncertainty
> - "The Thirty Percent Rule" by Kris Brandow — balancing tech debt vs feature work
> - "Accelerate" by Nicole Forsgren — research on what makes engineering teams fast

---

## Part 5: The Practice Loop
Taste isn't learned from reading — it's forged through build, judge, break, learn, repeat.

| Practice | What It Builds |
|----------|---------------|
| Build something real, end-to-end | Systems thinking — see how pieces connect |
| Review your own code using the Part 2 checklists | Self-critique — catch your own blind spots with a concrete framework |
| Read great codebases | Pattern recognition — absorb what "great" feels like |
| Write down why you made each decision | Forces you to articulate *why*, not just *what* |
| Do post-mortems on your own failures | Not just what broke, but *why* it broke |
| Teach or explain what you built | The biggest brain move isn't building the hardest thing — it's explaining the simple thing well |
| Ask: which principle or skill didn't apply to anything I built recently? | Pruning — cut what's dead weight, update what's drifted, add what's missing |

**Start with one codebase (browse, don't study):**
- [Bulletproof React](https://github.com/alan2207/bulletproof-react) — the architecture reference. Study how it's structured, then look at code.

> [!tip]- More codebases and people to follow
> **Codebases:**
> - [Cal.com](https://github.com/calcom/cal.com) — real product, well-structured Next.js app
> - [Shadcn/ui](https://github.com/shadcn-ui/ui) — clean component library
> - [T3 Stack](https://create.t3.gg) — full-stack TypeScript template
>
> **People:**
> - [Dan Abramov](https://overreacted.io) — React fundamentals
> - [Kent C. Dodds](https://kentcdodds.com) — testing and React patterns
> - [Theo Browne](https://www.youtube.com/@t3dotgg) — full-stack trade-offs
> - [CodeAesthetic](https://www.youtube.com/@CodeAesthetic) — short visual videos on code quality
> - [Fireship](https://www.youtube.com/@Fireship) — fast visual explainers
> - [The Primeagen](https://www.youtube.com/@ThePrimeagen) — senior engineer thinking out loud

---

## Part 6: Recommended Learning Path
A suggested progression — start wherever feels right, skip what you've already absorbed, revisit as you grow:

### Phase 1: Build the Eye
You're already shipping code — this is about adding a judgment layer on top.
- [ ] Read "A Philosophy of Software Design" by John Ousterhout
- [x] Read "The Grug Brained Developer" (grugbrain.dev)
- [x] Read "Goodbye, Clean Code" by Dan Abramov
- [x] Watch "Naming Things in Code" by CodeAesthetic (8 min)
- [x] Browse Bulletproof React repo — folder structure first, code second
- [ ] Write a CLAUDE.md for your current project (template in Part 0)

### Phase 2: Understand the System
Zoom out to see how pieces connect.
- [x] Read "Choose Boring Technology" by Dan McKinley
- [x] Read Google's Code Review guide
- [ ] On your next feature, use the "While Building" checklist and write down what you notice

### Phase 3: Build the Muscle (ongoing)
Judgment becomes instinct through repetition.
- [ ] After every feature, log what you learned in the Learnings Log below
- [ ] Review your own PRs using the "Before Shipping" checklist before requesting review
- [ ] On your next new project, use the Part 0 scaffolding checklist before writing code

---

## My Learnings Log

> [!info]- Logging guide (for AI and human)
> When something clicks or breaks while building, log it here. Tell Claude Code "log this learning" and it adds an entry.
>
> **Format:**
> ```
> ### YYYY-MM-DD — [tag] Sticky headline
> - Bullet points with enough context to stand on their own months later
> - Include the "why" or an example when the concept isn't self-explanatory
> - Not paragraphs, not over-simplified — enough depth to recall, concise enough to scan
> ```
>
> **Tags:** `[structure]` `[debugging]` `[tradeoff]` `[naming]` `[patterns]` `[git]` `[testing]` `[communication]` `[simplicity]` `[review]` or whatever fits.
>
> **Rules:**
> - Newest entries go at the top
> - Each entry should make sense without needing the original conversation
> - Headlines should be memorable phrases that capture the core lesson
> - When this section gets long, split it into its own `[Engineering Learnings Log](Engineering Learnings Log.md)` file

### 2026-03-30 — [patterns] Verify, don't trust + Own what you ship
- Added two new principles after stress-testing the existing seven. Both fill gaps that are especially important when building with AI.
- "Verify, don't trust" was already implicit everywhere (tests, build, lint, browser checks) but never stated as a principle. Making it explicit means it applies consistently — to your own code, to AI-generated code, to dependencies.
- "Own what you ship" captures the difference between using AI well and being a middleman. If you can't explain the code, you can't maintain it. Understanding compounds; copy-pasting doesn't. This is what separates "AI-assisted" from "AI-dependent."
- Also tightened all 9 principles to bold one-liner + max 2 sentences. Same format as the AEO playbook's 11 principles — scannable (read the bold) and deep (read the explanation when needed).

### 2026-03-30 — [tradeoff] Most of the work happens before and after writing code
- The hard part of engineering isn't typing code — it's thinking clearly before and after. Plan thoroughly, review to catch issues, codify knowledge, keep quality high so future changes are easy.
- Maps to the skill workflow: `/eng-spec` (explore + spec) and `/eng-stress-test` + `/eng-check` + `/deslop` (review) are where the bulk of the value lives. `/eng-build` (execution) should feel like the easy part.
- The balance shifts by context: small UI tweak needs less planning. New system touching core infrastructure needs almost all thinking. The framing is directional, not a formula.
- This is why the exploration mode in `/eng-spec` matters — rushing past "what are we actually building?" to get to code faster is the most expensive mistake.
- If execution feels hard, the planning was incomplete. If review finds too many issues, the planning was rushed.

### 2026-03-30 — [patterns] Invest in what compounds, defer what doesn't
- The filter for when to add something upfront vs later: "will this make the next 10 sessions better, or just this one?" If it compounds — conventions, principles, structure — add it now. If it's a one-time need, add it when you need it.
- This is YAGNI applied to context and process, not just code. Don't preload AI skills with context that's only relevant later. Don't add abstractions until the pattern repeats. Don't scaffold for hypothetical contributors.
- Examples: engineering principles in CLAUDE.md compound (every session benefits). An open source section in `/eng-init` doesn't compound until you're actually maintaining an open source project. A stress-test step in `/eng-spec` compounds (every spec benefits from challenge).
- The same principle applies to what you feed AI. Every piece of context in a skill or rules file has a cost — it takes up space and attention. Only include what earns its keep across many uses.

### 2026-03-30 — [review] The builder shouldn't be the reviewer
- The agent that writes a spec has blind spots about its own assumptions — same reason code reviews exist. Asking it to stress-test its own work produces weaker challenges than a fresh agent that reads the spec cold.
- Built this into `/eng-spec`: after writing the spec, it spawns a separate sub-agent (`/eng-stress-test`) that reads the spec with no knowledge of how it was written. The sub-agent loads CLAUDE.md and explores the codebase independently, then challenges the design.
- This is a general principle, not just an AI workflow trick. It applies to code reviews, design critiques, spec reviews, and QA. The author's sunk cost and familiarity create blind spots that only fresh eyes can catch.
- The sub-agent pattern in Claude Code: the parent agent spawns a child with the Agent tool. The child gets its own fresh context window — no inherited reasoning or bias. It only knows what it reads.

### 2026-03-29 — [patterns] Goal + tools + constraints > step-by-step orchestration
- Anthropic's own advice: don't box the model in. Give it tools, give it a goal, let it figure out the path. A year ago you needed scaffolding and strict workflows. Now you mostly don't — and the gap keeps widening.
- This is the Bitter Lesson applied to AI-assisted coding. General methods (clear goals, good tools, clean context) always outperform hand-engineered orchestration (step 1 → step 2 → step 3 workflows).
- What to hold onto: decomposition is still fundamental engineering — but it's a *thinking* tool for humans, not a limitation of the model. Decompose to sharpen your understanding, then give the model the full picture.
- What to let go of: prescriptive prompt structures (Task/Background/Do not), micro-step choreography in skills, breaking tasks down *for the model's sake*. These were training wheels. Test whether they're still needed — they probably aren't.
- The durable investments: CLAUDE.md (conventions), project structure (context engineering), tool access (MCPs, browser, docs), verification (tests, build, visual checks), acceptance criteria (definition of done). These work regardless of model generation.
- Updated `/eng-build` to reflect this: goal + constraints + verify, not step-by-step execution instructions. Updated [Working Effectively With AI](Working Effectively With AI.md) deep dive with tool-first thinking and the Bitter Lesson framing.

### 2026-03-27 — [structure] Seven patterns of a well-structured feature
- Navigated five production codebases using the deep dive method. Same seven patterns appeared in every mature codebase regardless of language or framework. One codebase (Papermark) showed what happens when the patterns aren't partially applied — working product, but growing friction from duplicated auth, fat routes, and no shared schemas. Cal.com was the most disciplined — they codified these patterns as explicit engineering rules in their `CLAUDE.md` and `agents/rules/` directory.
- **Seven timeless patterns:**
- **1. Thin routes, thick logic.** API routes should only validate input and delegate to business logic that lives separately. Routes are the receptionist, not the doctor. This keeps logic reusable — the same function can be called from an API route, a CSV import, or a background job.
- **2. One schema as the contract.** Define the shape of your data once. Frontend and backend both reference it. No drift, no "the API changed but the form didn't." Catches mismatches at build time instead of production. Every language has its version: Zod (JS), Django Serializers (Python), etc.
- **3. Wrap cross-cutting concerns, don't copy them.** Auth, permissions, error handling — anything every route needs should be handled once in a wrapper or base class, not duplicated per file. You'll never accidentally ship an unprotected route. Security by structure, not by memory.
- **4. Mirror feature names across layers.** If the feature is "issues," it should be `views/issue/`, `serializers/issue.py`, `services/issue/`, and `store/issue/`. Predictable naming means you always know where to look — no searching. This is feature-based architecture (3/25 learning) applied one level deeper.
- **5. Side effects happen after the response.** Webhooks, analytics, notifications, audit logs — the user doesn't wait for work they didn't ask for. Every codebase separates this: `waitUntil` (JS), `.delay()` (Python/Celery), background queues. Respond first, do housekeeping after.
- **6. Structured errors, handled at the boundary.** Define custom error types with codes, throw them anywhere, handle them once at the top. Individual routes don't format error responses — one central handler does. Every mature codebase has this.
- **7. Wiring files do zero logic.** Routers, URL configs, layouts, providers — these files compose pieces together but contain no business logic themselves. They read like a table of contents for the codebase.
- These don't directly improve UX — users don't care about your file structure. They compound into speed: a clean codebase means week 12 of building feels as fast as week 1. A messy one slows you down ~5% every week until you're fighting your own code more than building features.
- **Comparison across five codebases:**

| Principle | Dub (Next.js) | Documenso (Remix) | Papermark (Next.js) | Plane (Django+React) | Cal.com (Next.js) |
|---|---|---|---|---|---|
| 1. Thin routes | `withWorkspace` → `lib/api/` | `authenticatedProcedure` → `lib/server-only/` | Fat routes (all logic inline) | ViewSet → serializer + ORM | tRPC → Services → Repositories |
| 2. Schema as contract | Zod in `lib/zod/schemas/` | Zod in `.types.ts` per route | Partial (some Zod, mostly manual) | Django Serializers | Zod DTOs at every boundary |
| 3. Auth wrapped once | `withWorkspace` wrapper | `authenticatedProcedure` | Copy-pasted per route | `BaseViewSet` + `@allow_permission` | tRPC procedures + page-level checks |
| 4. Feature name mirroring | `api/links/`, `lib/api/links/`, `use-links.ts` | `document-router/`, `lib/server-only/envelope/`, `trpc.document.*` | SWR hooks yes, backend inconsistent | `views/issue/`, `serializers/issue.py`, `services/issue/`, `store/issue/` | `features/bookings/` with repositories, services, hooks, components |
| 5. Side effects after response | `waitUntil()` | `triggerWebhook()` | `waitUntil()` | `.delay()` (Celery) | Trigger.dev tasks |
| 6. Structured errors | `DubApiError` with codes | `AppError` with `AppErrorCode` | `TeamError`/`DocumentError` (basic) | `BaseViewSet.handle_exception()` | `ErrorWithCode` + factory methods, auto-converted by middleware |
| 7. Wiring = zero logic | `middleware.ts`, route files | `router.ts` files | `middleware.ts`, layouts | `urls.py` | `_app.ts`, routers, layouts |

### 2026-03-26 — [review] "I'll fix it later" is a wish, not a decision
- Work piles up every week — there's always something more urgent. If a shortcut isn't tracked with a ticket and a plan for when to address it, it's never getting fixed. Six months later, nobody remembers why it was done that way, and now it's "just how it works."
- The difference: "I'll clean this up later" (wish) vs "TODO: refactor auth flow — ticket #142, targeting next sprint" (decision). Principle #4 says shortcuts are fine if deliberate and documented. The documentation is what makes it a decision.
- This shows up most in code review. When someone says "I'll fix it in a follow-up PR," that follow-up almost never lands. If it matters enough to mention, it matters enough to fix now or track properly.

### 2026-03-26 — [patterns] Context engineering includes doc pointers — teach the AI where to look, not what to know
- AI agents hallucinate less when they know where to find authoritative information. Adding framework doc URLs to CLAUDE.md is cheap context that prevents expensive mistakes.
- Lightweight pointers > stuffing docs into context. A URL costs one line; pasting full docs fills the context window fast. The AI can `WebFetch` when it actually needs something.
- Built this into `/eng-init` as a lookup table of common stacks (React, Next.js, Supabase, Tailwind, etc.). User says their stack, skill auto-populates the right doc URLs. Unknown tech → ask for the URL.
- The behavioral nudge matters: "look these up before guessing" tells the AI to verify rather than assume. It's the same reason senior devs keep docs bookmarked — not because they don't know, but because they verify.
- This is perishable info (URLs can change, frameworks evolve) but it lives in the right place: per-project CLAUDE.md, not the timeless playbook. Follows the "timeless over trendy" rule — principles in the playbook, tool-specific references in project config.

### 2026-03-25 — [tradeoff] Choose boring technology — spend innovation tokens on product, not infrastructure
- Dan McKinley's "Innovation Token" model: you have ~3 tokens for novel, unproven technology choices. Spend them on what makes your product different, not on your stack.
- Boring tech = known failure modes. The advantage isn't that it's good — it's that you know why it's bad. New tech means months discovering problems that boring tech already has on record.
- The real cost is operation, not development. The ongoing cost to run a technology in production almost always outweighs the initial development convenience. You're choosing a tool for years, not a sprint.
- The mastery paradox: "You should use the tool you hate the most — because you hate it because you know the most about it." Engineers bail during the hard middle, creating a graveyard of half-mastered tools.
- Boring tech + AI = unfair advantage. AI is most fluent in widely-adopted, heavily-documented technologies. The most popular stack is the stack where AI helps you most.
- The heuristic for new tools: (1) How would we solve this with what we already have? (2) What "unnatural acts" does that require? (3) Only if truly unbearable, add something new — and commit to replacing the old thing, not running both.
- Applied to stack selection: Next.js, TypeScript, Supabase (Postgres), Tailwind + shadcn/ui, Vercel. Five pieces, nothing redundant. Every innovation token saved for product.
- Ship first, switch later. The cost of worrying about portability before you have users is higher than the cost of migrating when you actually need to.

### 2026-03-25 — [patterns] AI is a multiplier — good habits in, good code out
- AI multiplies what you already know. If you don't understand the problem, AI won't solve it for you.
- The 3-section prompt pattern: (1) Task — detailed technical description, (2) Background — docs, files, screenshots, links, (3) Do not — what AI shouldn't touch or change. This dramatically improves output quality.
- Break big tasks into small ones for AI. AI is good at small, scoped tasks. If you can't break it down, you don't understand the problem yet — and that's not an AI trick, that's fundamental engineering.
- Use rules files (CLAUDE.md, guidelines.md) so AI remembers project context across sessions. Write it once, benefit every session.
- Always give AI a way to verify its work — tests, browser, CLI, CI/CD. Don't let it just write code blindly.
- Don't let AI think for you. Let it type for you. The moment you outsource your thinking, you're not applying any skill — you're just a middleman.
- See [Working Effectively With AI](Working Effectively With AI.md) for the full deep dive.

### 2026-03-25 — [structure] Feature-based architecture is context engineering for AI
- Bulletproof React's structure isn't just clean for humans — it controls what AI sees, which controls the quality of what it produces.
- Three-ring dependency model: Shared (generic components) → Features (self-contained business slices) → App (routes that compose features). Dependencies only flow inward, never the reverse.
- A component lives in `src/components/` only if it's used by multiple features with no domain-specific behavior. The moment it needs a feature's API hook or business type, it belongs in that feature's `components/` folder.
- Feature isolation = safer AI edits. Because features can't import from each other, AI edits to one feature can't accidentally break another.
- When scoping AI tasks: feature work → middle ring, shared UI changes → inner ring, new pages → outer ring. Each task has a clear, bounded scope.
- Components "graduate" to shared only when you discover they're needed in multiple places. Principle #3 in action.

### 2026-03-25 — [naming] Name things for the reader, not the writer
- Don't abbreviate — `buildingPermit` over `bldPrmt`. You read code far more than you write it.
- Don't put the type in the name — `users` not `userList`. The type system handles that.
- Don't repeat context — `user.getName()` not `user.getUserName()`.
- Match name length to scope — short names for tiny scopes (`i` in a loop), descriptive names for wide scopes (functions used across the codebase).
- If you can't name it simply, it's doing too much — struggling to name a function is a design smell. Same principle as the "and" test for components.
- One-liner: good naming means the next person (or AI) doesn't have to read the body to understand what something does.

### 2026-03-25 — [simplicity] "Clean" code that's hard to change isn't clean — it's just tidy
- Dan Abramov's "Goodbye, Clean Code" — he refactored a colleague's duplicated animation code into a shared abstraction. It looked cleaner. His boss reverted it.
- The duplication wasn't accidental — each block needed to evolve independently for different product requirements. The "clean" version coupled unrelated things together, making every future change risky.
- The trap: code that *looks* the same isn't always *the same*. The real question is "will these things change for the same reason?" — not "do they look similar right now?"
- This reinforces Grug Brain and Sandi Metz's "Wrong Abstraction" — duplication is cheap to fix later, but a bad abstraction is expensive to undo because everything depends on it.
- One-liner: clean code that's hard to change isn't clean — it's just tidy.

### 2026-03-23 — [structure] When to split a component — the "and" test
- If you describe a component and use the word "and," each "and" is a split point. "This shows the billing form AND payment history AND plan comparison" → three components.
- Other signals: scrolling a lot in one file, big conditional renders (admin vs user), passing props through components that don't use them, copy-pasting JSX chunks, useEffects doing unrelated work.
- You mostly detect it by the pain it causes — but the "and" test catches it before the pain.
- When vibe coding, you won't notice. That's why CLAUDE.md should tell AI to flag growing components proactively.

### 2026-03-23 — [patterns] Concurrency in practice — simpler than it sounds
- Concurrency is when multiple things happen at the same time. In JavaScript, it's mostly about managing async operations — not threads or mutexes.
- `Promise.all` for parallel fetches — load multiple independent data sources at once instead of one by one.
- Disable buttons after click to prevent double submits — especially for payments and form submissions.
- Version numbers on data to prevent one user silently overwriting another's changes (optimistic concurrency).
- Ignore stale responses in search/autocomplete — track a request ID, only use the latest result.
- Background job queues for anything slow (emails, PDFs, image processing) — respond to the user immediately, do the work later.
- You don't need to learn thread safety or semaphores. These 5 patterns cover 95% of product concurrency.

### 2026-03-23 — [patterns] Production logging is part of the feature, not debugging leftovers
- Two kinds of logs: debugging logs (temporary, delete before shipping) and production logs (permanent, shipped intentionally).
- Production logs tell you what happened when you weren't there. The API response serves the user — the logs serve you at 3am.
- Good logs have: a label (`[POST /api/billing]`), context (userId, plan), and the outcome (success or error with reason).
- Request IDs tie all logs from one user's action together — essential when multiple users are hitting the app.
- Never log secrets, passwords, tokens, or credit card numbers.
- Start simple: `log(level, context, message, data)`. Move to a proper logging library when you outgrow it.

### 2026-03-23 — [structure] Locality of Behavior > Separation of Concerns (most of the time)
- Locality of Behavior (LoB): everything needed to understand one behavior lives in one place. Separation of Concerns (SoC): code grouped by what it *is* (styles, logic, validation) across multiple files.
- LoB wins most of the time. If you need to open 5 files to understand what happens when a user clicks a button, you've over-separated.
- The test: "If I change this behavior, how many files do I need to touch?" If 1 → good locality. If 5 → over-separated.
- Separate only when code is genuinely reusable across features (auth middleware, formatCurrency) or when a file gets unreadably long doing very different things.
- This is context engineering for AI too — when Claude Code reads a file with good locality, it gets the full picture in one read. Scattered code means more files loaded into context, more noise, worse AI output.
- Tailwind CSS is LoB applied to styling — styles on the element, not in a separate file. Same principle.
- Feature-based folder structure (Part 0) is LoB applied to project organization. This principle runs through everything.

### 2026-03-23 — [simplicity] Duplication is cheaper than the wrong abstraction
- Before extracting shared code, ask: "Will these two things change for the same reason?" If yes → extract. If no or unsure → keep them separate.
- You can always extract later once the real pattern reveals itself. But un-doing a bad abstraction is painful — by then everything depends on it.
- Example: two features both fetch user data. Looks like duplication, but billing needs invoices and dashboard needs projects. A shared `getUser(options)` couples them through a function neither truly owns.
- Principle #3: discover abstractions, don't design them.

### 2026-03-23 — [patterns] Refactor small, respect working code
- Refactor when the mess is actively slowing you down, not just because it looks ugly.
- Before removing "unnecessary" code, check `git blame` to understand why it was added. Someone may have already learned the hard way why it's there (Chesterton's Fence — don't tear down a fence until you understand why it was built).
- One refactor per PR. Keep the system working at every step. Never refactor and add features at the same time — if something breaks, you won't know which change caused it.
- Working imperfect code that's survived production has more value than a "perfect" rewrite that hasn't.

### 2026-03-23 — [testing] Integration tests > unit tests
- Most unit tests break on every refactor and don't tell you if the system actually works. They test pieces in isolation, but bugs happen at the seams between pieces.
- Integration tests are the sweet spot — they test real user flows (submit form → API processes → response returns) and survive internal restructuring because they test behavior, not implementation details.
- When deciding what to test, ask: "If I could only write one test for this feature, what would it be?" That's your integration test. Write it first.
- Unit tests are still worth it for pure logic with edge cases (calculations, formatting, business rules).
- "Write tests. Not too many. Mostly integration."

---

*Come back to this often. The questions won't change — but the ability to answer them gets sharper every time I build something real.*

---

*Resources last reviewed: 2026-03-22. Principles are timeless. Resources, tools, and people recommendations may age — revisit when something feels outdated.*
