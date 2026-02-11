-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: tde_lostkey_discard_sys.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.02.11
-- Revision..: 0.21.0
-- Purpose...: Set hidden parameter *_db_discard_lost_masterkey* to force
--              discard of lost master keys 
-- Notes.....:  
-- Reference.: Requires SYS, SYSDBA or DBA privilege
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------
-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET HEADING ON
SET FEEDBACK ON

-- set hidden parameter
ALTER SYSTEM SET "_db_discard_lost_masterkey"=TRUE SCOPE=MEMORY;

-- EOF -------------------------------------------------------------------------