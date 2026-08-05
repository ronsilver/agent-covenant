# PostgreSQL Naming Conventions

## Tables

- **snake_case**, **plural**
- Prefix with domain if multi-tenant: `shipments_`, `customers_`

```sql
-- Good
CREATE TABLE shipments (...);
CREATE TABLE shipment_methods (...);
CREATE TABLE customer_profiles (...);

-- Bad
CREATE TABLE Shipment (...);
CREATE TABLE shipmentMethod (...);
CREATE TABLE tbl_shipments (...);
```

## Columns

- **snake_case**, descriptive
- Boolean: `is_`, `has_`, `can_` prefix
- Timestamps: `_at` suffix (always with timezone)

```sql
CREATE TABLE shipments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID NOT NULL,
    quantity        BIGINT NOT NULL,          -- always store counts as integer
    currency_code   CHAR(3) NOT NULL,         -- ISO 4217: USD, EUR
    status          TEXT NOT NULL,
    is_refunded     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ                           -- soft delete
);
```

## Indexes

```sql
-- Pattern: idx_<table>_<columns>
CREATE INDEX idx_shipments_customer_id ON shipments(customer_id);
CREATE INDEX idx_shipments_status ON shipments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_shipments_created_at ON shipments(created_at DESC);
CREATE UNIQUE INDEX idx_shipments_idempotency_key ON shipments(idempotency_key);

-- Composite: columns in selectivity order (most selective first)
CREATE INDEX idx_shipments_customer_status ON shipments(customer_id, status);
```

## Constraints

```sql
-- Pattern: <table>_<column>_<type>
ALTER TABLE shipments
    ADD CONSTRAINT shipments_customer_id_fk
        FOREIGN KEY (customer_id) REFERENCES customers(id),
    ADD CONSTRAINT shipments_quantity_positive
        CHECK (quantity > 0),
    ADD CONSTRAINT shipments_currency_valid
        CHECK (currency_code ~ '^[A-Z]{3}$');
```

## Sequences / Primary Keys

Prefer `gen_random_uuid()` for distributed systems (no coordination needed):

```sql
-- UUID (preferred for distributed systems)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Bigint sequence (preferred for high-insert single-region)
id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY
```

## Functions / Triggers

```sql
-- snake_case, verb_noun
CREATE FUNCTION update_updated_at_column() RETURNS TRIGGER ...;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON shipments ...;
```

## Schemas (Namespaces)

Use schemas to separate domains in a single database:

```sql
CREATE SCHEMA shipments;
CREATE SCHEMA customers;
CREATE SCHEMA auth;

-- Tables become:
CREATE TABLE shipments.records (...);
CREATE TABLE customers.profiles (...);
```

## Money Storage

**Always store precise values as integers (units):**

```sql
-- Good
value_units BIGINT NOT NULL   -- 1000 = $10.00

-- Bad
amount DECIMAL(10,2)           -- floating point precision issues
amount FLOAT                   -- never use float for money
```
