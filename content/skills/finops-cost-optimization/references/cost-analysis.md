# Cost Analysis

Advanced patterns for AWS cost analysis.

## Right-Sizing Workflow

```bash
# 1. Get CPU/memory utilization for last 30 days
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name node_cpu_utilization \
  --start-time $(date -u -d '30 days ago' +%FT%TZ) \
  --end-time $(date -u +%FT%TZ) \
  --period 86400 \
  --statistics Average

# 2. Use AWS Compute Optimizer recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --filters name=Finding,values=OVER_PROVISIONED
```

## Application Signals

Use AWS Application Signals for service-level cost attribution.

## Tag Everything Strategy

```hcl
tags = {
  environment  = "production"
  service      = "api"
  team         = "engineering"
  cost_center  = "engineering"
  managed_by   = "terraform"
}
```

## Constraints

- NEVER deploy infrastructure without cost estimate.
- ALWAYS use gp3 over gp2 for EBS (20% cheaper).
