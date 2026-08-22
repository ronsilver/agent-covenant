#!/usr/bin/env bash
# SessionStart hook — injects mandatory reminder to load the 7 boot skills.
# These are auto-injected via @import in claude-code-global.md at the config level.
# Hook output goes into context as a system message (redundant enforcement).
# Non-blocking (exit 0 always) — @import is the primary mechanism.
set -euo pipefail

cat <<'MSG'
[CHECK] SESSION START — VERIFY THE 7 BOOT SKILLS

Do you see ALL 7 boot-skill bodies VERBATIM in context?
(Claude Code expands the @~/.claude/skills/*/SKILL.md imports in CLAUDE.md.)
Missing ANY of them → invoke them NOW:

  Skill(operating-protocol)     → risk tiers, anti-hallucination, evidence labels
  Skill(governance)             → compliance, binding, modification-protection
  Skill(engineering-standards)   → code limits, pre-commit chain, security
  Skill(context-management)      → JIT loading, staleness, sub-agent contracts
  Skill(token-efficiency)        → compression, model routing, thinking budget
  Skill(tool-usage)              → dedicated > Bash, parallel vs sequential
  Skill(skill-router)            → full domain skill catalog

All 7 present → proceed. These are not optional — they govern every action.
MSG

exit 0
