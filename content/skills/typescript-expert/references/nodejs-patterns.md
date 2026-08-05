# Node.js Backend Patterns (Generic)

## this project Backend Repos

| Repo | Stack | Purpose |
|---|---|---|
| `admin-ff` | Express + TypeScript | Feature flag API |
| `explore-platform` | Express | Data exploration API |
| `rudder-one` | Node.js | Event tracking pipeline |

## Complete Middleware Pipeline

```typescript
import express from "express";
import helmet from "helmet";
import cors from "cors";
import { pino } from "pino";

const app = express();

// Order matters: outer → inner
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(",") }));
app.use(helmet());
app.use(express.json({ limit: "1mb" }));
app.use(requestIdMiddleware());     // inject X-Request-ID
app.use(pinoHttp({ logger }));       // structured logging
app.use(rateLimit({ windowMs: 60_000, max: 100 }));
app.use("/v1", routes);
app.use(errorHandler);              // last — catches all errors
```

## Zod Env Validation (fail-fast)

```typescript
import { z } from "zod";

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  DB_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  ALLOWED_ORIGINS: z.string(),
});

export const env = envSchema.parse(process.env);
// Throws at startup if any var is missing/invalid
```

## Security Checklist

- [x] `helmet()` for security headers
- [x] `express.json({ limit: "1mb" })` body size limit
- [x] CORS: explicit origin list (never `*` in production)
- [x] Rate limiting: per-IP token bucket
- [x] Error handler: never leak stack traces
- [x] Zod validation on ALL request bodies
- [x] `NODE_ENV` branching (dev ≠ prod behavior)
