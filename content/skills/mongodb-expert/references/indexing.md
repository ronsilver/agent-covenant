# MongoDB Index Strategies

## ESR Rule (Equality, Sort, Range)
```javascript
db.orders.createIndex({ customer_id: 1, created_at: -1 })
// customer_id = Equality, created_at DESC = Sort
```

## Compound Index Coverage
```javascript
db.orders.createIndex({ status: 1, created_at: -1 })
// Covers: {status}, {status, created_at}, {status, created_at} sorted
// Does NOT cover: {created_at} alone
```

## Text Index
```javascript
db.orders.createIndex({ description: "text", customer_name: "text" })
// Weights: { description: 10, customer_name: 5 }
```

## TTL Index (auto-expire)
```javascript
db.sessions.createIndex({ created_at: 1 }, { expireAfterSeconds: 86400 })
```
NEVER use TTL for critical data — deletion is approximate (60s sweep).
