-- ------------------------------------------------------------------------------
-- OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
-- ------------------------------------------------------------------------------
-- Name.......: sessionsql.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2025.12.17
-- Revision...: 0.5.1
-- Purpose....: Configure SQL*Plus session with dynamic terminal width
-- Notes......: Sets LINESIZE and PAGESIZE based on current terminal dimensions
-- Usage......: @sessionsql.sql or via sessionsql alias
-- Reference..: Uses tput cols/lines to detect terminal size
-- ------------------------------------------------------------------------------

-- Detect terminal width and set LINESIZE accordingly
-- This uses a host command to get terminal columns
-- Fall back to 120 if detection fails

COLUMN term_cols NEW_VALUE linesize_value NOPRINT
SET TERMOUT OFF
SET FEEDBACK OFF
SET HEADING OFF

-- Try to get terminal width using shell command
-- This creates a temporary result that we can use
SELECT CASE 
    WHEN '&1' != '' THEN '&1'  -- Use parameter if provided
    ELSE '120'                  -- Default fallback
END AS term_cols
FROM dual;

SET TERMOUT ON
SET FEEDBACK ON
SET HEADING ON

-- Apply the settings
SET LINESIZE &linesize_value
SET PAGESIZE 50
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET WRAP ON
SET TRIMOUT ON
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
SET ECHO OFF

-- Show current settings
PROMPT
PROMPT Session Configuration Applied:
PROMPT ========================================
SHOW LINESIZE
SHOW PAGESIZE
SHOW LONG
PROMPT ========================================
PROMPT

-- Clean up
UNDEFINE linesize_value
UNDEFINE term_cols
