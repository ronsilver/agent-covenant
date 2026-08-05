---
name: aws-cloud-expert
description: "Design and implement secure, cost-optimized AWS infrastructure following least privilege, encryption, IaC, and operational excellence principles. Use when working with AWS services (EC2, ECS, Lambda, RDS, S3, SQS, SNS), IAM roles/policies, VPC networking, CloudFormation/CDK, cost optimization, or AWS monitoring and alerting. Trigger: AWS infrastructure, IAM policies, VPC networking. Do NOT trigger for: application-level code design, frontend development unrelated to cloud infrastructure, or cost optimization analysis (use finops-cost-optimization)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: cloud
  status: stable
---

# AWS Cloud Expert

Secure, cost-optimized AWS infrastructure: least privilege + encryption + IaC + observability.

## Core Principles

1. Least Privilege: NEVER `Action: "*"` → [references/iam.md](references/iam.md)
2. IaC only: Terraform
3. Encryption everywhere: TLS + KMS
4. Cost awareness: estimate first, tag all
5. Observable by default: logs, metrics, alarms

## IAM

- Roles over Users; specific actions only (no wildcard `*`); use Conditions

## Security

- Security Groups: NEVER `0.0.0.0/0` in ingress → [references/security.md](references/security.md)
- S3: block public access + versioning + encryption
- Secrets: Secrets Manager or SSM (NEVER hardcoded)

## MANDATORY Tags

`Environment`, `Project`, `ManagedBy`, `CostCenter` → [references/tagging.md](references/tagging.md)

## Cost Optimization

- Estimate before deploying; right-size (start small)
- Savings Plans/Spot → 30-90% savings
- Eliminate unused EIPs, volumes, LBs
- Budget alerts at 50%, 80%, 100% → [references/cost-optimization.md](references/cost-optimization.md)

## Monitoring

- CloudWatch alarms for all production services
- Structured JSON logging + explicit retention policies
- Enable S3/ALB/VPC/CloudTrail logging
- Dashboards: RED method + utilization + costs → [references/monitoring.md](references/monitoring.md)

## Operations

- Feature flags + canary deployments + automated rollbacks
- Every alarm links to runbook
- Weekly: review alarms | Monthly: cost analysis | Quarterly:
  right-sizing → [references/operations.md](references/operations.md)

## Resources
- [references/core-principles.md](references/core-principles.md) — least privilege, encryption, IaC, observability

## Constraints

- NEVER `Action: "*"` or `Resource: "*"`
- NEVER hardcode secrets
- ALWAYS encrypt at rest + in transit
- ALWAYS tag all resources
- ALWAYS estimate costs before deploying
- ALWAYS set CloudWatch alarms for production
- ALWAYS set explicit log retention

## Overview

AWS infrastructure following the Well-Architected Framework: least privilege IAM, encryption at rest and in transit, infrastructure as code (Terraform), and cost-aware operations. Every resource must be tagged, monitored, and deployed via IaC with no manual changes.

## Quick Reference

| Principle | Implementation | Check |
|-----------|---------------|-------|
| Least Privilege | IAM roles with scoped actions + conditions | No `Action: "*"` or `Resource: "*"` |
| Encryption | KMS + TLS for all services | All buckets encrypted, LB listeners use TLS |
| IaC | Terraform with remote state + locking | No manual console changes |
| Tagging | `Environment`, `Project`, `CostCenter`, `ManagedBy` | All resources tagged on creation |
| Cost Control | Budget alerts at 50%/80%/100%, right-size quarterly | Alarms configured |
| Observability | CloudWatch alarms, structured JSON logs, dashboards | RED metrics per service |

## Workflow

1. Estimate costs before deploying — use AWS Pricing Calculator and review existing reserved capacity
2. Write Terraform modules with mandatory tags, encryption, and least-privilege IAM
3. Validate: `terraform plan` → review diff → `tflint` → `checkov` for security compliance
4. Deploy with CI/CD; never use manual console changes
5. Configure CloudWatch alarms (linked to runbooks) and structured logging with retention policy
6. Monitor: weekly alarm review, monthly cost analysis, quarterly right-sizing review

## Anti-patterns

FAIL: Overly permissive IAM policy
```hcl
# BAD
Action = "s3:*"
Resource = "*"
```
PASS: Scope to specific actions and resources
```hcl
# GOOD
Action = ["s3:GetObject", "s3:PutObject"]
Resource = "arn:aws:s3:::example-data-bucket/*"
Condition {
  test     = "StringEquals"
  variable = "s3:x-amz-server-side-encryption"
  values   = ["aws:kms"]
}
```

FAIL: Security Group with open ingress
```hcl
# BAD
cidr_blocks = ["0.0.0.0/0"]
```
PASS: Restrict to known CIDRs
```hcl
# GOOD
cidr_blocks = ["10.0.0.0/16", "10.1.0.0/16"]
```

FAIL: Deploying without cost estimation
```
# BAD — surprise bill at month end
Deploy r6i.8xlarge without checking pricing
```
PASS: Estimate first, right-size
```
# GOOD
1. Check pricing: r6i.8xlarge = $1.6/hr vs r6i.large = $0.1/hr
2. Start with r6i.large, monitor utilization, scale up if needed
3. Set budget alert at 50%
```

FAIL: Missing encryption on S3 bucket
```hcl
# BAD
resource "aws_s3_bucket" "data" {
  bucket = "example-data"
}
```
PASS: Enforce encryption
```hcl
# GOOD
resource "aws_s3_bucket" "data" {
  bucket = "example-data"
}
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

## References

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) · last_verified: 2026-05-25
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) · last_verified: 2026-05-25
- [AWS Pricing Calculator](https://calculator.aws/) · last_verified: 2026-05-25

## Verification Checklist
- [ ] IAM policies scoped to specific actions and resources (no `Action: "*"`, no `Resource: "*"`)
- [ ] Security group ingress restricted to known CIDRs (no `0.0.0.0/0`)
- [ ] Encryption enabled at rest (KMS) and in transit (TLS) for all resources
- [ ] All resources tagged: `Environment`, `Project`, `CostCenter`, `ManagedBy`
- [ ] Cost estimate obtained before deploying new infrastructure
- [ ] CloudWatch alarms configured for all production services with runbook links

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Terraform plan shows unexpected resource changes | Drift from manual console changes; state file out of sync | Run `terraform refresh` or `terraform import` for drifted resources; prevent manual changes via SCP |
| Unable to list S3 bucket objects despite IAM permission | S3 bucket policy denying access; public access block active | Check bucket policy for explicit deny; verify IAM principal matches bucket policy condition |
| CloudWatch alarm not firing despite error rate > threshold | No metric data; alarm period mismatch; insufficient data actions not configured | Verify metric namespace/dimension match; set `treatMissingData: breaching`; check alarm period aligns with metric frequency |
| EC2 cost 2x above estimate | Instance type oversized; no Savings Plan; NAT gateway data transfer | Right-size via Compute Optimizer; purchase Savings Plan; add VPC endpoints to reduce NAT data transfer |
| Terraform state lock prevents concurrent runs (known limitation) | Multiple CI pipelines or engineers running `terraform apply` simultaneously on same workspace | Use remote state locking with DynamoDB; enforce serial execution in CI |
