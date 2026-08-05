# AWS Tagging Strategy

## Mandatory Tags

Every resource must have these tags:

| Tag | Example | Purpose |
|-----|---------|---------|
| `Environment` | `production`, `staging`, `development` | Environment isolation |
| `Project` | `my-app`, `analytics`, `ml-pipeline` | Cost allocation |
| `CostCenter` | `engineering-12345` | Billing attribution |
| `ManagedBy` | `terraform`, `terraform` | IaC origin tracking |

## Recommended Tags

| Tag | Example | Purpose |
|-----|---------|---------|
| `Owner` | `team-platform` | Team contact |
| `CreatedBy` | `terraform-apply` | Automation audit |
| `TerraformModule` | `ecs-service` | Module source tracking |
| `DataClassification` | `restricted`, `internal`, `public` | Compliance |

## Enforcement

- Terraform: `default_tags {}` in the provider block
- SCP: deny creation of untagged resources
- Config rule: `required-tags` custom rule
- Cost Explorer: group by `Project` and `Environment`

## Terraform Pattern

```hcl
provider "aws" {
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}
```
