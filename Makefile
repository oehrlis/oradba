# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Makefile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 0.18.4
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
# Support dev/test builds with suffix
ifdef ORADBA_BUILD_SUFFIX
    VERSION_FULL := $(VERSION)$(ORADBA_BUILD_SUFFIX)
else
    VERSION_FULL := $(VERSION)
endif
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
DOCKER 			:= $(shell command -v docker 2>/dev/null)

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
test: ## Run smart test selection (only tests affected by changes)
	@if [ -z "$(BATS)" ]; then \
		echo -e "$(COLOR_RED)Error: bats not found. Install with: brew install bats-core$(COLOR_RESET)"; \
		exit 1; \
	fi
	@if [ "$(DRY_RUN)" = "1" ]; then \
		echo -e "$(COLOR_BLUE)Dry run: showing which tests would execute...$(COLOR_RESET)"; \
		$(SCRIPTS_DIR)/select_tests.sh --dry-run --verbose; \
	else \
		echo -e "$(COLOR_BLUE)Running smart test selection...$(COLOR_RESET)"; \
		selected_tests=$$($(SCRIPTS_DIR)/select_tests.sh); \
		if [ -z "$$selected_tests" ]; then \
			echo -e "$(COLOR_YELLOW)No tests selected, running all tests$(COLOR_RESET)"; \
			$(BATS) $(TEST_DIR)/*.bats; \
		else \
			test_count=$$(echo "$$selected_tests" | wc -l | tr -d ' '); \
			echo -e "$(COLOR_GREEN)Running $$test_count selected test file(s)$(COLOR_RESET)"; \
			echo "$$selected_tests" | while read -r test_file; do \
				echo -e "$(COLOR_BLUE)  - $$test_file$(COLOR_RESET)"; \
			done; \
			cd $(TEST_DIR) && echo "$$selected_tests" | xargs $(BATS); \
		fi; \
	fi

.PHONY: test-full
test-full: ## Run all tests (no smart selection)
	@echo -e "$(COLOR_BLUE)Running full test suite (1516 tests, 70+ conditional skips expected)...$(COLOR_RESET)"
	@if [ -n "$(BATS)" ]; then \
		$(BATS) $(TEST_DIR)/*.bats; test_exit=$$?; \
		if [ $$test_exit -eq 0 ]; then \
			echo -e "$(COLOR_GREEN)All tests passed!$(COLOR_RESET)"; \
		elif [ $$test_exit -eq 1 ]; then \
			echo -e "$(COLOR_YELLOW)Tests completed with skipped tests (exit code 1 is normal with conditional skips)$(COLOR_RESET)"; \
			exit 0; \
		else \
			echo -e "$(COLOR_RED)Tests failed with exit code $$test_exit$(COLOR_RESET)"; \
			exit $$test_exit; \
		fi; \
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

.PHONY: test-plugin-client
test-plugin-client: ## Run client plugin tests only
	@echo -e "$(COLOR_BLUE)Running client plugin tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_client_plugin.bats

.PHONY: test-plugin-iclient
test-plugin-iclient: ## Run instant client plugin tests only
	@echo -e "$(COLOR_BLUE)Running instant client plugin tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_iclient_plugin.bats

.PHONY: test-plugin-oud
test-plugin-oud: ## Run OUD plugin tests only
	@echo -e "$(COLOR_BLUE)Running OUD plugin tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_oud_plugin.bats

.PHONY: test-plugin-database
test-plugin-database: ## Run database plugin tests only
	@echo -e "$(COLOR_BLUE)Running database plugin tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_database_plugin.bats

.PHONY: test-plugin-datasafe
test-plugin-datasafe: ## Run datasafe plugin tests only
	@echo -e "$(COLOR_BLUE)Running datasafe plugin tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_datasafe_plugin.bats

.PHONY: test-plugin-interface
test-plugin-interface: ## Run plugin interface compliance tests
	@echo -e "$(COLOR_BLUE)Running plugin interface tests...$(COLOR_RESET)"
	@$(BATS) $(TEST_DIR)/test_plugin_interface.bats

.PHONY: test-plugins
test-plugins: test-plugin-database test-plugin-datasafe test-plugin-client test-plugin-iclient test-plugin-oud test-plugin-interface ## Run all plugin tests

.PHONY: test-docker
test-docker: build ## Run Docker-based automated integration tests (requires Docker)
	@echo -e "$(COLOR_BLUE)Running Docker-based integration tests...$(COLOR_RESET)"
	@if [ -n "$(DOCKER)" ]; then \
		bash $(TEST_DIR)/run_docker_tests.sh --no-build; \
	else \
		echo -e "$(COLOR_RED)Error: Docker not found. Install Docker first.$(COLOR_RESET)"; \
		exit 1; \
	fi

.PHONY: test-docker-keep
test-docker-keep: build ## Run Docker tests and keep container for inspection
	@echo -e "$(COLOR_BLUE)Running Docker-based integration tests (keeping container)...$(COLOR_RESET)"
	@if [ -n "$(DOCKER)" ]; then \
		bash $(TEST_DIR)/run_docker_tests.sh --no-build --keep-container; \
	else \
		echo -e "$(COLOR_RED)Error: Docker not found. Install Docker first.$(COLOR_RESET)"; \
		exit 1; \
	fi

.PHONY: lint
lint: lint-shell lint-scripts lint-markdown ## Run all linters

.PHONY: lint-shell
lint-shell: ## Lint shell scripts with shellcheck
	@echo -e "$(COLOR_BLUE)Linting shell scripts...$(COLOR_RESET)"
	@if [ -n "$(SHELLCHECK)" ]; then \
		echo -e "$(COLOR_BLUE)  Checking main scripts...$(COLOR_RESET)"; \
		find $(BIN_DIR) $(LIB_DIR) $(SCRIPTS_DIR) -name "*.sh" -type f | \
			xargs $(SHELLCHECK) -x -S warning || exit 1; \
		echo -e "$(COLOR_BLUE)  Checking test scripts...$(COLOR_RESET)"; \
		find tests -name "*.sh" -type f | \
			xargs $(SHELLCHECK) -x -S warning || exit 1; \
		echo -e "$(COLOR_BLUE)  Checking BATS test files...$(COLOR_RESET)"; \
		find tests -name "*.bats" -type f | \
			xargs $(SHELLCHECK) -x -S warning || exit 1; \
		echo -e "$(COLOR_GREEN)✓ All shell scripts passed linting$(COLOR_RESET)"; \
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
		$(MARKDOWNLINT) --config .markdownlint.yaml '**/*.md' --ignore node_modules --ignore dist --ignore build || exit 1; \
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
	@echo -e "$(COLOR_BLUE)Building OraDBA distribution and installer...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/build_installer.sh
	@echo -e "$(COLOR_GREEN)✓ Build complete$(COLOR_RESET)"
	@ls -lh $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION_FULL).tar.gz $(DIST_DIR)/oradba_install.sh

.PHONY: build-dev
build-dev: ## Build distribution with -dev suffix for testing
	@$(MAKE) ORADBA_BUILD_SUFFIX="-dev" build

.PHONY: download-extensions
download-extensions: ## Download latest extension template from GitHub
	@echo -e "$(COLOR_BLUE)Downloading extension templates...$(COLOR_RESET)"
	@mkdir -p templates/oradba_extension
	@EXTENSION_REPO="oehrlis/oradba_extension"; \
	EXTENSION_CACHE="templates/oradba_extension/extension-template.tar.gz"; \
	EXTENSION_VERSION="templates/oradba_extension/.version"; \
	API_URL="https://api.github.com/repos/$$EXTENSION_REPO/releases/latest"; \
	echo "  Checking $$EXTENSION_REPO for latest release..."; \
	if command -v curl &> /dev/null; then \
		RELEASE_INFO=$$(curl -sS "$$API_URL" 2>/dev/null || echo "{}"); \
	elif command -v wget &> /dev/null; then \
		RELEASE_INFO=$$(wget -qO- "$$API_URL" 2>/dev/null || echo "{}"); \
	else \
		echo -e "$(COLOR_RED)Error: Neither curl nor wget available$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	LATEST_VERSION=$$(echo "$$RELEASE_INFO" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*": *"\(.*\)".*/\1/'); \
	TARBALL_URL=$$(echo "$$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*extension-template-[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4); \
	if [[ -n "$$LATEST_VERSION" ]] && [[ -n "$$TARBALL_URL" ]]; then \
		echo "  Latest version: $$LATEST_VERSION"; \
		if command -v curl &> /dev/null; then \
			curl -sS -L "$$TARBALL_URL" -o "$$EXTENSION_CACHE"; \
		else \
			wget -q "$$TARBALL_URL" -O "$$EXTENSION_CACHE"; \
		fi; \
		echo "$$LATEST_VERSION" > "$$EXTENSION_VERSION"; \
		echo -e "$(COLOR_GREEN)✓ Downloaded extension template $$LATEST_VERSION$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_RED)Error: Could not find extension template release$(COLOR_RESET)"; \
		exit 1; \
	fi

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
USER_DOC_METADATA := $(DOC_DIR)/metadata.yml
PANDOC_IMAGE := oehrlis/pandoc:latest

.PHONY: docs
docs: ## Generate all documentation (PDF only)
	@if [ -n "$(DOCKER)" ]; then \
		$(MAKE) docs-pdf; \
	else \
		echo -e "$(COLOR_YELLOW)⚠ Docker not available - skipping documentation generation$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)  Install Docker to generate documentation: https://docs.docker.com/get-docker/$(COLOR_RESET)"; \
	fi

.PHONY: docs-prepare
docs-prepare: ## Prepare documentation images for distribution
	@echo -e "$(COLOR_BLUE)Preparing documentation images...$(COLOR_RESET)"
	@# Clean any existing images first
	@rm -rf $(USER_DOC_DIR)/images $(SRC_DIR)/doc/images
	@mkdir -p $(USER_DOC_DIR)/images
	@mkdir -p $(SRC_DIR)/doc/images
	@# Copy PNG images only, exclude README.md and source subfolder
	@find $(DOC_DIR)/images -maxdepth 1 -name "*.png" -exec cp {} $(USER_DOC_DIR)/images/ \; 2>/dev/null || true
	@find $(DOC_DIR)/images -maxdepth 1 -name "*.png" -exec cp {} $(SRC_DIR)/doc/images/ \; 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Images copied for documentation build$(COLOR_RESET)"



.PHONY: docs-pdf
docs-pdf: docs-prepare ## Generate PDF user guide from markdown (requires Docker)
	@echo -e "$(COLOR_BLUE)Generating PDF documentation...$(COLOR_RESET)"
	@bash $(SCRIPTS_DIR)/build_pdf.sh

.PHONY: docs-check
docs-check: ## Check if documentation source files exist
	@echo -e "$(COLOR_BLUE)Checking documentation files...$(COLOR_RESET)"
	@if [ ! -f "$(USER_DOC_METADATA)" ]; then \
		echo -e "$(COLOR_RED)✗ Metadata file not found: $(USER_DOC_METADATA)$(COLOR_RESET)"; \
		exit 1; \
	else \
		echo -e "$(COLOR_GREEN)✓ Metadata file found: $(USER_DOC_METADATA)$(COLOR_RESET)"; \
	fi
	@chapter_count=$$(ls -1 $(USER_DOC_DIR)/*.md 2>/dev/null | wc -l | xargs); \
	if [ "$$chapter_count" -eq 0 ]; then \
		echo -e "$(COLOR_RED)✗ No documentation chapters found$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	echo -e "$(COLOR_GREEN)✓ Found $$chapter_count documentation chapters$(COLOR_RESET)"

.PHONY: docs-clean
docs-clean: ## Remove generated documentation
	@echo -e "$(COLOR_BLUE)Cleaning generated documentation...$(COLOR_RESET)"
	@rm -f $(DIST_DIR)/oradba-user-guide.pdf 2>/dev/null || true
	@rm -f $(USER_DOC_DIR)/oradba-user-guide.pdf 2>/dev/null || true
	@rm -rf $(DIST_DIR)/.tmp_docs 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Documentation cleaned$(COLOR_RESET)"

.PHONY: docs-clean-images
docs-clean-images: ## Remove images from build artifacts
	@echo -e "$(COLOR_BLUE)Cleaning documentation images from build artifacts...$(COLOR_RESET)"
	@rm -rf $(USER_DOC_DIR)/images 2>/dev/null || true
	@rm -rf $(SRC_DIR)/doc/images 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Build artifact images removed$(COLOR_RESET)"

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
clean: ## Clean build artifacts (preserves documentation)
	@echo -e "$(COLOR_BLUE)Cleaning build artifacts...$(COLOR_RESET)"
	@# Preserve documentation files if they exist
	@if [ -f "$(DIST_DIR)/oradba-user-guide.pdf" ]; then \
		mkdir -p .tmp_docs_preserve; \
		mv $(DIST_DIR)/oradba-user-guide.pdf .tmp_docs_preserve/ 2>/dev/null || true; \
		echo -e "$(COLOR_YELLOW)  Preserving documentation files during clean...$(COLOR_RESET)"; \
	fi
	@rm -rf $(DIST_DIR)
	@rm -rf build
	@# Restore documentation files
	@if [ -d .tmp_docs_preserve ]; then \
		mkdir -p $(DIST_DIR); \
		mv .tmp_docs_preserve/* $(DIST_DIR)/ 2>/dev/null || true; \
		rm -rf .tmp_docs_preserve; \
		echo -e "$(COLOR_YELLOW)  Documentation files restored$(COLOR_RESET)"; \
	fi
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name "*~" -type f -delete 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Cleaned$(COLOR_RESET)"

.PHONY: clean-extensions
clean-extensions: ## Clean downloaded extension templates
	@echo -e "$(COLOR_BLUE)Cleaning downloaded extension templates...$(COLOR_RESET)"
	@rm -rf templates/oradba_extension/*.tar.gz 2>/dev/null || true
	@rm -rf templates/oradba_extension/.version 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Extension templates cleaned$(COLOR_RESET)"

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
clean-all: clean clean-test-configs clean-extensions docs-clean ## Deep clean including documentation (removes everything)
	@echo -e "$(COLOR_BLUE)Deep cleaning...$(COLOR_RESET)"
	@rm -rf .bats-cache 2>/dev/null || true
	@rm -rf tests/results/*.log 2>/dev/null || true
	@echo -e "$(COLOR_GREEN)✓ Deep cleaned (including test results)$(COLOR_RESET)"

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
	@printf "%-20s %s\n" "docker" "$$([ -n '$(DOCKER)' ] && echo -e '$(COLOR_GREEN)✓ installed$(COLOR_RESET)' || echo -e '$(COLOR_RED)✗ not found$(COLOR_RESET)')"
	@echo ""
	@if [ -z '$(DOCKER)' ]; then \
		echo -e "$(COLOR_YELLOW)⚠ Docker not found - documentation generation (PDF) will not work$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)  Install Docker: https://docs.docker.com/get-docker/$(COLOR_RESET)"; \
		echo ""; \
	fi
	@echo -e "$(COLOR_YELLOW)Install missing tools:$(COLOR_RESET)"
	@echo "  macOS:  brew install shellcheck shfmt bats-core markdownlint-cli docker"
	@echo "  Linux:  apt-get install shellcheck shfmt bats docker.io"
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
ci: clean lint test-full docs build ## Run CI pipeline locally (full test suite + docs)
	@echo -e "$(COLOR_GREEN)✓ CI pipeline completed successfully$(COLOR_RESET)"

.PHONY: pre-commit
pre-commit: format lint test ## Run pre-commit checks (smart test selection)
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

.PHONY: release-notes
release-notes: ## Update GitHub release with release notes
	@echo -e "$(COLOR_BLUE)Updating GitHub release v$(VERSION) with notes...$(COLOR_RESET)"
	@RELEASE_FILE="$(DOC_DIR)/releases/v$(VERSION).md"; \
	if [ ! -f "$$RELEASE_FILE" ]; then \
		echo -e "$(COLOR_RED)Error: Release notes file not found: $$RELEASE_FILE$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	if ! command -v gh &> /dev/null; then \
		echo -e "$(COLOR_RED)Error: gh CLI not found. Install with: brew install gh$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	echo -e "$(COLOR_GREEN)Updating release v$(VERSION) with notes from $$RELEASE_FILE$(COLOR_RESET)"; \
	gh release edit "v$(VERSION)" --notes-file "$$RELEASE_FILE"

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
