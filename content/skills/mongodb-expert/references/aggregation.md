# MongoDB Aggregation Patterns

## Usage by User (Daily)
```javascript
db.records.aggregate([
  { $match: { created_at: { $gte: start, $lte: end } } },
  { $group: {
      _id: { user: "$user_id", date: { $dateToString: { format: "%Y-%m-%d", date: "$created_at" } } },
      usage: { $sum: "$total_units" },
      count: { $sum: 1 }
  }},
  { $sort: { "_id.date": -1 } }
])
```

## Lookup (Join)
```javascript
{ $lookup: {
    from: "users",
    localField: "user_id",
    foreignField: "_id",
    as: "user"
}}
```
NEVER $lookup without index on foreignField.

## Unwind Arrays
```javascript
{ $unwind: "$items" },
{ $group: { _id: "$items.product_id", total: { $sum: "$items.quantity" } } }
```
