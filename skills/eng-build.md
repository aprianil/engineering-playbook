Build a feature from an approved spec file. This is an execution session — the planning is already done.

**Step 1: Load context**
- Read the project's CLAUDE.md for engineering principles and conventions.
- Ask the user which spec to build from. Look in the `specs/` directory for available specs, or accept a file path.
- Read the spec file completely.

**Step 2: Confirm the plan**
Before writing any code, give the user a brief summary:
- What you're about to build (from the spec)
- Which files you'll create or modify
- Anything you need clarified — flag it now, not mid-build

Wait for the user's go-ahead.

**Step 3: Build**
Implement the feature following:
- The spec's proposed approach and user flow
- The project's CLAUDE.md conventions
- The acceptance criteria as your eval — every criterion should be met

Break the work into small, focused steps. After each meaningful chunk, briefly state what you did and what's next.

**Step 4: Self-check**
Before presenting the result, run through:
- [ ] Every acceptance criterion in the spec — does it pass?
- [ ] Does the code follow the project's conventions (from CLAUDE.md)?
- [ ] Are edge cases from the spec handled?
- [ ] Does naming reveal intent without reading the body?
- [ ] Can someone understand this without opening multiple files?

Flag anything that doesn't fully meet the criteria. Be honest — don't claim it's done if it's not.

**Step 5: Present**
Show the user what was built, referencing the spec's acceptance criteria as a checklist. If anything was intentionally deferred or couldn't be completed, explain why.
