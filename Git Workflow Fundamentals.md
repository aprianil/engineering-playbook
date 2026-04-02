# Git Workflow Fundamentals

> A practical guide to commits, branches, and PRs — the mechanics of shipping code as a team.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [[Engineering Learnings & Playbook]] system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## Why Git Matters Beyond "Saving Your Work"

Git isn't just version control. It's a **communication tool**. Your commits tell a story. Your branches organize work. Your PRs start conversations. When used well, git makes collaboration smooth. When used poorly, it creates confusion, lost work, and fear of deploying.

---

## Commits: The Building Blocks

A commit is a snapshot of your changes with a message explaining why. Good commits make everything else easier — reviewing, debugging, reverting.

### What Makes a Good Commit

```
Good commit:
- Does one thing
- Has a clear message that explains WHY, not just WHAT
- Can be understood without reading the code
- Could be reverted on its own without breaking other things

Bad commit:
- "fix stuff"
- "WIP"
- Changes 15 unrelated things at once
- "oops" followed by "fix oops"
```

### Writing Commit Messages

```
Format:
[short summary of what and why — under 72 characters]

[optional longer explanation if needed]

Examples:
"Add input validation to billing form to prevent empty submissions"
"Fix redirect loop on login page when session is expired"
"Split UserProfile into separate components for readability"

Not helpful:
"update code"
"fix bug"
"changes"
"asdf"
```

The summary should tell someone scanning `git log` what happened and why — without opening the diff.

### How Often to Commit

```
- Commit when you've completed one logical step
- Don't wait until everything is done
- Don't commit every single line change either
- Think of it like saving chapters, not saving every sentence
```

---

## Branches: Organizing Work

Branches let you work on something without affecting the main codebase until you're ready.

### The Basics

```
main (or master)
  └── your-feature-branch
        └── your changes live here until merged
```

- `main` is the source of truth — what's deployed or ready to deploy
- Feature branches are where you do your work
- When your work is done and reviewed, it gets merged into main

### Branch Naming

Pick a convention and stick with it. Common patterns:

```
feature/billing-page
fix/login-redirect-loop
chore/update-dependencies
refactor/split-user-profile
```

The prefix tells you the type of work. The rest tells you what it's about. Anyone scanning the branch list immediately knows what's happening.

### Branch Hygiene

```
- Create a new branch for each piece of work
- Keep branches short-lived — days, not weeks
- Delete branches after they're merged
- Pull from main regularly to avoid big merge conflicts later
- Don't work directly on main
```

---

## Pull Requests: The Conversation

A PR is not just "please merge my code." It's a request for feedback, a record of decisions, and a teaching moment.

### What Makes a Good PR

```
- Small and focused — one feature, one fix, one change
- Has a clear description: what changed, why, how to test it
- Includes screenshots for UI changes
- Links to the related issue or ticket if there is one
- The commit history tells a readable story
```

### PR Description Template

```markdown
## What
[One sentence: what does this PR do?]

## Why
[Why is this change needed? What problem does it solve?]

## How to test
[Steps someone can follow to verify this works]

## Screenshots (if UI change)
[Before/after if applicable]

## Notes
[Anything the reviewer should know — trade-offs, things to watch for, follow-up work]
```

### Small PRs Win

| Small PR | Big PR |
|----------|--------|
| Easy to review — reviewer stays focused | Reviewer gets overwhelmed, skims, misses issues |
| Easy to revert if something breaks | Reverting means losing everything, even the good parts |
| Merges cleanly, fewer conflicts | High chance of merge conflicts |
| Ships faster — less back and forth | Sits open for days waiting for review |

If your PR touches more than 10-15 files, ask yourself: can this be split?

---

## Common Git Commands You'll Actually Use

### Daily Workflow
```bash
git status                    — what's changed?
git add [file]                — stage specific files for commit
git commit -m "message"       — commit staged changes
git push                      — push your branch to remote
git pull                      — get latest changes from remote
```

### Branching
```bash
git checkout -b feature/name  — create and switch to new branch
git checkout main             — switch back to main
git merge main                — merge main into your current branch
git branch -d feature/name    — delete a branch after merge
```

### Investigating
```bash
git log --oneline -20         — see recent commits (compact)
git diff                      — see unstaged changes
git diff --staged             — see staged changes (about to commit)
git blame path/to/file        — see who changed each line and when
git stash                     — temporarily shelve changes
git stash pop                 — bring shelved changes back
```

### Undoing Things
```bash
git checkout -- [file]        — discard unstaged changes in a file
git reset HEAD [file]         — unstage a file (keep the changes)
git revert [commit]           — create a new commit that undoes a previous one
                                (safe — doesn't rewrite history)
```

A note on destructive commands: `git reset --hard`, `git push --force`, and `git clean -f` can permanently lose work. Understand what they do before using them. When in doubt, ask.

---

## The Workflow in Practice

```
1. Pull latest main
2. Create a branch from main
3. Do your work — commit as you go in logical steps
4. Push your branch
5. Open a PR with a clear description
6. Address review feedback — push new commits
7. Merge when approved
8. Delete the branch
9. Pull latest main — start again
```

---

## Merge Conflicts

Conflicts happen when two people change the same part of a file. They look scary but they're usually straightforward.

```
<<<<<<< HEAD (your changes)
const title = "Dashboard"
=======
const title = "Home"
>>>>>>> main (their changes)
```

To resolve:
1. Read both versions — understand what each person intended
2. Decide which to keep (or combine both)
3. Remove the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
4. Test that it works
5. Commit the resolution

To avoid conflicts:
- Pull from main often
- Keep branches short-lived
- Communicate with your team about who's working where

---

## Resources

- "Git Immersion" (gitimmersion.com) — hands-on, step-by-step git tutorial. Good for building comfort with the commands.
- "Oh Shit, Git!?" (ohshitgit.com) — plain-English solutions for common git mistakes. Bookmark this for when things go wrong.
- "How to Write a Git Commit Message" by Chris Beams (cbbeams.com) — the definitive post on commit message conventions. Short and practical.
- Atlassian Git Tutorials (atlassian.com/git/tutorials) — well-written visual guides for branching, merging, and workflows.
- "Git Flight Rules" (github.com/k88hudson/git-flight-rules) — a comprehensive FAQ for "I did X, how do I fix it?" Useful as a reference.

---

*Git is the language teams use to coordinate their work. Learn it well enough that it disappears — you think about your changes, not the commands.*
