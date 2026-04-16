--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: auditpdb.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.0.0
--  Purpose...: Switch session container directly to AUDITPDB1 (no prompt).
--  Usage.....: @auditpdb
--  Notes.....: Wrapper for pdb.sql with hardcoded AUDITPDB1 argument.
--              Requires SYSDBA or SET CONTAINER privilege (CDB-level session).
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

@pdb AUDITPDB1

-- EOF -------------------------------------------------------------------------
