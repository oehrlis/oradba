--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tde_init_full_sys_pdbiso.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Initialize TDE in a PDB in isolation mode i.e., with a dedicated
--              wallet in WALLET_ROOT for this pdb. The CDB must be configured for
--              TDE beforehand. This scripts does use several other scripts to
--              enable TDE and it also includes restart of the pdb. 
--
--              The following steps are performed:
--              - tde_wallet_create_sys.sql  create and configure software keystore
--              - tde_mkey_create_sys.sql      create master encryption key
--              - restart pdb
--              - tde_info_dba.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
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

-- format SQLPlus output and behavior
SET LINESIZE 180 PAGESIZE 66
SET HEADING ON
SET VERIFY ON
SET FEEDBACK ON

-- start to spool
SPOOL tde_init_full_sys_pdbiso.log

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