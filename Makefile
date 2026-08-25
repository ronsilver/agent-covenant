# =============================================================================
# Makefile - agent-covenant
# =============================================================================

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

SCRIPTS_DIR := scripts
TESTS_DIR := tests

SHELL_SCRIPTS := $(SCRIPTS_DIR)/sync.sh $(SCRIPTS_DIR)/validate.sh $(SCRIPTS_DIR)/validate-subagent-mode.sh $(SCRIPTS_DIR)/validate-kernel-budget.sh $(SCRIPTS_DIR)/validate-router-delegation.sh $(SCRIPTS_DIR)/mcp-github.sh
SHELL_LIBS    := $(SCRIPTS_DIR)/lib/common.sh $(SCRIPTS_DIR)/lib/sync.sh
SHELL_ALL     := $(SHELL_SCRIPTS) $(SHELL_LIBS)

# Set VERBOSE=1 to enable bash -x trace output, e.g.: make sync VERBOSE=1
BASH_EXEC := $(if $(filter 1,$(VERBOSE)),bash -x,bash)

# =============================================================================
# Validation (self-check)
# =============================================================================

.PHONY: lint-md
lint-md: ## Run markdownlint on all markdown files
	@echo "Running markdownlint..."
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint $$(find . -name "*.md" \
			-not -path "./.git/*" \
			-not -path "./node_modules/*" \
			-not -path "./.opencode/node_modules/*" \
			-not -path "./docs/plans/*"); \
	else \
		echo "  markdownlint not installed, skipping (npm install -g markdownlint-cli)"; \
	fi
	@echo "✓ markdownlint passed"

.PHONY: lint
lint: ## Run shellcheck on all scripts
	@echo "Running shellcheck..."
	shellcheck -x $(SHELL_SCRIPTS)
	@echo "Running shellcheck on libraries..."
	shellcheck --shell=bash $(SHELL_LIBS)
	@echo "Running shellcheck on test files..."
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shellcheck --shell=bash $(TESTS_DIR)/*.bats; \
	else \
		echo "  No .bats files found, skipping"; \
	fi
	@echo "✓ shellcheck passed"

.PHONY: fmt-check
fmt-check: ## Check shell script formatting
	@echo "Running shfmt check..."
	shfmt -d -i 4 -ci $(SHELL_ALL)
	@echo "Checking test file formatting..."
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shfmt -d -i 4 -ci $(TESTS_DIR)/*.bats; \
	else \
		echo "  No .bats files found, skipping"; \
	fi
	@echo "✓ shfmt passed"

.PHONY: fmt
fmt: ## Format shell scripts in-place
	shfmt -w -i 4 -ci $(SHELL_ALL)
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shfmt -w -i 4 -ci $(TESTS_DIR)/*.bats; \
	fi

.PHONY: test
test: ## Run bats tests
	@echo "Running bats tests..."
	bats $(TESTS_DIR)/
	@echo "✓ tests passed"

.PHONY: validate
validate: validate-subagent-mode validate-mcp-config validate-kernel-budget validate-icons validate-evals validate-router-delegation ## Run manifest + subagent + MCP + kernel budget + icon + eval + router delegation validation
	@echo "Running manifest validation..."
	$(SCRIPTS_DIR)/validate.sh
	@echo "✓ validation passed"

.PHONY: validate-mcp-config
validate-mcp-config: ## Validate MCP config portability (bare binaries, no PATH env, no secrets)
	@echo "Running MCP config validation..."
	@python3 $(SCRIPTS_DIR)/validate-mcp-config.py --ci
	@echo "✓ MCP config validation passed"

.PHONY: validate-subagent-mode
validate-subagent-mode: ## Check all subagents use mode: subagent
	@echo "Running subagent mode validation..."
	@$(SCRIPTS_DIR)/validate-subagent-mode.sh
	@echo "✓ subagent mode validation passed"

.PHONY: validate-router-delegation
validate-router-delegation: ## Check router dispatch mandate (REFUSAL PROTOCOL, Dispatch, MCP write root)
	@echo "Running router delegation validation..."
	@$(SCRIPTS_DIR)/validate-router-delegation.sh
	@echo "✓ router delegation validation passed"

.PHONY: validate-kernel-budget
validate-kernel-budget: ## Check kernel files stay within the 6000-byte budget
	@echo "Running kernel budget validation..."
	@$(SCRIPTS_DIR)/validate-kernel-budget.sh
	@echo ""

.PHONY: validate-icons
validate-icons: ## Check content/ for banned emoji/dingbat icons (gate: exits 1 on violation)
	@echo "Running content icon check..."
	@python3 $(SCRIPTS_DIR)/sweep-content-icons.py --check
	@echo ""

.PHONY: validate-skill-refs
validate-skill-refs: ## Check skill references and orphaned files (informational — non-blocking)
	@echo "Running skill reference validation..."
	@$(SCRIPTS_DIR)/validate-skill-references.sh || true
	@echo ""

.PHONY: validate-canonical-paths
validate-canonical-paths: ## Validate manifest paths against canonical agent docs (informational)
	@echo "Running canonical path validation..."
	@$(SCRIPTS_DIR)/validate-canonical-paths.sh || true
	@echo ""

.PHONY: validate-quality
validate-quality: ## Score all skills against 7-pillar quality standard (min score: 70)
	@echo "Running skill quality validation (7-pillar standard)..."
	@python3 $(SCRIPTS_DIR)/validate-skill-quality.py --ci --min $(or $(MIN),70) || (echo "❌ Some skills below threshold. Set MIN=<score> to adjust."; exit 1)
	@echo "✓ Quality validation passed"
	@echo ""

.PHONY: validate-shell-safety
validate-shell-safety: ## Scan content/ for ! characters that trigger Zsh history expansion
	@echo "Running shell safety validation..."
	@python3 $(SCRIPTS_DIR)/validate-shell-safety.py --ci || (echo "❌ Shell-unsafe '!' patterns found. Use validate-shell-safety.py --file <path> to locate."; exit 1)
	@echo "✓ Shell safety validation passed"
	@echo ""

.PHONY: validate-no-fintech
validate-no-fintech: ## Check content/ is free of fintech-domain coupling
	@echo "Running fintech domain validation..."
	@bash $(SCRIPTS_DIR)/validate-no-fintech.sh
	@echo ""

.PHONY: validate-evals
validate-evals: ## Validate skill evals presence, schema, and minimal quality
	@echo "Running eval validation..."
	@python3 $(SCRIPTS_DIR)/validate-evals.py --ci || (echo "[ERROR] Eval validation failed"; exit 1)
	@echo "[PASS] Eval validation passed"
	@echo ""

.PHONY: check
check: lint lint-md fmt-check validate validate-no-fintech validate-subagent-mode validate-mcp-config validate-quality validate-shell-safety test ## Run full validation chain
	@echo "Tip: run 'make validate-skill-refs' to check skill reference integrity."
	@echo ""
	@echo "✓ All checks passed"

.PHONY: benchmark benchmark-probe benchmark-dry
benchmark: ## Run benchmark harness (MODE=context|baseline|paired, RUNS=1..10, MAX_RUNS cap)
	python3 tests/benchmark/benchmark.py --mode $(or $(MODE),paired) --runs $(or $(RUNS),5) --max-runs $(or $(MAX_RUNS),10)

benchmark-probe: ## Probe dry-run: emit exactly two mode commands, no spend
	python3 tests/benchmark/benchmark.py --probe-only --dry-run

benchmark-dry: ## Dry-run: print opencode run commands, write nothing
	python3 tests/benchmark/benchmark.py --dry-run

# =============================================================================
# Sync
# =============================================================================

.PHONY: sync
sync: ## Sync rules to all enabled agents  [VERBOSE=1 for trace]
	$(BASH_EXEC) $(SCRIPTS_DIR)/sync.sh

.PHONY: sync-dry
sync-dry: ## Dry-run sync (show what would happen)  [VERBOSE=1 for trace]
	$(BASH_EXEC) $(SCRIPTS_DIR)/sync.sh --dry-run

.PHONY: sync-force
sync-force: ## Force sync ignoring the content cache  [VERBOSE=1 for trace]
	$(BASH_EXEC) $(SCRIPTS_DIR)/sync.sh --force

.PHONY: list
list: ## List available agents
	$(BASH_EXEC) $(SCRIPTS_DIR)/sync.sh --list

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
