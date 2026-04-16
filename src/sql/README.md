# OraDBA SQL Scripts
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->

## Overview

This directory contains SQL scripts for Oracle database administration, security,
auditing, and encryption management.

**For detailed documentation, see:** [sql-scripts.md](../doc/sql-scripts.md)

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

**See full naming convention details in:** [sql-scripts.md](../doc/sql-scripts.md#naming-convention)

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

| Alias      | Target                        | Purpose                          |
|------------|-------------------------------|----------------------------------|
| `oh`       | `oh.sql`                      | Display help for SQL scripts     |
| `who`      | `sec_whoami_show.sql`         | Current session info             |
| `audit`    | `aud_config_show_aud.sql`     | Audit configuration              |
| `apol`     | `aud_policies_show_aud.sql`   | Audit policies                   |
| `logins`   | `aud_logins_show_aud.sql`     | Login events                     |
| `afails`   | `aud_logins_failed_aud.sql`   | Failed logins                    |
| `tde`      | `tde_info_dba.sql`            | TDE status                       |
| `tdeops`   | `tde_ops_show_dba.sql`        | TDE operations                   |

## Script Categories

### Security Scripts

Security-related scripts for users, roles, profiles, and permissions.

**See:** [sql-scripts.md - Security Section](../doc/sql-scripts.md#script-categories)

### Audit Scripts

Unified and traditional audit scripts for monitoring and compliance.

Subcategories:

- **Policy Management** - Create, enable, disable, and drop audit policies
- **Configuration and Health** - Audit trail configuration, health dashboards, reports
- **Session and Login Analysis** - Login events, failed logins, session context
- **Event Detail Queries** - DDL, grants, critical objects/privileges, return codes
- **Top-N Analysis** - Top users, policies, objects, error codes
- **Trail Volume Analysis** - Trail trend analysis and user-host pattern detection
- **Splunk Integration** - Archive timestamp management for Splunk ingestion
- **ODB Policy Scripts** - Customer-specific ODB audit policies and context (PROD)

**See:** [sql-scripts.md - Audit Section](../doc/sql-scripts.md#script-categories)

### Splunk Integration Scripts

Scripts for Splunk archive timestamp management.

| Script | Purpose |
|--------|---------|
| `aud_splunk_at_detection_setup.sql` | Archive timestamp via Audit Trail Detection (K-AT pattern) |
| `aud_splunk_checkpoint_setup.sql` | Archive timestamp via Watchdog Checkpoint (K-WD pattern) |

### Trail Volume Analysis Scripts

Scripts for comprehensive audit trail analysis and optimization.

| Script | Purpose |
|--------|---------|
| `aud_trail_analysis_aud.sql` | Comprehensive trail analysis: volume trend, noise candidates, policy coverage gaps |
| `aud_trail_userhost_analysis_aud.sql` | User-host analysis for connection patterns and logon trigger regex design |

### Utility Scripts

Session context and environment helpers.

| Script | Purpose |
|--------|---------|
| `env.sql` | Show full session environment: DB version, audit mode, NLS, session identity, SQLPATH |
| `env_show_sqlpath.sql` | Show current SQLPATH directories with existence check |
| `pdb.sql` | Switch session container to a given PDB (parameterized, default AUDITPDB1) |
| `auditpdb.sql` | Switch session container directly to AUDITPDB1 |

### TDE / Encryption Scripts

Transparent Data Encryption setup, management, and monitoring.

**See:** [sql-scripts.md - TDE Section](../doc/sql-scripts.md#script-categories)

## Notes

- All detailed script documentation has been moved to [sql-scripts.md](../doc/sql-scripts.md)
- For SQL Developer reports, see `unified_audit_reports.xml`
- Legacy scripts with old naming (e.g., `sdsec_`, `cssec_`) are being migrated to new convention
- `odb_audit_ctx_create_aud.sql` and `odb_policies_enable_aud.sql` are PROD deployment scripts
  for ODB customer-specific audit policies; for lab use see `ora-db-audit-eng` repository
