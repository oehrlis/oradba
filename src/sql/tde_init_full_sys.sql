-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: tde_init_full_sys.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.01.01
-- Revision..: 0.9.5
-- Purpose...: Initialize TDE for a single tenant or container database. This
--              scripts does use several other scripts to enable TDE and it
--              also includes restart of the database. 
--
--              The following steps are performed:
--              - tde_walletroot_init_sys.sql       set init.ora parameter for TDE
--              - restart database
--              - tde_wallet_create_sys.sql  create and configure software keystore
--              - tde_mkey_create_sys.sql      create master encryption key
--              - restart database
--              - tde_info_dba.sql        show current TDE configuration
-- Notes.....:  
-- Reference.: Requires SYS, SYSDBA or SYSKM privilege
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values for wallet password
COLUMN def_wallet_pwd           NEW_VALUE def_wallet_pwd        NOPRINT
-- generate random password
SELECT dbms_random.string('X', 20) def_wallet_pwd FROM dual;

-- assign default value for parameter if argument 1 is empty
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_pwd           = &1 &def_wallet_pwd
COLUMN wallet_pwd           NEW_VALUE wallet_pwd NOPRINT

-- define default values for wallet password
COLUMN def_wallet_root_base     NEW_VALUE def_wallet_root_base  NOPRINT
-- get the wallet root directory from audit_file_dest
SELECT
    substr(value, 1, instr(value, '/', - 1, 1) - 1) def_wallet_root_base
FROM
    v$parameter
WHERE
    name = 'audit_file_dest';

-- assign default value for parameter if argument 2 is empty
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_root_base     = &2 &def_wallet_root_base
COLUMN wallet_root_base     NEW_VALUE wallet_root_base NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 180 PAGESIZE 66
SET HEADING ON
SET VERIFY ON
SET FEEDBACK ON

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


SPOOL &LOGDIR./tde_init_full_sys_&DBSID._&TIMESTAMP..log
-- configure WALLET_ROOT parameter
@tde_walletroot_init_sys.sql &wallet_root_base

PROMPT == Restart database to enable WALLET_ROOT ===============================
STARTUP FORCE;

-- configure software keystore for database / cdb
@tde_wallet_create_sys.sql &wallet_pwd

-- uncomment the following line if you have issues with pre-created master
-- encryption keys. e.g., because TDE wallets have been recreated
--@tde_lostkey_discard_sys.sql

-- configure master encryption key
@tde_mkey_create_sys.sql

PROMPT == Restart database to load software keystore with new master key =======
STARTUP FORCE;

-- display information
@tde_info_dba.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------