---
name: typescript-expert
description: "Full-stack TypeScript stack for modern projects: frontend SSR/CSR with Next.js 14 App Router and React, backend APIs with Node.js (Express/Fastify), state management with Zustand/Redux Toolkit, unit and integration testing with Vitest/Jest + React Testing Library + MSW, and static analysis with ESLint/Prettier/tsc. Use when building React components or hooks, implementing Next.js App Router or Server Components, writing Node.js REST API handlers, implementing middleware (auth, rate-limit, logging), managing client state (Zustand/RTK), writing frontend/backend tests, or running TypeScript linting/type checks. Trigger: TypeScript, Next.js, React, Zustand, Node.js, Express, Fastify, MSW, Vitest. Do NOT trigger for: Python backend development, Go microservices, iOS/mobile development."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: frontend
  status: stable
---
# TypeScript Expert

**TypeScript Stack: Next.js, React, Node.js backend, state management, testing and linting.**

## Core Stack

- Runtime: Node.js 20 LTS
- Language: TypeScript 5 (strict mode)
- Frontend: Next.js 14 (App Router) + React + Tailwind CSS
- Backend: Express 4 / Fastify 4
- State: Zustand (default) + TanStack Query / RTK Query (server cache)
- Forms: React Hook Form + Zod
- Testing: Vitest / Jest + React Testing Library + MSW (network mocking) + supertest (API)
- Linting: ESLint + Prettier + `tsc --noEmit`

## Frontend Project Structure

```
app/                    # Routes + Server Components
components/             # Shared UI
hooks/                  # Custom hooks
lib/                    # Utilities
services/               # API calls
types/                  # TypeScript types/interfaces
_components/            # Route-specific components (colocated)
```

## Backend Project Structure

```
src/
  routes/               # thin route handlers
  services/             # business logic
  middleware/            # auth, logging, error, rate-limit
  models/               # TypeScript interfaces/types
  config/               # env validation (zod)
tests/
  unit/
  integration/
```

## Server vs Client Components

- Client (`"use client"`): useState, useEffect, event handlers, browser APIs
- Server (default): data fetching, static content, headers/cookies, DB access
- NEVER `"use client"` at layout level — breaks entire subtree
- Server Components by default; add `"use client"` only at leaf level

## State Management

| Scenario | Use |
|---|---|
| Product config flow | Zustand (simple, colocated) |
| Complex dashboard | Zustand or RTK Query |
| Server cache (normalized) | RTK Query / TanStack Query |
| Form state | React Hook Form (NOT global) |
| URL state | Next.js router |

```typescript
import { create } from "zustand";
import { devtools } from "zustand/middleware";

interface FormState {
  quantity: number;
  unit: string;
  step: "review" | "processing" | "success" | "error";
  submitConfig: (config: ConfigData) => Promise<void>;
}

const useFormStore = create<FormState>()(
  devtools((set, get) => ({ /* ... */ }), { name: "app-store" })
);
```

- NEVER store raw PII in client state
- NEVER persist sensitive form data to localStorage
- ALWAYS clear form state on unmount or submission completion

## Backend Workflow

1. Validate env with `zod` at startup (fail-fast)
2. Register middleware: `cors -> helmet -> requestId -> logger -> routes -> errorHandler`
3. Route: parse -> call service -> return JSON (no business logic in handler)
4. Service: pure business logic + error wrapping
5. Error handler: never leak stack traces to client

```typescript
import helmet from "helmet";
app.use(helmet());
app.use(express.json({ limit: "1mb" }));
```

## Testing

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

const server = setupServer(
  http.post("/api/items", () => HttpResponse.json({ id: "item_123" }))
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test("shows loading state", async () => {
  const user = userEvent.setup();
  render(<SubmitButton value={1000} />);
  await user.click(screen.getByRole("button", { name: /submit/i }));
  expect(screen.getByRole("progressbar")).toBeInTheDocument();
});
```

- NEVER snapshot tests for dynamic UI — behavior assertions only
- NEVER test implementation details (internal state, private methods)
- ALWAYS query by accessible role/label (not `data-testid` as first choice)
- ALWAYS `userEvent` over `fireEvent`
- ALWAYS mock at network layer (MSW), not module imports
- ALWAYS test loading, error, and empty states
- Backend: `supertest` for integration, Jest mocks for unit

## Linting (Golden Chain)

```
prettier --check -> eslint -> tsc --noEmit
```
Stop on first failure. Never `|| true` in CI.

## Constraints

TypeScript:
- NEVER `any` — use `unknown` + type guards / `zod` validation
- ALWAYS type all props (no `any`); never `as` casts unless guarded

Frontend:
- NEVER fetch in `useEffect` — TanStack Query / RTK Query
- NEVER `"use client"` at layout level
- NEVER props drilling >3 levels — Context/Zustand
- ALWAYS validate forms with Zod
- ALWAYS handle loading/error/empty states

Backend:
- NEVER `console.log` in production — structured logger (pino/winston)
- NEVER unhandled promise rejections — always `try/catch`
- NEVER hardcode secrets — `process.env` with zod validation
- ALWAYS `helmet()` for security headers
- ALWAYS validate request bodies with zod before processing

## Security

- ALWAYS configure helmet with CSP, SRI on scripts/styles, `SameSite` cookies and `HttpOnly` flags
- ALWAYS run `eslint-plugin-security` as part of the linting golden chain
- ALWAYS run `npm audit` (or `pnpm audit`) in CI; block HIGH/Critical CVEs (OWASP A03)

## Overview

Full-stack TypeScript development for cloud-native covering Next.js 14 App Router frontend, Node.js (Express/Fastify) backend APIs, state management with Zustand and TanStack Query, and testing with Vitest/Jest + React Testing Library + MSW. Includes Server vs Client Component patterns, form validation with React Hook Form + Zod, and ESLint/Prettier/tsc linting pipeline.

## Anti-patterns

FAIL: Fetching data inside useEffect instead of using TanStack Query
```tsx
useEffect(() => { fetch('/api/items').then(setData) }, [])
```

PASS: Use TanStack Query for server state management
```tsx
const { data, isLoading } = useQuery({ queryKey: ['items'], queryFn: fetchItems })
```

FAIL: `"use client"` at layout level (breaks entire subtree server rendering)
```tsx
"use client";
export default function RootLayout({ children }) { return <html>{children}</html> }
```

PASS: Use `"use client"` only at leaf component level
```tsx
// layout.tsx (server) — no "use client"
// components/EntryForm.tsx (leaf client)
"use client";
export function EntryForm() { ... }
```

FAIL: Storing access tokens in localStorage (XSS vulnerable)
```tsx
localStorage.setItem('token', jwt)
```

PASS: Store tokens in memory with silent refresh or HttpOnly cookies
```tsx
const tokenRef = useRef<string | null>(null)
```

FAIL: Using `any` type instead of proper types
```tsx
function processEntry(data: any) { ... }
```

PASS: Use `unknown` with type guards or Zod validation
```tsx
function processEntry(data: unknown) {
    const parsed = itemSchema.parse(data)
}
```

## References

| Resource | URL | Last verified |
|---|---|---|
| Next.js App Router docs | https://nextjs.org/docs/app | 2026-04 |
| Zustand state management | https://github.com/pmndrs/zustand | 2026-04 |
| React Testing Library | https://testing-library.com/docs/react-testing-library/intro | 2026-03 |
| MSW (Mock Service Worker) | https://mswjs.io/docs/ | 2026-03 |

- [references/nextjs-patterns.md](references/nextjs-patterns.md)
- [references/nodejs-patterns.md](references/nodejs-patterns.md)
- [references/testing-patterns.md](references/testing-patterns.md)

## Verification Checklist

- [ ] Golden chain passed: `prettier --check` → `eslint` → `tsc --noEmit`
- [ ] `"use client"` only at leaf component level (never in layout)
- [ ] All props typed (no `any`); `unknown` + type guards used instead of `as` casts
- [ ] Data fetching uses TanStack Query / RTK Query (not `useEffect`)
- [ ] Tokens stored in memory or HttpOnly cookies (not localStorage)
- [ ] Request bodies validated with Zod before processing in backend handlers
- [ ] Loading, error, and empty states handled in all components
- [ ] Structured logger used (not `console.log` in production)
- [ ] helmet CSP/SRI/SameSite/HttpOnly configured; `eslint-plugin-security` and `npm audit` clean

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Server Component throws error accessing browser API | Component rendered on server (no `"use client"`) but uses `window`, `localStorage`, etc. | Add `"use client"` directive; move browser-only code to `useEffect` |
| ESLint passes but `tsc --noEmit` fails with type errors | `any` types used or Zod schema doesn't match TypeScript types | Replace `any` with `unknown` + Zod validation; keep Zod schemas as single source of truth |
| Zustand store persists sensitive form data after unmount | Store not cleaned on unmount or submission completion | Add `reset()` action to store; call on `useEffect` cleanup or submission terminal state |
| Next.js server action returns 500 with no stack trace (known issue: server action error serialization) | Server actions serialize errors; stack is hidden in production | Use `console.error` inside action before throw; check server logs (Vercel/CloudWatch) for full error |

| [WARN] Zod `safeParse` does not strip unknown keys; validated object fails downstream type assertion | `safeParse` validates shape but does not strip extra fields; downstream code expects exact type | Use `zod.strip()` or implement `strict()` on schema; explicitly destructure known fields before usage |
| use client component imported into a server component breaks the entire tree | Server Component renders client component but passes server-only data (Date, Buffer, Stream) as props | Serialize server data to plain JSON before passing to client component; use serialize() helper |
| Limitation: Zod discriminatedUnion requires literal discriminant field; dynamic discriminants not supported | Zod discriminatedUnion only works with literal string types as discriminant; enum or runtime values rejected | Use z.union() with custom superRefine instead of discriminatedUnion for dynamic discriminants |
