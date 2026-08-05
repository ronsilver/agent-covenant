# IAM Best Practices

## Least Privilege Rules

- NEVER `Action: "*"` or `Resource: "*"`
- Scope actions to specific API operations
- Use resource-level ARNs when possible
- Apply `Condition` blocks for extra constraint

## Policy Structure

```hcl
# GOOD pattern
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::example-data-bucket/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}
```

## Common Conditions

| Condition | Purpose |
|-----------|---------|
| `aws:SourceIp` | Restrict to office/VPN CIDRs |
| `aws:RequestedRegion` | Lock to allowed regions |
| `aws:MultiFactorAuthPresent` | Require MFA for sensitive actions |
| `s3:x-amz-server-side-encryption` | Force encryption on S3 writes |
| `iam:PassedToService` | Scope PassRole to specific services |

## Roles vs Users

- Prefer IAM roles over IAM users
- Use SSO (AWS IAM Identity Center) for human access
- EC2 roles via Instance Profile (NEVER access keys on instances)
- Cross-account access via role assumption only

## SCPs for Account Baselines

```hcl
# Block leaving the org or disabling CloudTrail
statement {
  effect    = "Deny"
  actions   = [
    "organizations:LeaveOrganization",
    "cloudtrail:StopLogging",
    "cloudtrail:DeleteTrail",
  ]
  resources = ["*"]
}
```
