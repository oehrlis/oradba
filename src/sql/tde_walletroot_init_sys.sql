-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: tde_walletroot_init_sys.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.02.11
-- Revision..: 0.21.0
-- Purpose...: Initialize init.ora parameter WALLET_ROOT based on value of
--              AUDIT_FILE_DEST to setup TDE with software keystore. This
--              script should run in CDB$ROOT. A manual restart
--              of the database is mandatory to activate WALLET_ROOT
-- Notes.....:
-- Reference.: Requires SYS, SYSDBA or DBA privilege
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN def_admin_path NEW_VALUE def_admin_path NOPRINT
-- get the admin directory from audit_file_dest
SELECT
    substr(value, 1, instr(value, '/', - 1, 1) - 1) def_admin_path
FROM
    v$parameter
WHERE
    name = 'audit_file_dest';

-- assign default value for parameter if argument 1 is empty
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE admin_path          = &1 &def_admin_path
COLUMN admin_path NEW_VALUE admin_path NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET HEADING ON
SET FEEDBACK ON
COLUMN name             FORMAT A42
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


SPOOL &LOGDIR./tde_walletroot_init_sys_&DBSID._&TIMESTAMP..log
-- create the wallet root folders
HOST mkdir -p &admin_path/wallet
host mkdir -p &admin_path/wallet/tde
host mkdir -p &admin_path/wallet/backups
host mkdir -p &admin_path/wallet/tde_seps

-- list init.ora parameter for TDE information in SPFile
PROMPT == Current setting of WALLET_ROOT in SPFILE =============================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration','_db_discard_lost_masterkey') 
ORDER BY name;

-- set the WALLET ROOT parameter
ALTER SYSTEM SET wallet_root='&admin_path/wallet' SCOPE=SPFILE;

-- list init.ora parameter for TDE information in SPFile
PROMPT == New setting of WALLET_ROOT in SPFILE =================================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration','_db_discard_lost_masterkey') 
ORDER BY name;

PROMPT =========================================================================
PROMPT == Please restart the database to apply the changes on WALLET_ROOT. =====
PROMPT =========================================================================

SPOOL OFF
-- EOF -------------------------------------------------------------------------