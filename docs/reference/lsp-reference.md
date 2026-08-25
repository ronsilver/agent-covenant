# LSP Reference — AI Agent Code Intelligence

Language Server Protocol (LSP) configuration for AI coding agents, mapped to supported tech stacks.

---

## Agent Support

| Agent | LSP Support | Mechanism | Configuration |
|-------|------------|-----------|---------------|
| **OpenCode** | Native | `auto_lsp: true` (default) | Auto-detects LSPs via project root markers (`go.mod`, `package.json`, etc.) |
| **Claude Code** | Plugins | `.lsp.json` via plugin system | `claude plugin install <name>@<marketplace>` |
| **Antigravity** | N/A | IDE built-in (Gemini-powered) | Not configurable via this system |
| **Codex CLI** | Not supported | — | — |
| **Pi** | Not supported | — | — |
| **OMP** | Not supported | — | — |

---

## Plugin Marketplaces (Claude Code)

| Marketplace | Type | Covers |
|-------------|------|--------|
| `claude-plugins-official` | **1st party (Anthropic)** | Go, TypeScript, Python, Java, Swift, Ruby, C/C++, Kotlin, Lua, PHP, Rust, C# |
| `boostvolt/claude-code-lsps` | Community (149 stars, MIT) | Bash, Terraform, YAML, Dart, and 18 more |

### Setup

```bash
# Official marketplace is auto-registered
# Add boostvolt for gap coverage
claude plugin marketplace add boostvolt/claude-code-lsps
```

---

## Tech Stack LSP Mapping

### Critical Priority (core backend + frontend + data)

| Language | LSP Server | Plugin (Claude Code) | Marketplace | Binary | Install |
|----------|-----------|---------------------|-------------|--------|---------|
| **Go** | gopls | `gopls-lsp` | oficial | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| **TypeScript/JS** | typescript-language-server | `typescript-lsp` | oficial | `typescript-language-server` | `npm i -g typescript-language-server typescript` |
| **Python** | Pyright | `pyright-lsp` | oficial | `pyright-langserver` | `pip install pyright` |
| **Shell/Bash** | bash-language-server | `bash-language-server` | boostvolt | `bash-language-server` | `brew install bash-language-server` |

### Medium Priority (specific services)

| Language | LSP Server | Plugin (Claude Code) | Marketplace | Binary | Install |
|----------|-----------|---------------------|-------------|--------|---------|
| **HCL (Terraform)** | terraform-ls | `terraform-ls` | boostvolt | `terraform-ls` | `brew install terraform-ls` |
| **Java** | Eclipse JDT.LS | `jdtls-lsp` | oficial | `jdtls` | `brew install jdtls` |
| **Swift** | SourceKit-LSP | `swift-lsp` | oficial | `sourcekit-lsp` | Bundled with Xcode (`xcode-select --install`) |

### Low Priority (legacy / limited repos)

| Language | LSP Server | Plugin (Claude Code) | Marketplace | Binary | Install |
|----------|-----------|---------------------|-------------|--------|---------|
| **Ruby** | ruby-lsp (Shopify) | `ruby-lsp` | oficial | `ruby-lsp` | `gem install ruby-lsp` |
| **Objective-C** | clangd | `clangd-lsp` | oficial | `clangd` | `xcode-select --install` |
| **YAML** | yaml-language-server | `yaml-language-server` | boostvolt | `yaml-language-server` | `brew install yaml-language-server` |
| **Dart** | Dart analysis server | `dart-analyzer` | boostvolt | `dart` | `brew install dart` |

### Not Covered

| Language | Reason |
|----------|--------|
| **Scala** | metals not available in any Claude Code marketplace. 1 repo (`data-processing-spark`). |
| **PLpgSQL** | No mature standalone LSP for SQL/PLpgSQL via CLI. |
| **Jupyter Notebook** | Not a language — covered by Python LSP for `.py` cells. |

---

## OpenCode auto_lsp

OpenCode (Crush) enables `auto_lsp: true` by default. It detects LSP servers in `$PATH` based on project root markers:

| Root Marker | LSP Started | Language |
|-------------|------------|---------|
| `go.mod` | `gopls` | Go |
| `package.json`, `tsconfig.json` | `typescript-language-server` | TypeScript/JS |
| `pyproject.toml`, `setup.py` | `pyright-langserver` | Python |
| `Cargo.toml` | `rust-analyzer` | Rust |
| `pom.xml`, `build.gradle` | `jdtls` | Java |
| `Gemfile` | `ruby-lsp` | Ruby |
| `Package.swift` | `sourcekit-lsp` | Swift |

No explicit LSP configuration is needed in `~/.config/opencode/opencode.json` — just ensure binaries are in `$PATH`.

To override or add custom LSP config:

```json
{
  "lsp": {
    "terraform": {
      "command": "terraform-ls",
      "args": ["serve"],
      "filetypes": ["terraform"],
      "root_markers": ["*.tf"]
    }
  }
}
```

---

## Bootstrap Script

```bash
# Full setup: install plugins + verify binaries
./scripts/setup-lsp.sh

# Verify binaries only (no plugin installation)
./scripts/setup-lsp.sh --check-only
```

---

## References

- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code Plugin Discovery](https://code.claude.com/docs/en/discover-plugins)
- [boostvolt/claude-code-lsps](https://github.com/boostvolt/claude-code-lsps)
- [OpenCode/Crush Schema](https://github.com/charmbracelet/crush/blob/main/schema.json)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
