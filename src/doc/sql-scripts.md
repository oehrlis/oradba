# SQL Scripts Reference

**Purpose:** Complete reference for OraDBA SQL scripts collection for database administration, security,
audit, and encryption tasks.

**Audience:** DBAs needing ready-to-use SQL scripts for common database tasks.

## Introduction {.unlisted}

OraDBA includes a comprehensive collection of SQL scripts for database administration, focusing on security,
audit, encryption, and general DBA tasks. Scripts are organized by topic and follow consistent naming conventions for
easy discovery and use.

## Location and Usage

### Script Location

```bash
# Scripts are located in SQLPATH
echo $SQLPATH
# Output: /opt/oradba/sql

# Navigate to SQL directory
cd $SQLPATH
# or use alias
cd $(echo $SQLPATH)

# List all SQL scripts
ls -1 *.sql | head -20
```

### Running SQL Scripts

```bash
# Set environment first
source oraenv.sh FREE

# Run script using @ syntax (SQLPATH is configured)
sqlplus / as sysdba @db_info.sql

# Or use full path
sqlplus / as sysdba @$SQLPATH/db_info.sql

# Using sessionsql for better formatting
sessionsql @who.sql
```

### Getting Help

Use the `oh.sql` script to discover available SQL scripts:

```sql
-- List all available scripts with their purposes
SQL> @oh

-- Filter by category
SQL> @oh aud      -- Show audit scripts
SQL> @oh tde      -- Show TDE scripts  
SQL> @oh sec      -- Show security scripts
```

The help script reads headers from all SQL files in `$SQLPATH` and displays
their names and purposes in a sorted, formatted list.

### login.sql

The `login.sql` script is automatically executed when SQL*Plus starts (via SQLPATH configuration). It provides:

- Optimized formatting settings
- Custom prompt with connection info
- Timing and error handling
- Helpful SQL*Plus environment

## Naming Convention

Scripts follow a consistent naming pattern for easy discovery:

### Format

```text
<action>_<category>_<object>[_priv].sql
```

**Components:**

- **action**: Operation verb (cr, dr, up, en, dis, gen) or omitted for queries
- **category**: Topic area (sec, aud, tde, dba, mon)
- **object**: What the script operates on
- **priv**: Required privilege level (_dba,_sys, _aud) - optional

### Action Verbs

| Verb   | SQL Command | Example                | Description                  |
|--------|-------------|------------------------|------------------------------|
| cr     | CREATE      | `cr_aud_policies.sql`  | Create objects/configuration |
| dr     | DROP        | `dr_aud_policies.sql`  | Drop/remove objects          |
| up     | UPDATE      | `up_sec_profile.sql`   | Update/alter configuration   |
| en     | ENABLE      | `en_aud_policies.sql`  | Enable features/policies     |
| dis    | DISABLE     | `dis_aud_policies.sql` | Disable features/policies    |
| gen    | GENERATE    | `gen_aud_stmts.sql`    | Generate SQL statements      |
| (none) | SELECT      | `aud_sessions.sql`     | Query/show information       |

### Categories

| Category   | Prefix | Focus Area                  | Examples                             |
|------------|--------|-----------------------------|--------------------------------------|
| Security   | `sec_` | Users, roles, privileges    | `sec_users.sql`, `sec_roles.sql`     |
| Audit      | `aud_` | Unified & traditional audit | `aud_sessions.sql`, `aud_events.sql` |
| Encryption | `tde_` | Transparent Data Encryption | `tde_info.sql`, `tde_keys.sql`       |
| Admin      | `dba_` | General DBA tasks           | `dba_space.sql`, `dba_jobs.sql`      |
| Monitor    | `mon_` | Monitoring & diagnostics    | `mon_sessions.sql`, `mon_locks.sql`  |

### Privilege Indicators

| Suffix | Privilege    | Example                | Required Access          |
|--------|--------------|------------------------|--------------------------|
| (none) | Regular User | `sec_whoami_show.sql`  | Minimal privileges       |
| `_dba` | DBA Role     | `sec_users_dba.sql`    | DBA or SYSTEM            |
| `_sys` | SYSDBA       | `tde_keystore_sys.sql` | SYSDBA/SYSKM/SYSBACKUP   |
| `_aud` | Audit Admin  | `aud_config_aud.sql`   | AUDIT_ADMIN/AUDIT_VIEWER |

## Quick Reference Card

Most frequently used scripts for daily DBA tasks:

```sql
-- User & Session Info
@who                    -- Current session and user information

-- Audit
@audit                  -- Recent audit events [AUDIT_ADMIN]
@logins                 -- Show login events [AUDIT_ADMIN]
@afails                 -- Failed login attempts [AUDIT_ADMIN]
@apol                   -- List audit policies [AUDIT_ADMIN]

-- Encryption (TDE)
@tde                    -- TDE configuration status [DBA]
@tdeops                 -- TDE operations progress [DBA]
```

## Script Categories

### Database Information

Basic database and session information scripts:

| Script                | Alias       | Privilege | Description                    |
|-----------------------|-------------|-----------|--------------------------------|
| `db_info.sql`         | -           | Any       | Database name, version, status |
| `sec_whoami_show.sql` | `who.sql`   | Any       | Current session identity, roles, container, auth method |
| `mon_sessions.sql`    | `sess.sql`  | Any       | Active database sessions       |
| `mon_locks.sql`       | `locks.sql` | Any       | Current locks and blocking     |

: Database Information SQL Scripts

**Usage Examples:**

```sql
-- Show database information
SQL> @db_info

-- Check who you are
SQL> @who

-- View active sessions
SQL> @sess
```

### Space and Storage

Tablespace and storage management:

| Script          | Alias       | Privilege | Description                     |
|-----------------|-------------|-----------|---------------------------------|
| `dba_space.sql` | `space.sql` | DBA       | Tablespace usage and free space |
| `dba_temp.sql`  | `temp.sql`  | DBA       | Temporary tablespace usage      |

**Usage Examples:**

```sql
-- Check tablespace usage
SQL> @space

-- Monitor temp space
SQL> @temp
```

### Security Scripts

User and privilege management:

| Script                  | Alias       | Privilege | Description                        |
|-------------------------|-------------|-----------|------------------------------------|
| `sec_whoami_show.sql`   | `who.sql`   | Any       | Current session and user info      |
| `sec_users.sql`         | `users.sql` | DBA       | List all database users            |
| `sec_roles.sql`         | `roles.sql` | DBA       | Show role hierarchy and grants     |
| `sec_privs.sql`         | `privs.sql` | Any       | Show privileges for current user   |
| `sec_obj_grants.sql`    | `objgr.sql` | Any       | Object privileges for current user |
| `sec_profiles.sql`      | `prof.sql`  | DBA       | Password profiles and settings     |
| `sec_failed_logins.sql` | `fails.sql` | DBA       | Recent failed login attempts       |

: Security SQL Scripts

**Usage Examples:**

```sql
-- Check current user info
SQL> @who

-- List all database users
SQL> @users

-- Check your privileges
SQL> @privs

-- View failed logins
SQL> @fails
```

### Audit Scripts

Unified audit query and analysis:

| Script                | Alias        | Privilege    | Description                        |
|-----------------------|--------------|--------------|------------------------------------|
| `aud_config.sql`      | `audit.sql`  | AUDIT_VIEWER | Audit configuration and trail info |
| `aud_policies.sql`    | `apol.sql`   | AUDIT_VIEWER | List audit policies and status     |
| `aud_sessions.sql`    | `asess.sql`  | AUDIT_VIEWER | Show all audit sessions            |
| `aud_events.sql`      | `aevt.sql`   | AUDIT_VIEWER | Recent audit events overview       |
| `aud_logins.sql`      | `logins.sql` | AUDIT_VIEWER | Show all login events              |
| `aud_failed.sql`      | `afails.sql` | AUDIT_VIEWER | Failed login attempts              |
| `aud_top_users.sql`   | -            | AUDIT_VIEWER | Top audit events by user           |
| `aud_top_actions.sql` | -            | AUDIT_VIEWER | Top audit events by action         |

**Audit Management Scripts:**

| Script                     | Privilege   | Description                      |
|----------------------------|-------------|----------------------------------|
| `cr_aud_policies_aud.sql`  | AUDIT_ADMIN | Create custom audit policies     |
| `en_aud_policies_aud.sql`  | AUDIT_ADMIN | Enable custom audit policies     |
| `dis_aud_policies_aud.sql` | AUDIT_ADMIN | Disable all audit policies       |
| `gen_aud_enable.sql`       | AUDIT_ADMIN | Generate AUDIT POLICY statements |

: Audit SQL Scripts

**Usage Examples:**

```sql
-- Check audit configuration
SQL> @audit

-- View recent audit events
SQL> @aevt

-- Check failed logins
SQL> @afails

-- See top audit events by user
SQL> @aud_top_users
```

### Audit Script Inventory

<!-- markdownlint-disable MD013 -->

Complete inventory of all audit-specific SQL scripts organized by category.

#### Policy Management

Scripts to create, enable, disable, and drop audit policies.

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_policies_create_aud.sql` | Create custom local audit policies (OraDBA generic template with ORADBA_LOC_* prefix) | AUDIT_ADMIN |
| `aud_policies_create_aud_oracle.sql` | Oracle default (ORA_*) predefined audit policies reference | AUDIT_VIEWER |
| `aud_policies_drop_aud.sql` | Disable all audit policies and drop all non-Oracle-maintained policies | AUDIT_ADMIN |
| `aud_policies_enable_aud.sql` | Enable custom local audit policies (OraDBA generic, ORADBA_LOC_* policies) | AUDIT_ADMIN |
| `aud_policies_show_aud.sql` | Show all local audit policies with enabled status, WHEN condition, and entity details | AUDIT_VIEWER |
| `aud_policies_gen_create_aud.sql` | Generate CREATE AUDIT POLICY statements from current enabled policies | AUDIT_VIEWER |
| `aud_policies_gen_disable_aud.sql` | Generate NOAUDIT statements for all currently enabled policies | AUDIT_VIEWER |
| `aud_policies_gen_drop_aud.sql` | Generate DROP AUDIT POLICY statements for all non-Oracle-maintained policies | AUDIT_VIEWER |
| `aud_policies_gen_enable_aud.sql` | Generate AUDIT POLICY statements from current enabled policies | AUDIT_VIEWER |
| `odb_audit_ctx_create_aud.sql` | Create ODB Application Context with WLS Classic and K8s Regex patterns (PROD) | AUDIT_ADMIN |
| `odb_policies_enable_aud.sql` | Enable ODB audit policies Phase A+B with dynamic user resolution (PROD) | AUDIT_ADMIN |

: Audit Policy Management Scripts

#### Configuration and Health

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_init_full_aud.sql` | Initialize audit environment: create tablespace, move trail, create purge/archive jobs | SYSDBA |
| `aud_config_show_aud.sql` | Show audit trail configuration: table sizes, record counts, trail statistics | AUDIT_VIEWER |
| `aud_health_show_aud.sql` | Single-screen operational health dashboard: mode, trail volume, purge config, top users | AUDIT_VIEWER |
| `aud_report_config_aud.sql` | Comprehensive audit configuration report (mode, parameters, tablespace, trail, purge jobs) | AUDIT_VIEWER |
| `aud_report_full_aud.sql` | Run a full suite of audit report queries (trail overview, top-N, trail analysis) | AUDIT_VIEWER |

: Audit Configuration and Health Scripts

#### Session and Login Analysis

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_logins_show_aud.sql` | Show login events from the unified audit trail | AUDIT_VIEWER |
| `aud_logins_failed_aud.sql` | Show failed login events from the unified audit trail | AUDIT_VIEWER |
| `aud_session_ctx_show_aud.sql` | Analyse available USERENV session context attributes for audit policy WHEN clauses | AUDIT_VIEWER |
| `aud_session_detail_show_aud.sql` | Show all audit entries for a given unified audit session ID | AUDIT_VIEWER |
| `aud_session_sql_detail_show_aud.sql` | Show audit entries for a given session with SQL_TEXT column included | AUDIT_VIEWER |
| `aud_sessions_show_aud.sql` | Show audit sessions for any audit type (parameterized) | AUDIT_VIEWER |
| `aud_sessions_std_show_aud.sql` | Show audit sessions for Standard audit type | AUDIT_VIEWER |
| `aud_sessions_datapump_show_aud.sql` | Show audit sessions for Datapump audit type | AUDIT_VIEWER |
| `aud_sessions_dbv_show_aud.sql` | Show audit sessions for Database Vault audit type | AUDIT_VIEWER |
| `aud_sessions_fga_show_aud.sql` | Show audit sessions for Fine Grained Audit type | AUDIT_VIEWER |
| `aud_sessions_rman_show_aud.sql` | Show audit sessions for RMAN audit type | AUDIT_VIEWER |
| `aud_sysdba_show_aud.sql` | Show SYSDBA and SYSOPER privileged access events from the unified audit trail | AUDIT_VIEWER |

: Audit Session and Login Analysis Scripts

#### Event Detail Queries

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_critobj_show_aud.sql` | Show recently accessed critical objects | AUDIT_VIEWER |
| `aud_critprivs_show_aud.sql` | Show recently used critical privileges | AUDIT_VIEWER |
| `aud_ddl_show_aud.sql` | Show recent DDL events (CREATE/ALTER/DROP/TRUNCATE/RENAME) | AUDIT_VIEWER |
| `aud_grants_show_aud.sql` | Show recently granted privileges | AUDIT_VIEWER |
| `aud_returncode_show_aud.sql` | Show failed operations grouped by return code (excludes ORA-00000) | AUDIT_VIEWER |

: Audit Event Detail Query Scripts

#### Storage and Trail Analysis

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_storage_usage_aud.sql` | Show unified audit trail storage usage | AUDIT_VIEWER |
| `aud_storage_purge_gen_aud.sql` | Generate unified audit trail storage purge statements | AUDIT_ADMIN |
| `aud_storage_usage_mod_gen_aud.sql` | Generate audit trail storage modification statements (move/resize) | AUDIT_ADMIN |
| `aud_tabsize_show_aud.sql` | Show unified audit trail table and partition sizes | AUDIT_VIEWER |

: Audit Storage and Trail Scripts

#### Top-N Analysis

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_top_action_aud.sql` | Show top audit events by action name | AUDIT_VIEWER |
| `aud_top_clientprog_aud.sql` | Show top audit events by client program name | AUDIT_VIEWER |
| `aud_top_dbid_aud.sql` | Show top audit events by DBID | AUDIT_VIEWER |
| `aud_top_host_aud.sql` | Show top audit events by user host | AUDIT_VIEWER |
| `aud_top_object_aud.sql` | Show top audit events by object name | AUDIT_VIEWER |
| `aud_top_object_user_aud.sql` | Show top audit events by object name (excluding Oracle maintained schemas) | AUDIT_VIEWER |
| `aud_top_osuser_aud.sql` | Show top audit events by OS username | AUDIT_VIEWER |
| `aud_top_owner_aud.sql` | Show top audit events by object schema (owner) | AUDIT_VIEWER |
| `aud_top_policy_aud.sql` | Show top audit events by unified_audit_policies | AUDIT_VIEWER |
| `aud_top_policy_detail_aud.sql` | Show top audit events by policy, user, and action combined | AUDIT_VIEWER |
| `aud_top_returncode_aud.sql` | Show top-N error codes from the unified audit trail (excludes success) | AUDIT_VIEWER |
| `aud_top_user_aud.sql` | Show top audit events by DB username | AUDIT_VIEWER |

: Audit Top-N Analysis Scripts

#### Trail Volume Analysis

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_trail_analysis_aud.sql` | Comprehensive trail analysis for concept optimization: volume trend, action/user distribution, noise candidates, policy coverage gaps | AUDIT_VIEWER |
| `aud_trail_userhost_analysis_aud.sql` | Detailed user-host analysis to identify connection patterns for logon trigger regex design | AUDIT_VIEWER |

: Audit Trail Volume Analysis Scripts

#### Splunk Integration

Scripts for configuring Splunk archive timestamp management.

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `aud_splunk_at_detection_setup.sql` | Set up Splunk archive timestamp management using Audit Trail Detection (K-AT pattern) | AUDIT_ADMIN |
| `aud_splunk_checkpoint_setup.sql` | Set up Splunk archive timestamp management using Watchdog Checkpoint (K-WD pattern) | AUDIT_ADMIN |

: Splunk Integration Scripts

#### Utility and Session Helpers

| Script | Purpose | Privilege |
|--------|---------|-----------|
| `audit.sql` | Alias for `aud_config_show_aud.sql` (shortcut for interactive use) | AUDIT_VIEWER |
| `auditpdb.sql` | Switch session container directly to AUDITPDB1 | DBA |
| `env.sql` | Show full session environment: DB version, audit mode, NLS, session identity, SQLPATH | Any |
| `env_show_sqlpath.sql` | Show current SQLPATH directories with existence check (called by env.sql) | Any |
| `pdb.sql` | Switch session container to a given PDB (parameterized, default AUDITPDB1) | DBA |
| `sec_whoami_show.sql` | Show current session identity: user, schema, roles, container, authentication method | Any |

: Audit Utility and Session Helper Scripts

<!-- markdownlint-enable MD013 -->

### TDE (Transparent Data Encryption) Scripts

Encryption management and monitoring:

| Script             | Alias         | Privilege | Description                 |
|--------------------|---------------|-----------|-----------------------------|
| `tde_info.sql`     | `tde.sql`     | DBA       | TDE configuration status    |
| `tde_keys.sql`     | `keys.sql`    | SYSDBA    | Master encryption keys info |
| `tde_wallets.sql`  | `wallets.sql` | DBA       | Keystore/wallet status      |
| `tde_enc_cols.sql` | -             | DBA       | Show encrypted columns      |
| `tde_enc_tbs.sql`  | -             | DBA       | Show encrypted tablespaces  |
| `tde_ops.sql`      | `tdeops.sql`  | DBA       | TDE operations progress     |

**TDE Setup Scripts:**

| Script                    | Privilege | Description                             |
|---------------------------|-----------|-----------------------------------------|
| `cr_tde_sys.sql`          | SYSDBA    | Initialize TDE for database             |
| `cr_tde_keystore_sys.sql` | SYSDBA    | Create software keystore                |
| `cr_tde_key_sys.sql`      | SYSDBA    | Create master encryption key            |
| `gen_tde_encrypt.sql`     | DBA       | Generate datafile encryption statements |

: Transparent Data Encryption (TDE) SQL Scripts

**Usage Examples:**

```sql
-- Check TDE configuration
SQL> @tde

-- View master keys
SQL> @keys

-- Check keystore status
SQL> @wallets

-- Monitor TDE operations
SQL> @tdeops
```

### Monitoring Scripts

Database monitoring and diagnostics:

| Script             | Alias        | Privilege | Description                   |
|--------------------|--------------|-----------|-------------------------------|
| `mon_sessions.sql` | `sess.sql`   | Any       | Show active sessions          |
| `mon_locks.sql`    | `locks.sql`  | Any       | Current locks and blocking    |
| `mon_sqlmon.sql`   | `sqlmon.sql` | Any       | SQL Monitor active executions |
| `dba_jobs.sql`     | `jobs.sql`   | DBA       | Scheduler jobs status         |

### Administration Scripts

General DBA tasks:

| Script           | Alias        | Privilege | Description                                 |
|------------------|--------------|-----------|---------------------------------------------|
| `dba_params.sql` | `params.sql` | DBA       | Show all init parameters (including hidden) |
| `dba_space.sql`  | `space.sql`  | DBA       | Tablespace usage                            |
| `dba_temp.sql`   | `temp.sql`   | DBA       | Temp tablespace usage                       |
| `dba_jobs.sql`   | `jobs.sql`   | DBA       | Scheduler jobs                              |

## Common Usage Patterns

### Quick Health Check

```sql
-- Connect and check database status
sqlplus / as sysdba
SQL> @db_info      -- Database info
SQL> @space        -- Tablespace usage
SQL> @temp         -- Temp space
SQL> @sess         -- Active sessions
SQL> @locks        -- Check for blocking
```

### Security Audit

```sql
-- Review security configuration
SQL> @users        -- All database users
SQL> @roles        -- Role hierarchy
SQL> @sec_users_dba  -- Detailed user info
SQL> @fails        -- Failed logins
SQL> @prof         -- Password profiles
```

### Unified Audit Analysis

```sql
-- Review audit trail
SQL> @audit        -- Audit configuration
SQL> @apol         -- Audit policies
SQL> @aevt         -- Recent events
SQL> @logins       -- Login events
SQL> @afails       -- Failed logins
SQL> @aud_top_users  -- Top users
SQL> @aud_top_actions  -- Top actions
```

### TDE Status Check

```sql
-- Check encryption status
SQL> @tde          -- TDE configuration
SQL> @wallets      -- Keystore status
SQL> @keys         -- Master keys
SQL> @tde_enc_tbs  -- Encrypted tablespaces
SQL> @tdeops       -- Operations in progress
```

## Custom SQL Scripts

### Adding Your Own Scripts

Place custom scripts in `SQLPATH`:

```bash
# Create custom script
cat > $SQLPATH/my_report.sql <<'EOF'
-- Custom Report
SET PAGESIZE 50
SELECT username, account_status, profile
FROM dba_users
WHERE account_status != 'OPEN'
ORDER BY username;
EOF

# Use it
sqlplus / as sysdba @my_report
```

### Script Template

```sql
-- ------------------------------------------------------------------------------
-- Script......: my_script.sql
-- Author......: Your Name
-- Date........: YYYY-MM-DD
-- Purpose.....: Brief description of what this script does
-- Notes.......: Any special requirements or notes
-- Usage.......: @my_script [parameter]
-- Requires....: DBA role
-- ------------------------------------------------------------------------------

SET PAGESIZE 100
SET LINESIZE 200
SET VERIFY OFF
SET FEEDBACK ON

-- Your SQL here
SELECT ...
FROM ...
WHERE ...;

-- Clean up
SET VERIFY ON
```

## Best Practices

1. **Check privileges** - Review required privileges before running scripts
2. **Use aliases** - Learn common aliases for faster access
3. **Test in dev first** - Test scripts in non-production environments
4. **Review generated SQL** - Check generated statements before execution
5. **Use sessionsql** - Better formatting with automatic terminal sizing
6. **Add custom scripts** - Place your scripts in SQLPATH
7. **Follow naming conventions** - Use consistent naming for custom scripts

## Troubleshooting

### Script Not Found

```bash
# Check SQLPATH
echo $SQLPATH

# Verify script exists
ls -l $SQLPATH/db_info.sql

# Use full path if needed
sqlplus / as sysdba @$SQLPATH/db_info.sql
```

### Insufficient Privileges

```sql
-- Check your privileges
SQL> @who
SQL> @privs

-- Most scripts indicate required privileges in filename or header
-- _dba = DBA role required
-- _sys = SYSDBA required
-- _aud = AUDIT_ADMIN or AUDIT_VIEWER required
```

### Output Formatting Issues

```sql
-- Use sessionsql for better formatting
sessionsql @my_script

-- Or adjust SQL*Plus settings
SQL> SET LINESIZE 200
SQL> SET PAGESIZE 100
SQL> @my_script
```

<!-- Web-only sections below: kept for MkDocs navigation, stripped during PDF build (build_pdf.sh). -->
## See Also {.unlisted .unnumbered}

- [RMAN Scripts](rman-scripts.md) - Backup and recovery templates
- [Functions Reference](functions.md) - Database functions library
- [Quick Start](quickstart.md) - Common SQL script examples
- [Troubleshooting](troubleshooting.md) - Solving script issues

## Navigation {.unlisted .unnumbered}

**Previous:** [Aliases Reference](aliases.md)  
**Next:** [RMAN Script Templates](rman-scripts.md)
