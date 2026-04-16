-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_ddl_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.31
-- Revision..: 0.21.0
-- Purpose...: Show recent DDL events from the Unified Audit Trail.
--             Filters on CREATE/ALTER/DROP/TRUNCATE/RENAME operations.
-- Notes.....: Parameters: days (default 7), schema (default %)
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

SPOOL &LOGDIR./aud_ddl_show_aud_&DBSID._&TIMESTAMP..log

-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 200
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp  FORMAT A20 WRAP HEADING "Timestamp"
COLUMN dbusername       FORMAT A16 WRAP HEADING "DB User"
COLUMN action_name      FORMAT A16 WRAP HEADING "Action"
COLUMN object_schema    FORMAT A16 WRAP HEADING "Schema"
COLUMN object_name      FORMAT A30 WRAP HEADING "Object"
COLUMN object_type      FORMAT A16 WRAP HEADING "Type"
COLUMN return_code      FORMAT 99999       HEADING "Error"
COLUMN sql_text         FORMAT A50 WRAP HEADING "SQL Text"

TTITLE 'Recent DDL Events (last &days days, schema=&schema)'

SELECT
    TO_CHAR(event_timestamp, 'DD.MM.YYYY HH24:MI:SS') AS event_timestamp,
    dbusername,
    action_name,
    object_schema,
    object_name,
    object_type,
    return_code,
    sql_text
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
    AND ( '&days' IS NULL OR event_timestamp >= sysdate - &days )
    AND upper(object_schema) LIKE upper('&schema')
    AND action_name IN (
        'CREATE TABLE', 'ALTER TABLE', 'DROP TABLE', 'TRUNCATE TABLE',
        'CREATE INDEX', 'DROP INDEX',
        'CREATE VIEW', 'DROP VIEW',
        'CREATE PROCEDURE', 'CREATE FUNCTION', 'CREATE PACKAGE', 'CREATE PACKAGE BODY',
        'ALTER PROCEDURE', 'ALTER FUNCTION', 'ALTER PACKAGE', 'ALTER PACKAGE BODY',
        'DROP PROCEDURE', 'DROP FUNCTION', 'DROP PACKAGE',
        'CREATE TRIGGER', 'ALTER TRIGGER', 'DROP TRIGGER',
        'CREATE SEQUENCE', 'ALTER SEQUENCE', 'DROP SEQUENCE',
        'CREATE SYNONYM', 'DROP SYNONYM',
        'CREATE TYPE', 'ALTER TYPE', 'DROP TYPE',
        'CREATE USER', 'ALTER USER', 'DROP USER',
        'CREATE ROLE', 'ALTER ROLE', 'DROP ROLE',
        'RENAME', 'COMMENT', 'GRANT', 'REVOKE'
    )
ORDER BY
    event_timestamp DESC;

UNDEFINE _days _schema
UNDEFINE days schema
UNDEFINE 1 2
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------
