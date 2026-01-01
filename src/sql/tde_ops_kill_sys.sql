--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tde_ops_kill_sys.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2025.12.19
--  Revision..: 0.8.0
--  Purpose...: Kill running TDE operations based on V$SESSION_LONGOPS
--  Notes.....:  
--  Reference.: Requires access to V$SESSION_LONGOPS
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- start to spool
-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

-- Get log directory from environment variable ORADBA_LOG (fallback to current dir)
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_${USER}.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_${USER}.sql
@/tmp/oradba_logdir_${USER}.sql
HOST rm -f /tmp/oradba_logdir_${USER}.sql

-- Get timestamp and database SID
COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./tde_ops_kill_sys_&DBSID._&TIMESTAMP..log
-- format SQLPlus output and behavior
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE
        
    -- Types
    SUBTYPE text_type IS VARCHAR2(2000 CHAR);       -- NOSONAR G-2120 keep function independent

    l_sql text_type; -- local variable for dynamic SQL
BEGIN
    -- Collect file information from database while excluding specified tablespaces.
    << kill_runing_tde_ops >> FOR r_tde_sess IN (
        SELECT
            sid,
            serial#,
            opname
        FROM
            v$session_longops
        WHERE
            opname LIKE 'TDE%'
            AND time_remaining > 0
    ) LOOP
        sys.dbms_output.put_line('- kill operation '
                                 || r_tde_sess.opname
                                 || ' for SID='
                                 || r_tde_sess.sid
                                 || ' and serial='
                                 || r_tde_sess.serial#);

        l_sql := 'ALTER SYSTEM KILL SESSION '''
                 || r_tde_sess.sid
                 || ','
                 || r_tde_sess.serial#
                 || '''';

        sys.dbms_output.put_line(l_sql);
        EXECUTE IMMEDIATE l_sql;
    END LOOP kill_runing_tde_ops;
END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------