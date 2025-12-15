# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Makefile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.2.0
# Purpose....: Development workflow automation for OraDBA project. Provides
#              targets for testing, linting, formatting, building, and releasing.
# Notes......: Use 'make help' to show all available targets
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Project configuration
PROJECT_NAME := oradba
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
SHELL := /bin/bash

# Directories
SRC_DIR := srv
BIN_DIR := $(SRC_DIR)/bin
LIB_DIR := $(SRC_DIR)/lib
ETC_DIR := $(SRC_DIR)/etc
SQL_DIR := $(SRC_DIR)/sql
TEST_DIR := tests
DOC_DIR := doc
SCRIPTS_DIR := scripts
DIST_DIR := dist

# Tools
SHELLCHECK := $(shell command -v shellcheck 2>/dev/null)
SHFMT := $(shell command -v shfmt 2>/dev/null)
BATS := $(shell command -v bats 2>/dev/null)
GIT := $(shell command -v git 2>/dev/null)
TAR := $(shell command -v tar 2>/dev/null)

# Color output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_RED := \033[31m

# Default target
.DEFAULT_GOAL := help

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## Show this help message
	@echo -e "$(COLOR_BOLD)OraDBA Development Makefile$(COLOR_RESET)"
	@echo "Version: $(VERSION)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Usage:$(COLOR_RESET)"
	@echo -e "  make $(COLOR_GREEN)<target>$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo "  make test              # Run all tests"
	@echo "  make lint              # Run linters"
	@echo "  make format            # Format shell scripts"
	@echo "  make build             # Build distribution archive"
	@echo "  make install           # Install locally"

# ==============================================================================
# Development
# ==============================================================================

.PHONY: test
test: ## Run all tests
	@echo -e "$(COLOR_BLUE)Running tests...$(COLOR_RESET)"
	@if [ -n "$(BATS)" ]; then \
		$(BATS) $(TEST_DIR)/*.bats; \
	else \
		echo -e "$(COLOR_RED)Error: bats not found. Install with: brew install bats-core$(COLOR_RESET)"; \
		exit 1; \
	fi

.PHONY: test-unit
test-unit: ## Run unit tests only
	 -e "$(COLOR_BLUE)Running unit tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/unit/*.bats 2>/dev/null || echo "No unit tests found"

.PHONY: test-integration
test-integration: ## Run integration tests only
	 -e "$(COLOR_BLUE)Running integration tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/integration/*.bats 2>/dev/null || echo "No integration tests found"

.PHONY: lint
lint: lint-shell lint-scripts ## Run all linters

.PHONY: lint-shell
lint-shell: ## Lint shell scripts with shellcheck
	 -e "$(COLOR_BLUE)Linting shell scripts...$(COLOR_RESET)"
	@if [ -n "$(SHELLCHECK)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHELLCHECK) -x -S warning || exit 1; \
		echo "$(COLOR_GREEN)✓ Shell scripts passed linting$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)Error: shellcheck not found. Install with: brew install shellcheck$(COLOR_RESET)"; \
		exit 1; \
	fi

.PHONY: lint-scripts
lint-scripts: ## Check for common script issues
	 -e "$(COLOR_BLUE)Checking scripts for common issues...$(COLOR_RESET)"
	@! find $(BIN_DIR) -name "*.sh" -type f -exec grep -l "^#!/bin/sh" {} \; | \
		grep . && echo "$(COLOR_GREEN)✓ No #!/bin/sh found (use #!/usr/bin/env bash)$(COLOR_RESET)" || \
		(echo "$(COLOR_RED)✗ Found scripts using #!/bin/sh$(COLOR_RESET)" && exit 1)

.PHONY: format
format: ## Format shell scripts with shfmt
	 -e "$(COLOR_BLUE)Formatting shell scripts...$(COLOR_RESET)"
	@if [ -n "$(SHFMT)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHFMT) -i 4 -bn -ci -sr -w; \
		echo "$(COLOR_GREEN)✓ Scripts formatted$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Warning: shfmt not found. Install with: brew install shfmt$(COLOR_RESET)"; \
	fi

.PHONY: format-check
format-check: ## Check if scripts are formatted correctly
	 -e "$(COLOR_BLUE)Checking script formatting...$(COLOR_RESET)"
	@if [ -n "$(SHFMT)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHFMT) -i 4 -bn -ci -sr -d || \
			(echo "$(COLOR_RED)✗ Scripts need formatting. Run: make format$(COLOR_RESET)" && exit 1); \
		echo "$(COLOR_GREEN)✓ All scripts properly formatted$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Warning: shfmt not found$(COLOR_RESET)"; \
	fi

.PHONY: check
check: lint test ## Run all checks (lint + test)

.PHONY: validate
validate: ## Validate configuration files
	 -e "$(COLOR_BLUE)Validating configuration files...$(COLOR_RESET)"
	@bash -n $(ETC_DIR)/*.conf 2>/dev/null || true
	@bash -n $(ETC_DIR)/*.bashrc 2>/dev/null || true
	 -e "$(COLOR_GREEN)✓ Configuration files validated$(COLOR_RESET)"

# ==============================================================================
# Build and Distribution
# ==============================================================================

.PHONY: build
build: clean ## Build distribution archive
	 -e "$(COLOR_BLUE)Building OraDBA distribution...$(COLOR_RESET)"
	@mkdir -p $(DIST_DIR)
	@$(TAR) czf $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='$(DIST_DIR)' \
		--exclude='.github' \
		--exclude='*.bats' \
		--exclude='tests' \
		--transform 's,^,$(PROJECT_NAME)-$(VERSION)/,' \
		$(SRC_DIR) $(SCRIPTS_DIR) README.md LICENSE CHANGELOG.md VERSION
	 -e "$(COLOR_GREEN)✓ Distribution archive created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz$(COLOR_RESET)"
	@ls -lh $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz

.PHONY: install
install: ## Install OraDBA locally
	 -e "$(COLOR_BLUE)Installing OraDBA...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/install.sh
	 -e "$(COLOR_GREEN)✓ OraDBA installed$(COLOR_RESET)"

.PHONY: uninstall
uninstall: ## Uninstall OraDBA
	 -e "$(COLOR_BLUE)Uninstalling OraDBA...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/uninstall.sh 2>/dev/null || echo "Uninstall script not found"

# ==============================================================================
# Documentation
# ==============================================================================

.PHONY: docs
docs: ## Generate documentation
	 -e "$(COLOR_BLUE)Generating documentation...$(COLOR_RESET)"
	@mkdir -p $(DOC_DIR)
	@echo "# OraDBA Scripts" > $(DOC_DIR)/SCRIPTS.md
	@echo "" >> $(DOC_DIR)/SCRIPTS.md
	@for script in $(BIN_DIR)/*.sh; do \
		echo "## $$(basename $$script)" >> $(DOC_DIR)/SCRIPTS.md; \
		echo "" >> $(DOC_DIR)/SCRIPTS.md; \
		echo '```bash' >> $(DOC_DIR)/SCRIPTS.md; \
		$$script --help 2>&1 || echo "No help available"; \
		echo '```' >> $(DOC_DIR)/SCRIPTS.md; \
		echo "" >> $(DOC_DIR)/SCRIPTS.md; \
	done 2>/dev/null || true
	 -e "$(COLOR_GREEN)✓ Documentation generated$(COLOR_RESET)"

.PHONY: changelog
changelog: ## Update CHANGELOG.md from git commits
	 -e "$(COLOR_BLUE)Generating changelog...$(COLOR_RESET)"
	@if [ -n "$(GIT)" ]; then \
		echo "# Changelog" > CHANGELOG.new.md; \
		echo "" >> CHANGELOG.new.md; \
		$(GIT) log --pretty=format:"- %s (%h)" --reverse >> CHANGELOG.new.md; \
		echo "$(COLOR_YELLOW)New changelog preview:$(COLOR_RESET)"; \
		head -20 CHANGELOG.new.md; \
		rm CHANGELOG.new.md; \
	fi

# ==============================================================================
# Git and Version Management
# ==============================================================================

.PHONY: version
version: ## Show current version
	 -e "$(COLOR_BOLD)OraDBA Version: $(COLOR_GREEN)$(VERSION)$(COLOR_RESET)"

.PHONY: version-bump-patch
version-bump-patch: ## Bump patch version (0.0.X)
	 -e "$(COLOR_BLUE)Bumping patch version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	rest=$${current#*.}; \
	minor=$${rest%%.*}; \
	patch=$${rest#*.}; \
	new_patch=$$((patch + 1)); \
	echo "$$major.$$minor.$$new_patch" > VERSION; \
	echo "$(COLOR_GREEN)✓ Version bumped: $$current → $$major.$$minor.$$new_patch$(COLOR_RESET)"

.PHONY: version-bump-minor
version-bump-minor: ## Bump minor version (0.X.0)
	 -e "$(COLOR_BLUE)Bumping minor version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	rest=$${current#*.}; \
	minor=$${rest%%.*}; \
	new_minor=$$((minor + 1)); \
	echo "$$major.$$new_minor.0" > VERSION; \
	echo "$(COLOR_GREEN)✓ Version bumped: $$current → $$major.$$new_minor.0$(COLOR_RESET)"

.PHONY: version-bump-major
version-bump-major: ## Bump major version (X.0.0)
	 -e "$(COLOR_BLUE)Bumping major version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	new_major=$$((major + 1)); \
	echo "$$new_major.0.0" > VERSION; \
	echo "$(COLOR_GREEN)✓ Version bumped: $$current → $$new_major.0.0$(COLOR_RESET)"

.PHONY: tag
tag: ## Create git tag from VERSION file
	@if [ -n "$(GIT)" ]; then \
		$(GIT) tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
		echo "$(COLOR_GREEN)✓ Created tag v$(VERSION)$(COLOR_RESET)"; \
	fi

.PHONY: status
status: ## Show git status and current version
	 -e "$(COLOR_BOLD)Project Status$(COLOR_RESET)"
	 -e "Version: $(COLOR_GREEN)$(VERSION)$(COLOR_RESET)"
	@if [ -n "$(GIT)" ]; then \
		echo ""; \
		$(GIT) status -sb; \
	fi

# ==============================================================================
# Cleanup
# ==============================================================================

.PHONY: clean
clean: ## Clean build artifacts
	 -e "$(COLOR_BLUE)Cleaning build artifacts...$(COLOR_RESET)"
	@rm -rf $(DIST_DIR)
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name "*~" -type f -delete 2>/dev/null || true
	 -e "$(COLOR_GREEN)✓ Cleaned$(COLOR_RESET)"

.PHONY: clean-all
clean-all: clean ## Deep clean (including caches)
	 -e "$(COLOR_BLUE)Deep cleaning...$(COLOR_RESET)"
	@rm -rf .bats-cache 2>/dev/null || true
	 -e "$(COLOR_GREEN)✓ Deep cleaned$(COLOR_RESET)"

# ==============================================================================
# Development Tools
# ==============================================================================

.PHONY: tools
tools: ## Show installed development tools
	 -e "$(COLOR_BOLD)Development Tools Status$(COLOR_RESET)"
	@echo ""
	@printf "%-20s %s\n" "Tool" "Status"
	@printf "%-20s %s\n" "----" "------"
	@printf "%-20s %s\n" "shellcheck" "$$([ -n '$(SHELLCHECK)' ] && echo '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "shfmt" "$$([ -n '$(SHFMT)' ] && echo '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "bats" "$$([ -n '$(BATS)' ] && echo '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "git" "$$([ -n '$(GIT)' ] && echo '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@echo ""
	 -e "$(COLOR_YELLOW)Install missing tools:$(COLOR_RESET)"
	@echo "  macOS:  brew install shellcheck shfmt bats-core"
	@echo "  Linux:  apt-get install shellcheck shfmt bats"

.PHONY: setup-dev
setup-dev: ## Setup development environment
	 -e "$(COLOR_BLUE)Setting up development environment...$(COLOR_RESET)"
	@if [ "$$(uname)" = "Darwin" ] && command -v brew >/dev/null; then \
		echo "Installing development tools via Homebrew..."; \
		brew install shellcheck shfmt bats-core 2>/dev/null || true; \
	else \
		echo "$(COLOR_YELLOW)Please install tools manually:$(COLOR_RESET)"; \
		echo "  - shellcheck: https://github.com/koalaman/shellcheck"; \
		echo "  - shfmt: https://github.com/mvdan/sh"; \
		echo "  - bats: https://github.com/bats-core/bats-core"; \
	fi
	 -e "$(COLOR_GREEN)✓ Development environment setup complete$(COLOR_RESET)"

# ==============================================================================
# CI/CD Helpers
# ==============================================================================

.PHONY: ci
ci: clean lint test build ## Run CI pipeline locally
	 -e "$(COLOR_GREEN)✓ CI pipeline completed successfully$(COLOR_RESET)"

.PHONY: pre-commit
pre-commit: format lint ## Run pre-commit checks
	 -e "$(COLOR_GREEN)✓ Pre-commit checks passed$(COLOR_RESET)"

.PHONY: pre-push
pre-push: check ## Run pre-push checks
	 -e "$(COLOR_GREEN)✓ Pre-push checks passed$(COLOR_RESET)"

# ==============================================================================
# Release Management
# ==============================================================================

.PHONY: release-check
release-check: ## Check if ready for release
	 -e "$(COLOR_BLUE)Checking release readiness...$(COLOR_RESET)"
	@echo ""
	@echo "Version: $(VERSION)"
	@echo ""
	@if [ -n "$(GIT)" ]; then \
		if [ -n "$$($(GIT) status --porcelain)" ]; then \
			echo "$(COLOR_RED)✗ Working directory not clean$(COLOR_RESET)"; \
			exit 1; \
		else \
			echo "$(COLOR_GREEN)✓ Working directory clean$(COLOR_RESET)"; \
		fi; \
		if $(GIT) tag | grep -q "v$(VERSION)"; then \
			echo "$(COLOR_RED)✗ Tag v$(VERSION) already exists$(COLOR_RESET)"; \
			exit 1; \
		else \
			echo "$(COLOR_GREEN)✓ Version tag available$(COLOR_RESET)"; \
		fi; \
	fi
	@$(MAKE) check
	@echo ""
	 -e "$(COLOR_GREEN)✓ Ready for release$(COLOR_RESET)"

.PHONY: release-prepare
release-prepare: release-check build ## Prepare release
	 -e "$(COLOR_BLUE)Preparing release v$(VERSION)...$(COLOR_RESET)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Review CHANGELOG.md"
	@echo "  2. Commit changes: git commit -am 'Release v$(VERSION)'"
	@echo "  3. Create tag: make tag"
	@echo "  4. Push changes: git push && git push --tags"

# ==============================================================================
# Info
# ==============================================================================

.PHONY: info
info: ## Show project information
	 -e "$(COLOR_BOLD)OraDBA Project Information$(COLOR_RESET)"
	@echo ""
	@echo "Project:     $(PROJECT_NAME)"
	@echo "Version:     $(VERSION)"
	@echo "Shell:       $(SHELL)"
	@echo ""
	@echo "Directories:"
	@echo "  Source:    $(SRC_DIR)"
	@echo "  Scripts:   $(SCRIPTS_DIR)"
	@echo "  Tests:     $(TEST_DIR)"
	@echo "  Docs:      $(DOC_DIR)"
	@echo "  Dist:      $(DIST_DIR)"
	@echo ""
	@echo "Files:"
	@echo "  Scripts:   $$(find $(BIN_DIR) -name "*.sh" 2>/dev/null | wc -l | xargs)"
	@echo "  Libraries: $$(find $(LIB_DIR) -name "*.sh" 2>/dev/null | wc -l | xargs)"
	@echo "  SQL:       $$(find $(SQL_DIR) -name "*.sql" 2>/dev/null | wc -l | xargs)"
	@echo "  Tests:     $$(find $(TEST_DIR) -name "*.bats" 2>/dev/null | wc -l | xargs)"

# ==============================================================================
# Quick Shortcuts
# ==============================================================================

.PHONY: t
t: test ## Shortcut for test

.PHONY: l
l: lint ## Shortcut for lint

.PHONY: f
f: format ## Shortcut for format

.PHONY: b
b: build ## Shortcut for build

.PHONY: c
c: clean ## Shortcut for clean
