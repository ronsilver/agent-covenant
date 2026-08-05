# Test Fixture & Data Strategies

## Fixture Design Principles
- Self-contained: each test creates what it needs
- Deterministic: same fixture = same test result
- Minimal: only data needed for the specific test
- Isolated: no shared mutable state between tests
- Named: descriptive fixture names tell what they represent

## Factory Patterns
### Go (table-driven)
```go
func validShipmentRequest() ShipmentRequest {
    return ShipmentRequest{
        Quantity: 1000,
        Currency: "USD",
        Customer: "cust_test123",
    }
}
```

### Python (FactoryBoy / fixtures)
```python
import factory
class ShipmentFactory(factory.Factory):
    class Meta: model = Shipment
    score = 1000
    category = "standard"
    status = "pending"

# Override for edge cases
edge_case = ItemFactory(score=99999999)
```

### TypeScript (test data builders)
```typescript
const validShipment = (overrides?: Partial<ShipmentRequest>): ShipmentRequest => ({
    quantity: 1000,
    category: "standard",
    customerId: "cust_test",
    ...overrides,
});

// Edge case
const maxQuantity = validShipment({ quantity: 99999999 });
```

## Synthetic Data Rules
- NEVER use real user data (PII) in test fixtures
- NEVER use production database dumps
- NEVER hardcode real API keys or tokens in fixtures
- Use `test_` or `sandbox_` prefixes for IDs
- Rotate test data periodically (prevent staleness)
- Anonymize: if you need production-like data, use Faker/chance.js

## Database Fixtures
```python
@pytest.fixture
async def db_session():
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine) as session:
        yield session
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```
ALWAYS create and drop schema per test. NEVER share database state between tests.
