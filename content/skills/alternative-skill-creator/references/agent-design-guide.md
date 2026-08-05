# Creating Specialized Agents with Skills

This guide explains how to create specialized agents by leveraging the skills system to transform Claude from a general-purpose assistant into domain-specific experts.

## Understanding Specialized Agents

A **specialized agent** is an instance of Claude equipped with domain-specific knowledge, workflows, and tools that enable it to perform tasks in a particular area with expert-level proficiency.

### Agent Transformation Through Skills

Skills transform Claude into specialized agents by providing:

1. **Procedural Knowledge** - Step-by-step workflows that no model can fully possess through training alone
2. **Domain Context** - Company-specific schemas, business logic, and domain expertise
3. **Tool Access** - Scripts and utilities for deterministic, complex operations
4. **Contextual Assets** - Templates, references, and resources for consistent output

**Example transformations:**

- General Claude + `pdf-editor` skill → **PDF Processing Agent**
- General Claude + `big-query` skill → **Data Analytics Agent**
- General Claude + `frontend-webapp-builder` skill → **Frontend Development Agent**
- General Claude + `order-processing-expert` skill → **Order Processing Agent**

## Designing Specialized Agents

### Step 1: Identify the Agent Domain

Define the specific domain or task area your agent will specialize in:

**Clear domain definition:**
- PASS: "Order processing API integration and EDI message handling"
- PASS: "React/Next.js frontend development with TypeScript"
- PASS: "PostgreSQL database design and query optimization"
- FAIL: "General programming" (too broad)
- FAIL: "Help with files" (too vague)

**Questions to answer:**
- What specific tasks will this agent perform?
- What expertise does it need that general Claude lacks?
- What repetitive workflows or knowledge does it require?
- What tools or integrations are essential?

### Step 2: Define Agent Capabilities

Map out the specific capabilities your specialized agent needs:

**Capability categories:**

1. **Knowledge capabilities** - What must the agent know?
   - Database schemas, API specifications, business rules
   - Domain terminology, standards, protocols
   - Company policies, compliance requirements

2. **Procedural capabilities** - What workflows must the agent execute?
   - Multi-step processes, deployment procedures
   - Testing strategies, debugging workflows
   - Code review patterns, security audits

3. **Tool capabilities** - What operations require deterministic execution?
   - Data transformations, file processing
   - API integrations, system commands
   - Code generation, validation scripts

4. **Output capabilities** - What artifacts must the agent produce?
   - Code templates, configuration files
   - Documentation, reports, diagrams
   - Test suites, deployment manifests

### Step 3: Design the Skill Architecture

Organize agent capabilities into a skill structure:

#### Single-Domain Agent (Simple)

For agents focused on one domain:

```
order-processor/
├── SKILL.md                    # Core agent instructions
├── scripts/
│   ├── validate_order.py       # Order message validation
│   └── parse_edi.py            # EDI format parsing
├── references/
│   └── edi-spec.md             # EDI specification
└── assets/
    └── message-templates/      # Standard message formats
```

#### Multi-Domain Agent (Moderate)

For agents that handle multiple related domains:

```
cloud-infrastructure/
├── SKILL.md                    # Overview + workflow selection
├── scripts/
│   ├── validate_terraform.sh
│   └── cost_estimator.py
└── references/
    ├── aws.md                  # AWS-specific patterns
    ├── gcp.md                  # GCP-specific patterns
    └── azure.md                # Azure-specific patterns
```

Claude loads only the relevant domain reference when needed.

#### Complex Agent (Advanced)

For agents requiring extensive domain knowledge:

```
fullstack-developer/
├── SKILL.md                    # Agent overview + navigation
├── scripts/
│   ├── init_project.py
│   ├── setup_testing.sh
│   └── deploy.sh
├── references/
│   ├── frontend/
│   │   ├── react-patterns.md
│   │   ├── state-management.md
│   │   └── testing.md
│   ├── backend/
│   │   ├── api-design.md
│   │   ├── database.md
│   │   └── auth.md
│   └── deployment/
│       ├── docker.md
│       └── kubernetes.md
└── assets/
    ├── frontend-template/
    ├── api-template/
    └── docker-compose.yml
```

### Step 4: Implement Agent Instructions

Write SKILL.md to guide the agent's behavior:

#### Frontmatter: Agent Trigger Definition

```yaml
---
name: order-processor
description: Expert agent for order processing API integration, EDI message handling, provider adapter implementation, and transaction flow debugging. Use when working with order management systems, messaging protocols, or implementing provider integrations.
---
```

**Key principles:**
- Include **what** the agent does AND **when** to activate it
- List all relevant triggers and contexts
- Be specific about domains, technologies, and use cases

#### Body: Agent Operating Instructions

Structure the body to guide agent behavior:

**1. Agent Overview**

```markdown
# Order Processing Agent

This agent specializes in order processing API integration and EDI message handling.

## Core Capabilities

- EDI order message parsing and validation
- Provider adapter implementation patterns
- Transaction flow debugging
- Order protocol compliance
```

**2. Workflow Guidance**

```markdown
## Standard Workflows

### Implementing a New Provider Adapter

1. Review provider documentation in `references/provider-specs/`
2. Use `scripts/generate_adapter.py` to create adapter scaffold
3. Implement message transformation logic
4. Add integration tests using `scripts/test_adapter.py`
5. Validate with `scripts/validate_order.py`

### Debugging Transaction Failures

1. Extract transaction logs
2. Parse EDI order messages with `scripts/parse_edi.py`
3. Check field mappings in `references/edi-spec.md`
4. Validate against provider requirements
5. Identify transformation errors
```

**3. Knowledge Access Patterns**

```markdown
## Reference Documentation

- **EDI Protocol**: See `references/edi-spec.md` for message structure
- **Provider Specifications**: See `references/provider-specs/` for provider-specific details
- **Adapter Patterns**: See `references/adapter-patterns.md` for implementation examples
```

**4. Tool Usage Instructions**

```markdown
## Available Tools

### Message Validation
Use `scripts/validate_order.py` to validate order format:
```bash
scripts/validate_order.py <order-file>
```

### Adapter Generation
Use `scripts/generate_adapter.py` to scaffold new adapters:
```bash
scripts/generate_adapter.py --provider <provider-name>
```
```

### Step 5: Optimize Agent Context Efficiency

Apply progressive disclosure to keep the agent efficient:

**Level 1: Metadata (Always loaded)**
- Keep description comprehensive but under 100 words
- Include all trigger conditions
- List key capabilities

**Level 2: SKILL.md Body (Loaded when triggered)**
- Keep core workflows and navigation under 500 lines
- Link to detailed references
- Provide essential procedural guidance

**Level 3: Resources (Loaded as needed)**
- Split domain-specific details into separate files
- Organize by domain, framework, or use case
- Let Claude load only what's needed

**Example optimization:**

FAIL: **Inefficient (everything in SKILL.md):**
```markdown
# Database Agent (5000 lines)
## PostgreSQL Patterns
[500 lines of PostgreSQL details]
## MySQL Patterns
[500 lines of MySQL details]
## MongoDB Patterns
[500 lines of MongoDB details]
...
```

PASS: **Efficient (progressive disclosure):**
```markdown
# Database Agent (200 lines)
## Supported Databases
- PostgreSQL: See references/postgresql.md
- MySQL: See references/mysql.md
- MongoDB: See references/mongodb.md

## Workflow
1. Identify database type
2. Load relevant reference
3. Apply patterns
```

## Agent Specialization Patterns

### Pattern 1: Technical Stack Agent

Agents specialized in specific technology stacks:

```yaml
---
name: go-microservice-expert
description: Design and implement production-ready Go microservices with Gin, GORM, gRPC, and OpenTelemetry. Use for Go service architecture, API handlers, database access, or observability.
---
```

**Characteristics:**
- Deep technical knowledge of specific frameworks
- Code patterns and best practices
- Integration with ecosystem tools

### Pattern 2: Domain Expert Agent

Agents specialized in business or technical domains:

```yaml
---
name: financial-compliance-auditor
description: Audit financial systems for compliance with PCI-DSS, SOX, and regulatory requirements. Use for security reviews, compliance checks, or financial system audits.
---
```

**Characteristics:**
- Domain-specific regulations and standards
- Audit procedures and checklists
- Compliance validation tools

### Pattern 3: Workflow Automation Agent

Agents specialized in executing complex workflows:

```yaml
---
name: deployment-orchestrator
description: Orchestrate zero-downtime deployments across multiple environments with rollback strategies. Use for production deployments, release management, or deployment automation.
---
```

**Characteristics:**
- Step-by-step procedures
- Safety checks and validations
- Automated execution scripts

### Pattern 4: Analysis and Diagnostics Agent

Agents specialized in analysis and problem-solving:

```yaml
---
name: performance-analyzer
description: Analyze and optimize code performance through profiling and bottleneck identification. Use for performance optimization, latency reduction, or throughput improvement.
---
```

**Characteristics:**
- Diagnostic workflows
- Analysis methodologies
- Optimization strategies

## Best Practices for Agent Design

### 1. Single Responsibility Principle

Each agent should have one clear specialization:

- PASS: `kubernetes-expert` - K8s deployment and troubleshooting
- PASS: `react-developer` - React/Next.js development
- FAIL: `fullstack-everything` - Too broad, dilutes expertise

### 2. Clear Activation Triggers

Define explicit conditions that should activate the agent:

```yaml
description: Build secure, optimized Docker images and compose setups. Use when: (1) creating Dockerfiles, (2) optimizing images, (3) fixing Docker issues, or (4) setting up docker-compose.
```

### 3. Procedural Over Declarative

Focus on HOW to do things, not just WHAT things are:

- PASS: "To implement JWT authentication: 1. Install library, 2. Create middleware..."
- FAIL: "JWT is a token-based authentication standard..."

### 4. Tools for Determinism

Provide scripts for operations that must be consistent:

- PASS: `scripts/rotate_pdf.py` - Same rotation logic every time
- FAIL: Rewriting PDF rotation code each time (inconsistent)

### 5. References for Knowledge

Store detailed knowledge in references, not SKILL.md:

- PASS: SKILL.md: "See references/api-spec.md for endpoint details"
- FAIL: SKILL.md: [10 pages of API documentation]

### 6. Templates for Consistency

Use assets for consistent output:

- PASS: `assets/service-template/` - Standard microservice structure
- FAIL: Recreating service structure from scratch each time

## Agent Testing and Iteration

### Testing Your Agent

1. **Concrete Examples** - Test with real-world scenarios
   - "Implement authentication for this API"
   - "Debug this failing K8s deployment"
   - "Optimize this slow database query"

2. **Trigger Validation** - Verify the agent activates correctly
   - Test with expected trigger phrases
   - Ensure no false positives (activating when it shouldn't)
   - Check for false negatives (not activating when it should)

3. **Workflow Execution** - Validate the agent follows procedures
   - Does it use the provided scripts?
   - Does it reference documentation correctly?
   - Does it produce expected output?

4. **Context Efficiency** - Monitor token usage
   - Is the description concise enough?
   - Is SKILL.md under 500 lines?
   - Are references loaded only when needed?

### Iteration Workflow

After deploying your agent:

1. **Use** - Apply the agent to real tasks
2. **Observe** - Note where it struggles or is inefficient
3. **Diagnose** - Identify missing knowledge, unclear workflows, or inefficient patterns
4. **Update** - Add missing scripts, clarify instructions, reorganize content
5. **Validate** - Test again with the same scenarios
6. **Deploy** - Package and distribute updated agent

**Common iteration scenarios:**

- **Agent doesn't activate** → Improve description triggers
- **Agent misunderstands workflow** → Clarify SKILL.md instructions
- **Agent rewrites same code** → Add script to avoid repetition
- **Agent can't find information** → Add reference documentation
- **Context bloat** → Move details from SKILL.md to references
- **Inconsistent output** → Add templates to assets

## Multi-Agent Patterns

For complex systems, combine multiple specialized agents:

### Complementary Agents

Agents that work together on different aspects:

- `go-microservice-expert` - Service implementation
- `kubernetes-expert` - Deployment and orchestration
- `postgres-database-expert` - Database design
- `opentelemetry-observability` - Monitoring and tracing

User activates the appropriate agent for each task phase.

### Hierarchical Agents

General agent that delegates to specialized sub-agents:

```yaml
---
name: platform-architect
description: Design complete platform architectures by coordinating infrastructure, services, and data layers. Delegates to specialized agents for implementation details.
---
```

References other agents in workflows:
- "For service implementation, use go-microservice-expert"
- "For database schema, use postgres-database-expert"

### Pipeline Agents

Agents designed for sequential workflow stages:

1. `api-designer` - Design API specification
2. `code-generator` - Generate service code
3. `test-generator` - Create test suites
4. `deployment-orchestrator` - Deploy to production

Each agent produces input for the next stage.

## Summary

Creating effective specialized agents requires:

1. **Clear domain definition** - Know exactly what expertise the agent provides
2. **Capability mapping** - Identify knowledge, workflows, tools, and outputs needed
3. **Efficient architecture** - Organize content with progressive disclosure
4. **Precise instructions** - Write clear, actionable guidance in SKILL.md
5. **Continuous iteration** - Test, observe, and improve based on real usage

The skills system transforms Claude from a capable generalist into a domain expert by providing the procedural knowledge, context, and tools that training alone cannot deliver.
