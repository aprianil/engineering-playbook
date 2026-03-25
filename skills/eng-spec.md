Write a feature spec before building anything.

The user will describe what they want loosely. Your job is to turn it into a clear spec that captures enough context for anyone — human or AI — to build from it without needing to ask 20 follow-up questions. The spec is the single source of truth: context, decisions, and criteria in one place. No handoffs.

Scale the spec to the task. Small feature? Skip sections that don't apply. New initiative? Fill in the full context. The structure flexes — the thinking doesn't.

**Step 1: Read the guardrails**
- Read the project's CLAUDE.md for engineering principles and conventions.
- If no CLAUDE.md exists, ask if the user wants to run `/eng-init` first.

**Step 2: Gather context**
If the user hasn't already covered these, ask — but only what's missing. Don't interrogate.

- "What problem does this solve?" (one sentence)
- "Who is this for? What are they doing when they hit this?" (the user, their situation, their frustration or need)
- "What triggered this?" (customer feedback, bug report, internal idea, strategic decision — the background that led here)

This is the Context box. The richer it is, the better everything downstream performs.

**Step 3: Ask for acceptance criteria**
Ask: "How will you know this is good? What should I check before considering this done?"

If the user isn't sure, suggest criteria based on the playbook principles:
- Can a new team member understand this code quickly?
- Are edge cases handled (empty state, errors, slow/down API)?
- Does the file structure follow the project's conventions?
- Is the UI functional for the user on the sad path, not just the happy path?
- Is it simple enough that it doesn't need comments to explain?

Let the user add, remove, or adjust.

**Step 4: Write the spec**
Based on everything gathered + CLAUDE.md principles, write a spec. Include only the sections that apply — skip what's not relevant for the size of the task.

```
## Feature: [name]

### Context
Why this exists. The background — customer feedback, bug reports, research, or decisions that led to this work. Enough that someone reading this 3 months from now understands the motivation without asking anyone.

### What
One-line description of what this feature does.

### Who
Who this is for and what they're doing when they encounter this. Not a persona doc — just enough to anchor the design decisions.

### User flow
The steps a user takes, in order. What they see, what they do, what happens. Cover the happy path and the sad path (errors, empty states, slow connections).

### Acceptance criteria
- [ ] [each criterion from step 3]

### Success metrics
How you'll know this feature actually worked after shipping. What changes in user behavior, error rates, support tickets, or business outcomes? Skip for small features — include for anything you'd want to evaluate later.

### Proposed approach
- File structure: which files will be created or modified
- Key decisions: any trade-offs or choices, with reasoning
- Edge cases: what happens when things go wrong

### Dependencies & risks
What could block or break this. External APIs, other teams, data migrations, timing constraints. Skip if none.

### Out of scope
What this feature explicitly does NOT include. Prevents scope creep and sets clear boundaries for AI and humans alike.
```

**Step 5: Get approval**
Present the spec to the user. Do NOT write any code yet. Wait for approval or adjustments.

**Step 6: Build**
Only after the user approves the spec, start implementing. Reference the acceptance criteria as you build — they are your eval.

**After building:**
Run through the acceptance criteria as a self-check. Flag anything that doesn't fully meet the criteria before presenting to the user.
