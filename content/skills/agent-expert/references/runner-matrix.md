# Agent Runner Comparison Matrix

| Feature | Claude Code | OpenCode | Cursor | Windsurf | Codex CLI | Gemini CLI | Copilot |
|---|---|---|---|---|---|---|---|
| Rules | CLAUDE.md | AGENTS.md | .cursor/rules/ | global_rules.md (6KB) | AGENTS.md | GEMINI.md | instructions.md |
| MCP stdio | Yes | Yes | Yes | Yes | Yes | Yes | No |
| MCP HTTP/SSE | HTTP only | Both | JSON | JSON | TOML | No | via VS Code |
| Skills | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Subagents | Yes | Yes | Yes | No | Yes | No | No |
| Hooks | Yes | Plugin-based | No | MCP callbacks | No | settings.json | No |

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
