--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aud_report_full_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2025.12.19
--  Usage.....: 
--  Purpose...: Run a couple of audit report queries  
--  Notes.....: 
--  Reference.: 
--  Reference..: https://github.com/oehrlis/oradba
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 200
SPOOL aud_report_full_aud.log

PROMPT
PROMPT ================================================================================
PROMPT = Show information about the audit trails
PROMPT ================================================================================
@aud_config_show_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show local audit policies policies. A join of the views AUDIT_UNIFIED_POLICIES
PROMPT = and AUDIT_UNIFIED_ENABLED_POLICIES
PROMPT ================================================================================
@aud_policies_show_aud.sql 

PROMPT
PROMPT ================================================================================
PROMPT = Show Unified Audit trail storage usage
PROMPT ================================================================================
@aud_storage_usage_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show Unified Audit trail table and partition size
PROMPT ================================================================================
@aud_tabsize_show_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by action for current DBID
PROMPT ================================================================================
@aud_top_action_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by client_program_name for current DBID
PROMPT ================================================================================
@aud_top_clientprog_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by DBID
PROMPT ================================================================================
@aud_top_dbid_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = 
PROMPT ================================================================================
@aud_top_user_aud.sql Show top unified audit events by dbusername for current DBID

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by object_name for current DBID
PROMPT ================================================================================
@aud_top_object_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by Object Name without Oracle maintained schemas
PROMPT = for current DBID
PROMPT ================================================================================
@aud_top_object_user_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by object_schema for current DBID
PROMPT ================================================================================
@aud_top_owner_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by os_username for current DBID
PROMPT ================================================================================
@aud_top_osuser_aud.sql 

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by unified_audit_policies for current DBID
PROMPT ================================================================================
@aud_top_policy_aud.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by unified_audit_policies, dbusername, action
PROMPT = for current DBID
PROMPT ================================================================================
@aud_top_policy_auddet.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by userhost for current DBID
PROMPT ================================================================================
@aud_top_host_aud.sql
