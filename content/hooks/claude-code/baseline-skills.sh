#!/usr/bin/env bash
# SessionStart hook — injects mandatory reminder to load the 7 boot skills.
# These are auto-injected via @import in claude-code-global.md at the config level.
# Hook output goes into context as a system message (redundant enforcement).
# Non-blocking (exit 0 always) — @import is the primary mechanism.
set -euo pipefail

cat <<'MSG'
[WARN] SESSION START — MANDATORY BOOT SKILLS

Boot skills are auto-loaded via @~/.claude/skills/*/SKILL.md in CLAUDE.md.
If you do NOT see their content in context, invoke them NOW:

  Skill(operating-protocol)     → risk tiers, anti-hallucination, evidence labels
  Skill(governance)             → compliance, binding, modification-protection
  Skill(engineering-standards)   → code limits, pre-commit chain, security
  Skill(context-management)      → JIT loading, staleness, sub-agent contracts
  Skill(token-efficiency)        → compression, model routing, thinking budget
  Skill(tool-usage)              → dedicated > Bash, parallel vs sequential
  Skill(skill-router)            → full domain skill catalog

These are not optional — they govern every action. Proceed only after ALL 7 are loaded.
MSG

exit 0
