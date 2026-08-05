# Next.js 14 Architecture Patterns

## App Router Structure
```
app/
  layout.tsx          # root layout (Server Component)
  page.tsx            # home page
  submit/
    page.tsx          # Server Component (data fetch)
    EntryForm.tsx   # Client Component ("use client")
    actions.ts        # Server Actions
  api/
    items/
      route.ts        # API route handler
```

## Server Components (default — no "use client")
- Fetch data directly (async component)
- Access DB, filesystem, env vars
- NO useState, useEffect, event handlers
- NO browser-only APIs

## Client Components ("use client")
- useState, useEffect, useContext
- Event handlers (onClick, onChange)
- Browser APIs (localStorage, geolocation)
- NEVER at layout level (breaks entire subtree)

## Server Actions
```typescript
// app/submit/actions.ts
"use server";
export async function createEntry(formData: FormData) {
    const amount = formData.get("amount");
    // validate + process on server
    revalidatePath("/submit");
}
```

## Data Fetching (no useEffect)
```typescript
// Server Component
export default async function SubmitPage() {
    const config = await fetchCustomerConfig();  // direct fetch
    return <EntryForm config={config} />;
}

// Client Component
function EntryForm({ config }) {
    const { data } = useQuery({ queryKey: ['items'], queryFn: fetchItems });
}
```

## Route Handlers
```typescript
// app/api/items/route.ts
export async function POST(request: Request) {
    const body = await request.json();
    const validated = itemSchema.parse(body);
    // process...
    return Response.json({ id: "item_123" }, { status: 201 });
}
```
