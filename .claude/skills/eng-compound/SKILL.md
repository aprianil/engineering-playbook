---
name: eng-compound
description: Capture non-obvious solutions so the team never solves the same problem twice. Run after a build or debug session where something surprising was learned.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
argument-hint: [optional: description of what was learned]
---

Capture a non-obvious solution so the team never pays the same debugging cost twice. Without this step, AI-assisted engineering is amnesiac -- every session is equally fast, but no session is faster than the last. This is what makes cycle N+1 faster than cycle N.

**When to run:**
- After `/eng-build` or `/eng-check` when something unexpected came up
- After a debugging session that took real effort to resolve
- When a teammate asks "did we hit this before?" and the answer is yes but undocumented

**When NOT to run:**
- The fix is obvious from the code and commit message -- `git blame` has it
- It's a project convention -- belongs in CLAUDE.md
- It's a timeless principle or mindset shift -- belongs in the playbook's learnings log

**The filter: would a teammate's AI session benefit from knowing this before hitting the same problem?** If yes, capture it. If no, skip.

## Capture

**1. Understand what was learned.**

If the user provided a description, start from that. If not, gather evidence:
- Check `git log --oneline -10` and `git diff HEAD~1` for recent changes
- Look at recent spec files in `specs/` for context on what was being built
- Ask the user what was surprising or hard

Ask the user to confirm what the core learning is. Don't over-extract. One solution doc per distinct problem. If the session surfaced multiple learnings, run this skill once per learning.

**2. Check for existing solutions.**

Search `docs/solutions/` in the current project for overlapping topics. Use Grep to search by keywords from the problem domain. If a related doc exists, update it rather than creating a duplicate.

**3. Write the solution doc.**

Save to `docs/solutions/[descriptive-name].md` (kebab-case, create the directory if needed).

Format:

```markdown
---
title: [descriptive title -- scannable, specific]
date: [YYYY-MM-DD]
tags: [relevant technology, pattern, or domain tags]
---

## Problem

What went wrong or what was non-obvious. Enough context that someone encountering the same symptoms would recognize this is their problem.

## Why it's hard to find

Why this isn't obvious from reading the code, docs, or error messages. This is what makes it worth documenting -- if it were googleable, you wouldn't need this doc.

## Solution

What fixed it and why. Include code snippets or file references when they help. Be specific enough to act on, concise enough to scan.

## Context

- Which project or feature surfaced this
- What stack/tools are involved
- Any conditions that must be true for this to apply
```

Keep it short. A good solution doc is 20-40 lines. If it's longer, you're explaining too much context or combining multiple problems.

**4. Assess transferability.**

Ask the user: "Is this specific to this project, or would it apply to any project using [relevant stack/tool]?"

- **Project-specific** -- stays in `docs/solutions/`. Done.
- **Transferable** -- also flag it for the engineering playbook. Add a note at the bottom: `> Transferable: candidate for engineering-playbook deep dive on [topic]`. The user decides when to promote it -- this skill doesn't write to the playbook directly.

**5. Make it discoverable.**

Check the project's CLAUDE.md. If there's no mention of `docs/solutions/`, add a one-liner to the appropriate section:

```markdown
## Knowledge base
- `docs/solutions/` — non-obvious solutions from past sessions. Search here before debugging from scratch.
```

This ensures future AI sessions know the knowledge store exists.

## Rules

- One problem per doc. Don't bundle unrelated learnings.
- Update over duplicate. If a solution already exists for this area, extend it.
- Specific over generic. "DataForSEO batch endpoint drops requests above 15 concurrent calls" beats "be careful with API rate limits."
- The doc should be useful to someone who has never seen this codebase. Include enough context to recognize the problem, not so much that it reads like a novel.
- Don't capture what git already knows. The commit message + diff is the authoritative record of what changed. Solution docs capture the *why it was hard* and *what to watch for next time*.
