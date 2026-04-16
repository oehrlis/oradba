--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: pdb.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.0.0
--  Purpose...: Switch session container to a given PDB.
--  Usage.....: @pdb [<container_name>]
--              Argument: PDB/container name (default: AUDITPDB1)
--              If omitted, SQL*Plus prompts - press Enter for default.
--  Notes.....: Requires SYSDBA or SET CONTAINER privilege (CDB-level session).
--  Examples..: @pdb                    -- switch to AUDITPDB1 (default)
--              @pdb AUDITPDB1          -- switch to AUDITPDB1
--              @pdb CDB$ROOT           -- switch back to CDB root
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET VERIFY OFF FEEDBACK OFF

-- Capture &1 or default to AUDITPDB1 when Enter is pressed without input
COLUMN _pdb NEW_VALUE _pdb NOPRINT
SELECT NVL(TRIM('&1'), 'AUDITPDB1') AS "_pdb" FROM DUAL;

ALTER SESSION SET CONTAINER = &_pdb;

SHOW con_name

SET FEEDBACK ON VERIFY ON
-- EOF -------------------------------------------------------------------------
