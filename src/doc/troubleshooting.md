# Troubleshooting Guide

**Purpose:** Solutions to common OraDBA v0.19.x issues - the canonical location for troubleshooting patterns and
solutions.

**Audience:** All users encountering problems with OraDBA.

## Introduction

This guide provides structured solutions to common OraDBA v0.19.x issues. Each entry follows a consistent pattern:
Symptom → Cause → Check → Fix → Related Chapters.

The Registry API and Plugin System introduced in v0.19.x simplify many operations but have their own troubleshooting
patterns.

## Common Issues and Solutions

### Issue: "oraenv.sh: command not found"

**Symptom:** Shell cannot find oraenv.sh when trying to source it.

**Likely Cause:** OraDBA bin directory not in PATH, or incorrect path specified.

**Check:**

```bash
# Check if oraenv.sh exists
ls -l /opt/oradba/bin/oraenv.sh

# Check current PATH
echo $PATH | grep oradba
```

**Fix:**

```bash
# Add to PATH
export PATH="/opt/oradba/bin:$PATH"

# Or use full path
source /opt/oradba/bin/oraenv.sh FREE

# Or add alias to your profile
alias oraenv='source /opt/oradba/bin/oraenv.sh'
```

**Related Chapters:** [Installation](installation.md), [Quick Start](quickstart.md)

### Issue: "This script must be sourced, not executed"

**Symptom:** Error when running oraenv.sh directly with `./oraenv.sh`

**Likely Cause:** Attempting to execute script instead of sourcing it. Environment variables only persist when sourced.

**Check:**

```bash
# Wrong way - creates subshell
./oraenv.sh FREE
bash oraenv.sh FREE
```

**Fix:**

```bash
# Correct - runs in current shell
source oraenv.sh FREE

# Or use POSIX syntax
. oraenv.sh FREE
```

**Related Chapters:** [Environment Management](environment.md), [Quick Start](quickstart.md)

### Issue: "ORACLE_SID not found in oratab"

**Symptom:** SID not found when setting environment

**Likely Cause:**

1. Typo in SID name (case-sensitive)
2. Entry missing from oratab
3. Using wrong oratab file location

**Check:**

```bash
# Check oratab content
cat /etc/oratab

# Verify SID name (case-sensitive)
grep "FREE:" /etc/oratab

# Check alternative locations
cat /var/opt/oracle/oratab
cat $HOME/.oratab

# Check which oratab OraDBA is using
echo $ORATAB_FILE
```

**Fix:**

```bash
# Add missing entry to oratab
echo "FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N" | sudo tee -a /etc/oratab

# Or use custom oratab location
export ORATAB_FILE="/path/to/oratab"
source oraenv.sh FREE
```

**Related Chapters:** [Quick Start](quickstart.md), [Configuration](configuration.md)

### Issue: "ORACLE_HOME directory does not exist"

**Symptom:** Error about missing ORACLE_HOME directory

**Likely Cause:** Incorrect path in oratab, or Oracle not installed at expected location

**Check:**

```bash
# Verify ORACLE_HOME in oratab
grep "FREE:" /etc/oratab
# Should show: FREE:/correct/path:N

# Check if directory exists
ls -ld /u01/app/oracle/product/19.0.0/dbhome_1

# Check for Oracle binaries
ls -l /u01/app/oracle/product/*/dbhome*/bin/sqlplus
```

**Fix:**

```bash
# Fix oratab entry with correct path
sudo vim /etc/oratab

# Or create symlink if Oracle is in different location
sudo ln -s /actual/oracle/location /expected/oracle/location
```

**Related Chapters:** [Installation](installation.md), [Quick Start](quickstart.md)

### Issue: "Permission denied"

**Symptom:** Cannot read oratab or access Oracle directories

**Likely Cause:** Insufficient file permissions on oratab or Oracle directories

**Check:**

```bash
# Check oratab permissions
ls -l /etc/oratab

# Check Oracle installation permissions
ls -ld $ORACLE_HOME

# Check current user and groups
id
```

**Fix:**

```bash
# Make oratab readable
sudo chmod 644 /etc/oratab

# Check Oracle installation permissions
ls -ld $ORACLE_HOME

# Fix if needed
sudo chown -R oracle:oinstall $ORACLE_HOME
```

### Issue: "No oratab file found"

**Symptom**: Cannot locate oratab file

**Solutions**:

```bash
# Check standard locations
ls -l /etc/oratab
ls -l /var/opt/oracle/oratab

# Create oratab if missing
sudo vim /etc/oratab

# Add entry
# Format: SID:ORACLE_HOME:STARTUP_FLAG
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
```

### Issue: SQL*Plus or RMAN not found

**Symptom**: "command not found" after setting environment

**Possible Causes**:

1. ORACLE_HOME not in PATH
2. Incorrect ORACLE_HOME
3. Missing Oracle binaries

**Solutions**:

```bash
# Verify environment
echo $ORACLE_HOME
echo $PATH

# Check Oracle binaries exist
ls -l $ORACLE_HOME/bin/sqlplus
ls -l $ORACLE_HOME/bin/rman

# Manually add to PATH
export PATH=$ORACLE_HOME/bin:$PATH

# Re-source oraenv.sh (use .sh to avoid conflict with Oracle's oraenv)
source oraenv.sh FREE
```

### Issue: Libraries not found (LD_LIBRARY_PATH)

**Symptom**: "libclntsh.so: cannot open shared object file"

**Solutions**:

```bash
# Check LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH

# Verify Oracle libraries
ls -l $ORACLE_HOME/lib/libclntsh.so

# Add to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

# Re-source oraenv.sh
source oraenv.sh FREE
```

### Issue: TNS configuration not found

**Symptom**: "TNS:could not resolve the connect identifier specified"

**Solutions**:

```bash
# Check TNS_ADMIN
echo $TNS_ADMIN

# Verify tnsnames.ora exists
ls -l $TNS_ADMIN/tnsnames.ora

# Set TNS_ADMIN manually
export TNS_ADMIN=$ORACLE_HOME/network/admin

# Or in user config
echo 'TNS_ADMIN=/custom/path' >> ~/.oradba_config
```

## Debug Mode

OraDBA provides comprehensive debug logging across all major script categories.
Debug mode helps troubleshoot issues by showing detailed execution flow, decision
points, and system interactions.

### Activation Methods

Debug support can be enabled in two ways:

#### Environment Variable (Global)

```bash
# Enable for all OraDBA scripts
export ORADBA_DEBUG=true

# Alternative method (legacy)
export ORADBA_LOG_LEVEL=DEBUG
```

#### Command Line Flag (Per Script)

```bash
# Enable for individual script runs
script_name.sh --debug [other options]
script_name.sh -d [other options]
```

### Script Categories with Debug Support

#### Phase 1: Infrastructure Scripts (v0.19.5+)

Core system and infrastructure management:

```bash
# Environment status and configuration
ORADBA_DEBUG=true oraup.sh
oraenv.sh --debug ORCL

# Installation and system validation
ORADBA_DEBUG=true oradba_check.sh
oradba_validate.sh --debug

# Extension management
oradba_extension.sh --debug list
ORADBA_DEBUG=true oradba_extension.sh install example
```

#### Phase 2: Management Tools (v0.19.6+)

Oracle database and listener management:

```bash
# Database control operations
ORADBA_DEBUG=true oradba_dbctl.sh start ORCL
oradba_dbctl.sh --debug status

# Listener management
oradba_lsnrctl.sh --debug start LISTENER
ORADBA_DEBUG=true oradba_lsnrctl.sh status

# Service orchestration
oradba_services.sh --debug restart
ORADBA_DEBUG=true oradba_services.sh start
```

#### Phase 3: Job Automation (v0.19.7+)

Backup and monitoring operations:

```bash
# RMAN operation monitoring
ORADBA_DEBUG=true rman_jobs.sh
rman_jobs.sh --debug -w -i 10

# DataPump export monitoring
exp_jobs.sh --debug -o "%EXP%" -w
ORADBA_DEBUG=true exp_jobs.sh --all

# DataPump import monitoring
imp_jobs.sh --debug -w -i 5
ORADBA_DEBUG=true imp_jobs.sh ORCL

# Long operations monitoring (core script)
longops.sh --debug -o "RMAN%" -w
ORADBA_DEBUG=true longops.sh --all ORCL FREE
```

### Debug Output Information

When debug mode is enabled, you'll see detailed information about:

**Infrastructure Scripts:**

- Library and plugin loading
- Oracle Home detection and validation
- Registry API operations
- Environment variable resolution
- Configuration file processing

**Management Tools:**

- Database startup/shutdown sequences
- Listener operations and port detection
- Service orchestration and dependency management
- Oracle environment setup and validation
- SQL operation execution and error handling

**Job Automation:**

- Wrapper script argument processing
- Filter application and SQL query construction
- Database connection establishment
- Monitoring loop iterations and timing
- Environment sourcing per SID

### Common Debug Patterns

**Environment Issues:**

```bash
# Debug Oracle environment setup
ORADBA_DEBUG=true oraenv.sh ORCL
# Shows: registry lookup, plugin application, path construction

# Debug home detection
ORADBA_DEBUG=true oraup.sh
# Shows: oratab parsing, home classification, plugin discovery
```

**Database Operations:**

```bash
# Debug database startup
oradba_dbctl.sh --debug start ORCL
# Shows: environment setup, SQL execution, timeout handling

# Debug service coordination
oradba_services.sh --debug restart
# Shows: startup order, listener/database dependencies
```

**Monitoring Operations:**

```bash
# Debug backup monitoring
rman_jobs.sh --debug -w
# Shows: argument filtering, longops.sh invocation, SQL query construction

# Debug with operation filter
longops.sh --debug -o "RMAN%" -a
# Shows: filter construction, environment sourcing, query execution
```

### Debug Output Format

Debug messages follow this pattern:

```text
DEBUG: script_name.sh: message content
```

For scripts using `oradba_log`:

```text
[DEBUG] timestamp script_name.sh: message content
```

### Legacy Debug Support

**Note:** The following method is deprecated but still supported:

```bash
# Legacy method (still works)
export DEBUG=1

# Run any script
source oraenv.sh FREE
```

### Performance Considerations

- Debug mode has minimal performance impact when disabled
- Debug output can be verbose - use judiciously in production
- Log files may grow larger when debug is enabled globally
- Consider per-script activation for focused troubleshooting

## Verification Steps

### Verify Installation

```bash
# Check installation directory
ls -la /opt/oradba/src/

# Verify scripts are executable
ls -l /opt/oradba/src/bin/oraenv.sh

# Test basic functionality
source /opt/oradba/src/bin/oraenv.sh --help
```

### Verify Environment

```bash
# After sourcing oraenv.sh
echo "ORACLE_SID: $ORACLE_SID"
echo "ORACLE_HOME: $ORACLE_HOME"
echo "ORACLE_BASE: $ORACLE_BASE"
echo "TNS_ADMIN: $TNS_ADMIN"

# Test Oracle connectivity
sqlplus -V
rman -version
```

### Verify Configuration

```bash
# Check configuration files
cat $ORADBA_PREFIX/src/etc/oradba.conf
cat ~/.oradba_config  # If exists

# Verify oratab
cat /etc/oratab
```

## Performance Issues

### Slow Environment Setup

**Possible Causes**:

1. Large oratab file
2. Network mounted directories
3. Slow disk I/O

**Solutions**:

- Use specific SID instead of interactive mode
- Optimize oratab (remove unused entries)
- Check disk performance

## Platform-Specific Issues

### macOS

**Issue**: Different oratab location

```bash
# Check macOS locations
ls -l /var/opt/oracle/oratab
ls -l /etc/oratab
```

### Linux

**Issue**: SELinux blocking access

```bash
# Check SELinux
getenforce

# Temporarily disable for testing
sudo setenforce 0

# Add proper context
sudo chcon -R -t bin_t /opt/oradba/src/bin/
```

## Getting Help

If you cannot resolve the issue:

1. **Enable debug mode** and capture output
2. **Check GitHub issues**: <https://github.com/oehrlis/oradba/issues>
3. **Create new issue** with:
   - Error message
   - Debug output
   - Environment details (OS, Oracle version)
   - Steps to reproduce

## Pre-Oracle Installation Issues

**Available from:** v0.17.0 - Troubleshooting for installations before Oracle Database is present.

### Issue: "ORACLE_BASE not found" During Installation

**Symptom:** Installer hangs or prompts for Oracle Base when Oracle is not installed.

**Likely Cause:** Installer trying to detect Oracle Base but Oracle is not installed yet.

**Check:**

```bash
# Verify Oracle is not installed
which oracle
ls -d /u01/app/oracle 2>/dev/null
echo $ORACLE_BASE
```

**Fix:**

```bash
# Use --user-level for home directory installation
./oradba_install.sh --user-level

# Or specify base explicitly
./oradba_install.sh --base /opt

# Or use direct prefix
./oradba_install.sh --prefix /opt/local/oradba

# Use --silent to avoid prompts
./oradba_install.sh --user-level --silent
```

**Related Chapters:** [Installation](installation.md#pre-oracle-installation)

### Issue: Temporary oratab Created

**Symptom:** OraDBA created `${ORADBA_BASE}/etc/oratab` instead of using system oratab.

**Likely Cause:** Normal behavior for pre-Oracle installations - system oratab doesn't exist yet.

**Check:**

```bash
# Verify it's a temporary oratab
cat $ORADBA_BASE/etc/oratab | head -3

# Check if it's a symlink
ls -la $ORADBA_BASE/etc/oratab

# Verify no system oratab exists
ls -l /etc/oratab /var/opt/oracle/oratab 2>/dev/null
```

**Fix:**

```bash
# This is expected! After Oracle installation:
oradba_setup.sh link-oratab

# Verify the symlink
oradba_setup.sh check
```

**Related Chapters:** [Installation](installation.md#post-oracle-configuration)

### Issue: "No Oracle installation detected"

**Symptom:** Tools report Oracle is not installed or `ORADBA_NO_ORACLE_MODE=true` is set.

**Likely Cause:** Oracle not installed yet, or ORACLE_HOME not detectable.

**Check:**

```bash
# Verify Oracle installation status
oradba_validate.sh  # Shows "Pre-Oracle" or "Oracle Installed"

# Check for Oracle binaries
which sqlplus oracle

# Check environment
echo $ORACLE_HOME
echo $ORADBA_NO_ORACLE_MODE
```

**Fix:**

```bash
# If Oracle is NOT installed - this is expected behavior
# Tools work in graceful degradation mode

# If Oracle IS installed - link oratab:
oradba_setup.sh link-oratab

# Or manually set ORACLE_HOME
export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

**Related Chapters:** [Installation](installation.md#graceful-degradation-no-oracle-mode)

### Issue: oraup.sh Shows No Databases

**Symptom:** `oraup.sh` reports "No Oracle databases found in oratab" when Oracle is installed.

**Likely Cause:**

1. Using temporary oratab instead of system oratab
2. System oratab exists but not linked
3. oratab is empty or has no entries

**Check:**

```bash
# Check which oratab is being used
oradba_setup.sh show-config

# Verify system oratab exists and has entries
cat /etc/oratab | grep -v "^#" | grep -v "^$"

# Check if using temp oratab
ls -la $ORADBA_BASE/etc/oratab
```

**Fix:**

```bash
# Link to system oratab
oradba_setup.sh link-oratab

# If oratab is empty, add database entries:
echo "FREE:/u01/app/oracle/product/21c/dbhome_1:N" | sudo tee -a /etc/oratab

# Then verify
oraup.sh
```

**Related Chapters:** [Environment Management](environment.md), [Quick Start](quickstart.md)

### Issue: Permission Denied During link-oratab

**Symptom:** `oradba_setup.sh link-oratab` fails with permission errors.

**Likely Cause:** Insufficient permissions to create symlink in `${ORADBA_BASE}/etc/`.

**Check:**

```bash
# Check ownership
ls -ld $ORADBA_BASE/etc/

# Check if temp oratab is writable
ls -l $ORADBA_BASE/etc/oratab

# Verify system oratab exists
ls -l /etc/oratab /var/opt/oracle/oratab 2>/dev/null
```

**Fix:**

```bash
# Fix ownership
sudo chown -R oracle:oinstall $ORADBA_BASE/etc/

# Run as appropriate user
oradba_setup.sh link-oratab

# Or with sudo if needed
sudo -E bash -c 'source oraenv.sh && oradba_setup.sh link-oratab'
```

**Related Chapters:** [Installation](installation.md#post-oracle-configuration)

### Issue: oraenv.sh Not Setting ORACLE_HOME

**Symptom:** After sourcing `oraenv.sh`, ORACLE_HOME is not set.

**Likely Cause:** Operating in No-Oracle Mode, or ORACLE_HOME not found in oratab.

**Check:**

```bash
# Check if in No-Oracle Mode
source oraenv.sh
echo $ORADBA_NO_ORACLE_MODE  # Should be empty or unset if Oracle is present

# Verify SID in oratab
grep "^ORCL:" /etc/oratab

# Check validation status
oradba_validate.sh
```

**Fix:**

```bash
# If pre-Oracle - expected behavior, tools gracefully degrade

# If Oracle installed but not linked:
oradba_setup.sh link-oratab
source oraenv.sh ORCL

# If oratab entry missing:
echo "ORCL:/u01/app/oracle/product/19c/dbhome_1:N" | sudo tee -a /etc/oratab
```

**Related Chapters:** [Environment Management](environment.md)

### Issue: Extensions Not Working in Pre-Oracle Mode

**Symptom:** Extensions fail to load or don't function correctly.

**Likely Cause:** Extensions may depend on Oracle being installed.

**Check:**

```bash
# Verify installation mode
oradba_validate.sh

# Check extension status
oradba_extension.sh list

# Review extension requirements
cat $ORADBA_BASE/extensions/*/metadata.json
```

**Fix:**

```bash
# Extensions work best after Oracle is installed
oradba_setup.sh link-oratab

# Or review extension-specific documentation
oradba_extension.sh info <extension-name>
```

**Related Chapters:** [Extensions](extensions.md)

### Issue: Dummy Home for Testing

**Symptom:** Want to test OraDBA without installing Oracle.

**Likely Cause:** Need isolated test environment.

**Check:**

```bash
# Verify current installation
oradba_validate.sh
```

**Fix:**

```bash
# Install with dummy ORACLE_HOME for testing
./oradba_install.sh --dummy-home /tmp/fake-oracle --prefix /tmp/oradba-test

# Test the installation
export ORADBA_BASE=/tmp/oradba-test
source /tmp/oradba-test/bin/oraenv.sh

# Validate
/tmp/oradba-test/bin/oradba_validate.sh

# Cleanup when done
rm -rf /tmp/oradba-test /tmp/fake-oracle
```

**Related Chapters:** [Installation](installation.md#pre-oracle-installation)

### Issue: Auto-Discovery Not Finding Running Instances (v0.19.x) {#auto-discovery-issues}

**Symptom:** Oracle instances are running but auto-discovery doesn't detect them.

**Likely Cause:**

1. Auto-discovery is disabled
2. Instances running as different user
3. Process names don't match expected patterns
4. `/proc` filesystem not accessible

**Check:**

```bash
# Verify auto-discovery is enabled
echo $ORADBA_AUTO_DISCOVER_INSTANCES  # Should be "true" or empty (default is true)

# Check for running Oracle processes manually
ps -ef | grep -E "(smon_|pmon_)" | grep -v grep

# Check processes for current user
ps -U $(id -un) -o pid,comm | grep -E "(db_smon_|ora_pmon_|asm_smon_)"

# Test discovery function directly
source /opt/oradba/lib/oradba_common.sh
discover_running_oracle_instances
```

**Fix:**

```bash
# Enable auto-discovery explicitly
export ORADBA_AUTO_DISCOVER_INSTANCES="true"
source oraenv.sh

# If instances run as different user (e.g., 'oracle' user)
# You need to switch to that user first
sudo su - oracle
source /opt/oradba/bin/oraenv.sh

# Or manually add to oratab
ps -U oracle -o pid,comm | grep -E "(smon_|pmon_)" | head -1
# Note the SID from process name, find ORACLE_HOME
sudo sh -c 'echo "FREE:/u01/app/oracle/product/23ai/dbhomeFree:N" >> /etc/oratab'
```

**Related Chapters:** [Configuration](configuration.md#scenario-7-auto-discovery), [Quick Start](quickstart.md)

### Issue: Permission Denied Writing to oratab

**Symptom:** Auto-discovery finds instances but can't persist them:

```text
[WARN] Cannot write to system oratab: /etc/oratab (permission denied)
[WARN] Falling back to local oratab: /opt/oradba/etc/oratab
```

**Likely Cause:** Running as non-root user without write permission to
`/etc/oratab`.

**Check:**

```bash
# Check oratab permissions
ls -l /etc/oratab

# Check if you have write access
test -w /etc/oratab && echo "Writable" || echo "Not writable"

# Check local oratab location
ls -l $ORADBA_PREFIX/etc/oratab
```

**Fix (Option 1 - Use Local oratab):**

```bash
# This works automatically - OraDBA falls back to local oratab
# Just use the local copy for your session
source oraenv.sh

# Verify it's using local oratab
echo $ORATAB_FILE  # Should show /opt/oradba/etc/oratab
```

**Fix (Option 2 - Sync to System oratab):**

```bash
# Manually copy discovered entries to system oratab (requires root/sudo)
sudo cat $ORADBA_PREFIX/etc/oratab >> /etc/oratab

# Or edit directly
sudo vi /etc/oratab
# Add: FREE:/u01/app/oracle/product/23ai/dbhomeFree:N

# Verify
grep FREE /etc/oratab

# Next login will use system oratab
source oraenv.sh FREE
```

**Fix (Option 3 - Make /etc/oratab Group-Writable):**

```bash
# As root, make oratab writable by dba group
sudo chmod 664 /etc/oratab
sudo chgrp dba /etc/oratab

# Verify
ls -l /etc/oratab
# Should show: -rw-rw-r-- 1 root dba

# Now discovery can persist directly
source oraenv.sh
```

**Related Chapters:** [Configuration](configuration.md#scenario-7-auto-discovery), [Installation](installation.md)

### Issue: Listener Status Not Displayed

**Symptom:** Listener status is not shown by `oraup.sh` or when switching environments.

**Likely Cause:**

1. No listener running
2. Listener name doesn't match SID
3. Client-only ORACLE_HOME (no listener expected)
4. Grid Infrastructure listener (managed separately)

**Check:**

```bash
# Check if listener is running
ps -ef | grep tnslsnr | grep -v grep

# Check listener status manually
lsnrctl status

# Check listener for specific SID
lsnrctl status LISTENER_FREE

# Verify ORACLE_HOME type
ls -l $ORACLE_HOME/bin/lsnrctl
ls -l $ORACLE_HOME/bin/sqlplus
```

**Behavior (v0.19.x):**

Listener status is shown when:

- SID matches listener name (e.g., SID=FREE, listener=LISTENER_FREE or
  LISTENER), OR
- Client-only ORACLE_HOME (has sqlplus but no lsnrctl) - shows status even
  without listener

Listener status is hidden when:

- Grid Infrastructure home (listener managed by Grid)
- Tool-only homes (OUD, OID, BI, etc.)

**Fix:**

```bash
# Start listener if not running
lsnrctl start LISTENER_FREE

# Check status to see if it appears now
oraup.sh

# Or manually check
lsnrctl status LISTENER_FREE
```

**Related Chapters:** [Service Management](service-management.md), [Usage Guide](usage.md)

## Log Files

Check log files for errors:

```bash
# OraDBA logs
ls -l $ORADBA_PREFIX/log/

# Oracle alert log (use alias)
taa  # tail alert log

# Or manually
tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert_*.log
```

**Related Chapters:** [Aliases](aliases.md), [Environment Management](environment.md)

## Reinstallation

If all else fails, try reinstalling:

```bash
# Backup customizations first
cp $ORADBA_PREFIX/etc/oradba_customer.conf ~/oradba_customer.conf.backup
cp $ORADBA_PREFIX/etc/sid.*.conf ~/

# Remove old installation
sudo rm -rf /opt/oradba

# Reinstall
sudo ./oradba_install.sh --prefix /opt/oradba

# Restore customizations
cp ~/oradba_customer.conf.backup $ORADBA_PREFIX/etc/oradba_customer.conf
```

**Related Chapters:** [Installation](installation.md), [Configuration](configuration.md)

## See Also {.unlisted .unnumbered}

- [Environment Management](environment.md) - Detailed environment setup
- [Configuration](configuration.md) - Configuration issues
- [Aliases](aliases.md) - Alias loading problems
- [PDB Aliases](pdb-aliases.md) - PDB alias issues
- [Installation](installation.md) - Reinstallation guide

## Navigation {.unlisted .unnumbered}

**Previous:** [rlwrap Filter Configuration](rlwrap.md)  
**Next:** [Quick Reference](reference.md)
