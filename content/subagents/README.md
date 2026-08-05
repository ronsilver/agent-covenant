# Sub-agents Catalog

15 active sub-agents organized into read-only analysis, read-only review specialists, and write agents.

## Taxonomy

| Group | Count | Agents |
|---|---|---|
| Meta / analysis (read-only) | 6 | `ultraplan`, `ultrareview`, `ultradebugger`, `ultrathinking`, `ultraresearch`, `research` |
| Review specialists (read-only) | 6 | `code-review`, `dependency-audit-agent`, `idempotency-agent`, `linting-agent`, `performance-profiler`, `security-auditor` |
| Write agents | 3 | `ultracode`, `git-requests`, `test-writer` |

## Orchestration flow

```
ultraplan -> plan (stdout) -> host persists -> ultracode
ultrareview / code-review -> task(s) to specialists -> to-do -> ultracode
ultradebugger -> root-cause report + fix proposal + test spec -> ultracode
research -> findings document -> ultraplan / ultracode
ultracode -> git-requests (branch, commit, push, PR)
```

Only `ultracode` mutates project source code. Only `git-requests` mutates git history. `test-writer` is the explicit exception for writing tests.

### Restricted delegation graph (permission.task)

| Agent | `permission.task` |
|---|---|
| Orchestrators (`ultrareview`, `code-review`) | allow only the 5 review specialists; deny `ultracode`/`test-writer`/`git-requests` |
| `ultradebugger`, `research`, `ultraplan`, `ultrathinking`, `ultraresearch` | specialists/research allowed or `ask`; deny write agents (`ultracode`, `test-writer`, `git-requests`) |
| `ultracode` | allow only `git-requests`, `test-writer`; ask rest |
| Specialists (`dependency-audit-agent`, `idempotency-agent`, `linting-agent`, `performance-profiler`, `security-auditor`) + `test-writer` | `"*": deny` (leaves) |
| `git-requests` | deny `ultracode`/`test-writer`; others allowed |

### Mandatory body sections

Every subagent must include the following sections in its body (after `## Anti-patterns`):

| Section | Applies to | Purpose |
|---|---|---|
| `Session start — load boot skills` | All 15 | Mandatory load of all 7 boot skills (6 core + `skill-router`) at Step 0, before any task; `git-requests` additionally loads `git-expert` at init |
| `Execution red line` | `ultraplan` | Forbids any mutation or write delegation |
| `Phase autonomy` + `Mandatory validation` | `ultracode` | Enables continuous execution + mandatory test output |
| `Scope restriction (read-only -- ABSOLUTE)` | 10 read-only agents | Forbids fixing or delegating writes |
| `Skill-router fallback` | All 15 | Dynamic skill discovery instead of blocking |
| `Clarify-first` | All 15 | Ask before assuming when info is missing |
| `Be critical` | `ultraplan`, `ultracode`, `research`, `ultrathinking` | Challenge the premise; counteract agreeableness |
| `Known blind spots` | All 15 | Per-agent documented weaknesses |
| `Delegation discipline` | All 15 | No `task` for trivial operations |

---

## 1. Meta / Analysis Agents (read-only)

| Sub-agent | Purpose |
|---|---|
| **`ultraplan`** | Converts ambiguous goals into deterministic, verifiable execution plans with DAG dependencies, binary success criteria, and pre-mortem risk analysis. |
| **`ultrathinking`** | Deep-reasoning strategist; explores k candidate approaches, stress-tests them, and emits a Reasoning Dossier that settles the design before planning. |
| **`ultrareview`** | Elite full-audit reviewer; orchestrates the 6 review specialists and synthesizes a single verdict. |
| **`ultradebugger`** | Root-cause debugger using the scientific method; delivers cause, minimum fix proposal, and regression test spec. |
| **`ultraresearch`** | External-facts specialist; surveys and cross-verifies vendors, libraries, APIs, and standards into a Research Dossier. |
| **`research`** | Investigates codebases and web sources; produces a findings document with citations and trade-offs. |

## 2. Review Specialists (read-only)

| Sub-agent | Purpose |
|---|---|
| **`code-review`** | PR-focused reviewer; reads diffs and orchestrates the 6 specialists. |
| **`dependency-audit-agent`** | CVEs, version drift, licenses, and supply-chain risk scanning. |
| **`idempotency-agent`** | Verifies idempotency design in critical write operations. |
| **`linting-agent`** | Runs multi-language linters/formatters and reports violations. |
| **`performance-profiler`** | Profiles hot paths and proposes optimizations with benchmark plans. |
| **`security-auditor`** | SAST, OWASP, IAM, input validation, secrets scanning, and AI safety. |

## 3. Write Agents

| Sub-agent | Purpose | Exception |
|---|---|---|
| **`ultracode`** | The Implementer. Executes plans and to-dos task by task; only agent that mutates project source code. | -- |
| **`test-writer`** | Writes unit, integration, and E2E tests. | Explicit write exception. |
| **`git-requests`** | End-to-end git workflow: branch, >=2 conventional commits, push, PR. | Writes only to git, never app logic. |

---

## Deprecated subagents

The following subagents from the original 53-agent catalog (6 axes) were removed and consolidated into skills. They are listed here for historical reference. Their domain knowledge now lives in the corresponding skill under `content/skills/`.

### By language (11 -- consolidated into language-specific skills)

| Sub-agent | Original purpose | Consolidated into skill |
|---|---|---|
| `go-agent` | Go microservice development with Gin, gRPC, `go-kit` | `golang-expert` |
| `typescript-agent` | React + Next.js 14, web SDKs, admin UIs | `typescript-expert` |
| `python-agent` | FastAPI, LangGraph, data pipelines, AI/ML | `python-expert` |
| `ruby-agent` | Rails web application development | `ruby-expert` |
| `java-agent` | Java 17+ / Spring Boot | `java-expert` |
| `scala-agent` | Apache Spark ETL data pipelines | `scala-expert` |
| `swift-agent` | iOS SDK + demo client | `swift-expert` |
| `kotlin-agent` | Android SDK | `kotlin-expert` |
| `hcl-terraform-agent` | Terraform + Terragrunt for AWS IaC | `terraform-expert` |
| `plpgsql-agent` | PostgreSQL migrations + stored procedures | `postgres-database-expert` |
| `shell-agent` | Bash for CI/CD, Helm hooks, Airflow operators | `scripting-expert` |

### Operational (9 -- consolidated into quality/security/ops skills)

| Sub-agent | Original purpose | Consolidated into skill |
|---|---|---|
| `documentation-writer` | READMEs, ADRs, docstrings, OpenAPI docs, Mermaid diagrams | `documentation-expert` |
| `pci-dss-compliance-agent` | Regulatory compliance enforcement (data privacy, audit scope) | `security-expert` |
| `secret-scanner` | Detect exposed secrets in code, history, configs, CI logs | `security-expert` |
| `migration-validator` | Validate DB / infra / K8s migrations: zero-downtime, rollback | `postgres-database-expert` |
| `ci-cd-validator` | GitHub Actions, Helm, Dockerfiles, ArgoCD manifests review | `github-actions-expert` + `helm-expert` |
| `observability-agent` | Grafana dashboards, PromQL alerts, OTEL tracing, Zap logs | `operational-excellence` |
| `incident-responder` | Runbooks, postmortems, T3 escalation, DR drills, chaos | `operational-excellence` |
| `code-reviewer` | PR review: security, performance, best practices, SOLID | `reviewer-expert` (replaced by `code-review` subagent) |
| `test-writer` (original) | Unit / integration / E2E tests, AAA, table-driven, pyramid | `testing-expert` (kept as `test-writer` subagent with enriched content) |

### Domain-specific (4 -- consolidated into domain skills)

| Sub-agent | Original purpose | Consolidated into skill |
|---|---|---|
| `anomaly-agent` | Anomaly detection orchestrator | `security-expert` |
| `auth-agent` | OAuth/OIDC/JWT authentication flows (B2B and consumer) | `security-expert` |
| `secrets-management-agent` | HashiCorp Vault secret management | `security-expert` |
| `webhook-agent` | Inbound webhook HMAC verification + outbound delivery | `idempotency-expert` |

### Granular cross-cutting (12 -- consolidated into architecture/infra skills)

| Sub-agent | Original purpose | Consolidated into skill |
|---|---|---|
| `api-designer-agent` | OpenAPI/Swagger contract-first, REST conventions, RFC 7807 | `openapi-expert` |
| `rate-limiter-agent` | krakend/apigw rate limiting, token bucket, anti-DDoS | `scalability-expert` |
| `messaging-agent` | RabbitMQ, SQS, SNS, Kinesis -- producer/consumer/DLQ/outbox | `scalability-expert` |
| `event-sourcing-agent` | Event Sourcing + CQRS for distributed state | `architecture-expert` |
| `notification-agent` | Email/SMS/push/webhook delivery | `scalability-expert` |
| `feature-flag-agent` | Flag lifecycle, gradual rollouts, A/B tests | `architecture-expert` |
| `cache-agent` | Redis cache-aside, TTL design, pub/sub, Lua scripts | `redis-cache-expert` |
| `nosql-agent` | MongoDB Atlas + DynamoDB single-table design | `mongodb-expert` + `dynamodb-expert` |
| `serverless-agent` | AWS Lambda for data pipelines, event processors | `aws-cloud-expert` |
| `cdn-agent` | CloudFront for SDK delivery, WAF, SSL/TLS | `aws-cloud-expert` |
| `graphql-agent` | GraphQL schemas, DataLoader N+1 prevention | `typescript-expert` |
| `websocket-agent` | WebSocket / SSE for real-time UI / dashboard updates | `scalability-expert` |

### Frontend-specific + AI/ML (4 -- consolidated into frontend/AI skills)

| Sub-agent | Original purpose | Consolidated into skill |
|---|---|---|
| `a11y-agent` | WCAG 2.2 Level AA -- keyboard nav, ARIA, contrast, screen reader | `accessibility-expert` |
| `i18n-agent` | Internationalization -- regional language variants | `typescript-expert` |
| `design-system-agent` | Design tokens for a white-label UI SDK | `typescript-expert` |
| `rag-agent` | RAG pipelines for the AI context layer -- chunking, embeddings | `agent-architecture-expert` |
| `mlops-agent` | Model lifecycle -- versioning, A/B testing, drift detection | `llm-expert` |
| `mcp-server-builder-agent` | Build MCP servers -- transport, tool schemas, auth | `mcp-expert` |

---

## File Format

Each sub-agent file follows YAML frontmatter + body:

```markdown
---
name: <kebab-case-name>
description: <1-line purpose>
permissionMode: read | build | full
mode: subagent                  # subagent = invoked via task (default for all subagents)
# NOTE: `hidden:` is forbidden (ADR-0021) and `model:` is forbidden (ADR-0023).
targets:
  - opencode
  - claudecode
  - cursor
  - codex
  - gemini
permission:
  read: allow | ask | deny
  edit: allow | ask | deny
  glob: allow | ask | deny
  grep: allow | ask | deny
  list: allow | ask | deny
  bash:
    "*": ask
    "<pattern>": allow | ask | deny
  task: allow | ask | deny
  webfetch: allow | ask | deny
  websearch: allow | ask | deny
  question: allow
  apply_patch: deny
  codesearch: allow | ask | deny
  doom_loop: ask
  external_directory: deny
  lsp: allow | ask | deny
  plan_enter: deny
  plan_exit: deny
  skill: allow | ask | deny
  todoread: deny
  todowrite: deny
---

# <Title>

## Core responsibilities
...

## Skills to invoke
...

## Workflow
...

## Output format
...

## Anti-patterns
...
```

### Role profiles

- **Planner** (`mode: subagent`): `edit: deny`; `question/plan_enter/plan_exit/todoread/todowrite: allow`; asks before planning, creates task lists; host agent owns file persistence.
- **Builder** (`mode: subagent`): `edit: allow`; `question/plan_enter/plan_exit/todoread/todowrite: allow`; executes plans and marks tasks done.
- **Reviewer / debugger** (`mode: subagent`): `question/todoread/todowrite: allow`; `plan_enter/plan_exit: deny`; tracks review items.
- **Investigator** (`mode: subagent`): `question: allow`; `plan_enter/plan_exit/todowrite: deny`; works autonomously after scope is set.
- **Domain expert / specialist** (`mode: subagent`): all 5 interactive fields `deny`; fully autonomous, invoked via `task`.
- **Git workflow** (`mode: subagent`): `edit: deny`; all interactive fields `deny`; operates only with git/gh commands.

See the canonical schema: [`docs/reference/subagent-schema.md`](../../docs/reference/subagent-schema.md) and the permissions reference: [`docs/reference/subagent-permissions.md`](../../docs/reference/subagent-permissions.md).

## How to Use

1. **In OpenCode / Claude Code / Cursor / Codex / Gemini**: invoke a sub-agent for tasks matching its purpose.
2. **Composition**: sub-agents reference each other for task orchestration via `task`.
3. **Sync**: deployed via `./scripts/sync.sh` per agent target.

## Maintenance

- **Adding a sub-agent**: create new `<name>.md` here + add to `manifest.yaml` `subagents.files` block.
- **Updating**: edit the file directly; sync redeploys to all agent targets.
- **Deprecation**: mark in this README + remove from `manifest.yaml`.
- **Versioning**: track changes in `CHANGELOG.md` at repo root.

Sync via `./scripts/sync.sh` per agent target.

See ADR `docs/adr/0001-hybrid-rules-architecture.md` for the full design rationale.
