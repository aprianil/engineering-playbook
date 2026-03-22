# Engineering Learnings & Playbook

> A living document for building engineering taste and judgment — from a designer and product builder who ships code, toward thinking like a senior engineer.

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
- [[How to Read and Navigate an Unfamiliar Codebase]] — finding your way through a project you didn't build
- [[How to Learn From Your Engineer's Code]] — turning PRs and code review into a learning tool
- [[Debugging Mindset]] — a systematic approach to fixing bugs instead of guessing
- [[Git Workflow Fundamentals]] — commits, branches, PRs, and the mechanics of shipping code
- [[Testing - When and What to Test]] — what's worth testing, what's not, and how to think about it
- [[Communicating Technically With Engineers]] — asking the right questions and translating between product and engineering

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
/features
  /billing
    BillingCard.tsx
    useBilling.tsx
    formatCurrency.ts
    billing.test.ts
  /user
    UserProfile.tsx
    useUser.tsx
/shared
  Button.tsx
  formatDate.ts
```

When you're working on billing, you only touch the billing folder. Context stays clean. No jumping across 6 folders to understand one feature.

This also means when Claude Code helps you with billing, it reads the billing folder and gets the full picture — no noise from unrelated features polluting the context.

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
- Do I have a CLAUDE.md at the project root?
- Are my conventions written down (in CLAUDE.md) so I don't repeat myself every session?
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

### Claude Code Practices Worth Adopting

Beyond CLAUDE.md, there are a few Claude Code habits that keep your workflow clean:

**Skills** — repeatable commands you can trigger with a slash. `/commit` writes a proper commit message. You can create custom skills for things you do often (like running a specific test suite or deploying). Think of them as shortcuts that keep you in flow.

**Hooks** — automated actions that run before or after tool calls. For example, a hook that runs your linter every time Claude Code edits a file. This catches quality issues automatically without you having to remember.

**The AI context mindset** — every time you structure a file or name a function, you're not just writing for yourself. You're writing for a future AI session that needs to understand this code fast. Clear naming, small files, and co-located features all make AI assistance dramatically better. The same things that make code maintainable for humans make it navigable for AI.

**Resources to go deeper:**

- **Bulletproof React** (github.com/alan2207/bulletproof-react) — the single best reference for React project structure. Study the folder layout and read the docs explaining each decision. This is your go-to template.
- **"Screaming Architecture"** by Robert Martin (blog.cleancoder.com) — short blog post on why your folder structure should reflect the product domain, not the framework. Reads in 5 minutes.
- **Next.js Project Structure docs** (nextjs.org/docs/getting-started/project-structure) — Next.js is opinionated about structure on purpose. Understanding their conventions teaches you how good defaults reduce decision fatigue.
- **T3 Stack** (create.t3.gg) — run `create-t3-app` and study the scaffolded project. The docs explain *why* each folder and config exists. Great for understanding how auth, database, API, and frontend connect.
- **"Delighthat Reactful Architecture"** by Josh W. Comeau (joshwcomeau.com) — a practical walkthrough of how he structures React apps. Written in a friendly, visual style that works well for a design background.
- **"How to Structure Your React Project"** by Theo Browne (YouTube, ~15 min) — opinionated walkthrough of feature-based architecture. He explains the *why* behind every choice, not just the *what*.
- **"The Feature-Sliced Design"** (feature-sliced.design) — a more formal methodology for organizing frontends by feature. Can feel over-engineered for small projects, but the mental model is worth understanding. Read the overview, skip the deep docs until you need them.
- **Shadcn/ui source code** (github.com/shadcn-ui/ui) — look at how each component is self-contained with its own files. Great example of clean separation at the component level.
- **Claude Code documentation** (docs.anthropic.com/en/docs/claude-code) — official docs on CLAUDE.md, skills, hooks, and best practices. Read the CLAUDE.md section first, then skills and hooks when you're ready to automate.
- **"Claude Code Best Practices"** (anthropic.com) — how to structure projects for effective AI-assisted development. Covers context management, file organization, and working with CLAUDE.md.

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

**Resources to go deeper:**

- "A Philosophy of Software Design" by John Ousterhout — the best book on simplicity and complexity in code. Short, practical, written for people who build things. Start here.
- "The Grug Brained Developer" (grugbrain.dev) — a funny, brutally honest essay on fighting complexity. Reads in 20 minutes. Covers YAGNI, abstraction traps, and why simple beats clever.
- "Simple Made Easy" by Rich Hickey (talk on YouTube, ~60 min) — the most famous talk on why simple and easy are not the same thing. Changes how you think about design choices.
- "Goodbye, Clean Code" by Dan Abramov (overreacted.io) — a short blog post about the moment he realized premature abstraction was worse than duplication. Very relatable for someone coming from a "make it clean" mindset.
- Jeff Bezos' 2015 shareholder letter on Type 1 vs Type 2 decisions — the original framing. Worth reading once.

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

**Resources to go deeper:**

- "How to Make Your Code Reviewer Fall in Love with You" by Michael Lynch (mtlynch.io) — practical guide on writing PRs that are easy to review. Covers small PRs, clear descriptions, and commit hygiene.
- Google's "Code Review Developer Guide" (google.github.io/eng-practices) — the actual internal guide Google uses for code reviews. The "What to look for in a code review" section is gold.
- "The Checklist Manifesto" by Atul Gawande — not about code, but about why checklists work in high-stakes fields (surgery, aviation). Changes how you see pre-ship checklists.
- "On Writing Software Well" by DHH (YouTube playlist) — short screencasts where he walks through real Rails code explaining design choices. Great for seeing how an experienced dev thinks out loud while building.

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

### Error Handling

| Good | Bad |
|------|-----|
| Errors are caught and handled with useful feedback | `try/catch` that swallows errors silently |
| User sees a helpful message when something fails | Raw stack trace or silent failure |
| Logging that helps you trace what happened | `console.log("here")` scattered everywhere |

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

**Resources to go deeper:**

- "Clean Code" by Robert C. Martin — the early chapters on naming and functions are useful. The later chapters get dogmatic and push over-abstraction, which contradicts the simplicity-first mindset of this playbook. Take what's practical, leave the rest.
- "Naming Things in Code" by CodeAesthetic (YouTube, ~8 min) — short video that clicks immediately. You'll start seeing bad naming everywhere after this.
- "The Wrong Abstraction" by Sandi Metz (sandimetz.com) — a short post that makes the case: duplication is far cheaper than the wrong abstraction. Read this before you refactor anything.
- Cal.com GitHub repo (github.com/calcom/cal.com) — a well-structured open-source Next.js app. Good example of folder structure, separation of concerns, and how a real product codebase looks. Browse, don't study — let the patterns sink in.
- Bulletproof React (github.com/alan2207/bulletproof-react) — an opinionated guide to React project architecture. Excellent for understanding how to organize files, separate features, and structure a frontend codebase. Very practical.

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

**Resources to go deeper:**

- "Thinking in Bets" by Annie Duke — you already have this in your vault. Re-read with engineering trade-offs in mind. Every architecture choice is a bet under uncertainty.
- "Choose Boring Technology" by Dan McKinley (boringtechnology.club) — a famous talk/essay about why you should default to proven, boring tools. Every new technology has a cost. You get a limited number of "innovation tokens."
- "The Thirty Percent Rule" by Kris Brandow — the idea that if you're spending more than 30% of your time on tech debt, something is wrong. If you're spending 0%, something is also wrong.
- "Accelerate" by Nicole Forsgren — research-backed book on what actually makes engineering teams fast. Useful for understanding why deployment speed and code quality aren't opposites.

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

**Codebases worth reading (start with one, browse don't study):**

- **Cal.com** (github.com/calcom/cal.com) — Next.js, well-structured, real product. Great for seeing how features are organized.
- **Bulletproof React** (github.com/alan2207/bulletproof-react) — not a product, but an architecture reference. Shows how to structure a React app the "right" way.
- **Shadcn/ui** (github.com/shadcn-ui/ui) — beautifully written component library. Great for seeing how small, focused, reusable code looks.
- **T3 Stack** (create.t3.gg) — full-stack TypeScript template. Good for understanding how auth, database, API, and frontend connect in a modern stack.

**People worth following (blogs/YouTube):**

- **Dan Abramov** (overreacted.io) — React core team, writes about fundamentals in a way that clicks
- **Kent C. Dodds** (kentcdodds.com) — testing, React patterns, practical engineering advice
- **Theo Browne** (t3.gg / YouTube) — opinionated full-stack takes, explains trade-offs well
- **CodeAesthetic** (YouTube) — short, visual videos on code quality concepts. Perfect for your learning style as a designer.
- **Fireship** (YouTube) — fast, visual explainers of concepts and tools. Good for getting the big picture before going deep.
- **The Primeagen** (YouTube) — senior engineer who thinks out loud. Entertaining and educational.

---

## Part 6: Recommended Learning Path

A suggested progression — start wherever feels right, skip what you've already absorbed, revisit as you grow:

### Phase 1: Build the Eye (now)
You're already shipping code — so this isn't about stopping to read. It's about adding a judgment layer on top of what you're already doing.

- [ ] Read "A Philosophy of Software Design" (the whole book, it's short)
- [ ] Read "Goodbye, Clean Code" by Dan Abramov
- [ ] Read "The Grug Brained Developer"
- [ ] Watch "Naming Things in Code" by CodeAesthetic
- [ ] Browse Bulletproof React repo for 30 minutes — focus on the folder structure first, code second
- [ ] Read "Screaming Architecture" blog post (5 min read)
- [ ] Watch Theo Browne's "How to Structure Your React Project" (15 min)
- [ ] On your next feature, use the "While Building" checklist and write down what you notice
- [ ] On your next new project, use the Part 0 scaffolding checklist before writing any code
- [ ] Write a CLAUDE.md for your current project (use the template in Part 0)
- [ ] Read the Claude Code docs on CLAUDE.md

### Phase 2: Understand the System (next)
Once you can spot good code, zoom out to understand how pieces connect.

- [ ] Watch "Simple Made Easy" by Rich Hickey
- [ ] Read "Choose Boring Technology"
- [ ] Browse Cal.com repo — trace one feature from UI to API to database
- [ ] Read Google's Code Review guide
- [ ] Start writing one-line "why" comments in your own PRs
- [ ] Set up a Claude Code hook that runs your linter on file edits

### Phase 3: Build the Muscle (ongoing)
This is where judgment becomes instinct.

- [ ] After every feature you ship, fill in the Learnings Log below
- [ ] Review your own PRs before requesting review — run through the "Before Shipping" checklist
- [ ] Pick one open-source repo and follow their PRs for a week
- [ ] Read "The Wrong Abstraction" by Sandi Metz before your next refactor
- [ ] Start keeping a DECISIONS.md in your project repos
- [ ] Create custom Claude Code skills for tasks you repeat often (deploy, test, etc.)

---

## My Learnings Log

> When something clicks or breaks while building, log it here. Tell Claude Code "log this learning" and it adds an entry.
> Format: `### YYYY-MM-DD — [tag] Short context` followed by the insight in 1-3 sentences. Newest first.
> Tags: `[structure]` `[debugging]` `[tradeoff]` `[naming]` `[patterns]` `[git]` `[testing]` `[communication]` `[simplicity]` `[review]` or whatever fits.
> When this section gets long, split it into its own `[[Engineering Learnings Log]]` file.

---

*No entries yet. First one gets added the next time something clicks or breaks.*

---

*Come back to this often. The questions won't change — but the ability to answer them gets sharper every time I build something real.*

---

*Resources last reviewed: 2026-03-22. Principles are timeless. Resources, tools, and people recommendations may age — revisit when something feels outdated.*
