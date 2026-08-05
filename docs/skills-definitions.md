# Skills Propuestas — justas y necesarias

---

## 🔒 Core — siempre cargadas, inmutables

[Definicion de skills Core](skills-definitions.md)

---

## 🖥️ Lenguajes — 1 skill = ecosistema completo

> Incluir en estas skills: linting + best practices + Security + testing + debugging + instrumentacion con opentelemtry
> Incluido en la skill de terraform, la herramienta spacelift y su cli llamado spacectl

| Skill | Absorbe | Descripción |
|---|---|---|
| golang-expert | go-microservice-expert + protobuf-grpc-expert + linting(Go) + OTEL(Go) | Ecosistema completo de desarrollo Go: microservicios concurrentes, comunicación via gRPC/Protobuf, instrumentación con OpenTelemetry y análisis estático con linters especializados. |
| python-expert | python-fastapi-expert + langgraph-langchain-expert + linting(Python) | Stack Python para backend asíncrono con FastAPI, orquestación de flujos de agentes con LangGraph/LangChain, y enforcement de calidad mediante linters y type checkers. |
| typescript-expert | react-nextjs-expert + nodejs-backend-expert + state-management-redux-zustand + frontend-testing-jest-vitest + linting(TS) | Stack full-typeScript: SSR/CSR con Next.js, APIs backend con Node.js, gestión de estado con Redux/Zustand, testing unitario e integración con Jest/Vitest y análisis estático con ESLint/TSConfig estricto. |
| java-expert | java-spring-expert + linting(Java) + enterprise patterns | Desarrollo enterprise con Spring Boot, aplicación de patrones arquitectónicos de la Spring Boot (REST APIs, enterprise workflows), y validación estática de calidad de código. |
| scala-expert | Spark DataFrame/Dataset, sbt, ScalaTest, PySpark | Computación distribuida con Apache Spark (API DataFrame/Dataset), gestión de build con sbt, testing funcional con ScalaTest y interoperabilidad con PySpark. |
| swift-expert | mobile-sdk-expert(iOS) + mobile-cicd-fastlane(iOS) | Desarrollo nativo iOS con Swift, construcción y distribución de SDKs móviles, y automatización de pipelines CI/CD mediante Fastlane y Xcode CLI. |
| kotlin-expert | mobile-sdk-expert(Android) + mobile-cicd-fastlane(Android) | Desarrollo nativo Android con Kotlin, empaquetado de SDKs, y pipelines de integración continua con Fastlane y Android Build Tools. |
| ruby-expert | Rails + Rails + RSpec | Desarrollo web con Ruby on Rails, personalización de aplicaciones web con el framework Rails, y testing BDD/TDD con RSpec y Capybara. |
| scripting-expert | Bash/Zsh + PowerShell + ShellCheck | Automatización de infraestructura y sistemas operativos mediante scripts shell y PowerShell, con validación estática y hardening via ShellCheck y PSScriptAnalyzer. |
| terraform-expert | spacelift + spacectl | Infraestructura como código con Terraform, orquestación de workflows de deploy con Spacelift, e interacción programática via CLI spacectl. |

---

## ☁️ Cloud & Infra

| Skill | Absorbe | Descripción |
|---|---|---|
| aws-cloud-expert | serverless-lambda-expert + cdn-edge-cloudfront | Diseño de arquitecturas nativas cloud en AWS, computación serverless con Lambda@Edge, optimización de latencia mediante CloudFront y gestión de infraestructura con CloudFormation/CDK. |
| kubernetes-expert | k8s-troubleshooting | Orquestación de cargas de trabajo con Kubernetes, incluyendo definición de recursos nativos (Deployments, StatefulSets, CRDs), networking (CNI, Ingress, Service Mesh) y resolución sistemática de incidentes. |
| docker-expert | — | Containerización de aplicaciones, optimización de imágenes multi-stage, configuración de runtime (cgroups, namespaces), y gestión de registries con scanning de vulnerabilidades. |
| helm-expert | — | Empaquetado de aplicaciones Kubernetes con Helm Charts, gestión de releases, values dinámicos, hooks de lifecycle y dependencias entre charts. |
| argocd-expert | gitops-argocd-flux | Implementación de GitOps con ArgoCD (y FluxCD): sincronización declarativa, políticas de sync automatizado, manejo de secrets con Sealed Secrets/External Secrets, y rollback controlado. |
| finops-cost-optimization | — | Análisis y optimización de gasto cloud: rightsizing de recursos, compra de Savings Plans/Reserved Instances, etiquetado obligatorio, budgets y reporte de costos por workload. |
| aws-bedrock-agentcore-expert | — | Integración de modelos foundation de AWS Bedrock, configuración de agentes con action groups, knowledge bases, y guardrails de contenido para aplicaciones generativas. |

---

## 🗄️ Datos

| Skill | Descripción |
|---|---|
| postgres-database-expert | Diseño de esquemas relacionales, optimización de planes de ejecución (EXPLAIN ANALYZE), indexing estratégico (B-Tree, GIN, BRIN), partitioning, replicación lógica y tuning de parámetros del motor. | soportar aurora postgres y rds postgres de aws |
| snowflake-expert | Data warehousing cloud-native: modelado dimensional, optimización de micro-partitions, gestión de costos por warehouse, streams/tasks para CDC, y control de acceso basado en roles (RBAC). |
| mongodb-expert | Modelado de documentos, estrategias de sharding, replicación con replica sets, operaciones de agregación, change streams y transacciones multi-documento ACID. | soportar documentdb de aws |
| dynamodb-expert | Diseño de tablas basado en patrones de acceso (single-table design), gestión de índices secundarios (LSI/GSI), streams para event-driven, y optimización de capacidad (on-demand vs provisioned). |
| redis-cache-expert | Implementación de estructuras de datos in-memory (Strings, Hashes, Sorted Sets, Streams), configuración de persistencia (RDB/AOF), clustering con Redis Cluster, y políticas de eviction. | soportar elasticache de redis en aws |
| elasticsearch-opensearch-expert | Diseño de mappings y analyzers, queries complejas (bool, nested, aggregations), tuning de clusters (shards, replicas, segment merging), y monitoreo de JVM heap. |
| vector-databases | Almacenamiento y recuperación de embeddings de alta dimensionalidad, indexado aproximado (ANN: HNSW, IVF), metadata filtering e integración con pipelines de RAG. |
| time-series-db | Gestión de datos temporales: modelado de series de tiempo, retención con downsampling, compresión, ingestión de alta frecuencia y consultas range-based (InfluxDB, TimescaleDB, Prometheus). |
| mysql-expert | Administración de instancias MySQL/MariaDB, replicación maestro-esclavo/grupo, partitioning, tuning de InnoDB (buffer pool, redo log), y migraciones online con pt-online-schema-change. | soportar aurora mysql y rds mysql de aws |
| liquibase-expert | Versionado declarativo de esquemas de base de datos, orquestación de changesets (XML/YAML/SQL), validación de checksums, y estrategias de rollback atomático. |
| database-migration-strategies | Planificación de migraciones con cero downtime: dual-write, strangler fig pattern, CDC (Change Data Capture), validación de consistencia y procedimientos de rollback. | considerar tambien utilizar herramientas de aws como DMS, proxy rds ... |

---

## 🔌 Protocolos & Comunicación

| Skill | Absorbe | Descripción |
|---|---|---|
| authentication-expert | oauth-oidc-jwt-expert | Implementación de flujos de autenticación y autorización: OAuth 2.0 (Authorization Code, Client Credentials), OpenID Connect, JWT (firma JWS/JWE), refresh tokens y PKCE. |
| openapi-expert | rest-openapi-expert | Especificación formal de APIs REST con OpenAPI 3.x, generación de stubs, validación de requests/responses, y documentación interactiva (Swagger UI/Redoc). |
| architecture-expert | api-design + architecture-design | Diseño de arquitecturas de software (monolítica modular, microservicios desacoplados, event-driven, hexagonal/ports-adapters), definición de APIs, selección de stack tecnológico y estrategias de despliegue. |


---

## ⚙️ Tools

| Skill | Absorbe | Descripción |
|---|---|---|
| github-actions-expert | — | Construcción de pipelines CI/CD con GitHub Actions: definición de workflows YAML (.github/workflows/) con triggers por eventos (push, pull_request, schedule, workflow_dispatch), matrices de build (strategy.matrix) para múltiples OS/arquitecturas/versiones, gestión de secrets con GitHub Secrets y OIDC para cloud providers (AWS, GCP, Azure), reusable workflows (workflow_call), composite actions, self-hosted runners vs. GitHub-hosted runners, security hardening (pin actions a full-length commit SHA, principle of least privilege para GITHUB_TOKEN con permissions mínimas, prevención de script injection attacks mediante variables de entorno intermedias, masking de valores sensibles con ::add-mask::), artifact signing, caché de dependencias (actions/cache), y monitoreo de flaky tests. |
| github-expert | — | Gestión avanzada de repositorios con GitHub: branch protection rules (requerir PR reviews, status checks, firmas GPG), CODEOWNERS para asignación de ownership por path/patrón con reglas de precedencia, rulesets para políticas escalables a nivel organización, releases semánticas con GitHub Releases y changelog automation (semantic-release, release-please), gestión de issues/PRs con templates (.github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md) y labels automáticos, monitoreo de seguridad (Dependabot alerts/version updates, secret scanning, code scanning con CodeQL, dependency review), vulnerability advisory database, OpenSSF Scorecards, y dependency graph para tracking completo del supply chain. |
| git-expert | git-protocol + git-guardrails | Dominio del protocolo Git a nivel de plumbing e internales: objetos internos (blob, tree, commit, tag, packfiles), content-addressable filesystem con SHA-1, transfer protocols (smart HTTP, SSH, Git protocol), reescritura de historia segura (rebase interactivo, filter-repo, filter-branch), reflog para recuperación de commits perdidos, hooks locales (pre-commit, commit-msg, pre-push) y server-side (update, pre-receive, post-receive) para enforcement de políticas (convención de mensajes, ACLs por directorio), guardrails contra force-pushes (--force-with-lease, receive.denyNonFastForwards), detección y prevención de leaks de secrets (git-secrets, gitleaks, truffleHog), signed commits (GPG/SSH signing, verified commits), conventional commits para mensajes estandarizados, y estrategias de branching (Git Flow, GitHub Flow, trunk-based development). |

---

## ✅ Calidad & Proceso

| Skill | Absorbe | Descripción |
|---|---|---|
| reviewer-expert | review | Ejecución de code reviews sistemáticos alineados con IEEE 1028: detección de defectos latentes (60-65% en inspecciones formales vs. <50% en informales), transferencia de conocimiento del dominio, validación de cobertura de tests, cumplimiento de OWASP Top 10, y análisis de evolvabilidad del código (75% de los comentarios según estudios de Microsoft). Velocidad óptima: 200-400 LOC/hora. |
| refactoring-expert | refactoring | Aplicación disciplinada del catálogo de refactorings de Fowler (2nd ed.): extracción de funciones/clases, encapsulación de colecciones, decomposición condicional, reemplazo de primitivos por objetos, y split-phase. Preservación de comportamiento observable mediante tests de caracterización y refactoring por pasos pequeños con retroalimentación inmediata. |
| testing-expert | testing-strategy | Diseño de estrategias de testing basadas en la pirámide de Cohn/Mike Bland: tests unitarios rápidos (TDD, first-class citizens), tests de integración con Test Doubles (mocks, stubs, fakes), tests de contrato con Pact, E2E con Playwright/Cypress, property-based testing (QuickCheck/Hypothesis), y fuzz testing. Métricas: cobertura de código como señal (no proof), detección de flaky tests, y cultura de "no test, no fix". |
| debugging-expert | systematic-debugging | Aplicación de metodologías de debugging estructurado del SRE Book de Google: reproducción de estado (reproduction case), instrumentación con tracing distribuido (OpenTelemetry), análisis de trazas de stack, profiling de memoria/CPU, uso de git bisect para localización binaria de commits defectuosos, y análisis de post-mortems sin blame. |
| performance-expert | performance-optimization | Profiling sistemático con herramientas de observabilidad (pprof, async-profiler, py-spy): identificación de hot paths, análisis de allocación de memoria y garbage collection, optimización de consultas N+1, implementación de cachés multi-nivel (L1/L2/CDN), connection pooling, y tuning de kernels de sistemas operativos para workloads de baja latencia. |
| accessibility-expert | accessibility-compliance | Verificación de cumplimiento WCAG 2.2 niveles A/AA/AAA basado en los 4 principios POUR (Perceivable, Operable, Understandable, Robust): uso semántico de HTML5, roles ARIA y landmarks, navegación por teclado (tab order, skip links), contraste de color (WCAG 1.4.3), testing con axe-core, y validación con lectores de pantalla (NVDA, JAWS, VoiceOver) y teclado únicamente. |
| playwright-expert | playwright-automation | Automatización de testing E2E con Playwright: locators resilientes (role + name), manejo de network interception y mocking de APIs, testing de accesibilidad integrado (axe-core), ejecución paralela con sharding, generación de traces y videos para debugging de fallos flaky, testing visual con screenshots, y CI integration con reporters personalizados. |
| scalability-expert | scalability-patterns | Diseño de sistemas elásticos y de alta disponibilidad: sharding de datos (consistent hashing), caché distribuida (CDN, Redis Cluster), colas de mensajes para desacoplamiento (SQS, Kafka), auto-scaling basado en métricas (CPU, request queue), patrones CQRS/Event Sourcing, manejo de overload (circuit breakers, rate limiting), y eliminación de single points of failure. |
| idempotency-expert | idempotency-patterns | Diseño de operaciones idempotentes en sistemas distribuidos: generación y validación de claves de idempotencia (idempotency keys), deduplicación de requests con ventanas temporales, transacciones compensatorias (Saga, TCC), validación de estado previo (conditional updates con ETags), manejo de retries con backoff exponencial, y garantía de exactly-once semantics mediante deduplication consumers. |
| planning-expert | grill-with-docs | Planificación de desarrollo basada en documentación técnica previa: elaboración de RFCs (Request for Comments) para propuestas de arquitectura, TRDs (Technical Requirement Documents) para especificación de soluciones, ADRs (Architecture Decision Records) para registro de decisiones técnicas, y grill sessions para validación cruzada de diseño antes de cualquier línea de código. |
| research-expert | repo-pack | Análisis exploratorio de repositorios: generación de mapas de dependencias (AST parsing, dependency graphs), detección de arquitecturas y bounded contexts, identificación cuantitativa de deuda técnica (code churn, cyclomatic complexity, cognitive complexity), reconocimiento de patrones de diseño y anti-patterns, y análisis de hotspots mediante mining de repositorios (Git log analysis). |
| documentation-expert | issue-to-trd | Transformación de requerimientos e issues en documentos técnicos de diseño (TRD): especificaciones de API con OpenAPI, manuales de operación (runbooks), documentación como código (Docs as Code), executable documentation mediante tests, y mantenimiento de wikis estructuradas con diagramas de arquitectura actualizados. |
| diagram-expert | diagram-generation | Creación de diagramas de arquitectura con C4 Model (Context, Containers, Components, Code) para diferentes niveles de abstracción, diagramas UML (secuencia, clases, actividad), flujos de datos (DFD), modelos entidad-relación (ERD), diagramas de secuencia para diseño de APIs, y arquitecturas de despliegue (infraestructura). Herramientas: PlantUML, Mermaid, Structurizr. |
| operational-excellence | — | Implementación de prácticas SRE del Google SRE Book: definición de SLIs (Service Level Indicators), SLOs (Service Level Objectives) y SLAs, elaboración de runbooks operacionales, cultura de post-mortems sin blame, eliminación de toil mediante automatización, monitoreo de distributed systems (latencia, tráfico, errores, saturación), y mejora continua de la confiabilidad mediante error budgets. |
| evaluation-expert | advanced-evaluation | Evaluación comparativa de soluciones técnicas mediante análisis estructurado de trade-offs (rendimiento vs. costo, consistencia vs. disponibilidad CAP theorem, complejidad operativa), diseño y ejecución de POCs (Proof of Concepts) con métricas objetivas, matrices de decisión ponderadas, y análisis de riesgos técnicos para selección de stack tecnológico. |
| reasoning-expert | reasoning + reasoning-trace | Mejora del razonamiento del agente mediante técnicas de Chain-of-Thought (CoT), Tree-of-Thought (ToT) para exploración de múltiples caminos, ReAct (Reasoning + Acting), y mantenimiento de trazabilidad completa de la línea de inferencia (reasoning traces) para auditoría y debugging de decisiones del agente. |
| skill-router | — | Enrutamiento dinámico de tareas hacia la skill especializada más adecuada mediante análisis de intención (intent classification), matching de dominio del problema contra perfiles de skills, contexto de ejecución actual, y fallback a skills de propósito general cuando no hay match con confianza suficiente. |

---

## 🧠 AI & Agentes

| Skill | Absorbe | Descripción |
|---|---|---|
| prompt-expert | agent-prompt-engineering + prompt-engineering | Ingeniería de prompts: diseño de system prompts, few-shot prompting, prompt chaining, evaluación de robustez ante jailbreaks/injections, y optimización de tokens de entrada. |
| mcp-expert | mcp-server-design | Diseño e implementación de servidores MCP (Model Context Protocol): definición de tool schemas, manejo de transporte (stdio/SSE), y exponibilidad de capacidades a agentes clientes. |
| agent-expert | multi-agent-patterns + agent-analysis-expert + subagent-analysis-expert | Orquestación de sistemas multi-agente: patrones de delegación (supervisor, plan-and-execute), análisis de agentes individuales y diseño de subagentes con scopes restringidos. |
| agent-architecture-expert | rag-architecture | Diseño de arquitecturas RAG: ingestion pipelines, chunking semántico, embedding models, vector stores, retrieval strategies (hybrid search, reranking) y grounding de respuestas. |
| llm-expert | llm-operations-expert + llm-observability + llm-cost-estimation | Operacionalización de LLMs en producción: deploy de modelos, gestión de versiones, logging de prompts/completions, tracing distribuido, monitoreo de latencia y estimación de costos de inferencia. |

---

## 🛡️ Seguridad & Compliance

| Skill | Absorbe | Descripción |
|---|---|---|
| security-expert | security-audit + threat-hunting | Auditoría de seguridad en código fuente (SAST) e infraestructura (DAST/IaC scanning), y ejecución de threat hunting proactivo mediante análisis de logs y behavioral analytics. |


---

---

## 🗑️ Eliminar

Las siguientes skills se proponen para eliminación:

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
