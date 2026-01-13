#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: validate_project.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 0.18.3
# Purpose....: Validate project structure and required files
# Notes......: Checks for presence of all required files and directories.
#              Verifies permissions and file formats.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

PROJECT_ROOT="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
cd "$PROJECT_ROOT"

echo "========================================="
echo "Validating oradba Project Structure"
echo "========================================="
echo ""

ERRORS=0
WARNINGS=0

# Function to check file existence
check_file() {
    local file="$1"
    local required="${2:-true}"

    if [[ -f "$file" ]]; then
        echo "✓ Found: $file"
    else
        if [[ "$required" == "true" ]]; then
            echo "✗ Missing required file: $file"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠ Optional file not found: $file"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Function to check directory existence
check_dir() {
    local dir="$1"
    local required="${2:-true}"

    if [[ -d "$dir" ]]; then
        echo "✓ Found: $dir/"
    else
        if [[ "$required" == "true" ]]; then
            echo "✗ Missing required directory: $dir"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠ Optional directory not found: $dir"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Check core files
echo "Checking core files..."
check_file "README.md"
check_file "VERSION"
check_file "CHANGELOG.md"
check_file "LICENSE"
check_file "CONTRIBUTING.md"
check_file ".gitignore"

echo ""
echo "Checking documentation..."
check_dir "doc"
check_file "doc/development.md"
check_file "doc/architecture.md"
check_file "doc/api.md"
check_file "doc/structure.md"
check_file "doc/version-management.md"
check_file "doc/markdown-linting.md"
check_file "doc/README.md"
check_dir "doc/templates"
check_file "doc/templates/header.sh"
check_file "doc/templates/header.sql"
check_file "doc/templates/header.rman"
check_file "doc/templates/header.conf"

echo ""
echo "Checking source structure..."
check_dir "src"
check_dir "src/bin"
check_dir "src/lib"
check_dir "src/etc"
check_dir "src/sql"
check_dir "src/rcv"
check_dir "src/templates"

echo ""
echo "Checking core scripts..."
check_file "src/bin/oraenv.sh"
check_file "src/bin/oradba_install.sh"
check_file "src/bin/oradba_check.sh"
check_file "src/bin/oradba_version.sh"
check_file "src/bin/dbstatus.sh"
check_file "src/lib/common.sh"
check_file "src/lib/db_functions.sh"
check_file "src/lib/aliases.sh"
check_file "src/etc/oradba_core.conf"
check_file "src/etc/oradba_standard.conf"

echo ""
echo "Checking examples..."
check_file "src/sql/db_info.sql"
check_file "src/sql/login.sql"
check_file "src/rcv/backup_full.rman"
check_file "src/templates/script_template.sh"
check_file "src/templates/etc/oratab.example"
check_file "src/templates/etc/oradba_config.example"

echo ""
echo "Checking test structure..."
check_dir "tests"
check_file "tests/run_tests.sh"
check_file "tests/test_common.bats"
check_file "tests/test_oraenv.bats"
check_file "tests/test_db_functions.bats"
check_file "tests/test_installer.bats"
check_file "tests/test_oradba_check.bats"
check_file "tests/test_oradba_version.bats"
check_file "tests/test_aliases.bats"
check_file "tests/test_sid_config.bats"

echo ""
echo "Checking scripts directory..."
check_dir "scripts"
check_file "scripts/build_installer.sh"
check_file "scripts/validate_project.sh"

echo ""
echo "Checking src/doc directory..."
check_dir "src/doc"
check_file "src/doc/README.md"
check_file "src/doc/01-introduction.md"
check_file "src/doc/02-installation.md"
check_file "src/doc/03-quickstart.md"
check_file "src/doc/04-environment.md"
check_file "src/doc/05-configuration.md"
check_file "src/doc/06-aliases.md"
check_file "src/doc/08-sql-scripts.md"
check_file "src/doc/09-rman-scripts.md"
check_file "src/doc/12-troubleshooting.md"
check_file "src/doc/13-reference.md"

echo ""
echo "Checking GitHub issue templates..."
check_dir ".github/ISSUE_TEMPLATE"
check_file ".github/ISSUE_TEMPLATE/bug_report.yml"
check_file ".github/ISSUE_TEMPLATE/feature_request.yml"
check_file ".github/ISSUE_TEMPLATE/task.yml"
check_file ".github/ISSUE_TEMPLATE/config.yml"

echo ""
echo "Checking markdownlint configuration..."
check_file ".markdownlint.json"

echo ""
echo "Checking CI/CD configuration..."
check_dir ".github/workflows"
check_file ".github/workflows/ci.yml"
check_file ".github/workflows/release.yml"
check_file ".github/workflows/dependency-review.yml"

echo ""
echo "Checking file permissions..."
if [[ -x "scripts/build_installer.sh" ]]; then
    echo "✓ scripts/build_installer.sh is executable"
else
    echo "✗ scripts/build_installer.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "scripts/validate_project.sh" ]]; then
    echo "✓ scripts/validate_project.sh is executable"
else
    echo "✗ scripts/validate_project.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "src/bin/oraenv.sh" ]]; then
    echo "✓ src/bin/oraenv.sh is executable"
else
    echo "✗ src/bin/oraenv.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "tests/run_tests.sh" ]]; then
    echo "✓ tests/run_tests.sh is executable"
else
    echo "✗ tests/run_tests.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking version format..."
VERSION=$(cat VERSION)
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "✓ VERSION file contains valid semantic version: $VERSION"
else
    echo "✗ VERSION file does not contain valid semantic version: $VERSION"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    echo "✓ Project structure is valid!"
    exit 0
else
    echo "✗ Project structure has errors!"
    exit 1
fi
