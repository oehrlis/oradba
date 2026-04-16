--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aud_policies_show_aud.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.1.0
--  Purpose...: Show local audit policies - join of AUDIT_UNIFIED_POLICIES and
--              AUDIT_UNIFIED_ENABLED_POLICIES. Policy-level attributes (condition,
--              eval, TOP, ORA) shown once per policy via ROW_NUMBER(); entity rows
--              listed below. Active YES policies first, ODB before ORA.
--  Usage.....: @aud_policies_show_aud
--  Notes.....: Requires SELECT on audit_unified_policies,
--              audit_unified_enabled_policies. LINESIZE 200 recommended.
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT OFF FEEDBACK OFF VERIFY OFF
SET LINESIZE 200 PAGESIZE 200

-- Column widths: 32+3+14+25+4+3+3+3+3+11+3+3+80 = 187 + 12 sep = 199
COLUMN policy_name          FORMAT A32  HEADING "Policy Name"
COLUMN active               FORMAT A3   HEADING "ACT"
COLUMN enabled_option       FORMAT A14  HEADING "Enabled Option"
COLUMN entity_name          FORMAT A25  HEADING "Entity Name"
COLUMN entity_type          FORMAT A4   HEADING "Type"
COLUMN success              FORMAT A3   HEADING "SUC"
COLUMN failure              FORMAT A3   HEADING "FAL"
COLUMN common               FORMAT A3   HEADING "COM"
COLUMN inherited            FORMAT A3   HEADING "INH"
COLUMN condition_eval_opt   FORMAT A11  HEADING "Eval Option"
COLUMN audit_only_toplevel  FORMAT A3   HEADING "TOP"
COLUMN oracle_supplied      FORMAT A3   HEADING "ORA"
COLUMN audit_condition      FORMAT A80  HEADING "Audit Condition"

BREAK ON policy_name SKIP 1

-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

-- Try to get log directory from environment (silently fall back to current dir)
WHENEVER OSERROR CONTINUE
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir.sql
@@/tmp/oradba_logdir.sql
HOST rm -f /tmp/oradba_logdir.sql
WHENEVER OSERROR EXIT FAILURE

-- Get timestamp and database SID
COLUMN logts  NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID     NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS')              AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME'))     AS logsid
FROM DUAL;

SPOOL &LOGDIR./aud_policies_show_aud_&DBSID._&TIMESTAMP..log

WITH base AS (
    SELECT
        NVL(u.policy_name, a.policy_name)                  AS policy_name,
        DECODE(a.policy_name, u.policy_name, 'YES', 'NO')  AS active,
        a.enabled_option,
        a.entity_name,
        a.entity_type,
        u.condition_eval_opt,
        a.success,
        a.failure,
        u.common,
        u.inherited,
        u.audit_only_toplevel,
        u.oracle_supplied,
        NVL(u.audit_condition, 'NONE')                     AS audit_condition,
        ROW_NUMBER() OVER (
            PARTITION BY NVL(u.policy_name, a.policy_name)
            ORDER BY a.enabled_option NULLS LAST, a.entity_name NULLS LAST
        ) AS rn
    FROM
        audit_unified_policies           u
        FULL JOIN audit_unified_enabled_policies a ON u.policy_name = a.policy_name
    GROUP BY
        u.policy_name, a.policy_name,
        a.enabled_option, a.entity_name, a.entity_type,
        a.success, a.failure,
        u.audit_condition, u.condition_eval_opt,
        u.common, u.inherited, u.audit_only_toplevel, u.oracle_supplied
)
SELECT
    policy_name,
    active,
    NVL(enabled_option, '-')                                       AS enabled_option,
    NVL(entity_name,    '-')                                       AS entity_name,
    NVL(entity_type,    '-')                                       AS entity_type,
    NVL(success,        '-')                                       AS success,
    NVL(failure,        '-')                                       AS failure,
    NVL(common,         '-')                                       AS common,
    NVL(inherited,      '-')                                       AS inherited,
    CASE WHEN rn = 1 THEN NVL(condition_eval_opt, '-') END         AS condition_eval_opt,
    CASE WHEN rn = 1 THEN NVL(audit_only_toplevel, '-') END        AS audit_only_toplevel,
    CASE WHEN rn = 1 THEN NVL(oracle_supplied, '-') END            AS oracle_supplied,
    CASE WHEN rn = 1 THEN audit_condition END                      AS audit_condition
FROM base
ORDER BY
    active DESC,
    CASE WHEN policy_name LIKE 'ORA%' THEN 1 ELSE 0 END,
    policy_name,
    rn;

SPOOL OFF

CLEAR BREAKS
SET FEEDBACK ON VERIFY ON
-- EOF -------------------------------------------------------------------------
