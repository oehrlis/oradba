-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_init_jobs_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.25
-- Revision..: 0.24.0
-- Usage.....: aud_init_jobs_aud.sql <AUDIT RETENTION>
--
--              AUDIT RETENTION   Days for which an audit timestamp will be created e.g.
--                                sysdate - <AUDIT RETENTION>. This defines the time window
--                                where audit records will be available on the system. This
--                                amount of DAYS is also the fallback when the AVAGENT does
--                                not create timestamps. Default 30 days
-- Purpose...: Create audit scheduler jobs.
--              - DAILY_UNIFIED_AUDIT_TIMESTAMP: sets archive timestamp for unified audit
--              - Daily_Unified_Audit_Purge_Job: purges audit records beyond archive timestamp
--              Part of the audit initialization suite. Can also be called standalone.
-- Notes.....: Called by aud_init_full_aud.sql. Requires AUDIT_ADMIN role.
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _audit_retention = 30

-- assign default value for parameter if argument 1 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE audit_retention = &1 &_audit_retention

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

SPOOL &LOGDIR./aud_init_jobs_aud_&DBSID._&TIMESTAMP..log
-- Anonymous PL/SQL Block to create audit scheduler jobs
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Types
  SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent

  -- Exception handling
  e_job_exists       EXCEPTION;
  e_audit_job_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_job_exists,       -27477);
  PRAGMA EXCEPTION_INIT(e_audit_job_exists, -46254);

BEGIN

  -- Create daily archive timestamp job for Unified Audit Trail
  sys.dbms_output.put_line('Create archive timestamp jobs');
  sys.dbms_output.put('- Unified Audit Trail........... ');
  <<create_ts_job>>
  BEGIN
    sys.dbms_scheduler.create_job(
      job_name        => 'DAILY_UNIFIED_AUDIT_TIMESTAMP',
      job_type        => 'PLSQL_BLOCK',
      job_action      => 'BEGIN sys.dbms_audit_mgmt.set_last_archive_timestamp(audit_trail_type => '
                      || 'sys.dbms_audit_mgmt.audit_trail_unified,last_archive_time => sysdate-&audit_retention); END;',
      start_date      => sysdate,
      repeat_interval => 'FREQ=HOURLY;INTERVAL=24',
      enabled         => TRUE,
      comments        => 'Archive timestamp for unified audit to sysdate-&audit_retention'
    );
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_job_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_ts_job;

  -- Create daily purge job for Unified Audit Trail
  sys.dbms_output.put_line('Create archive purge jobs');
  sys.dbms_output.put('- Unified Audit Trail............ ');
  <<create_purge_job>>
  BEGIN
    sys.dbms_audit_mgmt.create_purge_job(
      audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_unified,
      audit_trail_purge_interval => 24 /* hours */,
      audit_trail_purge_name     => 'Daily_Unified_Audit_Purge_Job',
      use_last_arch_timestamp    => TRUE
    );
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_audit_job_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_purge_job;

END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------
