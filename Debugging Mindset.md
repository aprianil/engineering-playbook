# Debugging Mindset

> A systematic approach to fixing bugs — so you spend less time guessing and more time understanding.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [Engineering Learnings & Playbook](Engineering%20Learnings%20%26%20Playbook.md) system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## The Core Problem

When something breaks, the instinct is to start changing code — move things around, add console.logs, try random fixes. This is guessing. It sometimes works, but it wastes time and often creates new problems.

Senior engineers debug differently. They **understand first, then fix.** The fix is usually the easy part. Finding the real cause is the skill.

---

## The Debugging Framework

### Step 1: Reproduce It

Before you fix anything, make sure you can see the bug happen consistently.

```
- Can I trigger this bug every time?
- What are the exact steps to reproduce it?
- Does it happen in all environments (dev, staging, production)?
- Does it happen for all users or just some?
```

If you can't reproduce it, you can't verify your fix. Don't skip this step.

### Step 2: Read the Error Message (Really Read It)

Error messages contain more information than most people extract.

```
What to look for:
- The error type — what category of problem is this?
- The message — what does it say in plain English?
- The file and line number — where exactly did it break?
- The stack trace — what was the chain of calls that led here?
```

A stack trace reads bottom-to-top. The bottom is where the journey started. The top is where it crashed. The interesting part is usually in the middle — where *your* code called something that broke.

### Step 3: Narrow the Search

The worst debugging strategy is "look everywhere." Instead, cut the problem space in half.

```
Ask yourself:
- Did this work before? What changed since then?
  (git log and git diff are your best friends here)
- Where in the flow does it break?
  (Is the data wrong at the source, in transit, or at the display?)
- What layer is the bug in?
  Surface (UI) → Logic (API/processing) → Data (database/state)
- Can I isolate this to one file or function?
```

**The binary search technique:** If you don't know where the bug is, check the middle of the flow. Is the data correct at that point? If yes, the bug is later. If no, the bug is earlier. Cut in half again. Keep going.

### Step 4: Form a Hypothesis

Before changing any code, state what you think is happening.

```
"I think [this function] is receiving [this value] instead of
[expected value] because [reason]."
```

Then verify it. Add a console.log or a breakpoint at the exact spot. Check if your hypothesis is correct.

If it is — you've found the bug. Fix it.
If it isn't — that's still progress. You've eliminated one possibility. Form a new hypothesis.

### Step 5: Fix and Verify

```
- Make the smallest change that fixes the bug
- Verify the bug is gone (reproduce steps from Step 1)
- Check that you didn't break anything else
- Understand WHY the fix works — not just that it works
```

That last point is critical. If you can't explain why your fix works, you might be masking the bug, not fixing it.

---

## Debugging Tools to Use

### Console / Logging
```javascript
// Bad — tells you nothing useful
console.log("here")
console.log(data)

// Better — labeled, specific, tells you where and what
console.log("[BillingPage] user data:", userData)
console.log("[API /billing] request body:", req.body)
console.log("[useBilling] state after update:", newState)
```

### Browser DevTools
- **Console tab** — see errors and your logs
- **Network tab** — see every API request and response (status codes, payloads, timing)
- **Elements tab** — inspect what's actually rendered vs what you expected
- **Sources tab** — set breakpoints and step through code line by line

### Git as a Debugging Tool
```
git log --oneline -20          — what changed recently?
git diff                       — what have I changed right now?
git diff HEAD~3                — what changed in the last 3 commits?
git blame path/to/file         — who changed each line, and when?
git bisect                     — binary search through commit history
                                 to find when the bug was introduced
```

`git bisect` is powerful when you know "this worked last week but doesn't now" — it helps you find the exact commit that broke it.

### Claude Code as a Debugging Partner
```
"I'm seeing [this error] when I [do this]. Here's the error message:
[paste it]. What's likely causing this?"

"Can you trace the data flow from [this component] to [this API endpoint]
and tell me where the value might be getting lost?"

"I think the bug is in [this file]. Can you read it and tell me
what might cause [this behavior]?"
```

Give Claude Code the error message, the context, and your hypothesis. It can trace flows and spot patterns faster than reading every file yourself.

---

## Common Bug Patterns

Recognizing these saves time because you'll know where to look:

| Pattern | Symptoms | Likely Cause |
|---------|----------|-------------|
| Works locally, breaks in production | Different behavior between environments | Environment variables, API URLs, or build differences |
| Works on first load, breaks on navigation | State not resetting or stale data | Missing cleanup in useEffect, stale cache, or client-side routing issue |
| Data shows up then disappears | Flash of correct content then empty/wrong | Race condition, re-render overwriting state, or hydration mismatch |
| "Cannot read property of undefined" | Accessing something that doesn't exist yet | Data not loaded, missing null check, or async timing issue |
| UI doesn't update after action | Changes happen but screen stays the same | State mutation instead of creating new reference, missing re-render trigger |
| Works for some users, not others | Inconsistent behavior | Permissions, data-dependent edge case, or browser differences |

---

## The Mindset Shift

| Beginner | Experienced |
|----------|------------|
| "It's broken, let me try things" | "It's broken, let me understand why" |
| Changes code, hopes it works | Forms hypothesis, verifies, then fixes |
| Looks at the line that errored | Traces the full path that led to the error |
| Feels frustrated and stuck | Treats it as a puzzle — each clue narrows the search |
| Fixes the symptom | Fixes the root cause |
| Deletes the console.logs immediately | Keeps useful logging for future debugging |

---

## After You Fix It

Every bug is a lesson. After fixing, ask:

```
- Why did this happen?
- Could I have caught this earlier? (Better types, tests, validation?)
- Is this same pattern hiding elsewhere in the code?
- What would I do differently to prevent this next time?
```

Log the interesting ones in your [Engineering Learnings & Playbook](Engineering%20Learnings%20%26%20Playbook.md) Learnings Log. Bugs you've fixed once and understood deeply rarely catch you again.

---

## Resources

- "Debugging: The 9 Indispensable Rules" by David Agans — short, practical book on systematic debugging. The rules apply to any kind of debugging, not just code.
- Chrome DevTools docs (developer.chrome.com/docs/devtools) — official guide. The Network and Sources tabs are worth learning well.
- "How to Debug" by John Regehr (blog.regehr.org) — a computer science professor's take on debugging methodology. More technical but the thinking process is universal.
- "The Art of Debugging" section in "A Philosophy of Software Design" by John Ousterhout — connects debugging skills to code design. Poorly designed code is harder to debug.

---

*Debugging is just asking good questions in a specific order. Get the order right, and the answers come faster every time.*
