# Building Engineering Taste

> How to develop the eye for what good engineering looks like — for someone who already has taste in design and product.

---

## The Starting Point

You know what good design looks like. You can look at a UI and immediately feel when something is off — spacing, hierarchy, flow. You didn't learn that from a checklist. You built it through years of seeing good and bad work, developing pattern recognition, and learning the vocabulary to articulate *why* something works or doesn't.

Engineering taste works the same way. The muscle is identical — evaluate against principles, notice patterns, articulate trade-offs. What's missing isn't the ability to judge. It's the engineering-specific vocabulary and exposure.

This note is a reading path to close that gap.

---

## What "Good Engineering" Actually Means

Before the reading list, ground yourself in what you're developing taste *for*. Good engineering isn't about clever code or knowing obscure language features. It comes down to a small set of qualities:

1. **Readable** — Can someone new understand this without a guided tour?
2. **Simple** — Does it solve the problem with the least complexity necessary?
3. **Changeable** — When requirements shift, can you change one thing without breaking ten others?
4. **Correct** — Does it actually do what it claims, including edge cases?
5. **Appropriate** — Is the level of effort proportional to the importance of the problem?

That last one is the trade-off muscle from your [Engineering Learnings & Playbook](Engineering%20Learnings%20%26%20Playbook.md). The first four are what the resources below teach you to see.

---

## The Reading Path

Ordered from "start here" to "when you're ready to go deeper." Don't try to do these all at once — spread them across weeks, and build real things in between.

### Phase 1: Build the Vocabulary

**"A Philosophy of Software Design" by John Ousterhout**
~180 pages. The single most important book for what you're trying to learn.

Ousterhout is a Stanford professor who spent decades watching students write code and identifying *why* some code is easy to work with and some becomes a nightmare. His core idea: **complexity is the root of all evil in software, and it creeps in through two mechanisms — dependencies and obscurity.**

What you'll get:
- A framework for evaluating whether code is "deep" (simple interface, rich functionality) or "shallow" (complex interface, trivial implementation)
- The vocabulary to articulate *why* a piece of code feels wrong — not just "this is messy" but "this leaks implementation details" or "this creates a dependency that doesn't need to exist"
- The argument that comments should describe *what's not obvious from the code* — which aligns with your playbook's "comments explain why, not what"

This is the design principles book of engineering. Read it first.

**CodeAesthetic's YouTube channel**
8-15 minute videos, visual, one concept each.

You watched the naming video. The rest of the channel covers: abstraction, dependency injection, coupling, error handling, refactoring, and more. Each video shows bad code → explains why it's bad → shows the fix.

This is the fastest way to build visual pattern recognition. It's the engineering equivalent of watching design critiques — you absorb what "off" looks like before you can fully articulate why.

Watch all of them. They're short enough to fit in gaps.

### Phase 2: Rewire Your Trade-Off Thinking

**"Simple Made Easy" by Rich Hickey (talk, ~60 min)**
Already in your playbook's further reading. Watch it now.

Hickey makes a distinction that changes how you evaluate everything: **simple** (few things tangled together) vs **easy** (familiar, close at hand). Code can be easy to write but complex to understand. A framework can be easy to start with but tangled in ways that fight you later.

After this talk, you'll start asking "is this simple or just easy?" about every tool and pattern choice. That question is engineering taste in one sentence.

**"Refactoring" by Martin Fowler (the smell catalog)**
Don't read cover to cover. Use Part 1 (chapters 1-4) for the philosophy, then skim the catalog of "code smells" — named patterns that signal something is off.

You already do this in design. "This has too much visual weight" is a design smell. "This function does too many things" is a code smell. Fowler gives you ~20 named smells with explanations: Long Method, Feature Envy, Shotgun Surgery, Primitive Obsession, etc.

The value isn't memorizing the catalog. It's that once you have names for the patterns, you start seeing them everywhere — and you can communicate about them. "This feels like Shotgun Surgery" is more actionable than "this feels wrong."

### Phase 3: See the Bigger Picture

**"Designing Data-Intensive Applications" by Martin Kleppmann**
The longer investment. Not about code style — about understanding *why systems are built the way they are*.

Databases, caching, message queues, replication, consistency, batch vs stream processing. You don't need to memorize any of it. Reading even the first few chapters shifts how you think about architecture decisions — you start seeing the trade-offs behind every "just use X" recommendation.

This is the engineering equivalent of reading "Don't Make Me Think" for the first time. It won't make you a systems engineer. It'll make you someone who asks the right questions when systems decisions come up.

Read this when you've shipped something real and start wondering why certain architectural choices feel slow or fragile.

**"Accelerate" by Nicole Forsgren**
Research-backed book on what actually makes engineering teams fast. Based on the largest study of software delivery performance ever conducted.

The core findings: continuous delivery, trunk-based development, test automation, and loosely coupled architecture predict both speed *and* stability. Most "best practices" that slow teams down (long code freezes, heavy approval processes, separate QA phases) actively hurt outcomes.

This matters for your concern because it helps you separate *cargo cult engineering* (doing things because "real engineers do it this way") from *practices that actually work*. You'll stop second-guessing yourself when you skip a ceremony that doesn't serve you.

---

## How This Connects to What You Already Know

| Design taste | Engineering taste | Same muscle |
|---|---|---|
| "This layout feels cluttered" | "This function does too many things" | Recognizing when something exceeds its complexity budget |
| "The hierarchy is unclear" | "The dependencies flow in the wrong direction" | Seeing structural problems before they cause visible failures |
| "This component doesn't belong here" | "This abstraction is in the wrong layer" | Judging whether something is in its right place |
| "I'd simplify this to the essential elements" | "I'd remove the indirection and inline this" | Cutting to what's necessary |
| "This feels inconsistent with the rest" | "This doesn't follow the patterns the codebase already uses" | Pattern matching against established conventions |

You're not starting from zero. You're translating.

---

## The Practice That Makes It Stick

Reading builds vocabulary. Building builds judgment. You need both, but building matters more.

After each resource:
- Apply it to code you're working on. Can you spot the patterns?
- Log what clicked in your [Engineering Learnings & Playbook](Engineering%20Learnings%20%26%20Playbook.md) learnings log
- When you review AI-generated code, try to articulate *why* something feels off using the vocabulary you're building

The goal: get to a point where you can look at a piece of code and say not just "this feels wrong" but *why* it's wrong and *what would be better* — the same way you already do with design.

---

## Essential Resources (Summary)

| Resource | Format | Time | What it builds |
|---|---|---|---|
| "A Philosophy of Software Design" — Ousterhout | Book | ~6 hours | Vocabulary for complexity, the "deep vs shallow" lens |
| CodeAesthetic (full channel) | YouTube | ~3 hours total | Visual pattern recognition, one concept at a time |
| "Simple Made Easy" — Rich Hickey | Talk | 60 min | Trade-off rewiring: simple vs easy |
| "Refactoring" smell catalog — Fowler | Book (skim) | ~2 hours | Named patterns for "something is off" |
| "Designing Data-Intensive Applications" — Kleppmann | Book | ~15 hours | Systems thinking, architecture trade-offs |
| "Accelerate" — Forsgren | Book | ~4 hours | Evidence for what practices actually matter |

---

*Taste isn't knowing everything. It's knowing what questions to ask and recognizing when something doesn't feel right. You already have that instinct — these resources give you the engineering lens to apply it through.*
