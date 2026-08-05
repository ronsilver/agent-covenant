# AWS Security

## Security Groups

- NEVER `0.0.0.0/0` in ingress
- Reference security groups instead of CIDRs when possible
- Default: deny all ingress, allow only needed egress
- Use `self` rule for intra-ASG communication

```hcl
resource "aws_security_group" "app" {
  name_prefix = "${var.service_name}-app-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App from internal LB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.lb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
```

## S3 Security

- Block public access at account level
- Enable versioning + MFA delete for critical buckets
- Server-side encryption: `aws:kms` by default
- Bucket policies deny insecure transport

## Encryption at Rest

| Service | Encryption method |
|---------|------------------|
| S3 | SSE-KMS (`aws:kms` or CMK) |
| EBS | EBS encryption by default |
| RDS | KMS via `storage_encrypted = true` |
| EFS | KMS via `encrypted = true` |
| Secrets Manager | KMS (default) |

## VPC Security

- Use private subnets for compute workloads
- NAT Gateways only for outbound internet
- VPC Endpoints (Gateway + Interface) to avoid data exfiltration
- Network ACLs for stateless subnet-level rules
- Security Groups for stateful instance-level rules

## Key Management

- Rotate KMS keys annually (automatic for AWS-managed keys)
- Use IAM policies to restrict `kms:Decrypt` and `kms:Encrypt`
- Enable KMS key rotation for CMKs
- Guard `kms:Decrypt` with conditions (e.g., `aws:SourceArn`)
