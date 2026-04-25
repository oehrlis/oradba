-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_init_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.04.25
-- Revision..: 0.24.0
-- Usage.....: @aud_init_show_aud
-- Purpose...: Show audit initialization configuration for verification.
--              Displays:
--              - Audit management configuration parameters (trail locations, retention)
--              - Audit cleanup (purge) job status
--              - Scheduler jobs for archive timestamps
--              - Currently enabled unified audit policies
--              Part of the audit initialization suite. Can also be called standalone.
-- Notes.....: Called by aud_init_full_aud.sql. Requires AUDIT_ADMIN or AUDIT_VIEWER role.
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

SET FEEDBACK OFF
SET VERIFY OFF

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

SPOOL &LOGDIR./aud_init_show_aud_&DBSID._&TIMESTAMP..log
SET LINESIZE 160 PAGESIZE 200

-- Audit Management Configuration Parameters
PROMPT
PROMPT === Audit Management Configuration Parameters ===
PROMPT
COL audit_trail    FOR a30
COL parameter_name FOR a35
COL parameter_value FOR a20
SELECT audit_trail, parameter_name, parameter_value
FROM dba_audit_mgmt_config_params
ORDER BY audit_trail, parameter_name;

-- Audit Cleanup (Purge) Jobs
PROMPT
PROMPT === Audit Cleanup (Purge) Jobs ===
PROMPT
COL job_name      FOR a35
COL job_status    FOR a10
COL audit_trail   FOR a30
COL job_frequency FOR a40
SELECT job_name, job_status, audit_trail, job_frequency
FROM dba_audit_mgmt_cleanup_jobs
ORDER BY job_name;

-- Scheduler Jobs for Audit Archive Timestamps
PROMPT
PROMPT === Scheduler Jobs for Audit Archive Timestamps ===
PROMPT
COL job_name        FOR a35
COL repeat_interval FOR a50
COL comments        FOR a50
SELECT job_name, repeat_interval, comments
FROM dba_scheduler_jobs
WHERE job_name LIKE '%AUDIT%'
ORDER BY job_name;

-- Enabled Unified Audit Policies
PROMPT
PROMPT === Enabled Unified Audit Policies ===
PROMPT
COL policy_name    FOR a40
COL enabled_option FOR a20
COL entity_name    FOR a30
SELECT policy_name, enabled_option, entity_name, entity_type, success, failure
FROM audit_unified_enabled_policies
ORDER BY policy_name, entity_name;

SPOOL OFF
-- EOF -------------------------------------------------------------------------
