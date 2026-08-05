#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# setup-lsp.sh — Bootstrap LSP servers for AI coding agents
#
# Installs LSP plugins for Claude Code and verifies LSP binaries
# required by both Claude Code and OpenCode (auto_lsp).
#
# Usage: ./scripts/setup-lsp.sh [--check-only]
#
# Marketplaces:
#   - claude-plugins-official (Anthropic 1st party)
#   - boostvolt/claude-code-lsps (community, for gaps)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Plugins from the official Anthropic marketplace
OFFICIAL_PLUGINS=(
    gopls-lsp
    typescript-lsp
    pyright-lsp
    jdtls-lsp
    swift-lsp
    ruby-lsp
    clangd-lsp
)

# Plugins from boostvolt marketplace (gaps not covered by official)
BOOSTVOLT_MARKETPLACE="boostvolt/claude-code-lsps"
BOOSTVOLT_PLUGINS=(
    bash-language-server
    terraform-ls
    yaml-language-server
    dart-analyzer
)

# Binary → install hint mapping (for verification step)
declare -A BINARY_INSTALL_HINT=(
    [gopls]="go install golang.org/x/tools/gopls@latest"
    [typescript-language-server]="npm i -g typescript-language-server typescript"
    [pyright-langserver]="pip install pyright"
    [bash-language-server]="brew install bash-language-server"
    [terraform-ls]="brew install terraform-ls"
    [jdtls]="brew install jdtls"
    [sourcekit-lsp]="xcode-select --install"
    [ruby-lsp]="gem install ruby-lsp"
    [clangd]="xcode-select --install"
    [yaml-language-server]="brew install yaml-language-server"
    [dart]="brew install dart"
)

# All binaries to verify
BINARIES=(
    gopls
    typescript-language-server
    pyright-langserver
    bash-language-server
    terraform-ls
    jdtls
    sourcekit-lsp
    ruby-lsp
    clangd
    yaml-language-server
    dart
)

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

check_only=false

usage() {
    echo "Usage: $(basename "$0") [--check-only]"
    echo ""
    echo "Options:"
    echo "  --check-only   Only verify binaries, do not install plugins"
    echo "  -h, --help     Show this help"
}

install_claude_plugins() {
    if ! command -v claude &>/dev/null; then
        log_warn "Claude Code not found in PATH — skipping plugin installation"
        return 0
    fi

    log_info "Claude Code detected"

    # Add boostvolt marketplace for gap plugins
    log_info "Adding marketplace: ${BOOSTVOLT_MARKETPLACE}"
    if ! claude plugin marketplace add "${BOOSTVOLT_MARKETPLACE}" 2>/dev/null; then
        log_warn "Failed to add ${BOOSTVOLT_MARKETPLACE} — may already exist"
    fi

    # Install official plugins
    log_info "Installing official LSP plugins..."
    local failed=0
    for plugin in "${OFFICIAL_PLUGINS[@]}"; do
        if claude plugin install "${plugin}@claude-plugins-official" --scope user 2>/dev/null; then
            log_info "  Installed: ${plugin}"
        else
            log_warn "  Failed or already installed: ${plugin}"
            ((failed++)) || true
        fi
    done

    # Install boostvolt plugins
    log_info "Installing community LSP plugins (boostvolt)..."
    for plugin in "${BOOSTVOLT_PLUGINS[@]}"; do
        if claude plugin install "${plugin}@claude-code-lsps" --scope user 2>/dev/null; then
            log_info "  Installed: ${plugin}"
        else
            log_warn "  Failed or already installed: ${plugin}"
            ((failed++)) || true
        fi
    done

    if [[ ${failed} -gt 0 ]]; then
        log_warn "${failed} plugin(s) failed or were already installed"
    fi
}

check_opencode() {
    if ! command -v opencode &>/dev/null; then
        log_info "OpenCode not found in PATH — skipping"
        return 0
    fi

    log_info "OpenCode detected — auto_lsp is enabled by default"
    log_info "  LSP servers in PATH will be auto-detected via root markers"
}

verify_binaries() {
    log_info "Verifying LSP binaries in PATH..."

    local found=0
    local missing=0

    for bin in "${BINARIES[@]}"; do
        if command -v "${bin}" &>/dev/null; then
            local version
            version=$("${bin}" --version 2>/dev/null | head -1 || echo "unknown")
            echo -e "  ${GREEN}✓${NC} ${bin} (${version})"
            ((found++))
        else
            local hint="${BINARY_INSTALL_HINT[${bin}]:-}"
            echo -e "  ${RED}✗${NC} ${bin}${hint:+ — install: ${hint}}"
            ((missing++))
        fi
    done

    echo ""
    log_info "Summary: ${found} found, ${missing} missing"

    if [[ ${missing} -gt 0 ]]; then
        log_warn "Install missing binaries for full LSP coverage"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-only)
                check_only=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo -e "${BOLD}=== LSP Setup for AI Agents ===${NC}"
    echo ""

    if [[ "${check_only}" == false ]]; then
        install_claude_plugins
        echo ""
    fi

    check_opencode
    echo ""
    verify_binaries
}

main "$@"
