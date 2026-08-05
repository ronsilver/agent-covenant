# DynamoDB Advanced Patterns

## Sparse Indexes
Only items with the indexed attribute appear in the GSI.
```json
{ "GSI": { "PK": "STATUS#pending", "SK": "DATE#2026-05-16" } }
```

## Composite Sort Keys
Hierarchical data: `SK: "STATE#JALISCO#CITY#GUADALAJARA"`.
Query: `begins_with(SK, "STATE#JALISCO")`.

## Versioned Items (Optimistic Locking)
```go
input := &dynamodb.UpdateItemInput{
    ConditionExpression: aws.String("#ver = :expected"),
    UpdateExpression:    aws.String("SET #qty = :qty ADD #ver :inc"),
}
```
Prevents lost updates via version attribute.

## TTL (Auto-Expire)
```go
item["ttl"] = &types.AttributeValueMemberN{Value: strconv.FormatInt(time.Now().Add(24*time.Hour).Unix(), 10)}
```
Enable TTL on attribute. Deletion within 48 hours of expiry (not instant).

## Global Tables (Multi-Region)
```bash
aws dynamodb update-table --table-name shipments \
    --replica-updates '[{"Create": {"RegionName": "sa-east-1"}}]'
```
Last-writer-wins conflict resolution.
