--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ausdap.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.06.05
--  Revision..:  
--  Purpose...: Generate statements to drop all audit policies as they are
--              currently set in AUDIT_UNIFIED_ENABLED_POLICIES.
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
--------------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
--------------------------------------------------------------------------------
SET PAGESIZE 2000  HEADING ON  VERIFY OFF
SET LINESIZE 300
SET SERVEROUTPUT ON
SET LONG 100000
SET LONGCHUNKSIZE 100000
SET TRIMSPOOL ON
SET WRAP OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN code             FORMAT A160 WRAP HEADING "Code"

SELECT
    'DROP AUDIT POLICY '
    || policy_name
    || ';'
    || CHR(10) AS code
FROM
    audit_unified_policies
WHERE
    oracle_supplied = 'NO'
GROUP BY 
    policy_name;
-- EOF -------------------------------------------------------------------------
