-- ------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- ------------------------------------------------------------------------------
-- Name.......: aud_config_show_aud.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2025.12.19
-- Revision...: 0.8.0
-- Purpose....: Show audit trail configuration and information
-- Notes......: Requires AUDIT_ADMIN or AUDIT_VIEWER role
-- Usage......: @aud_config_show_aud
-- Reference..: https://github.com/oehrlis/oradba
-- License....: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
-- ------------------------------------------------------------------------------

SET PAGESIZE 66 HEADING ON VERIFY OFF
SET FEEDBACK OFF SQLCASE UPPER NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN audit_trail      FORMAT A30 WRAP HEADING "Audit Trail"
COLUMN last_archive_ts  FORMAT A20 WRAP HEADING "Last Archive"  
COLUMN audit_condition  FORMAT A50 WRAP HEADING "Condition"
COLUMN parameter_name   FORMAT A30 WRAP HEADING "Parameter"
COLUMN parameter_value  FORMAT A50 WRAP HEADING "Value"

PROMPT
PROMPT ================================================================================
PROMPT Audit Trail Last Archive Timestamps
PROMPT ================================================================================

SELECT
    audit_trail,
    to_char(last_archive_ts, 'DD.MM.YYYY HH24:MI:SS') AS last_archive_ts,
    audit_condition
FROM
    dba_audit_mgmt_last_arch_ts
ORDER BY
    audit_trail;

PROMPT
PROMPT ================================================================================
PROMPT Audit Management Configuration Parameters
PROMPT ================================================================================

SELECT  
    parameter_name,
    parameter_value
FROM
    dba_audit_mgmt_config_params
ORDER BY
    parameter_name;

-- EOF -------------------------------------------------------------------------