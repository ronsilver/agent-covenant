# ARIA Design Patterns

## Modal Dialog
Focus trap: Tab cycles within modal, Shift+Tab to last. On close: restore focus to trigger.

## Tab Panel
```html
<button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">Card</button>
<button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2">Cash payment</button>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1" hidden>...</div>
```
Arrow keys switch tabs. Only active panel visible.

## Alert / Status
- `role="alert"` = assertive, immediate announcement
- `aria-live="polite"` = queued, waits for current to finish
- `aria-atomic="true"` = announce entire region, not just changes

## Skip Navigation
```html
<a href="#main" class="skip-link">Skip to main content</a>
<main id="main">...</main>
```
First focusable element. Visible on focus only.

## Testing Tools
- axe-core CLI: `npx @axe/core/cli https://checkout.example.com`
- Playwright: `injectAxe(page)` + `checkA11y(page)`
- Keyboard: Tab/Shift+Tab/Enter/Escape through full page
- Screen readers: VoiceOver (macOS), NVDA (Windows), TalkBack (Android)
- 200% zoom test: no horizontal scrollbar
