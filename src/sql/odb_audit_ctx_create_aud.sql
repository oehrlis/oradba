-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: odb_audit_ctx_create_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.09
-- Revision..: 0.1.0
-- Purpose...: Create ODB Application Context (ODB_AUDIT_CTX) with supporting
--             package (ODB_AUDIT_CTX_PKG) and logon trigger (ODB_SET_AUDIT_CTX_TRG).
--             The context classifies each session at login and sets boolean
--             attributes that audit policy WHEN clauses can evaluate:
--               IS_APP_ACCESS      - TRUE = connecting from a known app server
--               IS_OEM_ACCESS      - TRUE = OEM monitoring connection (host or user)
--               IS_KNOWN_CLIENT    - TRUE = explicitly listed client host or IP
--               IS_DEV_TOOL        - TRUE = client program is SQL Developer or Toad
--                                    Used by ODB_LOC_PRIV_DBA_ALL_V1 and ODB_LOC_DEV_ALL_V1 to exclude
--                                    developer tool sessions from ALL ACTIONS audit
--               CLIENT_HOST        - resolved client hostname (debug/analysis)
--               CLIENT_IP          - client IP address (debug/analysis)
--
--             ENVIRONMENT: PRODUCTION (ODB Customer)
--             This script uses PROD host patterns:
--               WLS Classic  : ^xa       (hostnames starting with "xa")
--               PaaS K8s Dep : -[a-z0-9]{10}-[a-z0-9]{5}$   (ReplicaSet pods)
--               PaaS K8s Cron: -[0-9]{10}-                   (CronJob pods)
--
--             Lab environment uses Docker container names (^app-classic|^app-paas).
--             See: lab/db/config/common/odb_audit_ctx_create_aud.sql
--             See: doc/analysis/paas-hostname-regex.md  for pattern analysis
--
--             Naming convention: ODB_ prefix = customer-specific deployment.
--             When adapting for a different customer, replace ODB_ with the
--             customer prefix throughout (context name, package, trigger, policies).
--
-- Notes.....: Run as SYSDBA or a user with:
--               CREATE ANY CONTEXT
--               CREATE ANY PROCEDURE
--               CREATE ANY TRIGGER (AFTER LOGON ON DATABASE)
--             Run per PDB (never in CDB$ROOT unless intentional).
--
-- Verify....: Before deploying, run aud_trail_userhost_analysis_aud.sql against
--             at least 7 days of audit trail to confirm all app-tier hostnames
--             are matched by C_APP_HOST_PATTERN. Check for false negatives
--             (missed app servers) and false positives (matched DBA hosts).
--
-- Fallback..: If the trigger or package fails at login, all context attributes
--             remain NULL. Audit policy WHEN clauses MUST use the IS NULL OR pattern
--             (NVL is not a simple rule condition - ORA-46368):
--               SYS_CONTEXT('ODB_AUDIT_CTX','IS_APP_ACCESS') != 'TRUE'
--               OR SYS_CONTEXT('ODB_AUDIT_CTX','IS_APP_ACCESS') IS NULL
--             This ensures NULL is treated as the safe (audit) default.
--             NULL defaults per attribute:
--               IS_APP_ACCESS   -> NULL = not app server = off-path = audit
--               IS_OEM_ACCESS   -> NULL = not OEM = audit
--               IS_KNOWN_CLIENT -> NULL = not listed = audit devs
--               IS_DEV_TOOL     -> NULL = unknown client = audit (conservative)
--
-- Extension.: To add new classification attributes:
--               1. Add a constant to the CONFIGURATION section in the package body
--               2. Add a private helper function F_IS_<NAME>
--               3. Call the helper in SET_AUDIT_CONTEXT and SET_CONTEXT the result
--               4. Update example policies in Step 4 if required
--             No changes to the package spec or the context DDL are needed.
--
-- Limitation: 1. HOST in SYS_CONTEXT('USERENV','HOST') is the machine name of
--                the client. Empty for local/Bequeath (OS-authenticated) connections.
--             2. IP_ADDRESS is empty for local connections (same server, IPC pipe).
--             3. MODULE/program name can be set by the application at will via
--                DBMS_APPLICATION_INFO - do not use for security-relevant decisions.
--             4. EVALUATE PER SESSION: the WHEN clause is evaluated once per session
--                at login. Context changes within an open session have no effect.
--             5. SYSDBA logons fire the trigger; actions before DB OPEN land in
--                mandatory binary audit files regardless of policy WHEN clauses.
--
-- Reference.: aud_trail_userhost_analysis_aud.sql  - verify host patterns before PROD
-- Reference.: doc/analysis/paas-hostname-regex.md  - K8s hostname pattern analysis
-- Reference.: doc/07_technical.md                  - architecture overview
-- Reference.: doc/analysis/phase-3-output.md       - design decisions
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

SET SERVEROUTPUT ON
SET LINESIZE 256 PAGESIZE 1000
SET FEEDBACK ON

-- =============================================================================
PROMPT ================================================================================
PROMPT = PRE-CHECKS - existing contexts and logon triggers
PROMPT ================================================================================
-- =============================================================================

COLUMN namespace        FORMAT A25  HEADING "Namespace"
COLUMN schema           FORMAT A20  HEADING "Schema"
COLUMN package          FORMAT A30  HEADING "Package"

SELECT namespace, schema, package
FROM   dba_context
WHERE  namespace IN ('ODB_AUDIT_CTX', 'AUDIT_CTX')
ORDER  BY namespace;

COLUMN trigger_name     FORMAT A35  HEADING "Trigger"
COLUMN status           FORMAT A10  HEADING "Status"
COLUMN trigger_type     FORMAT A20  HEADING "Type"
COLUMN triggering_event FORMAT A20  HEADING "Event"

SELECT trigger_name, status, trigger_type, triggering_event
FROM   dba_triggers
WHERE  triggering_event LIKE '%LOGON%'
  AND  base_object_type = 'DATABASE'
ORDER  BY trigger_name;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = STEP 1 - Create Application Context ODB_AUDIT_CTX
PROMPT =   Namespace : ODB_AUDIT_CTX
PROMPT =   Package   : ODB_AUDIT_CTX_PKG  (context can only be set by this package)
PROMPT =   Type      : ACCESSED GLOBALLY  (required for audit policy WHEN clauses)
PROMPT ================================================================================
-- =============================================================================

CREATE OR REPLACE CONTEXT ODB_AUDIT_CTX
    USING ODB_AUDIT_CTX_PKG
    ACCESSED GLOBALLY;

-- Note: ACCESSED GLOBALLY means the context values are visible across the session
-- in SYS_CONTEXT() calls, including inside audit policy WHEN clause evaluation.
-- The logon trigger still sets values only for the connecting session; GLOBALLY
-- refers to accessibility scope, not shared-memory visibility across sessions.

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = STEP 2 - Create Package ODB_AUDIT_CTX_PKG
PROMPT ================================================================================
-- =============================================================================

-- --- Package Specification ----------------------------------------------------
-- Public interface: single procedure called by the logon trigger.
-- The spec is intentionally minimal; all logic is in the body.

CREATE OR REPLACE PACKAGE ODB_AUDIT_CTX_PKG AS
    -- Sets all ODB_AUDIT_CTX attributes for the current session.
    -- Called by ODB_SET_AUDIT_CTX_TRG after every successful login.
    PROCEDURE SET_AUDIT_CONTEXT;
END ODB_AUDIT_CTX_PKG;
/

-- --- Package Body -------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY ODB_AUDIT_CTX_PKG AS

    -- =========================================================================
    -- CONFIGURATION
    -- -------------------------------------------------------------------------
    -- Adjust these constants for each deployment environment.
    -- All patterns are REGEXP_LIKE patterns, case-insensitive ('i' flag).
    -- Set a constant to NULL to disable that specific check.
    -- Run aud_trail_userhost_analysis_aud.sql to verify patterns against
    -- real host names before deploying to production.
    -- =========================================================================

    -- App-server host pattern (PROD: WLS Classic + PaaS K8s)
    -- Two app tiers are covered:
    --   WLS Classic : ^xa
    --     Hostnames start with "xa" (e.g. xaapp01, xaapp-prod-01).
    --   PaaS K8s Deployment pods: -[a-z0-9]{10}-[a-z0-9]{5}$
    --     ReplicaSet hash (10 chars) followed by pod hash (5 chars) at end.
    --     Example: legacy-sync-service-6c4d8bbdfd-jdbsd
    --   PaaS K8s CronJob pods: -[0-9]{10}-
    --     10-digit Unix timestamp embedded in the pod name.
    --     Example: healthcheck-batch-scheduled-1774600200-main-2963840711
    -- See: doc/analysis/paas-hostname-regex.md for full analysis.
    -- Lab pattern (Docker): '^app-classic|^app-paas'
    -- Lab script: lab/db/config/common/odb_audit_ctx_create_aud.sql
    C_APP_HOST_PATTERN  CONSTANT VARCHAR2(400) := '^xa|(-[a-z0-9]{10}-[a-z0-9]{5}$|-[0-9]{10}-)';

    -- OEM server host pattern
    -- Hostname of the Oracle Enterprise Manager (OEM) management server or
    -- agent host. Sessions from this host set IS_OEM_ACCESS = 'TRUE'.
    -- Set to NULL if OEM is not present or if user-based detection is sufficient.
    -- Example PROD pattern: '^oms-server$|^oem-mgmt-'
    C_OEM_HOST_PATTERN  CONSTANT VARCHAR2(400) := NULL;

    -- OEM agent usernames
    -- Pipe-separated list of usernames used by OEM agents and the repository.
    -- Sessions where SESSION_USER matches this list set IS_OEM_ACCESS = 'TRUE'.
    -- Standard OEM users: DBSNMP (monitoring agent), SYSMAN (OEM repository).
    -- Leave as-is unless additional OEM service accounts exist.
    C_OEM_USERS         CONSTANT VARCHAR2(200) := 'DBSNMP|SYSMAN';

    -- Known client host pattern
    -- Explicitly registered client hostnames: DBA workstations, jump hosts,
    -- approved admin terminals. Sessions matching set IS_KNOWN_CLIENT = 'TRUE'.
    -- These can be used to enable stricter or more detailed audit for direct
    -- admin access from defined hosts, or to distinguish trusted DBA logins.
    -- Set to NULL if host-based known-client detection is not required.
    -- Example PROD pattern: '^dba-ws-|^jumpbox-prod-'
    C_KNOWN_HOST_PATTERN CONSTANT VARCHAR2(400) := NULL;

    -- Known client IP pattern
    -- Explicitly registered IP addresses or subnets for known clients.
    -- Evaluated in addition to C_KNOWN_HOST_PATTERN (OR logic).
    -- Set to NULL to disable IP-based known-client detection.
    -- Example: '^10\.0\.1\.' for DBA subnet 10.0.1.0/24
    --          '^192\.168\.10\.(10|11|12)$' for specific workstation IPs
    C_KNOWN_IP_PATTERN  CONSTANT VARCHAR2(400) := NULL;

    -- Client programs classified as developer tools (SQL Developer, Toad)
    -- Matched case-insensitively against SYS_CONTEXT('USERENV','CLIENT_PROGRAM_NAME').
    -- Sessions matching this pattern set IS_DEV_TOOL = 'TRUE'.
    -- Used by DBA and developer audit policies to suppress ALL ACTIONS audit for
    -- known interactive tool sessions and reduce noise while keeping direct connections.
    -- Set to NULL to disable developer tool detection (all sessions treated equally).
    C_DEV_TOOL_PATTERN  CONSTANT VARCHAR2(200) := 'sql.developer|sqldeveloper|toad';

    -- =========================================================================
    -- PRIVATE HELPER FUNCTIONS
    -- -------------------------------------------------------------------------
    -- Each function encapsulates one classification decision.
    -- Returns TRUE when the condition is met, FALSE otherwise.
    -- Add new helpers here when extending the context with new attributes.
    -- =========================================================================

    -- Returns TRUE when the session originates from a known application server.
    -- Check is host-based only; IP fallback not used (app servers have stable names).
    FUNCTION F_IS_APP_SERVER(
        p_host IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN C_APP_HOST_PATTERN IS NOT NULL
           AND REGEXP_LIKE(p_host, C_APP_HOST_PATTERN, 'i');
    END F_IS_APP_SERVER;

    -- Returns TRUE when the session is an OEM monitoring connection.
    -- Two signals are combined with OR logic:
    --   - OEM management server host pattern
    --   - Known OEM agent/repository usernames (DBSNMP, SYSMAN)
    FUNCTION F_IS_OEM_ACCESS(
        p_host IN VARCHAR2,
        p_user IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN (C_OEM_HOST_PATTERN IS NOT NULL
                AND REGEXP_LIKE(p_host, C_OEM_HOST_PATTERN, 'i'))
            OR (C_OEM_USERS IS NOT NULL
                AND REGEXP_LIKE(p_user, '^(' || C_OEM_USERS || ')$', 'i'));
    END F_IS_OEM_ACCESS;

    -- Returns TRUE when the session originates from an explicitly listed client.
    -- Host pattern and IP pattern are evaluated with OR logic.
    FUNCTION F_IS_KNOWN_CLIENT(
        p_host IN VARCHAR2,
        p_ip   IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN (C_KNOWN_HOST_PATTERN IS NOT NULL
                AND REGEXP_LIKE(p_host, C_KNOWN_HOST_PATTERN, 'i'))
            OR (C_KNOWN_IP_PATTERN IS NOT NULL
                AND REGEXP_LIKE(p_ip, C_KNOWN_IP_PATTERN, 'i'));
    END F_IS_KNOWN_CLIENT;

    -- Returns TRUE when the connecting client program is a known developer tool
    -- (SQL Developer, Toad). Matched against CLIENT_PROGRAM_NAME from USERENV.
    -- Note: CLIENT_PROGRAM_NAME can be overridden by the application via
    -- DBMS_APPLICATION_INFO - use for noise reduction only, not security enforcement.
    FUNCTION F_IS_DEV_TOOL(
        p_program IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN C_DEV_TOOL_PATTERN IS NOT NULL
           AND REGEXP_LIKE(p_program, C_DEV_TOOL_PATTERN, 'i');
    END F_IS_DEV_TOOL;

    -- =========================================================================
    -- PUBLIC PROCEDURE
    -- =========================================================================

    PROCEDURE SET_AUDIT_CONTEXT IS
        v_host    VARCHAR2(256);
        v_ip      VARCHAR2(64);
        v_user    VARCHAR2(128);
        v_program VARCHAR2(48);
    BEGIN
        -- Collect session identifiers from USERENV.
        -- HOST and MODULE may be empty for local/Bequeath connections.
        -- All attributes are read once to avoid repeated SYS_CONTEXT calls.
        v_host    := LOWER(NVL(SYS_CONTEXT('USERENV', 'HOST'),                ''));
        v_ip      :=       NVL(SYS_CONTEXT('USERENV', 'IP_ADDRESS'),           '');
        v_user    := UPPER(NVL(SYS_CONTEXT('USERENV', 'SESSION_USER'),         ''));
        v_program := LOWER(NVL(SYS_CONTEXT('USERENV', 'CLIENT_PROGRAM_NAME'),  ''));

        -- IS_APP_ACCESS
        -- 'TRUE'  = connecting from a known application server (regular app traffic)
        -- 'FALSE' = direct connection: DBA, developer, unknown, or empty hostname
        -- Safe fallback for audit WHEN clauses (IS NULL OR pattern - NVL not allowed):
        --   SYS_CONTEXT('ODB_AUDIT_CTX','IS_APP_ACCESS') != 'TRUE'
        --   OR SYS_CONTEXT('ODB_AUDIT_CTX','IS_APP_ACCESS') IS NULL  -> audit
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'IS_APP_ACCESS',
            value     => CASE WHEN F_IS_APP_SERVER(v_host) THEN 'TRUE' ELSE 'FALSE' END
        );

        -- IS_OEM_ACCESS
        -- 'TRUE'  = OEM monitoring connection (host pattern or OEM agent username)
        -- 'FALSE' = not an OEM connection
        -- Safe fallback for audit WHEN clauses (IS NULL OR pattern - NVL not allowed):
        --   SYS_CONTEXT('ODB_AUDIT_CTX','IS_OEM_ACCESS') IS NULL  -> audit
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'IS_OEM_ACCESS',
            value     => CASE WHEN F_IS_OEM_ACCESS(v_host, v_user) THEN 'TRUE' ELSE 'FALSE' END
        );

        -- IS_KNOWN_CLIENT
        -- 'TRUE'  = session originates from an explicitly listed host or IP
        -- 'FALSE' = not in the known-client list
        -- Safe fallback for audit WHEN clauses (IS NULL OR pattern - NVL not allowed):
        --   SYS_CONTEXT('ODB_AUDIT_CTX','IS_KNOWN_CLIENT') IS NULL  -> audit
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'IS_KNOWN_CLIENT',
            value     => CASE WHEN F_IS_KNOWN_CLIENT(v_host, v_ip) THEN 'TRUE' ELSE 'FALSE' END
        );

        -- IS_DEV_TOOL
        -- 'TRUE'  = client program is SQL Developer or Toad (developer tool session)
        -- 'FALSE' = other client program (sqlplus, application, unknown)
        -- Safe fallback for audit WHEN clauses (IS NULL OR pattern - NVL not allowed):
        --   SYS_CONTEXT('ODB_AUDIT_CTX','IS_DEV_TOOL') != 'TRUE'
        --   OR SYS_CONTEXT('ODB_AUDIT_CTX','IS_DEV_TOOL') IS NULL  -> audit
        -- NULL context (trigger failure) -> IS NULL arm fires -> unknown client = audit (conservative).
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'IS_DEV_TOOL',
            value     => CASE WHEN F_IS_DEV_TOOL(v_program) THEN 'TRUE' ELSE 'FALSE' END
        );

        -- CLIENT_HOST and CLIENT_IP
        -- Stored for troubleshooting, pattern analysis, and forensic review.
        -- Not used directly in audit WHEN clauses.
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'CLIENT_HOST',
            value     => SUBSTR(v_host, 1, 256)
        );
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'ODB_AUDIT_CTX',
            attribute => 'CLIENT_IP',
            value     => SUBSTR(v_ip, 1, 64)
        );

    EXCEPTION
        WHEN OTHERS THEN
            -- Any error in context classification must never block a login.
            -- On exception all attributes remain NULL.
            -- Audit policy WHEN clauses must handle NULL via NVL to ensure
            -- the safe (audit) default is preserved when context is unavailable.
            NULL;
    END SET_AUDIT_CONTEXT;

END ODB_AUDIT_CTX_PKG;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = STEP 3 - Create Logon Trigger ODB_SET_AUDIT_CTX_TRG
PROMPT ================================================================================
-- =============================================================================

CREATE OR REPLACE TRIGGER ODB_SET_AUDIT_CTX_TRG
    AFTER LOGON ON DATABASE
BEGIN
    ODB_AUDIT_CTX_PKG.SET_AUDIT_CONTEXT;
EXCEPTION
    WHEN OTHERS THEN NULL;  -- trigger must never block a login
END ODB_SET_AUDIT_CTX_TRG;
/

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = STEP 4 - Verification
PROMPT ================================================================================
-- =============================================================================

PROMPT
PROMPT -- Application context registration:
COLUMN namespace FORMAT A25  HEADING "Namespace"
COLUMN schema    FORMAT A20  HEADING "Schema"
COLUMN package   FORMAT A30  HEADING "Package"

SELECT namespace, schema, package
FROM   dba_context
WHERE  namespace = 'ODB_AUDIT_CTX';

PROMPT
PROMPT -- Package compile status:
COLUMN object_name   FORMAT A30  HEADING "Object"
COLUMN object_type   FORMAT A20  HEADING "Type"
COLUMN status        FORMAT A10  HEADING "Status"
COLUMN last_ddl_time FORMAT A20  HEADING "Last DDL"

SELECT object_name, object_type, status,
       TO_CHAR(last_ddl_time, 'DD.MM.YYYY HH24:MI:SS') AS last_ddl_time
FROM   dba_objects
WHERE  object_name IN ('ODB_AUDIT_CTX_PKG')
ORDER  BY object_type;

PROMPT
PROMPT -- Logon trigger status:
COLUMN trigger_name FORMAT A35  HEADING "Trigger"
COLUMN status       FORMAT A10  HEADING "Status"

SELECT trigger_name, status
FROM   dba_triggers
WHERE  trigger_name = 'ODB_SET_AUDIT_CTX_TRG';

PROMPT
PROMPT -- Context values for the CURRENT session (re-connect to see trigger-set values):
COLUMN attribute FORMAT A25  HEADING "Context Attribute"
COLUMN value     FORMAT A60  HEADING "Value"

SELECT 'IS_APP_ACCESS'           AS attribute,
       SYS_CONTEXT('ODB_AUDIT_CTX', 'IS_APP_ACCESS')     AS value FROM DUAL
UNION ALL
SELECT 'IS_OEM_ACCESS',
       SYS_CONTEXT('ODB_AUDIT_CTX', 'IS_OEM_ACCESS')             FROM DUAL
UNION ALL
SELECT 'IS_KNOWN_CLIENT',
       SYS_CONTEXT('ODB_AUDIT_CTX', 'IS_KNOWN_CLIENT')           FROM DUAL
UNION ALL
SELECT 'IS_DEV_TOOL',
       SYS_CONTEXT('ODB_AUDIT_CTX', 'IS_DEV_TOOL')               FROM DUAL
UNION ALL
SELECT 'CLIENT_HOST',
       SYS_CONTEXT('ODB_AUDIT_CTX', 'CLIENT_HOST')               FROM DUAL
UNION ALL
SELECT 'CLIENT_IP',
       SYS_CONTEXT('ODB_AUDIT_CTX', 'CLIENT_IP')                 FROM DUAL
UNION ALL
SELECT '--- USERENV (reference) ---', NULL                        FROM DUAL
UNION ALL
SELECT 'USERENV.HOST',
       SYS_CONTEXT('USERENV', 'HOST')                            FROM DUAL
UNION ALL
SELECT 'USERENV.IP_ADDRESS',
       SYS_CONTEXT('USERENV', 'IP_ADDRESS')                      FROM DUAL
UNION ALL
SELECT 'USERENV.SESSION_USER',
       SYS_CONTEXT('USERENV', 'SESSION_USER')                    FROM DUAL
UNION ALL
SELECT 'USERENV.CLIENT_PROGRAM_NAME',
       SYS_CONTEXT('USERENV', 'CLIENT_PROGRAM_NAME')             FROM DUAL;

PROMPT
PROMPT -- Enabled audit policies referencing ODB_AUDIT_CTX:
COLUMN policy_name    FORMAT A45  HEADING "Policy"
COLUMN enabled_option FORMAT A20  HEADING "Enabled For"
COLUMN user_name      FORMAT A20  HEADING "User / Role"

SELECT DISTINCT
       policy_name,
       enabled_option,
       entity_name AS user_name
FROM   audit_unified_enabled_policies
WHERE  policy_name LIKE 'ODB\_%' ESCAPE '\'
ORDER  BY policy_name, entity_name;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = CLEANUP - commented out, execute only for full rollback
PROMPT ================================================================================
-- =============================================================================

-- Run in this order to avoid dependency errors.
-- NOAUDIT policies before DROP to avoid ORA-46257.
-- DROP   TRIGGER ODB_SET_AUDIT_CTX_TRG;
-- DROP   PACKAGE ODB_AUDIT_CTX_PKG;
-- DROP   CONTEXT ODB_AUDIT_CTX;

-- EOF -------------------------------------------------------------------------
