-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_top_returncode_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.31
-- Revision..: 0.21.0
-- Purpose...: Show top-N error codes from the Unified Audit Trail.
--             Aggregated count per return_code, excluding success (0).
-- Notes.....:
-- Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN return_code  FORMAT 99999         HEADING "Error Code"
COLUMN events       FORMAT 9,999,999,999 HEADING "Audit Events"
COLUMN action_name  FORMAT A30  WRAP     HEADING "Top Action"

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

SPOOL &LOGDIR./aud_top_returncode_aud_&DBSID._&TIMESTAMP..log

SELECT
    return_code,
    COUNT(*)              AS events,
    MAX(action_name)      AS action_name
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
    AND return_code != 0
GROUP BY
    return_code
ORDER BY
    events DESC;

SPOOL OFF
-- EOF -------------------------------------------------------------------------
