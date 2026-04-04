# Working Effectively With AI

> A deep dive from the [Engineering Learnings & Playbook](Engineering%20Learnings%20%26%20Playbook.md). How to work with AI coding tools — and how to evolve your approach as models get more capable.

---

## The Core Mental Model

AI is a multiplier, not a replacement. It multiplies what you already know — your engineering judgment, your understanding of the problem, your taste. Good judgment in, good code out.

**You own the what and the why. The model figures out the how.** Your job is to set the goal, provide the right context and tools, define what "done" looks like, and judge the result. The model's job is to get there — and increasingly, it's better at choosing its own path than following yours.

This mental model should evolve as models do. The less you need to choreograph, the more you should focus on being clear about the outcome. Don't hold onto scaffolding that models have outgrown.

---

## Context Engineering

The quality of AI output is directly tied to the quality of context it can access. This isn't just about prompting — it's about how you structure your project and what tools you give the model.

### Project Structure = AI Context

Your folder structure controls what AI reads into its context window. This affects every suggestion it makes.

- **Feature-based folders** → AI opens one folder, gets the full picture. Minimal noise.
- **Type-based folders** (components/, hooks/, utils/) → AI hunts across folders, loads more files, pieces things together. More noise, worse output.
- **Feature isolation** (features can't import from each other) → AI edits to one feature can't accidentally break another. The boundaries that protect humans protect AI too.
- **Good naming** → AI doesn't have to read the body to understand what something does. `create-discussion.tsx` vs `utils2.tsx`. Less guessing = less hallucination.
- **Locality of Behavior** → When AI reads a file with good locality, it gets the full picture in one read. Scattered code means more files loaded, more noise.

One-liner: the same things that make code maintainable for humans make it navigable for AI.

### CLAUDE.md / Rules Files

A rules file (CLAUDE.md, guidelines.md, agent.md — depends on the tool) is the single highest-leverage thing you can set up. AI reads it at the start of every session. Think of it as onboarding documentation for AI.

What to include:
- What the project is and who it's for
- Tech stack
- Project structure and conventions
- Important commands (dev, build, test)
- What to watch out for (gotchas, quirks)

Write it once, benefit every session. See Part 0 of the playbook for the template.

### Give Tools, Not Answers

Instead of pasting documentation into prompts, give the model a way to fetch what it needs. Instead of describing your database schema, give it access to query it. Instead of explaining what the UI looks like, give it a browser tool.

- **Documentation pointers** in CLAUDE.md (URLs the model can fetch when needed) beat pasted docs that fill the context window
- **MCPs** (Model Context Protocol) extend what the model can see and do — browser tools, dev tools, database access, doc fetchers
- **File access** — a well-structured codebase the model can explore is better than a long description of the codebase

The principle: the model should be able to get the context it needs, when it needs it. Don't try to front-load everything. Give it tools to discover.

---

## Communicating Intent

### Goal + Constraints > Step-by-Step Instructions

Give the model a clear goal and the constraints it should respect. Let it figure out the path.

**What works:**
- A clear description of the outcome you want
- Constraints that matter (what not to break, what conventions to follow, what's out of scope)
- Acceptance criteria — how you'll know it's done
- Access to the codebase, docs, and tools it needs

**What you can let go of:**
- Prescribing the exact execution order
- Breaking the task into micro-steps for the model (break it down for *your* thinking, but you don't need to hand-feed each step)
- Over-specifying implementation details the model can figure out from context

The difference between "AI is useless" and "AI is incredible" is still about how well you communicate — but the communication is shifting from "how to do it" to "what done looks like."

### Decomposition Is a Thinking Tool, Not an AI Limitation

Breaking problems down is fundamental engineering. If you can't decompose a task, you don't understand it well enough. That hasn't changed.

What's changed: you don't need to spoon-feed each piece to the model sequentially. Decompose to sharpen *your* thinking, then give the model the full picture and let it execute. The model can handle more than you think — and the gap between what it can handle now vs six months ago is large.

---

## Verification

The model should always have a way to prove its work. This is timeless — it doesn't change as models improve.

- **Tests** — generate them or write them, then make sure they pass
- **Running the app** — browser, preview, dev server
- **CLI commands** — build, lint, type check
- **CI/CD pipelines** — automated verification on push
- **Visual verification** — browser tools (Playwright, etc.) catch what code-level tests miss, especially for front-end work

If the model generates the tests, verify the tests too. Trust but verify.

---

## The Bitter Lesson Applied

Rich Sutton's Bitter Lesson: general methods that leverage computation always win over hand-engineered solutions. Applied to working with AI:

- **Don't over-orchestrate.** Fancy multi-step workflows with strict sequencing almost always lose to giving the model the goal and letting it work. A year ago you needed the scaffolding. Now you mostly don't.
- **Invest in context, not choreography.** A good CLAUDE.md, a clean project structure, and the right tools will outlast any clever prompting technique. Models change fast — your project structure and principles don't.
- **Let go of what models outgrow.** If you're still doing something because "that's how you work with AI," test whether it's still necessary. The model from six months ago is not the model you're using today.
- **The general approach wins.** Clear goals, good tools, clean context, strong verification. This works regardless of which model or which tool. Specific prompting tricks are brittle and expire.

---

## The Bottom Line

Every principle that makes you a better engineer also makes you better at working with AI:

- Clear thinking → clear goals for the model
- Understanding the problem → knowing what "done" looks like
- Good project structure → clean context the model can navigate
- Writing conventions down → rules files that persist across sessions
- Verifying your work → verification the model can run itself

The shift over time: less "how to instruct AI" and more "how to set up an environment where AI can do great work." Think less about the prompt, more about the project.

---

*This note evolves as models do. The principles (clarity, verification, good structure) are timeless. The specific techniques should be revisited when your current approach starts feeling like unnecessary scaffolding.*
