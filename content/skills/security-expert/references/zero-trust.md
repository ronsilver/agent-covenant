# Zero Trust Architecture

## Principles
1. Never trust, always verify: verify every request regardless of source
2. Least privilege: minimum access needed, just-in-time elevation
3. Assume breach: design as if perimeter already compromised
4. Explicit verification: authenticate + authorize every access

## Implementation Layers
### Network
- Micro-segmentation: per-service network policies
- mTLS: mutual TLS for service-to-service
- No implicit trust based on network location (internal IP != trusted)

### Identity
- MFA mandatory for all access (human + service)
- Short-lived credentials (STS tokens, 1h max)
- Continuous session validation (not one-time auth check)

### Data
- Encryption at rest (KMS, envelope encryption)
- Encryption in transit (TLS 1.3 minimum)
- Data classification: tag data sensitivity, apply controls accordingly

### Workload
- Immutable infrastructure (no patching, replace)
- Signed container images + verification on pull
- Runtime security: eBPF, Falco for anomaly detection

## Applying Zero Trust
- Micro-segmentation: per-service network policies with deny-by-default
- Secrets management: centralized vault with auto-rotation
- IAM roles: per-service, per-environment, time-bound
- Audit logging: all API calls logged, immutable, alert on anomalies
