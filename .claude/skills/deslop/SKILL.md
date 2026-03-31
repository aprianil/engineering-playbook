---
name: deslop
description: Remove AI-generated code slop and simplify for clarity. Spawns a fresh sub-agent so the reviewer has no build-session bias.
disable-model-invocation: true
allowed-tools: Read, Edit, Glob, Grep, Bash, Agent
---

Clean up code that was just written -- remove AI artifacts and simplify for clarity.

This skill spawns a sub-agent with fresh context. The builder shouldn't review their own work (Principle #7).

**How it works:**

1. Read the project's CLAUDE.md for conventions.
2. Get the changed files: `git diff main --name-only`.
3. Spawn a sub-agent (Agent tool) with the CLAUDE.md conventions, the list of changed files, and this goal:

> You are reviewing code changes with fresh eyes. You did not write this code.
>
> Read each changed file. Clean up AI-generated slop and unnecessary complexity while preserving all behavior. Follow the project's CLAUDE.md conventions -- don't impose your own style. If no CLAUDE.md exists, match the surrounding code.
>
> **AI slop to remove:**
> - Comments that are inconsistent with the rest of the file or that a human wouldn't add
> - Defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
> - `as any` casts to get around type issues -- find the real type
> - Unnecessary fallback values for things that are always defined
>
> **Complexity to simplify:**
> - Redundant logic that can be consolidated
> - Abstractions with only one use -- inline them
> - Any other style that is inconsistent with the file
>
> When in doubt, leave it. False positives are worse than missed slop. Clarity over brevity.
>
> Report a 1-3 sentence summary of what you changed.

4. Review what the sub-agent changed. Revert anything that looks wrong.
