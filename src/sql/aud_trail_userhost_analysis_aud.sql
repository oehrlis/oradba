-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_trail_userhost_analysis_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.28
-- Revision..: 0.2.1
-- Purpose...: Detailed user-host analysis from the unified audit trail.
--             Identifies connection patterns (host, client program, OS user)
--             to define regex candidates for logon trigger (Engineering Task E-05).
-- Notes.....: Run as AUDIT_ADMIN or AUDIT_VIEWER. Requires LOGON events in trail
--             (ORA_LOGON_LOGOFF or custom login policy must be active).
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

SPOOL &LOGDIR./aud_trail_userhost_analysis_aud_&DBSID._&TIMESTAMP..log

-- =============================================================================
PROMPT ================================================================================
PROMPT = 1. HOST SUMMARY — Distinct hosts mit Login-Anzahl und User-Anzahl (last &days days)
PROMPT =    Ziel: Uebersicht welche Hosts sich verbinden — Ausgangslage fuer Regex
PROMPT ================================================================================
-- =============================================================================
COLUMN userhost             FORMAT A60          HEADING "Host"
COLUMN logins               FORMAT 999,999,999  HEADING "Logins"
COLUMN users                FORMAT 9,999        HEADING "User (distinct)"
COLUMN programs             FORMAT 9,999        HEADING "Programs (distinct)"

SELECT
    NVL(userhost, 'n/a')            AS userhost,
    COUNT(*)                        AS logins,
    COUNT(DISTINCT dbusername)      AS users,
    COUNT(DISTINCT client_program_name) AS programs
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
  AND action_name     = 'LOGON'
GROUP BY userhost
ORDER BY logins DESC;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 2. HOST x USER x PROGRAM — Login-Kombinations-Matrix (last &days days)
PROMPT =    Ziel: Welcher User verbindet sich von welchem Host mit welchem Programm
PROMPT =    Grundlage fuer: Logon Trigger Regex + WHEN-Klausel in Audit Policies
PROMPT ================================================================================
-- =============================================================================
COLUMN userhost             FORMAT A45          HEADING "Host"
COLUMN dbusername           FORMAT A20          HEADING "DB User"
COLUMN os_username          FORMAT A15          HEADING "OS User"
COLUMN client_program_name  FORMAT A35          HEADING "Client Program"
COLUMN logins               FORMAT 999,999,999  HEADING "Logins"

SELECT
    NVL(userhost, 'n/a')            AS userhost,
    NVL(dbusername, 'n/a')          AS dbusername,
    NVL(os_username, 'n/a')         AS os_username,
    NVL(client_program_name, 'n/a') AS client_program_name,
    COUNT(*)                        AS logins
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
  AND action_name     = 'LOGON'
GROUP BY userhost, dbusername, os_username, client_program_name
ORDER BY logins DESC;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 3. DISTINCT HOSTNAMES — Alphabetisch sortiert fuer Regex-Muster-Analyse
PROMPT =    Ziel: Muster in Hostnamen erkennen (z.B. appserver%, *.domain.com)
PROMPT ================================================================================
-- =============================================================================
COLUMN userhost             FORMAT A80          HEADING "Host (distinct)"
COLUMN first_seen           FORMAT A20          HEADING "Erstes Login"
COLUMN last_seen            FORMAT A20          HEADING "Letztes Login"
COLUMN logins               FORMAT 999,999,999  HEADING "Logins"

SELECT
    NVL(userhost, 'n/a')                                        AS userhost,
    TO_CHAR(MIN(event_timestamp_utc), 'DD.MM.YYYY HH24:MI:SS')  AS first_seen,
    TO_CHAR(MAX(event_timestamp_utc), 'DD.MM.YYYY HH24:MI:SS')  AS last_seen,
    COUNT(*)                                                     AS logins
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
  AND action_name     = 'LOGON'
GROUP BY userhost
ORDER BY userhost ASC;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 4. ALLE VERBINDUNGEN (alle Actions) — Host x User Matrix
PROMPT =    Ziel: Vollbild auch ohne aktive Login-Policy (aus bereits vorhandenen Records)
PROMPT ================================================================================
-- =============================================================================
COLUMN userhost             FORMAT A45          HEADING "Host"
COLUMN dbusername           FORMAT A20          HEADING "DB User"
COLUMN events               FORMAT 999,999,999  HEADING "Audit Events"
COLUMN actions              FORMAT 9,999        HEADING "Actions (distinct)"

SELECT
    NVL(userhost, 'n/a')        AS userhost,
    NVL(dbusername, 'n/a')      AS dbusername,
    COUNT(DISTINCT action_name) AS actions,
    COUNT(*)                    AS events
FROM unified_audit_trail
WHERE dbid            = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '&days' DAY
GROUP BY userhost, dbusername
ORDER BY events DESC
FETCH FIRST 40 ROWS ONLY;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 5. V$SESSION — Aktuelle Verbindungen (Live)
PROMPT =    Ziel: Aktuelle Hosts und Client-Programme sehen ohne Trail-Abhaengigkeit
PROMPT ================================================================================
-- =============================================================================
COLUMN machine              FORMAT A45          HEADING "Machine"
COLUMN username             FORMAT A20          HEADING "DB User"
COLUMN osuser               FORMAT A15          HEADING "OS User"
COLUMN program              FORMAT A35          HEADING "Program"
COLUMN sessions             FORMAT 9,999        HEADING "Sessions"

SELECT
    NVL(machine, 'n/a')         AS machine,
    NVL(username, 'n/a')        AS username,
    NVL(osuser, 'n/a')          AS osuser,
    NVL(program, 'n/a')         AS program,
    COUNT(*)                    AS sessions
FROM v$session
WHERE type = 'USER'
GROUP BY machine, username, osuser, program
ORDER BY sessions DESC;

UNDEFINE 1 days _days

SPOOL OFF
-- EOF -------------------------------------------------------------------------
