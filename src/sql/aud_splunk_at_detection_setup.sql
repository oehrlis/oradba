-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_splunk_at_detection_setup.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.02
-- Revision..: v0.1.0
-- Usage.....: aud_splunk_at_detection_setup.sql [SPLUNK_USER] [FALLBACK_DAYS] \
--                                               [COLLECTION_INTERVAL_MIN] [SAFETY_MIN]
--
--             SPLUNK_USER            DB user Splunk uses to read UNIFIED_AUDIT_TRAIL.
--                                    Must be a dedicated user (not shared).
--                                    Default: SPLUNK_READER
--             FALLBACK_DAYS          Rolling window when no Splunk read detected.
--                                    Default: 30
--             COLLECTION_INTERVAL_MIN  Splunk collection interval in minutes.
--                                    Used in archive timestamp calculation.
--                                    archive_ts = max_splunk_ts - interval - safety
--                                    Default: 60
--             SAFETY_MIN             Safety buffer in minutes subtracted from
--                                    archive timestamp. Default: 15
--
-- Purpose...: Set up Splunk archive timestamp management using Audit Trail
--             Detection (K-AT = V-AT + V-RW Fallback).
--
--             Splunk JDBC reads UNIFIED_AUDIT_TRAIL in read-only mode.
--             Oracle detects Splunk reads by querying its own UNIFIED_AUDIT_TRAIL
--             for SELECT events by the Splunk user, then sets the archive timestamp.
--
--             Design: K-AT (AT-Watchdog pattern)
--               - Audit Policy ODB_SPLUNK_SESSION_AUD audits Splunk SELECTs
--               - Logon trigger sets CLIENT_IDENTIFIER for JDBC sessions
--               - SYNC_ARCHIVE_TS_FROM_AUDIT reads audit trail for Splunk reads
--               - Fresh read (< 4h): archive_ts = max_ts - interval - safety
--               - No recent read: archive_ts = SYSTIMESTAMP - fallback_days (V-RW)
--               - Archive timestamp never moved backwards
--
--             IMPORTANT: Verify audit record format in your environment before
--             production deployment. Run Step 0 verification queries after setup.
--             See doc/notes/splunk-archive-timestamp.md for full design.
--
-- Notes.....: Run as SYSDBA or user with AUDIT_ADMIN role in target PDB.
--             Splunk does NOT need to write anything - pure read-only JDBC.
--             The Splunk user must be dedicated (not shared with other tools).
--
-- Connect...: sqlplus / as sysdba
--             ALTER SESSION SET CONTAINER = AUDITPDB1;
--
-- Reference.: doc/notes/splunk-archive-timestamp.md (Variant K-AT)
--             doc/notes/splunkt-chat.md (V-AT design discussion)
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- Define default parameter values
DEFINE _splunk_user              = 'SPLUNK_READER'
DEFINE _fallback_days            = 30
DEFINE _collection_interval_min  = 60
DEFINE _safety_min               = 15

-- Accept parameters with defaults
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
COLUMN 3 NEW_VALUE 3 NOPRINT
COLUMN 4 NEW_VALUE 4 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
SELECT '' "3" FROM dual WHERE ROWNUM = 0;
SELECT '' "4" FROM dual WHERE ROWNUM = 0;
DEFINE splunk_user              = &1 &_splunk_user
DEFINE fallback_days            = &2 &_fallback_days
DEFINE collection_interval_min  = &3 &_collection_interval_min
DEFINE safety_min               = &4 &_safety_min
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

SPOOL &LOGDIR./aud_splunk_at_detection_setup_&DBSID._&TIMESTAMP..log
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Types
  SUBTYPE text_type IS VARCHAR2(512 CHAR);

  -- Exceptions
  e_obj_exists        EXCEPTION;
  e_policy_exists     EXCEPTION;
  e_job_exists        EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_obj_exists,    -955);    -- ORA-00955: name already used
  PRAGMA EXCEPTION_INIT(e_policy_exists, -46358);  -- ORA-46358: audit policy exists
  PRAGMA EXCEPTION_INIT(e_job_exists,    -27477);  -- ORA-27477: job already exists

  -- Variables
  l_splunk_user             VARCHAR2(30)  := '&splunk_user';
  l_fallback_days           PLS_INTEGER   := &fallback_days;
  l_collection_interval_min PLS_INTEGER   := &collection_interval_min;
  l_safety_min              PLS_INTEGER   := &safety_min;
  l_sql                     text_type;

BEGIN

  sys.dbms_output.put_line('=============================================================');
  sys.dbms_output.put_line('Splunk K-AT Setup: Audit Trail Detection + Rolling Fallback');
  sys.dbms_output.put_line('  Splunk user:       ' || l_splunk_user);
  sys.dbms_output.put_line('  Fallback days:     ' || l_fallback_days);
  sys.dbms_output.put_line('  Collection interval: ' || l_collection_interval_min || ' min');
  sys.dbms_output.put_line('  Safety buffer:     ' || l_safety_min || ' min');
  sys.dbms_output.put_line('  archive_ts formula: max_splunk_select_ts');
  sys.dbms_output.put_line('                    - ' || l_collection_interval_min || 'min (collection)');
  sys.dbms_output.put_line('                    - ' || l_safety_min || 'min (safety)');
  sys.dbms_output.put_line('=============================================================');

  -- ------------------------------------------------------------------
  -- Step 1: Create Audit Policy for Splunk user
  --         Audits SELECT on UNIFIED_AUDIT_TRAIL by the Splunk user.
  --         IMPORTANT: Verify the audit record format in your environment.
  --         See doc/notes/splunk-archive-timestamp.md - "Prüfhinweise".
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 1: Create audit policy ODB_SPLUNK_SESSION_AUD... ');
  <<create_audit_policy>>
  BEGIN
    -- Option A (preferred): Audit only SELECT on UNIFIED_AUDIT_TRAIL view.
    -- Verify that OBJECT_NAME in audit records matches 'UNIFIED_AUDIT_TRAIL'.
    -- Uncomment Option B if Option A does not produce the expected audit records.
    EXECUTE IMMEDIATE
      'CREATE AUDIT POLICY ODB_SPLUNK_SESSION_AUD' ||
      ' ACTIONS SELECT ON sys.unified_audit_trail';
    sys.dbms_output.put_line('created (SELECT ON unified_audit_trail)');
  EXCEPTION
    WHEN e_policy_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_audit_policy;

  -- Option B (fallback): Audit ALL actions by Splunk user.
  -- Higher volume but more reliable detection across Oracle versions.
  -- EXECUTE IMMEDIATE 'CREATE AUDIT POLICY ODB_SPLUNK_SESSION_AUD ACTIONS ALL';

  -- Add comment to the policy
  EXECUTE IMMEDIATE
    'COMMENT ON AUDIT POLICY ODB_SPLUNK_SESSION_AUD IS ' ||
    q'['Audits Splunk JDBC SELECT on UNIFIED_AUDIT_TRAIL for K-AT archive timestamp detection. ]' ||
    q'[Job SPLUNK_AT_SYNC reads MAX(event_timestamp) for SPLUNK_READER to derive archive_ts. ]' ||
    q'[See doc/notes/splunk-archive-timestamp.md for design rationale.']';

  -- Activate policy for the Splunk user
  sys.dbms_output.put('         Enabling ODB_SPLUNK_SESSION_AUD for ' || l_splunk_user || '... ');
  EXECUTE IMMEDIATE
    'AUDIT POLICY ODB_SPLUNK_SESSION_AUD BY ' || l_splunk_user;
  sys.dbms_output.put_line('enabled');

  -- ------------------------------------------------------------------
  -- Step 2: Create logon trigger to mark Splunk JDBC sessions
  --         Sets CLIENT_IDENTIFIER = 'SPLUNK_DBX' for the Splunk user.
  --         This distinguishes automated JDBC sessions from interactive
  --         sessions (which would not normally go through JDBC in the
  --         same way, but we rely on this for V-LT if used).
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 2: Create logon trigger TRG_SPLUNK_SESSION_CTX... ');
  l_sql := q'[
CREATE OR REPLACE TRIGGER trg_splunk_session_ctx
AFTER LOGON ON DATABASE
-- Sets CLIENT_IDENTIFIER and MODULE for automated Splunk JDBC sessions.
-- Required for K-AT (V-AT Audit Trail Detection) and K-LT (V-LT Logoff Trigger).
-- Splunk user: ]' || l_splunk_user || q'[
BEGIN
  IF SYS_CONTEXT('USERENV', 'SESSION_USER') = ']' || l_splunk_user || q'[' THEN
    DBMS_SESSION.SET_IDENTIFIER('SPLUNK_DBX');
    DBMS_APPLICATION_INFO.SET_MODULE(
      module_name => 'SPLUNK_DBX',
      action_name => 'DB_CONNECT');
  END IF;
END trg_splunk_session_ctx;]';
  EXECUTE IMMEDIATE l_sql;
  sys.dbms_output.put_line('created');

  -- ------------------------------------------------------------------
  -- Step 3: Create SYNC_ARCHIVE_TS_FROM_AUDIT procedure
  --         AUTHID DEFINER: runs with SYS/owner privileges.
  --         Reads UNIFIED_AUDIT_TRAIL for last Splunk SELECT.
  --         Computes archive_ts = max_ts - collection_interval - safety.
  --         Falls back to rolling window if no recent Splunk read found.
  --         Never moves archive timestamp backwards.
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 3: Create SYNC_ARCHIVE_TS_FROM_AUDIT procedure... ');
  l_sql := q'[
CREATE OR REPLACE PROCEDURE sys.sync_archive_ts_from_audit(
  p_splunk_user     IN VARCHAR2 DEFAULT ']' || l_splunk_user || q'[',
  p_fallback_days   IN NUMBER   DEFAULT ]' || l_fallback_days || q'[,
  p_interval_min    IN NUMBER   DEFAULT ]' || l_collection_interval_min || q'[,
  p_safety_min      IN NUMBER   DEFAULT ]' || l_safety_min || q'[,
  p_stale_hours     IN NUMBER   DEFAULT 4
) AUTHID DEFINER AS
  -- K-AT: Audit Trail Detection + Rolling Window Fallback
  --
  -- Reads UNIFIED_AUDIT_TRAIL for the most recent SELECT by the Splunk user.
  -- If a recent read is found (< p_stale_hours old):
  --   archive_ts = max_splunk_select_ts - p_interval_min - p_safety_min
  -- If no recent read found:
  --   archive_ts = SYSTIMESTAMP - p_fallback_days   (V-RW Fallback)
  --
  -- Archive timestamp is never moved backwards.
  --
  -- IMPORTANT: The audit record for Splunk SELECT must exist in UNIFIED_AUDIT_TRAIL.
  -- Verify: SELECT event_timestamp, action_name, object_name FROM unified_audit_trail
  --         WHERE dbusername = 'SPLUNK_READER' AND action_name = 'SELECT';

  v_max_splunk_ts   TIMESTAMP WITH TIME ZONE;
  v_archive_ts      TIMESTAMP WITH TIME ZONE;
  v_current_ts      TIMESTAMP WITH TIME ZONE;
  v_mode            VARCHAR2(20);
BEGIN
  -- Find the most recent Splunk SELECT in the audit trail
  -- Filter: within p_stale_hours to detect Splunk outage
  SELECT MAX(event_timestamp)
  INTO   v_max_splunk_ts
  FROM   sys.unified_audit_trail
  WHERE  dbusername = p_splunk_user
    AND  action_name = 'SELECT'
    AND  (SYSTIMESTAMP - event_timestamp) < NUMTODSINTERVAL(p_stale_hours, 'HOUR');

  IF v_max_splunk_ts IS NOT NULL THEN
    -- V-AT: Precise timestamp based on confirmed Splunk read.
    -- Subtract collection interval: Splunk at time T has read data up to T.
    -- Subtract safety buffer: absorb timing edge cases and indexing lag.
    -- Result: data before this timestamp was definitely in Splunk's last read.
    v_archive_ts := v_max_splunk_ts
                  - NUMTODSINTERVAL(p_interval_min, 'MINUTE')
                  - NUMTODSINTERVAL(p_safety_min, 'MINUTE');
    v_mode := 'V-AT';
  ELSE
    -- V-RW Fallback: No recent Splunk read detected.
    -- Conservative rolling window prevents unbounded audit trail growth.
    v_archive_ts := SYSTIMESTAMP - NUMTODSINTERVAL(p_fallback_days, 'DAY');
    v_mode := 'V-RW-FALLBACK';
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
      'sync_archive_ts_from_audit: mode=' || v_mode ||
      ' archive_ts=' || TO_CHAR(v_archive_ts, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') ||
      ' max_splunk_ts=' || NVL(TO_CHAR(v_max_splunk_ts, 'YYYY-MM-DD HH24:MI:SS'), 'NULL'));
  ELSE
    sys.dbms_output.put_line(
      'sync_archive_ts_from_audit: mode=' || v_mode ||
      ' no update (computed_ts <= current_ts)');
  END IF;
END sync_archive_ts_from_audit;]';

  EXECUTE IMMEDIATE l_sql;
  sys.dbms_output.put_line('created');

  -- ------------------------------------------------------------------
  -- Step 4: Create Oracle Scheduler job (hourly, offset from Splunk)
  --         Run 30 minutes after Splunk's collection cycle to ensure
  --         the audit record from Splunk's read is already visible.
  -- ------------------------------------------------------------------
  sys.dbms_output.put('Step 4: Create SPLUNK_AT_SYNC scheduler job... ');
  <<create_scheduler_job>>
  BEGIN
    sys.dbms_scheduler.create_job(
      job_name        => 'SPLUNK_AT_SYNC',
      job_type        => 'PLSQL_BLOCK',
      job_action      => 'BEGIN sys.sync_archive_ts_from_audit; END;',
      start_date      => SYSTIMESTAMP,
      repeat_interval => 'FREQ=HOURLY;BYMINUTE=30',  -- runs at :30 each hour
      enabled         => TRUE,
      comments        =>
        'K-AT: Syncs DBMS_AUDIT_MGMT LAST_ARCHIVE_TIMESTAMP from Unified Audit Trail. ' ||
        'Detects Splunk reads via audit records (V-AT). ' ||
        'Falls back to rolling window when Splunk inactive (V-RW). ' ||
        'See doc/notes/splunk-archive-timestamp.md.'
    );
    sys.dbms_output.put_line('created (FREQ=HOURLY;BYMINUTE=30)');
  EXCEPTION
    WHEN e_job_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_scheduler_job;

  sys.dbms_output.put_line('=============================================================');
  sys.dbms_output.put_line('K-AT Setup complete.');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('IMPORTANT: Verify audit record format before production use!');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('Next steps:');
  sys.dbms_output.put_line('  1. Connect as ' || l_splunk_user || ' and run a SELECT:');
  sys.dbms_output.put_line('     SELECT COUNT(*) FROM unified_audit_trail;');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('  2. Check audit record format (run as SYSDBA):');
  sys.dbms_output.put_line('     SELECT event_timestamp, action_name, object_schema,');
  sys.dbms_output.put_line('            object_name, client_id, dbusername');
  sys.dbms_output.put_line('     FROM   unified_audit_trail');
  sys.dbms_output.put_line('     WHERE  dbusername = ''' || l_splunk_user || '''');
  sys.dbms_output.put_line('     AND    action_name = ''SELECT''');
  sys.dbms_output.put_line('     ORDER  BY event_timestamp DESC FETCH FIRST 5 ROWS ONLY;');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('  3. Test sync manually:');
  sys.dbms_output.put_line('     EXEC sys.sync_archive_ts_from_audit;');
  sys.dbms_output.put_line('     SELECT * FROM dba_audit_mgmt_last_arch_ts;');
  sys.dbms_output.put_line('');
  sys.dbms_output.put_line('  4. If OBJECT_NAME in audit records is not UNIFIED_AUDIT_TRAIL:');
  sys.dbms_output.put_line('     Add WHERE object_name = <actual_name> filter to procedure.');
  sys.dbms_output.put_line('=============================================================');

END;
/

-- ------------------------------------------------------------------
-- Verification: Show current state
-- ------------------------------------------------------------------
PROMPT
PROMPT >> Audit policy status:
COL policy_name     FOR a30
COL enabled_opt     FOR a15
COL user_name       FOR a20
COL success         FOR a10
COL failure         FOR a10
SELECT policy_name, enabled_opt, user_name, success, failure
FROM   audit_unified_enabled_policies
WHERE  policy_name = 'ODB_SPLUNK_SESSION_AUD';

PROMPT
PROMPT >> Logon trigger status:
COL trigger_name  FOR a30
COL trigger_type  FOR a20
COL status        FOR a10
SELECT trigger_name, trigger_type, status
FROM   dba_triggers
WHERE  trigger_name = 'TRG_SPLUNK_SESSION_CTX';

PROMPT
PROMPT >> Scheduler job status:
COL job_name        FOR a30
COL repeat_interval FOR a35
COL comments        FOR a55
SELECT job_name, enabled, repeat_interval, comments
FROM   dba_scheduler_jobs
WHERE  job_name = 'SPLUNK_AT_SYNC';

PROMPT
PROMPT >> Current archive timestamps:
COL audit_trail     FOR a25
COL last_archive_ts FOR a35
SELECT audit_trail, last_archive_ts
FROM   dba_audit_mgmt_last_arch_ts
ORDER  BY audit_trail;

PROMPT
PROMPT >> Purge jobs (use_last_arch_timestamp must be YES):
COL job_name                FOR a35
COL audit_trail             FOR a25
COL use_last_arch_timestamp FOR a5
SELECT job_name, job_status, audit_trail, use_last_arch_timestamp
FROM   dba_audit_mgmt_cleanup_jobs
ORDER  BY job_name;

PROMPT
PROMPT >> Splunk user existence check:
SELECT username, account_status, created
FROM   dba_users
WHERE  username = upper('&splunk_user');

PROMPT
PROMPT >> Step 0 Verification - run after first Splunk test connection:
PROMPT    SELECT event_timestamp, action_name, object_schema, object_name,
PROMPT           client_id, dbusername, sql_text
PROMPT    FROM   unified_audit_trail
PROMPT    WHERE  dbusername = upper('&splunk_user') AND action_name = 'SELECT'
PROMPT    ORDER  BY event_timestamp DESC FETCH FIRST 5 ROWS ONLY;

SPOOL OFF
-- EOF -------------------------------------------------------------------------
