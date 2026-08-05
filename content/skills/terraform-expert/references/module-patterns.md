# Terraform Module Patterns

## Standard Module
```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Deployment environment (dev/staging/prod)"
}
variable "instance_count" {
  type        = number
  description = "Number of instances"
  default     = 3
}

# main.tf
resource "aws_ecs_service" "this" {
  name            = "${var.environment}-api"
  cluster         = data.aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.instance_count
  launch_type     = "FARGATE"
  network_configuration { ... }
}

# outputs.tf
output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.arn
}
```

## Remote State
```hcl
terraform {
  backend "s3" {
    bucket         = "example-terraform-state"
    key            = "prod/infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Naming Convention
- Resources: `snake_case`
- Variables/Outputs: `snake_case`
- Tags: `Environment`, `Service`, `Owner` (minimum)

## for_each vs count
```hcl
# PREFERRED: for_each (deterministic keys, no re-indexing)
resource "aws_instance" "this" {
  for_each = toset(var.availability_zones)
  availability_zone = each.value
}

# OK: count (simple cases, no key dependency)
resource "aws_instance" "this" {
  count = var.instance_count
}
```
