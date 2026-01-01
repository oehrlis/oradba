-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: db_info.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......:2026.01.01
-- Revision..: 0.9.5
-- Purpose...: Display comprehensive database information
-- Notes.....: Shows database name, instance details, and datafile information.
--              Run as: sqlplus / as sysdba @db_info.sql
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

SET PAGESIZE 1000
SET LINESIZE 200
SET FEEDBACK OFF
SET HEADING ON

PROMPT ========================================
PROMPT Database Information
PROMPT ========================================
PROMPT

SELECT 
    name AS "Database Name",
    db_unique_name AS "DB Unique Name",
    dbid AS "Database ID",
    created AS "Created",
    log_mode AS "Log Mode",
    open_mode AS "Open Mode",
    platform_name AS "Platform"
FROM v$database;

PROMPT
PROMPT ========================================
PROMPT Instance Information
PROMPT ========================================
PROMPT

SELECT 
    instance_name AS "Instance Name",
    host_name AS "Host Name",
    version AS "Version",
    startup_time AS "Startup Time",
    status AS "Status",
    database_status AS "Database Status"
FROM v$instance;

PROMPT
PROMPT ========================================
PROMPT Datafiles
PROMPT ========================================
PROMPT

SELECT 
    tablespace_name AS "Tablespace",
    COUNT(*) AS "Files",
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS "Size (GB)",
    ROUND(SUM(maxbytes)/1024/1024/1024, 2) AS "Max Size (GB)"
FROM dba_data_files
GROUP BY tablespace_name
ORDER BY tablespace_name;

SET FEEDBACK ON
