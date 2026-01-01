--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tde_init_full_sys_pdbiso_keyadmin.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2025.12.19
--  Revision..: 0.8.0
--  Purpose...: Create the software keystore in PDB in isolation mode as SYSKM
--              or PDBADMIN. Environment must be prepared before with
--              tde_init_full_sys_pdbiso_prepare.sql
--
--              The following steps are performed:
--              - set init.ora parameter
--              - create directory
--              - tde_info_dba.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN def_wallet_pwd NEW_VALUE def_wallet_pwd NOPRINT
COLUMN wallet_root NEW_VALUE wallet_root NOPRINT
-- generate random password
SELECT dbms_random.string('X', 20) def_wallet_pwd FROM dual;

-- get wallet root from v$parameter with pdb guid if we are in a pdb
SELECT trim(trailing '/' FROM value||'/'||nvl((SELECT rawtohex(guid) FROM v$pdbs WHERE con_id=sys_context('userenv','con_id')),'')) wallet_root 
FROM v$parameter WHERE name = 'wallet_root';

-- assign default value for parameter if argument 1 is empty
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_pwd          = &1 &def_wallet_pwd
COLUMN wallet_pwd NEW_VALUE wallet_pwd NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON

COLUMN wrl_type         FORMAT A8
COLUMN wrl_parameter    FORMAT A75
COLUMN status           FORMAT A18
COLUMN wallet_type      FORMAT A15
COLUMN con_id           FORMAT 99999

-- start to spool
-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

-- Get log directory from environment variable ORADBA_LOG (fallback to current dir)
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_$$.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_$$.sql
@/tmp/oradba_logdir_$$.sql
HOST rm -f /tmp/oradba_logdir_$$.sql

-- Get timestamp and database SID
COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./tde_pdbiso_init_keyadmin_sys_&DBSID._&TIMESTAMP..log
PROMPT == Software keystore password ===========================================
SELECT '&wallet_pwd' "Wallet Password" FROM dual;

PROMPT == Configure the software keystore ======================================
-- create software keystore in WALLET_ROOT
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "&wallet_pwd";

-- open the software keystore
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN FORCE KEYSTORE IDENTIFIED BY "&wallet_pwd";

-- create local auto-login software keystore from the existing software keystore
ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE '&wallet_root/tde' IDENTIFIED BY "&wallet_pwd";

PROMPT == Configure the master encryption key ==================================
ADMINISTER KEY MANAGEMENT SET KEY FORCE KEYSTORE IDENTIFIED BY "&wallet_pwd" WITH BACKUP;

-- list wallet information
PROMPT == Encryption wallet information from v$encryption_wallet ===============
SELECT * FROM v$encryption_wallet;

SPOOL OFF
-- EOF -------------------------------------------------------------------------