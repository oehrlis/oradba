#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: validate_project.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
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
check_file "PROJECT_SUMMARY.md"

echo ""
echo "Checking documentation..."
check_dir "doc"
check_file "doc/DEVELOPMENT.md"
check_file "doc/QUICKSTART.md"
check_file "doc/ARCHITECTURE.md"
check_file "doc/API.md"
check_file "doc/README.md"
check_dir "doc/templates"
check_file "doc/templates/header.sh"
check_file "doc/templates/header.sql"
check_file "doc/templates/header.rman"
check_file "doc/templates/header.conf"

echo ""
echo "Checking source structure..."
check_dir "srv"
check_dir "srv/bin"
check_dir "srv/lib"
check_dir "srv/etc"
check_dir "srv/sql"
check_dir "srv/rcv"
check_dir "srv/templates"

echo ""
echo "Checking core scripts..."
check_file "srv/bin/oraenv.sh"
check_file "srv/lib/common.sh"
check_file "srv/etc/oradba.conf"

echo ""
echo "Checking examples..."
check_file "srv/sql/db_info.sql"
check_file "srv/sql/login.sql"
check_file "srv/rcv/backup_full.rman"
check_file "srv/templates/script_template.sh"
check_file "srv/etc/oratab.example"
check_file "srv/etc/oradba_config.example"

echo ""
echo "Checking test structure..."
check_dir "tests"
check_file "tests/run_tests.sh"
check_file "tests/test_common.bats"
check_file "tests/test_oraenv.bats"
check_file "tests/test_installer.bats"

echo ""
echo "Checking scripts directory..."
check_dir "scripts"
check_file "scripts/build_installer.sh"
check_file "scripts/validate_project.sh"
check_file "scripts/init_git.sh"

echo ""
echo "Checking srv/doc directory..."
check_dir "srv/doc"
check_file "srv/doc/README.md"
check_file "srv/doc/USAGE.md"
check_file "srv/doc/TROUBLESHOOTING.md"

echo ""
echo "Checking GitHub issue templates..."
check_dir ".github/ISSUE_TEMPLATE"
check_file ".github/ISSUE_TEMPLATE/bug_report.md"
check_file ".github/ISSUE_TEMPLATE/feature_request.md"
check_file ".github/ISSUE_TEMPLATE/task.md"
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

if [[ -x "scripts/init_git.sh" ]]; then
    echo "✓ scripts/init_git.sh is executable"
else
    echo "✗ scripts/init_git.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "srv/bin/oraenv.sh" ]]; then
    echo "✓ srv/bin/oraenv.sh is executable"
else
    echo "✗ srv/bin/oraenv.sh is not executable"
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
