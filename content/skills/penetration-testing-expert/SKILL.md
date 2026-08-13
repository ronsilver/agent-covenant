---
name: penetration-testing-expert
description: "Offensive security and authorized penetration testing: scoped engagement methodology (reconnaissance, enumeration, vulnerability analysis, exploitation, post-exploitation, reporting), tool selection (nmap, ffuf, gobuster, sqlmap, nuclei, Burp Suite, Metasploit), OWASP WSTG coverage for web and API targets, and safe rules of engagement (written scope, no persistence, no production impact). Use when planning an authorized pentest, writing an engagement report, choosing recon or exploitation tooling, or building a lab for red-team practice. Trigger: penetration testing, pentest, offensive security, exploitation, nmap, burp suite, metasploit, red team, OWASP WSTG. Do NOT trigger for: defensive audits, SAST/DAST pipelines, CVE triage, threat hunting, or IAM review (use security-expert); application security feature work such as auth or TLS configuration (use general programming guidance)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: security
  status: beta
trigger: on-demand
---

# Penetration Testing Expert

**Authorized offensive security: scoped pentests, recon, exploitation, and clear reporting.**

## Overview

Penetration testing finds exploitable weaknesses through authorized, scoped attacks. This skill covers the full engagement lifecycle for web, API, network, and cloud targets: planning and rules of engagement, reconnaissance, enumeration, vulnerability analysis, exploitation, post-exploitation hygiene, and reporting. Every command runs inside an explicitly authorized scope; anything outside that scope is out of bounds.

**What this skill covers:**
- Engagement scoping and rules of engagement (written authorization, target inventory, time window)
- Recon and enumeration: nmap, subdomain discovery, HTTP probing, directory fuzzing
- Vulnerability analysis and exploitation: web (OWASP WSTG), API, network services
- Post-exploitation hygiene: proof of concept only, no lateral movement outside scope
- Report writing: findings, evidence, severity, remediation guidance

**What this skill does NOT cover:**
- Defensive security audits, SAST/DAST pipelines, CVE triage, threat hunting, IAM review (use `security-expert`)
- Security feature implementation such as auth, TLS, or CSRF protection (use general programming guidance)
- Long-running offensive operations beyond a test window (requires a dedicated red-team program)

**Limitation:** this skill assumes a written authorization for every target. Without one, stop and escalate.

## Quick Reference

| If you need to | Do this | See section |
|---|---|---|
| Start an engagement safely | Confirm written scope and rules of engagement first | Workflow |
| Enumerate a web target | Run passive recon, then directory and parameter fuzzing | Workflow |
| Exploit a discovered weakness | Build a proof of concept inside the authorized scope | Workflow |
| Report a finding | Record evidence, impact, and remediation for each issue | Workflow |
| Error: tool blocked by WAF | Switch to manual payload analysis and rate-limited requests | Troubleshooting |

## Workflow

### Primary Path: Scoped Engagement

```
1. Confirm scope: written authorization, target inventory, time window, exclusions.
2. Reconnaissance: passive OSINT, certificate transparency, subdomain discovery.
3. Enumeration: port scan, service fingerprint, HTTP probing, directory fuzzing.
4. Vulnerability analysis: map findings to OWASP WSTG checks.
5. Exploitation: build a minimal proof of concept for each confirmed issue.
6. Post-exploitation: collect evidence, then clean up artifacts.
7. Report: document each finding with reproduction steps and remediation.
```

**Before starting, confirm:**
- [ ] Written authorization covers every target in scope
- [ ] Time window and exclusions are explicit
- [ ] No production data will be modified or exfiltrated

**After completing, verify:**
- [ ] All test artifacts and credentials are removed
- [ ] Every finding has reproduction evidence
- [ ] No out-of-scope host was touched

### Alternative Path: Single Vulnerability Validation

```
1. Reproduce the reported issue on a staging or lab instance.
2. Isolate the minimum payload that triggers it.
3. Capture evidence and draft the remediation note.
```

## Guidelines

### DO

| Rule | Why |
|---|---|
| Keep every action inside the written scope | Scope violations are legal and ethical breaches |
| Document evidence as you go | Reports without reproduction steps are not actionable |
| Use least-privilege tooling accounts | Reduces blast radius and cleanup burden |

### DO NOT

| Anti-pattern | Correct approach | Why |
|---|---|---|
| Scanning hosts outside the approved target list | Stick to the target inventory | Out-of-scope scanning breaks authorization |
| Running destructive payloads on production | Use staging or lab instances | Production impact violates rules of engagement |
| Storing captured credentials in plain text | Keep evidence in a password-protected vault | Leaked credentials become a new incident |

## Anti-patterns

### WRONG: Scanning without confirming scope
```bash
nmap -p- 10.0.0.0/8
```
### CORRECT: Confirming scope first
```bash
cat scope.txt   # target list from written authorization
nmap -sV -p- --exclude-file out-of-scope.txt 10.0.0.5
```
**Why:** Scanning unlisted ranges invalidates the authorization for the entire engagement.

### WRONG: Running SQLMap against production
```bash
sqlmap -u https://prod.example.com/item?id=1 --batch --dump
```
### CORRECT: Testing against a staging clone
```bash
sqlmap -u https://staging.example.com/item?id=1 --batch --technique=BEU
```
**Why:** Dumping production data is destructive and outside any reasonable rules of engagement.

### WRONG: Skipping the report
```bash
# exploitation done, no notes, no evidence archive
```
### CORRECT: Recording evidence per finding
```bash
mkdir -p findings/CVE-2024-0001 && cp poc.py evidence.png findings/CVE-2024-0001/
```
**Why:** A finding without reproduction steps cannot be triaged or fixed.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| WAF blocks automated scans | Signature detection on default payloads | Slow the request rate, use manual analysis, rotate payloads |
| False positive in a scanner | Tool heuristics overstate risk | Confirm manually with a minimal proof of concept |
| Tool fails on modern endpoints | API-first apps need different techniques | Switch from HTML crawling to API enumeration (OpenAPI, GraphQL) |
| Known edge case: TLS interception breaks tooling | Corporate proxy injects its CA | Use the approved CA bundle or a dedicated lab network |

**Known issue:** default nmap service scans skip UDP. For authorized UDP scope, add `-sU`.

## Verification Checklist

Before claiming "done", confirm ALL:

- [ ] Every action stayed inside the written scope and time window
- [ ] Each finding has reproduction evidence and a severity rating
- [ ] All artifacts, payloads, and temporary credentials were removed
- [ ] The final report lists remediation guidance per finding

## LLM Red-Team (generative security)

Applies red-team methods to LLM and agent systems (master catalog #42 garak, #39 PyRIT):

- Prompt injection: test direct and indirect injection; verify the instruction-hierarchy defense holds.
- RAG poisoning: poison a controlled knowledge base and measure retrieval exploitation.
- MCP abuse: attempt tool-call forgery, tool poisoning, and excess-agency escalations.
- Tooling: `garak` for automated LLM vulnerability scanning; Microsoft PyRIT for agentic red-team workflows.

Every LLM red-team run stays inside the same written scope and reporting rules as the engagement.

## Tier 1 Advisory vs Tier 2 Execution

| Tier | Posture | Deliverable |
|---|---|---|
| Tier 1 Advisory | Analyze, advise, document risks without launching attacks | Findings and recommendations |
| Tier 2 Execution | Run authorized attacks inside written scope | Proofs of concept and validated findings |

Hard-refusal scope guard (master catalog #39): refuse, and escalate to the operator, any request to execute on:
- Denial-of-service or resource-exhaustion testing outside an explicitly sized test window
- Mass scanning of third-party or unowned address space
- Unattended or self-propagating payloads (worms)
- False-flag or framing operations
- Any activity affecting safety-of-life systems

When a request is ambiguous, run the 7-Question Gate below before acting.

## Six-Phase Engagement Workflow

```
1. Scope: written authorization, target inventory, exclusions (gate before anything else)
2. Recon: passive OSINT, certificate transparency, subdomain discovery
3. Map and rank: fingerprint services and endpoints; rank targets by exposure
4. Hunt: validate candidate weaknesses with minimal proofs of concept
5. Validate: confirm each finding with independent reproduction and impact rating
6. Report: evidence, severity, remediation, and residual risk
```

7-Question Gate (before every attack step, master catalog #40): who authorized the target? is the target in the written inventory? is the action within the time window? does the action avoid excluded hosts? is the impact reversible? is evidence capture in place? is a rollback defined? A NO to any question stops the step and escalates.

Evidence hygiene: capture artifacts (timestamps, tool output, screenshots, hashes) as the run progresses; never store captured credentials in plain text; purge test data at closeout.

## Framework Mapping

| Framework | Use |
|---|---|
| MITRE ATT&CK v19.1 | Map discovered techniques to adversary tactics |
| NIST CSF 2.0 | Map findings to govern, identify, protect, detect, respond, recover |
| MITRE ATLAS | Map AI/ML attack techniques and LLM-specific vectors |
| D3FEND v1.4.0 | Pair each ATT&CK technique with a defensive countermeasure |
| NIST AI RMF | Frame, map, measure, and manage AI risk for LLM targets |
| F3 (Fable-driven development) | Drive finding-validation via refutation and claim checks |

## References

| Resource | URL | Last verified |
|---|---|---|
| OWASP Web Security Testing Guide (WSTG) | https://owasp.org/www-project-web-security-testing-guide/ | 2026-08-09 |
| MITRE ATT&CK | https://attack.mitre.org/ | 2026-08-09 |
| PortSwigger Web Security Academy | https://portswigger.net/web-security | 2026-08-09 |
| Master catalog items: #39-44, #145, #117 | see docs/reference/master-catalog-mapping.md | - |
