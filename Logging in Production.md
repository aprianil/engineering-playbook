# Logging in Production

> Logging is not debugging leftovers. It's permanent, intentional code that tells you what your app is doing when you can't see it running.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [Engineering Learnings & Playbook](Engineering Learnings & Playbook.md) system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## Two Kinds of Logging

**Debugging logs** — temporary. Add them to find a bug, delete them before shipping:
```javascript
console.log("here")        // ← remove before shipping
console.log(data)           // ← remove before shipping
```

**Production logs** — permanent. Part of the codebase, shipped intentionally:
```javascript
logger.info("[billing] Subscription created", { userId, plan, subscriptionId })
logger.error("[billing] Payment failed", { userId, error: err.message })
```

Production logs run every time a real user hits your code. They exist so you can understand what happened when something breaks — without being there when it happened.

---

## Log Levels

Think of these as urgency:

| Level | When to use | Example |
|-------|------------|---------|
| `debug` | Step-by-step detail, dev only | "Validating input fields" |
| `info` | Something expected happened | "Subscription created for user abc123" |
| `warn` | Unusual but not broken | "Retry attempt 2 for Stripe API call" |
| `error` | Something broke, needs attention | "Payment failed: card expired" |

In production, you usually see `info`, `warn`, and `error`. Turn on `debug` only when investigating a specific issue.

---

## What to Log

### Always log:
- API requests coming in (who, what endpoint, what data)
- API responses going out (success or failure)
- Important business actions (user signed up, payment processed, plan changed)
- Errors with full context (what failed, who was affected, what input caused it)

### Sometimes log (debug level):
- Function inputs/outputs when tracing a specific flow
- State changes in complex logic
- External API calls (what you sent, what came back)

### Never log:
- Passwords, tokens, or secrets
- Full credit card numbers
- Personal data that shouldn't be in plain text
- Every single line of execution (too noisy to be useful)

---

## Bad vs Good Logging

```javascript
// Bad — tells you nothing
console.log("here")
console.log(data)
console.log("working")

// Good — labeled, contextual, traceable
logger.info("[POST /api/billing] Request received", { userId: req.user.id })
logger.info("[POST /api/billing] Validating input", { plan: body.plan })
logger.error("[POST /api/billing] Failed", { userId: req.user.id, error: err.message })
```

The good version tells you: which endpoint, what action, who was involved, and what went wrong. When a user reports "I can't upgrade my plan," you search the logs and find the answer in seconds instead of hours of guessing.

---

## Logging in Real Code

Production logging is woven into the business logic — it's part of the feature, not an afterthought:

```javascript
export async function POST(req) {
  const { userId, plan } = await req.json()

  logger.info("[billing] Upgrade requested", { userId, plan })

  try {
    const subscription = await stripe.subscriptions.create({ /* ... */ })

    logger.info("[billing] Upgrade successful", {
      userId,
      subscriptionId: subscription.id
    })

    return Response.json({ success: true })
  } catch (err) {
    logger.error("[billing] Upgrade failed", {
      userId,
      error: err.message,
      plan
    })

    return Response.json({ error: "Payment failed" }, { status: 400 })
  }
}
```

The API response serves the user. The logs serve you when something goes wrong.

---

## Request IDs

When multiple users hit your app at the same time, their logs mix together. A request ID ties all logs from one action together:

```javascript
// Middleware that tags every request
function addRequestId(req, res, next) {
  req.requestId = crypto.randomUUID()
  next()
}

// Every log includes it
logger.info(`[${req.requestId}] [billing] Upgrade requested`, { userId })
logger.info(`[${req.requestId}] [billing] Upgrade successful`, { subscriptionId })
```

User reports an issue → you find their request ID → filter logs → see the entire journey. No noise from other users.

---

## Structured Logging

Logging objects instead of strings makes logs searchable:

```javascript
// String (harder to search)
console.log("[billing] Failed for user abc123: Card expired")

// Structured (searchable, filterable)
logger.error({
  endpoint: "POST /api/billing",
  userId: "abc123",
  action: "create_subscription",
  error: "card_expired",
  plan: "pro"
})
```

With structured logs you can query: "Show me all card_expired errors this week" or "How many billing failures in the last 24 hours?"

---

## Logging AI Calls

AI calls are expensive, non-deterministic, and hard to debug. Regular code gives the same output for the same input — you can reproduce bugs easily. AI doesn't. The same prompt can return different responses every time. Without logs, you can't investigate what went wrong.

### What to log for AI calls

```javascript
const startTime = Date.now()

// Before the call
logger.info("[ai] Generating summary", {
  requestId,
  userId,
  model: "claude-sonnet-4-6",
  promptTemplate: "billing-summary-v2",
  inputLength: userContent.length
})

// After the call
logger.info("[ai] Summary generated", {
  requestId,
  userId,
  inputTokens: response.usage.input_tokens,
  outputTokens: response.usage.output_tokens,
  latency: Date.now() - startTime,
  estimatedCost: calculateCost(response.usage)
})

// On failure
logger.error("[ai] Summary failed", {
  requestId,
  userId,
  error: err.message,
  retryCount: attempt
})
```

### AI-specific things worth tracking

| What | Why |
|------|-----|
| Prompt template name (or a summary) | See what triggered a bad response |
| Token usage (input + output) | Track costs before you get a surprise bill |
| Latency | Know if AI calls are slowing down the user experience |
| Model used | Compare quality and cost between models |
| Estimated cost per request | Set budget alerts, catch runaway spending |
| Retry attempts | Know if the AI service is flaky |
| Fallback triggered | Know when users got the non-AI experience |

### Cost tracking

Without logging, end of month: "$2,400 Anthropic bill" and nobody knows which feature or which users caused it. With logging, you can query: "Which feature costs the most?" "Which users generate the most tokens?" "Is our prompt too long?"

### Logging prompts — be careful

Log which prompt template was used and the input length, but don't log full user content if it contains personal data. Use debug level for full prompts — only in dev when investigating issues.

```javascript
// Safe for production
logger.info("[ai] Request", {
  promptTemplate: "billing-summary-v2",
  inputLength: userContent.length
})

// Debug only — not in production if content has personal data
logger.debug("[ai] Full prompt", { prompt })
```

### Fallback logging

If your AI feature has a fallback (and it should), log when it kicks in:

```javascript
try {
  const summary = await generateAISummary(data)
  logger.info("[ai] Summary generated", { method: "ai", latency })
} catch (err) {
  logger.warn("[ai] Falling back to template summary", {
    error: err.message,
    userId
  })
  const summary = generateTemplateSummary(data)
}
```

This tells you how often users get the degraded experience — and whether your AI integration is reliable enough.

---

## Where Logs Go

| Environment | Where | Tool |
|-------------|-------|------|
| Development | Terminal | `console.log` is fine |
| Production | Logging service (searchable, stored) | Vercel Logs, Axiom, Logtail / Better Stack, Datadog |

The key: production logs need to be searchable. If you can only read them by SSHing into a server and running grep, that's a problem.

---

## How to Start

You don't need a logging framework on day one. Start with a simple helper:

```javascript
function log(level, context, message, data = {}) {
  console[level](`[${context}] ${message}`, data)
}

// Usage
log('info', 'POST /api/billing', 'Request received', { userId: '123' })
log('error', 'POST /api/billing', 'Failed', { error: err.message })
```

Label, context, data. When you outgrow this, move to a proper logging library. But this alone puts you ahead of most projects.

---

*Logging is like insurance — boring to set up, invaluable when you need it. The 3am production bug that takes 5 minutes to find instead of 5 hours? That's what good logging buys you.*
