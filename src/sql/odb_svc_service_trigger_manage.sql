-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_manage.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Manually start or stop the PDB RW/RO services.
--              Three actions are supported:
--                START  - start the service matching the current DB role,
--                         stop the opposite service
--                STOP   - stop both RW and RO services
--                STATUS - show active services (same as show script, brief)
--              Action is passed as a SQL*Plus variable on invocation:
--                @odb_svc_service_trigger_manage START
--                @odb_svc_service_trigger_manage STOP
--                @odb_svc_service_trigger_manage STATUS
--              If called without argument the script defaults to STATUS.
-- Notes......: Must be executed inside the target PDB context.
--              Connect as SYSDBA and set the container before running:
--                ALTER SESSION SET CONTAINER = <pdb_name>;
-- Reference..: https://docs.oracle.com/en/database/oracle/oracle-database/
-- License....: Apache License Version 2.0, January 2004
--              http://www.apache.org/licenses/
-- ---------------------------------------------------------------------------
-- Modified...:
-- see git log for revision history
-- ---------------------------------------------------------------------------

-- Accept action as first positional argument, default to STATUS
DEFINE action = '&1'

SPOOL odb_svc_service_trigger_manage.log

SET ECHO        OFF
SET FEEDBACK    OFF
SET VERIFY      OFF
SET LINESIZE    200
SET PAGESIZE    200
SET SERVEROUTPUT ON SIZE UNLIMITED

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- ---------------------------------------------------------------------------
-- Verify execution context: must run inside a PDB, not in CDB$ROOT
-- ---------------------------------------------------------------------------
DECLARE
    v_con_name VARCHAR2(128);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_con_name
      FROM dual;

    IF v_con_name IN ('CDB$ROOT', 'PDB$SEED') THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'ERROR: Script must be executed inside a PDB, not in ' ||
            v_con_name || '. Use ALTER SESSION SET CONTAINER first.');
    END IF;
END;
/
WHENEVER SQLERROR CONTINUE

-- ---------------------------------------------------------------------------
-- Execute action
-- ---------------------------------------------------------------------------
DECLARE
    v_action    VARCHAR2(10)  := UPPER(TRIM('&action'));
    v_pdb_name  VARCHAR2(128);
    v_db_domain VARCHAR2(128);
    v_db_role   VARCHAR2(30);
    v_svc_rw    VARCHAR2(256);
    v_svc_ro    VARCHAR2(256);
    v_svc_start VARCHAR2(256);
    v_svc_stop  VARCHAR2(256);

    FUNCTION get_service_name(p_suffix IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RTRIM(v_pdb_name || p_suffix || '.' || v_db_domain, '.');
    END;

    PROCEDURE print_active_services IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Active services:');
        FOR r IN (
            SELECT name
              FROM v$active_services
             WHERE UPPER(name) LIKE UPPER(v_pdb_name) || '\_R%' ESCAPE '\'
             ORDER BY name
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  [ACTIVE] ' || r.name);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_pdb_name
      FROM dual;

    SELECT NVL(value, '')
      INTO v_db_domain
      FROM v$parameter
     WHERE name = 'db_domain';

    SELECT database_role
      INTO v_db_role
      FROM v$database;

    v_svc_rw := get_service_name('_RW');
    v_svc_ro := get_service_name('_RO');

    -- Default to STATUS when no argument given
    IF v_action IS NULL OR v_action = '' THEN
        v_action := 'STATUS';
    END IF;

    DBMS_OUTPUT.PUT_LINE('PDB:    ' || v_pdb_name);
    DBMS_OUTPUT.PUT_LINE('Role:   ' || v_db_role);
    DBMS_OUTPUT.PUT_LINE('Action: ' || v_action);

    -- -----------------------------------------------------------------------
    CASE v_action

        WHEN 'START' THEN
            -- Start the service matching the current role, stop the other
            IF v_db_role = 'PRIMARY' THEN
                v_svc_start := v_svc_rw;
                v_svc_stop  := v_svc_ro;
            ELSE
                v_svc_start := v_svc_ro;
                v_svc_stop  := v_svc_rw;
            END IF;

            DBMS_OUTPUT.PUT_LINE('Stopping: ' || v_svc_stop);
            BEGIN
                DBMS_SERVICE.STOP_SERVICE(v_svc_stop);
            EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  (not running or already stopped)');
            END;

            DBMS_OUTPUT.PUT_LINE('Starting: ' || v_svc_start);
            DBMS_SERVICE.START_SERVICE(v_svc_start);
            DBMS_OUTPUT.PUT_LINE('Done.');
            print_active_services;

        WHEN 'STOP' THEN
            -- Stop both services unconditionally
            FOR v_svc IN (
                SELECT name
                  FROM v$active_services
                 WHERE UPPER(name) LIKE UPPER(v_pdb_name) || '\_R%' ESCAPE '\'
            ) LOOP
                DBMS_OUTPUT.PUT_LINE('Stopping: ' || v_svc.name);
                BEGIN
                    DBMS_SERVICE.STOP_SERVICE(v_svc.name);
                EXCEPTION WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('  (error stopping ' || v_svc.name ||
                                         ': ' || SQLERRM || ')');
                END;
            END LOOP;
            DBMS_OUTPUT.PUT_LINE('Done.');
            print_active_services;

        WHEN 'STATUS' THEN
            print_active_services;

        ELSE
            RAISE_APPLICATION_ERROR(
                -20103,
                'ERROR: Unknown action "' || v_action || '". ' ||
                'Valid values: START, STOP, STATUS.');
    END CASE;
END;
/

PROMPT
PROMPT odb_svc_service_trigger_manage.sql completed.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_manage.sql
