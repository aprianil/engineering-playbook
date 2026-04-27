---
name: sync-playbook
description: Sync the engineering playbook, deep dives, and skills from Obsidian and ~/.claude/skills/ to the engineering-playbook GitHub repo. Updates README if needed.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Sync the playbook, deep dives, and skills to the `engineering-playbook` GitHub repo.

## Sources of truth

- **Skills:** `~/.claude/skills/` is canonical. If you've been editing skill files in a project-local `.claude/skills/` (e.g. `Developer/engineering-playbook/`, `open-visibility/`, `companio-agent/`), copy those edits into `~/.claude/skills/` FIRST. This skill blindly pushes whatever lives in the canonical source, and silent downgrades are how regressions land on main.
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

### 3. Copy skills with rsync

```bash
rsync -a --delete \
  --exclude='web-animation-design' \
  --exclude='make-interfaces-feel-better' \
  ~/.claude/skills/ /tmp/engineering-playbook/.claude/skills/
```

The trailing slash on the source is mandatory. It copies the *contents* of `~/.claude/skills/`, not the directory itself. `--delete` removes any skill files in the repo that no longer exist in the canonical source.

**The repo ships engineering-process skills only.** Domain skills (`web-animation-design`, `make-interfaces-feel-better`, future `<domain>-design` / `<stack>-patterns` skills) live in `~/.claude/skills/` for the user's own invocation but don't belong in the public playbook, which is scoped to the engineering learning arc (plan → build → review → learn). Add any new non-engineering skill to the `--exclude` list above. If the excludes list grows past ~3 entries, flip to an allowlist instead of a blocklist.

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

- `eng-debug: plural hypotheses, revert rejected code, ban sleep fixes`
- `cleanup: remove stale nested skill dirs`
- `sync playbook and deep dives from vault` (for routine syncs with no deliberate skill changes)

### 7. Propagate canonical skills to consumer projects

The GitHub repo is now up to date, but any project that keeps a project-local `.claude/skills/<skill>/` copy is still running the old version — project-local overrides user-level at invocation time, so a stale project-local copy silently ships stale behavior the next time the user runs that skill in that project. Push the updated canonical version back down into each consumer project.

```bash
PROJECTS=(
  "/Users/apri/Developer/engineering-playbook"
  "/Users/apri/Developer/open-visibility"
  "/Users/apri/companio-agent"
)

for PROJECT in "${PROJECTS[@]}"; do
  TARGET="$PROJECT/.claude/skills"
  [ -d "$TARGET" ] || continue
  echo "Propagating to $PROJECT"
  for SKILL in "$TARGET"/*/; do
    SKILL_NAME=$(basename "$SKILL")
    SOURCE="$HOME/.claude/skills/$SKILL_NAME"
    if [ -d "$SOURCE" ]; then
      rsync -a --delete "$SOURCE/" "$SKILL/"
    fi
  done
done
```

What this does:
- Only overwrites skills that already exist in both user-level AND project-local. Skills that only exist project-local are left alone (deliberate project-specific customizations are preserved by not being in user-level).
- Skills added to user-level but absent from a project are NOT auto-added — adopting a new skill into a project is a deliberate decision, not a side effect of sync.
- The `--delete` flag keeps each skill's internal files (SKILL.md + scripts/ + resources/) exactly matching the canonical source.

Add new projects to the `PROJECTS` array as they're created. If a project no longer exists, the `[ -d "$TARGET" ] || continue` guard skips it silently rather than failing the sync.

After this step, every known project has the same skill code that was just pushed to the GitHub repo. No manual `cp` dance per project.

**Note on `Developer/engineering-playbook`:** this is the local checkout of the GitHub repo you just pushed to. After step 7, its working tree matches `origin/main` (what you pushed), but its local HEAD is still one commit behind. Fast-forward it:

```bash
git -C /Users/apri/Developer/engineering-playbook pull --ff-only
```
