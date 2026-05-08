-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_recreate.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Recreate PDB RW/RO services and the startup trigger
--              odb_pdb_service_trigger (idempotent).
--              Drops existing services and trigger before recreating.
--              Safe to run multiple times - use for updates and re-migrations.
-- Notes......: Must be executed inside the target PDB context.
--              Connect as SYSDBA and set the container before running:
--                ALTER SESSION SET CONTAINER = <pdb_name>;
--              Service names are derived automatically from CON_NAME
--              and db_domain:
--                <CON_NAME>_RW[.<db_domain>]
--                <CON_NAME>_RO[.<db_domain>]
-- Reference..: https://docs.oracle.com/en/database/oracle/oracle-database/
-- License....: Apache License Version 2.0, January 2004
--              http://www.apache.org/licenses/
-- ---------------------------------------------------------------------------
-- Modified...:
-- see git log for revision history
-- ---------------------------------------------------------------------------

SPOOL odb_svc_service_trigger_recreate.log

SET ECHO        OFF
SET FEEDBACK    OFF
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
-- Drop existing services (stop first, then delete) and trigger if present
-- ---------------------------------------------------------------------------
DECLARE
    v_pdb_name  VARCHAR2(128);
    v_db_domain VARCHAR2(128);
    v_svc_rw    VARCHAR2(256);
    v_svc_ro    VARCHAR2(256);
    v_count     INTEGER;

    FUNCTION get_service_name(p_suffix IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RTRIM(v_pdb_name || p_suffix || '.' || v_db_domain, '.');
    END;

    PROCEDURE safe_drop_service(p_svc IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM dba_services
         WHERE UPPER(name) = UPPER(p_svc);

        IF v_count > 0 THEN
            BEGIN
                DBMS_OUTPUT.PUT_LINE('Stopping service:  ' || p_svc);
                DBMS_SERVICE.STOP_SERVICE(p_svc);
            EXCEPTION WHEN OTHERS THEN NULL;
            END;
            DBMS_OUTPUT.PUT_LINE('Deleting service:  ' || p_svc);
            DBMS_SERVICE.DELETE_SERVICE(p_svc);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Service not found: ' || p_svc || ' (skip)');
        END IF;
    END;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_pdb_name
      FROM dual;

    SELECT NVL(value, '')
      INTO v_db_domain
      FROM v$parameter
     WHERE name = 'db_domain';

    v_svc_rw := get_service_name('_RW');
    v_svc_ro := get_service_name('_RO');

    safe_drop_service(v_svc_rw);
    safe_drop_service(v_svc_ro);

    -- Drop trigger if present
    SELECT COUNT(*) INTO v_count
      FROM dba_triggers
     WHERE trigger_name = 'ODB_PDB_SERVICE_TRIGGER'
       AND owner        = 'SYS';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Dropping trigger:  ODB_PDB_SERVICE_TRIGGER');
        EXECUTE IMMEDIATE 'DROP TRIGGER sys.odb_pdb_service_trigger';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Trigger not found: ODB_PDB_SERVICE_TRIGGER (skip)');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Cleanup completed.');
END;
/

-- ---------------------------------------------------------------------------
-- Recreate services
-- ---------------------------------------------------------------------------
DECLARE
    v_pdb_name  VARCHAR2(128);
    v_db_domain VARCHAR2(128);
    v_svc_rw    VARCHAR2(256);
    v_svc_ro    VARCHAR2(256);

    FUNCTION get_service_name(p_suffix IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RTRIM(v_pdb_name || p_suffix || '.' || v_db_domain, '.');
    END;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
      INTO v_pdb_name
      FROM dual;

    SELECT NVL(value, '')
      INTO v_db_domain
      FROM v$parameter
     WHERE name = 'db_domain';

    v_svc_rw := get_service_name('_RW');
    v_svc_ro := get_service_name('_RO');

    DBMS_OUTPUT.PUT_LINE('Creating service: ' || v_svc_rw);
    DBMS_SERVICE.CREATE_SERVICE(
        service_name     => v_svc_rw,
        network_name     => v_svc_rw,
        failover_method  => 'BASIC',
        failover_type    => 'SELECT',
        failover_retries => 3600,
        failover_delay   => 1);

    DBMS_OUTPUT.PUT_LINE('Creating service: ' || v_svc_ro);
    DBMS_SERVICE.CREATE_SERVICE(
        service_name     => v_svc_ro,
        network_name     => v_svc_ro,
        failover_method  => 'BASIC',
        failover_type    => 'SELECT',
        failover_retries => 3600,
        failover_delay   => 1);

    DBMS_OUTPUT.PUT_LINE('Services recreated successfully.');
END;
/

-- ---------------------------------------------------------------------------
-- Recreate startup trigger odb_pdb_service_trigger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sys.odb_pdb_service_trigger
    AFTER STARTUP ON DATABASE
DECLARE
    v_pdb_name    VARCHAR2(128);
    v_db_domain   VARCHAR2(128);
    v_db_role     VARCHAR2(30);
    v_svc_rw      VARCHAR2(256);
    v_svc_ro      VARCHAR2(256);
    v_svc_start   VARCHAR2(256);
    v_svc_stop    VARCHAR2(256);
    v_msg         VARCHAR2(512);

    FUNCTION get_service_name(p_suffix IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RTRIM(v_pdb_name || p_suffix || '.' || v_db_domain, '.');
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

    IF v_db_role = 'PRIMARY' THEN
        v_svc_start := v_svc_rw;
        v_svc_stop  := v_svc_ro;
    ELSE
        v_svc_start := v_svc_ro;
        v_svc_stop  := v_svc_rw;
    END IF;

    -- Stop the non-active service if it is currently running
    BEGIN
        DBMS_SERVICE.STOP_SERVICE(v_svc_stop);
    EXCEPTION
        WHEN OTHERS THEN NULL; -- Service may not be running; ignore
    END;

    -- Start the active service
    DBMS_SERVICE.START_SERVICE(v_svc_start);

EXCEPTION
    WHEN OTHERS THEN
        v_msg := 'ODB_PDB_SERVICE_TRIGGER ERROR [' || v_pdb_name ||
                 ']: ' || SQLERRM;
        DBMS_SYSTEM.KSDWRT(2, v_msg);
        RAISE;
END odb_pdb_service_trigger;
/

-- ---------------------------------------------------------------------------
-- Start the correct service immediately
-- ---------------------------------------------------------------------------
DECLARE
    v_pdb_name  VARCHAR2(128);
    v_db_domain VARCHAR2(128);
    v_db_role   VARCHAR2(30);
    v_svc_rw    VARCHAR2(256);
    v_svc_ro    VARCHAR2(256);

    FUNCTION get_service_name(p_suffix IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RTRIM(v_pdb_name || p_suffix || '.' || v_db_domain, '.');
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

    IF v_db_role = 'PRIMARY' THEN
        DBMS_OUTPUT.PUT_LINE('Role: PRIMARY - starting ' || v_svc_rw);
        BEGIN DBMS_SERVICE.STOP_SERVICE(v_svc_ro); EXCEPTION WHEN OTHERS THEN NULL; END;
        DBMS_SERVICE.START_SERVICE(v_svc_rw);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Role: ' || v_db_role || ' - starting ' || v_svc_ro);
        BEGIN DBMS_SERVICE.STOP_SERVICE(v_svc_rw); EXCEPTION WHEN OTHERS THEN NULL; END;
        DBMS_SERVICE.START_SERVICE(v_svc_ro);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Service started successfully.');
END;
/

PROMPT
PROMPT odb_svc_service_trigger_recreate.sql completed.
PROMPT Run odb_svc_service_trigger_show.sql to verify.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_recreate.sql
