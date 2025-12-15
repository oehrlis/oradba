# OraDBA SQL Tools and Reporting
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->
## General Information

A number of SQL scripts as well as SQL Developer Reports for various DBA
activities are available in this directory. The scripts focus on setup,
configuration and analysis of database security topics such as Oracle Unified
Audit, Oracle Centrally Managed Users, Advanced Security, Authentication,
Authorisation, Encryption and more.. An updated version of the scripts is
available via GitHub on [oehrli/oradba](https://github.com/oehrlis/oradba).

## Naming Concept Summary

### Core Principles

1. **Short and Intuitive**: 3-8 character base names for common scripts
2. **Action-Object Pattern**: `<action>_<object>.sql` or just `<object>.sql` for queries
3. **Common Aliases**: 2-5 character shortcuts for frequently used scripts
4. **Focus Areas**: DBA infrastructure, security, audit, encryption, user management

### Script Naming Convention

Scripts follow a simplified two-part format:

- **Query/Show Scripts**: `<object>.sql` or `ls_<object>.sql`
- **Action Scripts**: `<verb>_<object>.sql`

### Action Verbs (SQL-Style Operations)

Familiar database operation verbs:

| Verb | SQL Command | Usage Example          | Description                      |
|------|-------------|------------------------|----------------------------------|
| cr   | CREATE      | cr_aud_policies.sql    | Create objects/configuration     |
| dr   | DROP        | dr_aud_policies.sql    | Drop/remove objects              |
| up   | UPDATE      | up_sec_profile.sql     | Update/alter configuration       |
| en   | ENABLE      | en_aud_policies.sql    | Enable features/policies         |
| dis  | DISABLE     | dis_aud_policies.sql   | Disable features/policies        |
| gr   | GRANT       | gr_sec_privs.sql       | Grant privileges                 |
| gen  | GENERATE    | gen_aud_stmts.sql      | Generate SQL statements          |
| -    | SELECT      | aud_sessions.sql       | Query/show info (no prefix)      |

### Topic Categories

Organized by DBA focus areas:

| Category | Prefix | Examples                    | Description                      |
|----------|--------|-----------------------------|----------------------------------|
| Security | sec    | sec_users, sec_roles        | User, role, privilege management |
| Audit    | aud    | aud_sessions, aud_events    | Unified & traditional audit      |
| Encrypt  | tde    | tde_info, tde_keys          | Transparent Data Encryption      |
| Admin    | dba    | dba_space, dba_backup       | General DBA tasks                |
| Monitor  | mon    | mon_sessions, mon_locks     | Monitoring and diagnostics       |

### Privilege Indicators

Optional suffix to indicate required privilege level:

| Suffix | Privilege    | Example                  | Usage                            |
|--------|--------------|--------------------------|----------------------------------|
| (none) | Regular User | sec_whoami.sql           | Accessible by regular users      |
| _dba   | DBA Role     | sec_users_dba.sql        | Requires DBA or SYSTEM           |
| _sys   | SYSDBA       | tde_keystore_sys.sql     | Requires SYSDBA/SYSKM/SYSBACKUP  |
| _aud   | Audit Admin  | aud_config_aud.sql       | Requires AUDIT_ADMIN/AUDIT_VIEWER|

**Usage Guidelines:**

- Add suffix only when elevated privileges are required
- Query scripts without suffix can run with minimal privileges
- Action scripts (cr, dr, up, en, dis) typically need DBA or SYSDBA privileges
- Document exact privilege requirements in script header comments

### Common Aliases

Super-short 2-5 character aliases for most frequently used scripts:

| Alias     | Full Name           | Purpose                           |
|-----------|---------------------|-----------------------------------|
| who       | sec_whoami.sql      | Current user session info         |
| users     | sec_users.sql       | List database users               |
| roles     | sec_roles.sql       | Show role grants                  |
| privs     | sec_privs.sql       | Show privileges                   |
| audit     | aud_events.sql      | Recent audit events               |
| sess      | aud_sessions.sql    | Audit session overview            |
| tde       | tde_info.sql        | TDE configuration status          |
| keys      | tde_keys.sql        | TDE key information               |
| space     | dba_space.sql       | Tablespace usage                  |
| locks     | mon_locks.sql       | Current database locks            |

### Naming Examples and Best Practices

#### Good Examples (Short, Clear, Intuitive)

| Old Name (Verbose)                   | New Name (Improved)      | Why Better                    |
|--------------------------------------|--------------------------|-------------------------------|
| create_local_unified_audit_policies  | cr_aud_policies_dba.sql  | SQL-style verb, clear privs   |
| saua_asdetsql.sql                    | aud_sess_detail.sql      | Readable, no cryptic acronyms |
| sdsec_sysobj.sql                     | sec_sys_grants.sql       | Clear what it shows           |
| isenc_tde_pdbiso_keyadmin.sql        | cr_tde_keystore_sys.sql  | SQL verb, privilege indicated |
| sdua_enpolstm.sql                    | gen_aud_enable.sql       | Generate is SQL-friendly      |

#### Naming Patterns by Use Case

**Query/Display (SELECT - Read-Only)**:

```text
<category>_<object>[_priv].sql        # e.g., aud_sessions.sql, sec_users_dba.sql
<object>.sql                           # e.g., sessions.sql (generic, no category)
```

**Create Objects (CREATE)**:

```text
cr_<category>_<object>[_priv].sql     # e.g., cr_aud_policies_dba.sql, cr_tde_keystore_sys.sql
```

**Drop/Remove (DROP)**:

```text
dr_<category>_<object>[_priv].sql     # e.g., dr_aud_policies_dba.sql, dr_sec_role_sys.sql
```

**Update/Modify (UPDATE/ALTER)**:

```text
up_<category>_<object>[_priv].sql     # e.g., up_sec_profile_dba.sql, up_tde_wallet_sys.sql
```

**Enable Features (ENABLE)**:

```text
en_<category>_<object>[_priv].sql     # e.g., en_aud_policies_aud.sql, en_tde_sys.sql
```

**Disable Features (DISABLE)**:

```text
dis_<category>_<object>[_priv].sql    # e.g., dis_aud_policies_aud.sql
```

**Grant Privileges (GRANT)**:

```text
gr_<category>_<object>[_priv].sql     # e.g., gr_sec_privs_dba.sql
```

**Generate Statements (GENERATE)**:

```text
gen_<category>_<action>.sql           # e.g., gen_aud_enable.sql, gen_tde_encrypt.sql
```

**Note**: `[_priv]` is optional and added only when elevated privileges required.

#### Category Prefix Guidelines

Use clear, short prefixes for logical grouping:

- **sec_**: Security, users, roles, privileges, authentication
- **aud_**: Unified and traditional audit
- **tde_**: Transparent Data Encryption, keystores, keys
- **dba_**: General DBA tasks (space, backup, jobs)
- **mon_**: Monitoring (sessions, locks, performance)
- **pdb_**: PDB-specific operations
- **cdb_**: CDB-specific operations

#### Alias Creation Rules

1. **Common Scripts** (used daily): 3-5 chars (who, users, sess, locks)
2. **Frequent Scripts** (used weekly): 4-7 chars (audit, privs, space)
3. **Specialized Scripts**: No alias needed
4. **Aliases Should Be**:
   - Intuitive (who = whoami, sess = sessions)
   - No more than 7 characters
   - Avoid cryptic abbreviations
   - Omit action verbs and privilege suffixes (aliases are for convenience)
   - Focus on the object being queried or modified

**Example**: `cr_aud_policies_dba.sql` → alias: `crpol.sql` or just document as "use main name"

## Quick Reference Card

Most frequently used scripts for daily DBA tasks:

```sql
-- User & Session Info (User = any user, DBA = DBA role required)
@who                    -- Who am I? (current session info) [User]
@users                  -- List all database users [DBA]
@sess                   -- Show active sessions [User]

-- Security & Privileges
@privs                  -- Show privileges for current user [User]
@roles                  -- Show role hierarchy [DBA]
@objgr                  -- Show object grants for current user [User]

-- Audit (AUD = AUDIT_ADMIN or AUDIT_VIEWER role required)
@audit                  -- Recent audit events [AUD]
@logins                 -- Show login events [AUD]
@afails                 -- Failed login attempts [AUD]
@apol                   -- List audit policies [AUD]

-- Encryption (TDE)
@tde                    -- TDE configuration status [DBA]
@keys                   -- Master encryption keys [SYSDBA]
@wallets                -- Keystore status [DBA]
@tdeops                 -- TDE operations progress [DBA]

-- Database Administration
@space                  -- Tablespace usage [DBA]
@temp                   -- Temp space usage [DBA]
@locks                  -- Current locks & blocking [User]
@jobs                   -- Scheduler jobs status [DBA]
@params                 -- Init parameters (including hidden) [DBA]

-- Privilege Legend
-- [User]   = Regular user, minimal privileges
-- [DBA]    = DBA role or SYSTEM user
-- [SYSDBA] = SYSDBA, SYSKM, SYSBACKUP, etc.
-- [AUD]    = AUDIT_ADMIN or AUDIT_VIEWER role
```

## Generic DBA Activities

The following SQL scripts are available.

| Script                 | Alias        | Privs | Purpose                                 |
|------------------------|--------------|-------|-----------------------------------------|
| [dba_params.sql]       | [params.sql] | DBA   | Show all (hidden & regular) init params |
| [dba_space.sql]        | [space.sql]  | DBA   | Show tablespace usage and free space    |
| [dba_temp.sql]         | [temp.sql]   | DBA   | Show temp tablespace usage              |
| [dba_jobs.sql]         | [jobs.sql]   | DBA   | Show scheduler jobs status              |
| [mon_sessions.sql]     | [sess.sql]   | User  | Show active database sessions           |
| [mon_sessions_dba.sql] |              | DBA   | Show all sessions with detailed info    |
| [mon_locks.sql]        | [locks.sql]  | User  | Show current locks and blocking         |
| [mon_sqlmon.sql]       | [sqlmon.sql] | User  | SQL Monitor active/recent executions    |

## Oracle Database Security

### SQL Script Use Cases and Filenames

The following SQL scripts are available.

| Script                   | Alias         | Privs  | Purpose                                    |
|--------------------------|---------------|--------|--------------------------------------------||
| [sec_whoami.sql]         | [who.sql]     | User   | Show current session and user information  |
| [sec_users.sql]          | [users.sql]   | DBA    | List all database users with attributes    |
| [sec_users_dba.sql]      |               | DBA    | Detailed user info with password history   |
| [sec_roles.sql]          | [roles.sql]   | DBA    | Show role hierarchy and grants             |
| [sec_privs.sql]          | [privs.sql]   | User   | Show privileges for current user           |
| [sec_privs_dba.sql]      |               | DBA    | Show system privileges by user/role        |
| [sec_obj_grants.sql]     | [objgr.sql]   | User   | Show object privileges for current user    |
| [sec_obj_grants_dba.sql] |               | DBA    | Show all object privileges in database     |
| [sec_sys_grants.sql]     | [sysgr.sql]   | DBA    | Show SYS schema object grants              |
| [sec_profiles.sql]       | [prof.sql]    | DBA    | Show password profiles and settings        |
| [sec_failed_logins.sql]  | [fails.sql]   | DBA    | Show recent failed login attempts          |
| [cr_sec_role_dba.sql]    |               | DBA    | Create restricted DBA role with privs      |
| [cr_sec_pwfunc_dba.sql]  |               | DBA    | Create custom password verify function     |
| [up_sec_pwfunc_dba.sql]  |               | DBA    | Test password verify function with samples |

### SQL Developer Reports

not yet available

## Oracle Unified Audit

### SQL Script Use Cases and Filenames

#### Query & Analysis Scripts

| Script                  | Alias         | Privs | Purpose                                     |
|-------------------------|---------------|-------|---------------------------------------------|
| [aud_config.sql]        | [audit.sql]   | AUD   | Show audit configuration and trail info     |
| [aud_policies.sql]      | [apol.sql]    | AUD   | List audit policies and their status        |
| [aud_sessions.sql]      | [asess.sql]   | AUD   | Show all audit sessions (standard type)     |
| [aud_sess_rman.sql]     |               | AUD   | Show RMAN backup audit sessions             |
| [aud_sess_dp.sql]       |               | AUD   | Show Data Pump audit sessions               |
| [aud_sess_dbv.sql]      |               | AUD   | Show Database Vault audit sessions          |
| [aud_sess_fga.sql]      |               | AUD   | Show Fine-Grained Audit sessions            |
| [aud_sess_detail.sql]   | [asdet.sql]   | AUD   | Show detailed entries for specific session  |
| [aud_events.sql]        | [aevt.sql]    | AUD   | Recent audit events overview                |
| [aud_logins.sql]        | [logins.sql]  | AUD   | Show all login events                       |
| [aud_failed.sql]        | [afails.sql]  | AUD   | Show failed login attempts                  |
| [aud_grants.sql]        |               | AUD   | Show recently granted privileges            |
| [aud_crit_obj.sql]      |               | AUD   | Show critical object access events          |
| [aud_crit_priv.sql]     |               | AUD   | Show critical privilege usage events        |
| [aud_new_users.sql]     |               | AUD   | Show recently created users                 |
| [aud_storage.sql]       |               | DBA   | Show audit trail storage and partition size |
| [aud_report.sql]        |               | AUD   | Generate comprehensive audit report         |

#### Top Events Analysis

| Script                  | Alias         | Privs | Purpose                              |
|-------------------------|---------------|-------|--------------------------------------|
| [aud_top_users.sql]     | [atop_usr.sql]| AUD   | Top audit events by database user    |
| [aud_top_actions.sql]   | [atop_act.sql]| AUD   | Top audit events by action name      |
| [aud_top_objects.sql]   | [atop_obj.sql]| AUD   | Top audit events by object name      |
| [aud_top_policies.sql]  | [atop_pol.sql]| AUD   | Top audit events by audit policy     |
| [aud_top_clients.sql]   |               | AUD   | Top audit events by client program   |
| [aud_top_hosts.sql]     |               | AUD   | Top audit events by user host        |
| [aud_top_osusers.sql]   |               | AUD   | Top audit events by OS username      |
| [aud_top_schemas.sql]   |               | AUD   | Top audit events by object schema    |
| [aud_top_dbids.sql]     |               | AUD   | Top audit events by database ID      |

#### Configuration & Management Scripts

| Script                  | Alias         | Privs  | Purpose                                       |
|-------------------------|---------------|--------|-----------------------------------------------|
| [cr_aud_init_dba.sql]   |               | DBA    | Initialize audit environment (tbs, jobs)      |
| [cr_aud_policies_aud.sql]|              | AUD    | Create custom audit policies                  |
| [en_aud_policies_aud.sql]|              | AUD    | Enable custom audit policies                  |
| [dis_aud_policies_aud.sql]|             | AUD    | Disable all audit policies                    |
| [dr_aud_policies_aud.sql]|              | AUD    | Drop all non-Oracle maintained policies       |

#### Statement Generators

| Script                  | Alias         | Privs | Purpose                                   |
|-------------------------|---------------|-------|-------------------------------------------|
| [gen_aud_create.sql]    |               | DBA   | Generate CREATE AUDIT POLICY statements   |
| [gen_aud_enable.sql]    |               | AUD   | Generate AUDIT POLICY ENABLE statements   |
| [gen_aud_disable.sql]   |               | AUD   | Generate NOAUDIT POLICY statements        |
| [gen_aud_drop.sql]      |               | AUD   | Generate DROP AUDIT POLICY statements     |
| [gen_aud_purge.sql]     |               | DBA   | Generate audit trail purge statements     |
| [gen_aud_storage.sql]   |               | DBA   | Generate storage modification statements  |

### SQL Developer Reports

Predefined reports for Unified Audit Assessment available via
[unified_audit_reports.xml](https://github.com/oehrlis/oradba/blob/b4bc6e713405e8836e21532b6e0cd4075a576848/sql/unified_audit_reports.xml)

The scripts are divided into the following categories for easier organisation.

- **Generic Audit**
- **Audit Configuration**
- **Audit Sessions**
- **Generate Statements**
- **Top Audit Events**

| Folder              | Report                                      | Purpose                                                                                                                                |
|---------------------|---------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| Generic             | Audit Events by Day                         | Chart with number of Audit events by days with a couple of subqueries for history, by hour or DB Info                                  |
| Generic             | Audit Events by User                        | Chart with number of Audit events by user with a couple of subqueries for history, by hour or DB Info                                  |
| Generic             | Audit Events by User                        | Show of Audit Events by Users with a couple of subqueries for audit policies, actions, clients and Policy                              |
| Audit Configuration | Audit Storage Usage                         | Information about the Audit storage usage and configuration.                                                                           |
| Audit Configuration | Clean Up Events                             | Displays the audit cleanup event history                                                                                               |
| Audit Configuration | Clean Up Jobs                               | Displays the currently configured audit trail purge jobs                                                                               |
| Audit Configuration | Configuration                               | Show current audit configuration parameter                                                                                             |
| Audit Configuration | Last Archive Timestamp                      | Displays the last archive timestamps set for the audit trails                                                                          |
| Audit Configuration | Unified Audit Policies                      | Display overview about unified audit policies based on the views AUDIT_UNIFIED_POLICIES and AUDIT_UNIFIED_ENABLED_POLICIES.            |
| Audit Sessions      | Proxy Sessions                              | Show information about proxy sessions for audit type Standard based on UNIFIED_AUDIT_TRAIL                                             |
| Audit Sessions      | Session by Audit Type Standard              | Show information about sessions for audit type Standard based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Session Details                             | Show details of a particular session                                                                                                   |
| Audit Sessions      | Session Overview                            | Overview of standard audit session                                                                                                     |
| Audit Sessions      | Sessions by any Audit Type                  | Show information about sessions any audit type based on UNIFIED_AUDIT_TRAIL                                                            |
| Audit Sessions      | Sessions by Audit Type Database Vault       | Show information about sessions for audit type Database Vault based on UNIFIED_AUDIT_TRAIL                                             |
| Audit Sessions      | Sessions by Audit Type Datapump             | Show information about sessions for audit type Datapump based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Sessions by Audit Type Direct path API      | Show information about sessions for audit type Direct path API based on UNIFIED_AUDIT_TRAIL                                            |
| Audit Sessions      | Sessions by Audit Type Fine Grained Audit   | Show information about sessions for audit type Fine Grained Audit based on UNIFIED_AUDIT_TRAIL                                         |
| Audit Sessions      | Sessions by Audit Type Protocol             | Show information about sessions for audit type Protocol based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Sessions by Audit Type RMAN_AUDIT           | Show information about sessions for audit type RMAN_AUDIT based on UNIFIED_AUDIT_TRAIL                                                 |
| Generate Statements | Create all Audit Policy                     | Generate statements to create all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES. Requires DBA privileges. |
| Generate Statements | Disable all Audit Policy                    | Generate statements to disable all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                         |
| Generate Statements | Drop all Audit Policy                       | Generate statements to drop all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                            |
| Generate Statements | Enable all Audit Policy                     | Generate statements to enable all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                          |
| Top Audit Events    | Top Audit Events by Action                  | Show top unified audit events by Action Name                                                                                           |
| Top Audit Events    | Top Audit Events by Application Context     | Show top unified audit events by Application Context                                                                                   |
| Top Audit Events    | Top Audit Events by Audit Type              | Show top unified audit events by Audit Type                                                                                            |
| Top Audit Events    | Top Audit Events by Client                  | Show top unified audit events by Client                                                                                                |
| Top Audit Events    | Top Audit Events by Client Program name     | Show top unified audit events by Client Program                                                                                        |
| Top Audit Events    | Top Audit Events by DBID                    | Show top unified audit events by Database ID                                                                                           |
| Top Audit Events    | Top Audit Events by External User ID        | Show top unified audit events by External User ID                                                                                      |
| Top Audit Events    | Top Audit Events by Global User ID          | Show top unified audit events by Global User ID                                                                                        |
| Top Audit Events    | Top Audit Events by Object Name             | Show top unified audit events by Object Name                                                                                           |
| Top Audit Events    | Top Audit Events by none Oracle Object Name | Show top unified audit events by Object Name without Oracle maintained schemas                                                         |
| Top Audit Events    | Top Audit Events by Object Schema           | Show top unified audit events by Object Schema                                                                                         |
| Top Audit Events    | Top Audit Events by OS User                 | Show top unified audit events by OS User                                                                                               |
| Top Audit Events    | Top Audit Events by Unified Policy          | Show top unified audit events by Unified Audit Policy                                                                                  |
| Top Audit Events    | Top Audit Events by SQL Text                | Show top unified audit events by SQL Text                                                                                              |
| Top Audit Events    | Top Audit Events by User                    | Show top unified audit events by User                                                                                                  |

## Oracle Advanced Security and Encryption

### SQL Script Use Cases and Filenames

#### Query & Status Scripts

| Script                  | Alias         | Privs  | Purpose                                    |
|-------------------------|---------------|--------|--------------------------------------------||
| [tde_info.sql]          | [tde.sql]     | DBA    | Show TDE configuration status and details  |
| [tde_keys.sql]          | [keys.sql]    | SYSDBA | Show master encryption keys information    |
| [tde_wallets.sql]       | [wallets.sql] | DBA    | Show keystore/wallet status                |
| [tde_enc_cols.sql]      |               | DBA    | Show encrypted columns in database         |
| [tde_enc_tbs.sql]       |               | DBA    | Show encrypted tablespaces                 |
| [tde_ops.sql]           | [tdeops.sql]  | DBA    | Show TDE operations from V$SESSION_LONGOPS |
| [tde_ops_run.sql]       |               | DBA    | Show running TDE operations                |
| [tde_ops_csv.sql]       |               | DBA    | Export TDE operations as CSV               |
| [tde_backup_jobs.sql]   |               | DBA    | Show keystore backup scheduler jobs        |

#### Setup & Configuration Scripts

| Script                     | Alias      | Privs  | Purpose                                    |
|----------------------------|------------|--------|--------------------------------------------||
| [cr_tde_sys.sql]           |            | SYSDBA | Initialize TDE for single/container DB     |
| [cr_tde_pdb_iso_sys.sql]   |            | SYSDBA | Initialize TDE for PDB (isolated wallet)   |
| [cr_tde_pdb_uni_sys.sql]   |            | SYSDBA | Initialize TDE for PDB (unified wallet)    |
| [up_tde_wallet_sys.sql]    |            | SYSDBA | Set WALLET_ROOT parameter (needs restart)  |
| [cr_tde_keystore_sys.sql]  |            | SYSDBA | Create software keystore in WALLET_ROOT    |
| [cr_tde_key_sys.sql]       |            | SYSDBA | Create master encryption key               |
| [cr_tde_backup_job_dba.sql]|            | DBA    | Create scheduler job for keystore backups  |
| [dr_tde_sys.sql]           |            | SYSDBA | Remove TDE configuration completely        |
| [dr_tde_backup_job_dba.sql]|            | DBA    | Remove keystore backup scheduler job       |
| [en_tde_lostkey_sys.sql]   |            | SYSDBA | Enable discard of lost master keys         |

#### Statement Generators

| Script                  | Alias      | Privs  | Purpose                                      |
|-------------------------|------------|--------|----------------------------------------------|
| [gen_tde_encrypt.sql]   |            | DBA    | Generate offline datafile encryption stmts   |
| [gen_tde_decrypt.sql]   |            | DBA    | Generate offline datafile decryption stmts   |
| [gen_tde_rekey.sql]     |            | DBA    | Generate tablespace rekey statements         |

#### Advanced PDB Setup

| Script                        | Alias   | Privs  | Purpose                               |
|-------------------------------|---------|--------|---------------------------------------|
| [cr_tde_pdb_iso_prep_sys.sql] |         | SYSDBA | Prepare PDB isolation mode            |
| [cr_tde_pdb_iso_key_sys.sql]  |         | SYSKM  | Create keystore in PDB (SYSKM phase)  |
