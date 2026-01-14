# OraDBA Manual Testing Guide

## Overview

This document provides comprehensive manual testing procedures for OraDBA across three key areas:

- **Installation**: Fresh installation and upgrade scenarios
- **Configuration**: Environment setup and customization
- **Daily Use**: Common DBA workflows and operations

Use this guide for release testing, regression testing, or verification after modifications.

---

## 1. Installation Testing

### 1.1 Fresh Installation (Standalone)

**Objective**: Verify clean installation without existing Oracle environment

```bash
# 1. Download/build installer
cd /path/to/oradba
make clean && make build

# 2. Verify build artifacts
ls -lh dist/oradba-*.tar.gz dist/oradba_install.sh

# 3. Install to test location
TEST_PREFIX="/tmp/oradba-test-$(date +%s)"
mkdir -p "$TEST_PREFIX"
./dist/oradba_install.sh --prefix "$TEST_PREFIX" --yes

# 4. Verify installation structure
ls -la "$TEST_PREFIX/"
# Expected: bin/, lib/, etc/, sql/, rcv/, templates/, .install_info, VERSION

# 5. Verify VERSION file
cat "$TEST_PREFIX/VERSION"

# 6. Verify .install_info metadata
cat "$TEST_PREFIX/.install_info"
# Expected fields:
#   install_date=<timestamp>
#   install_version=<version>
#   install_method=embedded|tarball
#   install_user=<username>
#   coexist_mode=standalone|coexist
#   basenv_detected=yes|no

# 7. Verify core libraries
ls -1 "$TEST_PREFIX/lib/oradba_env_"*.sh
# Expected:
#   oradba_env_builder.sh
#   oradba_env_changes.sh
#   oradba_env_config.sh
#   oradba_env_parser.sh
#   oradba_env_status.sh
#   oradba_env_validator.sh

# 8. Verify configuration files
ls -1 "$TEST_PREFIX/etc/oradba_"*.conf
# Expected:
#   oradba_core.conf
#   oradba_standard.conf
#   oradba_services.conf

# 9. Verify templates exist
ls -1 "$TEST_PREFIX/templates/etc/"
# Expected various .template files

# 10. Cleanup
rm -rf "$TEST_PREFIX"
```

**Pass Criteria**:

- ✅ All expected directories created
- ✅ VERSION file matches build version
- ✅ .install_info has correct metadata
- ✅ All 6 environment libraries present
- ✅ All 3 core config files present
- ✅ Templates directory populated

### 1.2 Fresh Installation (With Oracle Environment)

**Objective**: Verify installation in active Oracle environment

**Prerequisites**: Oracle Database or Grid Infrastructure installed

```bash
# 1. Set Oracle environment
export ORACLE_SID=<your_sid>
export ORACLE_HOME=<your_oracle_home>

# 2. Install OraDBA
INSTALL_PREFIX="/opt/oracle/local/oradba"  # or your preferred location
sudo mkdir -p "$INSTALL_PREFIX"
sudo chown $(whoami):$(id -gn) "$INSTALL_PREFIX"
./dist/oradba_install.sh --prefix "$INSTALL_PREFIX" --yes

# 3. Verify Oracle environment detection
cat "$INSTALL_PREFIX/.install_info"
# Check: basenv_detected should indicate detection if basenv.ksh found

# 4. Source environment
source "$INSTALL_PREFIX/bin/oraenv.sh" "$ORACLE_SID"

# 5. Verify environment variables set
echo "ORACLE_SID: $ORACLE_SID"
echo "ORACLE_HOME: $ORACLE_HOME"
echo "ORACLE_BASE: $ORACLE_BASE"
echo "ORADBA_BASE: $ORADBA_BASE"

# 6. Verify library loading
env | grep ORADBA_ENV_.*_LOADED
# Expected: All 6 libraries should show "yes"

# 7. Test command availability
type oradba_env.sh oradba_homes.sh oradba_validate.sh
# Expected: All commands found
```

**Pass Criteria**:

- ✅ Installation completes without errors
- ✅ Oracle environment correctly detected
- ✅ Environment sourcing works
- ✅ All libraries load successfully
- ✅ Commands accessible in PATH

### 1.3 Upgrade Installation

**Objective**: Verify upgrade preserves user customizations

```bash
# 1. Setup existing installation
OLD_VERSION="1.0.0"  # Example
NEW_VERSION="1.0.1"  # Example

# 2. Create custom configuration
cat > "$INSTALL_PREFIX/etc/oradba_custom.conf" << 'EOF'
# Custom settings
[RDBMS]
CUSTOM_SETTING=value
EOF

# 3. Backup before upgrade
cp "$INSTALL_PREFIX/.install_info" /tmp/install_info.backup

# 4. Perform upgrade
./dist/oradba_install.sh --prefix "$INSTALL_PREFIX" --yes

# 5. Verify custom config preserved
diff "$INSTALL_PREFIX/etc/oradba_custom.conf" <(cat << 'EOF'
# Custom settings
[RDBMS]
CUSTOM_SETTING=value
EOF
)
# Expected: No differences

# 6. Verify version updated
grep "install_version" "$INSTALL_PREFIX/.install_info"
# Expected: New version

# 7. Verify libraries updated
head -n 10 "$INSTALL_PREFIX/lib/oradba_env_parser.sh"
# Check version comment matches new version
```

**Pass Criteria**:

- ✅ Upgrade completes without errors
- ✅ Custom configurations preserved
- ✅ VERSION file updated
- ✅ Libraries updated to new version
- ✅ Core configs not overwritten

---

## 2. Configuration Testing

### 2.1 Environment Loading

**Objective**: Verify environment setup works correctly

```bash
# 1. Test sourcing with SID (case variations)
source "$ORADBA_BASE/bin/oraenv.sh" <SID>
source "$ORADBA_BASE/bin/oraenv.sh" <sid>  # lowercase
source "$ORADBA_BASE/bin/oraenv.sh" <Sid>  # mixed case
# Expected: All variations should work (case-insensitive)

# 2. Verify ORACLE variables set correctly
echo "ORACLE_SID: $ORACLE_SID"
echo "ORACLE_HOME: $ORACLE_HOME"
echo "ORACLE_BASE: $ORACLE_BASE"
# Expected: All set to correct values from oratab

# 3. Verify TNS_ADMIN set
echo "TNS_ADMIN: $TNS_ADMIN"
# Expected: $ORACLE_HOME/network/admin or custom location

# 4. Verify PATH updated
echo "$PATH" | tr ':' '\n' | grep -E "oracle|oradba"
# Expected: ORACLE_HOME/bin and ORADBA_BASE/bin in PATH

# 5. Test alias availability
type sq taa cdh cda cdb rmanc
# Expected: All aliases found

# 6. Test function availability
type oradba_validate_oracle_home oradba_build_environment
# Expected: Functions exported and available
```

**Pass Criteria**:

- ✅ SID lookup is case-insensitive
- ✅ ORACLE_* variables set correctly
- ✅ PATH includes Oracle and OraDBA bins
- ✅ Standard aliases available
- ✅ Library functions accessible

### 2.2 Configuration Hierarchy

**Objective**: Verify configuration loading precedence

```bash
# 1. Check core configuration loads
cat "$ORADBA_BASE/etc/oradba_core.conf" | head -20
# Expected: [DEFAULT] section with core defaults

# 2. Test product-specific sections
grep "^\[RDBMS\]" "$ORADBA_BASE/etc/oradba_standard.conf"
grep "^\[CLIENT\]" "$ORADBA_BASE/etc/oradba_standard.conf"
grep "^\[GRID\]" "$ORADBA_BASE/etc/oradba_standard.conf"
# Expected: All sections present

# 3. Create custom configuration
cat > "$ORADBA_BASE/etc/oradba_custom.conf" << 'EOF'
[RDBMS]
# Override default setting
ORACLE_ARCH=custom_value
EOF

# 4. Re-source environment
source "$ORADBA_BASE/bin/oraenv.sh" "$ORACLE_SID"

# 5. Verify custom setting loads
# (Would need to check specific variable if config system exposes it)

# 6. Test user-level override
mkdir -p ~/.oradba/etc
cat > ~/.oradba/etc/oradba_custom.conf << 'EOF'
[RDBMS]
USER_SETTING=user_value
EOF

# 7. Re-source and verify user config loads
source "$ORADBA_BASE/bin/oraenv.sh" "$ORACLE_SID"
```

**Pass Criteria**:

- ✅ Core configuration loads without errors
- ✅ Product sections recognized
- ✅ Custom configurations load
- ✅ Configuration hierarchy respected (system → user)

### 2.3 Oracle Homes Management

**Objective**: Verify Oracle Homes registry functionality

```bash
# 1. List current homes (may be empty)
oradba_homes.sh list

# 2. Add Oracle Home
oradba_homes.sh add "$ORACLE_HOME" RDBMS "free" \
  --version "23.0.0.0" \
  --edition "FREE" \
  --description "Oracle Database 23ai Free"

# 3. Verify home registered
oradba_homes.sh list | grep "$ORACLE_HOME"
# Expected: Home listed with metadata

# 4. Test export functionality
oradba_homes.sh export > /tmp/homes_export.conf

# 5. Verify export format
head -10 /tmp/homes_export.conf
# Expected: Header with metadata, then home entries

# 6. Test home metadata retrieval
oradba_homes.sh show "$ORACLE_HOME"
# Expected: Detailed information about the home

# 7. Update home metadata
oradba_homes.sh update "$ORACLE_HOME" --description "Updated description"

# 8. Verify update
oradba_homes.sh show "$ORACLE_HOME" | grep "Updated description"

# 9. Test import validation
echo "# Invalid format" | oradba_homes.sh import --no-backup
# Expected: Format validation error

# 10. Cleanup
rm -f /tmp/homes_export.conf
```

**Pass Criteria**:

- ✅ List command works (empty or populated)
- ✅ Add command registers home correctly
- ✅ Export produces valid format
- ✅ Show displays home metadata
- ✅ Update modifies metadata
- ✅ Import validates format

---

## 3. Daily Use Testing

### 3.1 Environment Switching

**Objective**: Verify switching between different environments

```bash
# Prerequisites: Multiple SIDs in oratab or registered homes

# 1. Source first environment
source "$ORADBA_BASE/bin/oraenv.sh" <SID1>
echo "Current SID: $ORACLE_SID"
echo "Current HOME: $ORACLE_HOME"

# 2. Switch to second environment
source "$ORADBA_BASE/bin/oraenv.sh" <SID2>
echo "Current SID: $ORACLE_SID"
echo "Current HOME: $ORACLE_HOME"

# 3. Verify environment changed
# Expected: ORACLE_SID and ORACLE_HOME reflect new environment

# 4. Test alias works in new environment
sq
# Expected: SQL*Plus starts with new SID

# 5. Switch back
source "$ORADBA_BASE/bin/oraenv.sh" <SID1>

# 6. Verify switched back correctly
echo "Current SID: $ORACLE_SID"
```

**Pass Criteria**:

- ✅ Environment switches successfully
- ✅ ORACLE_* variables update correctly
- ✅ Aliases work in new environment
- ✅ Can switch back without issues

### 3.2 Environment Information Commands

**Objective**: Verify information display commands

```bash
# 1. Test list command (all environments)
oradba_env.sh list

# 2. Test list sids (from oratab)
oradba_env.sh list sids

# 3. Test list homes (from oradba_homes.conf)
oradba_env.sh list homes

# 4. Show information about current SID
oradba_env.sh show "$ORACLE_SID"
# Expected: SID details including home, product type, status

# 5. Show information about Oracle Home
oradba_env.sh show "$ORACLE_HOME"
# Expected: Home details including product, version, edition

# 6. Test validate command
oradba_env.sh validate
# Expected: Environment validation output with pass/fail for each check

# 7. Test status command
oradba_env.sh status
# Expected: Database/service status (OPEN, DOWN, etc.)

# 8. Test status with specific SID
oradba_env.sh status <OTHER_SID>
# Expected: Status for specified SID

# 9. Test with case variations
oradba_env.sh status <sid_lowercase>
# Expected: Works (case-insensitive)
```

**Pass Criteria**:

- ✅ List commands display available environments
- ✅ Show command displays detailed information
- ✅ Validate command checks environment
- ✅ Status command shows database state
- ✅ Commands work with case-insensitive SID

### 3.3 Environment Validation

**Objective**: Verify environment validation checks

```bash
# 1. Run full validation
oradba_env.sh validate

# 2. Check validation output includes:
#    - ORACLE_HOME existence
#    - ORACLE_HOME validity
#    - Required binaries (sqlplus, etc.)
#    - TNS_ADMIN directory
#    - Listener configuration
#    - Product type detection
#    - Version detection

# 3. Test validation with invalid HOME
export ORACLE_HOME="/invalid/path"
oradba_env.sh validate
# Expected: Validation failures reported

# 4. Restore valid environment
source "$ORADBA_BASE/bin/oraenv.sh" "$ORACLE_SID"

# 5. Run standalone validation script
"$ORADBA_BASE/bin/oradba_validate.sh"
# Expected: Installation validation output
```

**Pass Criteria**:

- ✅ Validation checks all critical components
- ✅ Reports success for valid environment
- ✅ Reports failures for invalid environment
- ✅ Provides actionable error messages

### 3.4 Database Status Checking

**Objective**: Verify database status detection

**Prerequisites**: Oracle Database running

```bash
# 1. Check status of current database
oradba_env.sh status
# Expected: Shows database status (OPEN, MOUNTED, etc.)

# 2. Verify status includes:
#    - SID
#    - ORACLE_HOME
#    - Product Type (RDBMS/GRID)
#    - Database Status (OPEN/MOUNTED/DOWN)
#    - Listener Status (RUNNING/DOWN)

# 3. Test status for different product types
# If Grid Infrastructure available:
oradba_env.sh status +ASM
# Expected: Shows Grid/ASM status

# 4. Test status when database is down
# (Optional - if safe to stop database)
# Expected: Status shows DOWN state

# 5. Test status for listener
# Expected: Shows listener state
```

**Pass Criteria**:

- ✅ Status command runs without errors
- ✅ Correctly identifies product type (RDBMS vs GRID)
- ✅ Shows accurate database state
- ✅ Shows listener status
- ✅ Handles different database states

### 3.5 Common DBA Aliases

**Objective**: Verify standard aliases work correctly

```bash
# 1. Test SQL*Plus shortcut
sq
# Execute: SELECT banner FROM v$version;
# Exit SQL*Plus
# Expected: Connects to database, executes query

# 2. Test directory shortcuts
cdh   # Go to ORACLE_HOME
pwd
# Expected: In ORACLE_HOME

cda   # Go to admin directory
pwd
# Expected: In $ORACLE_BASE/admin or similar

cdb   # Go to ORACLE_BASE
pwd
# Expected: In ORACLE_BASE

# 3. Test alert log access
taa   # Tail alert log
# Expected: Shows recent alert log entries (if database running)

# 4. Test RMAN shortcut
rmanc
# Execute: SHOW ALL;
# Exit RMAN
# Expected: Connects to RMAN, shows configuration

# 5. Test listener control (if available)
type lsnrctl
lsnrctl status
# Expected: Shows listener status
```

**Pass Criteria**:

- ✅ sq alias starts SQL*Plus correctly
- ✅ Directory aliases navigate to correct locations
- ✅ taa shows alert log
- ✅ rmanc starts RMAN
- ✅ Listener commands work if available

### 3.6 Multi-User Environment

**Objective**: Verify OraDBA works with multiple users

**Prerequisites**: Multiple OS users with Oracle access

```bash
# As User 1
su - user1
source /opt/oracle/local/oradba/bin/oraenv.sh <SID>
oradba_env.sh validate
# Expected: Works correctly

# As User 2
su - user2
source /opt/oracle/local/oradba/bin/oraenv.sh <SID>
oradba_env.sh validate
# Expected: Works correctly

# Verify user-specific configurations
# User 1 creates custom config
mkdir -p ~/.oradba/etc
cat > ~/.oradba/etc/oradba_custom.conf << 'EOF'
[RDBMS]
USER1_SETTING=value1
EOF

# User 2 creates different config
mkdir -p ~/.oradba/etc
cat > ~/.oradba/etc/oradba_custom.conf << 'EOF'
[RDBMS]
USER2_SETTING=value2
EOF

# Re-source and verify isolation
# Expected: Each user has independent configuration
```

**Pass Criteria**:

- ✅ Multiple users can use OraDBA simultaneously
- ✅ User-specific configurations work
- ✅ No permission conflicts
- ✅ Each user has isolated environment

---

## 4. Edge Cases & Error Handling

### 4.1 Missing Oracle Environment

**Objective**: Verify graceful handling when Oracle not available

```bash
# 1. Unset Oracle environment
unset ORACLE_SID ORACLE_HOME ORACLE_BASE

# 2. Attempt to source environment with invalid SID
source "$ORADBA_BASE/bin/oraenv.sh" NONEXISTENT
# Expected: Error message, no crash

# 3. Test commands without environment
oradba_env.sh validate
# Expected: Reports missing environment, doesn't crash

# 4. Test with corrupted oratab
# (Backup first!)
cp /etc/oratab /etc/oratab.backup
echo "INVALID:ENTRY" >> /etc/oratab
oradba_env.sh list sids
# Expected: Handles invalid entries gracefully
```

**Pass Criteria**:

- ✅ Clear error messages for missing environments
- ✅ No crashes or undefined behavior
- ✅ Handles corrupted configuration files
- ✅ Provides actionable guidance

### 4.2 Permission Issues

**Objective**: Verify behavior with insufficient permissions

```bash
# 1. Test with read-only oratab (if possible)
# Expected: Can read, warns if cannot write

# 2. Test with inaccessible ORACLE_HOME
chmod 000 "$ORACLE_HOME"  # If safe to do
oradba_env.sh validate
# Expected: Reports permission issue
chmod 755 "$ORACLE_HOME"  # Restore

# 3. Test installation without write permission
./dist/oradba_install.sh --prefix /root/oradba --yes
# Expected: Clear error message about permissions
```

**Pass Criteria**:

- ✅ Detects permission issues
- ✅ Provides clear error messages
- ✅ Suggests corrective actions
- ✅ Fails safely without corruption

### 4.3 Special Characters in Paths

**Objective**: Verify handling of paths with special characters

```bash
# 1. Test with spaces in path (if supported)
TEST_PATH="/tmp/oradba test $(date +%s)"
mkdir -p "$TEST_PATH"
./dist/oradba_install.sh --prefix "$TEST_PATH" --yes
# Expected: Handles spaces correctly or provides clear error

# 2. Test with symbolic links
ln -s /opt/oracle/local/oradba /tmp/oradba-link
source /tmp/oradba-link/bin/oraenv.sh "$ORACLE_SID"
# Expected: Works through symlink

# 3. Cleanup
rm -rf "$TEST_PATH" /tmp/oradba-link
```

**Pass Criteria**:

- ✅ Handles or reports special characters appropriately
- ✅ Works correctly with symbolic links
- ✅ Path resolution works correctly

---

## 5. Test Results Template

After completing manual tests, document results:

```markdown
# Manual Test Results

**Date**: YYYY-MM-DD
**Tester**: Your Name
**Version**: OraDBA vX.Y.Z
**Platform**: OS Name and Version
**Oracle**: Version (if applicable)

## Installation Testing
- [ ] Fresh Installation (Standalone): PASS/FAIL
- [ ] Fresh Installation (With Oracle): PASS/FAIL
- [ ] Upgrade Installation: PASS/FAIL

## Configuration Testing
- [ ] Environment Loading: PASS/FAIL
- [ ] Configuration Hierarchy: PASS/FAIL
- [ ] Oracle Homes Management: PASS/FAIL

## Daily Use Testing
- [ ] Environment Switching: PASS/FAIL
- [ ] Information Commands: PASS/FAIL
- [ ] Environment Validation: PASS/FAIL
- [ ] Database Status Checking: PASS/FAIL
- [ ] Common Aliases: PASS/FAIL
- [ ] Multi-User Environment: PASS/FAIL

## Edge Cases
- [ ] Missing Oracle Environment: PASS/FAIL
- [ ] Permission Issues: PASS/FAIL
- [ ] Special Characters: PASS/FAIL

## Issues Found
1. [Description of issue]
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Severity: Critical/Major/Minor

## Overall Assessment
- [ ] APPROVED for release
- [ ] APPROVED with minor issues documented
- [ ] HOLD - Critical issues must be resolved

**Notes**: Additional comments
```

---

## 6. Quick Reference

### Essential Commands

```bash
# Installation
./dist/oradba_install.sh --prefix <path> --yes

# Environment Setup
source $ORADBA_BASE/bin/oraenv.sh <SID>

# Information
oradba_env.sh list           # List all environments
oradba_env.sh show <SID>     # Show SID details
oradba_env.sh validate       # Validate environment
oradba_env.sh status [SID]   # Check database status

# Oracle Homes
oradba_homes.sh list         # List registered homes
oradba_homes.sh add <path>   # Register new home
oradba_homes.sh export       # Export configuration

# Validation
oradba_validate.sh           # Validate installation
```

### Common Aliases

```bash
sq      # SQL*Plus
taa     # Tail alert log
cdh     # cd $ORACLE_HOME
cda     # cd admin directory
cdb     # cd $ORACLE_BASE
rmanc   # RMAN connect
```

### Test Tips

1. **Always backup** before testing destructive operations
2. **Use test environments** when possible
3. **Document unexpected behavior** even if it doesn't fail
4. **Test with different Oracle versions** if available
5. **Test as different users** to verify multi-user support
6. **Check for memory leaks** in long-running sessions

---

**Last Updated**: 2026-01-14
**Applies To**: OraDBA v1.0.0+
