---
name: eng-compound
description: Capture non-obvious solutions so the team never solves the same problem twice. Automatically triggered via drafts from eng-check, or run standalone.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
argument-hint: [optional: description of what was learned]
---

Capture a non-obvious solution so the team never pays the same debugging cost twice. Without this step, AI-assisted engineering is amnesiac -- every session is equally fast, but no session is faster than the last. This is what makes cycle N+1 faster than cycle N.

## Two paths into this skill

**Path 1: From a draft (automatic loop)**

`/eng-check` writes drafts to `docs/solutions/.drafts/` when it spots something non-obvious during review. After the PR merges and a new session starts, a SessionStart hook detects the draft and tells Claude to run `/eng-compound`. This is the primary path -- no one has to remember anything.

When a draft exists:
1. Read the draft file
2. Look up the PR from the draft's `pr` field using `gh pr view [number] --json title,body,comments,reviews,files`
3. Combine the draft's signal with the full PR history -- review comments, requested changes, fixes, discussions
4. Write the complete solution doc (see format below)
5. Ask the user to confirm, edit, or discard
6. If confirmed, move from `.drafts/` to `docs/solutions/`. If discarded, delete the draft.

**Path 2: Standalone (manual)**

Run `/eng-compound` directly after any session where something non-obvious was learned -- debugging, production incidents, or a teammate asking "did we hit this before?"

When no draft exists:
1. If the user provided a description, start from that. If not, gather evidence:
   - Check `git log --oneline -10` and `git diff HEAD~1` for recent changes
   - Look at recent spec files in `specs/` for context on what was being built
   - Ask the user what was surprising or hard
2. Ask the user to confirm what the core learning is
3. Write the solution doc (see format below)

## When NOT to capture

- The fix is obvious from the code and commit message -- `git blame` has it
- It's a project convention -- belongs in CLAUDE.md
- It's a timeless principle or mindset shift -- belongs in the playbook's learnings log

**The filter: would a teammate's AI session benefit from knowing this before hitting the same problem?** If yes, capture it. If no, skip.

## Writing the solution doc

**First, check for existing solutions.** Search `docs/solutions/` for overlapping topics. Use Grep to search by keywords from the problem domain. If a related doc exists, update it rather than creating a duplicate.

Save to `docs/solutions/[descriptive-name].md` (kebab-case, create the directory if needed).

Format:

```markdown
---
title: [descriptive title -- scannable, specific]
date: [YYYY-MM-DD]
tags: [relevant technology, pattern, or domain tags]
pr: [PR number that surfaced this, if applicable]
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

Keep it short. A good solution doc is 20-40 lines.

## After writing

**Assess transferability.** Ask the user: "Is this specific to this project, or would it apply to any project using [relevant stack/tool]?"

- **Project-specific** -- stays in `docs/solutions/`. Done.
- **Transferable** -- add a note at the bottom: `> Transferable: candidate for engineering-playbook deep dive on [topic]`. The user decides when to promote it.

**Make it discoverable.** Check the project's CLAUDE.md. If there's no mention of `docs/solutions/`, add a one-liner:

```markdown
## Knowledge base
- `docs/solutions/` — non-obvious solutions from past sessions. Search here before debugging from scratch.
```

## Rules

- One problem per doc. Don't bundle unrelated learnings.
- Update over duplicate. If a solution already exists for this area, extend it.
- Specific over generic. "DataForSEO batch endpoint drops requests above 15 concurrent calls" beats "be careful with API rate limits."
- The doc should be useful to someone who has never seen this codebase.
- Don't capture what git already knows. Solution docs capture *why it was hard* and *what to watch for next time*.
