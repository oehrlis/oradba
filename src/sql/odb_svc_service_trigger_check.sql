-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_check.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Check migration status of PDB service triggers.
--              Shows both the legacy trigger (service_trigger) and the
--              current trigger (odb_pdb_service_trigger) side by side,
--              along with all RW/RO services registered in the PDB.
--              Use to verify that the trigger migration is complete and
--              no legacy objects remain.
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

SPOOL odb_svc_service_trigger_check.log

SET ECHO        OFF
SET FEEDBACK    OFF
SET LINESIZE    200
SET PAGESIZE    200
SET SERVEROUTPUT ON SIZE UNLIMITED

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- ---------------------------------------------------------------------------
-- Section 1: PDB identity and role
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  PDB Identity and Role
PROMPT ============================================================
PROMPT

COL con_name   FOR A20  HEAD 'PDB Name'
COL db_role    FOR A25  HEAD 'DB Role'
COL open_mode  FOR A20  HEAD 'Open Mode'
COL db_domain  FOR A30  HEAD 'DB Domain'

SELECT
    SYS_CONTEXT('USERENV', 'CON_NAME')  AS con_name,
    d.database_role                      AS db_role,
    v.open_mode                          AS open_mode,
    NVL(p.value, '(none)')              AS db_domain
  FROM v$database   d
  CROSS JOIN v$pdbs v
  CROSS JOIN v$parameter p
 WHERE v.con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND p.name   = 'db_domain';

-- ---------------------------------------------------------------------------
-- Section 2: Trigger migration status - legacy vs. current side by side
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Trigger Migration Status
PROMPT ============================================================
PROMPT

COL trigger_name  FOR A35  HEAD 'Trigger Name'
COL owner         FOR A10  HEAD 'Owner'
COL status        FOR A10  HEAD 'Status'
COL classification FOR A10 HEAD 'Type'
COL present       FOR A8   HEAD 'Present'

-- Drive from expected list; LEFT JOIN shows present/absent per trigger.
SELECT
    e.expected_name                             AS trigger_name,
    NVL(t.owner,  '(absent)')                  AS owner,
    NVL(t.status, 'N/A')                       AS status,
    CASE e.expected_name
        WHEN 'SERVICE_TRIGGER'         THEN 'LEGACY'
        WHEN 'ODB_PDB_SERVICE_TRIGGER' THEN 'CURRENT'
    END                                         AS classification,
    CASE WHEN t.trigger_name IS NOT NULL THEN 'YES'
         ELSE 'NO'
    END                                         AS present
  FROM (
    SELECT 'SERVICE_TRIGGER'         AS expected_name, 1 AS sort_order FROM dual
    UNION ALL
    SELECT 'ODB_PDB_SERVICE_TRIGGER' AS expected_name, 2 AS sort_order FROM dual
  ) e
  LEFT JOIN dba_triggers t
         ON t.trigger_name = e.expected_name
 ORDER BY e.sort_order;

-- ---------------------------------------------------------------------------
-- Section 3: All RW/RO services - registered and active
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  RW/RO Services - Registered vs. Active
PROMPT ============================================================
PROMPT

COL service_name  FOR A60  HEAD 'Service Name'
COL registered    FOR A12  HEAD 'Registered'
COL active        FOR A8   HEAD 'Active'

SELECT
    r.name                                      AS service_name,
    'YES'                                       AS registered,
    CASE WHEN a.name IS NOT NULL THEN 'YES'
         ELSE 'NO'
    END                                         AS active
  FROM dba_services r
  LEFT JOIN v$active_services a
         ON UPPER(a.name) = UPPER(r.name)
 WHERE UPPER(r.name) LIKE
       UPPER(SYS_CONTEXT('USERENV', 'CON_NAME')) || '\_R%' ESCAPE '\'
 ORDER BY r.name;

-- ---------------------------------------------------------------------------
-- Section 4: Migration verdict
-- ---------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Migration Verdict
PROMPT ============================================================
PROMPT

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_legacy_count   INTEGER;
    v_current_count  INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_legacy_count
      FROM dba_triggers
     WHERE trigger_name = 'SERVICE_TRIGGER';

    SELECT COUNT(*) INTO v_current_count
      FROM dba_triggers
     WHERE trigger_name = 'ODB_PDB_SERVICE_TRIGGER';

    DBMS_OUTPUT.PUT_LINE('Legacy  trigger SERVICE_TRIGGER:         ' ||
        CASE v_legacy_count  WHEN 0 THEN 'absent  (ok)'
                             ELSE        'PRESENT - drop manually:'
        END);
    IF v_legacy_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  DROP TRIGGER SYS.SERVICE_TRIGGER;');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Current trigger ODB_PDB_SERVICE_TRIGGER: ' ||
        CASE v_current_count WHEN 0 THEN 'absent  - create with odb_svc_service_trigger_create.sql'
                             ELSE        'present (ok)'
        END);

    DBMS_OUTPUT.PUT_LINE('');

    IF v_legacy_count = 0 AND v_current_count = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Result: OK - migration complete, no legacy objects remain.');
    ELSIF v_legacy_count > 0 AND v_current_count = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Result: WARNING - legacy trigger still present. ' ||
                             'Drop it manually: DROP TRIGGER SYS.SERVICE_TRIGGER;');
    ELSIF v_legacy_count > 0 AND v_current_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Result: PENDING - only legacy trigger present. ' ||
                             'Run odb_svc_service_trigger_recreate.sql to migrate.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Result: WARNING - no service trigger found. ' ||
                             'Run odb_svc_service_trigger_create.sql.');
    END IF;
END;
/
WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT odb_svc_service_trigger_check.sql completed.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_check.sql
