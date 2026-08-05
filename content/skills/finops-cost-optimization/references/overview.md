# FinOps / Cost Optimization — Overview

## AWS Cost Breakdown (typical)

| Service | % of bill | Primary optimization lever |
|---|---|---|
| EKS / EC2 | 35% | Right-size + Savings Plans + Spot for batch |
| RDS | 20% | Reserved instances 1yr + gp3 storage |
| Bedrock (AI services) | 15% | Model routing + prompt caching + token limits |
| Data transfer | 10% | VPC endpoints + regional edge caches |
| S3 + Glue | 8% | Storage class lifecycle + partition strategy |
| CloudWatch | 5% | Log retention policies + metric filter costs |
| Other | 7% | Various |

## Savings Plans Strategy

```bash
# 1. Get On-Demand spend baseline (last 3 months)
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-04-01 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# 2. Review Savings Plans recommendations
aws savingsplans list-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --purchase-option NO_UPFRONT

# Rule: commit 60% of stable baseline spend (leave buffer for growth)
# Use Compute SP (not EC2 SP) — covers Lambda + Fargate + EKS
```

## EKS Right-Sizing

```bash
# Per-namespace cost breakdown
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu | head -20

# AWS Cost Explorer: group by K8s cluster tag
aws ce get-cost-and-usage \
  --time-period Start=2026-04-01,End=2026-04-26 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --filter '{"Tags":{"Key":"service","Values":["api"]}}'

# Compute Optimizer recommendation
aws compute-optimizer get-eks-cluster-recommendations \
  --cluster-arns arn:aws:eks:us-east-1:123456789:cluster/example-prod
```

## Bedrock Token Cost Tracking

```python
# Per-request cost calculation (approximate)
BEDROCK_PRICING = {
    "anthropic.claude-3-5-sonnet-20241022-v2:0": {
        "input_per_1k":  0.003,   # $0.003 per 1K input tokens
        "output_per_1k": 0.015,   # $0.015 per 1K output tokens
    },
    "anthropic.claude-3-haiku-20240307-v1:0": {
        "input_per_1k":  0.00025,
        "output_per_1k": 0.00125,
    },
}

def estimate_cost(model_id: str, input_tokens: int, output_tokens: int) -> float:
    pricing = BEDROCK_PRICING[model_id]
    return (input_tokens / 1000 * pricing["input_per_1k"] +
            output_tokens / 1000 * pricing["output_per_1k"])

# Track per the AI service stimulus type to identify expensive branches
```

## Cost Anomaly Detection

```bash
# Create cost anomaly monitor per service
aws ce create-anomaly-monitor \
  --anomaly-monitor '{
    "MonitorName": "example-per-service",
    "MonitorType": "DIMENSIONAL",
    "MonitorDimension": "SERVICE"
  }'

aws ce create-anomaly-subscription \
  --anomaly-subscription '{
    "SubscriptionName": "cost-alerts",
    "MonitorArnList": ["arn:aws:ce::123456789:anomalymonitor/..."],
    "Subscribers": [{"Address": "finops@example.com", "Type": "EMAIL"}],
    "Threshold": 100,
    "Frequency": "DAILY"
  }'
```

## Monthly Cost Review Checklist

```
Data gathering:
  [ ] Export AWS Cost Explorer: last 30 days by service + tag
  [ ] Check Bedrock: tokens per the AI service stimulus type
  [ ] Check data warehouse: warehouse credits consumed
  [ ] Check CloudWatch: top log groups by size

Analysis:
  [ ] Any service > 20% above previous month? (investigate)
  [ ] Unused resources (EC2 < 10% CPU, RDS with no connections)
  [ ] Untagged resources (cannot be attributed)
  [ ] Savings Plans coverage > 80%? (target)

Actions:
  [ ] Schedule right-sizing for identified resources
  [ ] Clean up unused EBS volumes, snapshots, old AMIs
  [ ] Adjust Savings Plans commitment if spend changed > 15%
  [ ] Update budget alerts if spend trajectory changed
```

## Quick Wins Checklist

```bash
# 1. S3 Gateway VPC Endpoint (free, eliminates NAT gateway cost for S3)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids $ROUTE_TABLE_ID

# 2. EBS gp2 → gp3 migration (20% cheaper, same or better IOPS)
for volume in $(aws ec2 describe-volumes --filters Name=volume-type,Values=gp2 \
  --query 'Volumes[*].VolumeId' --output text); do
  aws ec2 modify-volume --volume-id $volume --volume-type gp3
done

# 3. Delete unattached EBS volumes
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].VolumeId' --output text

# 4. Old snapshots > 90 days (not needed for compliance)
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<`2026-01-26`].SnapshotId' --output text
```
