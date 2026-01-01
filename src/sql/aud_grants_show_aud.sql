--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aud_grants_show_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2025.12.19
--  Revision..: 0.8.0
--  Purpose...: Show recently granted privileges
--  Notes.....:  
--  Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
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

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON

COLUMN wrl_type         FORMAT A8
COLUMN wrl_parameter    FORMAT A75
COLUMN status           FORMAT A18
COLUMN wallet_type      FORMAT A15
COLUMN con_id           FORMAT 99999

-- start to spool
-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

-- Get log directory from environment variable ORADBA_LOG (fallback to current dir)
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_$$.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_$$.sql
@/tmp/oradba_logdir_$$.sql
HOST rm -f /tmp/oradba_logdir_$$.sql

-- Get timestamp and database SID
COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./aud_grants_show_aud_&DBSID._&TIMESTAMP..log
TTITLE  'Grants'
SELECT
    event_timestamp,
    dbusername,
    entry_id,
    statement_id,
    action_name,
    return_code,
    object_schema,
    object_name
    --,unified_audit_policies
FROM
    unified_audit_trail
WHERE
    ( '&days' IS NULL OR event_timestamp >= sysdate - &days ) AND
    action_name='GRANT'
ORDER BY
    event_timestamp ASC,
    entry_id ASC;

UNDEFINE def_sessionid sessionid
UNDEFINE 1
TTITLE OFF

SPOOL OFF
SPOOL OFF
-- EOF -------------------------------------------------------------------------