-- -----------------------------------------------------------------------
-- oradba - Oracle Database Administration Toolset
-- login.sql - SQL*Plus login script
-- -----------------------------------------------------------------------
-- Copyright (c) 2025 Stefan Oehrli
-- Licensed under the Apache License, Version 2.0
-- -----------------------------------------------------------------------

-- Set SQL*Plus formatting
SET PAGESIZE 50000
SET LINESIZE 200
SET LONG 20000
SET LONGCHUNKSIZE 20000
SET TIMING ON
SET TIME ON
SET SQLPROMPT "_USER'@'_CONNECT_IDENTIFIER> "

-- Set editor
DEFINE _EDITOR=vi

-- Set error handling
WHENEVER SQLERROR CONTINUE

-- Display connection info
PROMPT Connected to Oracle Database
PROMPT

-- Column formatting for common queries
COLUMN owner FORMAT A30
COLUMN object_name FORMAT A30
COLUMN tablespace_name FORMAT A30
COLUMN file_name FORMAT A60
COLUMN username FORMAT A30
COLUMN sid FORMAT 9999
COLUMN serial# FORMAT 99999
COLUMN status FORMAT A10
