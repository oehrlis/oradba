# PDB Aliases

## Overview

OraDBA automatically generates aliases for Pluggable Databases (PDBs) in Oracle
Multitenant environments. These aliases provide quick access to connect to
specific PDBs and set the session container.

## Features

- **Automatic PDB Discovery**: Queries v$pdbs to find all PDBs in the current CDB
- **Lowercase Aliases**: Each PDB gets a lowercase alias (e.g., `pdb1` for PDB1)
- **Prefixed Aliases**: Additional aliases with 'pdb' prefix for clarity (e.g., `pdbpdb1`)
- **ORADBA_PDB Integration**: Sets ORADBA_PDB variable which affects PS1 prompt
- **Configurable**: Can be disabled with ORADBA_NO_PDB_ALIASES toggle

## Prerequisites

- Oracle Database 12c or higher (Multitenant architecture)
- Container Database (CDB) environment
- SYSDBA privileges to query v$pdbs

## How It Works

When you source the oraenv.sh script for a CDB:

1. OraDBA checks if the database is a CDB
2. Queries v$pdbs for all PDBs (excluding PDB$SEED)
3. Creates aliases for each PDB
4. Exports ORADBA_PDBLIST variable

## Generated Aliases

For each PDB, two aliases are created:

### Simple Alias (lowercase PDB name)

```bash
alias pdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

### Prefixed Alias

```bash
alias pdbpdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

## Usage Examples

### Connect to a PDB

```bash
# Source CDB environment
source oraenv.sh CDB1

# Connect to PDB1 using simple alias
pdb1

# Or using prefixed alias
pdbpdb1
```

### Check Available PDBs

```bash
# List all PDBs
echo $ORADBA_PDBLIST

# Or query directly
sqlplus / as sysdba <<< "SELECT name, open_mode FROM v\$pdbs;"
```

### Switch Between PDBs

```bash
# Connect to PDB1
pdb1
SQL> SHOW CON_NAME

# Exit and connect to PDB2
SQL> EXIT
pdb2
SQL> SHOW CON_NAME
```

### Using with Prompt

When ORADBA_PDB is set, the prompt shows the PDB:

```bash
oracle@host:/path/ [CDB1.PDB1] $
```

## Configuration

### Enable PDB Aliases (default)

PDB aliases are enabled by default. No configuration needed.

### Disable PDB Aliases

Add to `oradba_customer.conf` or `sid.*.conf`:

```bash
export ORADBA_NO_PDB_ALIASES="true"
```

Then source the environment:

```bash
source oraenv.sh CDB1
# No PDB aliases will be generated
```

### Per-SID Configuration

Disable for specific CDB:

```bash
# In sid.CDB1.conf
export ORADBA_NO_PDB_ALIASES="true"
```

Enable for all others (default behavior).

## Variables

### ORADBA_PDBLIST

List of all PDBs in the current CDB:

```bash
echo $ORADBA_PDBLIST
# Output: PDB1 PDB2 PDB3
```

### ORADBA_PDB

Currently selected PDB (set by alias):

```bash
pdb1
echo $ORADBA_PDB
# Output: PDB1
```

### ORADBA_NO_PDB_ALIASES

Toggle to disable PDB alias generation:

```bash
export ORADBA_NO_PDB_ALIASES="true"   # Disable
export ORADBA_NO_PDB_ALIASES="false"  # Enable (default)
```

## Advanced Usage

### Custom PDB Aliases

You can add custom PDB aliases in `oradba_customer.conf`:

```bash
# Alias to connect and run queries
alias pdb1_status="pdb1 && sqlplus / as sysdba <<< 'SELECT tablespace_name, status FROM dba_tablespaces;'"

# Alias to open PDB
alias pdb1_open="sqlplus / as sysdba <<< 'ALTER PLUGGABLE DATABASE PDB1 OPEN;'"

# Alias to close PDB
alias pdb1_close="sqlplus / as sysdba <<< 'ALTER PLUGGABLE DATABASE PDB1 CLOSE IMMEDIATE;'"
```

### List All PDB Aliases

```bash
alias | grep "^pdb"
```

### Refresh PDB Aliases

If you create new PDBs, refresh the environment:

```bash
source oraenv.sh CDB1
# New PDB aliases will be generated
```

## Limitations

- **Requires Database Connection**: PDB aliases only generated if database is accessible
- **CDB Only**: Non-CDB databases won't generate PDB aliases
- **SYSDBA Required**: Needs SYSDBA privileges to query v$pdbs
- **Static Generation**: PDB aliases generated at environment load time, not dynamic
- **Name Conflicts**: If PDB name conflicts with existing alias, existing alias takes precedence

## Troubleshooting

### No PDB Aliases Generated

**Check if PDB alias generation is disabled:**

```bash
echo $ORADBA_NO_PDB_ALIASES
```

If "true", enable it:

```bash
export ORADBA_NO_PDB_ALIASES="false"
source oraenv.sh CDB1
```

**Check if database is a CDB:**

```bash
sqlplus / as sysdba <<< "SELECT cdb FROM v\$database;"
```

Must return "YES".

**Check if database is accessible:**

```bash
sqlplus / as sysdba <<< "SELECT 'OK' FROM dual;"
```

### PDB Alias Not Working

**Check if alias exists:**

```bash
alias pdb1
```

**Check ORADBA_PDBLIST:**

```bash
echo $ORADBA_PDBLIST
```

**Manually test PDB connection:**

```bash
sqlplus / as sysdba <<< "ALTER SESSION SET CONTAINER=PDB1;"
```

### New PDBs Not in Alias List

PDB aliases are generated when environment is sourced. After creating new PDBs:

```bash
# Refresh environment
source oraenv.sh CDB1

# Check updated list
echo $ORADBA_PDBLIST
```

## Security Considerations

- PDB aliases use OS authentication (/ as sysdba)
- ORADBA_PDB variable visible in environment (use with care)
- Consider using Oracle Wallet for PDB connections in production
- Limit SYSDBA access in production environments

## Examples

### Example 1: Development Environment

```bash
# Source CDB environment
source oraenv.sh DEVCDB

# Check available PDBs
echo $ORADBA_PDBLIST
# Output: DEVPDB1 DEVPDB2 TESTPDB

# Connect to development PDB
devpdb1
SQL> SHOW CON_NAME
CON_NAME
------------------------------
DEVPDB1

SQL> SELECT tablespace_name FROM dba_tablespaces;
```

### Example 2: Multiple PDB Management

```bash
#!/bin/bash
# Script to check status of all PDBs

source oraenv.sh PRODCDB

for pdb in $ORADBA_PDBLIST; do
    echo "Checking $pdb..."
    sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER=$pdb;
SELECT name, open_mode FROM v\$pdbs WHERE name='$pdb';
EXIT
EOF
done
```

### Example 3: Disable for Specific CDB

```bash
# In sid.PRODCDB.conf
export ORADBA_NO_PDB_ALIASES="true"

# PDBs managed through proper connection strings
# No automatic aliases for production safety
```

## Integration with Other Features

### PS1 Prompt

When ORADBA_PDB is set, prompt shows both SID and PDB:

```bash
oracle@host:/path/ [CDB1.PDB1] $
```

### dbstatus.sh

The dbstatus.sh script shows PDB information in multitenant environments.

### Hierarchical Configuration

PDB alias settings can be configured at any level:

- `oradba_core.conf` - Global default
- `oradba_customer.conf` - Site-wide override
- `sid.CDB1.conf` - CDB-specific setting

## See Also

- [ALIASES.md](ALIASES.md) - Complete alias reference
- [Oracle Multitenant Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/multi/index.html)
- Oracle docs: ALTER SESSION SET CONTAINER
- Oracle docs: V$PDBS view
