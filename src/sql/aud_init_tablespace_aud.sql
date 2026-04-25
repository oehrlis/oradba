-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_init_tablespace_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.25
-- Revision..: 0.24.0
-- Usage.....: aud_init_tablespace_aud.sql <TABLESPACE NAME> <DATAFILE SIZE>
--
--              TABLESPACE NAME   Name of the audit tablespace. Default is AUDIT_DATA
--              DATAFILE SIZE     Initial size of datafile. Default 20480K
-- Purpose...: Create audit tablespace. Supports OMF, ASM, and regular filesystem.
--              Part of the audit initialization suite. Can also be called standalone.
-- Notes.....: Called by aud_init_full_aud.sql. Requires SYSDBA or equivalent privileges.
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _tablespace_name = 'AUDIT_DATA'
DEFINE _tablespace_size = '20480K'

-- assign default value for parameter if argument 1 or 2 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
DEFINE tablespace_name = &1 &_tablespace_name
DEFINE tablespace_size = &2 &_tablespace_size
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

SPOOL &LOGDIR./aud_init_tablespace_aud_&DBSID._&TIMESTAMP..log
-- Anonymous PL/SQL Block to create audit tablespace
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Types
  SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent

  -- Local variables
  l_version           PLS_INTEGER;
  l_datafile_path     dba_data_files.file_name%TYPE;
  l_db_unique_name    v$database.db_unique_name%TYPE;
  l_audit_tablespace  v$tablespace.name%TYPE := '&tablespace_name';
  l_audit_data_file   dba_data_files.file_name%TYPE;
  l_file_dest         v$parameter.value%TYPE;
  l_sql               text_type;            -- sql used in EXECUTE IMMEDIATE
  l_status            text_type;            -- status message for output
  e_tablespace_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_tablespace_exists, -1543);

BEGIN

  sys.dbms_output.put_line('Create audit tablespace ' || l_audit_tablespace);

  -- Get required DB info
  <<get_data_dict_infos>>
  BEGIN
    SELECT
      (SELECT value FROM v$parameter WHERE name = 'db_create_file_dest'),
      (SELECT db_unique_name FROM v$database),
      (SELECT regexp_substr(version, '^\d+') FROM v$instance),
      (SELECT file_name FROM dba_data_files WHERE file_name LIKE '%system%' AND ROWNUM = 1)
    INTO
      l_file_dest, l_db_unique_name, l_version, l_datafile_path
    FROM dual;
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      sys.dbms_output.put_line('Error: Unable to retrieve data dictionary information.');
  END get_data_dict_infos;

  -- Create Tablespace but raise an exception if it already exists
  sys.dbms_output.put('- Create ' || l_audit_tablespace || ' Tablespace... ');
  <<create_tablespace>>
  BEGIN
    IF l_file_dest IS NOT NULL THEN
      -- OMF is enabled
      l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
               ' DATAFILE SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
      l_status := 'created (OMF)';
    ELSE
      -- Derive path or diskgroup from SYSTEM datafile
      IF l_datafile_path LIKE '+%' THEN
        -- ASM path
        l_datafile_path := regexp_substr(l_datafile_path, '[^/]*');
        l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
                 ' DATAFILE ''' || l_datafile_path || ''' SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
        l_status := 'created (ASM)';
      ELSE
        -- Filesystem path
        l_datafile_path := regexp_substr(l_datafile_path, '^/.*/');
        l_audit_data_file := l_datafile_path || LOWER(l_audit_tablespace) || '01' || l_db_unique_name || '.dbf';
        l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
                 ' DATAFILE ''' || l_audit_data_file || ''' SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
        l_status := 'created (regular)';
      END IF;
    END IF;
    EXECUTE IMMEDIATE l_sql;
    sys.dbms_output.put_line(l_status);
  EXCEPTION
    WHEN e_tablespace_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_tablespace;

END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------
