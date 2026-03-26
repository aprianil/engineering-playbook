---
name: sync-playbook
description: Sync engineering playbook and deep dive files from Obsidian to GitHub. Also copies skills and checks if README needs updating.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep
---

Sync engineering playbook files from Obsidian to GitHub.

1. Read `Engineering Learnings & Playbook.md` from `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Apri/` and find all files linked in the "Deep dives" section.
2. If `/tmp/engineering-playbook/` doesn't exist, clone `git@github.com:aprianil/engineering-playbook.git` there first.
3. Copy the playbook and all linked deep dive files to the repo.
4. Copy all skills from `~/.claude/skills/` to `.claude/skills/` in the repo.
5. Check if `README.md` needs updating (new deep dives, new skills, changed descriptions). Update if needed.
6. Stage, commit with a short message, and push.
