# Open Source Maintainership

> How to think about running an open source project — from a product builder's perspective.

---

## The Reframe: It's Product Management, Not Engineering Heroics

Most people think open source maintainership is about writing the best code. It's not. The projects that earn trust and grow communities are the ones with clear communication, good contributor experience, and opinionated decisions about scope.

This is product work. You already know how to:
- Say no to feature requests that don't fit the vision
- Design experiences for users (contributors are users too)
- Think about what "done" looks like before building
- Communicate decisions clearly

The gap isn't your background. It's the specific mechanics of how trust is built and maintained in open source. That's what this note covers.

---

## How Trust Is Built

Trust in open source comes from **predictability and transparency**, not credentials.

**What users and contributors look for:**
- **Clear README** — what this does, who it's for, how to get started. If someone lands on your repo and can't answer these in 30 seconds, they leave.
- **Consistent releases** — a project that ships regularly (even small updates) signals active maintenance. A project with no commits for 3 months signals abandonment.
- **Responsive issues** — you don't need to fix everything fast. You need to *acknowledge* fast. "Thanks for reporting — this is on our radar" costs 10 seconds and builds enormous trust.
- **Honest scope** — saying "this is intentionally out of scope" earns more respect than "maybe someday." Opinionated projects attract the right contributors.
- **Visible decision-making** — when you make a design choice, explain why in the PR or issue. People trust maintainers who show their reasoning, not just their conclusions.

**What erodes trust:**
- Silent issues — no response for weeks
- Breaking changes without warning or migration path
- Merging low-quality PRs to avoid conflict
- Scope creep — trying to be everything for everyone
- Inconsistency between what the README promises and what the code does

---

## Community Design

A community doesn't happen by accident. You design it the same way you design a product.

### Set Norms Early
Before your first external contributor shows up, have these in place:
- **CONTRIBUTING.md** — how to set up the project, how to submit changes, what you expect in a PR. This is onboarding documentation for contributors. Make it as clear as you'd make onboarding for a new user.
- **Issue templates** — guide people toward useful bug reports and feature requests. Without templates, you get "it doesn't work" with no context.
- **Code of conduct** — signals that you care about the experience, not just the code. Use an established one (Contributor Covenant is standard).
- **Labels on issues** — `good first issue`, `help wanted`, `bug`, `enhancement`. These are wayfinding for contributors. Small effort, big impact.

### The Gardening Mindset
Steve Klabnik (Rust documentation lead) reframes maintainership as gardening, not building. You're not constructing a monument — you're tending a living thing. That means:
- **Pruning** — closing stale issues, declining PRs that don't fit, removing features that aren't pulling their weight
- **Weeding** — keeping the codebase clean enough that new contributors can navigate it
- **Planting** — writing good issues that invite contribution, documenting decisions so newcomers understand the "why"

This mindset is natural for a product person. You already think about lifecycle, not just launch.

### Saying No With Grace
The hardest skill in open source is declining contributions without discouraging contributors. The frame:
- Thank the effort explicitly
- Explain the *why* behind the decision (scope, direction, complexity budget)
- Offer an alternative when possible ("this would work great as a plugin/fork")
- Be direct — vague "maybe later" responses waste everyone's time

Jessie Frazelle calls this "The Art of Closing." It's the same muscle as cutting features from a product roadmap — you're protecting the vision, not rejecting the person.

---

## Release Mechanics

### Semantic Versioning (SemVer)
The standard: `MAJOR.MINOR.PATCH` — [semver.org](https://semver.org)
- **PATCH** (1.0.1) — bug fixes, no behavior changes
- **MINOR** (1.1.0) — new features, backward compatible
- **MAJOR** (2.0.0) — breaking changes

SemVer communicates trust. Users know what to expect from each update. Breaking changes in a patch release destroys confidence fast.

**For early-stage projects (0.x.x):** SemVer convention says anything goes before 1.0. Use this honestly — ship 0.1.0, iterate, break things, and only cut 1.0 when the API is stable enough to commit to.

### Changelogs
Use the [Keep a Changelog](https://keepachangelog.com) format:
- Group changes by: Added, Changed, Deprecated, Removed, Fixed, Security
- Write for humans, not machines
- Link each version to a diff

A good changelog is the most underrated trust signal in open source. It tells users "we care about your upgrade experience."

### Release Cadence
Pick a rhythm and stick to it. Options:
- **Time-based** — release every 2 weeks regardless of what's in it (predictable for users)
- **Feature-based** — release when a meaningful set of changes is ready (natural for small teams)
- **Continuous** — every merged PR is a release (requires good CI/CD and test coverage)

For a first project, feature-based is simplest. The important thing is that releases happen visibly and regularly.

---

## Contribution Workflows

### What a Good CONTRIBUTING.md Covers
1. How to set up the development environment (step by step, assume nothing)
2. How to run tests locally
3. Branch naming convention (if any)
4. PR expectations — what you'll review for, how long reviews typically take
5. Where to ask questions (issues, discussions, Discord — pick one)

### Reviewing External PRs
This is where product thinking helps most. For each PR, ask:
- Does this fit the project's direction?
- Is the scope contained? (One PR = one thing, same as your engineering playbook)
- Will this be maintainable by someone other than the author?
- Does it have tests for the new behavior?

You don't need to be the deepest engineer in the room to review well. You need to ask "does this belong here?" and "can I understand this?" — both are product/design judgment calls.

### Making Issues Contribution-Ready
A well-written issue is the best contributor magnet:
- Clear description of the problem or desired behavior
- Acceptance criteria (what "done" looks like)
- Pointer to relevant files or code
- Label: `good first issue` for small, scoped changes newcomers can tackle

This is spec writing — something you already do.

---

## Boundaries and Sustainability

Open source burnout is real and well-documented. Set boundaries before you need them:

- **You don't owe anyone a response time.** Acknowledge when you can, but "I maintain this in my free time" is a perfectly valid stance.
- **Not every issue deserves a fix.** "Won't fix" is a valid label. Use it.
- **Contributors aren't employees.** Appreciate effort, but don't merge code that doesn't meet your standards just because someone spent time on it.
- **Your roadmap is yours.** Feature requests are input, not obligations.

Brett Cannon (Python core developer) frames it well: open source is a gift. You gave the code away for free. That's generous. You don't also owe unlimited support.

Rich Hickey (Clojure creator) puts it more bluntly: "Open source is not about you" — directed at users who demand maintainer attention as if they paid for it.

---

## Essential Resources

**The book:**
- "Working in Public" by Nadia Eghbal — the definitive book on open source social dynamics. Eghbal is a writer/researcher, not an engineer. Covers how communities form, the economics of attention, and what maintenance really looks like.

**Start here (short reads):**
- [GitHub Open Source Guides](https://opensource.guide) — "Best Practices for Maintainers" and "Building Welcoming Communities" chapters
- [keepachangelog.com](https://keepachangelog.com) — how to write changelogs humans read
- [semver.org](https://semver.org) — version numbering standard

**Talks:**
- "The Hard Parts of Open Source" by Evan Czaplicki (Strange Loop) — community management, handling criticism, opinionated decisions
- "How to be an Open Source Gardener" by Steve Klabnik — maintainership as tending, not building
- "Open Source is Not About You" by Rich Hickey — setting boundaries with users

**On boundaries:**
- Brett Cannon's "Setting Expectations for Open Source Participation" — what you owe and don't owe

---

*Your product instincts are the foundation. The mechanics layer on top. Most engineer-maintainers struggle with exactly the skills you already have — this note covers the part they find easy and you find unfamiliar.*
