-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_show.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Display current status of PDB services, the startup trigger
--              odb_pdb_service_trigger, database role and open mode.
-- Notes......: Must be executed inside the target PDB context.
--              Connect as SYSDBA and set the container before running:
--                ALTER SESSION SET CONTAINER = <pdb_name>;
--              Read-only: no DDL or DML is executed.
-- Reference..: https://docs.oracle.com/en/database/oracle/oracle-database/
-- License....: Apache License Version 2.0, January 2004
--              http://www.apache.org/licenses/
-- ---------------------------------------------------------------------------
-- Modified...:
-- see git log for revision history
-- ---------------------------------------------------------------------------

SPOOL odb_svc_service_trigger_show.log

SET ECHO        OFF
SET FEEDBACK    OFF
SET LINESIZE    200
SET PAGESIZE    200
SET SERVEROUTPUT ON SIZE UNLIMITED

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- ---------------------------------------------------------------------------
-- Verify execution context: must run inside a PDB, not in CDB$ROOT
-- ---------------------------------------------------------------------------
DECLARE
    v_con_name VARCHAR2(128);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_con_name
      FROM dual;

    IF v_con_name IN ('CDB$ROOT', 'PDB$SEED') THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'ERROR: Script must be executed inside a PDB, not in ' ||
            v_con_name || '. Use ALTER SESSION SET CONTAINER first.');
    END IF;
END;
/

WHENEVER SQLERROR CONTINUE

COL con_name      FOR A20  HEAD 'PDB Name'
COL db_role       FOR A20  HEAD 'DB Role'
COL open_mode     FOR A20  HEAD 'Open Mode'
COL db_domain     FOR A30  HEAD 'DB Domain'

COL name          FOR A60  HEAD 'Service Name'
COL network_name  FOR A60  HEAD 'Network Name'
COL enabled       FOR A8   HEAD 'Enabled'

COL trigger_name  FOR A30  HEAD 'Trigger Name'
COL owner         FOR A10  HEAD 'Owner'
COL status        FOR A10  HEAD 'Status'
COL trigger_type  FOR A20  HEAD 'Type'
COL triggering_event FOR A20 HEAD 'Event'

-- ---------------------------------------------------------------------------
-- Section 1: PDB identity and database role
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  PDB Identity and Role
PROMPT ============================================================
PROMPT

SELECT
    SYS_CONTEXT('USERENV', 'CON_NAME')  AS con_name,
    d.database_role                      AS db_role,
    v.open_mode                          AS open_mode,
    NVL(p.value, '(none)')              AS db_domain
  FROM v$database     d
  CROSS JOIN v$pdbs   v
  CROSS JOIN v$parameter p
 WHERE v.con_id   = SYS_CONTEXT('USERENV', 'CON_ID')
   AND p.name     = 'db_domain';

-- ---------------------------------------------------------------------------
-- Section 2: Registered services (DBA_SERVICES)
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Registered Services (DBA_SERVICES)
PROMPT ============================================================
PROMPT

SELECT
    name,
    network_name,
    enabled
  FROM dba_services
 WHERE UPPER(name) LIKE UPPER(SYS_CONTEXT('USERENV', 'CON_NAME')) || '\_R_\_%' ESCAPE '\'
 ORDER BY name;

-- ---------------------------------------------------------------------------
-- Section 3: Active services (V$ACTIVE_SERVICES)
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Active Services (V$ACTIVE_SERVICES)
PROMPT ============================================================
PROMPT

COL name          FOR A60  HEAD 'Service Name'
COL network_name  FOR A60  HEAD 'Network Name'

SELECT
    name,
    network_name
  FROM v$active_services
 WHERE UPPER(name) LIKE UPPER(SYS_CONTEXT('USERENV', 'CON_NAME')) || '\_R_\_%' ESCAPE '\'
 ORDER BY name;

-- ---------------------------------------------------------------------------
-- Section 4: Trigger status
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Trigger Status (DBA_TRIGGERS)
PROMPT ============================================================
PROMPT

SELECT
    owner,
    trigger_name,
    status,
    trigger_type,
    triggering_event
  FROM dba_triggers
 WHERE trigger_name = 'ODB_PDB_SERVICE_TRIGGER';

-- ---------------------------------------------------------------------------
-- Section 5: Trigger source (DBA_SOURCE)
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Trigger Source (DBA_SOURCE)
PROMPT ============================================================
PROMPT

SET LINESIZE 300
COL text FOR A280 HEAD 'Source'

SELECT text
  FROM dba_source
 WHERE name  = 'ODB_PDB_SERVICE_TRIGGER'
   AND owner = 'SYS'
   AND type  = 'TRIGGER'
 ORDER BY line;

PROMPT
PROMPT odb_svc_service_trigger_show.sql completed.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_show.sql
