# Workflows

10 slash-command workflows invoked via `/<name>` in agent chat. Organized in 4 categories.

## Available Workflows

| Category | Workflow | Description |
|---|---|---|
| **validation/** | `/lint` | Run linting and formatting |
| | `/test` | Run test suites |
| | `/validate` | Validate configuration and manifests |
| **git/** | `/pre-push` | Pre-push validation checklist |
| | `/pr-review` | Pull request review |
| | `/fix-pr-comments` | Address PR review comments |
| **infrastructure/** | `/terraform-module` | Terraform module creation |
| | `/docker-build` | Docker image build |
| | `/k8s-validate` | Kubernetes manifest validation |
| **security/** | `/security-check` | Security audit |

## Format

```yaml
---
name: workflow-name
description: What this workflow does
---
```

## Reference

→ Full catalog with descriptions and synced paths: [`docs/reference/workflows-catalog.md`](../../docs/reference/workflows-catalog.md)  
→ Adding a new workflow: [`AGENTS.md`](../../AGENTS.md) §Workflows
