--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: odb_policies_enable_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.09
--  Revision..: v0.1.0
--  Purpose...: Enable all ODB_* audit policies (Phase A + Phase B) for PROD.
--              Phase A policies are enabled for all users (generic).
--              Phase B policies use dynamic user resolution by naming convention
--              (roles.md) instead of static user lists.
--
--              Naming convention (doc/references/roles.md):
--                App-User  : <APP>_APPUSER  -> pattern %_APPUSER
--                Batch-User: <APP>_APPBATCH -> pattern %_APPBATCH
--                Dev-User  : <CUSTOMER>_<N> -> pattern ODB_DEV_% (confirm with customer)
--                DBA-User  : C##ODB_<LOGIN> -> role C##ODB_ROLE_DBA (static)
--
--  CONFIGURATION: adjust the three v_*_pattern variables below before running.
--
--  Notes.....: Run per PDB as AUDIT_ADMIN or SYSDBA.
--              Prerequisite: odb_policies_create_aud.sql must have run.
--              Prerequisite: ODB_AUDIT_CTX deployed (sql/odb_audit_ctx_create_aud.sql)
--              for context-based policies (ODB_LOC_APP_OFFPATH_V1).
--              Lab equivalent: lab/db/config/common/odb_policies_enable_aud.sql
--                            + lab/db/config/auditlab/setup/31_enable_audit_policies_auditpdb1.sql
--  Reference.: doc/references/roles.md         - naming convention
--  Reference.: doc/analysis/paas-hostname-regex.md  - app-server host patterns
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON
SET LINESIZE 256 PAGESIZE 1000
SET FEEDBACK ON

-- =============================================================================
PROMPT ================================================================================
PROMPT = CONFIGURATION - adjust patterns before running
PROMPT ================================================================================
-- =============================================================================
--
-- Edit these three patterns to match the customer naming convention.
-- Verify against DBA_USERS before running:
--   SELECT username FROM dba_users
--   WHERE username LIKE '%\_APPUSER'  ESCAPE '\'
--      OR username LIKE '%\_APPBATCH' ESCAPE '\'
--   ORDER BY username;
--
-- v_app_batch_pattern : covers <APP>_APPUSER + <APP>_APPBATCH (off-path detection)
-- v_dev_pattern       : personal developer accounts - confirm with customer
-- DBA role            : C##ODB_ROLE_DBA (common role, no variable needed)
--
-- =============================================================================
PROMPT ================================================================================
PROMPT = PHASE A - Generic policies (all users)
PROMPT ================================================================================
-- =============================================================================

-- Session Events
AUDIT POLICY odb_loc_logon_events_v1;
-- NOAUDIT POLICY odb_loc_logon_events_v1;

-- Security-Relevant Events
AUDIT POLICY odb_loc_ddl_all_v1;
-- NOAUDIT POLICY odb_loc_ddl_all_v1;

AUDIT POLICY odb_loc_sys_param_v1;
-- NOAUDIT POLICY odb_loc_sys_param_v1;

AUDIT POLICY odb_loc_data_pump_v1;
-- NOAUDIT POLICY odb_loc_data_pump_v1;

AUDIT POLICY odb_loc_directory_v1;
-- NOAUDIT POLICY odb_loc_directory_v1;

AUDIT POLICY odb_loc_secure_config_v1;
-- NOAUDIT POLICY odb_loc_secure_config_v1;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = Disabling Oracle Predefined Policies (ORA_* / ORA$_*)
PROMPT ================================================================================
-- =============================================================================
-- Project decision: exclusively ODB_LOC_* custom policies.
-- ORA_* are reference only, never activated.
-- Oracle 26ai Free enables several by default - disable all.
-- =============================================================================

DECLARE
    PROCEDURE noaudit_if_enabled(p_name IN VARCHAR2) IS
        v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM audit_unified_enabled_policies
        WHERE policy_name = UPPER(p_name);
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'NOAUDIT POLICY ' || p_name;
            DBMS_OUTPUT.PUT_LINE('  Disabled: ' || p_name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('  Not enabled (skip): ' || p_name);
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  Error disabling ' || p_name || ': ' || SQLERRM);
    END;
BEGIN
    noaudit_if_enabled('ORA_SECURECONFIG');
    noaudit_if_enabled('ORA_LOGIN_LOGOUT');
    noaudit_if_enabled('ORA_LOGON_LOGOFF');
    noaudit_if_enabled('ORA_LOGON_FAILURES');
    noaudit_if_enabled('ORA_DATABASE_PARAMETER');
    noaudit_if_enabled('ORA_ACCOUNT_MGMT');
    noaudit_if_enabled('ORA_DV_DEFAULT_PROTECTION');
    noaudit_if_enabled('ORA_DV_SCHEMA_CHANGES');
    noaudit_if_enabled('ORA$DICTIONARY_SENS_COL_ACCESS');
END;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = OEM noise exclusion (SYSMAN / DBSNMP)
PROMPT ================================================================================
-- =============================================================================

DECLARE
    v_count PLS_INTEGER := 0;
BEGIN
    FOR u IN (
        SELECT username FROM dba_users
        WHERE  username IN ('SYSMAN', 'DBSNMP')
        ORDER BY username
    ) LOOP
        EXECUTE IMMEDIATE 'NOAUDIT POLICY odb_loc_logon_events_v1 BY ' || u.username;
        DBMS_OUTPUT.PUT_LINE('  OEM exclusion applied: ' || u.username);
        v_count := v_count + 1;
    END LOOP;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  SYSMAN/DBSNMP not found - OEM exclusion skipped');
    END IF;
END;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = PHASE B - DBA full audit (role-based: C##ODB_ROLE_DBA + SYS)
PROMPT ================================================================================
-- =============================================================================

AUDIT POLICY odb_loc_priv_dba_all_v1
    BY USERS WITH GRANTED ROLES C##ODB_ROLE_DBA;
-- SYS is added explicitly: C##ODB_ROLE_DBA is not granted to SYS by default
AUDIT POLICY odb_loc_priv_dba_all_v1 BY SYS;
PROMPT   ODB_LOC_PRIV_DBA_ALL_V1 enabled for C##ODB_ROLE_DBA and SYS

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = PHASE B - Developer full audit (naming convention: ODB_DEV_%)
PROMPT ================================================================================
-- Adjust v_dev_pattern to match the customer's developer naming convention.
-- From roles.md: personal users follow <CUSTOMER>_<N> pattern.
-- Default: ODB_DEV_% - confirm with customer before running.
-- =============================================================================

DECLARE
    v_dev_pattern  CONSTANT VARCHAR2(100) := 'ODB\_DEV\_%';  -- *** CONFIRM WITH CUSTOMER ***
    v_policy       CONSTANT VARCHAR2(60)  := 'odb_loc_dev_all_v1';
    v_count        PLS_INTEGER := 0;
BEGIN
    FOR u IN (
        SELECT username FROM dba_users
        WHERE  username LIKE v_dev_pattern ESCAPE '\'
          AND  account_status = 'OPEN'
        ORDER BY username
    ) LOOP
        EXECUTE IMMEDIATE 'AUDIT POLICY ' || v_policy || ' BY ' || u.username;
        DBMS_OUTPUT.PUT_LINE('  Dev audit enabled: ' || u.username);
        v_count := v_count + 1;
    END LOOP;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  WARNING: no users matched pattern ' || v_dev_pattern
            || ' - check v_dev_pattern');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Total: ' || v_count || ' developer account(s)');
    END IF;
END;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = PHASE B - App off-path detection (naming convention: %_APPUSER + %_APPBATCH)
PROMPT ================================================================================
-- Enables ODB_LOC_APP_OFFPATH_V1 for all users matching the app/batch naming
-- convention from roles.md (<APP>_APPUSER and <APP>_APPBATCH).
-- BY ROLES is not possible for this policy (WHEN-clause context-based, not role-based).
-- Re-run this block after provisioning new app or batch accounts.
-- =============================================================================

DECLARE
    v_policy CONSTANT VARCHAR2(60) := 'odb_loc_app_offpath_v1';
    v_count  PLS_INTEGER := 0;
BEGIN
    FOR u IN (
        SELECT username FROM dba_users
        WHERE  (   username LIKE '%\_APPUSER'  ESCAPE '\'
                OR username LIKE '%\_APPBATCH' ESCAPE '\')
          AND  account_status = 'OPEN'
        ORDER BY username
    ) LOOP
        EXECUTE IMMEDIATE 'AUDIT POLICY ' || v_policy || ' BY ' || u.username;
        DBMS_OUTPUT.PUT_LINE('  Off-path audit enabled: ' || u.username);
        v_count := v_count + 1;
    END LOOP;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  WARNING: no APPUSER/APPBATCH accounts found'
            || ' - verify naming convention or run after user provisioning');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Total: ' || v_count || ' app/batch account(s)');
    END IF;
END;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = PHASE B - Direct access audit (all users, IP IS NULL)
PROMPT ================================================================================
-- =============================================================================

AUDIT POLICY odb_loc_direct_access_v1;
PROMPT   ODB_LOC_DIRECT_ACCESS_V1 enabled for all users

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = VERIFY - enabled ODB_* policies
PROMPT ================================================================================
-- =============================================================================

PROMPT
PROMPT -- Phase A policies (all users):
COLUMN policy_name      FORMAT A35  HEADING "Policy"
COLUMN enabled_option   FORMAT A22  HEADING "Enabled For"
COLUMN success          FORMAT A8   HEADING "Success"
COLUMN failure          FORMAT A8   HEADING "Failure"
COLUMN entity_name      FORMAT A30  HEADING "Entity"

SELECT DISTINCT policy_name, enabled_option, success, failure, entity_name
FROM audit_unified_enabled_policies
WHERE policy_name LIKE 'ODB\_%' ESCAPE '\'
ORDER BY policy_name, enabled_option, entity_name;

-- EOF -------------------------------------------------------------------------
