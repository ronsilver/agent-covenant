#!/usr/bin/env bash
# bootstrap-symlinks.sh — Create symlinks from legacy per-agent dirs to shared dir
# Run once after first sync to migrate existing agents to centralized structure.
set -euo pipefail

SHARED="${HOME}/.config/agent-covenant"

echo "==> Bootstrapping shared agent-covenant at ${SHARED}"

# Ensure shared dirs exist
mkdir -p "${SHARED}/skills"
mkdir -p "${SHARED}/subagents"
mkdir -p "${SHARED}/subagents-opencode"
mkdir -p "${SHARED}/hooks"

# Link agent skills dirs to shared
for agent_dir in \
	"${HOME}/.claude/skills" \
	"${HOME}/.claude-silver/skills" \
	"${HOME}/.claude-example/skills" \
	"${HOME}/.copilot/skills" \
	"${HOME}/.config/opencode/skills" \
	"${HOME}/.gemini/antigravity/skills" \
	"${HOME}/.github-copilot/skills"; do
	if [ -d "${agent_dir}" ] && [ ! -L "${agent_dir}" ]; then
		echo "  Backing up ${agent_dir} -> ${agent_dir}.bak.$(date +%Y%m%d)"
		mv "${agent_dir}" "${agent_dir}.bak.$(date +%Y%m%d)" 2>/dev/null || true
	fi
	if [ ! -e "${agent_dir}" ]; then
		echo "  Linking ${agent_dir} -> ${SHARED}/skills"
		mkdir -p "$(dirname "${agent_dir}")" && ln -sf "${SHARED}/skills" "${agent_dir}"
	fi
done

# Link Claude Code subagents
for agent_dir in \
	"${HOME}/.claude/agents" \
	"${HOME}/.claude-silver/agents" \
	"${HOME}/.claude-example/agents"; do
	if [ -d "${agent_dir}" ] && [ ! -L "${agent_dir}" ]; then
		mv "${agent_dir}" "${agent_dir}.bak.$(date +%Y%m%d)" 2>/dev/null || true
	fi
	if [ ! -e "${agent_dir}" ]; then
		echo "  Linking ${agent_dir} -> ${SHARED}/subagents"
		mkdir -p "$(dirname "${agent_dir}")" && ln -sf "${SHARED}/subagents" "${agent_dir}"
	fi
done

# Link OpenCode subagents (separate dir — opencode uses subagents-opencode/)
if [ -d "${HOME}/.config/opencode/agents" ] && [ ! -L "${HOME}/.config/opencode/agents" ]; then
	mv "${HOME}/.config/opencode/agents" "${HOME}/.config/opencode/agents.bak.$(date +%Y%m%d)" 2>/dev/null || true
fi
if [ ! -e "${HOME}/.config/opencode/agents" ]; then
	echo "  Linking ${HOME}/.config/opencode/agents -> ${SHARED}/subagents-opencode"
	mkdir -p "$(dirname "${HOME}/.config/opencode/agents")" && ln -sf "${SHARED}/subagents-opencode" "${HOME}/.config/opencode/agents"
fi

# Link Claude Code hooks
for hooks_dir in \
	"${HOME}/.claude/hooks" \
	"${HOME}/.claude-silver/hooks" \
	"${HOME}/.claude-example/hooks"; do
	if [ -d "${hooks_dir}" ] && [ ! -L "${hooks_dir}" ]; then
		mv "${hooks_dir}" "${hooks_dir}.bak.$(date +%Y%m%d)" 2>/dev/null || true
	fi
	if [ ! -e "${hooks_dir}" ]; then
		echo "  Linking ${hooks_dir} -> ${SHARED}/hooks"
		mkdir -p "$(dirname "${hooks_dir}")" && ln -sf "${SHARED}/hooks" "${hooks_dir}"
	fi
done

echo "==> Bootstrap complete. Run 'make sync' to populate shared directories."
