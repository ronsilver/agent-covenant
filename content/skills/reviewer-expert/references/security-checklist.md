# PR Security Review Checklist

## Check Each Diff For
- [ ] Secrets: grep for tokens, keys, passwords, connection strings
- [ ] Input Validation: new endpoints -> inputs validated + sanitized?
- [ ] Auth/Authz: new routes -> authentication enforced? authorization checked?
- [ ] SQL Injection: parameterized queries (no string concat, no `eval`)
- [ ] Command Injection: no `exec()`, `os.system()`, `child_process.exec()` with user input
- [ ] Dependencies: new packages? check CVE status (npm audit, trivy)
- [ ] Cryptography: hardcoded salts, weak algos (MD5/SHA1), insecure random
- [ ] Data Exposure: PII in logs, error messages leaking internals
- [ ] CWE References: every security finding must include CWE-ID + concrete fix

## OWASP Top 10 Map
| # | Risk | CWE Example |
|---|------|-------------|
| A01 | Broken Access Control | CWE-862 |
| A02 | Cryptographic Failures | CWE-327 |
| A03 | Injection | CWE-89 (SQL), CWE-78 (OS) |
| A05 | Security Misconfiguration | CWE-16 |
| A07 | Identification Failures | CWE-287 |
