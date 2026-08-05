# DynamoDB Operations

## Write
- PutItem: full replace
- UpdateItem: partial update (atomic counter: ADD #cnt :1)
- TransactWriteItems: atomic multi-table

## Read
- Query: PK required, optional SK filter
- GetItem: exact PK+SK
- NEVER Scan (full table read, expensive)

## Capacity
- On-Demand: spiky/unpredictable
- Provisioned: predictable, cheaper at scale
- Switch mode max 1x per 24h per table

## Limits
- Item: max 400KB
- GSI: max 20 (operational safe: 5)
- Query: 1MB response, paginate with LastEvaluatedKey
