-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: tde_walletroot_drop_sys.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.01.01
-- Revision..: 0.9.5
-- Purpose...: Reset init.ora parameter WALLET_ROOT for TDE. This script should
--              run in CDB$ROOT. A manual restart of the database is mandatory to
--              activate WALLET_ROOT.
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

COLUMN name             FORMAT A25
COLUMN value            FORMAT A60

-- start to spool
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


SPOOL &LOGDIR./tde_walletroot_drop_sys_&DBSID._&TIMESTAMP..log
-- list init.ora parameter for TDE information in SPFile
PROMPT == Current setting of WALLET_ROOT in SPFILE =============================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

-- set the WALLET ROOT parameter
ALTER SYSTEM RESET tde_configuration SCOPE=SPFILE;
ALTER SYSTEM RESET wallet_root SCOPE=SPFILE;

-- list init.ora parameter for TDE information in SPFile
PROMPT == New setting of WALLET_ROOT in SPFILE =================================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

PROMPT =========================================================================
PROMPT == Please restart the database to apply the changes on WALLET_ROOT. =====
PROMPT =========================================================================

SPOOL OFF
-- EOF -------------------------------------------------------------------------