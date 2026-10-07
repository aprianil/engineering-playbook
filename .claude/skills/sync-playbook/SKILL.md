---
name: sync-playbook
description: Sync the engineering playbook, deep dives, and skills from Obsidian and ~/.claude/skills/ to the engineering-playbook GitHub repo. Updates README if needed.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
metadata:
  internal: true
---

Sync the playbook, deep dives, and skills to the `engineering-playbook` GitHub repo.

## Sources of truth

- **Skills:** `~/.claude/skills/` is canonical. If you've been editing skill files in a project-local `.claude/skills/` (e.g. the mirror at `Developer/engineering-playbook/`), copy those edits into `~/.claude/skills/` FIRST. This skill blindly pushes whatever lives in the canonical source, and silent downgrades are how regressions land on main.
- **Playbook and deep dives:** the Obsidian vault at `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Apri/`.

## Steps

### 1. Freshen the working clone

Always reset `/tmp/engineering-playbook` to `origin/main`. Never reuse stale state from a previous run.

```bash
REPO=/tmp/engineering-playbook
if [ -d "$REPO/.git" ]; then
  cd "$REPO" && git fetch origin && git reset --hard origin/main && git clean -fd
else
  git clone git@github.com:aprianil/engineering-playbook.git "$REPO"
fi
```

### 2. Copy the playbook and deep dives

Read `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Apri/Engineering Learnings & Playbook.md` and enumerate every file in the "Deep dives (linked notes)" table near the top.

Copy the playbook file and every deep dive `.md` into `/tmp/engineering-playbook/` (flat structure, no subfolders). If a deep dive listed in the playbook doesn't exist in the vault, stop and tell the user which one is missing. Don't silently skip.

### 3. Copy skills with rsync (allowlist)

```bash
SKILLS="deslop eng-build eng-check eng-init eng-spec sync-playbook"
for S in $SKILLS; do
  rsync -a --delete "$HOME/.claude/skills/$S/" "/tmp/engineering-playbook/.claude/skills/$S/"
done
```

The trailing slash on each source is mandatory. It copies the skill's *contents*, not the directory itself. `--delete` keeps each skill's files exactly matching the canonical source.

**The repo ships engineering-process skills only, so this is an allowlist.** `~/.claude/skills/` also holds personal and domain skills (desktop and browser control, basecamp, design skills, symlinked tools) that don't belong in the public playbook, which is scoped to the engineering learning arc (plan, build, review, learn). A blocklist silently publishes every new personal skill; an allowlist can only miss one. When a new engineering skill should ship, add it to `SKILLS` here and to the README skills table. When one is retired, remove it from `SKILLS` and `git rm` its directory in the repo.

Do not use `cp -r ~/.claude/skills/<skill> .claude/skills/<skill>`. That pattern creates nested directories like `.claude/skills/eng-build/eng-build/` and was the source of a previous bug that required a cleanup commit to remove.

### 4. Update README if needed

Read `/tmp/engineering-playbook/README.md` and update:

- **Deep dives section:** add any deep dive present in the playbook's table but missing from README.
- **Skills table:** add new skills, remove deleted ones, fix descriptions that drifted.

Match the existing entry style. Keep descriptions to one line.

### 5. Pre-flight diff review

Inspect what's about to be committed *before* committing. This is the gate that catches regressions.

```bash
cd /tmp/engineering-playbook && git status --short && git diff --stat
```

Red flags:

- **Deletions in a skill file.** A skill shrinking significantly is a yellow flag for a possible regression. Read the full diff for that file (`git diff .claude/skills/<skill>/SKILL.md`) before committing. If you can't explain the deletion, stop and ask the user.
- **Missing expected files.** Playbook, deep dives, or new skills that should have been copied but aren't showing up as changed.
- **Stray files** you didn't intend to add.

A bad sync regresses `main`. Every project that re-syncs from it inherits the regression. Don't commit blind.

### 6. Commit and push

```bash
cd /tmp/engineering-playbook && git add -A && git commit -m "<message>" && git push origin main
```

Commit message style: short, lowercase first word, describes what changed. Match the existing history.

Examples:

- `eng-check: compress PR-gate, fold inline-fix into the orchestrator step`
- `cleanup: remove stale nested skill dirs`
- `sync playbook and deep dives from vault` (for routine syncs with no deliberate skill changes)

### 7. Refresh the local mirror

Canonical is `~/.claude/skills/`. The one mirror is `~/Developer/engineering-playbook/.claude/skills/`, the local checkout of the repo you just pushed. Other projects no longer keep project-local eng-* copies, so there's nothing else to propagate. If a project ever adds a project-local copy back, add it here: project-local overrides user-level at invocation time, so a stale copy silently ships stale behavior.

```bash
MIRROR="$HOME/Developer/engineering-playbook"
for SKILL in "$MIRROR/.claude/skills"/*/; do
  SKILL_NAME=$(basename "$SKILL")
  SOURCE="$HOME/.claude/skills/$SKILL_NAME"
  if [ -d "$SOURCE" ]; then
    rsync -a --delete "$SOURCE/" "$SKILL/"
  fi
done
```

This only overwrites skills that exist in both places, and `--delete` keeps each skill's internal files exactly matching the canonical source.

After the rsync the mirror's working tree matches `origin/main` (what you pushed), but its local HEAD is still one commit behind. Fast-forward it:

```bash
git -C "$HOME/Developer/engineering-playbook" pull --ff-only
```
