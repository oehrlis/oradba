-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_sysdba_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.31
-- Revision..: 0.21.0
-- Purpose...: Show SYSDBA and SYSOPER privileged access events from the
--             Unified Audit Trail. Includes OS-authenticated logins,
--             SYSDBA/SYSOPER logons, and operations using administrative
--             privilege.
-- Notes.....: Parameters: days (default 7), user (default %)
-- Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _days    = 7
DEFINE _user    = '%'

-- assign default value for parameter if argument 1 or 2 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
DEFINE days     = &1 &_days
DEFINE user     = &2 &_user
SET FEEDBACK ON
SET VERIFY ON

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

SPOOL &LOGDIR./aud_sysdba_show_aud_&DBSID._&TIMESTAMP..log

-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 200
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp          FORMAT A20 WRAP HEADING "Timestamp"
COLUMN dbusername               FORMAT A16 WRAP HEADING "DB User"
COLUMN os_username              FORMAT A14 WRAP HEADING "OS User"
COLUMN userhost                 FORMAT A26 WRAP HEADING "Host"
COLUMN action_name              FORMAT A20 WRAP HEADING "Action"
COLUMN system_privilege_used    FORMAT A20 WRAP HEADING "Privilege Used"
COLUMN return_code              FORMAT 99999       HEADING "Error"
COLUMN authentication_type      FORMAT A20 WRAP HEADING "Auth Type"

TTITLE 'SYSDBA/SYSOPER Privileged Access (last &days days, user=&user)'

SELECT
    TO_CHAR(event_timestamp, 'DD.MM.YYYY HH24:MI:SS') AS event_timestamp,
    dbusername,
    os_username,
    userhost,
    action_name,
    system_privilege_used,
    authentication_type,
    return_code
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
    AND ( '&days' IS NULL OR event_timestamp >= sysdate - &days )
    AND upper(dbusername) LIKE upper('&user')
    AND (
        system_privilege_used IN ('SYSDBA', 'SYSOPER', 'SYSBACKUP', 'SYSDG', 'SYSKM', 'SYSASM')
        OR authentication_type LIKE '%AS SYSDBA%'
        OR authentication_type LIKE '%AS SYSOPER%'
        OR dbusername IN ('SYS', 'SYSTEM')
    )
ORDER BY
    event_timestamp DESC;

UNDEFINE _days _user
UNDEFINE days user
UNDEFINE 1 2
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------
