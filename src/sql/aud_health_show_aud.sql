-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_health_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.31
-- Revision..: 0.21.0
-- Purpose...: Single-screen Operational Health Dashboard for Oracle Unified
--             Auditing. Shows audit mode, trail volume, purge config,
--             top users, top actions, and recent critical events.
-- Notes.....: Run as DBA or AUDIT_ADMIN. Read from UNIFIED_AUDIT_TRAIL and
--             DBA_AUDIT_MGMT_* views.
-- Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- format SQLPlus output and behavior
SET PAGESIZE 200  HEADING ON  VERIFY OFF
SET LINESIZE 150
SET FEEDBACK OFF  SQLCASE MIXED  NEWPAGE 1
-- Suppress automatic date/page-number line that SQL*Plus prepends to TTITLE
REPHEADER OFF
REPFOOTER OFF
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

-- Try to get log directory from environment (silently fall back to current dir)
WHENEVER OSERROR CONTINUE
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_${USER}.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_${USER}.sql
@@/tmp/oradba_logdir_${USER}.sql
HOST rm -f /tmp/oradba_logdir_${USER}.sql
WHENEVER OSERROR EXIT FAILURE

-- Get timestamp and database SID
COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./aud_health_show_aud_&DBSID._&TIMESTAMP..log

-- ============================================================================
-- Section 1: Audit Mode and Configuration
-- ============================================================================
TTITLE 'Audit Mode and Configuration'
COLUMN parameter    FORMAT A40 WRAP HEADING "Parameter"
COLUMN value        FORMAT A60 WRAP HEADING "Value"

SELECT 'Audit Trail'                    AS parameter,
       VALUE                            AS value
FROM   v$parameter
WHERE  name = 'audit_trail'
UNION ALL
SELECT 'Unified Audit (SGA)'           AS parameter,
       VALUE                            AS value
FROM   v$parameter
WHERE  name = 'unified_audit_sga_queue_size'
UNION ALL
SELECT 'Container Name'                AS parameter,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS value
FROM   DUAL
UNION ALL
SELECT 'DB Name'                       AS parameter,
       SYS_CONTEXT('USERENV', 'DB_NAME') AS value
FROM   DUAL;

TTITLE OFF

-- ============================================================================
-- Section 2: Unified Audit Trail Volume (last 7 days)
-- ============================================================================
TTITLE 'Audit Trail Volume - Last 7 Days'
COLUMN trail_day    FORMAT A12 HEADING "Day"
COLUMN records      FORMAT 999,999,999 HEADING "Records"

SELECT TO_CHAR(TRUNC(event_timestamp), 'DD.MM.YYYY') AS trail_day,
       COUNT(*)                                        AS records
FROM   unified_audit_trail
WHERE  dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND  event_timestamp >= SYSDATE - 7
GROUP BY TRUNC(event_timestamp)
ORDER BY TRUNC(event_timestamp) DESC;

TTITLE OFF

-- ============================================================================
-- Section 3: Top 10 Users (last 24 hours)
-- ============================================================================
TTITLE 'Top 10 DB Users - Last 24 Hours'
COLUMN dbusername   FORMAT A30 HEADING "DB User"
COLUMN records      FORMAT 999,999,999 HEADING "Records"

SELECT dbusername,
       COUNT(*) AS records
FROM   unified_audit_trail
WHERE  dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND  event_timestamp >= SYSDATE - 1
GROUP BY dbusername
ORDER BY records DESC
FETCH FIRST 10 ROWS ONLY;

TTITLE OFF

-- ============================================================================
-- Section 4: Top 10 Actions (last 24 hours)
-- ============================================================================
TTITLE 'Top 10 Actions - Last 24 Hours'
COLUMN action_name  FORMAT A30 HEADING "Action"
COLUMN records      FORMAT 999,999,999 HEADING "Records"

SELECT NVL(action_name, 'n/a') AS action_name,
       COUNT(*)                 AS records
FROM   unified_audit_trail
WHERE  dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND  event_timestamp >= SYSDATE - 1
GROUP BY action_name
ORDER BY records DESC
FETCH FIRST 10 ROWS ONLY;

TTITLE OFF

-- ============================================================================
-- Section 5: Active Audit Policies
-- ============================================================================
TTITLE 'Active Audit Policies'
COLUMN policy_name    FORMAT A40 HEADING "Policy Name"
COLUMN enabled_option FORMAT A20 HEADING "Enabled Option"
COLUMN entity_name    FORMAT A30 HEADING "User / Role"
COLUMN entity_type    FORMAT A12 HEADING "Entity Type"

SELECT DISTINCT
       policy_name,
       enabled_option,
       entity_name,
       entity_type
FROM   audit_unified_enabled_policies
ORDER BY policy_name, entity_name;

TTITLE OFF

-- ============================================================================
-- Section 6: Purge Job Status
-- ============================================================================
TTITLE 'Audit Purge Job Status'
COLUMN job_name         FORMAT A40 HEADING "Purge Job"
COLUMN job_status       FORMAT A15 HEADING "Status"
COLUMN job_frequency    FORMAT A40 HEADING "Frequency"
COLUMN job_container    FORMAT A20 HEADING "Container"

SELECT job_name,
       job_status,
       job_frequency,
       job_container
FROM   dba_audit_mgmt_cleanup_jobs
ORDER BY job_name;

TTITLE OFF

-- ============================================================================
-- Section 7: Recent Failed Operations (last 24 hours)
-- ============================================================================
TTITLE 'Recent Failed Operations - Last 24 Hours'
COLUMN event_timestamp  FORMAT A20 HEADING "Timestamp"
COLUMN dbusername       FORMAT A16 HEADING "DB User"
COLUMN action_name      FORMAT A20 HEADING "Action"
COLUMN return_code      FORMAT 99999 HEADING "Error"
COLUMN object_name      FORMAT A30 HEADING "Object"

SELECT TO_CHAR(event_timestamp, 'DD.MM.YYYY HH24:MI:SS') AS event_timestamp,
       dbusername,
       action_name,
       return_code,
       object_name
FROM   unified_audit_trail
WHERE  dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND  event_timestamp >= SYSDATE - 1
  AND  return_code != 0
ORDER BY event_timestamp DESC
FETCH FIRST 20 ROWS ONLY;

TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------
