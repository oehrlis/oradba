--------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: env_show_sqlpath.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2026.04.01
--  Revision..: v1.0.0
--  Purpose...: Show current SQLPATH directories with existence check
--  Notes.....: Parses $SQLPATH (colon-separated) via HOST bash and prints
--              each directory with a numbered list and [✓]/[✗] marker.
--              Uses SYS_CONTEXT to detect local (bequeath) vs remote (tcp)
--              connection. HOST always runs on the sqlplus client side:
--                - local  (NETWORK_PROTOCOL IS NULL): client = DB server
--                - remote (NETWORK_PROTOCOL = 'tcp'): client != DB server
--              Requires bash and a login shell (run via lab-sql / bash -lc).
--  Reference.: https://github.com/oehrlis/ora-db-audit-eng
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET LINESIZE 256 PAGESIZE 100 SERVEROUTPUT ON FORMAT WRAPPED
SET FEEDBACK OFF ECHO OFF TERMOUT ON VERIFY OFF

-- Check connection type and print context header
DECLARE
    v_proto   VARCHAR2(30) := SYS_CONTEXT('USERENV', 'NETWORK_PROTOCOL');
    v_host    VARCHAR2(64) := SYS_CONTEXT('USERENV', 'SERVER_HOST');
    v_ip      VARCHAR2(64) := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    IF v_proto IS NULL OR UPPER(v_proto) IN ('BEQ', 'BEQUEUE') THEN
        DBMS_OUTPUT.PUT_LINE('Connection : local / bequeath (sqlplus runs on DB server)');
        DBMS_OUTPUT.PUT_LINE('Server     : ' || v_host);
        DBMS_OUTPUT.PUT_LINE('Note       : SQLPATH below reflects the DB server environment.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Connection : ' || UPPER(v_proto) || ' from ' || NVL(v_ip, 'unknown'));
        DBMS_OUTPUT.PUT_LINE('Server     : ' || v_host);
        DBMS_OUTPUT.PUT_LINE('Note       : REMOTE connection - SQLPATH below reflects the CLIENT,');
        DBMS_OUTPUT.PUT_LINE('             not the DB server environment.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
END;
/

HOST bash -c 'echo "SQLPATH Directories:"; echo "==================="; n=1; IFS=":" read -ra DIRS <<< "$SQLPATH"; for dir in "${DIRS[@]}"; do if [ -d "$dir" ]; then mark="[✓]"; else mark="[✗]"; fi; printf " %2d. %-60s %s\n" $n "$dir" "$mark"; n=$((n+1)); done; echo ""'

SET FEEDBACK ON SERVEROUTPUT OFF

-- EOF -------------------------------------------------------------------------
