# ADR-0028: SBOM Scanner Tooling Adoption — cve-lite-cli and Dependency-Track

**Date:** 2026-08-08
**Status:** Proposed

## Context

The security-expert references (sast-tools.md, container-security.md) document
the scanner pipeline for the agent-covenant ecosystem. The 2025 OWASP Top 10
reclassification moved supply chain failures to A03, and the audit sweep
(ultraresearch + ultrathinking) found no lightweight SBOM-to-CVE tooling and no
continuous SBOM monitoring documented. Two gaps exist: (1) a lightweight CVE
lookup CLI (cve-lite-cli) for local SBOM files, and (2) a continuous monitoring
service (Dependency-Track) for published SBOMs.

## Decision

Adopt cve-lite-cli as the documented local SBOM CVE lookup tool and
Dependency-Track as the continuous SBOM monitoring target. Document both in
security-expert references:

1. sast-tools.md: add a Supply Chain and SBOM Tooling table with cve-lite-cli,
   syft, cosign, and OWASP Dependency-Check (task T5).
2. container-security.md: add an SBOM analysis step to the scanning pipeline
   and a release policy that pushes every SBOM to Dependency-Track (task T6).

This ADR is the governance record for the tooling names introduced by tasks T5
and T6. If this ADR is rejected at human review, tasks T5 and T6 MUST be reverted
before merge.

## Alternatives Considered

1. OWASP Dependency-Check as the only SBOM scanner: rejected for the local
   lookup path because a full dependency-check run is heavy for a single SBOM
   file; kept as the deep audit tool.
2. Trivy-only SBOM consumption: rejected because the reference pipeline needs a
   dedicated SBOM-to-CVE step that separates generation from analysis.
3. Full Dependency-Track deployment in this repo: rejected as out of scope;
   only the ingestion contract is documented.

## Consequences

- security-expert references now name concrete scanner tooling; drift between
  documentation and CI tooling is reduced.
- The literal tool names cve-lite-cli and Dependency-Track appear exactly once
  in their reference files, which the validation sequence enforces.
- If the tools are not adopted operationally, the documentation must be
  revised through a follow-up ADR; until then the entries remain a proposal.

## Follow-up (out of scope, requires separate ADR)

Three Core-skill residuals were identified during the 2025 OWASP audit. They are
NOT edited by this change (Core files are immutable without
ADR -> human approval -> manifest -> CHANGELOG) and are tracked here as
follow-ups:

1. engineering-standards/SKILL.md line 207: `- OWASP Top 10:
   https://owasp.org/www-project-top-ten/ (last_verified: 2026-05)` — update to
   the 2025 URL and re-verify the date.
2. docs/SKILL_QUALITY_STANDARD.md line 180: reference row
   `| Official OWASP Top 10 | https://owasp.org/www-project-top-ten/ | 2026-05-25 |`
   — update to the 2025 URL and re-verify the date.
3. operating-protocol/references/untrusted-content.md line 42 and
   references/risk-framework.md line 71 label AML.T0053 as "LLM Plugin
   Compromise (tool/MCP poisoning)" — must be relabeled: AML.T0053 is AI Agent
   Tool Invocation; tool poisoning maps to AML.T0110.

Each requires: ADR proposal -> human approval -> manifest update -> CHANGELOG
entry.

## Evidence

- OWASP Top 10 2025 taxonomy (A03 Software Supply Chain Failures):
  https://owasp.org/Top10/ (accessed 2026-08-08).
- MITRE ATLAS: AML.T0110 AI Agent Tool Poisoning (Definition and Instructions,
  Implementation, Runtime Response); AML.T0053 AI Agent Tool Invocation.
- Repo scan (2026-08-08): cve-lite-cli and Dependency-Track had 0 occurrences
  before this change; AML.T0110 had 0 occurrences.
- CycloneDX (ECMA-424) is the SBOM interchange standard Dependency-Track
  consumes and produces (https://cyclonedx.org, accessed 2026-08-08).
- ASVS 5.0.0 (https://owasp.org/www-project-application-security-verification-standard/)
  and WSTG v4.2 (https://owasp.org/www-project-web-security-testing-guide/v42/)
  are the flagship OWASP verification and testing standards referenced by
  security-expert (accessed 2026-08-08).
