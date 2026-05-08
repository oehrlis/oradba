-- ---------------------------------------------------------------------------
-- Trivadis - Part of Accenture, Platform Factory - Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- ---------------------------------------------------------------------------
-- Name.......: odb_svc_service_trigger_create.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.05.08
-- Revision...:
-- Purpose....: Create PDB RW/RO services and the startup trigger
--              odb_pdb_service_trigger (initial, non-destructive).
--              Aborts if services or trigger already exist.
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

SPOOL odb_svc_service_trigger_create.log

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
-- Verify services do not already exist
-- ---------------------------------------------------------------------------
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM dba_services
     WHERE UPPER(name) LIKE UPPER(SYS_CONTEXT('USERENV', 'CON_NAME')) || '\_R_\_%' ESCAPE '\';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20101,
            'ERROR: RW/RO services already exist for PDB ' ||
            SYS_CONTEXT('USERENV', 'CON_NAME') ||
            '. Use odb_svc_service_trigger_recreate.sql to replace them.');
    END IF;
END;
/

-- ---------------------------------------------------------------------------
-- Verify trigger does not already exist
-- ---------------------------------------------------------------------------
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM dba_triggers
     WHERE trigger_name = 'ODB_PDB_SERVICE_TRIGGER'
       AND owner        = 'SYS';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20102,
            'ERROR: Trigger ODB_PDB_SERVICE_TRIGGER already exists. ' ||
            'Use odb_svc_service_trigger_recreate.sql to replace it.');
    END IF;
END;
/

-- ---------------------------------------------------------------------------
-- Derive service names and create services
-- ---------------------------------------------------------------------------
DECLARE
    v_pdb_name    VARCHAR2(128);
    v_db_domain   VARCHAR2(128);
    v_svc_rw      VARCHAR2(256);
    v_svc_ro      VARCHAR2(256);

    -- Build service name: <PDB>_RW[.<domain>] or <PDB>_RO[.<domain>]
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

    DBMS_OUTPUT.PUT_LINE('Services created successfully.');
END;
/

-- ---------------------------------------------------------------------------
-- Create startup trigger odb_pdb_service_trigger
-- Fires AFTER STARTUP ON DATABASE inside the PDB.
-- Starts the service matching the current database role (PRIMARY -> RW,
-- PHYSICAL STANDBY -> RO) and explicitly stops the other service.
-- On error: writes to alert log via DBMS_SYSTEM.KSDWRT and re-raises.
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
        -- Write to alert log
        DBMS_SYSTEM.KSDWRT(2, v_msg);
        RAISE;
END odb_pdb_service_trigger;
/

-- ---------------------------------------------------------------------------
-- Start the correct service immediately (without waiting for next restart)
-- ---------------------------------------------------------------------------
DECLARE
    v_pdb_name    VARCHAR2(128);
    v_db_domain   VARCHAR2(128);
    v_db_role     VARCHAR2(30);
    v_svc_rw      VARCHAR2(256);
    v_svc_ro      VARCHAR2(256);

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
        BEGIN
            DBMS_SERVICE.STOP_SERVICE(v_svc_ro);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        DBMS_SERVICE.START_SERVICE(v_svc_rw);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Role: ' || v_db_role || ' - starting ' || v_svc_ro);
        BEGIN
            DBMS_SERVICE.STOP_SERVICE(v_svc_rw);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        DBMS_SERVICE.START_SERVICE(v_svc_ro);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Service started successfully.');
END;
/

PROMPT
PROMPT odb_svc_service_trigger_create.sql completed.
PROMPT Run odb_svc_service_trigger_show.sql to verify.
PROMPT

SPOOL OFF
-- EOF odb_svc_service_trigger_create.sql
