-- -----------------------------------------------------------------------
-- oradba - Oracle Database Administration Toolset
-- db_info.sql - Display database information
-- -----------------------------------------------------------------------
-- Copyright (c) 2025 Stefan Oehrli
-- Licensed under the Apache License, Version 2.0
-- -----------------------------------------------------------------------

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
