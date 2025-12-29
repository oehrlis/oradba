# Troubleshooting Guide

**Purpose:** Solutions to common OraDBA issues - the canonical location for troubleshooting patterns and solutions.

**Audience:** All users encountering problems with OraDBA.

## Introduction

This guide provides structured solutions to common OraDBA issues. Each entry follows a consistent pattern: Symptom →
Cause → Check → Fix → Related Chapters.

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

**Related Chapters:** [Installation](02-installation.md), [Quick Start](03-quickstart.md)

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

**Related Chapters:** [Environment Management](04-environment.md), [Quick Start](03-quickstart.md)

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

**Related Chapters:** [Quick Start](03-quickstart.md), [Configuration](05-configuration.md)

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

**Related Chapters:** [Installation](02-installation.md), [Quick Start](03-quickstart.md)

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

Enable detailed logging:

```bash
# Enable debug
export DEBUG=1

# Run oraenv.sh
source oraenv.sh FREE

# Check output for detailed information
```

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

**Related Chapters:** [Aliases](06-aliases.md), [Environment Management](04-environment.md)

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

**Related Chapters:** [Installation](02-installation.md), [Configuration](05-configuration.md)

## See Also

- [Environment Management](04-environment.md) - Detailed environment setup
- [Configuration](05-configuration.md) - Configuration issues
- [Aliases](06-aliases.md) - Alias loading problems
- [PDB Aliases](07-pdb-aliases.md) - PDB alias issues
- [Installation](02-installation.md) - Reinstallation guide

## Navigation

**Previous:** [rlwrap Filter Configuration](11-rlwrap.md)  
**Next:** [Quick Reference](13-reference.md)
