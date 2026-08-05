# AWS Cost Operations — Advanced Patterns

## Pre-Deployment Cost Estimation

Estimate BEFORE `terraform apply`, not after receiving the bill:

```bash
# 1. Generate cost estimate from terraform plan
terraform plan -out=plan.binary
terraform show -json plan.binary | infracost --path=/dev/stdin

# 2. Infracost output (example)
# ┌──────────────────────────────────────────────────────┐
# │ Project: example-prod                                  │
# │                                                       │
# │ + aws_rds_cluster.api                            │
# │   $876.00/mo — db.r6g.xlarge (Multi-AZ, 3000 IOPS)   │
# │                                                       │
# │ + aws_eks_cluster.main                                │
# │   $146.00/mo — EKS control plane                      │
# │                                                       │
# │ Total: $1,022.00/mo (+$1,022.00 vs current)          │
# └──────────────────────────────────────────────────────┘

# 3. If >$500 delta vs baseline → flag for review before apply
```

Integrate into CI:
```yaml
# .github/workflows/terraform.yml
- name: Infracost estimate
  run: |
    infracost breakdown --path=plan.json \
      --format=json --out-file=cost.json
    diff=$(infracost diff --path=cost.json --compare-to=baseline.json)
    if echo "$diff" | jq '.totalMonthlyCost > 500'; then
      gh pr comment --body "[WARN] Cost delta >$500/mo. Review required."
    fi
```

## Application Signals + Managed Prometheus

Replace CloudWatch custom metrics (expensive, limited) with Application Signals:

```hcl
# Enable Application Signals on EKS
resource "aws_eks_addon" "app_signals" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "amazon-cloudwatch-observability"
  
  configuration_values = jsonencode({
    agent = {
      config = {
        application_signals = {
          enabled = true
        }
      }
    }
  })
}
```

Benefits:
- Pre-built dashboards: latency, faults, errors per service
- No custom metric cost ($0.30/metric/month saved)
- Auto-correlation: service map + traces + logs in one view

## "Tag Everything" Strategy

Tags are the backbone of cost attribution. Enforcement layers:

### Layer 1 — Terraform module defaults
```hcl
# Every module includes mandatory tags
locals {
  mandatory_tags = {
    environment = var.environment
    service     = var.service_name
    team        = var.team
    cost_center = "engineering"
    managed_by  = "terraform"
  }
}
```

### Layer 2 — SCP (Service Control Policy)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUntaggedResources",
      "Effect": "Deny",
      "Action": ["ec2:RunInstances", "rds:CreateDBInstance"],
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/cost_center": "true"
        }
      }
    }
  ]
}
```

### Layer 3 — AWS Config Rule
```hcl
resource "aws_config_config_rule" "tag_compliance" {
  name = "required-tags-compliance"
  source {
    owner     = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  input_parameters = jsonencode({
    tag1Key   = "cost_center"
    tag1Value = "engineering,finance,operations"
  })
}
```

## Cost-by-Tag Breakdown

Query cost per tag dimension:

```sql
-- Athena query on AWS CUR (Cost and Usage Report)
SELECT
  line_item_usage_account_id,
  resource_tags_user_cost_center,
  resource_tags_user_service,
  SUM(line_item_unblended_cost) AS total_cost
FROM cur_table
WHERE billing_period = '2026-04'
GROUP BY 1, 2, 3
ORDER BY total_cost DESC;
```

Dashboard: QuickSight → "Cost by Team" → refreshed daily.

## Anomaly Detection + Forecasting

```hcl
# AWS anomaly detection
resource "aws_ce_anomaly_monitor" "example_service" {
  name              = "example-service-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "finops_slack" {
  name           = "finops-alerts"
  frequency      = "IMMEDIATE"
  monitor_arn_list = [aws_ce_anomaly_monitor.example_service.arn]
  
  subscriber {
    type    = "EMAIL"
    address = "finops@example.com"
  }
  
  # Threshold: alert on >20% deviation from expected
  threshold = 20.0
}

# Cost forecast (30-day projection)
resource "aws_budgets_budget" "forecast" {
  name         = "example-forecast-30d"
  budget_type  = "COST"
  limit_amount = "60000"  # Expected + 20% buffer
  time_unit    = "MONTHLY"
  
  cost_filter {
    name   = "Forecast"
    values = ["FORECAST"]
  }
}
```

## Cost Optimization Review Cycle

| Cadence | Action | Tool |
|---|---|---|
| **Pre-deploy** | Estimate from terraform plan | Infracost |
| **Weekly** | Bedrock token spend (the AI service) | AWS Cost Explorer + CloudWatch |
| **Monthly** | Full AWS bill review + right-sizing recs | Compute Optimizer + Trusted Advisor |
| **Quarterly** | Savings Plan / Reserved Instance purchases | AWS Cost Explorer Recommendations |
| **On anomaly** | Investigate within 2h of alert | AWS Anomaly Detection → Cost Explorer |

## Quick Wins (Generic-specific)

1. **gp2 → gp3**: same/better perf, 20% cheaper. One-line Terraform change.
2. **S3 VPC Gateway endpoint**: eliminates NAT gateway cost for S3 traffic.
3. **Haiku routing**: classify/summarize/validate tasks → 10x cheaper than Sonnet.
4. **Auto-suspend ≤ 1min**: data warehouse instances for analytics (idle = burn).
5. **Spot instances**: non-critical EKS node groups (staging, batch jobs).
6. **Log lifecycle**: 30d CloudWatch hot → 90d S3 cold → auto-delete after.
7. **1yr RDS RI**: stable DB workloads, 30-40% savings vs On-Demand.
