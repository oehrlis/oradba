--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: env.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.0.0
--  Purpose...: Show full session environment - DB version, audit mode, NLS,
--              session identity, and SQLPATH.
--  Usage.....: @env
--  Notes.....: Calls env_show_sqlpath.sql for SQLPATH section. All section
--              headers and data columns are 74 chars wide (label A28 + value A45).
--              Requires SELECT on v$instance, v$database, v$option,
--              v$nls_parameters, v$parameter, session_roles.
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET LINESIZE 80 PAGESIZE 100 FEEDBACK OFF VERIFY OFF SERVEROUTPUT OFF
COLUMN label FORMAT A28 HEADING "Attribute"
COLUMN value FORMAT A45 HEADING "Value"

-- ---------------------------------------------------------------------------
-- 1. Database / Instance
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === Database / Instance ==================================================

SELECT 'DB Version'       AS label, version_full                                    AS value FROM v$instance
UNION ALL
SELECT 'Instance Name',             instance_name                                   FROM v$instance
UNION ALL
SELECT 'Instance Status',           status                                          FROM v$instance
UNION ALL
SELECT 'Startup Time',              TO_CHAR(startup_time,'YYYY-MM-DD HH24:MI:SS')   FROM v$instance
UNION ALL
SELECT 'Logins',                    logins                                          FROM v$instance
UNION ALL
SELECT 'Archive Mode',              log_mode                                        FROM v$database
UNION ALL
SELECT 'Flashback',                 flashback_on                                    FROM v$database
UNION ALL
SELECT 'Dataguard Role',            database_role                                   FROM v$database;

-- ---------------------------------------------------------------------------
-- 2. Audit Mode
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === Audit Mode ===========================================================

SELECT 'Audit Trail (init.ora)' AS label,
       LISTAGG(value, ', ') WITHIN GROUP (ORDER BY value) AS value
FROM   v$parameter
WHERE  name = 'audit_trail'
UNION ALL
SELECT 'Unified Audit',
       CASE WHEN value = 'TRUE' THEN 'TRUE (Pure Unified Audit Mode)'
            ELSE value || ' (Mixed / Traditional)' END
FROM   v$option
WHERE  parameter = 'Unified Auditing';

-- ---------------------------------------------------------------------------
-- 3. NLS Settings
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === NLS Settings =========================================================

SELECT parameter AS label, value
FROM   v$nls_parameters
WHERE  parameter IN ('NLS_LANGUAGE','NLS_TERRITORY','NLS_CHARACTERSET',
                     'NLS_DATE_FORMAT','NLS_TIMESTAMP_FORMAT',
                     'NLS_TIMESTAMP_TZ_FORMAT','NLS_NUMERIC_CHARACTERS')
ORDER  BY parameter;

-- ---------------------------------------------------------------------------
-- 4. Session Identity
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === Session Identity =====================================================

SELECT 'Session User'      AS label, SYS_CONTEXT('USERENV','SESSION_USER')                         AS value FROM DUAL
UNION ALL
SELECT 'Current Schema',             SYS_CONTEXT('USERENV','CURRENT_SCHEMA')                        FROM DUAL
UNION ALL
SELECT 'Proxy User',                 NVL(SYS_CONTEXT('USERENV','PROXY_USER'),'-')                   FROM DUAL
UNION ALL
SELECT 'Container (CON_NAME)',       SYS_CONTEXT('USERENV','CON_NAME')                              FROM DUAL
UNION ALL
SELECT 'CDB Name',                   NVL(SYS_CONTEXT('USERENV','CDB_NAME'),'-')                     FROM DUAL
UNION ALL
SELECT 'Auth Method',                SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD')                 FROM DUAL
UNION ALL
SELECT 'OS User',                    NVL(SYS_CONTEXT('USERENV','OS_USER'),'-')                      FROM DUAL
UNION ALL
SELECT 'Client Host',                NVL(SYS_CONTEXT('USERENV','HOST'),'-')                         FROM DUAL
UNION ALL
SELECT 'Client IP',                  NVL(SYS_CONTEXT('USERENV','IP_ADDRESS'),'- (local/bequeath)')  FROM DUAL
UNION ALL
SELECT 'Client Program',             NVL(SYS_CONTEXT('USERENV','MODULE'),'-')                       FROM DUAL
UNION ALL
SELECT 'Server Host',                SYS_CONTEXT('USERENV','SERVER_HOST')                           FROM DUAL
UNION ALL
SELECT 'Active Roles',
       (SELECT NVL(LISTAGG(role, ', ') WITHIN GROUP (ORDER BY role),'-') FROM session_roles)        FROM DUAL
ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. SQLPATH
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === SQLPATH ==============================================================
@env_show_sqlpath

SET FEEDBACK ON VERIFY ON
-- EOF -------------------------------------------------------------------------
