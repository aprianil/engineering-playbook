# Working Effectively With AI

> A deep dive from the [[Engineering Learnings & Playbook]]. How to communicate with AI coding tools so they produce code you'd actually write yourself.

---

## The Core Mental Model

AI is a multiplier, not a replacement. It multiplies what you already know — your engineering judgment, your understanding of the problem, your habits. Good habits in, good code out. Bad habits in, bad code out faster.

**You are the architect. AI is the builder.** You think, you set context, you direct, you judge. AI types.

---

## Context Engineering

The quality of AI output is directly tied to the quality of context you give it. This isn't just about prompting — it's about how you structure your entire project.

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

---

## Prompting for Code

### The 3-Section Pattern

A reliable structure for any coding task:

**1. Task** — What to build. Be technically specific. Include the exact behavior, not just the feature name. Information that only a programmer would know: tech stack, how things should connect, terminal commands.

**2. Background** — Supporting context. Documentation links, relevant files, screenshots of how you want it to look, reference implementations. The more AI knows about your intent, the less it guesses.

**3. Do not** — Constraints and boundaries. What AI shouldn't touch, shouldn't change, shouldn't modify. This is surprisingly effective at reducing slop.

### Why Specificity Matters

When AI has to guess architecture, tech stack, or implementation details, you get:
- Code that looks good at first glance but is poorly structured underneath
- Styling and features that don't match your intent
- More errors, more debugging, more wasted time

When you provide full technical context:
- Code that runs first try
- Code that matches what you'd write yourself
- Less back-and-forth fixing

The difference between "AI is useless" and "AI is incredible" is often not the AI — it's how well you communicate what you want.

### Break Big Tasks Into Small Ones

AI is good at small, scoped tasks. It struggles with big, complex ones. So break it down:

1. Understand the problem
2. Plan the solution (you do this, not AI)
3. Break it into small, independent tasks
4. Give each task to AI with full context

If you can't break it down, you don't understand the problem well enough yet. This isn't an AI trick — it's fundamental engineering. The only difference is whether you type the solution or AI does.

---

## Verification

AI should never just write code. It needs a way to prove the code works:

- **Tests** — generate them or write them, then make sure they pass
- **Running the app** — browser, preview, dev server
- **CLI commands** — build, lint, type check
- **CI/CD pipelines** — automated verification on push

If you let AI generate the verification (tests, etc.), verify the verification. Don't trust AI to check its own homework without oversight.

For front-end and design tasks, visual verification tools (browser MCPs, screenshot comparison) help catch what tests miss.

---

## MCPs (Model Context Protocol)

MCPs are tools that extend what AI can do. Find the ones that match your stack:

- **Documentation fetchers** (e.g., Context7) — AI grabs docs automatically instead of you pasting them
- **Dev tools access** (e.g., Chrome DevTools MCP) — AI can see console errors, network requests, layout shifts
- **Framework-specific tools** (e.g., Next.js dev tools MCP) — AI gets build errors, project state, metadata

The point isn't specific tools — it's that these exist and the right combination makes a big difference for your workflow.

---

## The Bottom Line

Every principle that makes you a better engineer also makes you better at working with AI:

- Being specific → better prompts
- Breaking down problems → scoped AI tasks
- Setting constraints → the "do not" section
- Writing documentation → rules files
- Verifying your work → AI verification
- Good project structure → clean AI context

AI doesn't replace engineering skills. It amplifies them. Build the skills first — AI makes them go further.

---

*This note consolidates learnings from the playbook's logs on context engineering, Bulletproof React's architecture, and practical AI prompting patterns. Come back to this when starting a new project or when AI output quality drops.*
