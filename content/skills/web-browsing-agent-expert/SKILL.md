---
name: web-browsing-agent-expert
description: "Web browsing for AI agents: driving a headless browser (Playwright, Puppeteer) from agent tooling, navigation and page-state grounding, DOM extraction and structured data capture, form interaction, session and cookie management, anti-bot mitigation awareness, and safe browsing rules (no PII exfiltration, respect robots and terms). Use when building a browsing tool or MCP server for an agent, teaching an agent to navigate and read web pages, extracting structured content from dynamic sites, or handling login walls and pagination in agent workflows. Trigger: web browsing agent, headless browser, Playwright MCP, Puppeteer, browser automation for agents, DOM extraction, page navigation, session management. Do NOT trigger for: end-to-end UI testing of an application (use playwright-expert); writing standalone scraping scripts for data pipelines (use python-expert); fetching a single public URL (use the fetch tool)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: ai-agents
  status: beta
trigger: on-demand
---

# Web Browsing Agent Expert

**Headless browser control for AI agents: navigate, read, act, and verify.**

## Overview

Agents that browse the web drive a headless browser and turn page state into grounded context. This skill covers the browse loop (navigate, wait, extract, act, verify), DOM extraction and structured data capture, form and session handling, and the safety rules that keep browsing within terms of service and privacy boundaries.

**What this skill covers:**
- Browser tooling for agents: Playwright and Puppeteer control, page wait strategies
- Navigation and page-state grounding: selectors, DOM snapshots, accessibility-tree reading
- Structured extraction: tables, lists, JSON-LD, and dynamic content after interaction
- Session and cookie management: login walls, storage state, per-task isolation
- Anti-bot awareness: detection signals and compliant pacing

**What this skill does NOT cover:**
- End-to-end UI testing of an application under development (use `playwright-expert`)
- Standalone scraping pipelines and data processing (use `python-expert`)
- Single-page fetches that do not require a browser (use the built-in fetch tool)

**Limitation:** sites change layouts often; selectors break and require re-grounding on every new session.

## Quick Reference

| If you need to | Do this | See section |
|---|---|---|
| Load a dynamic page | Navigate, then wait for a stable selector before reading | Workflow |
| Read a table into structured data | Extract rows via a table selector and validate column count | Workflow |
| Handle a login wall | Reuse a saved storage state for the session only | Workflow |
| Avoid bot detection | Keep request pacing human-like and do not parallel-burst | Guidelines |
| Error: selector never matches | Re-ground on the accessibility tree or full DOM | Troubleshooting |

## Workflow

### Primary Path: Browse Loop

```
1. Navigate: open the target URL in a fresh browser context.
2. Wait: wait for the key selector or network idle, with a timeout.
3. Extract: read the DOM or accessibility tree and capture the needed data.
4. Act: fill forms, click, or paginate as required.
5. Verify: assert the page changed as expected before extracting again.
6. Finish: close the context and discard cookies between tasks.
```

**Before starting, confirm:**
- [ ] The target site allows automated access (robots, terms of service)
- [ ] No personal data will be captured or stored

**After completing, verify:**
- [ ] Extracted data matches the visible page
- [ ] Browser context closed and no session state persisted

### Alternative Path: Stored-State Session

```
1. Load a saved storage state for the authenticated session.
2. Navigate to the protected page and verify the login indicator.
3. Perform the task, then discard the context.
```

## Guidelines

### DO

| Rule | Why |
|---|---|
| Wait for explicit signals, not fixed sleeps | Fixed sleeps make runs flaky and slow |
| Ground every extraction in the current page state | Stale DOM causes wrong data |
| Isolate sessions per task | Prevents cross-task data leakage |

### DO NOT

| Anti-pattern | Correct approach | Why |
|---|---|---|
| Scraping at maximum concurrency | Respect robots and throttle requests | Aggressive bursts trigger blocks and violate terms |
| Storing full page HTML with embedded tokens | Extract only the fields you need | Reduces stored attack surface |
| Reusing one browser profile across tasks | Fresh context per task | Session bleed leaks data between tasks |

## Anti-patterns

### WRONG: Fixed sleep before reading
```python
await page.goto(url)
await asyncio.sleep(3)
text = await page.inner_text("body")
```
### CORRECT: Waiting for a stable signal
```python
await page.goto(url)
await page.wait_for_selector("#results", timeout=10000)
rows = await page.query_selector_all("table tbody tr")
```
**Why:** Fixed sleeps break when the network is slow or fast; explicit waits are deterministic.

### WRONG: Blind pagination loop
```python
while True:
    scrape(page)
    await page.click("button.next")
```
### CORRECT: Bounded pagination with a stop condition
```python
seen = set()
while len(seen) < 500:
    seen.update(extract_ids(page))
    if not await page.locator("button.next").is_visible():
        break
    await page.click("button.next")
```
**Why:** An unbounded loop can run forever on sites with infinite scroll.

### WRONG: Sharing a login session across unrelated tasks
```python
context = browser.new_context(storage_state="auth.json")  # reused everywhere
```
### CORRECT: Scoping the session to one task
```python
async with browser.new_context(storage_state="auth.json") as ctx:
    await run_single_task(ctx)
# context closed; auth state not reused
```
**Why:** A leaked authenticated session turns one compromised task into a wider incident.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Selector never matches | Page is an SPA that renders after interaction | Wait on a stable selector or use the accessibility tree |
| Empty table after extraction | Data loads via API after initial render | Trigger the API call, then re-extract |
| Login wall loops | Cookie consent or anti-bot interstitial | Accept consent, then wait; do not bypass security controls |
| Known edge case: headless detection | Site fingerprints headless browsers | Use the production browser channel, never stealth hacks |
| Workaround for rate-limited sites | Too many parallel contexts | Serialize tasks and add jitter between runs |

## Verification Checklist

Before claiming "done", confirm ALL:

- [ ] Navigate, wait, extract, act, verify loop completed for every page
- [ ] Extracted data validated against the rendered page
- [ ] Browser contexts closed and no session state persisted
- [ ] No personal data captured beyond the task requirement

## References

| Resource | URL | Last verified |
|---|---|---|
| Playwright documentation | https://playwright.dev/docs/intro | 2026-08-09 |
| Puppeteer documentation | https://pptr.dev/ | 2026-08-09 |
| Master catalog items: #45, #138, #146 | see docs/reference/master-catalog-mapping.md | - |
