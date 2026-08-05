# DynamoDB Cost Optimization

## Capacity Modes
| Mode | Cost Model | Best For |
|---|---|---|
| On-Demand | $1.25/M writes, $0.25/M reads | Unpredictable, new services |
| Provisioned | $0.00065/RCU-hr, $0.00013/WCU-hr | Predictable, cost-optimized |

## Right-Sizing
```bash
aws cloudwatch get-metric-statistics \
    --metric-name ConsumedReadCapacityUnits \
    --namespace AWS/DynamoDB
# If average < 30% of provisioned: reduce capacity
# If throttled > 0: increase capacity
```

## Storage Optimization
- TTL: auto-delete expired items (sessions, logs, temp data)
- Compress large attributes
- Archive old data to S3 (Streams -> Kinesis Firehose -> S3)

## Cost Allocation Tags
```bash
aws dynamodb tag-resource \
    --resource-arn arn:...:table/shipments \
    --tags Key=Environment,Value=production Key=Service,Value=shipments
```

## Query Cost
| Query Type | RCU Cost |
|---|---|
| GetItem (strong consistent) | 1 RCU per 4KB |
| Query (eventual consistent) | 0.5 RCU per 4KB |
| Scan | Full table RCUs each time |

Rule: Query > GetItem > Scan. NEVER Scan in production.
