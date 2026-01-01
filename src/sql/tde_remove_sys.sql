--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tde_remove_sys.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2025.12.19
--  Revision..: 0.8.0
--  Purpose...: Remove TDE and software keystore configuration in a single tenant
--              or container database. This scripts does use several other scripts
--              to remove TDE and it also includes restart of the database. 
--
--              The following steps are performed:
--              - zip the current wallet directory
--              - remove the current wallet directory
--              - tde_walletroot_drop_sys.sql       reset init.ora parameter for TDE
--              - restart database
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
COLUMN wallet_root      NEW_VALUE wallet_root       NOPRINT
COLUMN wallet_root_base NEW_VALUE wallet_root_base  NOPRINT

-- get wallet root from v$parameter with pdb guid if we are in a pdb
SELECT trim(trailing '/' FROM value||'/'||nvl((SELECT rawtohex(guid) FROM v$pdbs WHERE con_id=sys_context('userenv','con_id')),'')) wallet_root 
FROM v$parameter WHERE name = 'wallet_root';
SELECT replace('&wallet_root','/wallet') wallet_root_base FROM dual;

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

SPOOL &LOGDIR./tde_remove_sys_&DBSID._&TIMESTAMP..log
-- ZIP current wallet root directory
HOST zip -r &wallet_root_base/wallet_$(date "%Y%m%d-%H%M%S").zip &wallet_root
HOST rm -rf &wallet_root

-- reset WALLET_ROOT parameter
@tde_walletroot_drop_sys.sql

PROMPT == Restart database to load software keystore with new master key =======
STARTUP FORCE;

-- display information
@tde_info_dba.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------