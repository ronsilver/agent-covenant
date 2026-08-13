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

## Ten-Class Vulnerability Table

| # | Class | Examples | CWE anchors |
|---|-------|----------|-------------|
| 1 | Injection | SQL, command, LDAP, XPath, NoSQL, XXE | CWE-89, 78, 90, 643, 611 |
| 2 | Auth and authz | Privilege escalation, IDOR, session flaws | CWE-269, 639, 384 |
| 3 | Data exposure | Secrets, PII in logs or responses | CWE-532, 359 |
| 4 | Cryptography | Weak algorithms, hardcoded keys, insecure random | CWE-327, 798, 330 |
| 5 | Input validation | Unvalidated lengths, types, encodings | CWE-20 |
| 6 | Business logic | Race conditions, TOCTOU | CWE-362, 367 |
| 7 | Configuration | Insecure defaults, permissive CORS | CWE-16, 942 |
| 8 | Supply chain | Malicious deps, unsigned artifacts | CWE-1104, 1357 |
| 9 | RCE | Deserialization, pickle, eval | CWE-502, 94 |
| 10 | XSS | Reflected, stored, DOM | CWE-79 |

## False-Positive List

The following are NOT findings on their own (master catalog #98):
- Missing rate limiting or DoS hardening on a low-traffic internal endpoint
- Absence of an IP rate limiter without a stated abuse model
- Open redirect that cannot be chained to a sensitive action
