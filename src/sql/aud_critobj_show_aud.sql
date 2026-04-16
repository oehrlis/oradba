-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_critobj_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.02.11
-- Revision..: 0.21.0
-- Purpose...: Show recently accessed critical objects.
-- Notes.....:
-- Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _days    = 7
DEFINE _schema  = '%'

-- assign default value for parameter if argument 1 or 2 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
DEFINE days     = &1 &_days
DEFINE schema   = &2 &_schema
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


SPOOL &LOGDIR./aud_critobj_show_aud_&DBSID._&TIMESTAMP..log
-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 200
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp          FORMAT A20 WRAP HEADING "Timestamp"
COLUMN db_user                  FORMAT A16 WRAP HEADING "DB User"
COLUMN action_name              FORMAT A16 WRAP HEADING "Action"
COLUMN object_schema            FORMAT A16 WRAP HEADING "Schema"
COLUMN object_name              FORMAT A30 WRAP HEADING "Object"
COLUMN sql_text                 FORMAT A60 WRAP HEADING "SQL Text"
COLUMN return_code              FORMAT 99999       HEADING "Error"

TTITLE  'Critical Object Access (last &days days, schema=&schema)'

SELECT
    TO_CHAR(event_timestamp, 'DD.MM.YYYY HH24:MI:SS') event_timestamp,
    dbusername                                         db_user,
    action_name,
    object_schema,
    object_name,
    sql_text,
    return_code
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
    AND ( '&days' IS NULL OR event_timestamp >= sysdate - &days )
    AND upper(object_schema) LIKE upper('&schema')
    AND (
        (object_schema = 'SYS' AND object_name IN (
            'USER$', 'ENC$', 'DEFAULT_PWD$', 'LINK$', 'SCHEDULER$_JOB',
            'AUDIT_ACTIONS', 'FGA_LOG$', 'AUD$'
        ))
        OR (object_schema = 'AUDSYS' AND object_name IN (
            'AUD$UNIFIED', 'CLI_SWP$aud$1'
        ))
        OR (object_schema = 'SYS' AND object_name LIKE '%$')
    )
ORDER BY
    event_timestamp DESC;

UNDEFINE _days _schema
UNDEFINE days schema
UNDEFINE 1 2
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------
