# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `content/subagents/*.md` — rewrote all 16 subagent descriptions to single-line, plain-scalar-safe text (no `: `, no leading `#`/`- `, no `Use when/before/after` prefix) for OpenCode and Claude Code sync compatibility.
- `scripts/validate.sh` — added `validate_subagent_descriptions` gate (manifest-driven, quote-tolerant, full folded-value scan) wired into `main()`.
- `tests/test_validate.bats` — added 6 subagent-description validator tests.
- `docs/reference/subagent-schema.md` — documented third-person description convention and ADR-0002 boundary note.

## [0.0.1] - 2026-07-27

### Added

### Changed

### Fixed
