# AWS Core Principles

## Well-Architected Framework

Six pillars applied :

| Pillar | Implementation | Check |
|--------|---------------|-------|
| Operational Excellence | IaC (Terraform), runbooks, feature flags | All infra deployed via CI/CD |
| Security | Least privilege IAM, KMS encryption, VPC isolation | No public S3, no `0.0.0.0/0` ingress |
| Reliability | Multi-AZ, auto-scaling, health checks | Production workloads span >=2 AZs |
| Performance Efficiency | Right-sizing, Compute Optimizer, Graviton | Review quarterly |
| Cost Optimization | Savings Plans, Spot, budget alerts | Alarms at 50%/80%/100% |
| Sustainability | Graviton instances, delete unused resources | Quarterly cleanup |

## Infrastructure as Code

- Terraform is the ONLY allowed IaC tool
- Remote state with DynamoDB locking
- No manual console changes — any drift must be imported

## Encryption Standards

- At rest: KMS (AWS-managed or customer-managed key)
- In transit: TLS 1.2+ minimum
- S3 defaults: AES-256 via `aws:kms`
