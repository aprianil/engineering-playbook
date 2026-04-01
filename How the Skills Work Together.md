# How the Skills Work Together

> A walkthrough of building a real feature using the full skill cycle -- from vague idea to shipped code. Shows how the playbook's engineering principles are embedded in every step.

---

## The feature: Citation Tracking

Track whether a brand appears in AI search results. This is the first feature for an AEO (Answer Engine Optimization) tool.

---

## Step 1: `/eng-init` (one-time setup)

Scaffolds a CLAUDE.md with engineering principles, Do/Don't rules, feature structure patterns, and doc references for your stack. Every future AI session in this project reads this file first.

Run once per project. The principles compound -- every session benefits.

---

## Step 2: `/eng-spec citation-tracking` (planning)

You describe a vague idea: "I want to track if a brand shows up in AI search results."

The skill detects the idea is still forming and enters **exploration mode** -- asking focused questions one at a time:

```
> What's the core problem you're solving?
  - Brand owners don't know if AI recommends them (selected)

> Which AI platforms should we track in v1?
  - ChatGPT + Perplexity -- two platforms to validate the approach

> How should we check for citations?
  - Not sure yet -- need to explore
```

When a question needs deeper thinking, the skill enters **plan mode** -- explores APIs, compares approaches, and presents a recommendation:

```
Option A: DataForSEO AI Search API -- they handle the prompting,
          you get structured responses. Simpler, dependency on third party.

Option B: Direct API calls to ChatGPT + Perplexity APIs.
          Full control, but more complexity to maintain.

Recommendation: Option A for v1.
Simplicity -- DataForSEO handles the hard part.
Type 2 decision -- you can switch to direct APIs later.
```

Once the idea is clear, the skill **launches parallel research agents** to ground the spec in real codebase evidence before writing it. Two agents run simultaneously -- one maps which files and patterns the feature should follow, the other surfaces edge cases and constraints (irreversible decisions, failure modes, risky inputs). The spec is then written from their findings, so the "Proposed approach" references real file paths and the "Edge cases" section reflects actual constraints -- not guesses.

Then it **spawns a sub-agent to stress-test the spec with fresh eyes** (the builder shouldn't be the reviewer). The stress-test agent reads the spec cold, loads the project's CLAUDE.md, explores the codebase, and challenges the design:

```
Verdict: address these first

1. Response time < 30s for 10 prompts -- is that realistic?
   DataForSEO queries take 5-15s each. 10 sequential queries
   could be 50-150s. Parallelize or reduce v1 limit.

2. No validation on prompt input -- what if someone submits
   empty prompts or 100 prompts? Add to acceptance criteria.

3. API key management -- spec says "no auth" but DataForSEO
   needs a key. Ensure .env is in .gitignore.
```

You see the spec + stress-test findings together. Adjust, approve, save to `specs/citation-tracking.md`.

**Principles in play:** simplicity (chose the simpler approach), YAGNI (only two platforms, not three), Type 2 decision (reversible API choice), parallel research grounded the spec in real file paths and constraints, fresh eyes on the spec, stress-test caught the verification gap.

---

## Step 3: `/eng-build` (execution)

New session. Claude reads the CLAUDE.md and the approved spec. The planning is done -- execution should feel easy.

```
Building citation tracking from the approved spec.
6 acceptance criteria, 2 platforms, DataForSEO integration.

Schema and business logic done. Queries run in parallel...
API route done -- thin, validates with Zod, delegates to lib/...
Frontend done -- results per prompt per platform, error states handled...

Acceptance criteria:
- [x] User can input a brand name and up to 10 prompts
- [x] System queries ChatGPT and Perplexity via DataForSEO
- [x] Results show cited/not cited per prompt per platform
- [x] Error states handled: API down, rate limit, no results
- [x] Results stored in database for historical tracking
- [x] Response time < 30s for 10 prompts (parallel queries)
```

The feature follows the project's structure conventions -- thin routes, business logic in `lib/`, shared Zod schema, feature-specific UI components.

While building, the skill holds judgment questions in mind -- am I discovering this abstraction or forcing it? What breaks if this fails? Can someone understand this without opening multiple files? These aren't steps, they're a lens. If something feels off, it pauses and flags.

After building, the skill prompts reflection -- but only if something surprised you. What trade-off did we make? What would we do differently? If something non-obvious was learned -- an API quirk, a debugging insight, a pattern that wasn't googleable -- the skill suggests running `/eng-compound` to capture it so the team never pays the same cost again.

**Principles in play:** simplicity (6 focused files), documented trade-offs (in the spec), verified against acceptance criteria.

---

## Step 4: `/deslop` (clean up with fresh eyes)

```
Removed 3 unnecessary comments, one redundant try/catch,
replaced an `as any` cast with a proper type, inlined a
single-use helper. 4 changes.
```

`/deslop` spawns a fresh sub-agent that reads the project's CLAUDE.md first, then reviews the code without the build session's context or bias. It removes AI slop -- comments that restate the obvious, defensive checks that can't trigger, type casts that hide real issues -- and simplifies unnecessary complexity like redundant logic or single-use abstractions. The sub-agent follows the CLAUDE.md conventions, not its own preferences.

---

## Step 5: `/eng-check` (last gate before shipping)

`/eng-check` spawns **two sub-agents in parallel**, each with fresh eyes and no build-session bias:

- **Architecture reviewer** -- checks principles, feature structure, naming, and spec alignment. Focuses on design and patterns.
- **Correctness reviewer** -- checks for bugs, edge cases, security issues, and test coverage. Focuses on whether it actually works.

Both read the CLAUDE.md, the changed files, and the spec. Their findings get merged into a single report, deduplicated where they overlap:

```
Architecture verdict: looks good
- 6 files, clean separation, each does one thing
- Routes thin -- validates and delegates
- Schema shared between frontend and backend
- Feature names mirror across layers

Correctness verdict: one issue
- API rate limit error returns raw DataForSEO error message
  to the client -- wrap in a user-friendly error
- Tests cover happy path and error states
- No security issues found
```

Two reviewers catch more than one. Architecture issues and correctness issues are different lenses -- splitting them means neither gets shortchanged. If the spec was good and the build followed it, the review should be clean. Issues here mean the planning was incomplete.

---

## Step 6: You review (own what you ship)

You look at the code. You can trace the full flow:

1. User submits brand name + prompts
2. Zod validates the input
3. `check-citations.ts` calls DataForSEO in parallel
4. Parses responses for brand mentions
5. Stores results in the database
6. Frontend renders per-prompt per-platform results

You understand every file and every decision. You could explain it to someone. You could change it next week without fear.

That's the difference between shipping code and owning it.

---

## The full cycle

```
/eng-init            Set up project principles (once)
     |
/eng-spec            Explore --> Research --> Spec --> Stress-test
     |               (searches docs/solutions/ for prior art)
/eng-build           Execute from the approved spec + reflect
     |
/deslop              Clean up with fresh eyes (sub-agent)
     |
/eng-check           Verify against principles + draft compound learnings
     |
You review           Own what you ship
     |
Ship PR              Merge and deploy
     |
/eng-compound        Enriches draft with PR history, you confirm
                     (SessionStart hook reminds you; stale drafts auto-clean)
```

### Standalone skills

Most skills fit the cycle above, but these can also be used independently:

- **`/eng-stress-test`** -- auto-triggered by `/eng-spec`, but you can also run it standalone on any spec or plan. Useful when you've written a spec by hand or want to re-challenge one after changes.
- **`/deslop`** -- works on any branch with changes, not just after `/eng-build`. Good for cleaning up code from any session.
- **`/eng-compound`** -- primarily auto-triggered: `/eng-check` writes drafts when it spots something non-obvious, and a SessionStart hook quietly reminds you they exist. But you can also run it standalone after debugging sessions or production incidents. Captured solutions feed back into `/eng-spec`'s research phase. Stale drafts (30+ days) are auto-cleaned.

---

Most of the work happens before and after writing code. The spec forces planning. The research grounds it in real codebase evidence. The stress-test catches assumptions. The build follows the spec and reflects on what surprised you. Compound captures what was learned so the team never solves the same problem twice. Deslop brings fresh eyes to clean up. Eng-check splits the review into two lenses so nothing gets missed. And at the end, you understand what you shipped.

The principles aren't abstract -- they're embedded in every step.
