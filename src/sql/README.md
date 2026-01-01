# OraDBA SQL Scripts
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->

## Overview

This directory contains SQL scripts for Oracle database administration, security,
auditing, and encryption management.

**For detailed documentation, see:** [08-sql-scripts.md](../doc/08-sql-scripts.md)

## Quick Start

```bash
# Set environment
source oraenv.sh FREE

# Run a script
sqlplus / as sysdba @db_info.sql

# Common aliases work automatically
@who    # Current session info
@audit  # Audit configuration
@tde    # TDE status
```

## Log File Management

SQL scripts that produce output automatically spool to log files with the format:
`scriptname_sid_timestamp.log`

**Log Directory Configuration:**

```bash
# Option 1: Use ORADBA_LOG environment variable (recommended)
export ORADBA_LOG=/var/log/oracle
sqlplus / as sysdba @aud_policies_show_aud.sql
# Creates: /var/log/oracle/aud_policies_show_aud_proddb_20260101_143045.log

# Option 2: Without ORADBA_LOG (fallback to current directory)
sqlplus / as sysdba @aud_policies_show_aud.sql
# Creates: ./aud_policies_show_aud_proddb_20260101_143045.log
```

**Log File Format:**

- `scriptname`: Name of the SQL script (e.g., aud_policies_show_aud)
- `sid`: Database instance name in lowercase (e.g., proddb)
- `timestamp`: Execution time in YYYYMMDD_HH24MISS format

**Benefits:**

- Centralized log management when ORADBA_LOG is set
- Unique filenames prevent overwrites
- Easy identification of database and execution time
- Supports log rotation and cleanup strategies

## Naming Convention

Scripts follow the format: `<domain>_<action>_<object>[_scope][_priv].sql`

- **Domains:** `sec`, `aud`, `tde`, `dba`, `mon`, `net`, `util`
- **Actions:** `show`, `create`, `enable`, `disable`, `drop`, `gen`, `init`
- **Privilege:** `_dba`, `_sys`, `_aud` (optional suffix)

**See full naming convention details in:** [08-sql-scripts.md](../doc/08-sql-scripts.md#naming-convention)

## Getting Help

Use the `oh.sql` script to explore available SQL scripts:

```bash
# List all SQL scripts with their purposes
sqlplus / as sysdba @oh

# Filter by category
@oh aud      # Show audit scripts
@oh tde      # Show TDE scripts
@oh sec      # Show security scripts
```

## Common Aliases

| Alias    | Target                      | Purpose                      |
|----------|-----------------------------|------------------------------|
| `oh`     | `oh.sql`                    | Display help for SQL scripts |
| `who`    | `sec_whoami_show.sql`       | Current session info         |
| `audit`  | `aud_config_show_aud.sql`   | Audit configuration          |
| `apol`   | `aud_policies_show_aud.sql` | Audit policies               |
| `logins` | `aud_logins_show_aud.sql`   | Login events                 |
| `afails` | `aud_logins_failed_aud.sql` | Failed logins                |
| `tde`    | `tde_info_dba.sql`          | TDE status                   |
| `tdeops` | `tde_ops_show_dba.sql`      | TDE operations               |

## Script Categories

### Security Scripts

Security-related scripts for users, roles, profiles, and permissions.

**See:** [08-sql-scripts.md - Security Section](../doc/08-sql-scripts.md#script-categories)

### Audit Scripts

Unified and traditional audit scripts for monitoring and compliance.

**See:** [08-sql-scripts.md - Audit Section](../doc/08-sql-scripts.md#script-categories)

### TDE / Encryption Scripts

Transparent Data Encryption setup, management, and monitoring.

**See:** [08-sql-scripts.md - TDE Section](../doc/08-sql-scripts.md#script-categories)

## Notes

- All detailed script documentation has been moved to [08-sql-scripts.md](../doc/08-sql-scripts.md)
- For SQL Developer reports, see `unified_audit_reports.xml`
- Legacy scripts with old naming (e.g., `sdsec_`, `cssec_`) are being migrated to new convention
| [tde_init_full_sys_pdbiso_keyadmin.sql](tde_init_full_sys_pdbiso_keyadmin.sql) | Create the software keystore in PDB in isolation mode as SYSKM Environment must be prepared before with tde_init_full_sys_pdbiso_prepare.sql                                                                                                                       |
| [tde_init_full_sys_pdbiso.sql](tde_init_full_sys_pdbiso.sql)                   | Initialize TDE in a PDB in isolation mode i.e., with a dedicated wallet in WALLET_ROOT for this pdb. The CDB must be configured for TDE beforehand. This scripts does use several other scripts to enable TDE and it also includes **restart** of the pdb. |
| [tde_init_full_sys_pdbuni.sql](tde_init_full_sys_pdbuni.sql)                   | Initialize TDE in a PDB in united mode i.e., with a common wallet of the CDB in WALLET_ROOT. The CDB must be configured for TDE beforehand. This scripts does use several other scripts to enable TDE and it also includes **restart** of the pdb.         |
| [tde_init_full_sys.sql](tde_init_full_sys.sql)                                 | Initialize TDE for a single tenant or container database. This scripts does use several other scripts to enable TDE and it also includes **restart** of the database.                                                                                      |
| [tde_info_dba.sql](tde_info_dba.sql)                               | Show information about the TDE Configuration                                                                                                                                                                                                               |
| [tde_wallet_create_sys_backup.sql](tde_wallet_create_sys_backup.sql)     | Create DBMS_SCHEDULER program, schedule and job for TDE software keystore backups. Backup path and directory can be specified. Default is set to WALLET_ROOT/backup                                                                                        |
| [tde_wallet_bkup_remove_sys.sql](tde_wallet_bkup_remove_sys.sql)     | Delete DBMS_SCHEDULER program, schedule and job for TDE software keystore backups created with [tde_wallet_create_sys_backup.sql](tde_wallet_create_sys_backup.sql)                                                                                                  |
| [tde_wallet_bkup_show_sys.sql](tde_wallet_bkup_show_sys.sql)     | Show DBMS_SCHEDULER program, schedule and job for TDE software keystore backups                                                                                                                                                                            |
| [tde_dbf_offline_decrypt_sys.sql](tde_dbf_offline_decrypt_sys.sql)                 | Generate chunks to offline encrypt datafiles                                                                                                                                                                                                               |
| [tde_dbf_offline_encrypt_sys.sql](tde_dbf_offline_encrypt_sys.sql)                 | Generate chunks to offline decrypt datafiles                                                                                                                                                                                                               |
| [tde_ops_show_dba_csv.sql](tde_ops_show_dba_csv.sql)                   | Show TDE operations from V$SESSION_LONGOPS as CSV                                                                                                                                                                                                          |
| [tde_ops_show_dba_run.sql](tde_ops_show_dba_run.sql)                   | Show TDE running operations from V$SESSION_LONGOPS                                                                                                                                                                                                         |
| [tde_ops_show_dba.sql](tde_ops_show_dba.sql)                           | Show TDE operations from V$SESSION_LONGOPS                                                                                                                                                                                                                 |
