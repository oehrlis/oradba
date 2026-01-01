--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aud_storage_usage_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.01.01
-- Revision...: 0.9.5
--  Purpose...: Show Unified Audit trail storage usage
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN name             format a80 wrap heading "Name"
COLUMN value            format a40 wrap heading "Value"

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


SPOOL &LOGDIR./aud_storage_usage_aud_&DBSID._&TIMESTAMP..log
SELECT
    name,
    value
FROM
    (
        SELECT
            1                      AS id,
            'Sum of audit records' AS name,
            to_char(COUNT(*))      AS value
        FROM
            unified_audit_trail
        UNION
        SELECT
            2                 AS id,
            'Sum of audit records for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'            AS name,
            to_char(COUNT(*)) AS value
        FROM
            unified_audit_trail
        WHERE
            dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
        UNION
        SELECT
            3                                AS id,
            'Oldest audit record for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'                           AS name,
            to_char(MIN(event_timestamp),
                    'DD.MM.YYYY HH24:MI:SS') AS value
        FROM
            unified_audit_trail
        WHERE
            dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
        UNION
        SELECT
            4                                AS id,
            'Newest audit record for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'                           AS name,
            to_char(MAX(event_timestamp),
                    'DD.MM.YYYY HH24:MI:SS') AS value
        FROM
            unified_audit_trail
        WHERE
            dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
        UNION
        SELECT
            5                                AS id,
            'Last archive timestamp for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'                           AS name,
            to_char(MAX(last_archive_ts),
                    'DD.MM.YYYY HH24:MI:SS') AS value
        FROM
            dba_audit_mgmt_last_arch_ts
        WHERE
            audit_trail = 'UNIFIED AUDIT TRAIL'
        UNION
        SELECT
            6                                 AS id,
            'Sum of audit records older than event timestamp for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'                            AS name,
            to_char(COUNT(u.event_timestamp)) AS value
        FROM
            unified_audit_trail         u,
            dba_audit_mgmt_last_arch_ts t
        WHERE
                t.audit_trail = 'UNIFIED AUDIT TRAIL'
            AND u.event_timestamp < t.last_archive_ts
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    7                                       AS id,
                    'Sum of audit records for foreign DBID' AS name,
                    to_char(COUNT(*))                       AS value
                FROM
                    unified_audit_trail
                WHERE
                    dbid <> con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            )
        WHERE
            value > 0
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    8                                      AS id,
                    'Oldest audit record for foreign DBID' AS name,
                    to_char(MIN(event_timestamp),
                            'DD.MM.YYYY HH24:MI:SS')       AS value
                FROM
                    unified_audit_trail
                WHERE
                    dbid <> con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            )
        WHERE
            value IS NOT NULL
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    9                                      AS id,
                    'Newest audit record for foreign DBID' AS name,
                    to_char(MAX(event_timestamp),
                            'DD.MM.YYYY HH24:MI:SS')       AS value
                FROM
                    unified_audit_trail
                WHERE
                    dbid <> con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            )
        WHERE
            value IS NOT NULL
        UNION
        SELECT
            10                  AS id,
            'Tablespace in use' AS name,
            LISTAGG(DISTINCT tablespace_name, ', ') WITHIN GROUP(
            ORDER BY
                tablespace_name
            )                   AS value
        FROM
            dba_segments
        WHERE
            segment_name = 'AUD$UNIFIED'
        UNION
        SELECT
            11                                      AS id,
            'Amount of audit trail data partitions' AS name,
            to_char(COUNT(partition_name))          AS value
        FROM
            dba_tab_partitions
        WHERE
            table_name = 'AUD$UNIFIED'
        UNION
        SELECT
            12                                    AS id,
            'Audit Trail data partition interval' AS name,
            INTERVAL                              AS value
        FROM
            dba_part_tables
        WHERE
                owner = 'AUDSYS'
            AND table_name = 'AUD$UNIFIED'
        UNION
        SELECT
            13                                AS id,
            'Audit Trail data partition type' AS name,
            partitioning_type                 AS value
        FROM
            dba_part_tables
        WHERE
                owner = 'AUDSYS'
            AND table_name = 'AUD$UNIFIED'
        UNION
        SELECT
            14                                               AS id,
            'Sum of audit trail segments (data, lob, index)' AS name,
            to_char(dbms_xplan.format_size(SUM(bytes)))      AS value
        FROM
            dba_segments
        WHERE
            owner = 'AUDSYS'
        UNION
        SELECT
            15                                                                                  AS id,
            'Sum of audit trail segments (data, lob, index) for tablespace ' || tablespace_name AS name,
            to_char(dbms_xplan.format_size(SUM(bytes)))                                         AS value
        FROM
            dba_segments
        WHERE
            owner = 'AUDSYS'
        GROUP BY
            tablespace_name
        UNION
        SELECT
            16                   AS id,
            'Average audit record length (last analyzed '
            || to_char(last_analyzed, 'DD.MM.YYYY HH24:MI:SS')
            || ')'               AS name,
            to_char(avg_row_len) AS value
        FROM
            dba_tables
        WHERE
            owner = 'AUDSYS'
    );

SPOOL OFF
-- EOF -------------------------------------------------------------------------
