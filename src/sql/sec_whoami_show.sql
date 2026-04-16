--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sec_whoami_show.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.0.0
--  Purpose...: Show current session identity - connected user, schema, roles,
--              container, authentication method, and connection attributes.
--  Usage.....: @sec_whoami_show
--  Notes.....: Reads from SESSION_ROLES, SYS_CONTEXT(USERENV,...), and
--              v$session. Requires SELECT on v$session.
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET LINESIZE 120 PAGESIZE 100 FEEDBACK OFF VERIFY OFF
SET SERVEROUTPUT OFF

-- ---------------------------------------------------------------------------
-- Session Identity
-- ---------------------------------------------------------------------------
COLUMN label      FORMAT A25  HEADING "Attribute"
COLUMN value      FORMAT A80  HEADING "Value"

SELECT 'Session User'           AS label, SYS_CONTEXT('USERENV','SESSION_USER')          AS value FROM DUAL
UNION ALL
SELECT 'Current Schema',                  SYS_CONTEXT('USERENV','CURRENT_SCHEMA')         FROM DUAL
UNION ALL
SELECT 'Proxy User',                      NVL(SYS_CONTEXT('USERENV','PROXY_USER'),'-')    FROM DUAL
UNION ALL
SELECT 'Container (CON_NAME)',            SYS_CONTEXT('USERENV','CON_NAME')               FROM DUAL
UNION ALL
SELECT 'CDB Name',                        SYS_CONTEXT('USERENV','CDB_NAME')               FROM DUAL
UNION ALL
SELECT 'Auth Method',                     SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD')  FROM DUAL
UNION ALL
SELECT 'Auth Identity',                   NVL(SYS_CONTEXT('USERENV','AUTHENTICATED_IDENTITY'),'-') FROM DUAL
UNION ALL
SELECT 'OS User',                         SYS_CONTEXT('USERENV','OS_USER')                FROM DUAL
UNION ALL
SELECT 'Client Host',                     NVL(SYS_CONTEXT('USERENV','HOST'),'-')          FROM DUAL
UNION ALL
SELECT 'Client IP',                       NVL(SYS_CONTEXT('USERENV','IP_ADDRESS'),'-')    FROM DUAL
UNION ALL
SELECT 'Client Program',                  NVL(SYS_CONTEXT('USERENV','MODULE'),'-')        FROM DUAL
UNION ALL
SELECT 'Network Protocol',                NVL(SYS_CONTEXT('USERENV','NETWORK_PROTOCOL'),'bequeath (local)') FROM DUAL
UNION ALL
SELECT 'Server Host',                     SYS_CONTEXT('USERENV','SERVER_HOST')            FROM DUAL
ORDER BY 1;

-- ---------------------------------------------------------------------------
-- Active Session Roles
-- ---------------------------------------------------------------------------
COLUMN role FORMAT A50 HEADING "Active Role"

SELECT role FROM session_roles ORDER BY role;

SET FEEDBACK ON VERIFY ON
-- EOF -------------------------------------------------------------------------
