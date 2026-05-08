-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_check_all.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Show service trigger and RW/RO service status for all open
--              PDBs from CDB root in a compact summary format.
--              Covers both the legacy trigger (SERVICE_TRIGGER) and the
--              current trigger (ODB_PDB_SERVICE_TRIGGER / USZ_PDB_SERVICE_TRIGGER).
-- Notes......: Must be executed in CDB$ROOT as SYSDBA.
--              Read-only: no DDL or DML is executed.
-- Reference..: https://docs.oracle.com/en/database/oracle/oracle-database/
-- License....: Apache License Version 2.0, January 2004
--              http://www.apache.org/licenses/
-- ---------------------------------------------------------------------------
-- Modified...:
-- see git log for revision history
-- ---------------------------------------------------------------------------

SPOOL odb_svc_service_trigger_check_all.log

SET ECHO        OFF
SET FEEDBACK    OFF
SET LINESIZE    220
SET PAGESIZE    200
SET SERVEROUTPUT ON SIZE UNLIMITED

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- ---------------------------------------------------------------------------
-- Verify execution context: must run in CDB$ROOT
-- ---------------------------------------------------------------------------
DECLARE
    v_con_name VARCHAR2(128);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_con_name
      FROM dual;

    IF v_con_name <> 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'ERROR: Script must be executed in CDB$ROOT, not in ' ||
            v_con_name || '.');
    END IF;
END;
/

WHENEVER SQLERROR CONTINUE

-- ---------------------------------------------------------------------------
-- Section 1: CDB identity and role
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  CDB Identity and Role
PROMPT ============================================================
PROMPT

COL cdb_name   FOR A20  HEAD 'CDB Name'
COL db_role    FOR A25  HEAD 'DB Role'
COL open_mode  FOR A15  HEAD 'Open Mode'
COL db_domain  FOR A30  HEAD 'DB Domain'

SELECT
    name                        AS cdb_name,
    database_role               AS db_role,
    open_mode                   AS open_mode,
    NVL(value, '(none)')        AS db_domain
  FROM v$database
  CROSS JOIN (
    SELECT value FROM v$parameter WHERE name = 'db_domain'
  );

-- ---------------------------------------------------------------------------
-- Section 2: Trigger status per PDB
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Trigger Status per PDB (all open PDBs)
PROMPT  Legacy: SERVICE_TRIGGER  |  Current: *_PDB_SERVICE_TRIGGER
PROMPT ============================================================
PROMPT

COL pdb_name         FOR A20  HEAD 'PDB Name'
COL legacy           FOR A10  HEAD 'SERVICE_|TRIGGER'
COL current_trigger  FOR A30  HEAD 'Current Trigger Name'
COL current_status   FOR A10  HEAD 'Status'
COL verdict          FOR A50  HEAD 'Verdict'

SELECT
    p.name                                          AS pdb_name,
    -- Legacy trigger SERVICE_TRIGGER
    CASE WHEN leg.trigger_name IS NOT NULL
         THEN leg.status
         ELSE 'absent'
    END                                             AS legacy,
    -- Current trigger (any prefix ending in _PDB_SERVICE_TRIGGER)
    NVL(cur.trigger_name, 'absent')                AS current_trigger,
    NVL(cur.status, 'absent')                      AS current_status,
    -- Verdict
    CASE
        WHEN leg.trigger_name IS NULL
             AND cur.trigger_name IS NOT NULL
             THEN 'OK'
        WHEN leg.trigger_name IS NOT NULL
             AND cur.trigger_name IS NOT NULL
             THEN 'WARNING: legacy trigger still present'
        WHEN leg.trigger_name IS NOT NULL
             AND cur.trigger_name IS NULL
             THEN 'PENDING: only legacy trigger, recreate needed'
        ELSE 'WARNING: no service trigger found'
    END                                             AS verdict
  FROM v$pdbs p
  -- Legacy trigger
  LEFT JOIN cdb_triggers leg
         ON leg.con_id      = p.con_id
        AND leg.trigger_name = 'SERVICE_TRIGGER'
  -- Current trigger: any name ending in _PDB_SERVICE_TRIGGER (ODB_, USZ_, etc.)
  LEFT JOIN cdb_triggers cur
         ON cur.con_id      = p.con_id
        AND cur.trigger_name LIKE '%\_PDB\_SERVICE\_TRIGGER' ESCAPE '\'
        AND cur.trigger_name <> 'SERVICE_TRIGGER'
 WHERE p.open_mode LIKE 'READ%'
   AND p.name      <> 'PDB$SEED'
 ORDER BY p.name;

-- ---------------------------------------------------------------------------
-- Section 3: RW/RO service status per PDB
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  RW/RO Service Status per PDB (all open PDBs)
PROMPT ============================================================
PROMPT

COL pdb_name      FOR A20  HEAD 'PDB Name'
COL service_name  FOR A50  HEAD 'Service Name'
COL registered    FOR A12  HEAD 'Registered'
COL active        FOR A8   HEAD 'Active'

SELECT
    p.name                                          AS pdb_name,
    s.name                                          AS service_name,
    'YES'                                           AS registered,
    CASE WHEN a.name IS NOT NULL THEN 'YES'
         ELSE 'NO'
    END                                             AS active
  FROM v$pdbs p
  JOIN cdb_services s
    ON s.con_id = p.con_id
   AND (   UPPER(s.name) LIKE UPPER(p.name) || '\_RW%' ESCAPE '\'
        OR UPPER(s.name) LIKE UPPER(p.name) || '\_RO%' ESCAPE '\')
  LEFT JOIN v$active_services a
         ON UPPER(a.name) = UPPER(s.name)
 WHERE p.open_mode LIKE 'READ%'
   AND p.name      <> 'PDB$SEED'
 ORDER BY p.name, s.name;

PROMPT
PROMPT odb_svc_service_trigger_check_all.sql completed.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_check_all.sql
