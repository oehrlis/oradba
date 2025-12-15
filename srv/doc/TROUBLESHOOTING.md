# Troubleshooting Guide

## Common Issues and Solutions

### Issue: "oraenv.sh: command not found"

**Symptom**: Shell cannot find oraenv.sh

**Solution**:

```bash
# Add to PATH
export PATH="/opt/oradba/srv/bin:$PATH"

# Or use full path
source /opt/oradba/srv/bin/oraenv.sh ORCL
```

### Issue: "This script must be sourced, not executed"

**Symptom**: Error when running oraenv.sh directly

**Solution**: Use `source` or `.` instead of executing:

```bash
# Correct
source oraenv.sh ORCL

# Or
. oraenv.sh ORCL

# Incorrect
./oraenv.sh ORCL  # This will fail
```

### Issue: "ORACLE_SID not found in oratab"

**Symptom**: SID not found when setting environment

**Possible Causes**:

1. Typo in SID name
2. Entry not in oratab
3. Wrong oratab file

**Solutions**:

```bash
# Check oratab content
cat /etc/oratab

# Verify SID name (case-sensitive)
grep "ORCL:" /etc/oratab

# Check alternative locations
cat /var/opt/oracle/oratab
cat $HOME/.oratab

# Use custom oratab location
export ORATAB_FILE="/path/to/oratab"
source oraenv.sh ORCL
```

### Issue: "ORACLE_HOME directory does not exist"

**Symptom**: Error about missing ORACLE_HOME

**Solutions**:

```bash
# Verify ORACLE_HOME in oratab
grep "ORCL:" /etc/oratab
# Should show: ORCL:/correct/path:N

# Check directory exists
ls -ld /u01/app/oracle/product/19.0.0/dbhome_1

# Fix oratab entry
sudo vim /etc/oratab
```

### Issue: "Permission denied"

**Symptom**: Cannot read oratab or access directories

**Solutions**:

```bash
# Check oratab permissions
ls -l /etc/oratab

# Make readable
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
ORCL:/u01/app/oracle/product/19.0.0/dbhome_1:N
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

# Re-source oraenv
source oraenv.sh ORCL
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

# Re-source oraenv
source oraenv.sh ORCL
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

# Run oraenv
source oraenv.sh ORCL

# Check output for detailed information
```

## Verification Steps

### Verify Installation

```bash
# Check installation directory
ls -la /opt/oradba/srv/

# Verify scripts are executable
ls -l /opt/oradba/srv/bin/oraenv.sh

# Test basic functionality
source /opt/oradba/srv/bin/oraenv.sh --help
```

### Verify Environment

```bash
# After sourcing oraenv
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
cat $ORADBA_PREFIX/srv/etc/oradba.conf
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
sudo chcon -R -t bin_t /opt/oradba/srv/bin/
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
# oradba logs
ls -l $ORADBA_PREFIX/logs/

# Oracle alert log
tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert_*.log
```

## Reinstallation

If all else fails, try reinstalling:

```bash
# Remove old installation
sudo rm -rf /opt/oradba

# Reinstall
sudo ./oradba_install.sh --prefix /opt/oradba
```

## See Also

- [USAGE.md](USAGE.md) - Usage guide
- [SCRIPTS.md](SCRIPTS.md) - Script reference
- [EXAMPLES.md](EXAMPLES.md) - Examples
