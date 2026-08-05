# Source Triangulation Framework

## Trust Hierarchy
1. Source code (highest authority — behavior as executed)
2. Tests (expected behavior, edge cases documented)
3. Configuration/deployment manifests (runtime reality)
4. Git history (evolution, refactoring patterns, ownership)
5. Documentation / README (intent, rationale — may be outdated)
6. Issues / PRs (discussions, known problems, decisions)
7. External docs (API specs, library docs — general, not platform-specific)

## Triangulation Rule
NEVER draw conclusions from single source.
Cross-validate at least 3 independent sources.
Code always wins over docs when they conflict.

## Example: "Does shipments service use circuit breakers?"
1. Check source: grep for "gobreaker" / "CircuitBreaker" in services/*.go
2. Check config: look for circuit_breaker settings in config files
3. Check deploy manifests: Helm values for resilience settings
4. Check monitoring: Grafana dashboards for circuit breaker state metrics
5. Check incident history: post-mortems mentioning circuit breakers

## Contradiction Resolution
| If source A says X, source B says Y... |
|---|
| Check date: which is more recent? |
| Check deployment: which is in production now? |
| Run a test: reproduce and observe actual behavior |
| Document the contradiction + resolution |
