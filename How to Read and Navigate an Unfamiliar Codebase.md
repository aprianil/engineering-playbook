# How to Read and Navigate an Unfamiliar Codebase

> A field guide for opening a project you didn't build and finding your way around — without reading every file.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [[Engineering Learnings & Playbook]] system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## The Problem

You open a project. There are dozens of folders, hundreds of files. You didn't write any of it. Where do you even start?

Most people start reading from the top — file by file, folder by folder. This is the worst approach. You'll drown in details before you understand the shape of the thing.

Senior engineers don't read codebases. They **navigate** them. They look for landmarks, trace paths, and build a mental map from the outside in.

---

## Step 1: Get the Big Picture (5 minutes)

Before opening any code file, orient yourself.

```
- Read the README (if it exists)
- Read the CLAUDE.md (if it exists) — this is the fastest briefing
- Look at the folder structure — just the top level
  Ask: does this scream the product or the framework?
- Check package.json (or equivalent) — what dependencies are used?
  This tells you the tech stack faster than any doc
- Look at the scripts section — what commands exist?
  (dev, build, test, deploy — each one tells you something)
```

At this point you should know: what the project is, what it's built with, and roughly how it's organized. You haven't read a single line of code yet. That's the point.

---

## Step 2: Find the Entry Points (10 minutes)

Every app has a front door. Find it.

**For a web app (Next.js, React, etc.):**
- Look at the routing — `app/` directory, `pages/` directory, or router config
- Routes tell you what the app *does* — each route is a feature or page
- Find the main layout or root component — this wraps everything

**For an API:**
- Look at the route definitions — usually in a `routes/` folder or a main server file
- Each route is an endpoint — this is the API's surface area
- Find the middleware — this shows you what happens to every request (auth, logging, etc.)

**For any project:**
- Find where the app starts — `index.ts`, `main.ts`, `app.ts`, or whatever the entry point is
- Trace from there: what does it load? What does it connect to?

```
The entry points are your map legend. Everything else connects back to them.
```

---

## Step 3: Trace One Feature End-to-End (20 minutes)

Pick one feature — the simplest one you can find. Then trace it from the surface to the bottom.

**The trace path for a web feature:**
```
1. Find the page/route for the feature
2. What components does it render?
3. Where does the data come from? (API call, database query, props)
4. Follow the data — where is the API endpoint?
5. What does the endpoint do? (validate, query, transform, return)
6. Where does it touch the database? What tables/models?
7. Follow the response back to the UI — how is it rendered?
```

After tracing one feature, you understand the pattern the codebase uses. Most codebases are consistent — once you see how one feature works, you can predict how the others work.

---

## Step 4: Identify the Patterns (ongoing)

As you navigate, look for:

```
- How is state managed? (local state, context, store, server state)
- How are API calls made? (fetch, axios, tRPC, server actions)
- How is auth handled? (middleware, HOC, hooks)
- How are errors handled? (try/catch, error boundaries, global handler)
- How are files named? (conventions tell you where to find things)
- Is there a shared/common folder? What lives there?
```

You don't need to memorize these. Just notice them. Pattern recognition builds over time.

---

## Step 5: Use Your Tools

You don't have to read files top to bottom. Use search.

**In Claude Code:**
- Ask "what does this file do?" — let AI summarize instead of reading every line
- Ask "trace the flow from [this component] to the database"
- Ask "what files are related to [feature name]?"

**In your editor:**
- `Cmd+Shift+F` — search across the entire project
- `Cmd+Click` — jump to where a function/component is defined
- File tree — collapse everything, then expand only what you need

**In the terminal:**
- `git log --oneline -20` — see recent changes, understand what's active
- `git log --oneline -- path/to/file` — see the history of a specific file

---

## The "3-Layer" Mental Model

When navigating any codebase, think in three layers:

| Layer | What to look for | Example |
|-------|-----------------|---------|
| **Surface** | What the user sees and interacts with | Pages, components, forms, buttons |
| **Logic** | What processes the user's actions | API routes, hooks, server actions, validation |
| **Data** | Where information lives and how it's shaped | Database tables, models, schemas, types |

Every feature touches all three layers. When you're lost, ask: which layer am I in? What's above me? What's below me?

---

## Common Mistakes When Reading Code

| Mistake | Instead |
|---------|---------|
| Reading every file from top to bottom | Navigate by tracing features, not scanning files |
| Starting with utility files or configs | Start with entry points and routes |
| Trying to understand everything at once | Understand one feature deeply, then expand |
| Reading code without running it | Run the app first — click around, see what it does |
| Ignoring git history | `git log` and `git blame` tell you *why* code exists |

---

## Resources

- "How to Read Code" by Max Kanat-Alexander — a practical approach to reading unfamiliar code, focused on navigating rather than memorizing
- "Code Reading" (wiki.c2.com) — classic collection of wisdom on how experienced developers read code
- "How to quickly and effectively read other people's code" by Aria Stewart — focused on the mental techniques for building understanding fast
- "Navigating a Codebase" section in Bulletproof React (github.com/alan2207/bulletproof-react) — seeing a well-organized codebase helps you recognize structure in messier ones

---

*The goal isn't to understand everything. It's to build a mental map good enough to find what you need, when you need it.*
