# Python Testing Patterns

## pytest Fixtures
```python
import pytest
from httpx import AsyncClient, ASGITransport

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.mark.anyio
async def test_create_payment(client):
    response = await client.post("/payments", json={"amount": 1000, "currency": "USD"})
    assert response.status_code == 201
```

## Parametrize
```python
@pytest.mark.parametrize("currency,expected_status", [
    ("USD", 201), ("EUR", 201), ("EUR", 422), ("", 422),
])
async def test_currency_validation(client, currency, expected_status):
    ...
```

## Mocking at Network Layer (respx)
```python
import respx
@respx.mock
async def test_external_provider_integration(client):
    respx.post("https://api.external.com/reserve").mock(
        return_value=httpx.Response(200, json={"status": "confirmed"})
    )
    ...
```

## Test Database
```python
@pytest.fixture
async def db():
    engine = create_async_engine("postgresql+asyncpg://test:test@localhost:5433/test")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

## Coverage
```bash
pytest --cov=src --cov-report=html --cov-report=term
```
Target: >80% line coverage. Focus on branch coverage for complex logic.
