# Micro-Refactorings Catalog

## Extract Variable
Before: `unitPrice * quantity - bulkAdjustment`
After:
```go
subtotal := unitPrice * quantity
total := subtotal - bulkAdjustment
```

## Inline Temp
Before:
```typescript
const total = order.subtotal + order.shippingFee;
return { ...order, total };
```
After:
```typescript
return { ...order, total: order.subtotal + order.shippingFee };
```

## Split Loop
Before: loop does both validation AND transformation
After: separate loop for validation, separate loop for transformation

## Replace Loop with Pipeline
Before:
```python
approved = []
for p in items:
    if p.status == "active":
        approved.append(p)
```
After:
```python
approved = [p for p in items if p.status == "active"]
```

## Decompose Conditional
Before:
```go
if date.Before(deadline) && amount > minAmount && !customer.IsBanned {
    processPayment(...)
}
```
After:
```go
if !date.Before(deadline) { return ErrTooLate }
if amount <= minAmount    { return ErrTooSmall }
if customer.IsBanned      { return ErrBanned }
processPayment(...)
```

## Introduce Parameter Object
Before: `func CreateRecord(ctx, ownerID, value, category, token, webhookURL)`
After: `func CreateRecord(ctx, req CreateRecordRequest)` where `CreateRecordRequest` is a struct
