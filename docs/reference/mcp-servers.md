# MCP Servers Reference

12 MCP servers configured in `content/mcp/mcp.json`.

## Server Catalog

| Server | Description | Type |
|--------|-------------|------|
| **fetch** | Fetch and extract content from URLs | Standard (uvx, `--with mcp<2`) |
| **filesystem** | File system read/write operations | Standard (npx) |
| **github** | GitHub API integration | Standard (installed binary) |
| **memory** | Persistent memory storage for AI context | Standard (npx) |
| **sequential-thinking** | Multi-step reasoning and chain-of-thought processing | Standard (npx) |
| **time** | Time zone conversion and time-based operations | Standard (uvx, `--with mcp<2`) |
| **aws-docs** | AWS documentation search and retrieval | Standard (uvx) |
| **aws-pricing** | AWS pricing catalog and cost estimation | Standard (uvx) |
| **grafana-cloud** | Grafana Cloud dashboards, alerts, datasources | Cloud (SSE) |
| **grafana-selfhosted** | Self-hosted Grafana dashboards, alerts, datasources | Cloud (SSE) |
| **atlassian** | Jira and Confluence integration | Standard (npx) |
| **notion** | Notion pages and databases | Standard (npx) |
| **context7** | Up-to-date library and framework documentation | Cloud (SSE) |
| **gitmcp** | Semantic search over GitHub repositories | Cloud (SSE) |
| **openspec** | OpenSpec proposal and spec management | Standard (npx) |
| **gitnexus** | GitNexus code intelligence | Standard (npx) |

## Synced Locations

| Agent | MCP Config Path |
|-------|-----------------|
| **Claude Code** | `./.mcp.json` (project scope — Claude Code 2.x reads this; config-dir `.mcp.json` is legacy) |
| **Antigravity** | `~/.gemini/antigravity/mcp_config.json` |
| **OpenCode** | `~/.config/opencode/opencode.json` |
| **OMP** | `~/.omp/agent/mcp.json` |

Codex CLI: TOML (~/.codex/config.toml, manual — not synced); Pi: no MCP; Codex App: shares codex-cli config.

## Token Configuration

```bash
cp content/mcp/.env.example ~/.mcp.env
# Edit ~/.mcp.env with your tokens
# Add to ~/.zshrc: [ -f ~/.mcp.env ] && source ~/.mcp.env
source ~/.zshrc && make sync
```

| Server | Token Required |
|--------|----------------|
| **github** | `GITHUB_TOKEN` — [github.com/settings/tokens](https://github.com/settings/tokens) (scopes: `repo`, `read:org`, `read:user`) |
| **grafana-cloud** | `GRAFANA_URL`, `GRAFANA_SERVICE_ACCOUNT_TOKEN` |
| **grafana-selfhosted** | `GRAFANA_SELFHOSTED_URL`, `GRAFANA_SELFHOSTED_SERVICE_ACCOUNT_TOKEN` |
| **atlassian** | `CONFLUENCE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN`; `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN` |
| **notion** | `NOTION_API_TOKEN` |

## Portability Rules

`make sync` deploys the `mcp` block as declared in the canonical sources
(`content/mcp/mcp.json`, `content/mcp/opencode-mcp.json`). The sync pipeline
must NOT transform them, or every `make sync` re-breaks deployments:

- **Bare binaries only**: server commands use `npx`, `uvx`, `go`, `python` —
  never absolute paths. Absolute paths couple the config to the PATH of the
  sync machine (homebrew vs mise vs asdf) and break on other machines. The only
  exception is the uv-tool venv interpreter
  (`~/.local/share/uv/tools/*/bin/python`), validated by
  `scripts/validate-mcp-config.py`.
- **No PATH injection**: never inject a literal `PATH` into a server's
  `environment`/`env`. Server processes inherit the agent runtime's PATH.
- **Secrets via env, never inline**: reference tokens with `{env:VAR}`
  (OpenCode runtime expansion) or `${VAR}` (expanded at sync time from
  `~/.mcp.env`). Never commit a literal token to a config file.
- **Split command arrays**: keep `["binary", "arg", ...]` split. A single
  array element containing the full command string causes
  `posix_spawn` ENOENT.
- **openspec** runs via `npx -y openspec-mcp` (npm 0.4.2). The PyPI `uvx
  openspec-mcp` (0.2.0) distribution is broken.
- **github** runs the `mcp-github` wrapper (bare command on PATH), which
  resolves the token at spawn time (process env → `~/.mcp.env` → `gh auth
  token`) and `exec`s the pre-installed `github-mcp-server`. Never use
  `go run ...@latest` — compiling on first spawn exceeds the agent runtime's
  MCP connection timeout (`MCP error -32000: Connection closed`), and the
  server exits immediately without a token (`Error: authentication required`).
  Install once per machine:
  `cp scripts/mcp-github.sh ~/.local/bin/mcp-github` (ensure `~/.local/bin` is
  on PATH) and `go install github.com/github/github-mcp-server/cmd/github-mcp-server@latest`
  (or `brew install github-mcp-server`).
- **fetch / time** need `uvx --with "mcp<2"` until the upstream servers are
  compatible with the mcp SDK 2.x (they import `mcp.shared.exceptions.McpError`,
  removed in 2.0.0).

`make validate-mcp-config` enforces all of the above in CI.


