-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_trail_analysis_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.28
-- Revision..: 0.2.1
-- Purpose...: Comprehensive audit trail analysis for audit concept optimization.
--             Covers volume trend, action/user distribution, noise candidates,
--             and policy coverage gaps. Used for engineering tasks E-01/E-02.
-- Notes.....: Run as AUDIT_ADMIN or AUDIT_VIEWER. Filter to current PDB via DBID.
--             Parameter 1: number of days to analyse (default 30)
-- Reference.: SYS (or grant manually to a DBA)
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

-- define default values
DEFINE _days = 30
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE days = &1 &_days
SET FEEDBACK ON
SET VERIFY ON

SET PAGESIZE 200  HEADING ON  VERIFY OFF
SET LINESIZE 220
SET FEEDBACK OFF  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

-- Configure spool directory and filename components
DEFINE LOGDIR = '.'
DEFINE TIMESTAMP = 'UNKNOWN'
DEFINE DBSID = 'UNKNOWN'

WHENEVER OSERROR CONTINUE
HOST echo "DEFINE LOGDIR = '${ORADBA_LOG:-.}'" > /tmp/oradba_logdir_${USER}.sql 2>/dev/null || echo "DEFINE LOGDIR = '.'" > /tmp/oradba_logdir_${USER}.sql
@@/tmp/oradba_logdir_${USER}.sql
HOST rm -f /tmp/oradba_logdir_${USER}.sql
WHENEVER OSERROR EXIT FAILURE

COLUMN logts NEW_VALUE TIMESTAMP NOPRINT
COLUMN logsid NEW_VALUE DBSID NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS logts,
       LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME')) AS logsid
FROM DUAL;

SPOOL &LOGDIR./aud_trail_analysis_aud_&DBSID._&TIMESTAMP..log

-- =============================================================================
PROMPT ================================================================================
PROMPT = 1. VOLUME TREND — Audit events per day (last &days days)
PROMPT =    Ziel: Wachstumsrate und Spitzentage identifizieren
PROMPT ================================================================================
-- =============================================================================
COLUMN audit_day   FORMAT A12          HEADING "Tag"
COLUMN events      FORMAT 999,999,999  HEADING "Audit Events"
COLUMN policies    FORMAT 999,999      HEADING "Policies (distinct)"
COLUMN users       FORMAT 9,999        HEADING "User (distinct)"

SELECT
    TO_CHAR(TRUNC(event_timestamp_utc), 'DD.MM.YYYY') AS audit_day,
    COUNT(*)                                           AS events,
    COUNT(DISTINCT unified_audit_policies)             AS policies,
    COUNT(DISTINCT dbusername)                         AS users
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY TRUNC(event_timestamp_utc)
ORDER BY TRUNC(event_timestamp_utc) DESC;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 2. ACTION DISTRIBUTION — Top actions by count (last &days days)
PROMPT =    Ziel: Welche Actions dominieren den Trail — Rauschen identifizieren
PROMPT ================================================================================
-- =============================================================================
COLUMN action_name          FORMAT A35          HEADING "Action"
COLUMN events               FORMAT 999,999,999  HEADING "Events"
COLUMN pct                  FORMAT 999.9        HEADING "% Total"
COLUMN has_policy           FORMAT A10          HEADING "Hat Policy"

SELECT
    NVL(action_name, 'n/a')                                         AS action_name,
    COUNT(*)                                                         AS events,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)                AS pct,
    CASE WHEN unified_audit_policies IS NOT NULL THEN 'Ja' ELSE 'Nein' END AS has_policy
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY NVL(action_name, 'n/a'),
         CASE WHEN unified_audit_policies IS NOT NULL THEN 'Ja' ELSE 'Nein' END
ORDER BY events DESC
FETCH FIRST 30 ROWS ONLY;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 3. USER x ACTION MATRIX — Top user/action combinations (last &days days)
PROMPT =    Ziel: Was tun welche User-Klassen — Basis fuer Policy-Scope-Entscheid
PROMPT ================================================================================
-- =============================================================================
COLUMN dbusername           FORMAT A25          HEADING "DB User"
COLUMN action_name          FORMAT A30          HEADING "Action"
COLUMN object_schema        FORMAT A20          HEADING "Schema"
COLUMN events               FORMAT 999,999,999  HEADING "Events"

SELECT
    NVL(dbusername, 'n/a')      AS dbusername,
    NVL(action_name, 'n/a')     AS action_name,
    NVL(object_schema, 'n/a')   AS object_schema,
    COUNT(*)                    AS events
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY dbusername, action_name, object_schema
ORDER BY events DESC
FETCH FIRST 40 ROWS ONLY;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 4. CLIENT PROGRAM NOISE — Top client programs (last &days days)
PROMPT =    Ziel: Tool-basiertes Rauschen erkennen (SQL Developer, Toad, OEM, etc.)
PROMPT ================================================================================
-- =============================================================================
COLUMN client_program_name  FORMAT A50          HEADING "Client Program"
COLUMN users                FORMAT 9,999        HEADING "User (distinct)"
COLUMN events               FORMAT 999,999,999  HEADING "Events"

SELECT
    NVL(client_program_name, 'n/a')    AS client_program_name,
    COUNT(DISTINCT dbusername)          AS users,
    COUNT(*)                            AS events
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY client_program_name
ORDER BY events DESC
FETCH FIRST 25 ROWS ONLY;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 5. MANDATORY AUDIT (keine benannte Policy) — last &days days
PROMPT =    Ziel: Baseline verstehen — was landet ohne aktive Policy im Trail
PROMPT ================================================================================
-- =============================================================================
COLUMN action_name          FORMAT A35          HEADING "Action"
COLUMN dbusername           FORMAT A20          HEADING "DB User"
COLUMN audit_type           FORMAT A25          HEADING "Audit Type"
COLUMN events               FORMAT 999,999,999  HEADING "Events"

SELECT
    NVL(audit_type, 'n/a')      AS audit_type,
    NVL(action_name, 'n/a')     AS action_name,
    NVL(dbusername, 'n/a')      AS dbusername,
    COUNT(*)                    AS events
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
  AND (unified_audit_policies IS NULL OR unified_audit_policies = '')
GROUP BY audit_type, action_name, dbusername
ORDER BY events DESC
FETCH FIRST 30 ROWS ONLY;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 6. POLICY COVERAGE — Welche Policies erzeugen wie viele Records (last &days days)
PROMPT =    Ziel: Hot Policies und Policy-Volumen-Verteilung verstehen
PROMPT ================================================================================
-- =============================================================================
COLUMN unified_audit_policies   FORMAT A55          HEADING "Policy"
COLUMN users                    FORMAT 9,999        HEADING "User (distinct)"
COLUMN events                   FORMAT 999,999,999  HEADING "Events"
COLUMN pct                      FORMAT 999.9        HEADING "% Total"

SELECT
    NVL(unified_audit_policies, '--- kein Policy (Mandatory) ---') AS unified_audit_policies,
    COUNT(DISTINCT dbusername)                                      AS users,
    COUNT(*)                                                        AS events,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)               AS pct
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY unified_audit_policies
ORDER BY events DESC;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 7. RETURN CODE DISTRIBUTION — Fehler und erfolgreiche Actions (last &days days)
PROMPT =    Ziel: Fehlgeschlagene Aktionen identifizieren — relevant fuer WHENEVER NOT SUCCESSFUL
PROMPT ================================================================================
-- =============================================================================
COLUMN return_code          FORMAT 99999        HEADING "ORA Error"
COLUMN action_name          FORMAT A30          HEADING "Action"
COLUMN events               FORMAT 999,999,999  HEADING "Events"
COLUMN erfolg               FORMAT A10          HEADING "Status"

SELECT
    return_code,
    CASE WHEN return_code = 0 THEN 'Erfolg' ELSE 'Fehler' END AS erfolg,
    NVL(action_name, 'n/a')                                    AS action_name,
    COUNT(*)                                                    AS events
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
  AND return_code != 0
GROUP BY return_code, action_name
ORDER BY events DESC
FETCH FIRST 20 ROWS ONLY;

UNDEFINE 1 days _days

SPOOL OFF
-- EOF -------------------------------------------------------------------------
