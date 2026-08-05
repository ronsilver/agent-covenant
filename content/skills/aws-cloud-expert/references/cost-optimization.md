# AWS Cost Optimization

## Savings Plans & Reserved Instances

| Option | Discount | Commitment | Best for |
|--------|----------|------------|----------|
| Compute Savings Plan | up to 66% | 1yr/3yr | EC2, ECS, Lambda across regions |
| EC2 Instance Savings Plan | up to 72% | 1yr/3yr | Steady-state EC2 in specific family |
| Reserved Instances | up to 75% | 1yr/3yr | RDS, ElastiCache, OpenSearch |

## Spot Instances

- Use for stateless, fault-tolerant workloads (batch, EMR, EKS node groups)
- Use `capacity-optimized` allocation strategy
- Set `maxPrice = on-demand` to avoid interruption
- Use Spot Interruption Handler (or Karpenter drain for EKS)

## Right-Sizing

1. Run AWS Compute Optimizer weekly
2. Downsize instances with <20% avg CPU over 14 days
3. Migrate to Graviton (Arm) for 20-40% cost reduction
4. Remove unused EIPs, volumes, LBs monthly

## Budget Alerts

```hcl
resource "aws_budgets_budget" "monthly" {
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 50
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

## S3 Storage Classes

| Class | Retrieval | Cost | Use case |
|-------|-----------|------|----------|
| STANDARD | Instant | Baseline | Active data |
| INTELLIGENT_TIERING | Instant | Auto-optimized | Unknown access patterns |
| GLACIER_IR | Minutes | 50% less | Monthly access |
| DEEP_ARCHIVE | 12h | 95% less | Compliance retention |
