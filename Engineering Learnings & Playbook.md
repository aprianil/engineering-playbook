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
> - Follow the playbook's own principles. Simplicity first. Don't bloat it.
> - Don't add sections preemptively. Add them when there's a real learning to capture.
> - Timeless over trendy. Principles should last. Resources and tools are perishable — flag them as such.
> - No rigid rules. Guidelines that flex beat hard rules that fight you.
> - Walk me through your thinking before making edits. I want to approve the reasoning first.
> - Check for internal conflicts before adding anything new. Don't let new advice contradict existing principles.
> - Tone: practical, direct, written for a designer/product builder. Not academic, not CS-heavy.
> - Only use the principles and learnings documented here when writing or editing code in my projects. Don't guess or invent new philosophy — work with what's in this file.
> - **This playbook is the root, not the container.** When a topic needs a deep dive, suggest creating a new .md file in this vault (flat structure, no subfolders — all files live at the vault root) and link to it from here using `[[Note Name]]`. Keep the playbook as a clean hub that links out — don't let it grow into a textbook.

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
| [[How to Read and Navigate an Unfamiliar Codebase]] | Finding your way through a project you didn't build |
| [[How to Learn From Your Engineer's Code]] | Turning PRs and code review into a learning tool |
| [[Debugging Mindset]] | A systematic approach to fixing bugs instead of guessing |
| [[Git Workflow Fundamentals]] | Commits, branches, PRs, and the mechanics of shipping code |
| [[Testing - When and What to Test]] | What's worth testing, what's not, and how to think about it |
| [[Communicating Technically With Engineers]] | Asking the right questions, translating between product and engineering |
| [[Logging in Production]] | Production logging is permanent code, not debugging leftovers |
| [[Race Conditions]] | Timing bugs when things happen at the same time — common when vibe coding |
| [[Working Effectively With AI]] | How to communicate with AI coding tools — prompting, context engineering, and verification |

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

Do this instead (organized by feature):
/components          ← shared, generic (Button, Form, Table — no business logic)
  /ui
    Button.tsx
    Form.tsx
    Table.tsx
  /layouts
    DashboardLayout.tsx
/features            ← self-contained business slices
  /billing
    /components      ← billing-specific UI (composes shared components)
      BillingCard.tsx
      CreateInvoice.tsx
    useBilling.tsx
    billingApi.ts
    billing.test.ts
  /user
    /components
      UserProfile.tsx
    useUser.tsx
/lib                 ← third-party configs and integrations
```

**Two tiers of components:**
- `src/components/` — shared, generic building blocks. Used across multiple features. Knows nothing about any business domain.
- `features/billing/components/` — specific to that feature. Composes shared components with feature-specific logic. Lives inside the feature folder.

A component starts in its feature folder. It only "graduates" to shared when you discover it's genuinely needed by multiple features — not before (Principle #3).

**Dependencies flow one direction:** shared → features → app (routes/pages). Features never import from each other. Shared never imports from features. This keeps the blast radius small — changes to billing can't break user.

When you're working on billing, you only touch the billing folder. Context stays clean. No jumping across 6 folders to understand one feature.

This also means when AI helps you with billing, it reads the billing folder and gets the full picture — no noise from unrelated features polluting the context.

### The Scaffolding Checklist

Before starting any new project, answer these:

```
Structure
- What are the 3-5 core features? Each one becomes a folder.
- What's truly shared across features? That goes in /shared.
- Where do API calls live? Co-located with the feature that uses them.
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

Step 3 (more complexity, still contained):
/features
  /billing
    BillingPage.tsx
    BillingCard.tsx
    useBilling.tsx
    billingApi.ts
    billing.test.ts
```

The rule: split when a file does too many things, not before. This is Principle #3 in action — discover the structure, don't over-design it upfront.

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
/features    — feature-based folders, each self-contained
/shared      — reusable components and utilities
/lib         — third-party integrations and configs

## Conventions
- Feature folders: everything related to a feature lives together
- Naming: PascalCase for components, camelCase for functions/hooks
- Imports: use @/ alias for root-level imports
- Components: split when they do too much — favor readability over line count

## Commands
- npm run dev — start dev server
- npm run build — production build
- npm run test — run tests

## What to watch out for
- [Any known gotchas, quirks, or things that break easily]
```

This takes 5 minutes to write and pays off in every AI session. Claude Code will follow these conventions automatically instead of guessing.

### Working With AI Coding Tools

Beyond rules files, there are habits that make AI consistently useful. These apply regardless of which tool you use — the principles are the same.

**The AI context mindset** — every time you structure a file or name a function, you're not just writing for yourself. You're writing for a future AI session that needs to understand this code fast. Clear naming, small files, and co-located features all make AI assistance dramatically better. The same things that make code maintainable for humans make it navigable for AI.

**Be specific when giving tasks** — the difference between "AI is useless" and "AI is incredible" is often how well you communicate. Give it the technical details, the constraints, the docs, and what it should *not* touch. When AI has to guess, you get code that looks right but isn't.

**Break tasks down** — AI is good at small, focused tasks. It struggles with big, ambiguous ones. If you can't break a task down into smaller pieces, you don't understand the problem well enough yet. This isn't an AI trick — it's fundamental engineering.

**Verify, don't trust** — AI should never just write code. Give it a way to prove the code works: tests, build commands, browser checks. If you let AI generate the tests, verify the tests too.

**Extend with tools** — most AI coding tools support plugins or extensions (MCPs, etc.) that give AI access to documentation, dev tools, databases. Find the ones that match your stack — the right combination makes a real difference.

See [[Working Effectively With AI]] for the full deep dive on prompting patterns, context engineering, and verification.

**Claude Code-specific practices:**

**Skills** — repeatable commands you can trigger with a slash. `/commit` writes a proper commit message. You can create custom skills for things you do often. Think of them as shortcuts that keep you in flow.

Custom skills built for this playbook:
- `/eng-init` — scaffolds a CLAUDE.md in any project with the engineering principles from this playbook baked in. Run once per project. Team-friendly — any contributor benefits from it.
- `/eng-check` — reviews code against the engineering principles in the project's CLAUDE.md. Use before opening a PR or when you want a staff-engineer-level check on your work.
- `/eng-spec` — describe what you want loosely, define acceptance criteria (evals), and let AI write the spec before any code. The spec becomes the blueprint. Evals first, then build.
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

**5 principles to internalize:**

1. **Aim for simplicity.** Cut as much as you can. Large and complicated software changes too slowly. Write code that reveals your intentions and is easy to change.

2. **YAGNI — You Aren't Going To Need It.** Don't write complicated software in anticipation of future requirements that may never appear. You are bad at predicting the future.

3. **Discover abstractions, don't design them.** Wait until you see the pattern repeat before extracting it. Premature abstraction is worse than duplication.

4. **Think about time as a design constraint.** It's okay to pick the quick way — but do it deliberately, document the trade-off, and plan to pay it down.

5. **Type 1 vs Type 2 decisions.** Type 1 decisions are hard to reverse — proceed carefully. Type 2 decisions are reversible — move fast. Most decisions are Type 2.

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
- What does "done" look like?
- What's the simplest thing that could work?
- Is this reversible? (Type 1 vs Type 2 decision)
- Can I sketch the structure before writing code?
- What's my folder structure philosophy — and why?
```

### While Building

```
- Can someone with no context understand this in 6 months?
- Am I discovering this abstraction or forcing it?
- Am I building for a real requirement or an imaginary one?
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
- Is the PR small and focused on one thing?
- Does the commit history tell a story?
```

### After Shipping

```
- What broke? Why? Was it predictable?
- What trade-off did I make? Was it right?
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
| Small, focused functions that do one thing | 200-line functions with nested if/else chains |

### Error Handling & Logging

| Good | Bad |
|------|-----|
| Errors are caught and handled with useful feedback | `try/catch` that swallows errors silently |
| User sees a helpful message when something fails | Raw stack trace or silent failure |
| Production logs with context: who, what, where, why it failed | `console.log("here")` scattered everywhere |
| Structured logs with labels: `[POST /api/billing] Failed { userId, error }` | Unlabeled `console.log(data)` — no idea which flow it belongs to |
| Request IDs to trace one user's journey across the system | Logs from all users mixed together with no way to filter |
| Sensitive data (passwords, tokens, card numbers) never logged | Full credentials dumped into logs |

See [[Logging in Production]] for deeper guidance.

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
| Validates input at the boundary | No validation, raw errors in responses |
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

- [ ] Read "Choose Boring Technology" by Dan McKinley
- [ ] Read Google's Code Review guide
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
> - When this section gets long, split it into its own `[[Engineering Learnings Log]]` file

### 2026-03-25 — [patterns] AI is a multiplier — good habits in, good code out
- AI multiplies what you already know. If you don't understand the problem, AI won't solve it for you.
- The 3-section prompt pattern: (1) Task — detailed technical description, (2) Background — docs, files, screenshots, links, (3) Do not — what AI shouldn't touch or change. This dramatically improves output quality.
- Break big tasks into small ones for AI. AI is good at small, scoped tasks. If you can't break it down, you don't understand the problem yet — and that's not an AI trick, that's fundamental engineering.
- Use rules files (CLAUDE.md, guidelines.md) so AI remembers project context across sessions. Write it once, benefit every session.
- Always give AI a way to verify its work — tests, browser, CLI, CI/CD. Don't let it just write code blindly.
- Don't let AI think for you. Let it type for you. The moment you outsource your thinking, you're not applying any skill — you're just a middleman.
- See [[Working Effectively With AI]] for the full deep dive.

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
