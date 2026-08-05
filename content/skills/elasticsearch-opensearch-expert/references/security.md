# ES/OpenSearch Security

## Access Control
```json
PUT _plugins/_security/api/roles/shipments_read {
  "cluster_permissions": ["cluster_monitor"],
  "index_permissions": [{
    "index_patterns": ["shipments-*"],
    "allowed_actions": ["read", "search"]
  }]
}
```

## Encryption
- TLS: encrypt data in transit (required for production)
- Encryption at rest: KMS for node-to-node + client-to-node
- Field-level encryption: sensitive fields (national ID, tax ID) encrypted before indexing

## Authentication
| Method | Use |
|---|---|
| Internal user DB | Dev/test |
| SAML / OIDC | Enterprise SSO |
| IAM (AWS OpenSearch) | AWS-native |
| mTLS | Service-to-service |

## Audit Logging
```json
PUT _plugins/_security/api/audit/config {
  "enabled": true,
  "audit": {
    "enable_rest": true,
    "enable_transport": true,
    "resolve_bulk_requests": true,
    "log_request_body": false  // NEVER true for PII data
  }
}
```

## Backup / Recovery
```bash
# Snapshot to S3
PUT _snapshot/example-backups {
  "type": "s3",
  "settings": { "bucket": "example.es-backups", "region": "us-east-1" }
}
PUT _snapshot/example-backups/snapshot_2026_05_16
GET _snapshot/example-backups/_all  # verify
```
