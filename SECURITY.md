# Security Policy

## Scope

This repository contains AI agent configuration files (rule packs, skills, hooks). Security concerns include:

- Hooks that could be exploited to execute arbitrary code
- Rule packs that inadvertently disable safety guardrails
- Skills that leak secrets or bypass PII protections

## Reporting

Report security issues via GitHub Security Advisories (preferred) or email the the platform security team.

**Do not** open public issues for security vulnerabilities.

## Supported Versions

The latest tagged release on `main` is supported. Older versions receive no security backports.
