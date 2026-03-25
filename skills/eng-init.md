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
3. Discover abstractions, don't design them. Wait for the pattern to repeat before extracting.
4. Time is a design constraint. Shortcuts are okay if deliberate and documented.
5. Type 1 vs Type 2 decisions. Most decisions are reversible — move fast on those. Be careful with irreversible ones.

When writing or editing code:
- Organize by feature, not by file type
- Each file should do one thing
- Name things so the purpose is clear without reading the body
- Handle the sad path, not just the happy path
- Keep files focused — favor readability over line count
- Don't add complexity for hypothetical scenarios
- If a component can be described with "and" (does X AND Y AND Z), suggest splitting it
- Proactively flag when a file is growing beyond one responsibility — don't wait to be asked
```

3. **Project structure section** — scan the current directory and document the folder structure.

4. **Commands section** — detect package.json or similar and list available scripts.

5. **Contributing section** — add a short note:

```
## For contributors
- Read this file before making changes
- Follow the principles above — they apply to all code in this project
- Use `/eng-check` to review code against these principles before opening a PR
```
