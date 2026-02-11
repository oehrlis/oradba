-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: util_schema_create_sys.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.02.11
-- Revision..: 0.21.0
-- Usage.....: util_schema_create_sys.sql <SCHEMA_NAME>
--              SCHEMA_NAME - utility schema name (default: ORADBA)
-- Purpose...: 
--              - Creates the schema if it does not exist (NO AUTHENTICATION).
--              - Grants: CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE JOB,
--                SELECT_CATALOG_ROLE, PURGE DBA_RECYCLEBIN.
--              - Safe to run multiple times; re-grants are harmless.
--  Requires..: SYSDBA (or DBA with CREATE USER), Oracle 12c+.
-- Notes.....: 
--              - In a **CDB** environment, run this in the **PDB** (recommended).
--                If you must create a common user in CDB$ROOT, use a name like C##XYZ_DBA.
--              - NO AUTHENTICATION is suitable for a job-owning utility schema created by
--                a DBA and not used for end-user logins. Adjust to an auth method you
--                prefer (IDENTIFIED BY, EXTERNALLY, etc.) if needed.
--  Exit codes: Exits with Oracle SQLCODE on error (WHENEVER SQLERROR).
-- Reference.: 
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- Fail fast in automation -----------------------------------------------------
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- SQL*Plus formatting ---------------------------------------------------------
SET LINESIZE 256 PAGESIZE 1000
SET SERVEROUTPUT ON
SET FEEDBACK OFF
SET VERIFY OFF

-- Parameter defaulting ---------------------------------------------------------
-- &1 = schema name (default ORADBA)
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;

DEFINE _SCHEMA_NAME = &1 ORADBA

SET FEEDBACK ON

PROMPT Info : Using utility schema "&_SCHEMA_NAME"

-- Main -------------------------------------------------------------------------
DECLARE

-- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent
    TYPE t_table_varchar_type IS TABLE OF text_type;

-- Variables
    l_schema   dba_users.username%type := '&_SCHEMA_NAME';
    l_exists   PLS_INTEGER;
    l_stmt     text_type;              -- sql used in EXECUTE IMMEDIATE

BEGIN
    -- normalize schema name to uppercase
    l_schema := UPPER(l_schema);
    -- Check if schema exists without exceptions (G-5060) and without COUNT(*) (G-8110)
    SELECT CASE
        WHEN EXISTS (SELECT 1 FROM sys.dba_users WHERE username = l_schema)
            THEN 1
            ELSE 0
        END
    INTO l_exists
    FROM
        sys.dual;

    IF l_exists = 0 THEN
        l_stmt := 'CREATE USER '
            || sys.dbms_assert.enquote_name(UPPER(l_schema), FALSE)
            || ' NO AUTHENTICATION';
        EXECUTE IMMEDIATE l_stmt;
        sys.dbms_output.put_line('Info : Schema '|| l_schema ||' created');
  ELSE
        sys.dbms_output.put_line('Info : Schema '|| l_schema ||' already exists');
  END IF;

  -- Grants (idempotent) --------------------------------------------------------
  l_stmt := 'GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE JOB '
         || 'TO '|| sys.dbms_assert.enquote_name(UPPER(l_schema), FALSE);
  EXECUTE IMMEDIATE l_stmt;
  sys.dbms_output.put_line('Info : Granted CREATE SESSION/TABLE/PROCEDURE/JOB');

  l_stmt := 'GRANT SELECT_CATALOG_ROLE TO '|| sys.dbms_assert.enquote_name(UPPER(l_schema), FALSE);
  EXECUTE IMMEDIATE l_stmt;
  sys.dbms_output.put_line('Info : Granted SELECT_CATALOG_ROLE');

  l_stmt := 'GRANT PURGE DBA_RECYCLEBIN TO '|| sys.dbms_assert.enquote_name(UPPER(l_schema), FALSE);
  EXECUTE IMMEDIATE l_stmt;
  sys.dbms_output.put_line('Info : Granted PURGE DBA_RECYCLEBIN');
END;
/

-- -----------------------------------------------------------------------------
--  Section...: Create RECYCLEBIN_PURGE_LOG + indexes + housekeeping
-- Purpose...: Logging table for recycle bin purge procedure/job, with:
--              - Monthly interval partitioning on LOG_TS
--              - Indexes for common lookups
--              - Housekeeping proc + scheduler job to purge old logs
-- -----------------------------------------------------------------------------

-- Create (or recreate) the table ----------------------------------------------
DECLARE

    -- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent
    TYPE t_table_varchar_type IS TABLE OF text_type;

    -- Variables
    l_owner   dba_users.username%type := '&_SCHEMA_NAME';
    l_exists   PLS_INTEGER;
    l_stmt     text_type;              -- sql used in EXECUTE IMMEDIATE

BEGIN
    -- normalize schema name to uppercase
    l_owner := UPPER(l_owner);
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM sys.all_tables
            WHERE owner = l_owner
              AND table_name = 'RECYCLEBIN_PURGE_LOG'
         ) THEN 1 ELSE 0 END
    INTO l_exists
    FROM
        sys.dual;

  IF l_exists = 1 THEN
    -- If you want to *force* the partitioned definition, drop & recreate:
    l_stmt :=  'DROP TABLE '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||
        '.RECYCLEBIN_PURGE_LOG PURGE';
    EXECUTE IMMEDIATE l_stmt;
    sys.dbms_output.put_line('Info : Dropped existing RECYCLEBIN_PURGE_LOG');
  END IF;

  l_stmt := '
    CREATE TABLE '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.RECYCLEBIN_PURGE_LOG
    (
      log_ts      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
      owner       VARCHAR2(128),
      object_name VARCHAR2(400),
      object_type VARCHAR2(64),
      drop_time   DATE,
      status      VARCHAR2(20),
      err_msg     VARCHAR2(4000)
    )
    PARTITION BY RANGE (log_ts)
    INTERVAL (NUMTOYMINTERVAL(1, ''MONTH''))
    (
      PARTITION p0 VALUES LESS THAN (TIMESTAMP ''2020-01-01 00:00:00'')
    )';
    EXECUTE IMMEDIATE l_stmt;
    sys.dbms_output.put_line('Info : Created RECYCLEBIN_PURGE_LOG (interval partitioned)');
END;
/
-- Create indexes (if missing) --------------------------------------------------
DECLARE
    -- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent
    TYPE t_table_varchar_type IS TABLE OF text_type;

    -- Variables
    l_owner   dba_users.username%type := UPPER('&_SCHEMA_NAME');
    l_exists   PLS_INTEGER;
    l_stmt     text_type;              -- sql used in EXECUTE IMMEDIATE

  FUNCTION idx_missing(p_idx VARCHAR2) RETURN BOOLEAN IS
    l_cnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_cnt
      FROM sys.all_indexes
     WHERE owner = l_owner
       AND index_name = p_idx;
    RETURN l_cnt = 0;
  END;
BEGIN
    -- normalize schema name to uppercase
    l_owner := UPPER(l_owner);
  IF idx_missing('IDX_RPLOG_LOGTS') THEN
    EXECUTE IMMEDIATE
      'CREATE INDEX '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.IDX_RPLOG_LOGTS '||
      'ON '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.RECYCLEBIN_PURGE_LOG(log_ts)';
    sys.dbms_output.put_line('Info : Created index IDX_RPLOG_LOGTS');
  ELSE
    sys.dbms_output.put_line('Info : Index IDX_RPLOG_LOGTS already exists');
  END IF;

  IF idx_missing('IDX_RPLOG_OWNER_DROP') THEN
    EXECUTE IMMEDIATE
      'CREATE INDEX '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.IDX_RPLOG_OWNER_DROP '||
      'ON '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.RECYCLEBIN_PURGE_LOG(owner, drop_time)';
    sys.dbms_output.put_line('Info : Created index IDX_RPLOG_OWNER_DROP');
  ELSE
    sys.dbms_output.put_line('Info : Index IDX_RPLOG_OWNER_DROP already exists');
  END IF;

  IF idx_missing('IDX_RPLOG_STATUS') THEN
    EXECUTE IMMEDIATE
      'CREATE INDEX '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.IDX_RPLOG_STATUS '||
      'ON '|| sys.dbms_assert.enquote_name(l_owner, FALSE) ||'.RECYCLEBIN_PURGE_LOG(status)';
    sys.dbms_output.put_line('Info : Created index IDX_RPLOG_STATUS');
  ELSE
    sys.dbms_output.put_line('Info : Index IDX_RPLOG_STATUS already exists');
  END IF;
END;
/
-- Housekeeping procedure (purge old log rows) ---------------------------------
CREATE OR REPLACE PROCEDURE &_SCHEMA_NAME..recyclebin_purge_log_clean
(
  p_keep_days IN PLS_INTEGER DEFAULT 31
) AUTHID DEFINER
AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  DELETE FROM &_SCHEMA_NAME..recyclebin_purge_log
   WHERE log_ts < SYSTIMESTAMP - NUMTODSINTERVAL(p_keep_days, 'DAY');
  COMMIT;
  sys.dbms_output.put_line('Info : RECYCLEBIN_PURGE_LOG cleanup done (keep '||p_keep_days||' days)');
END;
/
-- Scheduler job to clean the log daily at 03:00 --------------------------------
DECLARE
  l_job VARCHAR2(200) := '&_SCHEMA_NAME..PURGE_RBLOG_JOB';
  l_cnt PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_cnt
    FROM sys.user_scheduler_jobs
   WHERE job_name = UPPER('PURGE_RBLOG_JOB');

  IF l_cnt = 0 THEN
    sys.dbms_scheduler.create_job(
      job_name            => l_job,
      job_type            => 'STORED_PROCEDURE',
      job_action          => '&_SCHEMA_NAME..RECYCLEBIN_PURGE_LOG_CLEAN',
      number_of_arguments => 1,
      start_date          => SYSTIMESTAMP,
      repeat_interval     => 'FREQ=DAILY;BYHOUR=3;BYMINUTE=0;BYSECOND=0',
      enabled             => FALSE,
      comments            => 'Cleanup RECYCLEBIN_PURGE_LOG older than N days (default 31)'
    );

    sys.dbms_scheduler.set_job_argument_value(
      job_name => l_job,
      argument_position => 1,
      argument_value => '31'  -- retention days
    );

    sys.dbms_scheduler.enable(l_job);
    sys.dbms_output.put_line('Info : Created and enabled job '||l_job);
  ELSE
    sys.dbms_output.put_line('Info : Job '||l_job||' already exists');
  END IF;
END;
/
-- EOF (table + housekeeping section) -------------------------------------------

SET VERIFY ON
-- EOF --------------------------------------------------------------------------