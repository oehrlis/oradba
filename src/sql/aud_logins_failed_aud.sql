-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_logins_failed_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.02.11
-- Revision..: 0.21.0
-- Purpose...: Show failed logins
-- Notes.....:  
-- Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _days    = 1
-- assinge default values
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE days     = &1 &_days
SET FEEDBACK ON
SET VERIFY ON

-- start to spool
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


SPOOL &LOGDIR./aud_logins_failed_aud_&DBSID._&TIMESTAMP..log
-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 180
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp          FORMAT A20 WRAP HEADING "Session Start"
COLUMN dbusername               FORMAT A12 WRAP HEADING "DB User"
COLUMN userhost                 FORMAT A25 heading "User Host"
COLUMN terminal                 FORMAT A12 heading "Terminal"
COLUMN external_userid          FORMAT A25 heading "External User"
COLUMN global_userid            FORMAT A25 heading "Global User"
COLUMN return_code              FORMAT 99999 heading "Error"
COLUMN unified_audit_policies   FORMAT A50 WRAP HEADING "Policies"
 
TTITLE  'Failed Logins'
SELECT
    event_timestamp,
    dbusername,
    userhost,
    terminal,
    external_userid,
    global_userid,
    return_code
    --,unified_audit_policies
    --,sql_text
FROM
    unified_audit_trail
WHERE
    ( '&days' IS NULL OR event_timestamp >= sysdate - &days ) AND
    action_name='LOGON' AND
    return_code<>0
ORDER BY
    event_timestamp ASC,
    entry_id ASC;

UNDEFINE def_sessionid sessionid
UNDEFINE 1
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------