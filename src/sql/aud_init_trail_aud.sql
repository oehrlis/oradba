-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_init_trail_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.27
-- Revision..: 0.24.2
-- Usage.....: aud_init_trail_aud.sql <TABLESPACE NAME>
--
--              TABLESPACE NAME   Name of the audit tablespace. Default is AUDIT_DATA
-- Purpose...: Configure audit trail locations and partition interval.
--              - Moves Unified Audit Trail to the specified tablespace (always)
--              - Moves Standard and FGA Audit Trail to the specified tablespace
--                only when the database runs in Mixed Auditing Mode
--              - Sets partition interval to 1 day
--              Part of the audit initialization suite. Can also be called standalone.
-- Notes.....: Called by aud_init_full_aud.sql. Requires AUDIT_ADMIN role.
--              Tablespace must already exist before running this script.
--              Mixed mode is detected via V$OPTION WHERE PARAMETER =
--              'Unified Auditing' AND VALUE = 'FALSE'.
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _tablespace_name = 'AUDIT_DATA'

-- assign default value for parameter if argument 1 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE tablespace_name = &1 &_tablespace_name
COLUMN tablespace_name NEW_VALUE tablespace_name NOPRINT
SELECT upper('&tablespace_name') tablespace_name FROM dual;

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

SPOOL &LOGDIR./aud_init_trail_aud_&DBSID._&TIMESTAMP..log
-- Anonymous PL/SQL Block to configure audit trail locations and partition interval
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Local variables
  l_audit_tablespace v$tablespace.name%TYPE := '&tablespace_name';
  l_unified_auditing v$option.value%TYPE;
  l_mixed_mode       BOOLEAN;

BEGIN

  -- Detect audit mode: 'TRUE' = Pure Unified Auditing, 'FALSE' = Mixed Mode
  SELECT value
    INTO l_unified_auditing
    FROM v$option
   WHERE parameter = 'Unified Auditing';

  l_mixed_mode := (l_unified_auditing = 'FALSE');

  IF l_mixed_mode THEN
    sys.dbms_output.put_line('Audit mode: Mixed (Unified + Standard/FGA)');
  ELSE
    sys.dbms_output.put_line('Audit mode: Pure Unified Auditing');
  END IF;

  sys.dbms_output.put_line('Configure audit trail location and partition interval');

  -- Set location for Unified Audit Trail (always)
  sys.dbms_output.put('- Set location to ' || l_audit_tablespace || ' for Unified Audit Trail... ');
  sys.dbms_audit_mgmt.set_audit_trail_location(
    audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_unified,
    audit_trail_location_value => l_audit_tablespace
  );
  sys.dbms_output.put_line('done');

  -- Set location for Standard and FGA Audit Trail (mixed mode only)
  IF l_mixed_mode THEN
    sys.dbms_output.put('- Set location to ' || l_audit_tablespace || ' for Standard and FGA Audit Trail... ');
    sys.dbms_audit_mgmt.set_audit_trail_location(
      audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_db_std,
      audit_trail_location_value => l_audit_tablespace
    );
    sys.dbms_output.put_line('done');
  ELSE
    sys.dbms_output.put_line('- Skip Standard and FGA Audit Trail location (Pure Unified Auditing mode)');
  END IF;

  -- Set partition interval to 1 day
  sys.dbms_output.put('- Set partition interval to 1 day... ');
  sys.dbms_audit_mgmt.alter_partition_interval(
    interval_number    => 1,
    interval_frequency => 'DAY'
  );
  sys.dbms_output.put_line('done');

END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------
