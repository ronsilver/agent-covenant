# pt-online-schema-change

## Safe ALTER TABLE (no table lock)
```bash
pt-online-schema-change \
  --alter "ADD COLUMN total_units BIGINT NOT NULL DEFAULT 0" \
  --execute \
  D=app,t=records
```

## How It Works
1. Creates empty shadow table (_records_new)
2. Copies rows in chunks via INSERT...SELECT
3. Uses triggers to sync ongoing writes
4. Atomically swaps tables (RENAME)
5. Drops old table

## Safety
- --dry-run: preview without executing
- --max-load: pause if Threads_running > threshold
- --chunk-size: rows per copy batch (default 1000)
- NEVER run on <1M rows (direct ALTER is fine)

## For Aurora MySQL
- Works identically
- Monitor reader endpoint load during copy phase
