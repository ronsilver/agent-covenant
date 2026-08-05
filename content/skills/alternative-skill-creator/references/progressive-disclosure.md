# Progressive Disclosure

## Three-Level Loading System

Skills use a three-level loading system to manage context efficiently:

| Level | When Loaded | Size | Purpose |
|-------|-------------|------|---------|
| **1. Metadata** | Always | ~100 tokens | Skill discovery and triggering |
| **2. SKILL.md body** | When triggered | <500 lines / <5000 tokens recommended | Core workflow and navigation |
| **3. Resources** | As needed | Unlimited | Detailed information and code |

### Level 1: Metadata (Always Loaded)

The `name` and `description` from YAML frontmatter are always in context.

**Example:**
```yaml
---
name: database-migration
description: Zero-downtime database migrations with rollback strategies. Use when modifying database schemas, changing column types, adding indexes, or performing data transformations in production environments.
---
```

This ~50 words is always loaded for every skill.

### Level 2: SKILL.md Body (Loaded When Triggered)

After the skill triggers, the markdown body is loaded.

**Target: <500 lines**

**Contents:**
- Quick reference tables
- Core workflow steps
- Links to bundled resources
- Essential constraints

### Level 3: Resources (Loaded As Needed)

Claude decides when to load scripts, references, or assets based on the task.

**No size limit** - Scripts can be executed without loading into context.

## Progressive Disclosure Patterns

### Pattern 1: High-Level Guide with References

Keep overview in SKILL.md, details in references.

```markdown
# PDF Processing

## Quick Start

Extract text with pdfplumber:
```python
import pdfplumber
with pdfplumber.open('document.pdf') as pdf:
    text = pdf.pages[0].extract_text()
```

## Advanced Features

- **Form filling**: See [references/forms.md](references/forms.md)
- **Table extraction**: See [references/tables.md](references/tables.md)
- **OCR integration**: See [references/ocr.md](references/ocr.md)
```

**Result**: Claude loads `forms.md` only when user needs form filling.

### Pattern 2: Domain-Specific Organization

For skills with multiple domains, organize by domain to avoid loading irrelevant context.

```
bigquery-skill/
├── SKILL.md (overview and domain selection)
└── references/
    ├── finance.md     - Revenue, billing, payment metrics
    ├── sales.md       - Opportunities, pipeline, conversions
    ├── product.md     - API usage, feature adoption
    └── marketing.md   - Campaigns, attribution, ROI
```

**SKILL.md:**
```markdown
# BigQuery Analytics

## Domain Selection

Choose the relevant domain:

| Domain | Reference | Use For |
|--------|-----------|---------|
| Finance | [references/finance.md](references/finance.md) | Revenue, billing, payments |
| Sales | [references/sales.md](references/sales.md) | Pipeline, opportunities |
| Product | [references/product.md](references/product.md) | API usage, features |
| Marketing | [references/marketing.md](references/marketing.md) | Campaigns, attribution |
```

**Result**: When user asks "How many sales opportunities do we have?", Claude only reads `sales.md`.

### Pattern 3: Framework/Variant Organization

For skills supporting multiple frameworks or platforms.

```
cloud-deploy/
├── SKILL.md (workflow + provider selection)
└── references/
    ├── aws.md      - AWS deployment patterns
    ├── gcp.md      - GCP deployment patterns
    └── azure.md    - Azure deployment patterns
```

**SKILL.md:**
```markdown
# Cloud Deployment

## Workflow

1. Choose cloud provider
2. Configure infrastructure
3. Deploy application
4. Verify deployment

## Provider-Specific Guides

- **AWS**: [references/aws.md](references/aws.md) - ECS, EKS, Lambda
- **GCP**: [references/gcp.md](references/gcp.md) - GKE, Cloud Run, Functions
- **Azure**: [references/azure.md](references/azure.md) - AKS, Container Instances
```

**Result**: When user chooses AWS, Claude only reads `aws.md`.

### Pattern 4: Conditional Details

Show basic content, link to advanced content.

```markdown
# DOCX Processing

## Creating Documents

Use docx-js for new documents:
```javascript
const docx = require('docx');
const doc = new docx.Document({
  sections: [{
    properties: {},
    children: [
      new docx.Paragraph({text: "Hello World"})
    ]
  }]
});
```

## Editing Documents

For simple edits, modify the XML directly.

**For tracked changes**: See [references/redlining.md](references/redlining.md)
**For OOXML details**: See [references/ooxml.md](references/ooxml.md)
**For styles and formatting**: See [references/formatting.md](references/formatting.md)
```

**Result**: Claude reads `redlining.md` only when user needs tracked changes.

## Guidelines for Splitting Content

### When to Split

**Split when:**
- PASS: SKILL.md approaching 500 lines
- PASS: Content has distinct use cases (different domains/frameworks)
- PASS: Detailed examples not always needed
- PASS: Reference material (schemas, APIs)

**NEVER split when:**
- FAIL: Content is core workflow (always needed)
- FAIL: Creating artificial separation
- FAIL: Files would be <20 lines

### How to Split

**1. Identify logical boundaries:**
- By domain (finance, sales, product)
- By feature (basic, advanced, troubleshooting)
- By framework (AWS, GCP, Azure)
- By workflow phase (setup, execution, validation)

**2. Create clear navigation in SKILL.md:**
```markdown
## Database Operations

| Operation | Guide | When to Use |
|-----------|-------|-------------|
| Migrations | [references/migrations.md](references/migrations.md) | Schema changes |
| Backups | [references/backups.md](references/backups.md) | Data protection |
| Replication | [references/replication.md](references/replication.md) | High availability |
```

**3. Use descriptive links:**

PASS: Good: "For zero-downtime migrations, see [references/migrations.md](references/migrations.md)"

FAIL: Bad: "More info [references/migrations.md](references/migrations.md)"

### Avoid Deep Nesting

**Bad (deeply nested):**
```
SKILL.md → references/overview.md → references/advanced/patterns.md
```

**Good (flat structure):**
```
SKILL.md → references/overview.md
SKILL.md → references/patterns.md
```

**Rule**: All references should link directly from SKILL.md (one level deep).

## Reference File Structure

For files >100 lines, include table of contents:

```markdown
# Advanced Patterns

## Table of Contents
- [Pattern 1: Event Sourcing](#pattern-1-event-sourcing)
- [Pattern 2: CQRS](#pattern-2-cqrs)
- [Pattern 3: Saga Pattern](#pattern-3-saga-pattern)

## Pattern 1: Event Sourcing
...

## Pattern 2: CQRS
...
```

This allows Claude to see the full scope when previewing the file.

## Complete Example

**Before (monolithic 800-line SKILL.md):**
```markdown
# Payment Processing

[600 lines of code examples for all payment providers]
[100 lines of error handling]
[50 lines of testing patterns]
[50 lines of troubleshooting]
```

**After (Progressive Disclosure):**

```markdown
# Payment Processing (100 lines)

## Quick Start
[Basic workflow - 30 lines]

## Payment Providers

| Provider | Guide |
|----------|-------|
| Stripe | [references/stripe.md](references/stripe.md) |
| PayPal | [references/paypal.md](references/paypal.md) |
| Square | [references/square.md](references/square.md) |

## Additional Resources

- **Error handling**: [references/errors.md](references/errors.md)
- **Testing**: [references/testing.md](references/testing.md)
- **Troubleshooting**: [references/troubleshooting.md](references/troubleshooting.md)
```

```
references/
├── stripe.md (150 lines)
├── paypal.md (150 lines)
├── square.md (150 lines)
├── errors.md (100 lines)
├── testing.md (100 lines)
└── troubleshooting.md (50 lines)
```

**Result**:
- SKILL.md: 800L → 100L (-87%)
- Total content: 800L → 800L (same information, better organized)
- Context loaded: Only what's needed for the current task
