Review the current code against the team's engineering principles.

If a CLAUDE.md exists in the project root, read it first to load the project's engineering principles. If not, use the principles below as the baseline.

Then review the code the user is pointing to (or the most recently edited files if not specified). Check against:

**Principles:**
- Is this as simple as it can be?
- Is anything being built for an imaginary future requirement? (YAGNI)
- Are there forced abstractions that should stay as duplication?
- If shortcuts were taken, are they documented?
- Are irreversible decisions being treated with enough care?

**Structure:**
- Is each file focused on one thing?
- Is code organized by feature, not by type?
- Does naming reveal intent without reading the body?
- Would a new team member — or AI — understand this without reading 5 other files?

**Quality:**
- Are edge cases handled (empty, null, unexpected input)?
- Is error handling useful, not silent?
- Is the sad path covered, not just the happy path?
- Are there side effects that could break other things?

**Output format:**
- Start with a one-line verdict: looks good / has concerns / needs rework
- List specific issues found, referencing the principle or checklist item
- For each issue, suggest a concrete fix
- End with: "Checked against project engineering principles"
- Keep it concise — flag what matters, skip what's fine
