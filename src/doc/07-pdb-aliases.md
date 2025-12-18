# PDB Alias Reference

## Introduction

OraDBA automatically generates aliases for Pluggable Databases (PDBs) in Oracle
Multitenant environments. These aliases provide quick access to connect to
specific PDBs, making it easy to work with containerized databases.

**Key Features:**

- Automatic PDB discovery from `v$pdbs`
- Lowercase aliases for each PDB
- Optional prefixed aliases for clarity
- Integration with PS1 prompt
- Configurable per-CDB

## Prerequisites

- Oracle Database 12c or higher (Multitenant architecture)
- Container Database (CDB) environment
- SYSDBA privileges to query `v$pdbs`

## How It Works

When you source `oraenv.sh` for a CDB, OraDBA:

1. Checks if database is a CDB (`v$database.cdb = 'YES'`)
2. Queries `v$pdbs` for all PDBs (excluding PDB$SEED)
3. Creates aliases for each PDB
4. Exports `ORADBA_PDBLIST` variable

This happens automatically unless `ORADBA_NO_PDB_ALIASES=true`.

## Generated Aliases

For each PDB, two aliases are created:

### Simple Alias (lowercase PDB name)

```bash
# For PDB named "PDB1"
alias pdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

### Prefixed Alias

```bash
# Same with 'pdb' prefix for clarity
alias pdbpdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

## Usage Examples

### Basic Usage

```bash
# Source CDB environment
$ source oraenv.sh CDB1
Setting environment for ORACLE_SID: CDB1

# Check available PDBs
$ echo $ORADBA_PDBLIST
PDB1 PDB2 TESTPDB

# Connect to PDB1
$ pdb1

SQL*Plus: Release 19.0.0.0.0 - Production

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production

SQL> SHOW CON_NAME

CON_NAME
------------------------------
PDB1

SQL> SHOW CON_ID

CON_ID
------------------------------
3
```

### Check Current PDB

```bash
# ORADBA_PDB variable shows current PDB
$ echo $ORADBA_PDB
PDB1

# Prompt also shows CDB.PDB format
$ # Prompt displays: [CDB1.PDB1]
```

### Switch Between PDBs

```bash
# Connect to PDB1
$ pdb1
SQL> SHOW CON_NAME
CON_NAME: PDB1

# Exit and switch to PDB2
SQL> EXIT
$ pdb2
SQL> SHOW CON_NAME
CON_NAME: PDB2
```

### List All PDB Aliases

```bash
# Show all PDB aliases
$ alias | grep "^pdb"
pdb1='export ORADBA_PDB='\''PDB1'\''; sqlplus / as sysdba <<< '\''ALTER SESSION SET CONTAINER=PDB1;'\'''
pdb2='export ORADBA_PDB='\''PDB2'\''; sqlplus / as sysdba <<< '\''ALTER SESSION SET CONTAINER=PDB2;'\'''
pdbpdb1='export ORADBA_PDB='\''PDB1'\''; sqlplus / as sysdba <<< '\''ALTER SESSION SET CONTAINER=PDB1;'\'''
pdbpdb2='export ORADBA_PDB='\''PDB2'\''; sqlplus / as sysdba <<< '\''ALTER SESSION SET CONTAINER=PDB2;'\'''
```

## Configuration

### Enable PDB Aliases (Default)

PDB aliases are enabled by default. No configuration needed.

### Disable PDB Aliases Globally

Add to `oradba_customer.conf`:

```bash
# Disable PDB alias generation globally
export ORADBA_NO_PDB_ALIASES="true"
```

### Disable for Specific CDB

Add to `sid.CDB1.conf`:

```bash
# Disable PDB aliases only for CDB1
export ORADBA_NO_PDB_ALIASES="true"
```

### Re-enable After Disabling

```bash
# Remove or comment out ORADBA_NO_PDB_ALIASES
# Or explicitly enable
export ORADBA_NO_PDB_ALIASES="false"

# Reload environment
source oraenv.sh CDB1
```

## Variables

### ORADBA_PDBLIST

List of all PDBs in the current CDB:

```bash
$ echo $ORADBA_PDBLIST
PDB1 PDB2 TESTPDB
```

**Usage in scripts:**

```bash
for pdb in $ORADBA_PDBLIST; do
    echo "Checking $pdb..."
    sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER=$pdb;
SELECT name, open_mode FROM v\$pdbs WHERE name='$pdb';
EXIT
EOF
done
```

### ORADBA_PDB

Currently selected PDB (set by PDB alias):

```bash
$ pdb1
$ echo $ORADBA_PDB
PDB1
```

**Used by:**

- PS1 prompt customization
- Scripts to track current PDB context
- Functions that need PDB context

### ORADBA_NO_PDB_ALIASES

Toggle to control PDB alias generation:

```bash
# Disable
export ORADBA_NO_PDB_ALIASES="true"

# Enable (default)
export ORADBA_NO_PDB_ALIASES="false"

# Or unset to use default
unset ORADBA_NO_PDB_ALIASES
```

## Prompt Integration

When `ORADBA_PDB` is set, the prompt shows both CDB and PDB:

```bash
# Default prompt
oracle@host:/path/ [CDB1] $

# After connecting to PDB1
oracle@host:/path/ [CDB1.PDB1] $

# After switching to PDB2
oracle@host:/path/ [CDB1.PDB2] $
```

This requires `ORADBA_CUSTOMIZE_PS1=true` in configuration (default).

## Advanced Usage

### Custom PDB Aliases

Add custom PDB-related aliases in `oradba_customer.conf`:

```bash
# Alias to open a PDB
alias pdb1_open="sqlplus / as sysdba <<< 'ALTER PLUGGABLE DATABASE PDB1 OPEN;'"

# Alias to close a PDB
alias pdb1_close="sqlplus / as sysdba <<< 'ALTER PLUGGABLE DATABASE PDB1 CLOSE IMMEDIATE;'"

# Alias to check PDB status
alias pdb1_status="sqlplus -s / as sysdba <<< \"
ALTER SESSION SET CONTAINER=PDB1;
SELECT name, open_mode, restricted FROM v\\\$pdbs WHERE name='PDB1';
EXIT\""

# Alias to show PDB tablespaces
alias pdb1_ts="sqlplus -s / as sysdba <<< \"
ALTER SESSION SET CONTAINER=PDB1;
SELECT tablespace_name, status FROM dba_tablespaces ORDER BY tablespace_name;
EXIT\""
```

### Refresh PDB Aliases After Creating New PDBs

PDB aliases are generated when environment is loaded. After creating new PDBs:

```bash
# Create new PDB
$ sqlplus / as sysdba
SQL> CREATE PLUGGABLE DATABASE PDB3 ADMIN USER pdb3admin IDENTIFIED BY password;
SQL> ALTER PLUGGABLE DATABASE PDB3 OPEN;
SQL> EXIT

# Refresh environment to get new PDB alias
$ source oraenv.sh CDB1

# Check updated list
$ echo $ORADBA_PDBLIST
PDB1 PDB2 PDB3

# New alias available
$ pdb3
SQL> SHOW CON_NAME
CON_NAME: PDB3
```

### Script to Manage All PDBs

```bash
#!/bin/bash
# Check status of all PDBs in current CDB

if [[ -z "$ORADBA_PDBLIST" ]]; then
    echo "Error: Not connected to a CDB or no PDBs found"
    exit 1
fi

echo "PDB Status Report for $ORACLE_SID"
echo "=================================="

for pdb in $ORADBA_PDBLIST; do
    echo ""
    echo "PDB: $pdb"
    sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=$pdb;
SELECT '  Open Mode: ' || open_mode FROM v\$database;
SELECT '  Restricted: ' || restricted FROM v\$pdbs WHERE name='$pdb';
EXIT
EOF
done
```

## Troubleshooting

### No PDB Aliases Generated

**Check if disabled:**

```bash
$ echo $ORADBA_NO_PDB_ALIASES
true  # PDB aliases are disabled
```

**Solution:** Enable them:

```bash
export ORADBA_NO_PDB_ALIASES="false"
source oraenv.sh CDB1
```

**Check if database is a CDB:**

```bash
$ sqlplus -s / as sysdba <<< "SELECT cdb FROM v\$database;"

CDB
---
YES  # Must be YES for PDB aliases to work
```

**Check if database is accessible:**

```bash
$ sqlplus / as sysdba <<< "SELECT 'OK' FROM dual;"
OK
```

### PDB List Empty

**Check for PDBs:**

```bash
$ sqlplus -s / as sysdba <<< "
SELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED' ORDER BY name;
"

# If no results, create a PDB or check database configuration
```

**Check database mode:**

```bash
$ sqlplus -s / as sysdba <<< "SELECT open_mode FROM v\$database;"

OPEN_MODE
----------
READ WRITE  # Must be OPEN for PDB queries
```

### Alias Not Working

**Check if alias exists:**

```bash
$ type pdb1
# Should show alias definition
```

**Test manual PDB connection:**

```bash
$ sqlplus / as sysdba <<< "ALTER SESSION SET CONTAINER=PDB1;"
# Should succeed if PDB exists and is accessible
```

**Check PDB open mode:**

```bash
$ sqlplus -s / as sysdba <<< "SELECT name, open_mode FROM v\$pdbs WHERE name='PDB1';"

NAME      OPEN_MODE
--------- ----------
PDB1      READ WRITE
```

### New PDBs Not in Alias List

PDB aliases are generated at environment load time, not dynamically. After creating new PDBs, reload:

```bash
# Reload environment
$ source oraenv.sh CDB1

# Verify new PDB in list
$ echo $ORADBA_PDBLIST
PDB1 PDB2 NEWPDB
```

## Security Considerations

1. **OS Authentication** - PDB aliases use OS authentication (/ as sysdba)
2. **Privilege Requirements** - Requires SYSDBA which has full control
3. **Environment Variables** - ORADBA_PDB visible in process environment
4. **Production Use** - Consider using:
   - Oracle Wallet for secure connections
   - Dedicated PDB accounts instead of SYSDBA
   - Connection strings with proper authentication
5. **Audit Logging** - SYSDBA actions are audited in CDB
6. **Limited Access** - Restrict SYSDBA access in production environments

## Example Scenarios

### Scenario 1: Development Environment

```bash
# Source dev CDB
$ source oraenv.sh DEVCDB

# Check available dev PDBs
$ echo $ORADBA_PDBLIST
DEVPDB1 DEVPDB2 TESTPDB

# Connect to development PDB
$ devpdb1
SQL> SHOW CON_NAME
CON_NAME: DEVPDB1

SQL> -- Run development queries
SQL> SELECT tablespace_name, status FROM dba_tablespaces;
```

### Scenario 2: Multi-PDB Health Check

```bash
#!/bin/bash
# health_check.sh - Check all PDBs

source oraenv.sh PRODCDB --silent

echo "PDB Health Check - $(date)"
echo "=============================="

for pdb in $ORADBA_PDBLIST; do
    sqlplus -s / as sysdba <<EOF | grep -v "^$"
ALTER SESSION SET CONTAINER=$pdb;
SELECT '$pdb Status:' FROM dual;
SELECT '  Size: ' || ROUND(SUM(bytes)/1024/1024/1024,2) || ' GB' 
  FROM dba_segments;
SELECT '  Sessions: ' || COUNT(*) FROM v\$session WHERE username IS NOT NULL;
EXIT
EOF
    echo ""
done
```

### Scenario 3: Production Safety

For production, disable automatic aliases:

```bash
# In sid.PRODCDB.conf
export ORADBA_NO_PDB_ALIASES="true"

# Use explicit connection strings instead
# Requires proper wallet or credential management
```

## Best Practices

1. **Use PDB aliases for development** - Quick and convenient
2. **Disable in production** - Use proper connection strings with authentication
3. **Document PDB naming** - Use consistent lowercase naming for clarity
4. **Reload after PDB changes** - Re-source environment after creating/dropping PDBs
5. **Check ORADBA_PDBLIST** - Verify available PDBs before scripting
6. **Use ORADBA_PDB in scripts** - Track current PDB context
7. **Consider security** - SYSDBA has full privileges, use appropriately
8. **Test PDB access** - Verify PDB is open before connecting

## Limitations

- **Static Generation** - Aliases generated at environment load, not dynamic
- **Requires Database Access** - Database must be accessible to query PDBs
- **CDB Only** - Non-CDB databases don't generate PDB aliases
- **SYSDBA Required** - Needs SYSDBA privileges to query `v$pdbs`
- **Name Conflicts** - If PDB name conflicts with existing alias, existing takes precedence
- **Lowercase Only** - Aliases are lowercase regardless of PDB name case
- **No Parameters** - Aliases don't accept parameters (fixed to SYSDBA connection)

## Next Steps

- **[Aliases](06-aliases.md)** - Complete alias reference
- **[Configuration](05-configuration.md)** - Customize OraDBA settings
- **[Environment Management](04-environment.md)** - Understanding oraenv.sh
- **[Troubleshooting](12-troubleshooting.md)** - Solve common issues

## Further Reading

- [Oracle Multitenant Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/multi/)
- Oracle SQL Reference: ALTER SESSION
- Oracle Database Reference: V$PDBS
- Oracle Database Administrator's Guide: Managing a Multitenant Environment
