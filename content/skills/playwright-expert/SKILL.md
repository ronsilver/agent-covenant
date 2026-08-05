---
name: playwright-expert
description: "E2E testing automation with Playwright: resilient locators (role + name), network interception and API mocking, integrated accessibility testing (axe-core), parallel execution with sharding, trace and video generation for flaky failure debugging, visual testing with screenshots, and CI integration with custom reporters. Use when writing end-to-end tests for web application user flows, implementing page object models, running visual regression tests, fixing flaky tests, or automating browser interactions. Trigger: E2E testing, Playwright, visual testing, browser automation, flaky test, trace debugging. Do NOT trigger for: unit testing, API integration testing, mobile app testing."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Playwright Expert

**E2E testing: resilient locators, network mocking, visual testing, and CI.**

## Locator Strategy (priority order)
```typescript
// 1. Role + accessible name (BEST — most resilient)
page.getByRole("button", { name: "Submit" })

// 2. Text content
page.getByText("Welcome, User")

// 3. Label association
page.getByLabel("Email address")

// 4. Placeholder
page.getByPlaceholder("Enter your name")

// 5. Test ID (LAST RESORT)
page.getByTestId("submit-form-btn")
```

## Form Submission Test
```typescript
test("complete form submission flow", async ({ page }) => {
  await page.goto("/contact");
  await page.getByLabel("Full name").fill("Jane Doe");
  await page.getByLabel("Email address").fill("jane@example.com");
  await page.getByLabel("Message").fill("Hello, I have a question.");
  await page.getByRole("button", { name: "Submit" }).click();
  await expect(page.getByText("Submission received")).toBeVisible();
  await expect(page.getByTestId("confirmation-id")).toBeVisible();
});
```

## API Mocking
```typescript
// Mock external API response
await page.route("**/api/submissions", async (route) => {
  await route.fulfill({
    status: 201,
    json: { id: "sub_test123", status: "received" }
  });
});
```

## Visual Testing
```typescript
test("contact page matches baseline", async ({ page }) => {
  await page.goto("/contact");
  await expect(page).toHaveScreenshot("contact-page.png", {
    maxDiffPixelRatio: 0.01   // 1% tolerance
  });
});
```

## CI Configuration
```yaml
- name: Playwright E2E
  run: npx playwright test --shard=${{ matrix.shard }}/4
  strategy:
    matrix:
      shard: [1, 2, 3, 4]
- uses: actions/upload-artifact@v4
  with:
    name: playwright-traces
    path: test-results/
```

## Constraints
- NEVER use CSS selectors/XPath as primary locators (brittle)
- NEVER use `page.waitForTimeout(5000)` — use `waitForSelector`/`waitForResponse`
- NEVER skip trace generation on failure (`trace: "on-first-retry"`)
- ALWAYS mock external dependencies at network level
- NEVER rely on test order (tests must be independent)
- NEVER test non-critical flows at E2E level (push to lower pyramid tiers)

## Overview

Playwright powers E2E testing strategy with resilient locators, API mocking, visual regression, and parallel sharding. Tests run against user flows and critical business paths with trace/video capture for flaky failure debugging.

## Quick Reference

| Feature | API | Use Case |
|---|---|---|
| Locators | `getByRole`, `getByText`, `getByLabel` | Resilient element targeting |
| Network Mock | `page.route()` | Stub external API responses in E2E |
| Visual | `toHaveScreenshot()` | UI regression detection |
| CI | Sharding + trace upload | Parallel execution across 4 shards |

## Workflow

1. Write locators using role + accessible name (highest priority)
2. Mock external APIs at the network level with `page.route()`
3. Add assertions for success states, error messages, and loading states
4. Configure trace capture: `trace: "on-first-retry"` in `playwright.config.ts`
5. Set up visual snapshot baselines for key pages
6. Run locally: `npx playwright test` with `--shard` for parallel execution
7. Integrate into CI with artifact upload for traces on failure

## Anti-patterns

FAIL: Using CSS selectors or XPath as primary locators
PASS: Always prefer `getByRole`, `getByText`, or `getByLabel`

```typescript
// FAIL:
await page.locator(".btn-primary").click();
await page.locator("#submit-btn").click();

// PASS:
await page.getByRole("button", { name: "Submit" }).click();
await page.getByText("Welcome, User").click();
```

FAIL: Using `page.waitForTimeout(5000)` for async operations
PASS: Use explicit `waitForSelector`, `waitForResponse`, or `waitForURL`

```typescript
// FAIL:
await page.waitForTimeout(3000);
await expect(page.getByText("Success")).toBeVisible();

// PASS:
await page.waitForResponse(resp => resp.url().includes("/api/submissions") && resp.status() === 201);
await expect(page.getByText("Success")).toBeVisible();
```

FAIL: Skipping trace collection, then unable to debug CI failures
PASS: Always enable `trace: "on-first-retry"` in playwright config

```typescript
// FAIL: no trace config → flaky test in CI → no evidence
// PASS:
use: { trace: "on-first-retry" }
```

## References

- [Playwright Best Practices](https://playwright.dev/docs/best-practices) (last_verified: 2025-02)
- [Playwright CI Integration](https://playwright.dev/docs/ci) (last_verified: 2024-12)
- [axe-core Accessibility Testing](https://www.deque.com/axe/) (last_verified: 2024-10)

- [references/ci-setup.md](references/ci-setup.md)
- [references/locator-strategy.md](references/locator-strategy.md)

## Verification Checklist

- [ ] Locators use role + accessible name as primary strategy (never CSS/XPath)
- [ ] External APIs mocked at network level with `page.route()`
- [ ] Trace capture enabled: `trace: "on-first-retry"` in playwright config
- [ ] Visual snapshot baselines set for key pages with `toHaveScreenshot()`
- [ ] Tests are independent (no test-order dependencies)
- [ ] Sharding configured for parallel CI execution across at least 2 shards
- [ ] No `page.waitForTimeout()` used (prefer explicit `waitForSelector`/`waitForResponse`)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Test flaky in CI but passes locally | Timing issue — async operation not awaited before assertion | Replace `waitForTimeout` with `waitForResponse` or `waitForSelector` on expected element |
| Visual test fails with large diff | Baseline screenshot stale after intentional UI change | Run with `--update-snapshots` to update baseline; commit new snapshot to repo |
| `page.route()` mock not intercepting requests | Route pattern does not match actual request URL | Check browser devtools network tab for exact URL; use wildcard pattern (`**/api/**`) |
| Visual test fails on CI but passes locally (known issue: font rendering differs) | CI and local environments use different font rendering engines | Run `--update-snapshots` on CI with consistent Docker image; freeze system fonts in CI config |
| [WARN] Limitation: Playwright element selectors fail for shadow DOM components | Default locator strategy cannot pierce closed shadow roots | Use `locator('css=my-component').shadowRoot.locator()` for shadow DOM; prefer `getByRole` which works across shadow boundaries in Chromium |
