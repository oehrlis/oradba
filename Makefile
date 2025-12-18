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
PROJECT_NAME	:= oradba
VERSION 		:= $(shell cat VERSION 2>/dev/null || echo "0.0.0")
SHELL 			:= /bin/bash

# Directories
SRC_DIR 	:= src
BIN_DIR 	:= $(SRC_DIR)/bin
LIB_DIR 	:= $(SRC_DIR)/lib
ETC_DIR 	:= $(SRC_DIR)/etc
SQL_DIR 	:= $(SRC_DIR)/sql
TEST_DIR 	:= tests
DOC_DIR 	:= doc
SCRIPTS_DIR	:= scripts
DIST_DIR 	:= dist

# Tools
SHELLCHECK		:= $(shell command -v shellcheck 2>/dev/null)
SHFMT 			:= $(shell command -v shfmt 2>/dev/null)
MARKDOWNLINT	:= $(shell command -v markdownlint 2>/dev/null || command -v markdownlint-cli 2>/dev/null)
BATS 			:= $(shell command -v bats 2>/dev/null)
GIT 			:= $(shell command -v git 2>/dev/null)
TAR 			:= $(shell command -v tar 2>/dev/null)

# Color output
COLOR_RESET 	:= \033[0m
COLOR_BOLD		:= \033[1m
COLOR_GREEN 	:= \033[32m
COLOR_YELLOW	:= \033[33m
COLOR_BLUE 		:= \033[34m
COLOR_RED 		:= \033[31m

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
	@echo -e "$(COLOR_BOLD)Development:$(COLOR_RESET)"
	@grep -E '^(test|lint|format|check|validate).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Build & Distribution:$(COLOR_RESET)"
	@grep -E '^(build|install|uninstall|clean).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Documentation:$(COLOR_RESET)"
	@grep -E '^(docs|changelog).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Version & Git:$(COLOR_RESET)"
	@grep -E '^(version|tag|status).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)CI/CD & Release:$(COLOR_RESET)"
	@grep -E '^(ci|pre-commit|pre-push|release).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Tools & Info:$(COLOR_RESET)"
	@grep -E '^(tools|setup-dev|info|help).*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Quick Shortcuts:$(COLOR_RESET)"
	@grep -E '^[tlfbc]:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo "  make test              # Run all tests"
	@echo "  make lint              # Run all linters"
	@echo "  make format            # Format code"
	@echo "  make build             # Build distribution"
	@echo "  make ci                # Run full CI pipeline"

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
	@echo -e "$(COLOR_BLUE)Running unit tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/unit/*.bats 2>/dev/null || echo "No unit tests found"

.PHONY: test-integration
test-integration: ## Run integration tests only
	@echo -e "$(COLOR_BLUE)Running integration tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/integration/*.bats 2>/dev/null || echo "No integration tests found"

.PHONY: lint
lint: lint-shell lint-scripts lint-markdown ## Run all linters

.PHONY: lint-shell
lint-shell: ## Lint shell scripts with shellcheck
	@echo -e "$(COLOR_BLUE)Linting shell scripts...$(COLOR_RESET)"
	@if [ -n "$(SHELLCHECK)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHELLCHECK) -x -S warning || exit 1; \
		echo -e "$(COLOR_GREEN)✓ Shell scripts passed linting$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_RED)Error: shellcheck not found. Install with: brew install shellcheck$(COLOR_RESET)"; \
		exit 1; \
	fi

.PHONY: lint-scripts
lint-scripts: ## Check for common script issues
	@echo -e "$(COLOR_BLUE)Checking scripts for common issues...$(COLOR_RESET)"
	@! find $(BIN_DIR) -name "*.sh" -type f -exec grep -l "^#!/bin/sh" {} \; | \
		grep . && echo -e "$(COLOR_GREEN)✓ No #!/bin/sh found (use #!/usr/bin/env bash)$(COLOR_RESET)" || \
		(echo -e "$(COLOR_RED)✗ Found scripts using #!/bin/sh$(COLOR_RESET)" && exit 1)

.PHONY: lint-markdown
lint-markdown: ## Lint Markdown files with markdownlint
	@echo -e "$(COLOR_BLUE)Linting Markdown files...$(COLOR_RESET)"
	@if [ -n "$(MARKDOWNLINT)" ]; then \
		$(MARKDOWNLINT) --config .markdownlint.yaml *.md doc/*.md src/doc/*.md || exit 1; \
		echo -e "$(COLOR_GREEN)✓ Markdown files passed linting$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_YELLOW)Warning: markdownlint not found. Install with: npm install -g markdownlint-cli$(COLOR_RESET)"; \
	fi

.PHONY: format
format: ## Format shell scripts with shfmt
	@echo -e "$(COLOR_BLUE)Formatting shell scripts...$(COLOR_RESET)"
	@if [ -n "$(SHFMT)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHFMT) -i 4 -bn -ci -sr -w; \
		echo -e "$(COLOR_GREEN)✓ Scripts formatted$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_YELLOW)Warning: shfmt not found. Install with: brew install shfmt$(COLOR_RESET)"; \
	fi

.PHONY: format-check
format-check: ## Check if scripts are formatted correctly
	@echo -e "$(COLOR_BLUE)Checking script formatting...$(COLOR_RESET)"
	@if [ -n "$(SHFMT)" ]; then \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHFMT) -i 4 -bn -ci -sr -d || \
			(echo -e "$(COLOR_RED)✗ Scripts need formatting. Run: make format$(COLOR_RESET)" && exit 1); \
		echo -e "$(COLOR_GREEN)✓ All scripts properly formatted$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_YELLOW)Warning: shfmt not found$(COLOR_RESET)"; \
	fi

.PHONY: check
check: lint test ## Run all checks (lint + test)

.PHONY: validate
validate: ## Validate configuration files
	@echo -e "$(COLOR_BLUE)Validating configuration files...$(COLOR_RESET)"
	@bash -n $(ETC_DIR)/*.conf 2>/dev/null || true
	@bash -n $(ETC_DIR)/*.bashrc 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Configuration files validated$(COLOR_RESET)"

# ==============================================================================
# Build and Distribution
# ==============================================================================

.PHONY: build
build: clean clean-test-configs ## Build distribution archive and installer
	@echo -e "$(COLOR_BLUE)Building OraDBA distribution...$(COLOR_RESET)"
	@mkdir -p $(DIST_DIR)
	@$(TAR) czf $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='$(DIST_DIR)' \
		--exclude='.github' \
		--exclude='*.bats' \
		--exclude='tests' \
		--transform 's,^,$(PROJECT_NAME)-$(VERSION)/,' \
		$(SRC_DIR) $(SCRIPTS_DIR) README.md LICENSE CHANGELOG.md VERSION
	@echo -e "$(COLOR_GREEN)✓ Distribution archive created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz$(COLOR_RESET)"
	@ls -lh $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz
	@echo -e "$(COLOR_BLUE)Building installer script...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/build_installer.sh
	@echo -e "$(COLOR_GREEN)✓ Installer created: $(DIST_DIR)/oradba_install.sh$(COLOR_RESET)"
	@ls -lh $(DIST_DIR)/oradba_install.sh

.PHONY: install
install: ## Install OraDBA locally
	@echo -e "$(COLOR_BLUE)Installing OraDBA...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/install.sh
	@echo -e "$(COLOR_GREEN)✓ OraDBA installed$(COLOR_RESET)"

.PHONY: uninstall
uninstall: ## Uninstall OraDBA
	@echo -e "$(COLOR_BLUE)Uninstalling OraDBA...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/uninstall.sh 2>/dev/null || echo "Uninstall script not found"

# ==============================================================================
# Documentation
# ==============================================================================

# Documentation directories and files
USER_DOC_DIR := $(SRC_DIR)/doc
USER_DOC_CHAPTERS := $(USER_DOC_DIR)/??-*.md
USER_DOC_METADATA := $(USER_DOC_DIR)/metadata.yml
PANDOC_IMAGE := oehrlis/pandoc:latest

.PHONY: docs
docs: docs-html docs-pdf ## Generate all documentation (HTML and PDF)

.PHONY: docs-html
docs-html: ## Generate HTML user guide from markdown
	@echo -e "$(COLOR_BLUE)Generating HTML documentation...$(COLOR_RESET)"
	@mkdir -p $(DIST_DIR)
	@cd $(USER_DOC_DIR) && \
		pandoc ??-*.md -o ../../$(DIST_DIR)/oradba-user-guide.html \
		--metadata-file=metadata.yml \
		--toc --toc-depth=3 \
		--standalone \
		--self-contained 2>/dev/null || \
		echo -e "$(COLOR_YELLOW)⚠ Pandoc not available locally, skipping HTML generation$(COLOR_RESET)"
	@if [ -f "$(DIST_DIR)/oradba-user-guide.html" ]; then \
		echo -e "$(COLOR_GREEN)✓ HTML documentation generated: $(DIST_DIR)/oradba-user-guide.html$(COLOR_RESET)"; \
		ls -lh $(DIST_DIR)/oradba-user-guide.html; \
	fi

.PHONY: docs-pdf
docs-pdf: ## Generate PDF user guide from markdown (requires Docker)
	@echo -e "$(COLOR_BLUE)Generating PDF documentation...$(COLOR_RESET)"
	@mkdir -p $(DIST_DIR)
	@if command -v docker >/dev/null 2>&1; then \
		cd $(USER_DOC_DIR) && \
		docker run --rm -v $$(pwd):/workdir $(PANDOC_IMAGE) \
			??-*.md -o oradba-user-guide.pdf \
			--metadata-file=metadata.yml \
			--toc --toc-depth=3 \
			--pdf-engine=xelatex \
			-N --listings 2>&1 | grep -v "Missing character" || true; \
		mv oradba-user-guide.pdf ../../$(DIST_DIR)/ 2>/dev/null || true; \
		cd - >/dev/null; \
		if [ -f "$(DIST_DIR)/oradba-user-guide.pdf" ]; then \
			echo -e "$(COLOR_GREEN)✓ PDF documentation generated: $(DIST_DIR)/oradba-user-guide.pdf$(COLOR_RESET)"; \
			ls -lh $(DIST_DIR)/oradba-user-guide.pdf; \
		else \
			echo -e "$(COLOR_RED)✗ PDF generation failed$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)⚠ Docker not available, skipping PDF generation$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)  Install Docker to generate PDF documentation$(COLOR_RESET)"; \
	fi

.PHONY: docs-check
docs-check: ## Check if documentation source files exist
	@echo -e "$(COLOR_BLUE)Checking documentation files...$(COLOR_RESET)"
	@if [ ! -f "$(USER_DOC_METADATA)" ]; then \
		echo -e "$(COLOR_RED)✗ Metadata file not found: $(USER_DOC_METADATA)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@chapter_count=$$(ls -1 $(USER_DOC_DIR)/??-*.md 2>/dev/null | wc -l | xargs); \
	if [ "$$chapter_count" -eq 0 ]; then \
		echo -e "$(COLOR_RED)✗ No documentation chapters found$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	echo -e "$(COLOR_GREEN)✓ Found $$chapter_count documentation chapters$(COLOR_RESET)"

.PHONY: docs-clean
docs-clean: ## Remove generated documentation
	@echo -e "$(COLOR_BLUE)Cleaning generated documentation...$(COLOR_RESET)"
	@rm -f $(DIST_DIR)/oradba-user-guide.html 2>/dev/null || true
	@rm -f $(DIST_DIR)/oradba-user-guide.pdf 2>/dev/null || true
	@rm -f $(USER_DOC_DIR)/oradba-user-guide.html 2>/dev/null || true
	@rm -f $(USER_DOC_DIR)/oradba-user-guide.pdf 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Documentation cleaned$(COLOR_RESET)"

.PHONY: changelog
changelog: ## Update CHANGELOG.md from git commits
	@echo -e "$(COLOR_BLUE)Generating changelog...$(COLOR_RESET)"
	@if [ -n "$(GIT)" ]; then \
		echo "# Changelog" > CHANGELOG.new.md; \
		echo "" >> CHANGELOG.new.md; \
		$(GIT) log --pretty=format:"- %s (%h)" --reverse >> CHANGELOG.new.md; \
		echo -e "$(COLOR_YELLOW)New changelog preview:$(COLOR_RESET)"; \
		head -20 CHANGELOG.new.md; \
		rm CHANGELOG.new.md; \
	fi

# ==============================================================================
# Git and Version Management
# ==============================================================================

.PHONY: version
version: ## Show current version
	@echo -e "$(COLOR_BOLD)OraDBA Version: $(COLOR_GREEN)$(VERSION)$(COLOR_RESET)"

.PHONY: version-bump-patch
version-bump-patch: ## Bump patch version (0.0.X)
	@echo -e "$(COLOR_BLUE)Bumping patch version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	rest=$${current#*.}; \
	minor=$${rest%%.*}; \
	patch=$${rest#*.}; \
	new_patch=$$((patch + 1)); \
	echo "$$major.$$minor.$$new_patch" > VERSION; \
	echo -e "$(COLOR_GREEN)✓ Version bumped: $$current → $$major.$$minor.$$new_patch$(COLOR_RESET)"

.PHONY: version-bump-minor
version-bump-minor: ## Bump minor version (0.X.0)
	@echo -e "$(COLOR_BLUE)Bumping minor version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	rest=$${current#*.}; \
	minor=$${rest%%.*}; \
	new_minor=$$((minor + 1)); \
	echo "$$major.$$new_minor.0" > VERSION; \
	echo -e "$(COLOR_GREEN)✓ Version bumped: $$current → $$major.$$new_minor.0$(COLOR_RESET)"

.PHONY: version-bump-major
version-bump-major: ## Bump major version (X.0.0)
	@echo -e "$(COLOR_BLUE)Bumping major version...$(COLOR_RESET)"
	@current=$$(cat VERSION); \
	major=$${current%%.*}; \
	new_major=$$((major + 1)); \
	echo "$$new_major.0.0" > VERSION; \
	echo -e "$(COLOR_GREEN)✓ Version bumped: $$current → $$new_major.0.0$(COLOR_RESET)"

.PHONY: tag
tag: ## Create git tag from VERSION file
	@if [ -n "$(GIT)" ]; then \
		$(GIT) tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
		echo -e "$(COLOR_GREEN)✓ Created tag v$(VERSION)$(COLOR_RESET)"; \
	fi

.PHONY: status
status: ## Show git status and current version
	@echo -e "$(COLOR_BOLD)Project Status$(COLOR_RESET)"
	@echo -e "Version: $(COLOR_GREEN)$(VERSION)$(COLOR_RESET)"
	@if [ -n "$(GIT)" ]; then \
		echo ""; \
		$(GIT) status -sb; \
	fi

# ==============================================================================
# Cleanup
# ==============================================================================

.PHONY: clean
clean: ## Clean build artifacts
	@echo -e "$(COLOR_BLUE)Cleaning build artifacts...$(COLOR_RESET)"
	@rm -rf $(DIST_DIR)
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name "*~" -type f -delete 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Cleaned$(COLOR_RESET)"

.PHONY: clean-test-configs
clean-test-configs: ## Clean test-generated SID config files
	@echo -e "$(COLOR_BLUE)Cleaning test SID config files...$(COLOR_RESET)"
	@rm -f $(ETC_DIR)/sid.FREE.conf 2>/dev/null || true
	@rm -f $(ETC_DIR)/sid.CDB1.conf 2>/dev/null || true
	@rm -f $(ETC_DIR)/sid.TESTDB.conf 2>/dev/null || true
	@rm -f $(ETC_DIR)/sid.TESTDB1.conf 2>/dev/null || true
	@rm -f $(ETC_DIR)/sid.TESTDB2.conf 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Test config files cleaned$(COLOR_RESET)"

.PHONY: clean-all
clean-all: clean clean-test-configs docs-clean ## Deep clean (including caches, test configs, and docs)
	@echo -e "$(COLOR_BLUE)Deep cleaning...$(COLOR_RESET)"
	@rm -rf .bats-cache 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Deep cleaned$(COLOR_RESET)"

# ==============================================================================
# Development Tools
# ==============================================================================

.PHONY: tools
tools: ## Show installed development tools
	@echo -e "$(COLOR_BOLD)Development Tools Status$(COLOR_RESET)"
	@echo ""
	@printf "%-20s %s\n" "Tool" "Status"
	@printf "%-20s %s\n" "----" "------"
	@printf "%-20s %s\n" "shellcheck" "$$([ -n '$(SHELLCHECK)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "shfmt" "$$([ -n '$(SHFMT)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "markdownlint" "$$([ -n '$(MARKDOWNLINT)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "bats" "$$([ -n '$(BATS)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@printf "%-20s %s\n" "git" "$$([ -n '$(GIT)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@echo ""
	@echo -e "$(COLOR_YELLOW)Install missing tools:$(COLOR_RESET)"
	@echo "  macOS:  brew install shellcheck shfmt bats-core markdownlint-cli"
	@echo "  Linux:  apt-get install shellcheck shfmt bats"
	@echo "          npm install -g markdownlint-cli"

.PHONY: setup-dev
setup-dev: ## Setup development environment
	@echo -e "$(COLOR_BLUE)Setting up development environment...$(COLOR_RESET)"
	@if [ "$$(uname)" = "Darwin" ] && command -v brew >/dev/null; then \
		echo "Installing development tools via Homebrew..."; \
		brew install shellcheck shfmt bats-core 2>/dev/null || true; \
	else \
		echo -e "$(COLOR_YELLOW)Please install tools manually:$(COLOR_RESET)"; \
		echo "  - shellcheck: https://github.com/koalaman/shellcheck"; \
		echo "  - shfmt: https://github.com/mvdan/sh"; \
		echo "  - bats: https://github.com/bats-core/bats-core"; \
	fi
	@echo -e "$(COLOR_GREEN)✓ Development environment setup complete$(COLOR_RESET)"

# ==============================================================================
# CI/CD Helpers
# ==============================================================================

.PHONY: ci
ci: clean lint test docs build ## Run CI pipeline locally (includes docs)
	@echo -e "$(COLOR_GREEN)✓ CI pipeline completed successfully$(COLOR_RESET)"

.PHONY: pre-commit
pre-commit: format lint ## Run pre-commit checks
	@echo -e "$(COLOR_GREEN)✓ Pre-commit checks passed$(COLOR_RESET)"

.PHONY: pre-push
pre-push: check ## Run pre-push checks
	@echo -e "$(COLOR_GREEN)✓ Pre-push checks passed$(COLOR_RESET)"

# ==============================================================================
# Release Management
# ==============================================================================

.PHONY: release-check
release-check: ## Check if ready for release
	@echo -e "$(COLOR_BLUE)Checking release readiness...$(COLOR_RESET)"
	@echo ""
	@echo "Version: $(VERSION)"
	@echo ""
	@if [ -n "$(GIT)" ]; then \
		if [ -n "$$($(GIT) status --porcelain)" ]; then \
			echo -e "$(COLOR_RED)✗ Working directory not clean$(COLOR_RESET)"; \
			exit 1; \
		else \
			echo -e "$(COLOR_GREEN)✓ Working directory clean$(COLOR_RESET)"; \
		fi; \
		if $(GIT) tag | grep -q "v$(VERSION)"; then \
			echo -e "$(COLOR_RED)✗ Tag v$(VERSION) already exists$(COLOR_RESET)"; \
			exit 1; \
		else \
			echo -e "$(COLOR_GREEN)✓ Version tag available$(COLOR_RESET)"; \
		fi; \
	fi
	@$(MAKE) check
	@echo ""
	@echo -e "$(COLOR_GREEN)✓ Ready for release$(COLOR_RESET)"

.PHONY: release-prepare
release-prepare: release-check build ## Prepare release
	@echo -e "$(COLOR_BLUE)Preparing release v$(VERSION)...$(COLOR_RESET)"
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
	@echo -e "$(COLOR_BOLD)OraDBA Project Information$(COLOR_RESET)"
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
	@echo "  Docs:      $$(find $(DOC_DIR) -name "*.md" 2>/dev/null | wc -l | xargs)"

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
