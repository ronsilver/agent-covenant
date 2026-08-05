# ARIA Design Patterns

## Modal Dialog
```html
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Order</h2>
  <button aria-label="Close" onclick="closeDialog()">X</button>
</div>
```
- Trap focus inside modal (Tab cycles within, Shift+Tab to last)
- On close: restore focus to triggering element
- aria-modal="true" prevents screen reader access to background content

## Tab Panel
```html
<div role="tablist" aria-label="Fulfillment Methods">
  <button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">Standard</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2">Express</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">Standard shipment form...</div>
```
- Arrow keys switch tabs, Tab moves to panel content
- aria-selected updates on tab switch
- Only active tabpanel is focusable

## Accordion
```html
<button aria-expanded="false" aria-controls="section-1">Order Details</button>
<div id="section-1" role="region" aria-labelledby="trigger-1" hidden>...</div>
```
- aria-expanded toggles true/false
- hidden attribute hides collapsed content from screen readers

## Alert / Status
```html
<div role="alert">Order rejected: insufficient stock</div>
<div aria-live="polite" aria-atomic="true">Order status updated</div>
```
- role="alert" = assertive (immediate announcement)
- aria-live="polite" = queue announcement (waits for current to finish)
- aria-live="assertive" = interrupts current announcement

## Live Region for Dynamic Content
```html
<div aria-live="polite" aria-relevant="additions removals">
  <div>Order of 100 units confirmed</div>
</div>
```
- aria-relevant: additions | removals | text | all
- aria-atomic="true": announce entire region, not just changes

## Skip Navigation
```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content">...</main>
```
- First focusable element on page
- Visible on focus, hidden otherwise (.skip-link:not(:focus) { clip: rect(0 0 0 0) })
