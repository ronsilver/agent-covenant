# Workflows Catalog (10)

Slash-command workflows for common development tasks. Invoke with `/workflow-name` in the agent chat.

Each workflow lives in `content/workflows/<category>/<name>.md`.

## Synced Locations

| Agent | Path |
|-------|------|
| **Windsurf** | `~/.windsurf/workflows/` |
| **Windsurf JetBrains** | `~/.codeium/workflows/` |
| **Antigravity** | `~/.gemini/antigravity/workflows/` |
| **local-project** | `<project>/.windsurf/workflows/` (when enabled) |

---

## Validation (3)

| Workflow | Slash Command | Description |
|----------|--------------|-------------|
| `validation/lint.md` | `/lint` | Run linters with comprehensive checks (shellcheck, shfmt, golangci-lint, ruff, eslint, tflint) |
| `validation/test.md` | `/test` | Run project tests with coverage requirements |
| `validation/validate.md` | `/validate` | Validate current project code (manifest, frontmatter, file references) |

## Git (3)

| Workflow | Slash Command | Description |
|----------|--------------|-------------|
| `git/pre-push.md` | `/pre-push` | Comprehensive pre-push checks (lint → test → validate → security scan) |
| `git/pr-review.md` | `/pr-review` | Review a Pull Request end-to-end using `gh` CLI |
| `git/fix-pr-comments.md` | `/fix-pr-comments` | Systematically address PR review comments |

## Infrastructure (3)

| Workflow | Slash Command | Description |
|----------|--------------|-------------|
| `infrastructure/terraform-module.md` | `/terraform-module` | Create a Terraform module following best practices (3-layer validation, tflint + checkov + trivy) |
| `infrastructure/docker-build.md` | `/docker-build` | Build Docker image with strict validation (hadolint, multi-stage, vulnerability scanning) |
| `infrastructure/k8s-validate.md` | `/k8s-validate` | Validate Kubernetes manifests (kubeconform, helm lint, kube-linter) |

## Security (1)

| Workflow | Slash Command | Description |
|----------|--------------|-------------|
| `security/security-check.md` | `/security-check` | Deep security analysis (OWASP Top 10, SAST, secret detection, IAM review, dependency CVEs) |

---

## Workflow Frontmatter Format

```markdown
---
description: Short description shown in agent's slash-command list
---

## Steps

1. ...
2. ...
```

## Adding a New Workflow

1. Create `content/workflows/<category>/<name>.md` with `description` frontmatter.
2. Add the path to `manifest.yaml` under `workflows.files`.
3. Run `make sync`.
