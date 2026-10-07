# Git Workflow Fundamentals

> A practical guide to commits, branches, and PRs: the mechanics of shipping code as a team.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [[Engineering Learnings & Playbook]] system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook, so don't duplicate what's already there.

---

## Why Git Matters Beyond "Saving Your Work"

Git isn't just version control. It's a **communication tool**. Your commits tell a story. Your branches organize work. Your PRs start conversations. When used well, git makes collaboration smooth. When used poorly, it creates confusion, lost work, and fear of deploying.

---

## Commits: The Building Blocks

A commit is a snapshot of your changes with a message explaining why. Good commits make everything else easier: reviewing, debugging, reverting.

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
[short summary of what and why, aim for 50 characters, 72 max]

[optional longer explanation if needed, wrapped at 72 characters]

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

The summary should tell someone scanning `git log` what happened and why, without opening the diff.

### How Often to Commit

```
- Commit when you've completed one logical step
- Don't wait until everything is done
- Don't commit every single line change either
- Think of it like saving chapters, not saving every sentence
- When building in slices: each slice's last commit must build and
  pass tests on its own, so the PR can be bisected and reverted
  slice by slice
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

- `main` is the source of truth: what's deployed or ready to deploy
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
- Keep branches short-lived: days, not weeks
- Delete branches after they're merged
- Pull from main regularly to avoid big merge conflicts later
- Don't work directly on main
```

---

## Pull Requests: The Conversation

A PR is not just "please merge my code." It's a request for feedback, a record of decisions, and a teaching moment.

### What Makes a Good PR

```
- Focused: one feature, one fix, or one change
- Has a clear description: what changed, why, how to test it
- Includes screenshots for UI changes
- Links to the related issue or ticket if there is one
- The commit history tells a readable story (one commit per slice)
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
[Anything the reviewer should know: trade-offs, things to watch for, follow-up work]
```

### Small Commits Win (the PR Can Be Big)

The old rule was "keep PRs small." With agents building a whole feature in one session, the unit that matters is the commit. `/eng-build` ships one spec as one PR, built slice by slice, and each slice is one green commit that builds and passes tests on its own.

| Green slice commits | One big blob of changes |
|----------|--------|
| Easy to review: the reviewer reads one slice at a time | Reviewer gets overwhelmed, skims, misses issues |
| Easy to revert: undo one slice, keep the rest | Reverting means losing everything, even the good parts |
| Easy to bisect: every commit builds and passes | A broken middle commit hides where the bug came in |

A large PR is fine when it has a slice map in the description (one line per slice: name, commit range, where the risk sits) and green per-slice commits. A large PR with neither is the one to push back on.

Some changes still get their own PR, however small. `/eng-build` stops and asks when a build hits one of these:
- A schema migration with backfill, or any destructive or irreversible data change
- A change to the auth, payments, or publish/deploy mechanism itself (code that only *uses* them is fine)
- An acceptance criterion that depends on a post-deploy action
- A cross-repo change
- A refactor riding along with the feature
- A change to something someone is actively running, where the restart or deploy is its own gate

---

## Common Git Commands You'll Actually Use

### Daily Workflow
```bash
git status                    # what's changed?
git add [file]                # stage specific files for commit
git commit -m "message"       # commit staged changes
git push                      # push your branch to remote
git pull                      # get latest changes from remote
```

### Branching
```bash
git switch -c feature/name    # create and switch to new branch
git switch main               # switch back to main
git merge main                # merge main into your current branch
git branch -d feature/name    # delete a branch after merge
```

### Working in Parallel
```bash
git worktree add -b feature/billing ../app-billing   # new folder, new branch, same repo
git worktree list                                    # see every worktree
git worktree remove ../app-billing                   # clean up after merge
```

A worktree is a second checkout of the same repo in its own folder, on its own branch. This is how parallel agents avoid colliding: each one works in its own worktree, so two agents never edit the same files on disk or fight over which branch is checked out.

### Investigating
```bash
git log --oneline -20         # see recent commits (compact)
git diff                      # see unstaged changes
git diff --staged             # see staged changes (about to commit)
git blame path/to/file        # see who changed each line and when
git stash                     # temporarily shelve changes
git stash pop                 # bring shelved changes back
```

### Undoing Things
```bash
git restore [file]            # discard unstaged changes in a file
git restore --staged [file]   # unstage a file (keep the changes)
git revert [commit]           # create a new commit that undoes a previous one
                              # (safe, doesn't rewrite history)
```

A note on destructive commands: `git reset --hard`, `git push --force`, and `git clean -f` can permanently lose work. Understand what they do before using them. When in doubt, ask.

---

## The Workflow in Practice

```
1. Pull latest main
2. Create a branch from main
3. Do your work, commit as you go in logical steps
4. Push your branch
5. Open a PR with a clear description
6. Address review feedback, push new commits
7. Merge when approved: gh pr merge --rebase, so each slice commit
   survives on main (squash collapses them and loses per-slice revert)
8. Delete the branch
9. Pull latest main, start again
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
1. Read both versions. Understand what each person intended
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

- "Git Immersion" (gitimmersion.com): hands-on, step-by-step git tutorial. Good for building comfort with the commands.
- "Oh Shit, Git!?" (ohshitgit.com): plain-English solutions for common git mistakes. Bookmark this for when things go wrong.
- "How to Write a Git Commit Message" by Chris Beams (cbea.ms/git-commit): the definitive post on commit message conventions. Seven rules, including a 50-character subject and a body wrapped at 72. Short and practical.
- Atlassian Git Tutorials (atlassian.com/git/tutorials): well-written visual guides for branching, merging, and workflows.
- "Git Flight Rules" (github.com/k88hudson/git-flight-rules): a comprehensive FAQ for "I did X, how do I fix it?" Useful as a reference.

---

*Git is the language teams use to coordinate their work. Learn it well enough that it disappears. You think about your changes, not the commands.*
