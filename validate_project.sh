#!/usr/bin/env bash
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# validate_project.sh - Validate project structure and files
# -----------------------------------------------------------------------

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
check_file "build_installer.sh"

echo ""
echo "Checking documentation..."
check_dir "docs"
check_file "docs/DEVELOPMENT.md"
check_file "docs/QUICKSTART.md"

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
check_dir "test"
check_file "test/run_tests.sh"
check_file "test/test_common.bats"
check_file "test/test_oraenv.bats"
check_file "test/test_installer.bats"

echo ""
echo "Checking CI/CD configuration..."
check_dir ".github/workflows"
check_file ".github/workflows/ci.yml"
check_file ".github/workflows/release.yml"
check_file ".github/workflows/dependency-review.yml"

echo ""
echo "Checking file permissions..."
if [[ -x "build_installer.sh" ]]; then
    echo "✓ build_installer.sh is executable"
else
    echo "✗ build_installer.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "srv/bin/oraenv.sh" ]]; then
    echo "✓ srv/bin/oraenv.sh is executable"
else
    echo "✗ srv/bin/oraenv.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi

if [[ -x "test/run_tests.sh" ]]; then
    echo "✓ test/run_tests.sh is executable"
else
    echo "✗ test/run_tests.sh is not executable"
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
