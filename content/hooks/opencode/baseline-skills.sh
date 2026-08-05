#!/usr/bin/env bash
# OpenCode has no native shell-hook system for context injection.
# Skills are invoked via the skill() tool, which is model-driven.
# The primary enforcement mechanism for OpenCode is the microkernel
# (AGENTS.md) containing the explicit step-0 skill-loading instruction.
# This script serves as a placeholder if OpenCode later adds shell hooks.
set -euo pipefail

cat <<'MSG'
[WARN] SESSION START — MANDATORY BASELINE SKILLS

Before responding to ANY user message, invoke these 4 skills RIGHT NOW:

  skill({name:"operating-protocol"})   → risk tiers, done criteria, anti-hallucination
  skill({name:"tool-usage"})           → tool selection, parallel vs sequential
  skill({name:"token-efficiency"})     → verbosity limits, ≤25w/≤50w, thinking budget
  skill({name:"skill-router"})         → full domain skill catalog

These are not optional. Mentioning in prose is NOT invocation — call the skill tool.
After invoking, proceed normally. Do NOT ask for user confirmation to load skills.
MSG

exit 0
