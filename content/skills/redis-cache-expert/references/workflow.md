# Redis Workflow

Standard workflow for adding Redis caching.

1. Identify hot read path (measured, not assumed).
2. Choose data structure + pattern (cache-aside vs write-through).
3. Define TTL (short for volatile data, longer for reference data).
4. Implement with connection pool (never new connection per request).
5. Add cache invalidation on write path.
6. Monitor: `INFO stats`, `MONITOR`, hit/miss ratio.

## Constraints

- NEVER cache without TTL.
- ALWAYS handle `ConnectionError` / `TimeoutError` with fallback.
