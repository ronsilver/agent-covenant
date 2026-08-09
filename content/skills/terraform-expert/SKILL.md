---
name: terraform-expert
description: "Infrastructure as code with Terraform/OpenTofu: HCL modules, remote state management, 3-layer validation (tflint, checkov, trivy), drift detection, secret handling, and declarative AWS resource design. Use when creating or reviewing Terraform modules, running terraform plan/apply/import, managing remote state, importing existing resources, configuring workspaces, detecting infrastructure drift, or working with .tf files. Trigger: Terraform, OpenTofu, HCL, IaC, tflint, checkov, trivy, state, drift. Do NOT trigger for: Kubernetes manifests, Helm charts, ArgoCD configuration (use k8s/expert skills)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: cloud
  status: stable
---

# Terraform Expert

**IaC with Terraform: modules, 3-layer security.**

## Core Stack

- IaC: Terraform 1.x / OpenTofu (HCL)
- State: Remote with locking (S3 + DynamoDB)
- Validation: `tflint` -> `checkov` -> `trivy` (3-layer security)
- Docs: `terraform-docs`

## Module Structure

```
main.tf          # resource definitions
variables.tf     # input variables (type + description mandatory)
outputs.tf       # output values
versions.tf      # terraform + provider version constraints
README.md        # auto-generated (terraform-docs)
```

## 3-Layer Validation (MANDATORY — STOP on failure)

```
1. tflint         -> code quality, provider rules, naming
2. checkov + trivy -> security policies, compliance, CVEs
3. terraform-docs  -> auto-generate README
```

- NEVER skip layers. NEVER `|| true` in CI.
- All three must pass before commit.

## Core Rules

- Variables: `type` + `description` mandatory — never empty `description`
- Naming: `snake_case` for resources, variables, outputs
- State: Remote with locking (S3 + DynamoDB on AWS)
- Resources: `for_each` > `count` (deterministic keys)
- Secrets: Never in code — use `sops`, Vault, or AWS Secrets Manager
- Tags: ALWAYS `Environment`, `Service`, `Owner` minimum

## Apply Workflow (MANDATORY)

```
terraform validate -> tflint -> checkov -> terraform plan -> review plan diff -> terraform apply
```

- `terraform plan` MUST run after every edit
- `terraform import` safety: run `terraform state list` first
- Breaking change: STOP -> warn -> propose migration strategy -> explicit approval
- NEVER guess cloud API constraints — read official docs first

## Remote State

```hcl
terraform {
  backend "s3" {
    bucket         = "example-terraform-state"
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Constraints

- NEVER hardcode secrets — use `sops` / env vars / Secrets Manager
- NEVER share state files across components
- NEVER use `latest` for module versions — pin to specific tags
- ALWAYS 3-layer validation before commit
- ALWAYS `for_each` > `count`
- ALWAYS pin provider versions
- ALWAYS remote state with locking
- NEVER skip `terraform plan` -> review -> `apply`

## Overview

Infrastructure as Code with Terraform 1.x / OpenTofu using HCL modules, remote state with locking, and 3-layer validation (tflint → checkov → trivy). Every change follows a mandatory plan → review → apply workflow.

## Quick Reference

| Validation Layer | Purpose | Command |
|-----------------|---------|--------|
| tflint | Code quality, provider rules, naming conventions | `tflint --init && tflint` |
| checkov | Security policies, compliance scanning | `checkov -d .` |
| trivy | CVE scanning of provider dependencies | `trivy config .` |
| terraform-docs | Auto-generate README | `terraform-docs markdown . > README.md` |
| State Mgmt | Remote state with locking | S3 + DynamoDB backend |


## Workflow

1. Write HCL: `main.tf`, `variables.tf` (type + description mandatory), `outputs.tf`, `versions.tf`
2. Validate: `terraform validate` → `tflint` → `checkov` → `trivy` — stop on any failure
3. Review: `terraform plan` → inspect diff for unintended changes → share plan with team
4. Apply: use `terraform apply` with remote state locking
5. Post-deploy: run `terraform-docs` to update README, verify drift detection is enabled
6. Import existing resources: `terraform state list` first → `terraform import` with dry-run flag

## Anti-patterns

FAIL: Hardcoding secrets in Terraform files
```hcl
# BAD
variable "db_password" {
  default = "supersecret123"
}
```
PASS: Use sops, Vault, or env vars
```hcl
# GOOD
variable "db_password" {
  type      = string
  sensitive = true
  description = "Database password — set via env or sops"
}
```

FAIL: Using `count` instead of `for_each`
```hcl
# BAD — count uses index, reordering destroys/recreates
resource "aws_route_table" "rt" {
  count = length(var.subnets)
  subnet_id = var.subnets[count.index]
}
```
PASS: Use `for_each` with deterministic keys
```hcl
# GOOD — each key is independent
resource "aws_route_table" "rt" {
  for_each = { for i, s in var.subnets : i => s }
  subnet_id = each.value
}
```

FAIL: Using `latest` for module versions
```hcl
# BAD
source  = "terraform-aws-modules/vpc/aws"
version = "~> 5.0"
```
PASS: Pin to exact version
```hcl
# GOOD
source  = "terraform-aws-modules/vpc/aws"
version = "5.0.0"
```

FAIL: Skipping validation before apply
```
# BAD: skip checkov because "it passes locally"
terraform apply --auto-approve  # no validation
```
PASS: Mandatory 3-layer validation
```
# GOOD: fail CI if any layer fails
terraform validate && tflint && checkov -d . && trivy config .
```

## References

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) · last_verified: 2026-08-08
- [checkov — Infrastructure Security](https://www.checkov.io/) · last_verified: 2026-08-08
- [trivy — Vulnerability Scanning](https://trivy.dev/latest/) · last_verified: 2026-08-08

- [references/module-patterns.md](references/module-patterns.md)


## Verification Checklist

- [ ] 3-layer validation passed: `tflint` → `checkov` → `trivy`
- [ ] `terraform plan` reviewed for unintended changes before apply
- [ ] Remote state with locking configured (S3 + DynamoDB)
- [ ] `for_each` used over `count` (deterministic resource keys)
- [ ] Module versions pinned to exact tag (never `latest`)
- [ ] `type` + `description` present on all input variables
- [ ] No secrets hardcoded — using sops, Vault, or Secrets Manager
- [ ] Tags `Environment`, `Service`, `Owner` present on all resources

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `terraform apply` fails with state locking error | Another process holds the lock | Wait for lock to release; use `force-unlock` only if you verified the lock is stale |
| checkov reports HIGH violation on S3 bucket | Bucket missing `block_public_acls` or encryption | Add `aws_s3_bucket_public_access_block` and `server_side_encryption_configuration` |
| Drift detected after `terraform apply` | Out-of-band change or manual resource modification | Run `terraform plan` to identify drift; import drifted resources or revert manual changes |
| `terraform import` succeeds but plan shows full destroy (edge case: resource address mismatch) | Imported address does not match module resource pattern | Use `terraform state list` to verify imported address format matches module structure exactly |

| [WARN] `terraform plan` shows no changes but `apply` still modifies resources | Provider schema version mismatch between plan-time and apply-time; computed fields resolved at apply | Pin provider version in `required_providers`; run `terraform validate` before each apply |
| terraform import succeeds but the resource is immediately recreated on next apply | Terraform attributes differ from real resource state; import does not set all required fields | Run terraform plan immediately after import; capture missing attrs with terraform state show |
| Known bug: terraform plan succeeds but apply fails with provider registry timeout on first run | Terraform init fetches provider plugins; plan uses cached plugins but apply retries registry lookup | Run terraform init before each apply in CI; pin provider version to avoid re-fetch |
