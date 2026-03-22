# Communicating Technically With Engineers

> How to participate in technical conversations, ask the right questions, and translate between product thinking and engineering thinking.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [[Engineering Learnings & Playbook]] system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## Your Advantage

You sit between product and engineering. Most people only speak one language. You're learning to speak both. That's not a weakness — it's a superpower in the making.

You don't need to know every technical detail. You need to know enough to:
- Ask questions that lead to better decisions
- Understand trade-offs when they're explained
- Push back when something doesn't add up
- Translate between what users need and what the system can do

---

## The Vocabulary That Matters

You don't need to memorize a glossary. But understanding these concepts lets you follow (and contribute to) technical conversations:

### When Discussing Features
```
Scope          — how much work is included in this feature
Edge case      — unusual situation that might break the expected flow
Happy path     — the flow when everything goes right
Sad path       — what happens when something goes wrong
Blocker        — something that prevents progress
Dependency     — something this work relies on to function
```

### When Discussing Architecture
```
Frontend       — what the user sees and interacts with
Backend/API    — the server that processes requests and returns data
Database       — where data is stored permanently
State          — data that the app holds temporarily (in memory)
Middleware     — code that runs between the request and the response
Endpoint       — a specific URL the API responds to
Schema         — the shape/structure of data
```

### When Discussing Quality
```
Tech debt      — shortcuts taken now that need fixing later
Refactor       — restructuring code without changing behavior
Breaking change — a change that causes existing features to stop working
Regression     — something that used to work but doesn't anymore
Idempotent     — doing something twice has the same result as doing it once
```

### When Discussing Performance
```
Latency        — how long it takes to respond
Load           — how much traffic/usage the system handles
Caching        — storing results so you don't recalculate every time
Rate limiting  — preventing too many requests in a short time
```

You don't need to use these words perfectly. Understanding them when you hear them is enough.

---

## How to Ask Good Technical Questions

The pattern: **context → observation → question**

### Good Examples

```
"I noticed the dashboard takes about 3 seconds to load.
Is that because we're fetching all the data at once,
or is there something else going on?"
→ Context + observation + specific question

"The billing page re-renders every time I type in the form.
Is that expected, or is something triggering unnecessary re-renders?"
→ Describes what you see + asks for the engineer's interpretation

"If we add this feature, does it touch the auth system?
I want to understand the blast radius before we commit."
→ Shows you're thinking about side effects and risk

"What's the simplest way to get this working for the demo,
and what would we need to do differently for production?"
→ Acknowledges the trade-off between speed and quality
```

### Patterns to Avoid

```
"Can you just make it faster?"
→ Too vague. Faster how? What's slow? What's acceptable?

"Why is the code like this?"
→ Can sound like criticism. Reframe: "What was the thinking behind this approach?"

"Is this hard to build?"
→ Hard to answer without context. Better: "What's involved in building this? What are the unknowns?"

"Can we just add a button that does X?"
→ "Just" minimizes complexity. Better: "What would it take to add X? Is it straightforward or are there dependencies?"
```

The word **"just"** is the biggest red flag in technical communication. It implies something is simple when it might not be. Drop it.

---

## How to Talk About Trade-Offs

This is where your product background becomes powerful. Engineers think about trade-offs technically. You can add the product lens.

### The Framework

When discussing any decision, try to cover:

```
1. What are we optimizing for? (Speed, quality, user experience, cost)
2. What are we giving up? (Time, flexibility, perfection)
3. Is this reversible? (Can we change our mind later, or are we locked in?)
4. What's the risk? (What's the worst case if this goes wrong?)
5. When do we revisit? (Is this a forever decision or a for-now decision?)
```

### Example Conversations

**Engineer:** "We can build this with a simple solution in 2 days, or a more scalable solution in 2 weeks."

**You (product lens):** "How many users will realistically use this in the next 3 months? If it's under 100, let's go simple and revisit when usage grows. If we're launching to thousands, maybe the investment is worth it now."

**Engineer:** "We should refactor the auth system before adding this feature."

**You (product lens):** "What breaks if we don't? Is this a 'nice to have' refactor or a 'the feature won't work without it' refactor? If it's the latter, let's do it. If not, can we ship the feature first and refactor after?"

---

## Participating in Technical Discussions

You don't need to have all the answers. You need to bring the questions that shape better decisions.

### Questions Worth Asking in Any Technical Discussion

```
"What's the simplest version of this we can ship?"
"What happens if this fails? What does the user see?"
"Who else does this affect? What other features touch this?"
"How do we know this works? How would we test it?"
"What are we assuming that might not be true?"
"Is this a one-way door or a two-way door?"
"What's the maintenance cost of this approach?"
```

These questions don't require deep technical knowledge. They require product thinking and the [[Engineering Learnings & Playbook]] mindset.

### What to Do When You Don't Understand

```
1. Say so — "I want to make sure I understand this correctly..."
2. Paraphrase — "So what you're saying is [your understanding], right?"
3. Ask for analogies — "Can you compare this to something I'd recognize?"
4. Ask about impact — "I don't fully get the technical details, but
   help me understand: what does this mean for the user?"
```

Not understanding is fine. Pretending to understand is not — it leads to bad decisions.

---

## Translating Between Product and Engineering

| Product Language | Engineering Translation |
|-----------------|----------------------|
| "The page feels slow" | "Latency is high — what's the load time? What's the bottleneck?" |
| "Can we just add this field?" | "What data model changes are needed? Does this require a migration?" |
| "Users are confused by this flow" | "The state management might need rethinking — where is the user getting lost?" |
| "We need this by Friday" | "What scope fits the timeline? What can we cut vs what's essential?" |
| "Make it look like this design" | "Here's the design — what's straightforward and what might need a different approach technically?" |

| Engineering Language | Product Translation |
|---------------------|-------------------|
| "This will create tech debt" | "We're taking a shortcut that we'll need to fix later" |
| "It's a breaking change" | "Existing users will be affected — things they rely on might stop working" |
| "We need to refactor first" | "The current code structure makes this change risky or slow — we should clean it up first" |
| "It's not idempotent" | "If this runs twice, it could cause duplicate charges/emails/records" |
| "There's a race condition" | "Two things are happening at the same time and the order matters — sometimes it goes wrong" |

---

## Resources

- "The Manager's Path" by Camille Fournier — chapters on working with engineers and understanding technical decisions. Written for managers but directly applicable to product/design people working closely with engineering.
- "Talking with Tech Leads" by Patrick Kua — interviews with senior engineers about how they communicate and make decisions. Helps you understand how they think.
- "An Elegant Puzzle" by Will Larson — about engineering organizations and how decisions flow. Useful for understanding the bigger picture of why engineers prioritize what they do.

---

*You don't need to speak engineering fluently. You need to ask the questions that make engineering decisions better. That's the value you bring to the conversation.*
