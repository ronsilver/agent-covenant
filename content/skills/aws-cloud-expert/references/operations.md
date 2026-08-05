# AWS Operations

## Deployment Strategy

1. Feature flags for all changes
2. Canary deployments (5% → 25% → 100%)
3. Automated rollback on alarm triggers
4. Every alarm links to a runbook in repo

## Regular Reviews

| Cadence | Activity |
|---------|----------|
| Weekly | Review open alarms, untriaged errors |
| Monthly | Cost analysis, budget forecasting |
| Quarterly | Right-sizing, unused resource audit |
| Biannually | Well-Architected Review |

## Drift Detection

- `terraform plan` runs daily via CI
- Drift alerts via CloudWatch → automate re-apply or manual import
- Config rules for compliance (s3-public-read, unrestricted SG)

## Backup & Recovery

| Service | Backup strategy | RTO | RPO |
|---------|----------------|-----|-----|
| RDS | Automated snapshots (7-35d) | 15 min | 5 min |
| DynamoDB | On-demand backups | 1h | Last backup |
| EFS | Automatic backup | 1h | 15 min |
| S3 | Versioning + Cross-region replication | 15 min | Real-time |
| EC2 | AMI lifecycle via Backup plans | 30 min | Daily |

## Incident Response

- Detect: CloudWatch alarms, alert on metrics
- Triage: link to runbook, assess severity
- Mitigate: rollback, scale up, failover
- Post-mortem: 5 whys, SLA impact, action items
