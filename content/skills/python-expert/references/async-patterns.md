# Python Async Patterns

## asyncio Basics
```python
import asyncio
async def main():
    result = await fetch_data()
    tasks = [asyncio.create_task(worker(i)) for i in range(10)]
    results = await asyncio.gather(*tasks)

asyncio.run(main())
```

## FastAPI Async
```python
from fastapi import FastAPI, Depends
app = FastAPI()

@app.post("/items")
async def create_item(
    req: ItemRequest,
    db: AsyncSession = Depends(get_db)
) -> ItemResponse:
    async with db.begin():
        item = await item_service.create(db, req)
    return item
```

## SQLAlchemy 2.0 Async
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

async with AsyncSession(engine) as session:
    result = await session.execute(select(Item).where(Item.status == "active"))
    items = result.scalars().all()
```

## Concurrency Limits
```python
semaphore = asyncio.Semaphore(10)  # max 10 concurrent
async with semaphore:
    result = await api_call()
```

## Anti-Patterns
- NEVER `time.sleep()` in async code -> `await asyncio.sleep()`
- NEVER CPU-bound work in async without `run_in_executor()`
- NEVER create tasks without storing references (garbage collected silently)
- NEVER mix sync and async DB sessions
