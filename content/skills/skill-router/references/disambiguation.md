# Disambiguation Reference

Deployed only when SKILL.md decision tree cannot resolve between ≥2 candidate skills.

| Pair | Trigger keywords | Route to | Anti-route |
|---|---|---|---|
| `kubernetes-expert` vs `helm-expert` | deployment, pod, service, ingress | `kubernetes-expert` | `helm-expert` |
| `kubernetes-expert` vs `helm-expert` | chart, values, template, release | `helm-expert` | `kubernetes-expert` |
| `postgres-database-expert` vs similar | schema, query, index, explain | `postgres-database-expert` | – |
| `postgres-database-expert` vs similar | migration, expand-contract, backfill | `postgres-database-expert` | – |
| `security-expert` for compliance | CVE, OWASP, SAST, threat, PCI DSS | `security-expert` | – |
| `terraform-expert` vs `aws-cloud-expert` | .tf, module, state, plan | `terraform-expert` | `aws-cloud-expert` |
| `terraform-expert` vs `aws-cloud-expert` | EC2, Lambda, RDS, S3 cfg | `aws-cloud-expert` | `terraform-expert` |
| `evaluation-expert` vs `reasoning-expert` | benchmark, trade-off, metric | `evaluation-expert` | `reasoning-expert` |
| `evaluation-expert` vs `reasoning-expert` | fallacy, CoT, logic, audit | `reasoning-expert` | `evaluation-expert` |
| `prompt-expert` vs `llm-expert` | injection, temperature, few-shot | `prompt-expert` | `llm-expert` |
| `prompt-expert` vs `llm-expert` | cost, caching, drift, observability | `llm-expert` | `prompt-expert` |
| `python-expert` vs `typescript-expert` | FastAPI, pandas, LangGraph | `python-expert` | `typescript-expert` |
| `python-expert` vs `typescript-expert` | Next.js, React, Zustand, Express | `typescript-expert` | `python-expert` |
| `golang-expert` vs `java-expert` | Gin, gRPC, pgx, Zap | `golang-expert` | `java-expert` |
| `golang-expert` vs `java-expert` | Spring Boot, JPA, KillBill | `java-expert` | `golang-expert` |
| `swift-expert` vs `kotlin-expert` | iOS, SwiftUI, CocoaPods, SPM | `swift-expert` | `kotlin-expert` |
| `swift-expert` vs `kotlin-expert` | Android, Jetpack, Gradle, JitPack | `kotlin-expert` | `swift-expert` |
