# Playwright Locator Priority

1. `page.getByRole('button', { name: /submit/i })` — BEST, most resilient
2. `page.getByLabel('SKU')` — for form fields
3. `page.getByText('Total: 100 units')` — for visible text
4. `page.getByPlaceholder('SKU-00000')` — for inputs with placeholder
5. `page.getByTestId('submit-btn')` — LAST RESORT, use only when above fail

## NEVER Use
- CSS selectors as primary: `.order-form button.primary`
- XPath: `//div[@class='item']//button`
- nth-child or positional selectors

## Wait Strategies
- `await expect(locator).toBeVisible()` — wait for visibility
- `await page.waitForResponse(u => u.url().includes('/api/'))` — wait for API
- Never `page.waitForTimeout(5000)` — flaky, slow

## API Mocking (MSW-like at network level)
```typescript
await page.route('**/api/shipments', async route => {
  await route.fulfill({ status: 201, json: { id: 'test', status: 'label_created' } });
});
```
