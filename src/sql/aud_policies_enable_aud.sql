--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
-- Name......: aud_policies_enable_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.com
-- Editor....: Stefan Oehrli
-- Date......: 2025.12.19
-- Revision..:  
-- Purpose...: SQL script to enable custom local audit policies policies
-- Notes.....:  
-- Reference.: SYS (or grant manually to a DBA)
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
COL policy_name FOR A40
COL entity_name FOR A30
COL comments FOR A80

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

SPOOL &LOGDIR./aud_policies_enable_aud_&DBSID._&TIMESTAMP..log
-- enable default Oracle policies
-- AUDIT POLICY ora_logon_failures WHENEVER NOT SUCCESSFUL;
-- AUDIT POLICY ora_secureconfig;
-- AUDIT POLICY ora_account_mgmt;
-- AUDIT POLICY ora_database_parameter;
-- AUDIT POLICY ora_cis_recommendations;

-- enable SecBench specific audit policies
AUDIT POLICY oradba_loc_all_logon_events;
AUDIT POLICY oradba_loc_all_act_priv_usr BY SYS, SYSKM, SYSRAC, PUBLIC;
AUDIT POLICY oradba_loc_all_act_priv_usr BY USERS WITH GRANTED ROLES dba,datapump_exp_full_database, imp_full_database, exp_full_database, datapump_imp_full_database;
AUDIT POLICY oradba_loc_all_act_proxy_usr;
AUDIT POLICY oradba_loc_all_act_direct_acc;
-- AUDIT POLICY oradba_loc_all_act_direct_acc_stm;
-- AUDIT POLICY oradba_loc_all_act_named_usr;
-- AUDIT POLICY oradba_loc_all_act_named_usr BY soe;
AUDIT POLICY oradba_loc_all_dp_events;
AUDIT POLICY oradba_loc_dir_acc;
AUDIT POLICY oradba_loc_acc_mgmt;
AUDIT POLICY oradba_loc_critical_db_act;
AUDIT POLICY oradba_loc_db_schema_changes;
AUDIT POLICY oradba_loc_inst_config;
AUDIT POLICY oradba_loc_secure_config;

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies;
-- EOF ---------------------------------------------------------------------
