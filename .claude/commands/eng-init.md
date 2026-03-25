Initialize a CLAUDE.md file in the current project with shared engineering principles.

First, check if a CLAUDE.md already exists in the current project root. If it does, ask before overwriting.

Then create a CLAUDE.md that includes:

1. **Project-specific section** — ask the user for:
   - What the project is (one line)
   - Tech stack
   - Any known gotchas

2. **Engineering principles section** — always include these:

```
## Engineering principles

These guide how code is written and reviewed in this project:

1. Aim for simplicity. Cut as much as you can. Write code that reveals intentions and is easy to change.
2. YAGNI — don't build for imaginary future requirements.
3. Discover abstractions, don't design them. Wait for the pattern to repeat before extracting. Duplication is cheaper than the wrong abstraction.
4. Time is a design constraint. Shortcuts are okay if deliberate and documented.
5. Type 1 vs Type 2 decisions. Most decisions are reversible — move fast on those. Be careful with irreversible ones.

When writing or editing code:
- Organize by feature, not by file type. Start flat — don't create folders for one file. Let structure emerge as the feature grows.
- Dependencies flow one direction. Features don't import from other features. Shared code doesn't import from features.
- Each file should do one thing. Favor locality of behavior — if someone needs to open 5 files to understand one behavior, it's over-separated.
- Name things so the reader never has to open the body to understand what it does. Don't abbreviate, don't put the type in the name (e.g., `users` not `userList`), don't repeat context (e.g., `user.getName()` not `user.getUserName()`). Match name length to scope.
- Handle the sad path, not just the happy path.
- Keep files focused — favor readability over line count.
- Don't add complexity for hypothetical scenarios.
- If a component can be described with "and" (does X AND Y AND Z), suggest splitting it.
- Proactively flag when a file is growing beyond one responsibility — don't wait to be asked.
- Code you write is also context for AI tools. Clear naming, small files, and co-located features make AI assistance dramatically better.
```

3. **Project structure section** — scan the current directory and document the folder structure. If the project is new or empty, suggest a feature-based structure based on the tech stack.

4. **Commands section** — detect package.json or similar and list available scripts.

5. **Contributing section** — add a short note:

```
## For contributors
- Read this file before making changes
- Follow the principles above — they apply to all code in this project
```
