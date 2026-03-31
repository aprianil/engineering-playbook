# How the Skills Work Together

> A walkthrough of building a real feature using the full skill cycle — from vague idea to shipped code. Shows how the 9 engineering principles are embedded in every step.

---

## The feature: Citation Tracking

Track whether a brand appears in AI search results. This is the first feature for an AEO (Answer Engine Optimization) tool.

---

## Step 1: `/eng-init` (one-time setup)

Scaffolds a CLAUDE.md with all 9 engineering principles, Do/Don't rules, feature structure patterns, and doc references for your stack. Every future AI session in this project reads this file first.

Run once per project. The principles compound — every session benefits.

---

## Step 2: `/eng-spec citation-tracking` (planning)

You describe a vague idea: "I want to track if a brand shows up in AI search results."

The skill detects the idea is still forming and enters **exploration mode** — asking focused questions one at a time:

```
> What's the core problem you're solving?
  - Brand owners don't know if AI recommends them (selected)

> Which AI platforms should we track in v1?
  - ChatGPT + Perplexity — two platforms to validate the approach

> How should we check for citations?
  - Not sure yet — need to explore
```

When a question needs deeper thinking, the skill enters **plan mode** — explores APIs, compares approaches, and presents a recommendation:

```
Option A: DataForSEO AI Search API — they handle the prompting,
          you get structured responses. Simpler, dependency on third party.

Option B: Direct API calls to ChatGPT + Perplexity APIs.
          Full control, but more complexity to maintain.

Recommendation: Option A for v1.
Principle #1 (simplicity) — DataForSEO handles the hard part.
Principle #5 (Type 2) — you can switch to direct APIs later.
```

Once the idea is clear, the skill writes a full spec — context, user flow, acceptance criteria, edge cases, proposed file structure.

Then it **spawns a sub-agent to stress-test the spec with fresh eyes** (Principle #7: the builder shouldn't be the reviewer). The stress-test agent reads the spec cold, loads the project's CLAUDE.md, explores the codebase, and challenges the design:

```
Verdict: address these first

1. Response time < 30s for 10 prompts — is that realistic?
   DataForSEO queries take 5-15s each. 10 sequential queries
   could be 50-150s. Parallelize or reduce v1 limit.

2. No validation on prompt input — what if someone submits
   empty prompts or 100 prompts? Add to acceptance criteria.

3. API key management — spec says "no auth" but DataForSEO
   needs a key. Ensure .env is in .gitignore.
```

You see the spec + stress-test findings together. Adjust, approve, save to `specs/citation-tracking.md`.

**Principles in play:** #1 (simplicity — chose the simpler approach), #2 (YAGNI — only two platforms, not three), #5 (Type 2 — reversible API choice), #7 (fresh eyes on the spec), #8 (stress-test caught the verification gap).

---

## Step 3: `/eng-build` (execution + reflection)

New session. Claude reads the CLAUDE.md and the approved spec. The planning is done — execution should feel easy.

```
Building citation tracking from the approved spec.
6 acceptance criteria, 2 platforms, DataForSEO integration.

Schema and business logic done. Queries run in parallel...
API route done — thin, validates with Zod, delegates to lib/...
Frontend done — results per prompt per platform, error states handled...

Acceptance criteria:
- [x] User can input a brand name and up to 10 prompts
- [x] System queries ChatGPT and Perplexity via DataForSEO
- [x] Results show cited/not cited per prompt per platform
- [x] Error states handled: API down, rate limit, no results
- [x] Results stored in database for historical tracking
- [x] Response time < 30s for 10 prompts (parallel queries)
```

The feature follows the project's structure conventions — thin routes, business logic in `lib/`, shared Zod schema, feature-specific UI components.

While building, the skill holds judgment questions in mind — am I discovering this abstraction or forcing it? What breaks if this fails? Can someone understand this without opening multiple files? These aren't steps, they're a lens. If something feels off, it pauses and flags.

After shipping, the skill prompts reflection — but only if something surprised you. What trade-off did we make? What would we do differently? Learnings get routed to the right place: CLAUDE.md for project conventions, `docs/learnings.md` for codebase quirks, or the playbook's Learnings Log for timeless insights.

**Principles in play:** #1 (simple structure — 6 focused files), #4 (documented trade-offs in the spec), #8 (verified against acceptance criteria).

---

## Step 4: `/deslop` (clean up with fresh eyes)

```
Removed 3 unnecessary comments, one redundant try/catch,
replaced an `as any` cast with a proper type, inlined a
single-use helper. 4 changes.
```

`/deslop` spawns a fresh sub-agent that reads the code without the build session's context or bias (Principle #7). It removes AI slop — comments that restate the obvious, defensive checks that can't trigger, type casts that hide real issues — and simplifies unnecessary complexity like redundant logic or single-use abstractions. The sub-agent follows the project's CLAUDE.md conventions, not its own preferences.

---

## Step 5: `/eng-check` (last gate before shipping)

```
Verdict: looks good

- Simplicity: 6 files, clean separation, each does one thing
- Routes thin — validates and delegates
- Schema shared between frontend and backend
- Feature names mirror across layers
- Error handling at boundary with structured errors
- Checked against project engineering principles.
```

The review checks against the same principles the spec was written against. If the spec was good and the build followed it, the review should be clean. Issues here mean the planning was incomplete.

**Principles in play:** all 9 — the checklist covers every principle.

---

## Step 6: You review (Principle #9: own what you ship)

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
/eng-init          Set up project principles (once)
     |
/eng-spec          Explore → Spec → Stress-test
     |
/eng-build         Execute from the approved spec + reflect
     |
/deslop            Clean up with fresh eyes (sub-agent)
     |
/eng-check         Verify against principles
     |
You review         Own what you ship
```

Most of the work happens before and after writing code. The spec forces planning. The stress-test catches assumptions. The build follows the spec and reflects on what surprised you. Deslop brings fresh eyes to clean up. Eng-check verifies quality. And at the end, you understand what you shipped.

The principles aren't abstract — they're embedded in every step.
