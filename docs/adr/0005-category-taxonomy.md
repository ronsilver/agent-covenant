# ADR 0005: Skill Category Taxonomy

**Date:** 2026-04-27
**Status:** Accepted

## Context

Skill frontmatter `metadata.category` had ~22 distinct values across 102 skills with no controlled vocabulary. This fragmented routing and made `skill-index.md` organization inconsistent.

## Decision

**Controlled category vocabulary** (10 values):

| Value            | Covers                                                                                                    |
| ---------------- | --------------------------------------------------------------------------------------------------------- |
| `infrastructure` | Cloud, IaC, K8s, Docker, GitOps, serverless, CDN, FinOps                                                  |
| `backend`        | Go, Java, Node.js, Python, gRPC, messaging, databases                                                     |
| `frontend`       | React, Next.js, state management, design tokens, i18n, a11y                                               |
| `observability`  | OpenTelemetry, PromQL, operational excellence                                                             |
| `security`       | Security audit, threat hunting, OAuth/JWT, Vault, webhooks                                                |
| `quality`        | Code review, TDD, refactoring, linting, performance, simplify, verification                               |
| `devops`         | GitHub Actions, Git protocol, mobile CI/CD, chaos, disaster recovery                                      |
| `core`           | Operating protocol, engineering standards, context management, tool-usage, token-efficiency, skill-router |
| `ai-agents`      | Multi-agent patterns, evaluation, memory, RAG, prompting, BDI, tool-design, hosted-agents                 |

Values not in this list should be migrated at next major version bump.

## Consequences

- Existing skills with non-standard categories (e.g., `engineering`, `development`, `org-navigation`, `data-analysis`) should update at their next modification
- `skill-creator` should use this taxonomy when creating new skills
- `validate.sh` does NOT enforce this taxonomy (see ADR 0002); it is a convention only
