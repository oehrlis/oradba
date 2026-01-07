SHELL := /usr/bin/env bash

EXT_DIR ?= extension-template
DIST ?= dist
VERSION := $(shell cat VERSION)

.PHONY: lint lint-sh lint-md test build clean

lint: lint-sh lint-md

lint-sh:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found"; exit 1; }
	find scripts $(EXT_DIR) -name "*.sh" -print0 | xargs -0 shellcheck -e SC1091

lint-md:
	@command -v markdownlint >/dev/null 2>&1 || { echo "markdownlint not found"; exit 1; }
	markdownlint "**/*.md" --ignore node_modules --ignore dist --ignore build

test:
	@command -v bats >/dev/null 2>&1 || { echo "bats not found"; exit 1; }
	bats tests

build:
	./scripts/build.sh --dist "$(DIST)" --extension "$(EXT_DIR)"

clean:
	rm -rf "$(DIST)"
