# How to Learn From Your Engineer's Code

> Your engineer is a free masterclass. Their PRs, commits, and architecture choices teach you more than any course — if you know what to look for.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md) system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## Why This Matters

You work alongside engineers. Every PR they open, every file they structure, every decision they make — that's real-world engineering judgment in action. Courses teach you theory. Your engineer's code teaches you how things actually get built in your product, with your constraints, in your stack.

The trick is knowing how to extract the lessons.

---

## How to Read Their PRs

PRs are the single best learning material you have. Each one is a decision record — it shows what changed, why, and how.

**What to look at in every PR:**

```
1. The description — what problem does this solve? How did they frame it?
2. The file list — which files were touched? Why those files?
3. The diff — what was added, removed, changed?
4. The structure — did they create new files? Split existing ones? Why?
5. The naming — how did they name new functions, variables, components?
6. The tests — what did they choose to test? What did they skip?
```

**Questions to ask yourself (not necessarily out loud):**

```
- Why did they put this code in this file and not another?
- Why did they split this into two functions instead of one?
- What pattern are they following that I can reuse?
- Is there anything here I don't understand? (Write it down.)
- Would I have done this differently? Why might their way be better?
```

---

## How to Ask Good Questions

Asking your engineer "why did you do it this way?" is one of the highest-leverage things you can do. But how you ask matters.

**Good questions (show you've thought about it):**

```
"I noticed you split the billing logic into its own hook instead of
keeping it in the component. Was that for reusability, or to keep
the component focused on rendering?"

"I see you're validating the input here at the API layer instead
of in the form. Is there a reason you prefer server-side validation
for this?"

"This pattern is different from how we did it in [other feature].
Was that intentional, or has our approach evolved?"
```

**Less useful questions (show you haven't looked yet):**

```
"What does this do?" (Read the code first, then ask about what's unclear.)
"Is this right?" (Too vague — ask about the specific choice.)
"Why is this so complicated?" (Might sound like a criticism — reframe as curiosity.)
```

The pattern: **observe first, form a hypothesis, then ask about the gap** between what you expected and what you see.

---

## What to Pay Attention To Over Time

As you read more of your engineer's code, start tracking patterns:

### Architecture Decisions
- How do they organize features? What goes where?
- When do they create a new file vs add to an existing one?
- How do they separate concerns (UI, logic, data)?
- When do they reach for a library vs write it themselves?

### Code Style Choices
- How do they name things? What conventions do they follow?
- How long are their functions? When do they split?
- How do they handle errors — where, and with what pattern?
- How do they manage state — local, global, server?

### Decision Patterns
- When do they choose speed over quality? (And how do they mark it?)
- When do they push back on a feature or scope?
- How do they handle tech debt — do they document it? Where?
- What do they refuse to compromise on?

---

## Turn Code Review Into a Learning Ritual

If you have access to review their PRs (even just reading, not formally reviewing):

**Weekly practice:**
```
1. Pick one PR from the past week
2. Read it fully — description, diff, tests
3. Write down one thing you learned or one pattern you noticed
4. If something is unclear, ask about it
5. Log it in your [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md) Learnings Log
```

This takes 15-20 minutes a week and compounds fast.

---

## What Not to Do

| Don't | Do instead |
|-------|-----------|
| Copy their code without understanding it | Understand the pattern, then apply it yourself |
| Assume their way is always the right way | They make trade-offs too — ask about the reasoning |
| Wait until you "know enough" to ask questions | Ask now — curiosity at your level is a strength, not a weakness |
| Only look at code when you need to fix something | Read proactively — even code you're not working on |
| Compare your code to theirs and feel inadequate | They have years more reps — you're building the same muscle |

---

## Resources

- "How to Do Code Reviews Like a Human" by Michael Lynch (mtlynch.io) — written for reviewers, but reading it teaches you what experienced engineers look for
- Google's "Code Review Developer Guide" (google.github.io/eng-practices) — understanding the reviewer's checklist helps you read PRs with the same lens
- "The Senior Engineer's Guide to Helping Others" by James Stanier — perspective from the other side, useful for understanding how your engineer thinks about mentoring through code

---

*Your engineer's codebase is a textbook written specifically for your product, your stack, and your team. No course can match that. Read it.*
