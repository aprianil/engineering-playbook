# Testing: When and What to Test

> A practical guide to testing for someone who ships features. Not a testing textbook, but enough to make confident decisions about what's worth testing.

---

> [!info]- Context for AI (Claude Code)
> This note is part of the [[Engineering Learnings & Playbook]] system. Follow the same editing principles: simplicity first, walk through thinking before editing, no bloat, practical tone for a designer/product builder. This file is a deep dive linked from the playbook, so don't duplicate what's already there.

---

## Why Test At All

Tests aren't about proving your code works right now. You already know it works. You just built it.

Tests are about **protecting your future self.** When you (or someone else) changes something in three months, tests catch what breaks. Without them, every change is a gamble.

---

## Types of Tests (Simple Mental Model)

Don't worry about memorizing the taxonomy. Think of it as three levels:

### Unit Tests
Test **one small piece** in isolation: a function, a utility, a calculation.

```
"Does formatCurrency(1000) return '$1,000.00'?"
"Does calculateDiscount(100, 20) return 80?"
```

- Fast to write, fast to run
- Great for pure logic: functions that take input and return output
- Don't test UI rendering or API calls

### Integration Tests
Test **how pieces work together**: a component that fetches data, an API endpoint that queries the database.

```
"When I submit the billing form, does it call the API with the right data?"
"Does the /api/billing endpoint return the correct response for a valid request?"
```

- More realistic than unit tests
- Catches bugs that happen at the seams between pieces
- Slower to write but higher confidence

### End-to-End (E2E) Tests
Test **the full user flow**, from clicking a button to seeing the result, through the entire system.

```
"Can a user sign up, log in, create a project, and see it on their dashboard?"
```

- Most realistic: tests what the user actually experiences
- Slowest to write and run, most brittle
- Use sparingly for critical paths only

---

## What to Test (The Practical Guide)

Not everything needs a test. Here's how to decide:

### Always worth testing:

```
- Business logic (calculations, pricing, permissions, rules)
  → If this breaks, users lose money or access

- Data transformations (formatting, parsing, mapping)
  → Easy to test, catches subtle bugs, pure input/output

- API endpoints that handle user data
  → Validates that the contract between frontend and backend holds

- Authentication and authorization flows
  → If this breaks, security is compromised

- Edge cases you've already been bitten by
  → If it broke once, test it so it never breaks the same way again
```

### Often not worth testing:

```
- Simple UI rendering ("does this button exist?")
  → Too brittle, breaks on every design change, low value

- Third-party library behavior
  → Trust the library's own tests. Test YOUR usage of it, not IT.

- Obvious getters/setters with no logic
  → If there's no logic, there's nothing to break

- One-off scripts or prototypes
  → You'll delete this before the test becomes useful
```

### The Rule of Thumb

**Test behavior, not implementation.** Ask "what should happen when X?" not "does this function call that function?"

```
Good test thinking:
"When a user submits an empty form, they should see a validation error"

Bad test thinking:
"When handleSubmit is called, it should call setError with 'Required'"
```

The first survives refactoring. The second breaks every time you change how validation works internally.

---

## How to Think About Test Coverage

100% coverage is not the goal. Coverage measures lines executed, not quality.

```
High coverage, low quality:
- Tests that check everything exists but verify nothing meaningful
- Tests that pass even when the behavior is wrong
- Tests that break on every change (brittle)

Lower coverage, high quality:
- Critical paths are tested end-to-end
- Business logic has unit tests with edge cases
- API contracts are verified
- You can refactor with confidence
```

Focus on: **what would hurt the most if it broke?** Test that first.

---

## A Simple Testing Workflow

This is the loop `/eng-build` runs, and it works by hand too.

```
1. Before building, every acceptance criterion names its proof
   → A test name, a command and its expected result, or a browser step
   → A criterion that can't name a proof isn't done being written
2. Build one slice
3. Ask: "What's the riskiest part of this?" and "What are the edge cases?"
   → Empty input, null values, large numbers, duplicate submissions
   → Test those first
4. Verify the slice: tests pass, the app builds, the user flow works
5. Commit. A hook runs typecheck + tests on every commit and blocks
   the commit if either fails
6. When done, tick each criterion only with its proof beside it
```

The commit hook is the one `/eng-init` sets up. Nobody has to remember to run the tests, the commit just won't land red.

**Fixing a bug?** Start with a failing guard test. Write the test that reproduces the bug, watch it fail, fix the code, watch it pass. Both runs are the proof. More in [[Debugging Mindset]].

You don't need to write tests for everything. You need to write tests for the things that matter.

### Verifying UI: Drive the Real Browser

For a UI slice, green tests aren't the finish line. "Works" means it works in a real browser. Drive the live app (for example with Playwright MCP: navigate, click, fill the form, check the console and network tabs for errors), then hand it to a fresh QA agent that didn't build it and tries to break it like a real user.

That counts as verification for the slice. It's different from writing an E2E test suite: nothing gets saved as a test file, so "use E2E sparingly" still stands.

---

## Testing in Practice (React + Next.js context)

### Unit Tests (Vitest or Jest)
```javascript
// Testing a utility function
test('formatCurrency handles zero', () => {
  expect(formatCurrency(0)).toBe('$0.00')
})

test('formatCurrency handles large numbers', () => {
  expect(formatCurrency(1000000)).toBe('$1,000,000.00')
})
```

### Component Tests (React Testing Library)
```javascript
// Testing behavior, not implementation
test('shows error when form is submitted empty', async () => {
  render(<BillingForm />)

  await userEvent.click(screen.getByRole('button', { name: /submit/i }))

  expect(screen.getByText(/required/i)).toBeInTheDocument()
})
```

### API Tests (Supertest or similar)
```javascript
// Testing the API contract
test('POST /api/billing returns 400 for missing fields', async () => {
  const response = await request(app)
    .post('/api/billing')
    .send({})

  expect(response.status).toBe(400)
  expect(response.body.error).toBeDefined()
})
```

---

## Common Testing Mistakes

| Mistake | Instead |
|---------|---------|
| Testing implementation details (which function was called) | Test observable behavior (what the user sees or what the API returns) |
| Writing tests after a bug but not understanding the root cause | Understand why it broke first, then write a test that catches the root cause |
| Mocking everything | Mock external dependencies (APIs, databases), but test your own logic for real |
| Writing tests that pass no matter what | Make sure your test actually fails when the behavior is wrong. Break it on purpose to verify |
| Treating tests as a chore to check off | Treat tests as protection for your future self |

### The AI-Written Test Trap

When an agent writes both the code and the tests, the tests can quietly prove nothing. They mock the very thing being tested, or assert that a function was called, or check a value the code returns no matter what.

One question catches it: **would this test still pass if the code under test did nothing?** If yes, it's not proof. Break the code on purpose (comment out the body, return early) and make sure the test goes red. `/eng-check` asks the same question of every criterion's named proof.

---

## Resources

- "Testing Trophy" by Kent C. Dodds (kentcdodds.com): his model for how much to invest in each testing level. Prioritizes integration tests over unit tests. Practical and opinionated.
- React Testing Library docs (testing-library.com): the philosophy here matters as much as the API: test what the user experiences, not internal state.
- "Write Tests. Not Too Many. Mostly Integration." by Kent C. Dodds: the title is the advice. Short blog post that reframes how to think about testing investment.
- Vitest docs (vitest.dev): if you're in a Vite/Next.js setup, Vitest is fast and modern. Good docs with clear examples.
- "How to Know What to Test" by Kent C. Dodds (kentcdodds.com): specifically about deciding what's worth testing. Directly relevant to your question.

---

*Tests are not proof that your code is perfect. They're a safety net that lets you change code without fear. Invest in the net where the fall would hurt most.*
