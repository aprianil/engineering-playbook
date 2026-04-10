# Designing Frontends for Performance

> A mental model for shipping fast frontends that stays true across framework generations. Three decisions determine most of what matters. The rest is noise.

## Why this deep dive exists

Most frontend performance advice is a list of tricks tied to the framework of the year. Memoize this, lazy-load that, defer the other thing. Useful, but perishable — and easy to mistake for a plan.

The real lesson under all of those tricks is smaller and more stable: **performance is a byproduct of three architectural decisions made correctly, plus measurement.** Everything else is a footnote.

This note holds the principles. For the tool-specific implementation (Next.js 16, React Compiler, shadcn, etc.), see the project's `CLAUDE.md` — those ship with expiration dates.

---

## The mental model: three decisions, in priority order

### 1. Where rendering happens — server vs client

Every component lives somewhere on a spectrum from "rendered on the server, zero JS shipped" to "rendered in the browser with a full interactive runtime." The default should be: **server by default, client at the leaves.**

A server-rendered card with one interactive button isn't a client component — the button is. If you mark the whole card as client, every child becomes client too, and the bundle grows. The discipline is: push the "use client" boundary as far down the tree as possible.

This decision compounds. Every feature inherits the default. If you get this wrong in the first few components, the rest of the codebase follows.

### 2. When data arrives — parallel vs waterfall

A waterfall is "fetch A, then fetch B, then fetch C" when B and C don't depend on A. Each waterfall adds a network round-trip. This is the #1 cause of slow apps and the most common mistake — and the framework cannot fix it for you.

The fix has two forms:
- **Parallel fetching**: `Promise.all()` (or equivalent) for anything independent. Start everything that doesn't depend on something else at the same time.
- **Streaming**: wrap slow sections in Suspense boundaries so the fast sections render without waiting. Users see the fast stuff immediately and the slow stuff streams in.

Before optimizing anything else, find and kill the waterfalls.

### 3. How much JS ships to the browser — bundle size

Every KB of client JS is parse + compile + execute cost on mid-tier mobile. This is what makes an app feel sluggish *even when the network is fast*. You can have a 100ms API response and still feel slow if the bundle is 2 MB.

The discipline is: ship less. That means:
- Server-render by default (decision #1 feeds this one).
- Import directly, not through barrel files. Barrels defeat tree-shaking.
- Lazy-load anything heavy that isn't above the fold — charts, editors, date pickers, modals.
- Defer third-party scripts (analytics, error tracking) until after the main app is interactive.

Bundle size is the single biggest lever on perceived performance after the first paint.

**The point of the three-decision frame:** get these right and you rarely need micro-optimization. Get them wrong and no amount of memoization saves you. Spend your attention here.

---

## Two supporting principles

### Perceived speed > real speed

Users don't wait for work they can see is happening. An optimistic UI update that reverts if it fails feels instant, even though the real work takes seconds. A streaming skeleton feels fast, even though the first byte hasn't changed. Instant navigation between already-loaded pages feels magical, even though it's just cache.

This is the principle behind local-first's appeal. And it's achievable without adopting a sync engine — a well-used query library plus optimistic mutations plus streaming gets you 80% of the feel at 5% of the complexity.

*Flag: this may prove to be a tactic rather than a principle. Revisit when enough product experience has been accumulated to tell.*

### Architecture fit > architecture trend

Local-first, server-rendered, SPA, MPA, edge-rendered — each fits a different product shape. The question isn't "what's the best architecture?" but "what is this product shaped like?"

| Product shape | Architecture fit |
|---|---|
| High-frequency writes + multi-user collaboration + offline-first feel | Local-first is worth its complexity (Linear, Figma) |
| Reporting + occasional actions + single-user | Conventional server-rendered wins (most B2B SaaS) |
| Content-heavy, read-mostly, SEO-driven | Static with selective dynamic (marketing sites, docs) |
| Keystroke-fast editing surface | Local state + occasional sync (text editors, design tools) |

Choose for what the product actually does, not for what makes a good blog post. This is the same taste muscle as [[Choosing a Tech Stack]] and Type 1 vs Type 2 decisions.

---

## What good looks like

| Good | Bad |
|---|---|
| Server-rendered by default, client code at interactive leaves | Whole pages marked as client components "just in case" |
| Independent fetches run in parallel; slow sections streamed | Each request awaits the previous one; whole page blocks on the slowest query |
| Bundle budget defined in CI and enforced on merge | "We'll check performance before launch" |
| One chart library, dynamic-imported, never above the fold | Three chart libraries, all eagerly loaded on the home screen |
| Optimistic UI for writes the user expects to be instant | Every mutation shows a spinner; the product feels slow even when it isn't |
| Performance measured on real users at p75 (Core Web Vitals) | Lighthouse scores on the author's MacBook |
| Polish and performance shipped together from day one | "Perf pass" scheduled after the feature ships |

---

## Apply in this order

When reviewing a frontend for performance, check in this order. Fix the earlier ones before touching the later ones — optimizing re-renders on an app with a 2 MB bundle is wasted effort.

1. **Eliminate waterfalls.** Are independent fetches running in parallel? Are slow sections in Suspense boundaries?
2. **Reduce bundle size.** What's shipping to the client that doesn't need to? Are barrels killing tree-shaking? Are heavy components above the fold?
3. **Reconsider the server/client boundary.** Are components marked client when they could be server? Is the client boundary as low as possible?
4. **Add optimistic UI where the user expects instant.** Writes the user expects to see reflected immediately.
5. **Measure real users.** Core Web Vitals at p75. Set a budget in CI.
6. **Only then: re-render optimization.** And with a modern React Compiler, most of this is automatic. Don't habitually add memoization.

The order is not negotiable. Most frontends I've seen optimize in reverse — memoizing re-renders in an app that has a 2 MB bundle and three waterfalls. That's how you burn a week and move nothing.

---

## Measurement: the only honest way to know

The rule from the playbook is **verify, don't trust** — same thing, applied to pixels and milliseconds.

Every frontend project should ship with:
- **Real-user measurement** of Core Web Vitals at the 75th percentile. Lab scores are a sanity check, not a measurement.
- **A bundle budget in CI.** Fails the build if a route exceeds a threshold. The single most effective guard against bundle creep.
- **A first-paint budget.** How quickly the shell appears on a cold load.

Performance decisions made on intuition are usually wrong. Set the budget before writing the code, not after.

---

## The design system is performance infrastructure

A strong design system — tokens, shared primitives, consistent interaction patterns — is a compounding investment. It prevents the "let's just add Framer Motion for this one thing" bundle creep. It lets you ship polish without shipping complexity. It gives server components a safe set of primitives to use without reaching for client-side libraries.

Invest in the design system up front — but in **tokens and primitives**, not in custom components. Most shadcn-style libraries give you a server-safe primitive layer for free. Customize what needs customizing, copy-paste the rest.

---

## Anti-patterns

Things that look like they should help but usually don't:

- **Manual memoization everywhere.** Modern React compilers handle this. Manual `useMemo`/`useCallback` makes code harder to read and rarely moves the needle.
- **Micro-benchmarks in isolation.** You're optimizing the thing you can measure, not the thing that matters.
- **Optimizing the home screen in dev mode.** Dev mode is 5-10x slower than production. Measure production builds on real devices.
- **Adding a state management library before feeling the pain.** Server state + URL state + form state covers 90% of everything.
- **Choosing architecture based on what's trending.** Reread "Architecture fit > architecture trend" above.
- **"We'll polish performance before launch."** You won't. Performance, like UX polish, is a constraint on every ship, not a final phase.

---

## Prefer derivation over synchronization — the useEffect smell

Most `useEffect` calls are a sign of something else going wrong. The hook's original intent was "sync with an external system on mount" — but teams reach for it to mirror state, relay events, and chain updates. Each misuse is the seed of the next infinite loop, race condition, or "why did this run?" debugging session.

The React team themselves now warn about this — see [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect). Teams like Factory have gone further and banned direct `useEffect` entirely, exposing only a named `useMountEffect` wrapper for the rare legitimate case. That's the move that makes the rule stick: a single opt-in escape hatch you have to consciously reach for.

The principle is timeless: **effects are implicit synchronization; prefer explicit derivation, events, or libraries.**

### The five replacements

**1. Derive state, don't sync it.** If a value can be computed from other values, compute it — don't store it in `useState` and sync it via an effect.

```typescript
// ❌ Two renders, stale-then-filtered
useEffect(() => setFiltered(products.filter(p => p.inStock)), [products]);

// ✅ One render, one expression
const filtered = products.filter(p => p.inStock);
```

**2. Use data-fetching libraries.** Effect-based fetching reinvents cancellation, caching, and staleness — badly. Use a query library (SWR, TanStack Query) or RSC-based fetching.

```typescript
// ❌ Race condition risk, no cache, no retry
useEffect(() => { fetchProduct(id).then(setProduct); }, [id]);

// ✅ Library handles it
const { data } = useQuery(['product', id], () => fetchProduct(id));
```

**3. Event handlers, not effects.** If a user click triggers work, put the work in the handler. Don't set a flag that an effect watches.

```typescript
// ❌ Effect as action relay
useEffect(() => { if (liked) { postLike(); setLiked(false); } }, [liked]);

// ✅ Direct
<button onClick={() => postLike()}>Like</button>
```

**4. `useMountEffect` for one-time external sync.** The rare legitimate case — DOM integration, third-party widget lifecycles, browser API subscriptions. Wrap it in a named hook so intent is explicit:

```typescript
function useMountEffect(fn: () => void | (() => void)) {
  useEffect(fn, []);
}
```

**5. `key` for reset, not dependency choreography.** If a component should "start fresh" when an ID changes, use React's remount semantics directly — don't write an effect that tears down and rebuilds.

```typescript
// ✅ key forces clean remount
<VideoPlayer key={videoId} videoId={videoId} />
```

### The smell tests

You're about to reach for `useEffect`. Before you do:
- Is this value derivable from other state or props? → Derive it inline.
- Is this a fetch? → Use a query library.
- Is this a response to a user action? → Put it in the event handler.
- Is this resetting state when an ID changes? → Use `key`.
- Is this genuinely "sync with an external system on mount"? → Use `useMountEffect`.

If none of the above, you might have a real effect. Most of the time, you don't.

### Why this matters more with AI coding

`useEffect` is the hook agents reach for by default — it "looks right," it compiles, and it appears to work in the happy path. The failure modes (race conditions, infinite loops, stale closures) only surface under specific timing, so tests often pass and reviewers miss them. A hard rule ("no direct `useEffect`") turns this from a judgment call into a mechanical check, which is exactly the kind of guardrail AI can enforce and humans can verify in review.

This connects to [[Race Conditions]] — effects are the #1 source of timing bugs in React code — and to the "verify, don't trust" principle. Banning the hook is a structural guardrail, not a style preference.

---

## Perishable: how this applies in 2026 (revisit when it ages)

The timeless principles above don't change. The tools do. As of April 2026:

- **React Server Components** are stable and the default in Next.js. Use them.
- **React Compiler** is stable and handles ~80% of manual memoization. Turn it on; don't precompile `useMemo`/`useCallback` into habits.
- **Next.js 16** made caching opt-in (`"use cache"`) and introduced Cache Components + PPR (Partial Prerendering). The pattern for data-heavy pages: static shell + streamed dynamic sections via Suspense.
- **Core Web Vitals thresholds**: LCP <2.5s, INP <200ms, CLS <0.1 at p75. Competitive sites aim well below those.
- **Local-first sync engines** (Zero, ElectricSQL, InstantDB) are interesting but only fit specific product shapes. Read the Linear sync engine blog for architectural taste, not as an adoption decision.

When the framework changes, update this section. The principles above should still apply.

---

## Essential resources

- [Vercel's React Best Practices](https://www.infoq.com/news/2026/02/vercel-react-best-practices/) — 69 rules in 8 categories, prioritized by impact. The priority order is the most valuable part.
- [Next.js 16 release notes](https://nextjs.org/blog/next-16) — the current state of the tooling.
- [Core Web Vitals](https://web.dev/vitals/) — Google's measurable definition of "fast enough."

> [!tip]- Further reading
> - [Scaling the Linear Sync Engine](https://linear.app/blog/scaling-the-linear-sync-engine) — local-first architecture in production
> - [React Server Components in practice](https://react.dev/reference/rsc/server-components) — the mental model for server/client boundaries
> - [Interaction to Next Paint](https://web.dev/blog/inp-cwv-launch) — why INP matters more than the old FID metric

---

*Principles in this note should outlive any specific framework. Tools and thresholds in the "perishable" section will age — revisit when something feels outdated.*
