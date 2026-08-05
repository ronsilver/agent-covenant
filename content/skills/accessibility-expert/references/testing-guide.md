# Accessibility Testing Guide

## Automated (axe-core)
```bash
# CLI
npx @axe-core/cli https://checkout.example.com

# Playwright integration
import { injectAxe, checkA11y } from 'axe-playwright';
await injectAxe(page);
const results = await checkA11y(page, null, { detailedReport: true });
```
- Catches ~30% of issues (color contrast, missing alt, duplicate IDs, invalid ARIA)
- Does NOT catch: keyboard traps, focus order, meaningful sequence, screen reader UX

## Keyboard Testing (Manual — MOST IMPORTANT)
1. Tab through entire page: can you reach every interactive element?
2. Shift+Tab: can you go backward through all elements?
3. Enter/Space: can you activate every button/link?
4. Escape: closes modals, dropdowns, tooltips?
5. Arrow keys: navigate radio groups, tabs, sliders, selects?
6. Focus never disappears into a trap
7. Focus always visible (never outline:none without replacement)

## Screen Reader Testing
| OS | Screen Reader | Browser |
|---|---|---|
| macOS | VoiceOver (built-in) | Safari |
| Windows | NVDA (free) | Firefox/Chrome |
| Windows | JAWS (paid) | Chrome |
| Android | TalkBack (built-in) | Chrome |
| iOS | VoiceOver (built-in) | Safari |

### VoiceOver Quick Test
1. Cmd+F5 to activate
2. Ctrl+Option+Right Arrow to navigate
3. Ctrl+Option+Space to activate
4. Verify heading hierarchy (VO rotor: Ctrl+Option+U -> Headings)
5. Verify landmarks (VO rotor -> Landmarks)

## Zoom Testing
- 200% browser zoom: everything readable, no horizontal scroll?
- 400%: critical content still accessible?

## Color Tools
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Chrome DevTools: inspect element -> Styles -> click color swatch -> contrast ratio
- axe DevTools: auto-checks contrast on audit
