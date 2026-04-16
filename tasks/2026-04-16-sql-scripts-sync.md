# SQL Scripts Sync from ora-db-audit-eng Implementation Plan
<!-- markdownlint-disable -->

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sync updated and new SQL scripts from `ora-db-audit-eng/sql/` into `oradba/src/sql/` and update all documentation accordingly.

**Architecture:** Direct file copy for new scripts; diff-based selective update for modified scripts; documentation update in README.md and sql-scripts.md. Test scripts (tst_*) are excluded.

**Tech Stack:** SQL*Plus scripts, Markdown documentation, Bash diff tools.

---

## Overview: What Changes

### New scripts to add (18 files)

| Script | Category | Purpose |
|--------|----------|---------|
| `aud_ddl_show_aud.sql` | Event Detail | Show recent DDL events |
| `aud_health_show_aud.sql` | Config/Health | Operational health dashboard |
| `aud_policies_create_aud_oracle.sql` | Policy Mgmt | Oracle default (ORA_*) policies reference |
| `aud_report_config_aud.sql` | Config/Health | Comprehensive audit config report |
| `aud_returncode_show_aud.sql` | Event Detail | Show failed operations by return code |
| `aud_session_ctx_show_aud.sql` | Session/Login | Analyse USERENV context attributes |
| `aud_splunk_at_detection_setup.sql` | Splunk | Archive timestamp via AT detection |
| `aud_splunk_checkpoint_setup.sql` | Splunk | Archive timestamp via Watchdog checkpoint |
| `aud_sysdba_show_aud.sql` | Session/Login | Show SYSDBA/SYSOPER access events |
| `aud_top_returncode_aud.sql` | Top-N | Top-N error codes from audit trail |
| `aud_trail_analysis_aud.sql` | Trail Volume | Comprehensive trail analysis |
| `aud_trail_userhost_analysis_aud.sql` | Trail Volume | User-host analysis for regex design |
| `auditpdb.sql` | Utility | Switch session to AUDITPDB1 |
| `env.sql` | Utility | Show full session environment |
| `env_show_sqlpath.sql` | Utility | Show SQLPATH directories |
| `odb_audit_ctx_create_aud.sql` | Policy Mgmt | Create ODB application context (PROD) |
| `odb_policies_enable_aud.sql` | Policy Mgmt | Enable ODB audit policies (PROD) |
| `pdb.sql` | Utility | Switch session to a given PDB |

### Modified scripts to update (8 files)

| Script | Key Change |
|--------|-----------|
| `aud_config_show_aud.sql` | Uses `dba_fga_audit_trail` instead of `sys.fga_log$` (no SYS access needed) |
| `aud_critobj_show_aud.sql` | Improved parameter handling with defaults |
| `aud_critprivs_show_aud.sql` | Improved parameter handling with defaults |
| `aud_grants_show_aud.sql` | Missing `SPOOL OFF` added |
| `aud_policies_show_aud.sql` | Significant formatting/ordering improvements |
| `aud_report_full_aud.sql` | References new trail analysis scripts |
| `aud_top_policy_detail_aud.sql` | Column header fix (`Policies` → `User`) |
| `sec_whoami_show.sql` | Full standalone implementation (was alias to spsec_usrinf.sql) |

### Documentation to update

- `src/sql/README.md` - Add new script categories (Splunk, Trail Volume, new Utility scripts)
- `src/doc/sql-scripts.md` - Add all new scripts to inventory tables

### Scripts explicitly excluded

- All `tst_*` scripts (lab-specific test scripts, not generic tooling)

---

## Task 1: Copy New Scripts

**Files:**
- Create: 18 new `.sql` files in `src/sql/` (listed in overview above)

- [ ] **Step 1: Copy all 18 new scripts from source**

```bash
SOURCE=/Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql
TARGET=/Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql

cp "$SOURCE/aud_ddl_show_aud.sql"             "$TARGET/"
cp "$SOURCE/aud_health_show_aud.sql"           "$TARGET/"
cp "$SOURCE/aud_policies_create_aud_oracle.sql" "$TARGET/"
cp "$SOURCE/aud_report_config_aud.sql"         "$TARGET/"
cp "$SOURCE/aud_returncode_show_aud.sql"       "$TARGET/"
cp "$SOURCE/aud_session_ctx_show_aud.sql"      "$TARGET/"
cp "$SOURCE/aud_splunk_at_detection_setup.sql" "$TARGET/"
cp "$SOURCE/aud_splunk_checkpoint_setup.sql"   "$TARGET/"
cp "$SOURCE/aud_sysdba_show_aud.sql"           "$TARGET/"
cp "$SOURCE/aud_top_returncode_aud.sql"        "$TARGET/"
cp "$SOURCE/aud_trail_analysis_aud.sql"        "$TARGET/"
cp "$SOURCE/aud_trail_userhost_analysis_aud.sql" "$TARGET/"
cp "$SOURCE/auditpdb.sql"                      "$TARGET/"
cp "$SOURCE/env.sql"                           "$TARGET/"
cp "$SOURCE/env_show_sqlpath.sql"              "$TARGET/"
cp "$SOURCE/odb_audit_ctx_create_aud.sql"      "$TARGET/"
cp "$SOURCE/odb_policies_enable_aud.sql"       "$TARGET/"
cp "$SOURCE/pdb.sql"                           "$TARGET/"
```

- [ ] **Step 2: Verify all 18 files were copied**

```bash
ls /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_ddl_show_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_health_show_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_trail_analysis_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/odb_audit_ctx_create_aud.sql
# Expected: all 4 files listed without errors
```

- [ ] **Step 3: Check scripts use standalone logging pattern (no /opt/oracle/ paths)**

```bash
grep -l "/opt/oracle" /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_*.sql \
                      /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/odb_*.sql \
                      /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/env*.sql \
                      /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/pdb*.sql \
                      /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/auditpdb*.sql
# Expected: no output (none of the new scripts should have container paths)
```

- [ ] **Step 4: Commit new scripts**

```bash
cd /Users/stefan.oehrli/Repos/own/oehrlis/oradba
git add src/sql/aud_ddl_show_aud.sql src/sql/aud_health_show_aud.sql \
        src/sql/aud_policies_create_aud_oracle.sql src/sql/aud_report_config_aud.sql \
        src/sql/aud_returncode_show_aud.sql src/sql/aud_session_ctx_show_aud.sql \
        src/sql/aud_splunk_at_detection_setup.sql src/sql/aud_splunk_checkpoint_setup.sql \
        src/sql/aud_sysdba_show_aud.sql src/sql/aud_top_returncode_aud.sql \
        src/sql/aud_trail_analysis_aud.sql src/sql/aud_trail_userhost_analysis_aud.sql \
        src/sql/auditpdb.sql src/sql/env.sql src/sql/env_show_sqlpath.sql \
        src/sql/odb_audit_ctx_create_aud.sql src/sql/odb_policies_enable_aud.sql \
        src/sql/pdb.sql
git commit -m "feat(sql): add 18 new audit analysis and utility scripts from ora-db-audit-eng"
```

---

## Task 2: Update Modified Scripts

**Files:**
- Modify: 8 existing `.sql` files in `src/sql/`

### 2a: `aud_config_show_aud.sql`

Key change: Replace `sys.fga_log$` references with `dba_fga_audit_trail` (removes need for direct SYS object access).

- [ ] **Step 1: Copy updated version**

```bash
cp /Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql/aud_config_show_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_config_show_aud.sql
```

- [ ] **Step 2: Verify the SYS table reference is replaced**

```bash
grep "fga_log\$" /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_config_show_aud.sql
# Expected: no output (sys.fga_log$ should be gone)
grep "dba_fga_audit_trail" /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_config_show_aud.sql
# Expected: 6 lines with the DBA view reference
```

### 2b: `aud_policies_show_aud.sql`

Key change: Improved formatting, ROW_NUMBER() to show policy attributes once, better sort order (Active YES first, ODB before ORA).

- [ ] **Step 3: Copy updated version**

```bash
cp /Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql/aud_policies_show_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_policies_show_aud.sql
```

### 2c: `sec_whoami_show.sql`

Key change: Full standalone implementation showing session identity, roles, container, auth method. Was previously just `@spsec_usrinf.sql`.

- [ ] **Step 4: Copy updated version**

```bash
cp /Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql/sec_whoami_show.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/sec_whoami_show.sql
```

### 2d: `aud_report_full_aud.sql`

Key change: References new `aud_trail_analysis_aud.sql` and `aud_trail_userhost_analysis_aud.sql` at end of report.

- [ ] **Step 5: Copy updated version**

```bash
cp /Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql/aud_report_full_aud.sql \
   /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_report_full_aud.sql
```

### 2e: Remaining 4 modified scripts

- [ ] **Step 6: Copy remaining modified scripts**

```bash
SOURCE=/Users/stefan.oehrli/repos/own/oehrlis/ora-db-audit-eng/sql
TARGET=/Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql

cp "$SOURCE/aud_critobj_show_aud.sql"       "$TARGET/"
cp "$SOURCE/aud_critprivs_show_aud.sql"     "$TARGET/"
cp "$SOURCE/aud_grants_show_aud.sql"        "$TARGET/"
cp "$SOURCE/aud_top_policy_detail_aud.sql"  "$TARGET/"
```

- [ ] **Step 7: Verify key fixes are present**

```bash
# aud_grants_show_aud.sql should now have SPOOL OFF
grep "SPOOL OFF" /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_grants_show_aud.sql
# Expected: at least one line

# aud_top_policy_detail_aud.sql column header fix
grep '"User"' /Users/stefan.oehrli/Repos/own/oehrlis/oradba/src/sql/aud_top_policy_detail_aud.sql
# Expected: COLUMN dbusername ... HEADING "User"
```

- [ ] **Step 8: Commit modified scripts**

```bash
cd /Users/stefan.oehrli/Repos/own/oehrlis/oradba
git add src/sql/aud_config_show_aud.sql src/sql/aud_policies_show_aud.sql \
        src/sql/sec_whoami_show.sql src/sql/aud_report_full_aud.sql \
        src/sql/aud_critobj_show_aud.sql src/sql/aud_critprivs_show_aud.sql \
        src/sql/aud_grants_show_aud.sql src/sql/aud_top_policy_detail_aud.sql
git commit -m "fix(sql): update 8 audit scripts with improvements from ora-db-audit-eng"
```

---

## Task 3: Update src/sql/README.md

**Files:**
- Modify: `src/sql/README.md`

The README needs new entries for:
- Splunk Integration scripts
- Trail Volume Analysis scripts
- New utility scripts (env, pdb, auditpdb)
- New aliases/shortcuts

- [ ] **Step 1: Read current README**

Read `src/sql/README.md` in full to understand current structure.

- [ ] **Step 2: Add Splunk Integration section to Script Categories**

Add after the Audit Scripts section:

```markdown
### Splunk Integration Scripts

Scripts for Splunk archive timestamp management.

| Script | Purpose |
|--------|---------|
| `aud_splunk_at_detection_setup.sql` | Archive timestamp via Audit Trail Detection (K-AT pattern) |
| `aud_splunk_checkpoint_setup.sql` | Archive timestamp via Watchdog Checkpoint (K-WD pattern) |
```

- [ ] **Step 3: Add Trail Volume Analysis section**

```markdown
### Trail Volume Analysis Scripts

Scripts for comprehensive trail analysis and optimization.

| Script | Purpose |
|--------|---------|
| `aud_trail_analysis_aud.sql` | Comprehensive trail analysis: volume trend, noise candidates, policy gaps |
| `aud_trail_userhost_analysis_aud.sql` | User-host analysis for connection patterns and logon trigger regex design |
```

- [ ] **Step 4: Add new utility scripts to aliases/common table**

Add `env`, `pdb`, `auditpdb` to the aliases/common section.

- [ ] **Step 5: Update ODB Policy scripts section**

Add `odb_audit_ctx_create_aud.sql` and `odb_policies_enable_aud.sql` to the policy management section.

- [ ] **Step 6: Commit README update**

```bash
cd /Users/stefan.oehrli/Repos/own/oehrlis/oradba
git add src/sql/README.md
git commit -m "docs(sql): update README with new Splunk, trail analysis, and utility scripts"
```

---

## Task 4: Update src/doc/sql-scripts.md

**Files:**
- Modify: `src/doc/sql-scripts.md`

This is the full reference documentation. All new scripts need entries here.

- [ ] **Step 1: Read the full sql-scripts.md**

Read `src/doc/sql-scripts.md` to understand current table structure and categories.

- [ ] **Step 2: Add new Event Detail scripts**

In the Event Detail / Audit Events section, add:
- `aud_ddl_show_aud.sql` - Show recent DDL events (CREATE/ALTER/DROP/TRUNCATE/RENAME)
- `aud_returncode_show_aud.sql` - Show failed operations grouped by return code
- `aud_sysdba_show_aud.sql` - Show SYSDBA and SYSOPER privileged access events

- [ ] **Step 3: Add new Configuration and Health scripts**

In the Configuration section, add:
- `aud_health_show_aud.sql` - Single-screen operational health dashboard
- `aud_report_config_aud.sql` - Comprehensive audit configuration report

- [ ] **Step 4: Add new Policy Management scripts**

In the Policy Management section, add:
- `aud_policies_create_aud_oracle.sql` - Oracle default (ORA_*) predefined audit policies reference
- `odb_audit_ctx_create_aud.sql` - Create ODB Application Context (PROD version with WLS/K8s patterns)
- `odb_policies_enable_aud.sql` - Enable ODB audit policies Phase A+B (PROD version with dynamic user resolution)

- [ ] **Step 5: Add Session/Login Analysis scripts**

In the Session Analysis section, add:
- `aud_session_ctx_show_aud.sql` - Analyse USERENV context attributes for WHEN clauses

- [ ] **Step 6: Add new Splunk Integration section**

Create new section "Splunk Integration" with:
- `aud_splunk_at_detection_setup.sql`
- `aud_splunk_checkpoint_setup.sql`

- [ ] **Step 7: Add new Top-N script**

In the Top-N section, add:
- `aud_top_returncode_aud.sql` - Top-N error codes from the unified audit trail

- [ ] **Step 8: Add new Trail Volume Analysis section**

Create new section "Trail Volume Analysis" with:
- `aud_trail_analysis_aud.sql`
- `aud_trail_userhost_analysis_aud.sql`

- [ ] **Step 9: Add new Utility scripts**

In the Utility section, add:
- `env.sql` - Show full session environment
- `env_show_sqlpath.sql` - Show SQLPATH directories with existence check
- `pdb.sql` - Switch session container to a given PDB
- `auditpdb.sql` - Switch session container to AUDITPDB1

- [ ] **Step 10: Document sec_whoami_show.sql as standalone**

Update the description of `sec_whoami_show.sql` from "alias for spsec_usrinf.sql" to the correct description: shows session identity, roles, container, authentication method.

- [ ] **Step 11: Commit documentation update**

```bash
cd /Users/stefan.oehrli/Repos/own/oehrlis/oradba
git add src/doc/sql-scripts.md
git commit -m "docs(sql): add 18 new scripts and update modified scripts in sql-scripts.md"
```

---

## Task 5: Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Read current CHANGELOG.md and VERSION**

```bash
head -30 /Users/stefan.oehrli/Repos/own/oehrlis/oradba/CHANGELOG.md
cat /Users/stefan.oehrlis/Repos/own/oehrlis/oradba/VERSION
```

- [ ] **Step 2: Add changelog entry**

Add an `[Unreleased]` or new version entry with:

```markdown
### Added
- 18 new SQL scripts: Splunk integration, trail volume analysis, DDL events,
  sysdba access, health dashboard, config report, ODB policy management, PDB utilities
- `aud_ddl_show_aud.sql`, `aud_health_show_aud.sql`, `aud_policies_create_aud_oracle.sql`,
  `aud_report_config_aud.sql`, `aud_returncode_show_aud.sql`, `aud_session_ctx_show_aud.sql`,
  `aud_splunk_at_detection_setup.sql`, `aud_splunk_checkpoint_setup.sql`,
  `aud_sysdba_show_aud.sql`, `aud_top_returncode_aud.sql`, `aud_trail_analysis_aud.sql`,
  `aud_trail_userhost_analysis_aud.sql`, `auditpdb.sql`, `env.sql`, `env_show_sqlpath.sql`,
  `odb_audit_ctx_create_aud.sql`, `odb_policies_enable_aud.sql`, `pdb.sql`

### Fixed
- `aud_config_show_aud.sql`: use `dba_fga_audit_trail` instead of `sys.fga_log$`
- `aud_grants_show_aud.sql`: add missing SPOOL OFF
- `aud_top_policy_detail_aud.sql`: fix column header (Policies → User)
- `sec_whoami_show.sql`: full standalone implementation (was alias to spsec_usrinf.sql)

### Changed
- `aud_policies_show_aud.sql`: improved formatting, ROW_NUMBER deduplication, sort order
- `aud_critobj_show_aud.sql`, `aud_critprivs_show_aud.sql`: improved parameter handling
- `aud_report_full_aud.sql`: now includes trail analysis sections
```

- [ ] **Step 3: Commit changelog**

```bash
cd /Users/stefan.oehrli/Repos/own/oehrlis/oradba
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for SQL scripts sync from ora-db-audit-eng"
```

---

## Self-Review Checklist

- [x] All 18 new scripts listed explicitly with copy commands
- [x] All 8 modified scripts addressed individually with key changes documented
- [x] tst_* scripts excluded
- [x] `aud_report_full_aud.sql` update accounts for its dependency on the 2 new trail analysis scripts
- [x] No `/opt/oracle/` path check included (Task 1 Step 3)
- [x] `sec_whoami_show.sql` correctly noted as full standalone (not just alias update)
- [x] Documentation covers both README.md and sql-scripts.md
- [x] CHANGELOG entry covers Added/Fixed/Changed correctly
- [x] All commits use Conventional Commits format
