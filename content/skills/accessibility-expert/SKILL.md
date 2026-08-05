---
name: accessibility-expert
description: "WCAG 2.2 compliance verification (levels A/AA/AAA) based on the 4 POUR principles: semantic HTML, ARIA roles and landmarks, keyboard navigation, color contrast (WCAG 1.4.3), testing with axe-core and screen readers (NVDA/JAWS/VoiceOver). Use when working on a11y compliance, semantic HTML, keyboard navigation, focus management, ARIA roles, screen reader support, color contrast, or fixing accessibility audit failures. Trigger: a11y compliance, semantic HTML, keyboard navigation. Do NOT trigger for: general UI design questions without accessibility context."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Accessibility Expert

**WCAG 2.2: semantic HTML, ARIA, keyboard nav, contrast, screen readers.**

## POUR Principles
- Perceivable: info available to senses (alt text, captions, contrast)
- Operable: UI usable via keyboard + assistive tech
- Understandable: predictable, clear language, error suggestions
- Robust: works across browsers + assistive tech (valid HTML + ARIA)

## Semantic HTML First
```html
<!-- CORRECT: semantic -->
<nav aria-label="Main navigation">...</nav>
<main><h1>Submit</h1></main>
<button type="button">Submit</button>

<!-- NEVER: div soup -->
<div onclick="submit()">Submit</div>
```

## Focus Management
- Visible focus ring: `:focus-visible { outline: 2px solid #005A9C; }`
- Tab order matches visual order. No `tabindex > 0` (never positive values)
- Modals: trap focus, restore on close
- NEVER `outline: none` without alternative indicator

## ARIA Rules
1. No ARIA is better than bad ARIA — semantic HTML first
2. `aria-label` on interactive elements without visible text
3. `aria-live="polite"` for dynamic content updates
4. `aria-expanded`, `aria-selected` on interactive widgets

## Color Contrast (WCAG 1.4.3)
| Level | Text | Large Text |
|---|---|---|
| AA | 4.5:1 | 3:1 |
| AAA | 7:1 | 4.5:1 |

## Testing
```bash
npx axe-core --chrome-options="headless" https://form.example.com
```
- axe-core for automated checks (~30% of issues). Manual keyboard testing for the rest.
- Screen reader testing: VoiceOver (macOS), NVDA (Windows), TalkBack (Android)
- ALWAYS test with 200% zoom + keyboard-only navigation

## Constraints
- NEVER use `tabindex > 0` (breaks tab order)
- NEVER remove `:focus-visible` outline without visible alternative
- NEVER use color alone to convey information (add icons/text)
- ALWAYS provide text alternatives for non-text content (`alt`, `aria-label`)
- ALWAYS test keyboard navigation (Tab/Shift+Tab/Enter/Escape)

## Overview

Verify WCAG 2.2 compliance (levels A/AA/AAA) based on the 4 POUR principles: semantic HTML, ARIA roles and landmarks, keyboard navigation, color contrast (WCAG 1.4.3), and testing with axe-core and screen readers (NVDA/JAWS/VoiceOver).

## Quick Reference

| Requirement | WCAG Criterion | Minimum Standard |
|---|---|---|
| Color contrast | 1.4.3 | AA: 4.5:1 text, 3:1 large text |
| Keyboard navigation | 2.1.1 | All functionality via keyboard |
| Focus visible | 2.4.7 | Visible focus ring required |
| Alt text | 1.1.1 | Every non-text element |
| ARIA landmarks | 1.3.1 | Semantic regions: nav, main, complementary |

## Workflow

1. Run axe-core automated scan to catch ~30% of issues
2. Manually test keyboard navigation: Tab, Shift+Tab, Enter, Escape
3. Test with 200% zoom and no viewport resizing loss
4. Verify color contrast ratios meet AA minimum (4.5:1)
5. Test with screen reader: VoiceOver (macOS) or NVDA (Windows)
6. Fix issues by priority: POUR principles (Perceivable first)

## Anti-patterns

FAIL: Using div soup instead of semantic HTML
```html
<!-- BAD: no semantic meaning -->
<div class="nav"><div onclick="nav()">Home</div></div>
<div class="main"><div class="title">Submit</div></div>

<!-- GOOD: semantic landmarks -->
<nav aria-label="Main"><a href="/">Home</a></nav>
<main><h1>Submit</h1></main>
```

FAIL: Removing focus outline without providing alternative
```css
/* BAD: invisible focus */
*:focus { outline: none; }

/* GOOD: visible custom focus indicator */
:focus-visible { outline: 2px solid #005A9C; outline-offset: 2px; }
```

FAIL: Using color alone to convey information
```html
<!-- BAD: color-only status indicator -->
<span style="color: red">Failed</span>

<!-- GOOD: icon + text + color -->
<span style="color: red">FAIL Failed</span>
```

## References

- WCAG 2.2 specification: https://www.w3.org/TR/WCAG22/ (last_verified: 2026-05)
- axe-core documentation: https://www.deque.com/axe/ (last_verified: 2026-05)
- WebAIM contrast checker: https://webaim.org/resources/contrastchecker/ (last_verified: 2026-05)

- [references/aria-patterns.md](references/aria-patterns.md)
- [references/aria-testing.md](references/aria-testing.md)
- [references/testing-guide.md](references/testing-guide.md)
- [references/wcag-checklist.md](references/wcag-checklist.md)

## Verification Checklist
- [ ] axe-core automated scan run with zero violations
- [ ] Color contrast verified against AA minimum (4.5:1 text, 3:1 large text)
- [ ] Keyboard navigation tested: Tab, Shift+Tab, Enter, Escape across all interactive elements
- [ ] Screen reader tested (VoiceOver/NVDA) for all content and interactive flows
- [ ] No `tabindex > 0` present; no `outline: none` without visible alternative
- [ ] 200% zoom test: no content loss, no horizontal scrolling at 320px viewport

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| axe-core reports missing `alt` attributes on images | Decorative images missing `alt=""` or informative images without description | Add `alt=""` for decorative, meaningful `alt` text for informative images |
| Focus is invisible during keyboard navigation | `:focus-visible` outline removed without providing alternative indicator | Add `:focus-visible { outline: 2px solid #005A9C; outline-offset: 2px; }` |
| Color contrast fails AA minimum (4.5:1) | Text color + background do not meet ratio threshold | Adjust text color or background; use WebAIM contrast checker to validate |
| Screen reader skips dynamic content | No `aria-live` region for content updates after page load | Add `aria-live="polite"` to container of dynamic content |
| axe-core misses contrast issues on gradients/background images (known bug) | Static color contrast check does not analyze CSS gradients or background images | Manually verify contrast on gradient backgrounds with WebAIM contrast checker; test with actual rendering |
