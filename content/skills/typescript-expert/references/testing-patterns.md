# TypeScript/React Testing Patterns

## Component Testing (React Testing Library)
```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

test("submission flow completes", async () => {
    const user = userEvent.setup();
    render(<SubmitPage />);

    await user.type(screen.getByLabelText("SKU"), "SKU-10293");
    await user.click(screen.getByRole("button", { name: /submit/i }));

    await waitFor(() => {
        expect(screen.getByText("Submission successful")).toBeInTheDocument();
    });
});
```

## State Pattern Testing
- Loading: expect(screen.getByRole("progressbar"))
- Error: expect(screen.getByRole("alert"))
- Empty: expect(screen.getByText(/no results/i))
- Success: expect(screen.getByText(/approved/i))

## MSW (Mock Service Worker)
```typescript
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

const server = setupServer(
    http.post("/api/items", () =>
        HttpResponse.json({ id: "item_123", status: "approved" }, { status: 201 })
    )
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
```

## API Testing (supertest)
```typescript
import request from "supertest";
import app from "../src/app";

describe("POST /v1/items", () => {
    it("returns 201 on valid item", async () => {
        const res = await request(app)
            .post("/v1/items")
            .send({ amount: 1000, currency: "USD" });
        expect(res.status).toBe(201);
    });
});
```

## Never
- snapshot tests for dynamic UI
- data-testid as primary selector
- fireEvent over userEvent
- testing implementation details (internal state, private methods)
- tests that depend on execution order
