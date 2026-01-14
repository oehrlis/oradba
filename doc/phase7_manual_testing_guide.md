# Phase 7: Pre-Release Testing - Manual Testing Guide

## Overview

This guide provides step-by-step instructions for manual testing of OraDBA
v1.0.0 before release. The automated test suite (533+ BATS tests) covers unit
and integration testing, but manual verification ensures real-world usability.

**Status**: Phase 7 of 9 - Pre-Release Testing  
**Automated Tests**: User will run separately (`make test-full`)  
**Manual Tests**: Follow this guide

## Prerequisites Verification

### 1. Version Check ✅

```bash
cd /Users/stefan.oehrli/Development/github/oehrlis/oradba
cat VERSION
# Expected: 1.0.0-dev
```

### 2. Test Infrastructure ✅

```bash
# Verify test files present
find tests -name "*.bats" -type f | wc -l
# Expected: 28 test files

# Verify .testmap.yml exists
ls -la .testmap.yml
# Expected: File present, 4-5KB

# Check Makefile test targets
make help | grep test
# Expected: test, test-full, test-unit, test-integration targets
```

### 3. Build System ✅

```bash
# Verify build scripts
ls -la scripts/build*.sh
# Expected: build_installer.sh, build_pdf.sh

# Check dist directory
ls -la dist/
# Expected: oradba-1.0.0-dev.tar.gz, oradba_install.sh, oradba_check.sh
```

## Automated Test Execution (User Action Required)

**User must run these commands manually:**

### Full Test Suite

```bash
# Run all 533+ tests
make test-full

# Expected results:
# - 528+ tests passed
# - 0 tests failed
# - 15 tests skipped (integration tests requiring Oracle environment)
# - 100% pass rate for non-skipped tests
```

### Code Quality Checks

```bash
# Run shellcheck linting
make lint-shell

# Expected: 0 errors, 0 warnings (Phase 4 validated this)

# Run markdown linting
make lint-markdown

# Expected: All markdown files pass
```

### Combined Checks

```bash
# Run all checks together
make check

# Expected: Tests pass + Lint passes
```

## Manual Testing Scenarios

### Scenario 1: Fresh Installation Test

**Purpose**: Verify clean installation works without Oracle environment

```bash
# 1. Build latest installer
make build

# 2. Verify build artifacts
ls -la dist/oradba-1.0.0-dev.tar.gz dist/oradba_install.sh
# Expected: Both files present, installer ~7-8MB

# 3. Test installer checksums (optional)
cd dist && sha256sum oradba_install.sh

# 4. Test installation to temporary location
mkdir -p /tmp/oradba-test
./dist/oradba_install.sh --prefix /tmp/oradba-test --yes

# 5. Verify installation
ls -la /tmp/oradba-test/
# Expected: bin/, lib/, etc/, sql/, rcv/, templates/, .install_info, VERSION

# 6. Check VERSION file
cat /tmp/oradba-test/VERSION
# Expected: 1.0.0-dev

# 7. Check .install_info
cat /tmp/oradba-test/.install_info
# Expected fields:
# - install_date=<timestamp>
# - install_version=1.0.0-dev
# - install_method=embedded
# - install_user=<your_user>
# - coexist_mode=standalone
# - basenv_detected=no

# 8. Verify core libraries present
ls -la /tmp/oradba-test/lib/oradba_env_*.sh
# Expected: 6 files (parser, builder, validator, config, status, changes)

# 9. Verify configuration files
ls -la /tmp/oradba-test/etc/oradba_{core,standard,services}.conf
# Expected: All 3 files present

# 10. Cleanup
rm -rf /tmp/oradba-test
```

**Acceptance Criteria**:

- ✅ Installation completes without errors
- ✅ All expected directories and files created
- ✅ VERSION matches 1.0.0-dev
- ✅ .install_info has correct values
- ✅ All 6 environment libraries present
- ✅ All 3 core config files present

### Scenario 2: Environment Loading Test

**Purpose**: Verify environment setup works (requires Oracle environment)

**Prerequisites**: ORACLE_HOME set or oratab entry exists

```bash
# 1. Source oraenv for existing SID
source /tmp/oradba-test/bin/oraenv.sh <YOUR_SID>

# 2. Verify environment variables
echo $ORACLE_SID
echo $ORACLE_HOME
echo $ORACLE_BASE
echo $ORADBA_BASE
# Note: ORADBA_CURRENT_HOME only set if Oracle Homes registered
echo $ORADBA_CURRENT_HOME  # May be empty if oradba_homes.conf not configured

# 3. Check library loading
echo $ORADBA_ENV_PARSER_LOADED
echo $ORADBA_ENV_BUILDER_LOADED
echo $ORADBA_ENV_VALIDATOR_LOADED
echo $ORADBA_ENV_CONFIG_LOADED
# Expected: All should be "yes"

# 4. Test alias availability
type sq taa cdh cda rmanc
# Expected: All aliases found

# 5. Test new v1.0.0 commands
oradba_env.sh validate
# Expected: Environment validation output

oradba_env.sh status
# Expected: Service status output (if Oracle running)

# 6. Test Oracle Homes management
oradba_homes.sh list
# Expected: List of registered Oracle Homes (or empty if none)
```

**Acceptance Criteria**:

- ✅ Environment sourced without errors
- ✅ ORACLE_SID, ORACLE_HOME, ORACLE_BASE set correctly
- ✅ All 4 environment libraries loaded
- ✅ Standard aliases available
- ✅ New v1.0.0 commands work

### Scenario 3: Configuration System Test

**Purpose**: Verify hierarchical configuration loading

```bash
# 1. Check core configuration loaded
grep -l "oradba_core.conf" /tmp/oradba-test/etc/
# Expected: File exists

# 2. Test configuration hierarchy
cat /tmp/oradba-test/etc/oradba_core.conf | head -20
# Expected: Core defaults with [DEFAULT] section

# 3. Test configuration validation
oradba_validate_config.sh /tmp/oradba-test/etc/oradba_core.conf
# Expected: Validation passes (if command exists)

# 4. Check product sections
grep "^\[RDBMS\]" /tmp/oradba-test/etc/oradba_standard.conf
grep "^\[CLIENT\]" /tmp/oradba-test/etc/oradba_standard.conf
# Expected: Both sections found
```

**Acceptance Criteria**:

- ✅ Core configuration loads without errors
- ✅ Product sections ([RDBMS], [CLIENT], etc.) present
- ✅ Configuration validation passes

### Scenario 4: Oracle Homes Management Test

**Purpose**: Verify Oracle Homes registry and management

```bash
# 1. Test Oracle Homes list
oradba_homes.sh list
# Expected: Formatted list or "No Oracle Homes registered"

# 2. Test export functionality (v1.0.0 feature)
oradba_homes.sh export > /tmp/homes_export.conf
cat /tmp/homes_export.conf
# Expected: Export header with metadata and any registered homes

# 3. Test import validation (v1.0.0 feature)
echo "# Test import" | oradba_homes.sh import --no-backup
# Expected: Format validation error (invalid format)

# 4. Cleanup
rm -f /tmp/homes_export.conf
```

**Acceptance Criteria**:

- ✅ List command works (with or without homes)
- ✅ Export produces valid output format
- ✅ Import validates input format

### Scenario 5: Documentation Verification

**Purpose**: Ensure all documentation is accurate and complete

```bash
# 1. Verify README.md updated
grep "v1.0.0" README.md
grep "Modular Library System" README.md
grep "533+" README.md
# Expected: All v1.0.0 references present

# 2. Check CHANGELOG.md
grep "## \[1.0.0\]" CHANGELOG.md
grep "Breaking Changes" CHANGELOG.md
# Expected: v1.0.0 entry present with breaking changes section

# 3. Verify developer documentation
ls -la doc/phase*_report.md
# Expected: phase4_code_quality_report.md, phase5_changelog_report.md, phase6_readme_report.md

# 4. Check doc links in README
grep -o '\[.*\](doc/.*\.md)' README.md | while read link; do
  file=$(echo "$link" | sed 's/.*(\(.*\))/\1/')
  [ -f "$file" ] && echo "✓ $file" || echo "✗ $file MISSING"
done
# Expected: All links valid
```

**Acceptance Criteria**:

- ✅ README.md reflects v1.0.0 features
- ✅ CHANGELOG.md has complete v1.0.0 entry
- ✅ All phase reports present
- ✅ All documentation links valid

### Scenario 6: Code Quality Verification

**Purpose**: Confirm Phase 4 code quality standards maintained

```bash
# 1. Verify no shellcheck errors
shellcheck src/bin/*.sh src/lib/*.sh 2>&1 | grep -c "error:"
# Expected: 0

# 2. Count shellcheck warnings
shellcheck src/bin/*.sh src/lib/*.sh 2>&1 | grep -c "warning:"
# Expected: 0

# 3. Check function headers
grep -l "^# Purpose:" src/lib/*.sh | wc -l
# Expected: 10 (all library files have headers)

# 4. Verify naming conventions
grep -h "^oradba_[a-z_]*() {" src/lib/*.sh | wc -l
# Expected: 48+ (public functions with oradba_ prefix)
```

**Acceptance Criteria**:

- ✅ 0 shellcheck errors
- ✅ 0 shellcheck warnings  
- ✅ All libraries have function headers
- ✅ Consistent naming conventions

## Build & Distribution Verification

### Build Process

```bash
# 1. Clean previous builds
make clean

# 2. Build complete distribution
make build

# 3. Verify artifacts created
ls -lh dist/oradba-1.0.0-dev.tar.gz
ls -lh dist/oradba_install.sh
ls -lh dist/oradba_check.sh

# Expected sizes:
# - tarball: ~5-6MB
# - installer: ~7-8MB (embedded tarball + script)
# - check script: ~20-30KB

# 4. Test tarball extraction
cd /tmp
tar -tzf /path/to/dist/oradba-1.0.0-dev.tar.gz | head -20
# Expected: List of files with oradba-1.0.0-dev/ prefix

# 5. Verify installer integrity
head -20 dist/oradba_install.sh
# Expected: Proper shebang, header, version info

# 6. Test check script standalone
./dist/oradba_check.sh --version
# Expected: Version output
```

**Acceptance Criteria**:

- ✅ Build completes without errors
- ✅ All 3 artifacts created with reasonable sizes
- ✅ Tarball contains all expected files
- ✅ Installer has proper structure
- ✅ Check script is standalone and works

## Test Results Summary

After completing all manual tests, document results:

```bash
# Create test results file
cat > doc/phase7_test_results.md << 'RESULTS'
# Phase 7: Pre-Release Testing Results

**Date**: $(date)
**Tester**: <your_name>
**Platform**: $(uname -s) $(uname -r)

## Automated Tests
- [ ] `make test-full` passed (528+/528 tests)
- [ ] `make lint-shell` passed (0 errors, 0 warnings)
- [ ] `make lint-markdown` passed
- [ ] `make check` passed

## Manual Test Scenarios
- [ ] Scenario 1: Fresh Installation (PASS/FAIL)
- [ ] Scenario 2: Environment Loading (PASS/FAIL)
- [ ] Scenario 3: Configuration System (PASS/FAIL)
- [ ] Scenario 4: Oracle Homes Management (PASS/FAIL)
- [ ] Scenario 5: Documentation Verification (PASS/FAIL)
- [ ] Scenario 6: Code Quality Verification (PASS/FAIL)

## Build & Distribution
- [ ] Build process (PASS/FAIL)
- [ ] Artifacts created (PASS/FAIL)
- [ ] Installer integrity (PASS/FAIL)

## Issues Found
<List any issues discovered>

## Recommendation
- [ ] APPROVED for Phase 8 (Version & Release Prep)
- [ ] HOLD - Issues must be resolved first

**Notes**:
<Additional comments>
RESULTS
```

## Next Steps After Testing

If all tests pass:

1. ✅ Mark Phase 7 complete
2. ✅ Document any minor issues for future releases
3. ✅ Proceed to Phase 8: Version & Release Prep
   - Update VERSION to 1.0.0 (remove -dev)
   - Final CHANGELOG review
   - Create release notes
   - Tag preparation

If tests fail:

1. ❌ Document failures in detail
2. ❌ Fix critical issues
3. ❌ Re-run affected tests
4. ❌ Update documentation if needed
5. ❌ Restart Phase 7 after fixes

## Quick Reference Commands

```bash
# Run full test suite
make test-full

# Build distribution
make clean && make build

# Install to test location
./dist/oradba_install.sh --prefix /tmp/oradba-test --yes

# Test environment loading
source /tmp/oradba-test/bin/oraenv.sh <SID>

# Verify v1.0.0 features
oradba_env.sh status
oradba_env.sh validate
oradba_homes.sh export

# Cleanup test installation
rm -rf /tmp/oradba-test
```

## Expected Timeline

- Automated tests: 15-20 minutes (user runs `make test-full`)
- Manual testing: 30-45 minutes (follow scenarios)
- Build verification: 10-15 minutes
- Documentation: 10 minutes
- **Total**: ~1.5-2 hours

## Success Criteria

Phase 7 is complete when:

- ✅ All automated tests pass (528+/528)
- ✅ All 6 manual scenarios pass
- ✅ Build produces valid artifacts
- ✅ Documentation is complete and accurate
- ✅ No critical issues found
- ✅ Test results documented

---

**Phase 7 Status**: Ready for user execution  
**Next Phase**: Phase 8 - Version & Release Prep (after successful testing)
