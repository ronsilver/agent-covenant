# Redis Cache Patterns

Cache-aside, write-through, and pub/sub for this project.

## Cache-Aside (Read-Through)

```python
value = redis.get(key)
if not value:
    value = db.query(...)
    redis.setex(key, ttl=300, value=serialize(value))
return deserialize(value)
```

## Pub/Sub

```python
redis.publish("order:events", json.dumps({"event": "ShipmentReserved", "txn_id": "..."}))
```

## Constraints

- ALWAYS invalidate cache on write.
- ALWAYS namespace keys.
- NEVER use Redis as primary store for transactional data.
