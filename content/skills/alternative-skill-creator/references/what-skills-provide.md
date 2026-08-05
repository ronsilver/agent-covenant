# What Skills Provide

## The Problem Skills Solve

Claude has general knowledge but lacks:
- Company-specific schemas, business logic, and internal conventions
- Opinionated "do this, not that" for your stack
- Step-by-step workflows with exact commands
- Runnable code examples for your specific tech stack

Skills solve this by packaging curated, opinionated, domain-specific knowledge into an activatable module.

## What a Skill Delivers

### 1. Domain Context

Knowledge that Claude can't reliably infer from general training:

```
message-broker-expert provides:
- Internal adapter naming conventions
- Discovery service registration patterns
- Proprietary framing protocols
```

### 2. Opinionated Defaults

Removes "which approach?" decisions:

```
postgres-database-expert provides:
- "Use pgxpool for connection pooling, not database/sql"
- "Never use SELECT * — always name columns"
- "Use golang-migrate for migrations, not GORM AutoMigrate"
```

### 3. Actionable Patterns

Copy-paste code for common operations:

```go
// From go-microservice-expert: handler pattern
func (h *PaymentHandler) Create(c *gin.Context) {
    ctx, span := otel.Tracer("handler").Start(c.Request.Context(), "Create")
    defer span.End()
    // ...
}
```

### 4. Workflow Sequences

Ordered steps for complex tasks:

```
From review-implementing:
1. Requirements review
2. Design review
3. Implementation review
4. Operational review
```

## Skill vs. General Knowledge

| Task | Without Skill | With Skill |
|------|--------------|-----------|
| Write a Gin handler | Generic handler, maybe wrong patterns | Follows this project conventions exactly |
| Review a PR | Generic checklist | Domain-specific checklist with company standards |
| Deploy to K8s | Generic manifest | Includes security context, probes, NetworkPolicy |
| Write a migration | May use wrong tool | Uses golang-migrate with safe patterns |

## Progressive Disclosure Model

Skills use progressive disclosure to stay efficient:

```
SKILL.md (always loaded on trigger):
  - Core concepts (≤500 lines)
  - Reference navigation table
  - Most common patterns

references/*.md (loaded on demand):
  - Deep dives per topic
  - Exhaustive code examples
  - Advanced patterns
```

Claude reads `SKILL.md` when the skill triggers, then reads specific reference files only when the task requires that detail. This keeps context windows small and responses accurate.

## Skill Activation

A skill is activated when the user's request matches the skill's `description` trigger conditions. The trigger is matched semantically, not by exact keywords:

```yaml
# This description triggers on multiple phrasings:
description: Design RESTful APIs with OpenAPI/Swagger specifications, versioning,
and best practices. Use when creating new APIs, documenting endpoints, or reviewing
API design.

# Activates for:
# "Help me design the payment API"
# "Review this endpoint design"
# "What HTTP status code should I use?"
# "How should I version this API?"
```
