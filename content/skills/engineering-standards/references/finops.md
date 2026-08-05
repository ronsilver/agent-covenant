# FinOps Best Practices

## Cost Allocation
- Tag ALL resources: Environment, Service, Team, CostCenter
- Enable cost allocation tags in AWS Billing
- Regular cost reviews (monthly per team)

## Right-Sizing
- Monitor actual utilization (CPU, memory, IOPS)
- Downsize over-provisioned resources
- Use auto-scaling for variable workloads
- Review and remove unused resources monthly

## Commitment-Based Discounts
- Savings Plans for predictable compute (EC2, Lambda, Fargate)
- Reserved Instances for RDS, ElastiCache, OpenSearch
- 1-year commitment minimum, 3-year for stable workloads
- Never commit without 3+ months of stable usage data

## Storage Optimization
- S3 Lifecycle policies: transition to cheaper tiers
- S3 Intelligent-Tiering for unpredictable access patterns
- Delete old snapshots, AMIs, logs
- Glacier for long-term archival (90+ days)

## Bedrock / AI Costs
- Model routing: Haiku for simple queries (80%+ of traffic)
- Prompt caching: immutable instructions at prompt start
- Max tokens: cap to prevent runaway generation
- Budget alerts at 80% of monthly allocation
