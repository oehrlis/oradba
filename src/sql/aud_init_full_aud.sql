-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_init_full_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.25
-- Revision..: 0.24.0
-- Usage.....: aud_init_full_aud.sql <TABLESPACE NAME> <DATAFILE SIZE> <AUDIT RETENTION>
--
--              TABLESPACE NAME   Name of the audit tablespace. Default is AUDIT_DATA
--              DATAFILE SIZE     Initial size of datafile. Default 20480K
--              AUDIT RETENTION   Days for which an audit timestamp will be created e.g.
--                                sysdate - <AUDIT RETENTION>. This does help to create
--                                some kind of time window where audit records will be
--                                available on the system. This amount of DAYS
--                                is also the fallback when the AVAGENT does not create
--                                timestamps. Default 30 days
-- Purpose...: Initialize full audit environment by calling all initialization sub-scripts:
--              1. aud_init_tablespace_aud.sql - Create audit tablespace
--              2. aud_init_trail_aud.sql      - Configure audit trail locations and partition interval
--              3. aud_init_jobs_aud.sql       - Create archive timestamp and purge scheduler jobs
--              4. aud_init_show_aud.sql       - Show audit configuration for verification
--              Each sub-script can also be called independently.
--              Each sub-script creates its own log file in LOGDIR (or current directory).
-- Notes.....: Requires SYSDBA or equivalent privileges.
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _tablespace_name = 'AUDIT_DATA'
DEFINE _tablespace_size = '20480K'
DEFINE _audit_retention = 30

-- assign default value for parameter if argument 1, 2 or 3 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
COLUMN 3 NEW_VALUE 3 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
SELECT '' "3" FROM dual WHERE ROWNUM = 0;
DEFINE tablespace_name = &1 &_tablespace_name
DEFINE tablespace_size = &2 &_tablespace_size
DEFINE audit_retention = &3 &_audit_retention
COLUMN tablespace_name NEW_VALUE tablespace_name NOPRINT
SELECT upper('&tablespace_name') tablespace_name FROM dual;

SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

PROMPT ============================================================
PROMPT  Initialize full audit environment
PROMPT  Tablespace : &tablespace_name (&tablespace_size)
PROMPT  Retention  : &audit_retention days
PROMPT ============================================================
PROMPT  Note: Each step produces its own log file.
PROMPT ============================================================

-- Step 1: Create audit tablespace
PROMPT
PROMPT --- Step 1/4: Create audit tablespace ---
PROMPT
@@aud_init_tablespace_aud &tablespace_name &tablespace_size

-- Step 2: Configure audit trail locations and partition interval
PROMPT
PROMPT --- Step 2/4: Configure audit trail locations and partition interval ---
PROMPT
@@aud_init_trail_aud &tablespace_name

-- Step 3: Create archive timestamp and purge scheduler jobs
PROMPT
PROMPT --- Step 3/4: Create archive timestamp and purge scheduler jobs ---
PROMPT
@@aud_init_jobs_aud &audit_retention

-- Step 4: Show audit configuration for verification
PROMPT
PROMPT --- Step 4/4: Show audit configuration ---
PROMPT
@@aud_init_show_aud

PROMPT
PROMPT ============================================================
PROMPT  Audit initialization complete.
PROMPT ============================================================
-- EOF -------------------------------------------------------------------------
