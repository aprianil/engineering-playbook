# Anatomy of a Well-Structured Feature

> How a single feature should be structured across layers — seven timeless patterns observed across five production codebases in different languages and frameworks.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [Engineering Learnings & Playbook](Engineering%20Learnings%20&%20Playbook.md) system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## The Big Idea

Part 0 of the playbook covers *project* structure — how to organize folders, where features live, how dependencies flow. This deep dive is one zoom level deeper: **how a single feature is built internally across layers.**

These patterns were observed by navigating five production codebases:
- **Dub** — Next.js, REST API, Prisma (link attribution platform)
- **Documenso** — Remix, tRPC, Prisma (document signing)
- **Papermark** — Next.js, REST API, Prisma (document sharing)
- **Plane** — Django + React (project management)
- **Cal.com** — Next.js, tRPC, Prisma (scheduling)

Different languages, different frameworks, different teams. Same seven patterns in every mature codebase.

---

## The Seven Patterns

### 1. Thin Routes, Thick Logic

API routes should only validate input and delegate to business logic that lives separately. Routes are the receptionist, not the doctor.

**Why it matters:** If the logic for "create a link" lives inside the API route, you can't reuse it from a CSV import, a background job, or a different API version. Extract the logic, and any entry point can call it.

**What it looks like:**
```
Route file (thin):
  validate input → call business logic → return response

Business logic file (thick):
  the actual work — database writes, transformations, side effects
```

### 2. One Schema as the Contract

Define the shape of your data once. Frontend and backend both reference it. No drift, no "the API changed but the form didn't."

**Why it matters:** When a field name changes, it should break at build time — not silently in production. A shared schema catches mismatches before users ever see them.

**Every language has its version:** Zod (JavaScript), Django Serializers (Python), Pydantic (Python), JSON Schema, etc.

### 3. Wrap Cross-Cutting Concerns, Don't Copy Them

Auth, permissions, error handling — anything every route needs should be handled once in a wrapper or base class, not duplicated per file.

**Why it matters:** Copy-pasted auth checks mean you'll eventually forget one. A wrapper makes security structural — you can't accidentally ship an unprotected route.

**What it looks like across languages:**
- JavaScript: wrapper functions (`withWorkspace`), tRPC procedures (`authenticatedProcedure`)
- Python: base classes (`BaseViewSet`), decorators (`@allow_permission`)
- The pattern is the same: write it once, apply it everywhere.

### 4. Mirror Feature Names Across Layers

If the feature is "billing," it should be `api/billing/`, `lib/billing/`, and `use-billing.ts`. Predictable naming means you always know where to look — no searching.

**Why it matters:** When something breaks, you find the right file in seconds. When building, you know exactly where new code goes. This is feature-based architecture (Part 0) applied one level deeper — not just "organize by feature" but "name consistently across layers."

### 5. Side Effects Happen After the Response

Webhooks, analytics, notifications, audit logs — the user doesn't wait for work they didn't ask for. Respond first, do housekeeping after.

**Why it matters:** If sending a webhook takes 500ms, that's 500ms the user stares at a spinner for something they don't care about. Background the work.

**What it looks like across languages:**
- JavaScript: `waitUntil()`, background jobs (Trigger.dev, Inngest)
- Python: `.delay()` with Celery, task queues
- The pattern: respond immediately, queue the rest.

### 6. Structured Errors, Handled at the Boundary

Define custom error types with codes, throw them anywhere, handle them once at the top. Individual routes don't format error responses — one central handler does.

**Why it matters:** Without this, every route has its own error formatting — different shapes, different status codes, inconsistent messages. One handler means consistent error responses across your entire API.

**What it looks like:**
```
Anywhere in the code:
  throw new AppError("LIMIT_EXCEEDED", "You've hit your plan limit")

One central handler:
  catches AppError → formats → returns { error: { code, message }, status: 400 }
  catches unknown  → logs     → returns { error: "Something went wrong", status: 500 }
```

### 7. Wiring Files Do Zero Logic

Routers, URL configs, layouts, providers — these files compose pieces together but contain no business logic themselves. They read like a table of contents for the codebase.

**Why it matters:** When a wiring file contains logic, you can't tell at a glance what the app does. When it's pure composition, you open one file and see the entire API surface — every route, every feature, every provider.

---

## The Flow Through All Seven

Every feature in every mature codebase follows this path:

```
UI (form/button)
  → Route (thin — validates input, checks auth via wrapper)
    → Business logic (thick — the actual work)
      → Database (via ORM)
    → Response sent to user
    → Side effects (background — webhooks, analytics, notifications)
  → Errors caught at boundary → consistent error response
```

The route file, business logic file, and schema file all share the same feature name across layers.

---

## Comparison Across Five Codebases

| Principle | Dub (Next.js) | Documenso (Remix) | Papermark (Next.js) | Plane (Django+React) | Cal.com (Next.js) |
|---|---|---|---|---|---|
| 1. Thin routes | `withWorkspace` → `lib/api/` | `authenticatedProcedure` → `lib/server-only/` | Fat routes (all logic inline) | ViewSet → serializer + ORM | tRPC → Services → Repositories |
| 2. Schema as contract | Zod in `lib/zod/schemas/` | Zod in `.types.ts` per route | Partial (some Zod, mostly manual) | Django Serializers | Zod DTOs at every boundary |
| 3. Auth wrapped once | `withWorkspace` wrapper | `authenticatedProcedure` | Copy-pasted per route | `BaseViewSet` + `@allow_permission` | tRPC procedures + page-level checks |
| 4. Feature name mirroring | `api/links/`, `lib/api/links/`, `use-links.ts` | `document-router/`, `lib/server-only/envelope/`, `trpc.document.*` | SWR hooks yes, backend inconsistent | `views/issue/`, `serializers/issue.py`, `services/issue/`, `store/issue/` | `features/bookings/` with repositories, services, hooks, components |
| 5. Side effects after response | `waitUntil()` | `triggerWebhook()` | `waitUntil()` | `.delay()` (Celery) | Trigger.dev tasks |
| 6. Structured errors | `DubApiError` with codes | `AppError` with `AppErrorCode` | `TeamError`/`DocumentError` (basic) | `BaseViewSet.handle_exception()` | `ErrorWithCode` + factory methods, auto-converted by middleware |
| 7. Wiring = zero logic | `middleware.ts`, route files | `router.ts` files | `middleware.ts`, layouts | `urls.py` | `_app.ts`, routers, layouts |

Papermark shows what happens when the patterns aren't applied consistently — a working product, but growing friction from duplicated auth, fat routes, and no shared schemas. Cal.com shows the most disciplined implementation — they codified these patterns as explicit engineering rules.

---

## Applying to Open Visibility v1

These seven patterns apply from day one, even in a small single-app project:

1. **Thin routes** — keep `app/api/citations/route.ts` thin. Put the logic in `lib/citations/`.
2. **Schema as contract** — define Zod schemas once in `lib/citations/schema.ts`, use them for both API validation and frontend types.
3. **Auth wrapper** — write one `withAuth` wrapper. Use it on every route.
4. **Feature mirroring** — `app/api/citations/`, `lib/citations/`, `features/citations/` (UI + hooks).
5. **Side effects** — if you send notifications or log analytics, use `waitUntil()` or a background queue.
6. **Structured errors** — create one `AppError` class with codes. Handle it once in a middleware or error handler.
7. **Wiring files** — keep `middleware.ts` and layout files free of business logic.

You don't need Cal.com's repository pattern or dependency injection at v1. Start with these seven. Add complexity when you feel the pain.

---

*These patterns don't directly improve UX — users don't care about your file structure. They compound into speed: a clean codebase means week 12 of building feels as fast as week 1.*
