--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tde_init_full_sys_pdbuni.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.01.01
-- Revision...: 0.9.5
--  Purpose...: Initialize TDE in a PDB in united mode i.e., with a common wallet
--              of the CDB in WALLET_ROOT. The CDB must be configured for
--              TDE beforehand. This scripts does use several other scripts to
--              enable TDE and it also includes restart of the pdb. 
--
--              The following steps are performed:
--              - tde_mkey_create_sys.sql      create master encryption key
--              - restart pdb
--              - tde_info_dba.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET HEADING ON
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


SPOOL &LOGDIR./tde_pdbuni_init_sys_&DBSID._&TIMESTAMP..log
-- uncomment the following line if you have issues with pre-created master
-- encryption keys. e.g., because TDE wallets have been recreated
--@tde_lostkey_discard_sys.sql

-- configure master encryption key
@tde_mkey_create_sys.sql

PROMPT == Restart database to load software keystore with new master key =======
ALTER PLUGGABLE DATABASE CLOSE;
ALTER PLUGGABLE DATABASE OPEN;

-- display information
@tde_info_dba.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------