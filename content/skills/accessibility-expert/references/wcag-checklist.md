# WCAG 2.2 Compliance Checklist (Level AA)

## Perceivable
- [ ] 1.1.1 Non-text Content: all images have alt text, icons have aria-label
- [ ] 1.2.2 Captions: video content has captions
- [ ] 1.3.1 Info and Relationships: form inputs use label/for or aria-labelledby
- [ ] 1.3.2 Meaningful Sequence: tab order matches visual order
- [ ] 1.4.1 Use of Color: error states include text + icon, not color alone
- [ ] 1.4.3 Contrast (Minimum): text 4.5:1, large text 3:1
- [ ] 1.4.4 Resize Text: page works at 200% zoom without horizontal scroll
- [ ] 1.4.10 Reflow: content reflows at 320px width (mobile)
- [ ] 1.4.12 Text Spacing: line height 1.5, paragraph spacing 2x, letter spacing 0.12x

## Operable
- [ ] 2.1.1 Keyboard: all functionality available via keyboard
- [ ] 2.4.1 Bypass Blocks: skip navigation link provided
- [ ] 2.4.3 Focus Order: focus flows logically through page
- [ ] 2.4.4 Link Purpose: link text describes destination (not "click here")
- [ ] 2.4.6 Headings and Labels: headings describe content, labels describe inputs
- [ ] 2.4.7 Focus Visible: keyboard focus indicator visible on all interactive elements
- [ ] 2.5.8 Target Size: interactive targets at least 24x24px

## Understandable
- [ ] 3.1.1 Language of Page: <html lang="es"> or appropriate lang attribute
- [ ] 3.3.1 Error Identification: form errors described in text
- [ ] 3.3.2 Labels/Instructions: inputs have labels, required formats indicated
- [ ] 3.3.3 Error Suggestion: validation errors include correction suggestions
- [ ] 3.3.4 Error Prevention: financial/legal forms have review + confirm step

## Robust
- [ ] 4.1.2 Name, Role, Value: custom components expose name/role/value via ARIA
- [ ] 4.1.3 Status Messages: dynamic updates announced via aria-live regions
