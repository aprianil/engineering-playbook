# Code Review — What to Look For and How to Do It

> A deep dive from the [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md). Based on [Google's Code Review Developer Guide](https://google.github.io/eng-practices/review/reviewer/) — the actual guide Google engineers use internally, made public.

---

## The Core Standard

**"Approve a PR once it definitely improves overall code health — even if it isn't perfect."**

No perfect code exists. The goal is continuous improvement, not perfection. But never approve something that makes the codebase worse. The bar is: is this better than what we had before?

This is a trade-off. Too strict → developers stop contributing. Too lenient → code health degrades one small compromise at a time.

---

## What to Look For

When reviewing code, run through these in order. Design problems found early save you from reviewing code that might get rewritten anyway.

### 1. Design

The most important thing. Does the change make sense as a whole?

- Do the pieces interact in a way that's logical?
- Does this functionality belong here — or in a library, a different feature, a different layer?
- Does it integrate well with the rest of the system?
- Do dependencies flow in the right direction? Features shouldn't import from each other. Shared code shouldn't import from features. (See Part 0 — dependency direction)

If the design is wrong, say so immediately. Don't review the details of code that needs a rethink.

### 2. Functionality

Does it actually do what the author intended? Think about edge cases the author might have missed.

- What happens with empty input, null values, unexpected types?
- Are there concurrency issues — race conditions, double submits?
- For UI changes: does it look right? Does it handle loading, error, and empty states?

### 3. Complexity

**"More complex than it should be"** is the most common problem in code review.

Three levels to check:
- **Lines** — is this line too hard to parse? Could it be simpler?
- **Functions** — is this function doing too much? Would a reader understand it quickly? Use the "and" test: if you describe a function and use the word "and," each "and" is a split point.
- **Classes/files** — is this abstraction earning its keep, or is it over-engineering? Was it discovered from real patterns, or designed upfront? (Principle #3 — discover abstractions, don't design them)

Watch for solving problems that don't exist yet. "What if we need to support X in the future?" — you probably won't. YAGNI.

Check for locality of behavior: can you understand this behavior without opening multiple files? If a change requires jumping across 5 files to follow one flow, that's a complexity signal — not just an inconvenience.

### 4. Tests

Tests should come with the change, not as a follow-up (follow-ups rarely happen).

- Are they testing behavior, not implementation details?
- Would they actually fail if the code broke?
- Do they cover edge cases, not just the happy path?
- Are the tests themselves simple and readable?

### 5. Naming

Does the name tell you what it does without reading the body?

- Long enough to communicate purpose, short enough to read easily
- Consistent with the existing codebase
- If you can't name it simply, it might be doing too much

### 6. Comments

Good comments explain **why**, not what. If code needs a comment explaining *what* it does, it should be rewritten to be clearer.

- Comments should explain intent, context, or non-obvious trade-offs
- Outdated comments are worse than no comments
- TODOs are fine — but they should reference a ticket or have a name attached

### 7. Style & Consistency

Follow the style guide. Don't mix style changes with functional changes in the same PR.

- If it's not in the style guide, it's preference — defer to the author
- Prefix style suggestions with "Nit:" so the author knows it's optional

---

## How to Navigate a Review

Don't just read top to bottom. Be strategic:

**Step 1 — Zoom out.** Read the PR description. Does the change make sense? Is it the right approach? If not, stop here and say so — with a suggestion for what to do instead.

**Step 2 — Review the main files first.** Find the biggest, most important files in the change. This is where design problems live. If you find fundamental issues, flag them before reviewing the rest.

**Step 3 — Read the rest systematically.** Once the design is solid, go through remaining files. Reading tests before implementation can help you understand the intended behavior.

---

## Speed Matters

Slow reviews kill teams. Not because of one slow review, but because the pattern compounds.

- **One business day maximum** to respond to a review request
- **Don't interrupt focused work** — review at natural break points (between tasks, after lunch, before/after meetings)
- **Quick incremental feedback > slow comprehensive review** — if you spot a design issue early, say it immediately. Don't wait until you've reviewed everything
- **LGTM with comments** is fine when the remaining suggestions are minor and you trust the author to address them

The most common complaint about code review isn't strictness — it's slowness. Fix the speed and most frustration disappears.

---

## How to Write Comments

The difference between a helpful review and a demoralizing one is how you write.

### The rules

- **Comment on the code, not the person.** "This function is getting complex" not "You wrote this in a confusing way"
- **Explain why.** Don't just say "change this" — explain what problem it causes or what principle it violates
- **Label severity.** Use "Nit:" for optional polish. Use "Optional:" or "FYI:" for educational comments. Unlabeled = must fix
- **Balance.** Call out good work too — a clean test, a smart design choice, a clear name. Positive reinforcement shapes future behavior

### When to give solutions vs. let them figure it out

- Point out the problem first. Let the author decide how to fix it — they learn more that way
- Offer a concrete suggestion when the fix isn't obvious, or when it would save significant back-and-forth
- The goal is code quality first, education second

### If you can't understand it

If you can't understand what the code does after a reasonable effort, that's a review comment. The code should be rewritten for clarity — not explained in a review thread that nobody will read later.

---

## Handling Pushback

Sometimes authors disagree with your feedback. That's healthy.

**When they push back:**
1. Consider whether they're right — they often know the code better than you
2. If their reasoning improves code health, accept it and move on
3. If you still believe the change matters, explain why — show that you understood their point, then clarify yours

**The "I'll fix it later" trap:**
This almost never happens. The further in time from the original PR, the less likely the cleanup is. If something needs fixing, it needs fixing now — unless it's a genuine emergency.

**Stay kind, stay firm.** Most developer frustration comes from *how* feedback is delivered, not whether standards are enforced. Respectful tone + clear reasoning = reviewers and authors both leave better.

---

## The One-Page Summary

```
Before reviewing
- Read the PR description. Does the approach make sense?
- Check the main files first. Flag design issues before reviewing details.

What to look for (in priority order)
1. Design — does it make sense as a whole? Dependency direction correct?
2. Functionality — does it work? Edge cases?
3. Complexity — simpler than necessary? Over-engineered? Good locality? The "and" test?
4. Tests — do they test behavior? Would they catch a break?
5. Naming — clear without reading the body?
6. Comments — explain why, not what
7. Style — follow the guide, defer on preferences

How to comment
- Code, not the person
- Explain why
- Label: Nit / Optional / FYI for non-blockers
- Acknowledge good work

Speed
- Respond within one business day
- Don't interrupt focused work
- Quick feedback > slow comprehensive review
```

---

*Source: [Google's Code Review Developer Guide](https://google.github.io/eng-practices/review/reviewer/). Adapted for the [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md).*
