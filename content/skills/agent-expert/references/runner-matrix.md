# Agent Runner Comparison Matrix

| Feature | Claude Code | OpenCode | Antigravity | Codex CLI | Codex App | Pi | OMP |
|---|---|---|---|---|---|---|---|---|
| Rules | CLAUDE.md | AGENTS.md | GEMINI.md | AGENTS.md | — (shared) | AGENTS.md | AGENTS.md |
| MCP stdio | Yes | Yes | Yes | Yes (TOML, manual) | shared | No | Yes |
| MCP HTTP/SSE | Both | Both | — | No | No | No | — |
| Skills | Yes (tool) | Yes (tool) | Yes (@ file) | Yes (file path) | Yes (file path) | Yes (read) | Yes (skill:// read) |
| Subagents | Yes | Yes | No | Yes | No | No | No |
| Hooks | Yes | Plugin-based | No | No | No | No | No |

## Permission Modes
| Mode | Autonomy |
|---|---|
| default | Ask permission per action |
| acceptEdits | Accept file edits, ask for system ops |
| bypassPermissions | Full auto (dangerous) |
| plan | Show plan only, no execution |

## Subagent Contract
```json
{
  "task_id": "uuid",
  "status": "success|error",
  "output_summary": "<1-2 sentences>",
  "files_modified": ["path"],
  "errors": ["description"]
}
```
- Always isolated context
- Never shared mutable state
- Verify critical claims on return
