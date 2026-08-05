# Database Security Patterns

## Least Privilege Roles

```sql
-- Application role: limited to what it needs
CREATE ROLE app_user LOGIN PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE shipments_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Read-only role for analytics/reporting
CREATE ROLE readonly_user LOGIN PASSWORD 'another_password';
GRANT CONNECT ON DATABASE shipments_db TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Migration role: full DDL
CREATE ROLE migrator LOGIN PASSWORD 'migration_password';
GRANT ALL PRIVILEGES ON DATABASE shipments_db TO migrator;
```

## Row-Level Security (RLS)

Enforce tenant isolation at the database level:

```sql
-- Enable RLS
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their customer's data
CREATE POLICY customer_isolation ON shipments
    USING (customer_id = current_setting('app.current_customer_id')::uuid);

-- Admin bypass
CREATE POLICY admin_all ON shipments
    TO admin_role
    USING (TRUE);
```

```go
// Set tenant context in Go before queries
_, err = pool.Exec(ctx,
    "SET LOCAL app.current_customer_id = $1", customerID)
```

## Parameterized Queries (Always)

```go
// NEVER: SQL injection vulnerable
query := fmt.Sprintf("SELECT * FROM shipments WHERE id = '%s'", userInput)

// ALWAYS: parameterized
row := pool.QueryRow(ctx, "SELECT * FROM shipments WHERE id = $1", userInput)

// GORM is parameterized by default — but beware raw SQL
db.Where("id = ?", userInput).Find(&payment)   // safe
db.Where(fmt.Sprintf("id = '%s'", userInput))  // UNSAFE — never do this
```

## Sensitive Data Handling

```sql
-- PII masking view (expose only last 4 digits of tracking ref)
CREATE VIEW v_shipments_masked AS
SELECT
    id,
    customer_id,
    quantity,
    'XXXX-XXXX-XXXX-' || RIGHT(tracking_ref, 4) AS tracking_ref_masked,
    created_at
FROM shipments;

-- Grant access to masked view only
GRANT SELECT ON v_shipments_masked TO readonly_user;
REVOKE SELECT ON shipments FROM readonly_user;
```

## Encryption

```sql
-- pgcrypto for column-level encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive field
UPDATE users
SET ssn_encrypted = pgp_sym_encrypt(ssn, current_setting('app.encryption_key'))
WHERE id = $1;

-- Decrypt
SELECT pgp_sym_decrypt(ssn_encrypted, current_setting('app.encryption_key')) AS ssn
FROM users WHERE id = $1;
```

## Audit Logging

```sql
-- Automatic audit trail via trigger
CREATE OR REPLACE FUNCTION audit_log_trigger() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_at)
    VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD) END,
        CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) END,
        NOW()
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_shipments
    AFTER INSERT OR UPDATE OR DELETE ON shipments
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

## Connection Security

```bash
# DATABASE_URL with SSL
DATABASE_URL="postgres://app_user:password@host:5432/shipments_db?sslmode=require"

# Verify SSL
EXPLAIN SELECT 1;  -- run: SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid();
```
