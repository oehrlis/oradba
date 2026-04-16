-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: aud_session_ctx_show_aud.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.03.28
-- Revision..: 0.2.1
-- Purpose...: Analyse available session context attributes (USERENV) for use in
--             audit policy WHEN clauses and logon triggers (Engineering Task E-03).
--             Shows which attributes are populated and suitable for policy restrictions.
-- Notes.....: Run as any authenticated user to see own session context.
--             Run as AUDIT_VIEWER to see cross-session attribute coverage in trail.
--             WHEN clause limitation: only SYS_CONTEXT() with string comparison
--             is supported - no REGEXP_LIKE directly in audit policy WHEN clause.
-- Reference.: SYS (or grant manually to a DBA)
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

SET PAGESIZE 200  HEADING ON  VERIFY OFF
SET LINESIZE 180
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

SPOOL &LOGDIR./aud_session_ctx_show_aud_&DBSID._&TIMESTAMP..log

-- =============================================================================
PROMPT ================================================================================
PROMPT = 1. USERENV CONTEXT — Aktuelle Session (Werte der eigenen Session)
PROMPT =    Ziel: Welche Attribute sind verfuegbar und welche Werte liefern sie
PROMPT =    Relevanz fuer WHEN-Klausel und Logon Trigger
PROMPT ================================================================================
-- =============================================================================
COLUMN attribute        FORMAT A35  HEADING "Attribute"
COLUMN wert             FORMAT A80  HEADING "Wert"
COLUMN when_clause      FORMAT A5   HEADING "WHEN?"
COLUMN trigger_use      FORMAT A8   HEADING "Trigger?"

SELECT attribute, wert, when_clause, trigger_use FROM (
    SELECT 'SESSION_USER'                       AS attribute, SYS_CONTEXT('USERENV','SESSION_USER')           AS wert, 'Ja'   AS when_clause, 'Ja'     AS trigger_use FROM dual
    UNION ALL SELECT 'CURRENT_USER',              SYS_CONTEXT('USERENV','CURRENT_USER'),            'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'DB_NAME',                   SYS_CONTEXT('USERENV','DB_NAME'),                 'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'CON_NAME',                  SYS_CONTEXT('USERENV','CON_NAME'),                'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'IP_ADDRESS',                SYS_CONTEXT('USERENV','IP_ADDRESS'),              'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'HOST',                      SYS_CONTEXT('USERENV','HOST'),                    'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'OS_USER',                   SYS_CONTEXT('USERENV','OS_USER'),                 'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'TERMINAL',                  SYS_CONTEXT('USERENV','TERMINAL'),                'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'MODULE',                    SYS_CONTEXT('USERENV','MODULE'),                  'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'ACTION',                    SYS_CONTEXT('USERENV','ACTION'),                  'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'CLIENT_INFO',               SYS_CONTEXT('USERENV','CLIENT_INFO'),             'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'CLIENT_IDENTIFIER',         SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER'),       'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'AUTHENTICATION_METHOD',     SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD'),   'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'AUTHENTICATION_TYPE',       SYS_CONTEXT('USERENV','AUTHENTICATION_TYPE'),     'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'NETWORK_PROTOCOL',          SYS_CONTEXT('USERENV','NETWORK_PROTOCOL'),        'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'SERVICE_NAME',              SYS_CONTEXT('USERENV','SERVICE_NAME'),            'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'INSTANCE_NAME',             SYS_CONTEXT('USERENV','INSTANCE_NAME'),           'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'SERVER_HOST',               SYS_CONTEXT('USERENV','SERVER_HOST'),             'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'PROXY_USER',                SYS_CONTEXT('USERENV','PROXY_USER'),              'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'PROXY_ENTERPRISE_IDENTITY', SYS_CONTEXT('USERENV','PROXY_ENTERPRISE_IDENTITY'),'Nein','Ja'    FROM dual
    UNION ALL SELECT 'UNIFIED_AUDIT_SESSIONID',   SYS_CONTEXT('USERENV','UNIFIED_AUDIT_SESSIONID'), 'Nein', 'Nein'  FROM dual
    UNION ALL SELECT 'SID',                       SYS_CONTEXT('USERENV','SID'),                     'Nein', 'Ja'    FROM dual
    UNION ALL SELECT 'ISDBA',                     SYS_CONTEXT('USERENV','ISDBA'),                   'Ja',   'Ja'     FROM dual
    UNION ALL SELECT 'CURRENT_EDITION_NAME',      SYS_CONTEXT('USERENV','CURRENT_EDITION_NAME'),    'Ja',   'Nein'  FROM dual
)
ORDER BY when_clause DESC, attribute;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 2. WHEN-KLAUSEL SYNTAX — Beispiele fuer Audit Policy WHEN-Klauseln
PROMPT =    Hinweis: Nur einfache SYS_CONTEXT()-Vergleiche moeglich, kein REGEXP_LIKE
PROMPT =    Fuer Regex: Application Context via Logon Trigger setzen (E-04)
PROMPT ================================================================================
-- =============================================================================
SELECT
    '-- Nur auditieren wenn NICHT vom App-Server (IP direkt): '       AS beispiel FROM dual
    UNION ALL SELECT 'WHEN (SYS_CONTEXT(''USERENV'',''IP_ADDRESS'') NOT LIKE ''10.0.1.%'')'      FROM dual
    UNION ALL SELECT ''                                                                            FROM dual
    UNION ALL SELECT '-- Nur auditieren wenn von bestimmtem Netz:'                                FROM dual
    UNION ALL SELECT 'WHEN (SYS_CONTEXT(''USERENV'',''IP_ADDRESS'') LIKE ''192.168.%'')'          FROM dual
    UNION ALL SELECT ''                                                                            FROM dual
    UNION ALL SELECT '-- Application Context (gesetzt via Logon Trigger mit Regex):'              FROM dual
    UNION ALL SELECT 'WHEN (SYS_CONTEXT(''audit_ctx'',''client_type'') = ''direct'')'             FROM dual
    UNION ALL SELECT ''                                                                            FROM dual
    UNION ALL SELECT '-- Nur auditieren wenn NICHT via SQL Developer / Toad (Module):'            FROM dual
    UNION ALL SELECT 'WHEN (SYS_CONTEXT(''USERENV'',''MODULE'') IS NULL'                          FROM dual
    UNION ALL SELECT '      OR SYS_CONTEXT(''USERENV'',''MODULE'') NOT LIKE ''%SQL Developer%'')' FROM dual;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 3. UNIFIED_AUDIT_TRAIL SPALTEN — Session-Kontext-Mapping
PROMPT =    Welche USERENV-Attribute landen in welcher Trail-Spalte
PROMPT ================================================================================
-- =============================================================================
COLUMN userenv_attr     FORMAT A35  HEADING "SYS_CONTEXT('USERENV',...)"
COLUMN trail_column     FORMAT A35  HEADING "UNIFIED_AUDIT_TRAIL Spalte"
COLUMN nutzbar          FORMAT A12  HEADING "WHEN-Klausel"

SELECT userenv_attr, trail_column, nutzbar FROM (
    SELECT 'SESSION_USER'            AS userenv_attr, 'DBUSERNAME'              AS trail_column, 'Ja'  AS nutzbar FROM dual
    UNION ALL SELECT 'IP_ADDRESS',     'CLIENT_IP',                               'Ja'  FROM dual
    UNION ALL SELECT 'HOST',           'USERHOST',                                'Ja'  FROM dual
    UNION ALL SELECT 'OS_USER',        'OS_USERNAME',                             'Ja'  FROM dual
    UNION ALL SELECT 'TERMINAL',       'TERMINAL_ID',                             'Ja'  FROM dual
    UNION ALL SELECT 'MODULE',         'APPLICATION_CONTEXTS (teilweise)',        'Ja'  FROM dual
    UNION ALL SELECT 'CLIENT_INFO',    'APPLICATION_CONTEXTS (teilweise)',        'Ja'  FROM dual
    UNION ALL SELECT 'CLIENT_IDENTIFIER','CLIENT_IDENTIFIER',                     'Ja'  FROM dual
    UNION ALL SELECT 'SERVICE_NAME',   'NAME_ATTR (SERVICE_NAME)',                'Nein' FROM dual
    UNION ALL SELECT 'AUTHENTICATION_TYPE','AUTHENTICATION_TYPE',                 'Nein' FROM dual
    UNION ALL SELECT 'PROXY_USER',     'PROXY_SESSIONID (indirekt)',              'Nein' FROM dual
    UNION ALL SELECT 'ISDBA',          '-  (kein direktes Mapping)',              'Ja'  FROM dual
    UNION ALL SELECT 'Custom Context', 'APPLICATION_CONTEXTS',                    'Ja'  FROM dual
)
ORDER BY nutzbar DESC, userenv_attr;

-- =============================================================================
PROMPT
PROMPT ================================================================================
PROMPT = 4. TRAIL COVERAGE — Fuellgrad der Session-Attribute in vorhandenen Records
PROMPT =    Ziel: Welche Attribute haben tatsaechlich Werte im Trail (letzten 7 Tage)
PROMPT ================================================================================
-- =============================================================================
COLUMN attribut         FORMAT A30  HEADING "Trail-Attribut"
COLUMN mit_wert         FORMAT 999,999,999 HEADING "Mit Wert"
COLUMN ohne_wert        FORMAT 999,999,999 HEADING "Ohne Wert / NULL"
COLUMN fuellgrad        FORMAT 999.9 HEADING "% gefuellt"

SELECT
    'USERHOST'        AS attribut,
    COUNT(CASE WHEN userhost IS NOT NULL THEN 1 END)              AS mit_wert,
    COUNT(CASE WHEN userhost IS NULL THEN 1 END)                  AS ohne_wert,
    ROUND(COUNT(CASE WHEN userhost IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS fuellgrad
FROM unified_audit_trail
WHERE dbid = con_id_to_dbid(sys_context('USERENV','CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '7' DAY
UNION ALL
SELECT 'CLIENT_IP',
    COUNT(CASE WHEN client_ip IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN client_ip IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN client_ip IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1)
FROM unified_audit_trail
WHERE dbid = con_id_to_dbid(sys_context('USERENV','CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '7' DAY
UNION ALL
SELECT 'OS_USERNAME',
    COUNT(CASE WHEN os_username IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN os_username IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN os_username IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1)
FROM unified_audit_trail
WHERE dbid = con_id_to_dbid(sys_context('USERENV','CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '7' DAY
UNION ALL
SELECT 'CLIENT_PROGRAM_NAME',
    COUNT(CASE WHEN client_program_name IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN client_program_name IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN client_program_name IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1)
FROM unified_audit_trail
WHERE dbid = con_id_to_dbid(sys_context('USERENV','CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '7' DAY
UNION ALL
SELECT 'CLIENT_IDENTIFIER',
    COUNT(CASE WHEN client_identifier IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN client_identifier IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN client_identifier IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1)
FROM unified_audit_trail
WHERE dbid = con_id_to_dbid(sys_context('USERENV','CON_ID'))
  AND event_timestamp_utc >= SYSTIMESTAMP - INTERVAL '7' DAY
ORDER BY fuellgrad DESC;

SPOOL OFF
-- EOF -------------------------------------------------------------------------
