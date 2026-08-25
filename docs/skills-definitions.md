# Proposed Skills - just and necessary

---

## Core - always loaded, immutable

> [Core skills definition](skills-definitions.md)

---

## Languages - 1 skill = complete ecosystem

> Include in these skills: linting + best practices + Security + testing + debugging + opentelemetry instrumentation
> Included in the terraform skill, the spacelift tool and its cli called spacectl

| Skill | Absorbe | Description |
|---|---|---|
| golang-expert | go-microservice-expert + protobuf-grpc-expert + linting(Go) + OTEL(Go) | Complete Go development ecosystem: concurrent microservices, communication via gRPC/Protobuf, OpenTelemetry instrumentation and static analysis with specialized linters. |
| python-expert | python-fastapi-expert + langgraph-langchain-expert + linting(Python) | Python toolchain for async backend with FastAPI, agent flow orchestration with LangGraph/LangChain, and quality enforcement through linters and type checkers. |
| typescript-expert | react-nextjs-expert + nodejs-backend-expert + state-management-redux-zustand + frontend-testing-jest-vitest + linting(TS) | Full-TypeScript toolchain: SSR/CSR with Next.js, backend APIs with Node.js, state management with Redux/Zustand, unit and integration testing with Jest/Vitest and static analysis with strict ESLint/TSConfig. |
| java-expert | java-spring-expert + linting(Java) + enterprise patterns | Enterprise development with Spring Boot, application of Spring Boot architectural patterns (REST APIs, enterprise workflows), and static validation of code quality. |
| scala-expert | Spark DataFrame/Dataset, sbt, ScalaTest, PySpark | Distributed computing with Apache Spark (DataFrame/Dataset API), build management with sbt, functional testing with ScalaTest and interoperability with PySpark. |
| swift-expert | mobile-sdk-expert(iOS) + mobile-cicd-fastlane(iOS) | Native iOS development with Swift, mobile SDK build and distribution, and CI/CD pipeline automation via Fastlane and Xcode CLI. |
| kotlin-expert | mobile-sdk-expert(Android) + mobile-cicd-fastlane(Android) | Native Android development with Kotlin, SDK packaging, and continuous integration pipelines with Fastlane and Android Build Tools. |
| ruby-expert | Rails + Rails + RSpec | Web development with Ruby on Rails, customization of web applications with the Rails framework, and BDD/TDD testing with RSpec and Capybara. |
| scripting-expert | Bash/Zsh + PowerShell + ShellCheck | Infrastructure and OS automation via shell and PowerShell scripts, with static validation and hardening via ShellCheck and PSScriptAnalyzer. |
| terraform-expert | spacelift + spacectl | Infrastructure as code with Terraform, orchestration of deploy workflows with Spacelift, and programmatic interaction via the spacectl CLI. |

---

## Cloud & Infra

| Skill | Absorbe | Description |
|---|---|---|
| aws-cloud-expert | serverless-lambda-expert + cdn-edge-cloudfront | Design of cloud-native architectures on AWS, serverless computing with Lambda@Edge, latency optimization via CloudFront and infrastructure management with CloudFormation/CDK. |
| kubernetes-expert | k8s-troubleshooting | Orchestration of workloads with Kubernetes, including native resource definition (Deployments, StatefulSets, CRDs), networking (CNI, Ingress, Service Mesh) and systematic incident resolution. |
| docker-expert | — | Application containerization, multi-stage image optimization, runtime configuration (cgroups, namespaces), and registry management with vulnerability scanning. |
| helm-expert | — | Kubernetes application packaging with Helm Charts, release management, dynamic values, lifecycle hooks and dependencies between charts. |
| argocd-expert | gitops-argocd-flux | GitOps implementation with ArgoCD (and FluxCD): declarative synchronization, automated sync policies, secret management with Sealed Secrets/External Secrets, and controlled rollback. |
| finops-cost-optimization | — | Cloud cost analysis and optimization: resource right-sizing, Savings Plans/Reserved Instances purchase, mandatory tagging, budgets and cost reporting by workload. |
| aws-bedrock-agentcore-expert | — | Integration of AWS Bedrock foundation models, agent configuration with action groups, knowledge bases, and content guardrails for generative applications. |

---

## Data

| Skill | Description |
|---|---|
| postgres-database-expert | Relational schema design, execution plan optimization (EXPLAIN ANALYZE), strategic indexing (B-Tree, GIN, BRIN), partitioning, logical replication and engine parameter tuning. | support aws aurora postgres and rds postgres |
| snowflake-expert | Cloud-native data warehousing: dimensional modeling, micro-partition optimization, per-warehouse cost management, streams/tasks for CDC, and role-based access control (RBAC). |
| mongodb-expert | Document modeling, sharding strategies, replica set replication, aggregation operations, change streams and multi-document ACID transactions. | support aws documentdb |
| dynamodb-expert | Table design based on access patterns (single-table design), secondary index management (LSI/GSI), streams for event-driven, and capacity optimization (on-demand vs provisioned). |
| redis-cache-expert | Implementation of in-memory data structures (Strings, Hashes, Sorted Sets, Streams), persistence configuration (RDB/AOF), Redis Cluster clustering, and eviction policies. | support aws elasticache redis |
| elasticsearch-opensearch-expert | Mapping and analyzer design, complex queries (bool, nested, aggregations), cluster tuning (shards, replicas, segment merging), and JVM heap monitoring. |
| vector-databases | Storage and retrieval of high-dimensional embeddings, approximate indexing (ANN: HNSW, IVF), metadata filtering and integration with RAG pipelines. |
| time-series-db | Temporal data management: time series modeling, retention with downsampling, compression, high-frequency ingestion and range-based queries (InfluxDB, TimescaleDB, Prometheus). |
| mysql-expert | MySQL/MariaDB instance administration, master-slave/group replication, partitioning, InnoDB tuning (buffer pool, redo log), and online migrations with pt-online-schema-change. | support aws aurora mysql and rds mysql |
| liquibase-expert | Declarative versioning of database schemas, changeset orchestration (XML/YAML/SQL), checksum validation, and atomic rollback strategies. |
| database-migration-strategies | Zero-downtime migration planning: dual-write, strangler fig pattern, CDC (Change Data Capture), consistency validation and rollback procedures. | also consider using aws tools such as DMS, rds proxy ... |

---

## Protocols & Communication

| Skill | Absorbe | Description |
|---|---|---|
| authentication-expert | oauth-oidc-jwt-expert | Implementation of authentication and authorization flows: OAuth 2.0 (Authorization Code, Client Credentials), OpenID Connect, JWT (JWS/JWE signing), refresh tokens and PKCE. |
| openapi-expert | rest-openapi-expert | Formal REST API specification with OpenAPI 3.x, stub generation, request/response validation, and interactive documentation (Swagger UI/Redoc). |
| architecture-expert | api-design + architecture-design | Software architecture design (modular monolith, decoupled microservices, event-driven, hexagonal/ports-adapters), API definition, technology selection and deployment strategies. |


---

## Tools

| Skill | Absorbe | Description |
|---|---|---|
| github-actions-expert | — | CI/CD pipeline construction with GitHub Actions: YAML workflow definition (.github/workflows/) with event triggers (push, pull_request, schedule, workflow_dispatch), build matrices (strategy.matrix) for multiple OS/architectures/versions, secret management with GitHub Secrets and OIDC for cloud providers (AWS, GCP, Azure), reusable workflows (workflow_call), composite actions, self-hosted vs GitHub-hosted runners, security hardening (pin actions to full-length commit SHA, principle of least privilege for GITHUB_TOKEN with minimal permissions, prevention of script injection attacks via intermediate environment variables, masking sensitive values with ::add-mask::), artifact signing, dependency caching (actions/cache), and flaky test monitoring. |
| github-expert | — | Advanced GitHub repository management: branch protection rules (require PR reviews, status checks, GPG signatures), CODEOWNERS for ownership assignment by path/pattern with precedence rules, rulesets for org-level scalable policies, semantic releases with GitHub Releases and changelog automation (semantic-release, release-please), issue/PR management with templates (.github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md) and automatic labels, security monitoring (Dependabot alerts/version updates, secret scanning, code scanning with CodeQL, dependency review), vulnerability advisory database, OpenSSF Scorecards, and dependency graph for full supply chain tracking. |
| git-expert | git-protocol + git-guardrails | Mastery of the Git protocol at plumbing and internals level: internal objects (blob, tree, commit, tag, packfiles), content-addressable filesystem with SHA-1, transfer protocols (smart HTTP, SSH, Git protocol), safe history rewriting (interactive rebase, filter-repo, filter-branch), reflog for recovery of lost commits, local hooks (pre-commit, commit-msg, pre-push) and server-side (update, pre-receive, post-receive) for policy enforcement (message convention, per-directory ACLs), guardrails against force-pushes (--force-with-lease, receive.denyNonFastForwards), secret leak detection and prevention (git-secrets, gitleaks, truffleHog), signed commits (GPG/SSH signing, verified commits), conventional commits for standardized messages, and branching strategies (Git Flow, GitHub Flow, trunk-based development). |

---

## Quality & Process

| Skill | Absorbe | Description |
|---|---|---|
| reviewer-expert | review | Execution of systematic code reviews aligned with IEEE 1028: latent defect detection (60-65% in formal inspections vs <50% in informal ones), domain knowledge transfer, test coverage validation, OWASP Top 10 compliance, and code evolvability analysis (75% of comments per Microsoft studies). Optimal speed: 200-400 LOC/hour. |
| refactoring-expert | refactoring | Disciplined application of the Fowler refactoring catalog (2nd ed.): function/class extraction, collection encapsulation, conditional decomposition, replacement of primitives with objects, and split-phase. Preservation of observable behavior through characterization tests and small-step refactoring with immediate feedback. |
| testing-expert | testing-strategy | Design of testing strategies based on the Cohn/Mike Bland pyramid: fast unit tests (TDD, first-class citizens), integration tests with Test Doubles (mocks, stubs, fakes), contract tests with Pact, E2E with Playwright/Cypress, property-based testing (QuickCheck/Hypothesis), and fuzz testing. Metrics: code coverage as a signal (not proof), flaky test detection, and a "no test, no fix" culture. |
| debugging-expert | systematic-debugging | Application of structured debugging methodologies from Google's SRE Book: state reproduction (reproduction case), distributed tracing instrumentation (OpenTelemetry), call-trace analysis, memory/CPU profiling, git bisect for binary localization of defective commits, and blameless post-mortem analysis. |
| performance-expert | performance-optimization | Systematic profiling with observability tools (pprof, async-profiler, py-spy): hot path identification, memory allocation and garbage collection analysis, N+1 query optimization, multi-level cache implementation (L1/L2/CDN), connection pooling, and OS kernel tuning for low-latency workloads. |
| accessibility-expert | accessibility-compliance | WCAG 2.2 levels A/AA/AAA compliance verification based on the 4 POUR principles (Perceivable, Operable, Understandable, Robust): semantic HTML5 usage, ARIA roles and landmarks, keyboard navigation (tab order, skip links), color contrast (WCAG 1.4.3), testing with axe-core, and validation with screen readers (NVDA, JAWS, VoiceOver) and keyboard only. |
| playwright-expert | playwright-automation | E2E testing automation with Playwright: resilient locators (role + name), network interception and API mocking, integrated accessibility testing (axe-core), parallel execution with sharding, trace and video generation for flaky failure debugging, visual testing with screenshots, and CI integration with custom reporters. |
| scalability-expert | scalability-patterns | Design of elastic, high-availability systems: data sharding (consistent hashing), distributed cache (CDN, Redis Cluster), message queues for decoupling (SQS, Kafka), metric-based auto-scaling (CPU, request queue), CQRS/Event Sourcing patterns, overload handling (circuit breakers, rate limiting), and elimination of single points of failure. |
| idempotency-expert | idempotency-patterns | Design of idempotent operations in distributed systems: idempotency key generation and validation, request deduplication with time windows, compensating transactions (Saga, TCC), precondition validation (conditional updates with ETags), retry handling with exponential backoff, and exactly-once semantics guarantee via deduplication consumers. |
| planning-expert | grill-with-docs | Development planning based on prior technical documentation: RFCs (Request for Comments) for architecture proposals, TRDs (Technical Requirement Documents) for solution specification, ADRs (Architecture Decision Records) for recording technical decisions, and grill sessions for cross-validation of design before any line of code. |
| research-expert | repo-pack | Exploratory repository analysis: dependency map generation (AST parsing, dependency graphs), architecture and bounded context detection, quantitative technical debt identification (code churn, cyclomatic complexity, cognitive complexity), design pattern and anti-pattern recognition, and hotspot analysis via repository mining (Git log analysis). |
| documentation-expert | issue-to-trd | Transformation of requirements and issues into technical design documents (TRD): API specifications with OpenAPI, operations manuals (runbooks), documentation as code (Docs as Code), executable documentation via tests, and maintenance of structured wikis with updated architecture diagrams. |
| diagram-expert | diagram-generation | Creation of architecture diagrams with C4 Model (Context, Containers, Components, Code) for different abstraction levels, UML diagrams (sequence, classes, activity), data flows (DFD), entity-relationship models (ERD), sequence diagrams for API design, and deployment architectures (infrastructure). Tools: PlantUML, Mermaid, Structurizr. |
| operational-excellence | — | Implementation of Google SRE Book practices: definition of SLIs (Service Level Indicators), SLOs (Service Level Objectives) and SLAs, operational runbook creation, blameless post-mortem culture, toil elimination via automation, distributed systems monitoring (latency, traffic, errors, saturation), and continuous reliability improvement via error budgets. |
| evaluation-expert | advanced-evaluation | Comparative evaluation of technical solutions through structured trade-off analysis (performance vs cost, consistency vs availability CAP theorem, operational complexity), design and execution of POCs (Proof of Concepts) with objective metrics, weighted decision matrices, and technical risk analysis for technology selection. |
| reasoning-expert | reasoning + reasoning-trace | Agent reasoning improvement via Chain-of-Thought (CoT), Tree-of-Thought (ToT) for multi-path exploration, ReAct (Reasoning + Acting), and full inference line traceability (reasoning traces) maintenance for agent decision auditing and debugging. |
| skill-router | — | Dynamic task routing toward the most appropriate specialized skill via intent classification, problem domain matching against skill profiles, current execution context, and fallback to general-purpose skills when there is no match with sufficient confidence. |

---

## AI & Agents

| Skill | Absorbe | Description |
|---|---|---|
| prompt-expert | agent-prompt-engineering + prompt-engineering | Prompt engineering: system prompt design, few-shot prompting, prompt chaining, robustness evaluation against jailbreaks/injections, and input token optimization. |
| mcp-expert | mcp-server-design | Design and implementation of MCP (Model Context Protocol) servers: tool schema definition, transport handling (stdio/SSE), and capability exposure to client agents. |
| agent-expert | multi-agent-patterns + agent-analysis-expert + subagent-analysis-expert | Multi-agent system orchestration: delegation patterns (supervisor, plan-and-execute), individual agent analysis and subagent design with restricted scopes. |
| agent-architecture-expert | rag-architecture | RAG architecture design: ingestion pipelines, semantic chunking, embedding models, vector stores, retrieval strategies (hybrid search, reranking) and response grounding. |
| llm-expert | llm-operations-expert + llm-observability + llm-cost-estimation | LLM operationalization in production: model deployment, version management, prompt/completion logging, distributed tracing, latency monitoring and inference cost estimation. |

---

## Security & Compliance

| Skill | Absorbe | Description |
|---|---|---|
| security-expert | security-audit + threat-hunting | Security audit in source code (SAST) and infrastructure (DAST/IaC scanning), and proactive threat hunting execution via log analysis and behavioral analytics. |


---

---

## Delete

The following skills are proposed for deletion:

> **Note:** Some entries below (`fraud-detection-patterns`, `order-gateway-testing`, `kyc-aml-compliance`) are fintech-domain-specific and have been removed from the active catalog. They remain in this historical list for record-keeping only.

- terragrunt-expert
- vault-api-expert
- api-gateway-expert
- amqp-rabbitmq-expert
- message-queue-patterns
- websockets-realtime
- feature-flag-management
- webhook-design-security
- fraud-detection-patterns
- order-gateway-testing
- verification-before-completion
- improve-codebase-architecture
- linting
- kyc-aml-compliance
- data-privacy-gdpr-lgpd
- design-system-tokens
- notification-systems
- i18n-l10n-expert
