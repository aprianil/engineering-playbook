# Race Conditions

> When two things happen at almost the same time and the result depends on which one finishes first. The bugs are subtle, hard to reproduce, and easy to create when vibe coding.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [Engineering Learnings & Playbook](Engineering Learnings & Playbook.md) system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook — don't duplicate what's already there.

---

## What Is a Race Condition

A race condition happens when your code assumes things will happen in a certain order, but they don't. Two operations "race" each other — and the wrong one wins.

They're especially common when vibe coding because you're moving fast and not thinking about "what if this happens twice" or "what if the response comes back late."

---

## The Most Common Race Conditions You'll Hit

### 1. Double Submit

User clicks a button twice before the first request finishes.

```
Click 1 → POST /api/charge → processing...
Click 2 → POST /api/charge → processing...
Both succeed → user charged twice
```

**Fix — disable the button:**

```jsx
function PayButton() {
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handlePay = async () => {
    if (isSubmitting) return
    setIsSubmitting(true)
    try {
      await fetch('/api/charge', { method: 'POST' })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Button onClick={handlePay} disabled={isSubmitting}>
      {isSubmitting ? 'Processing...' : 'Pay Now'}
    </Button>
  )
}
```

**Belt and suspenders — also protect the backend:**

```javascript
// Make the operation idempotent with a unique key
app.post('/api/charge', async (req, res) => {
  const { idempotencyKey, amount } = req.body

  // Check if this exact request was already processed
  const existing = await db.charges.findByKey(idempotencyKey)
  if (existing) return res.json(existing)  // return same result, don't charge again

  const charge = await stripe.charges.create({ amount })
  await db.charges.save({ idempotencyKey, result: charge })
  res.json(charge)
})
```

The frontend sends a unique key per action. If the same key arrives twice, the backend returns the first result instead of processing again. This is called **idempotency** — doing something twice has the same result as doing it once.

---

### 2. Stale Response Overwrites Fresh Data

User types in a search box. Each keystroke fires an API call. Responses arrive out of order.

```
Type "b"   → request 1 sent (slow server)
Type "bi"  → request 2 sent
Type "bil" → request 3 sent

Request 3 returns → shows results for "bil" ✓
Request 2 returns → shows results for "bi" (overwrites "bil"!) ✗
Request 1 returns → shows results for "b" (overwrites again!) ✗
```

User searched for "bil" but sees results for "b."

**Fix — track the latest request:**

```javascript
let latestRequestId = 0

async function search(query) {
  const requestId = ++latestRequestId
  const response = await fetch(`/api/search?q=${query}`)
  const data = await response.json()

  // Only update if this is still the latest request
  if (requestId === latestRequestId) {
    setResults(data)
  }
  // Otherwise discard — a newer request already won
}
```

**In React, the same pattern with useEffect cleanup:**

```jsx
useEffect(() => {
  let cancelled = false

  async function fetchResults() {
    const res = await fetch(`/api/search?q=${query}`)
    const data = await res.json()
    if (!cancelled) setResults(data)
  }

  fetchResults()
  return () => { cancelled = true }  // cleanup cancels stale requests
}, [query])
```

The `cancelled` flag ensures that when the query changes before the previous request returns, the old result gets thrown away.

---

### 3. Two Users Edit the Same Data

```
User A loads document (version 1) at 10:00am
User B loads document (version 1) at 10:01am
User A saves their edit at 10:05am → version 2
User B saves their edit at 10:06am → overwrites version 2 with changes based on version 1
User A's work is gone. No error. No warning.
```

This is called the **lost update problem**.

**Fix — optimistic concurrency with version numbers:**

```javascript
async function saveDocument(docId, content, loadedVersion) {
  const current = await db.documents.findById(docId)

  if (current.version !== loadedVersion) {
    throw new Error(
      "This document was edited by someone else since you opened it. " +
      "Please refresh to see their changes before saving."
    )
  }

  await db.documents.update(docId, {
    content,
    version: loadedVersion + 1
  })
}
```

User B's save now fails with a helpful message instead of silently destroying User A's work. The `version` field is the guard.

---

### 4. State Update After Unmount

User navigates away from a page before an API call finishes. The response arrives and tries to update state on a component that no longer exists.

```
User opens billing page → API call starts
User navigates to dashboard → billing component unmounts
API returns → tries to setState on unmounted billing component
React warning or unexpected behavior
```

**Fix — same cleanup pattern as the search example:**

```jsx
useEffect(() => {
  let cancelled = false

  async function loadBilling() {
    const data = await fetchBillingData()
    if (!cancelled) setBillingData(data)
  }

  loadBilling()
  return () => { cancelled = true }
}, [])
```

Or use `AbortController` to actually cancel the fetch:

```jsx
useEffect(() => {
  const controller = new AbortController()

  async function loadBilling() {
    try {
      const res = await fetch('/api/billing', { signal: controller.signal })
      const data = await res.json()
      setBillingData(data)
    } catch (err) {
      if (err.name !== 'AbortError') throw err  // ignore cancelled requests
    }
  }

  loadBilling()
  return () => controller.abort()
}, [])
```

`AbortController` doesn't just ignore the result — it actually cancels the network request, saving bandwidth and server resources.

---

### 5. Multiple Rapid State Updates

Clicking a counter button very fast, or toggling something rapidly:

```javascript
// Bug — each click reads the CURRENT state, not the latest
const handleLike = () => {
  setLikes(likes + 1)  // if likes is 0 and you click 3 times fast,
                        // all three read likes as 0, result is 1 not 3
}

// Fix — use the function form to read the LATEST state
const handleLike = () => {
  setLikes(prev => prev + 1)  // each update builds on the previous one
}
```

The function form `prev => prev + 1` always reads the most recent value, even if multiple updates are queued.

---

## How to Spot Race Conditions

When building or reviewing code, ask:

```
- What happens if this runs twice at the same time?
- What happens if the response comes back after the user has moved on?
- What happens if two users do this at the same time to the same data?
- What happens if the network is slow and responses arrive out of order?
- What happens if the user clicks this very fast?
```

These are the questions from the playbook's "While Building" checklist — "What happens when this input is empty/null/unexpected?" and "What else does this change touch?" Race conditions are the timing version of those questions.

---

## The Patterns That Prevent Race Conditions

| Problem | Pattern | Implementation |
|---------|---------|---------------|
| Double submit | Disable + idempotency | Disable button on click, idempotency key on backend |
| Stale responses | Request tracking | Increment a counter or use `cancelled` flag in useEffect |
| Lost updates | Optimistic concurrency | Version number on the record, check before saving |
| Update after unmount | Cleanup on unmount | `cancelled` flag or `AbortController` in useEffect |
| Rapid state updates | Functional updates | `setState(prev => ...)` instead of `setState(value)` |

---

## When Vibe Coding, Watch For These

Race conditions are the #1 subtle bug source when moving fast. You won't see them in happy-path testing because they depend on timing. They show up when:

- Real users are slower or faster than you expected
- Network is flaky or slow
- Multiple users are active at once
- The AI call takes 3 seconds instead of 0.5 seconds

Before shipping a feature, take 30 seconds and ask: **"What if two of these happen at the same time?"** That one question catches most race conditions.

---

*Race conditions are timing bugs. The code is "correct" — it just assumes things happen in order. The fix is always the same: don't assume order, verify it.*
