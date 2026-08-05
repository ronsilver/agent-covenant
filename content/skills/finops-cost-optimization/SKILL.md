---
name: finops-cost-optimization
description: "Analyze and optimize AWS costs for cloud-native infrastructure. Use when reviewing monthly AWS spend, right-sizing EC2/EKS node groups, implementing Savings Plans or Reserved Instances, optimizing Bedrock token costs for AI, reducing Data warehouse compute costs, setting up cost allocation tags, configuring AWS Budgets and anomaly detection, or performing cost reviews before large infrastructure changes. Trigger: AWS cost optimization, Savings Plans, Bedrock cost control. Do NOT trigger for: application-level performance optimization unrelated to infrastructure cost."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---

# FinOps / Cost Optimization

**Analyze and optimize AWS infrastructure costs for cloud-native projects.**

**See [references/overview.md](references/overview.md)**

## Cost Attribution (tagging strategy)

```hcl
# Required tags on ALL AWS resources (enforced via SCP or Terraform)
tags = {
  environment  = "production"         # production | staging | dev
  service      = "api"               # api | inference | apigw | ...
  team         = "engineering"      # team ownership
  cost_center  = "engineering"
  managed_by   = "terraform"
}
```

## Top Cost Drivers (generic)

| Service | Cost driver | Optimization |
|---|---|---|
| EKS / EC2 | Oversized nodes, low utilization | Right-size + Spot for non-critical |
| RDS PostgreSQL | Multi-AZ + storage IOPS | Reserved instance 1yr, gp3 storage |
| AWS Bedrock | Token consumption (AI) | Haiku for classification, cache common prompts |
| Data warehouse | Warehouse running idle | Auto-suspend ≤ 1min for AI warehouse |
| Data transfer | Cross-region, NAT gateway | VPC endpoints, S3 Gateway endpoint |
| CloudWatch Logs | Log retention too long | Lifecycle policy: 30d hot, 90d cold (S3) |

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

# 3. Apply: change instance type in Terraform, roll nodes
```

## Bedrock Cost Control

```python
# Use model routing based on task complexity
def select_model(task: str) -> str:
    CHEAP_TASKS = ["classify_intent", "summarize_short", "validate_sql"]
    EXPENSIVE_TASKS = ["generate_complex_sql", "multi_step_analysis"]

    if task in CHEAP_TASKS:
        return "anthropic.claude-3-haiku-20240307-v1:0"   # 10x cheaper
    return "anthropic.claude-3-5-sonnet-20241022-v2:0"

# Prompt caching: use cache_control for repeated system prompts
# (Anthropic API — saves 90% on repeated context)
```

## AWS Budgets

```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "example-monthly-aws"
  budget_type  = "COST"
  limit_amount = "50000"   # USD
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_email_addresses = ["finops@example.com", "oncall@example.com"]
  }
}

resource "aws_ce_anomaly_monitor" "example" {
  name              = "example-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}
```

→ [references/overview.md](references/overview.md) | [references/cost-analysis.md](references/cost-analysis.md) | [references/aws-cost-operations.md](references/aws-cost-operations.md) — advanced patterns: pre-deployment estimation, Application Signals, Tag Everything strategy, anomaly detection + forecasting

## Constraints

- NEVER deploy infrastructure without cost estimate (terraform plan + aws-pricing MCP)
- NEVER leave Data warehouses running without auto-suspend
- ALWAYS tag ALL resources (untagged resources = unattributable spend)
- ALWAYS set AWS Budgets alert at 80% of monthly target
- ALWAYS use gp3 over gp2 for EBS (same or better perf, 20% cheaper)
- ALWAYS use S3 Gateway VPC endpoint (eliminates NAT gateway cost for S3)
- NEVER use On-Demand for stable, predictable workloads > 1 month
- ALWAYS review Bedrock token spend weekly during AI development

## Overview

FinOps combines cultural practice (cost + engineering accountability) with automated cost controls. This skill covers AWS cost attribution via mandatory tagging, right-sizing EC2/EKS, Bedrock token cost optimization through model routing and prompt caching, Data warehouse auto-suspend, anomaly detection via AWS Budgets, and pre-deployment cost estimation using the `aws-pricing` MCP.

## Quick Reference

| Action | Tool/Mechanism | Frequency |
|---|---|---|
| Tag audit | AWS Config + SCP rule | Continuous |
| Right-size EC2/EKS | AWS Compute Optimizer | Monthly |
| Bedrock cost review | CloudWatch + Cost Explorer | Weekly |
| Budget alerts | AWS Budgets (80% threshold) | Monthly |
| Anomaly detection | AWS Cost Anomaly Monitor | Daily |
| Data warehouse cost check | Data warehouse Account Usage views | Daily |
| Pre-deploy estimate | `aws-pricing` MCP tool | Every deploy |

## Workflow

1. **Tag every resource** — Enforce `environment`, `service`, `team`, `cost_center`, `managed_by` tags via Terraform provider + SCP. Untagged resources trigger auto-remediation.
2. **Set monthly budgets** — Create AWS Budget at 80% of forecast. Configure notifications to `finops@example.com` and `oncall@example.com`.
3. **Run Compute Optimizer** — Monthly: pull EC2/EKS right-sizing recommendations. Resize under-utilized instances via Terraform PR. Apply Spot for non-critical stateless workloads.
4. **Optimize Bedrock tokens** — Route classification tasks to Haiku, complex analysis to Sonnet. Enable prompt caching for repeated system prompts. Track token spend per model per service.
5. **Configure auto-suspend** — Data warehouse: auto-suspend ≤ 1 minute for AI. RDS: enable Storage Auto Scaling. EBS: gp3 over gp2.
6. **Review and report** — Weekly cost review with team leads. Investigate any >10% MoM increase. Publish cost-per-service dashboard to Grafana.

## Anti-patterns

FAIL: Untagged resources deployed without cost attribution.
```hcl
# BAD: No tags — cost shows as "unknown" in billing reports
resource "aws_instance" "worker" {
  ami           = "ami-123"
  instance_type = "m5.large"
  # no tags block
}
```
```hcl
# GOOD: Mandatory tags on every resource
resource "aws_instance" "worker" {
  tags = {
    environment = "production"
    service     = "inference"
    team        = "ai-platform"
    cost_center = "engineering"
    managed_by  = "terraform"
  }
}
```

FAIL: Data warehouse running 24/7 for occasional queries.
```sql
-- BAD: No auto-suspend → warehouse runs all night for zero queries
ALTER WAREHOUSE analytics_wh SET auto_suspend = 0;
```
```sql
-- GOOD: Auto-suspend after 60 seconds of idle
ALTER WAREHOUSE analytics_wh SET auto_suspend = 60;
```

FAIL: Using On-Demand for stable, predictable workloads.
```
BAD: Running production RDS on On-Demand for 18+ months (pays 30-40% premium).
GOOD: Purchase 1-year or 3-year Reserved Instance / Savings Plan for predictable baselines.
```

FAIL: Ignoring data transfer costs in cost estimates
```hcl
# BAD: deploying cross-AZ workload without considering transfer costs
resource "aws_lb" "public" {
  internal = false  # Internet-facing = NAT gateway for private subnets
}
# Cross-AZ: $0.01/GB each direction; NAT Gateway: $0.045/GB + $0.045/hr
# Hidden cost: 10 TB/mo cross-AZ = $100+ unaccounted
```

```hcl
# GOOD: co-locate resources within same AZ where possible
resource "aws_lb" "internal" {
  internal = true  # No NAT needed
}
# Use VPC endpoints (S3 Gateway = free, endpoints = $0.01/hr vs NAT $0.045/hr)
```

FAIL: Over-provisioned RDS without rightsizing review
```hcl
# BAD: db.r6g.8xlarge (32 vCPU, 256 GB RAM) running at 15% CPU
resource "aws_db_instance" "main" {
  instance_class = "db.r6g.8xlarge"
  # No utilization review ever performed
}
```

```hcl
# GOOD: start with right-sized instance, monitor, adjust
resource "aws_db_instance" "main" {
  instance_class = "db.r6g.2xlarge"  # 8 vCPU, 64 GB — 4x cheaper
  # Add Performance Insights to validate utilization quarterly
}
# Monthly savings: ~$1,200 → ~$300 (75% reduction at On-Demand rates)
```

## References

| Resource | URL | Last verified |
|---|---|---|
| AWS Well-Architected — Cost Optimization Pillar | https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/ | 2026-05-25 |
| FinOps Foundation — Official Framework | https://www.finops.org/framework/ | 2026-05-25 |
| AWS Cost Management User Guide | https://docs.aws.amazon.com/cost-management/latest/userguide/ | 2026-05-25 |

## Verification Checklist
- [ ] All AWS resources tagged: `environment`, `service`, `team`, `cost_center`, `managed_by`
- [ ] AWS Budget alert configured at 80% of monthly forecast
- [ ] Data warehouse auto-suspend ≤ 1 min for AI workload
- [ ] Bedrock token costs tracked per model per service (Haiku vs Sonnet vs Opus)
- [ ] Cost estimate obtained via `aws-pricing` MCP before any infrastructure deploy
- [ ] Monthly Compute Optimizer review scheduled for right-sizing
- [ ] Anomaly detection enabled via AWS Cost Anomaly Monitor

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Monthly AWS bill exceeds budget by 40% | Untagged resources not attributable; anomaly not detected; right-sizing not done in 6+ months | Run cost attribution per service; enable anomaly monitor; run Compute Optimizer review |
| Data warehouse cost doubled month-over-month | Warehouse running 24/7 without auto-suspend; concurrent warehouse not set | Set `auto_suspend = 60` (seconds); use separate warehouses per workload; suspend during idle hours |
| Bedrock token cost unexpectedly high | All tasks routed to Sonnet/Opus; no Haiku for cheap classification | Implement model routing: Haiku for intent classification and validation, Sonnet for complex analysis only |
| Untagged resources appear in billing report | Terraform modules missing mandatory tags; drift from manual creation | Add `tags` block to all Terraform resources; enforce via SCP; audit quarterly with Config rules |
| Savings Plan utilization drops mid-cycle due to workload shift (known limitation) | Savings Plans are region+instance-family-flexible but cannot be changed after purchase; workload migration invalidates coverage | Use Convertible RIs or Savings Plans with `compute` scope; right-size and plan workload patterns before purchasing 3-year commitments |
| Savings Plans show low coverage despite active instances | Not all instance families are covered by Savings Plans (e.g., `inf1`, `p4d` GPU instances excluded) | Check `pricingModel` in Cost Explorer — filter by `Coverage`; use separate RI for non-covered families like GPU/AI instances |
| Spot instance workload fails during peak hours | Spot interruption rate spikes during high EC2 demand periods; reclamation costs (restart + data re-fetch) exceed On-Demand savings for stateful workloads | Use On-Demand for stateful/transactional workloads; Spot only for stateless batch jobs with checkpointing; set `maxPrice` to 50% of On-Demand to reduce interruption rate |
