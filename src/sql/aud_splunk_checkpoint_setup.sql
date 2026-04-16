-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_splunk_checkpoint_setup.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.01
-- Revision..: v0.2.0
-- Usage.....: aud_splunk_checkpoint_setup.sql [SCHEMA] [SPLUNK_USER] [FALLBACK_DAYS]
--
--             SCHEMA         Schema owner for checkpoint table and procedure.
--                            Default: current user (run as DBA/SYSDBA)
--             SPLUNK_USER    DB user that Splunk uses to write checkpoints.
--                            Receives INSERT, UPDATE on splunk_checkpoint.
--                            Default: SPLUNK_READER
--             FALLBACK_DAYS  Days used as rolling window when Splunk checkpoint
--                            is stale (> 4h old). Default: 30
--
-- Purpose...: Set up Splunk archive timestamp management for Oracle Unified
--             Auditing using the K-WD (Watchdog) pattern:
--             K-WD = V-CP (Checkpoint Write) + V-RW (Rolling Window Fallback)
--
--             PREREQUISITE: Splunk must have a write-capable DB account that
--             can INSERT/UPDATE on the SPLUNK_CHECKPOINT table. If Splunk is
--             read-only, use aud_splunk_at_detection_setup.sql (K-AT) instead.
--
--             This script:
--               1. Creates SPLUNK_CHECKPOINT table
--               2. Creates SYNC_ARCHIVE_TIMESTAMP procedure (AUTHID DEFINER)
--               3. Creates hourly Oracle Scheduler job
--               4. Grants INSERT, UPDATE on checkpoint table to Splunk user
--
--             Design: K-WD (Watchdog pattern)
--               - V-CP: Checkpoint fresh (< 4h): precise timestamp based on Splunk reads
--               - V-RW: Checkpoint stale (> 4h): conservative rolling window fallback
--               - Archive timestamp never moved backwards
--
-- Notes.....: Run as SYSDBA or user with AUDIT_ADMIN role in target PDB.
--             Splunk must be configured to write max(EVENT_TIMESTAMP) to
--             SPLUNK_CHECKPOINT after each successful collection cycle.
--             See doc/notes/splunk-archive-timestamp.md for full design (K-WD).
--
-- Connect...: sqlplus / as sysdba
--             ALTER SESSION SET CONTAINER = AUDITPDB1;
--
-- Reference.: doc/notes/splunk-archive-timestamp.md (Variant K-WD)
-- See also..: sql/aud_splunk_at_detection_setup.sql (K-AT, for read-only Splunk)
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- Define default parameter values
DEFINE _schema        = 'SYS'
DEFINE _splunk_user   = 'SPLUNK_READER'
DEFINE _fallback_days = 30

-- Accept parameters with defaults
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
COLUMN 3 NEW_VALUE 3 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
SELECT '' "3" FROM dual WHERE ROWNUM = 0;
DEFINE schema        = &1 &_schema
DEFINE splunk_user   = &2 &_splunk_user
DEFINE fallback_days = &3 &_fallback_days
COLUMN schema NEW_VALUE schema NOPRINT
SELECT upper('&schema') schema FROM dual;
COLUMN splunk_user NEW_VALUE splunk_user NOPRINT
SELECT upper('&splunk_user') splunk_user FROM dual;

-- Configure spool
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

WHENEVER OSERROR CONTINUE
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_${USER}.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_${USER}.sql
@@/tmp/oradba_logdir_${USER}.sql
HOST rm -f /tmp/oradba_logdir_${USER}.sql
WHENEVER OSERROR EXIT FAILURE

COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./aud_splunk_checkpoint_setup_&DBSID._&TIMESTAMP..log
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Types
  SUBTYPE text_type IS VARCHAR2(512 CHAR);

  -- Exceptions
  e_table_exists      EXCEPTION;
  e_job_exists        EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_table_exists, -955);   -- ORA-00955: name already used
  PRAGMA EXCEPTION_INIT(e_job_exists,   -27477);  -- ORA-27477: job already exists

  -- Variables
  l_schema        VARCHAR2(30) := '&schema';
  l_splunk_user   VARCHAR2(30) := '&splunk_user';
  l_fallback_days PLS_INTEGER  := &fallback_days;
  l_sql           text_type;

BEGIN

  sys.dbms_output.put_line('=============================================================');
  sys.dbms_output.put_line('Splunk Archive Timestamp Management - Setup');
  sys.dbms_output.put_line('  Schema:        ' || l_schema);
  sys.dbms_output.put_line('  Splunk user:   ' || l_splunk_user);
  sys.dbms_output.put_line('  Fallback days: ' || l_fallback_days);
  sys.dbms_output.put_line('=============================================================');

  -- ------------------------------------------------------------------
  -- Step 1: Create SPLUNK_CHECKPOINT table
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 1: Create SPLUNK_CHECKPOINT table... ');
  <<create_checkpoint_table>>
  BEGIN
    l_sql :=
      'CREATE TABLE ' || l_schema || '.splunk_checkpoint (' ||
      '  collector_id    VARCHAR2(64)             NOT NULL,' ||
      '  last_read_ts    TIMESTAMP WITH TIME ZONE NOT NULL,' ||
      '  updated_at      TIMESTAMP WITH TIME ZONE' ||
      '    DEFAULT SYSTIMESTAMP NOT NULL,' ||
      '  CONSTRAINT pk_splunk_checkpoint PRIMARY KEY (collector_id)' ||
      ')';
    EXECUTE IMMEDIATE l_sql;
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_table_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_checkpoint_table;

  -- Comment on table and columns
  EXECUTE IMMEDIATE
    'COMMENT ON TABLE ' || l_schema || '.splunk_checkpoint IS ' ||
    q'['Tracks last EVENT_TIMESTAMP read by each Splunk collector instance. ]' ||
    q'[Updated by Splunk DB Connect after each successful collection. ]' ||
    q'[Read by SYNC_ARCHIVE_TIMESTAMP job to manage DBMS_AUDIT_MGMT archive timestamp. ]' ||
    q'[See doc/notes/splunk-archive-timestamp.md for design rationale.']';

  EXECUTE IMMEDIATE
    'COMMENT ON COLUMN ' || l_schema || '.splunk_checkpoint.collector_id IS ' ||
    q'['Unique identifier for this Splunk DB Connect input (e.g. SPLUNK_PROD_01)']';

  EXECUTE IMMEDIATE
    'COMMENT ON COLUMN ' || l_schema || '.splunk_checkpoint.last_read_ts IS ' ||
    q'['MAX(EVENT_TIMESTAMP) from last successful Splunk collection']';

  EXECUTE IMMEDIATE
    'COMMENT ON COLUMN ' || l_schema || '.splunk_checkpoint.updated_at IS ' ||
    q'['Timestamp when Splunk last updated this checkpoint (staleness detection)']';

  -- ------------------------------------------------------------------
  -- Step 2: Create SYNC_ARCHIVE_TIMESTAMP procedure
  --         AUTHID DEFINER: procedure runs with owner privileges
  --         (requires AUDIT_ADMIN or SYSDBA - caller needs only EXECUTE)
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 2: Create SYNC_ARCHIVE_TIMESTAMP procedure... ');
  l_sql := q'[
CREATE OR REPLACE PROCEDURE ]' || l_schema || q'[.sync_archive_timestamp(
  p_fallback_days IN NUMBER DEFAULT ]' || l_fallback_days || q'[,
  p_safety_min    IN NUMBER DEFAULT 15,
  p_stale_hours   IN NUMBER DEFAULT 4
) AUTHID DEFINER AS
  -- Tracks the MIN last_read_ts across all active Splunk collectors.
  -- "Active" means updated within p_stale_hours.
  -- If no active checkpoint found, falls back to a conservative rolling window.
  -- Archive timestamp is never moved backwards.

  v_checkpoint_ts   TIMESTAMP WITH TIME ZONE;
  v_archive_ts      TIMESTAMP WITH TIME ZONE;
  v_current_ts      TIMESTAMP WITH TIME ZONE;
  v_stale_threshold INTERVAL DAY TO SECOND;
  v_mode            VARCHAR2(20);
BEGIN
  v_stale_threshold := NUMTODSINTERVAL(p_stale_hours, 'HOUR');

  -- Read MIN checkpoint across all active collectors
  -- MIN ensures we do not purge records not yet read by the slowest collector
  SELECT MIN(last_read_ts)
  INTO   v_checkpoint_ts
  FROM   ]' || l_schema || q'[.splunk_checkpoint
  WHERE  (SYSTIMESTAMP - updated_at) < v_stale_threshold;

  IF v_checkpoint_ts IS NOT NULL THEN
    -- Precise: archive up to what Splunk has confirmed reading,
    -- minus a safety buffer to absorb timing edge cases
    v_archive_ts := v_checkpoint_ts - NUMTODSINTERVAL(p_safety_min, 'MINUTE');
    v_mode       := 'CHECKPOINT';
  ELSE
    -- Fallback: Splunk checkpoint is stale or absent.
    -- Conservative rolling window prevents unbounded growth.
    v_archive_ts := SYSTIMESTAMP - NUMTODSINTERVAL(p_fallback_days, 'DAY');
    v_mode       := 'FALLBACK';
  END IF;

  -- Read current archive timestamp (may not exist on first run)
  BEGIN
    SELECT last_archive_ts INTO v_current_ts
    FROM   sys.dba_audit_mgmt_last_arch_ts
    WHERE  audit_trail = 'UNIFIED AUDIT TRAIL';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v_current_ts := NULL;
  END;

  -- Only advance the timestamp, never move it backwards
  IF v_current_ts IS NULL OR v_archive_ts > v_current_ts THEN
    sys.dbms_audit_mgmt.set_last_archive_timestamp(
      audit_trail_type  => sys.dbms_audit_mgmt.audit_trail_unified,
      last_archive_time => v_archive_ts);
    sys.dbms_output.put_line(
      'sync_archive_timestamp: mode=' || v_mode ||
      ' archive_ts=' || TO_CHAR(v_archive_ts, 'YYYY-MM-DD HH24:MI:SS TZH:TZM'));
  ELSE
    sys.dbms_output.put_line(
      'sync_archive_timestamp: mode=' || v_mode ||
      ' no update needed (archive_ts <= current_ts)');
  END IF;
END sync_archive_timestamp;]';

  EXECUTE IMMEDIATE l_sql;
  sys.dbms_output.put_line('created');

  -- ------------------------------------------------------------------
  -- Step 3: Create hourly Oracle Scheduler job
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 3: Create SPLUNK_ARCHIVE_TS_SYNC scheduler job... ');
  <<create_scheduler_job>>
  BEGIN
    sys.dbms_scheduler.create_job(
      job_name        => 'SPLUNK_ARCHIVE_TS_SYNC',
      job_type        => 'PLSQL_BLOCK',
      job_action      => 'BEGIN ' || l_schema || '.sync_archive_timestamp; END;',
      start_date      => SYSTIMESTAMP,
      repeat_interval => 'FREQ=HOURLY;INTERVAL=1',
      enabled         => TRUE,
      comments        =>
        'Syncs DBMS_AUDIT_MGMT LAST_ARCHIVE_TIMESTAMP from Splunk checkpoint table. ' ||
        'Uses precise checkpoint when fresh, falls back to rolling window when stale. ' ||
        'Part of Splunk JDBC audit retention management. ' ||
        'See doc/notes/splunk-archive-timestamp.md'
    );
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_job_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_scheduler_job;

  -- ------------------------------------------------------------------
  -- Step 4: Grant privileges to Splunk checkpoint writer
  --         Splunk needs only INSERT, UPDATE - no access to audit trail mgmt
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 4: Grant INSERT, UPDATE on SPLUNK_CHECKPOINT to ' ||
                      l_splunk_user || '... ');
  BEGIN
    EXECUTE IMMEDIATE
      'GRANT INSERT, UPDATE ON ' || l_schema || '.splunk_checkpoint' ||
      ' TO ' || l_splunk_user;
    sys.dbms_output.put_line('granted');
  EXCEPTION
    WHEN OTHERS THEN
      sys.dbms_output.put_line('WARNING: ' || SQLERRM);
      sys.dbms_output.put_line(
        '  Run manually: GRANT INSERT, UPDATE ON ' ||
        l_schema || '.splunk_checkpoint TO ' || l_splunk_user || ';');
  END;

  sys.dbms_output.put_line('=============================================================');
  sys.dbms_output.put_line('Setup complete.');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('Next steps:');
  sys.dbms_output.put_line('  1. Configure Splunk DB Connect to write checkpoint:');
  sys.dbms_output.put_line('     MERGE INTO ' || l_schema || '.splunk_checkpoint t');
  sys.dbms_output.put_line('     USING (SELECT ''SPLUNK_PROD_01'' AS collector_id,');
  sys.dbms_output.put_line('                   :last_event_ts AS last_read_ts FROM DUAL) s');
  sys.dbms_output.put_line('     ON (t.collector_id = s.collector_id)');
  sys.dbms_output.put_line('     WHEN MATCHED THEN UPDATE');
  sys.dbms_output.put_line('       SET last_read_ts = s.last_read_ts,');
  sys.dbms_output.put_line('           updated_at   = SYSTIMESTAMP');
  sys.dbms_output.put_line('     WHEN NOT MATCHED THEN INSERT');
  sys.dbms_output.put_line('       (collector_id, last_read_ts)');
  sys.dbms_output.put_line('       VALUES (s.collector_id, s.last_read_ts);');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('  2. Verify Purge Job exists (from aud_init_full_aud.sql):');
  sys.dbms_output.put_line('     SELECT job_name, job_status, use_last_arch_timestamp');
  sys.dbms_output.put_line('     FROM   dba_audit_mgmt_cleanup_jobs;');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('  3. Test sync manually:');
  sys.dbms_output.put_line('     EXEC ' || l_schema || '.sync_archive_timestamp;');
  sys.dbms_output.put_line('     SELECT * FROM dba_audit_mgmt_last_arch_ts;');
  sys.dbms_output.put_line('=============================================================');

END;
/

-- ------------------------------------------------------------------
-- Verification: Show current state
-- ------------------------------------------------------------------
PROMPT
PROMPT >> Scheduler job status:
COL job_name        FOR a30
COL job_status      FOR a10
COL repeat_interval FOR a35
COL comments        FOR a55
SELECT job_name, enabled, repeat_interval, comments
FROM   dba_scheduler_jobs
WHERE  job_name = 'SPLUNK_ARCHIVE_TS_SYNC';

PROMPT
PROMPT >> Checkpoint table:
COL table_name FOR a30
COL comments   FOR a60
SELECT t.table_name, c.comments
FROM   dba_tables t
LEFT JOIN dba_tab_comments c
  ON  c.owner = t.owner AND c.table_name = t.table_name
WHERE  t.table_name = 'SPLUNK_CHECKPOINT'
AND    t.owner      = upper('&schema');

PROMPT
PROMPT >> Current archive timestamps:
COL audit_trail     FOR a25
COL last_archive_ts FOR a35
SELECT audit_trail, last_archive_ts
FROM   dba_audit_mgmt_last_arch_ts
ORDER BY audit_trail;

PROMPT
PROMPT >> Purge jobs (use_last_arch_timestamp must be YES):
COL job_name               FOR a35
COL audit_trail            FOR a25
COL use_last_arch_timestamp FOR a5
SELECT job_name, job_status, audit_trail, use_last_arch_timestamp
FROM   dba_audit_mgmt_cleanup_jobs
ORDER BY job_name;

SPOOL OFF
-- EOF -------------------------------------------------------------------------
