#!/usr/bin/env bash
# MCP github server wrapper.
#
# Resolves the GitHub token at spawn time so the github-mcp-server works
# regardless of how the agent runtime was launched (stale terminals, GUI
# launchers, non-interactive shells that never source ~/.zshrc).
#
# Resolution order:
#   1. GITHUB_PERSONAL_ACCESS_TOKEN already set in the process environment
#   2. GITHUB_TOKEN from the environment, else from ~/.mcp.env
#   3. gh CLI auth token (keyring)
#
# Install (once per machine, ~/.local/bin must be on PATH):
#   cp scripts/mcp-github.sh ~/.local/bin/mcp-github
#   chmod +x ~/.local/bin/mcp-github
#
# Prerequisite: the github-mcp-server binary must be on PATH:
#   go install github.com/github/github-mcp-server/cmd/github-mcp-server@latest
#   (or: brew install github-mcp-server)
set -euo pipefail

if [[ -f "${HOME}/.mcp.env" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.mcp.env"
fi

if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="${GITHUB_TOKEN}"
    else
        gh_token="$(gh auth token 2>/dev/null || true)"
        export GITHUB_PERSONAL_ACCESS_TOKEN="${gh_token}"
    fi
fi

exec github-mcp-server stdio
