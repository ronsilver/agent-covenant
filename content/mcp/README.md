# MCP Servers

Unified Model Context Protocol server configuration for all enabled AI agents. 12 MCP servers provide domain tools for GitHub, AWS, Context7, OpenSpec, and more.

## Configured Servers

| Server | Transport | Purpose |
|---|---|---|
| `deepwiki` | Cloud | Documentation search |
| `fetch` | uvx (`--with mcp<2`) | URL content fetching |
| `filesystem` | npx | Local file access |
| `github` | wrapper (`mcp-github`) | GitHub API (issues, PRs, repos) |
| `memory` | npx | Knowledge graph persistence |
| `sequential-thinking` | npx | Structured reasoning |
| `time` | uvx (`--with mcp<2`) | Timezone utilities |
| `aws-api` | uvx | AWS API calls |
| `aws-docs` | uvx | AWS documentation |
| `aws-pricing` | uvx | AWS cost data |
| `grafana-cloud` | uvx | Grafana Cloud (monitoring.example.com) |
| `grafana-selfhosted` | uvx | Self-hosted Grafana |
| `atlassian` | uvx | Jira + Confluence |
| `notion` | npm | Notion API |
| `context7` | npx | Library documentation |
| `gitmcp` | npx | GitHub code search |
| `openspec` | npx | OpenSpec project management |
| `graphify` | uvx | Knowledge graph query server (query_graph, get_node, get_neighbors, get_community, god_nodes, graph_stats, shortest_path) |

## Prerequisites

```bash
brew install node uv docker
```

Set up environment tokens via `~/.mcp.env` (see `.env.example` in this directory).

## Sync

```bash
make sync       # Deploy to all enabled agents
```

MCP config syncs to each agent's native location: `~/.codeium/windsurf/.mcp.json`, `~/.claude/.mcp.json`, etc.

## Custom Server


## Reference

→ Full server catalog with token config: [`docs/reference/mcp-servers.md`](../../docs/reference/mcp-servers.md)  
→ Adding a new server: [`AGENTS.md`](../../AGENTS.md) §MCP Servers
