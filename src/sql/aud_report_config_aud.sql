-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
--  Name......: aud_report_config_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.4.0
--  Purpose...: Comprehensive audit configuration report covering:
--              1. Database, Container and Audit Mode
--              2. Audit-relevant init.ora Parameters
--              3. Audit Trail Tablespace and Segment Sizes
--              4. Record Counts per Trail (AUD$, FGA_LOG$, unified)
--              5. Unified Audit Trail Storage Details
--              6. DBMS_AUDIT_MGMT Configuration Parameters
--              7. Archive Timestamps
--              8. Cleanup / Purge Jobs
--              9. Audit-related Scheduler Jobs
--  Notes.....: Run as SYSDBA or with AUDIT_ADMIN role in target PDB.
--              SQLCASE MIXED is required to preserve lowercase string literals
--              (parameter names in v$parameter are lowercase).
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

SET LINESIZE 140
SET PAGESIZE 100  HEADING ON  VERIFY OFF
-- NOTE: SQLCASE must be MIXED - UPPER would corrupt lowercase string literals
-- (v$parameter names, v$option values, regex patterns)
SET FEEDBACK OFF  SQLCASE MIXED  NEWPAGE 1
ALTER SESSION SET nls_date_format      = 'DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'DD.MM.YYYY HH24:MI:SS';

-- Column formats
COL info_name       FOR A35   HEADING "Property"
COL info_value      FOR A90   HEADING "Value"
COL owner           FOR A10   HEADING "Owner"
COL table_name      FOR A22   HEADING "Trail"
COL last_analyzed   FOR A19   HEADING "Last Analysed"
COL num_rows        FOR 9,999,999,999 HEADING "No of Rows"
COL avg_row_len     FOR 9,999,999,999 HEADING "Avg Row Len"
COL data_size       FOR A10   HEADING "Data Size"
COL total_size      FOR A10   HEADING "Total Size"
COL min_rec         FOR A19   HEADING "Oldest Record"
COL max_rec         FOR A19   HEADING "Newest Record"
COL rec_day         FOR 9,999,999,999 HEADING "Avg/Day"
COL rec_month       FOR 9,999,999,999 HEADING "Avg/Month"
COL rec_year        FOR 9,999,999,999 HEADING "Avg/Year"
COL rec_tot         FOR 9,999,999,999 HEADING "Total Records"
COL audit_trail     FOR A25   HEADING "Audit Trail"
COL parameter_name  FOR A35   HEADING "Parameter"
COL parameter_value FOR A20   HEADING "Value"
COL last_archive_ts FOR A22   HEADING "Last Archive Timestamp"
COL rac_instance    FOR 9999  HEADING "RAC"
COL database_id     FOR 9999999999 HEADING "Database ID"
COL job_name        FOR A42   HEADING "Job Name"
COL job_status      FOR A10   HEADING "Status"
COL job_frequency   FOR A6    HEADING "Freq h"
COL use_last_arch   FOR A6    HEADING "UseTS"
COL job_container   FOR A12   HEADING "Container"
COL state           FOR A12   HEADING "State"
COL repeat_interval FOR A30   HEADING "Repeat Interval"
COL name            FOR A70   HEADING "Name"
COL value           FOR A40   HEADING "Value"

-- -----------------------------------------------------------------------
-- Spool setup
-- -----------------------------------------------------------------------
DEFINE LOGDIR    = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID     = 'UNKNOWN'

WHENEVER OSERROR CONTINUE
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_${USER}.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_${USER}.sql
@@/tmp/oradba_logdir_${USER}.sql
HOST rm -f /tmp/oradba_logdir_${USER}.sql
WHENEVER OSERROR EXIT FAILURE

COLUMN logts  NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID     NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS')          AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME'))  AS logsid
FROM   DUAL;

SPOOL &LOGDIR./aud_report_config_aud_&DBSID._&TIMESTAMP..log

-- ============================================================================
-- Section 1: Database, Container and Audit Mode
-- ============================================================================
TTITLE '1. Database, Container and Audit Mode'
SELECT info_name, info_value
FROM (
    SELECT 1  AS id, 'DB Name'        AS info_name, d.name                              AS info_value FROM v$database d
    UNION ALL
    SELECT 2, 'CDB',                  d.cdb                                             FROM v$database d
    UNION ALL
    SELECT 3, 'DB Version',           v.banner                                          FROM v$version v WHERE v.banner LIKE 'Oracle%' AND ROWNUM = 1
    UNION ALL
    SELECT 4, 'DB Unique Name',       d.db_unique_name                                  FROM v$database d
    UNION ALL
    SELECT 5, 'Open Mode',            d.open_mode                                       FROM v$database d
    UNION ALL
    SELECT 6, 'Container ID',         SYS_CONTEXT('USERENV', 'CON_ID')                 FROM DUAL
    UNION ALL
    SELECT 7, 'Container Name',       SYS_CONTEXT('USERENV', 'CON_NAME')               FROM DUAL
    UNION ALL
    SELECT 8, 'CDB Name',             SYS_CONTEXT('USERENV', 'CDB_NAME')               FROM DUAL
    UNION ALL
    SELECT 9, 'Audit Mode',
        CASE WHEN (SELECT value FROM v$option WHERE parameter = 'Unified Auditing') = 'TRUE'
             THEN 'PURE UNIFIED' ELSE 'MIXED / TRADITIONAL' END
    FROM DUAL
)
ORDER BY id;
TTITLE OFF

-- ============================================================================
-- Section 2: Audit-relevant init.ora Parameters
-- ============================================================================
TTITLE '2. Audit-relevant init.ora Parameters'
COL info_name  FOR A35
COL info_value FOR A90
SELECT name AS info_name, value AS info_value
FROM   v$parameter
WHERE  name IN (
    'audit_trail',
    'audit_file_dest',
    'audit_sys_operations',
    'audit_syslog_level',
    'unified_audit',
    'unified_audit_common_systemlog',
    'unified_audit_systemlog',
    'unified_audit_trail_exclude_columns'
)
ORDER BY name;
TTITLE OFF

-- ============================================================================
-- Section 3: Audit Trail Tablespace and Segment Sizes
-- ============================================================================
TTITLE '3. Audit Trail Tablespace and Segment Sizes'
WITH seg_size AS (
    SELECT owner, segment_name,
           SUM(bytes) total_bytes
    FROM   dba_segments
    WHERE  segment_name IN ('AUD$', 'FGA_LOG$', 'AUD$UNIFIED')
    GROUP BY owner, segment_name
),
fmt AS (
    SELECT t.owner, t.table_name,
           TO_CHAR(t.last_analyzed, 'DD.MM.YYYY HH24:MI:SS') last_analyzed,
           t.num_rows,
           t.avg_row_len,
           s.total_bytes
    FROM   dba_tables t
           LEFT JOIN seg_size s ON s.segment_name = t.table_name
    WHERE  t.table_name IN ('AUD$', 'FGA_LOG$', 'AUD$UNIFIED')
)
SELECT
    owner,
    table_name,
    last_analyzed,
    num_rows,
    avg_row_len,
    CASE
        WHEN num_rows * avg_row_len >= 1073741824 THEN TO_CHAR(ROUND(num_rows * avg_row_len / 1073741824, 1)) || 'G'
        WHEN num_rows * avg_row_len >= 1048576    THEN TO_CHAR(ROUND(num_rows * avg_row_len / 1048576, 1))    || 'M'
        WHEN num_rows * avg_row_len >= 1024       THEN TO_CHAR(ROUND(num_rows * avg_row_len / 1024))          || 'K'
        ELSE TO_CHAR(NVL(num_rows * avg_row_len, 0))
    END  AS data_size,
    CASE
        WHEN total_bytes IS NULL                THEN '-'
        WHEN total_bytes >= 1073741824 THEN TO_CHAR(ROUND(total_bytes / 1073741824, 1)) || 'G'
        WHEN total_bytes >= 1048576    THEN TO_CHAR(ROUND(total_bytes / 1048576, 1))    || 'M'
        WHEN total_bytes >= 1024       THEN TO_CHAR(ROUND(total_bytes / 1024))          || 'K'
        ELSE TO_CHAR(total_bytes)
    END  AS total_size
FROM fmt
ORDER BY table_name;
TTITLE OFF

-- ============================================================================
-- Section 4: Record Counts per Audit Trail
-- ============================================================================
TTITLE '4. Record Counts per Audit Trail'
SELECT 'AUD$' "table_name", min_rec, max_rec, rec_day, rec_month, rec_year, rec_tot FROM
  (SELECT MIN(ntimestamp#) min_rec FROM sys.aud$),
  (SELECT MAX(ntimestamp#) max_rec FROM sys.aud$),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_day   FROM sys.aud$ GROUP BY TO_CHAR(ntimestamp#, 'YYYY.MM.DD')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_month FROM sys.aud$ GROUP BY TO_CHAR(ntimestamp#, 'YYYY.MM')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_year  FROM sys.aud$ GROUP BY TO_CHAR(ntimestamp#, 'YYYY')),
  (SELECT NVL(COUNT(*), 0)      rec_tot   FROM sys.aud$)
UNION
SELECT 'FGA_LOG$' "table_name", min_rec, max_rec, rec_day, rec_month, rec_year, rec_tot FROM
  (SELECT MAX(timestamp) max_rec FROM dba_fga_audit_trail),
  (SELECT MIN(timestamp) min_rec FROM dba_fga_audit_trail),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_day   FROM dba_fga_audit_trail GROUP BY TO_CHAR(timestamp, 'YYYY.MM.DD')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_month FROM dba_fga_audit_trail GROUP BY TO_CHAR(timestamp, 'YYYY.MM')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_year  FROM dba_fga_audit_trail GROUP BY TO_CHAR(timestamp, 'YYYY')),
  (SELECT NVL(COUNT(*), 0)      rec_tot   FROM dba_fga_audit_trail)
UNION
SELECT 'UNIFIED_AUDIT_TRAIL' "table_name", min_rec, max_rec, rec_day, rec_month, rec_year, rec_tot FROM
  (SELECT MAX(event_timestamp) max_rec FROM unified_audit_trail),
  (SELECT MIN(event_timestamp) min_rec FROM unified_audit_trail),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_day   FROM unified_audit_trail GROUP BY TO_CHAR(event_timestamp, 'YYYY.MM.DD')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_month FROM unified_audit_trail GROUP BY TO_CHAR(event_timestamp, 'YYYY.MM')),
  (SELECT NVL(AVG(COUNT(*)), 0) rec_year  FROM unified_audit_trail GROUP BY TO_CHAR(event_timestamp, 'YYYY')),
  (SELECT NVL(COUNT(*), 0)      rec_tot   FROM unified_audit_trail);
TTITLE OFF

-- ============================================================================
-- Section 5: Unified Audit Trail Storage Details
-- ============================================================================
TTITLE '5. Unified Audit Trail Storage Details'
SELECT name, value
FROM (
    SELECT 1  AS id, 'Total unified audit records'  AS name, TO_CHAR(COUNT(*)) AS value
    FROM unified_audit_trail
    UNION ALL
    SELECT 2,
           'Records for current DBID (' || CON_ID_TO_DBID(SYS_CONTEXT('USERENV', 'CON_ID')) || ')',
           TO_CHAR(COUNT(*))
    FROM   unified_audit_trail
    WHERE  dbid = CON_ID_TO_DBID(SYS_CONTEXT('USERENV', 'CON_ID'))
    UNION ALL
    SELECT 3, 'Oldest record (current DBID)',
           TO_CHAR(MIN(event_timestamp), 'DD.MM.YYYY HH24:MI:SS')
    FROM   unified_audit_trail
    WHERE  dbid = CON_ID_TO_DBID(SYS_CONTEXT('USERENV', 'CON_ID'))
    UNION ALL
    SELECT 4, 'Newest record (current DBID)',
           TO_CHAR(MAX(event_timestamp), 'DD.MM.YYYY HH24:MI:SS')
    FROM   unified_audit_trail
    WHERE  dbid = CON_ID_TO_DBID(SYS_CONTEXT('USERENV', 'CON_ID'))
    UNION ALL
    SELECT 5, 'Tablespace(s) in use',
           LISTAGG(DISTINCT tablespace_name, ', ') WITHIN GROUP (ORDER BY tablespace_name)
    FROM   dba_segments WHERE segment_name = 'AUD$UNIFIED'
    UNION ALL
    SELECT 6, 'Number of partitions', TO_CHAR(COUNT(partition_name))
    FROM   dba_tab_partitions WHERE table_name = 'AUD$UNIFIED'
    UNION ALL
    SELECT 7, 'Partition interval', TO_CHAR(interval)
    FROM   dba_part_tables WHERE owner = 'AUDSYS' AND table_name = 'AUD$UNIFIED'
    UNION ALL
    SELECT 8, 'Partition type', partitioning_type
    FROM   dba_part_tables WHERE owner = 'AUDSYS' AND table_name = 'AUD$UNIFIED'
    UNION ALL
    SELECT 9, 'Total segment size (AUDSYS)',
        CASE
            WHEN SUM(bytes) >= 1073741824 THEN TO_CHAR(ROUND(SUM(bytes) / 1073741824, 1)) || 'G'
            WHEN SUM(bytes) >= 1048576    THEN TO_CHAR(ROUND(SUM(bytes) / 1048576, 1))    || 'M'
            WHEN SUM(bytes) >= 1024       THEN TO_CHAR(ROUND(SUM(bytes) / 1024))          || 'K'
            ELSE TO_CHAR(SUM(bytes))
        END
    FROM   dba_segments WHERE owner = 'AUDSYS'
    UNION ALL
    SELECT 9 + ROW_NUMBER() OVER (ORDER BY tablespace_name),
           'Segment size in ' || tablespace_name,
        CASE
            WHEN SUM(bytes) >= 1073741824 THEN TO_CHAR(ROUND(SUM(bytes) / 1073741824, 1)) || 'G'
            WHEN SUM(bytes) >= 1048576    THEN TO_CHAR(ROUND(SUM(bytes) / 1048576, 1))    || 'M'
            WHEN SUM(bytes) >= 1024       THEN TO_CHAR(ROUND(SUM(bytes) / 1024))          || 'K'
            ELSE TO_CHAR(SUM(bytes))
        END
    FROM   dba_segments WHERE owner = 'AUDSYS'
    GROUP BY tablespace_name
)
ORDER BY id;
TTITLE OFF

-- ============================================================================
-- Section 6: DBMS_AUDIT_MGMT Configuration Parameters
-- ============================================================================
TTITLE '6. DBMS_AUDIT_MGMT Configuration Parameters'
SELECT audit_trail, parameter_name, parameter_value
FROM   dba_audit_mgmt_config_params
ORDER BY audit_trail, parameter_name;
TTITLE OFF

-- ============================================================================
-- Section 7: Archive Timestamps
-- ============================================================================
TTITLE '7. Archive Timestamps'
SELECT
    audit_trail,
    rac_instance,
    TO_CHAR(last_archive_ts, 'DD.MM.YYYY HH24:MI:SS') AS last_archive_ts,
    database_id
FROM   dba_audit_mgmt_last_arch_ts
ORDER BY audit_trail, rac_instance;
TTITLE OFF

-- ============================================================================
-- Section 8: Audit Cleanup / Purge Jobs
-- ============================================================================
TTITLE '8. Audit Cleanup / Purge Jobs'
SELECT
    job_name,
    job_status,
    audit_trail,
    REGEXP_SUBSTR(TO_CHAR(job_frequency), 'INTERVAL=(\d+)', 1, 1, 'i', 1) AS job_frequency,
    CASE use_last_archive_timestamp WHEN 'YES' THEN 'YES' ELSE 'NO' END    AS use_last_arch,
    job_container
FROM   dba_audit_mgmt_cleanup_jobs
ORDER BY audit_trail, job_name;
TTITLE OFF

-- ============================================================================
-- Section 9: Audit-related Scheduler Jobs
-- ============================================================================
TTITLE '9. Audit-related Scheduler Jobs'
SELECT job_name, state, repeat_interval
FROM   dba_scheduler_jobs
WHERE  UPPER(job_name) LIKE '%AUDIT%'
   OR  UPPER(comments) LIKE '%AUDIT%'
ORDER BY job_name;
TTITLE OFF

SPOOL OFF

PROMPT
PROMPT aud_report_config_aud: completed
PROMPT

-- EOF -------------------------------------------------------------------------
