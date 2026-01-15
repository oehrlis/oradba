#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: validate_project.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.15
# Revision...: 1.0.0
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
check_file "doc/extension-system.md"
check_file "doc/automated_testing.md"
check_file "doc/manual_testing.md"
check_file "doc/README.md"
check_dir "doc/templates"
check_file "doc/templates/header.sh"
check_file "doc/templates/header.sql"
check_file "doc/templates/header.rman"
check_file "doc/templates/header.conf"
check_dir "doc/archive"

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
echo "Counting source files..."
SQL_COUNT=$(find src/sql -name "*.sql" -type f 2>/dev/null | wc -l | tr -d ' ')
RCV_COUNT=$(find src/rcv -name "*.rcv" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "✓ Found $SQL_COUNT SQL scripts in src/sql/"
echo "✓ Found $RCV_COUNT RMAN scripts in src/rcv/"

echo ""
echo "Checking core scripts..."
check_file "src/bin/oraenv.sh"
check_file "src/bin/oradba_install.sh"
check_file "src/bin/oradba_check.sh"
check_file "src/bin/oradba_version.sh"
check_file "src/bin/oradba_validate.sh"
check_file "src/bin/oradba_setup.sh"
check_file "src/bin/oradba_homes.sh"
check_file "src/bin/oradba_extension.sh"
check_file "src/bin/oradba_dbctl.sh"
check_file "src/bin/oradba_lsnrctl.sh"
check_file "src/bin/oradba_services.sh"
check_file "src/bin/oradba_services_root.sh"
check_file "src/bin/oradba_rman.sh"
check_file "src/bin/oradba_sqlnet.sh"
check_file "src/bin/oradba_help.sh"
check_file "src/bin/dbstatus.sh"
check_file "src/bin/oraup.sh"
check_file "src/bin/sync_to_peers.sh"
check_file "src/bin/sync_from_peers.sh"

echo ""
echo "Checking core libraries..."
check_file "src/lib/oradba_common.sh"
check_file "src/lib/oradba_db_functions.sh"
check_file "src/lib/oradba_aliases.sh"
check_file "src/lib/extensions.sh"

echo ""
echo "Checking environment management libraries..."
check_file "src/lib/oradba_env_parser.sh"
check_file "src/lib/oradba_env_builder.sh"
check_file "src/lib/oradba_env_validator.sh"
check_file "src/lib/oradba_env_config.sh"
check_file "src/lib/oradba_env_status.sh"
check_file "src/lib/oradba_env_changes.sh"

echo ""
echo "Checking configuration files..."
check_file "src/etc/oradba_core.conf"
check_file "src/etc/oradba_standard.conf"
check_file "src/etc/sid._DEFAULT_.conf"
check_file "src/templates/etc/oradba_homes.conf.template"

echo ""
echo "Checking template examples..."
check_file "src/templates/script_template.sh"
check_file "src/templates/etc/oratab.example"
check_file "src/templates/etc/oradba_config.example"
check_file "src/templates/etc/oradba_customer.conf.example"
check_file "src/templates/etc/sid.ORACLE_SID.conf.example"
check_file "src/templates/etc/oradba_rman.conf.example"

echo ""
echo "Checking test structure..."
check_dir "tests"
check_file "tests/run_tests.sh"
check_file "tests/test_oradba_common.bats"
check_file "tests/test_oradba_db_functions.bats"
check_file "tests/test_oradba_aliases.bats"
check_file "tests/test_extensions.bats"
check_file "tests/test_execute_db_query.bats"
check_file "tests/test_logging.bats"
check_file "tests/test_logging_infrastructure.bats"
check_file "tests/test_oradba_env_parser.bats"
check_file "tests/test_oradba_env_config.bats"
check_file "tests/test_oradba_env_status.bats"
check_file "tests/test_oradba_env_changes.bats"
check_file "tests/test_oraenv.bats"
check_file "tests/test_oraup.bats"
check_file "tests/test_installer.bats"
check_file "tests/test_oradba_check.bats"
check_file "tests/test_oradba_version.bats"
check_file "tests/test_oradba_help.bats"
check_file "tests/test_oradba_homes.bats"
check_file "tests/test_oracle_homes.bats"
check_file "tests/test_oratab_priority.bats"
check_file "tests/test_sid_config.bats"
check_file "tests/test_oradba_rman.bats"
check_file "tests/test_oradba_sqlnet.bats"
check_file "tests/test_service_management.bats"
check_file "tests/test_longops.bats"
check_file "tests/test_get_seps_pwd.bats"
check_file "tests/test_job_wrappers.bats"
check_file "tests/test_sync_scripts.bats"

echo ""
echo "Checking scripts directory..."
check_dir "scripts"
check_file "scripts/build_installer.sh"
check_file "scripts/validate_project.sh"
check_file "scripts/select_tests.sh"
check_file "scripts/build_pdf.sh"
check_file "scripts/archive_github_releases.sh"

echo ""
echo "Checking src/doc directory..."
check_dir "src/doc"
check_file "src/doc/index.md"
check_file "src/doc/introduction.md"
check_file "src/doc/installation.md"
check_file "src/doc/quickstart.md"
check_file "src/doc/environment.md"
check_file "src/doc/configuration.md"
check_file "src/doc/aliases.md"
check_file "src/doc/sql-scripts.md"
check_file "src/doc/rman-scripts.md"
check_file "src/doc/troubleshooting.md"
check_file "src/doc/reference.md"
check_file "src/doc/extensions.md"
check_file "src/doc/service-management.md"
check_file "src/doc/sqlnet-config.md"
check_dir "src/doc/images"

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
echo "Checking additional configuration files..."
check_file "mkdocs.yml"
check_file "Makefile"
check_file "oradba.code-workspace" "false"

echo ""
echo "Checking CI/CD configuration..."
check_dir ".github/workflows"
check_file ".github/workflows/ci.yml"
check_file ".github/workflows/release.yml"
check_file ".github/workflows/dependency-review.yml"
check_file ".github/workflows/docs.yml"

echo ""
echo "Checking file permissions..."
for script in scripts/build_installer.sh scripts/validate_project.sh scripts/select_tests.sh scripts/build_pdf.sh scripts/archive_github_releases.sh; do
    if [[ -x "$script" ]]; then
        echo "✓ $script is executable"
    else
        echo "✗ $script is not executable"
        ERRORS=$((ERRORS + 1))
    fi
done

for script in src/bin/*.sh; do
    if [[ -x "$script" ]]; then
        echo "✓ $script is executable"
    else
        echo "✗ $script is not executable"
        ERRORS=$((ERRORS + 1))
    fi
done

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
