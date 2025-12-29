# SQL Scripts Reference

**Purpose:** Complete reference for OraDBA's SQL scripts collection for database administration, security, audit, and
encryption tasks.

**Audience:** DBAs needing ready-to-use SQL scripts for common database tasks.

## Introduction

OraDBA includes a comprehensive collection of SQL scripts for database
administration, focusing on security, audit, encryption, and general DBA tasks.
Scripts are organized by topic and follow consistent naming conventions for
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
| `sec_whoami_show.sql` | `who.sql`   | Any       | Current session info           |
| `mon_sessions.sql`    | `sess.sql`  | Any       | Active database sessions       |
| `mon_locks.sql`       | `locks.sql` | Any       | Current locks and blocking     |

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

## See Also

- [RMAN Scripts](09-rman-scripts.md) - Backup and recovery templates
- [Functions Reference](10-functions.md) - Database functions library
- [Quick Reference](13-reference.md) - Common SQL script examples
- [Troubleshooting](12-troubleshooting.md) - Solving script issues

## Navigation

**Previous:** [PDB Alias Reference](07-pdb-aliases.md)  
**Next:** [RMAN Script Templates](09-rman-scripts.md)
