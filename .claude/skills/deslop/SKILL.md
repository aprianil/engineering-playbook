---
name: deslop
description: Remove AI-generated code slop and simplify for clarity. Use after generating new code, before a code review, or when asked to clean up unnecessary comments, defensive checks that can't fire, `as any` casts, deep nesting, single-use abstractions, or AI-sounding comments and docs. Spawns a fresh sub-agent for unbiased cleanup.
disable-model-invocation: false
allowed-tools: Read, Edit, Glob, Grep, Bash, Agent
---

Clean up code that was just written: remove AI artifacts and simplify for clarity.

This skill spawns a sub-agent with fresh context. The builder shouldn't review their own work (Principle #7).

**How it works:**

1. Read the project's CLAUDE.md for conventions.
2. Get the changed files: detect the base branch (`git symbolic-ref refs/remotes/origin/HEAD` or fall back to `main`/`master`), then diff against the merge base (`git diff $(git merge-base <base> HEAD) --name-only`). This ensures only changes on the current branch are reviewed.
3. Spawn a sub-agent (Agent tool) with the CLAUDE.md conventions, the list of changed files, and this goal:

> You are reviewing code changes with fresh eyes. You did not write this code.
>
> Read each changed file and its diff. Clean up AI-generated slop and unnecessary complexity introduced on this branch while preserving all behavior. Leave pre-existing code alone. Follow the project's CLAUDE.md conventions; don't impose your own style. If no CLAUDE.md exists, match the surrounding code.
>
> **AI slop to remove:**
> - Comments that are unnecessary, inconsistent with the rest of the file, or that a human wouldn't add
> - Defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
> - `as any` casts to get around type issues: find the real type
> - Unnecessary fallback values for things that are always defined
> - Type guards or null checks for values typed as required. If the type system says it's there, deleting the guard exposes the real bug, it doesn't create one
>
> **Complexity to simplify:**
> - Deeply nested code that reads better with early returns
> - Redundant logic that can be consolidated
> - Abstractions with only one use: inline them
> - Any other style that is inconsistent with the file
>
> **Prose slop in comments, docstrings, and markdown docs in the diff:**
> - Comments that name a feeling, not a mechanism ("keeps things robust", "for a seamless experience"). Rewrite to say what the code does or why, or cut it. If the comment could sit unchanged in any other project, cut it.
> - AI vocabulary and fancy verbs: crucial, delve, enhance, ensure, leverage, utilize, facilitate, robust, seamless, pivotal, comprehensive. "Serves as" becomes "is". Use the plain word.
> - Superficial -ing tails ("..., ensuring consistency", "..., improving performance"). Delete, or state the actual effect.
> - Abstract metaphor nouns: substrate, vector, primitive, surface, scaffolding, north star, flywheel. Pick the concrete word.
> - Filler and hedging: "in order to", "it is important to note that", "could potentially". Cut to the claim.
> - Chatbot leftovers and decorative emojis in comments, logs, or docs ("Now we...", "Let's...", "✅ Done!").
> - Em dashes and `--` used as dashes. Use a period or a comma.
> - Over-compressed comments that make the reader decode ("bad date → exit 2, no write"). Write a whole sentence, unless the file already uses that terse style.
>
> Leave string literals alone (error messages, log text, UI copy). Tests and callers may match on them. For markdown, follow any voice rules in CLAUDE.md over these.
>
> **Guardrails:**
> - Prefer minimal, focused edits over broad rewrites.
> - If you spot a real bug, report it with file:line. Don't fix it here.
> - When in doubt, leave it. False positives are worse than missed slop. Clarity over brevity.
>
> Report a 1-3 sentence summary of what you changed, plus any bugs you spotted.

4. Review what the sub-agent changed. Revert anything that looks wrong. Pass any reported bugs to whoever owns the fix.
