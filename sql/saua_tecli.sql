--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_tecli.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Show top unified audit events by client_program_name for current DBID
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN client_program_name  FORMAT A60 WRAP HEADING "Client Program Name"
COLUMN events               FORMAT 9,999,999,999 heading "Audit Events"

SPOOL saua_tecli.log
SELECT
    nvl(client_program_name, 'n/a') client_program_name,
    COUNT(*)                events
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
GROUP BY
    client_program_name
ORDER BY
    events DESC;
SPOOL OFF
-- EOF -------------------------------------------------------------------------
