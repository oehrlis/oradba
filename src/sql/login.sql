-- ------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- ------------------------------------------------------------------------------
-- Name.......: login.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2025.12.16
-- Revision...: 0.3.0
-- Purpose....: SQL*Plus login and environment configuration script
-- Notes......: Automatically executed when SQL*Plus starts if in SQLPATH.
--              Sets formatting, timing, and column display options.
-- Reference..: https://github.com/oehrlis/oradba
-- License....: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
-- ------------------------------------------------------------------------------

-- Set SQL*Plus formatting
SET PAGESIZE 50000
SET LINESIZE 200
SET LONG 20000
SET LONGCHUNKSIZE 20000

-- Timing and prompts (commented out to avoid polluting automated queries)
-- Uncomment these for interactive sessions:
-- SET TIMING ON
-- SET TIME ON
-- SET SQLPROMPT "_USER'@'_CONNECT_IDENTIFIER> "

-- Set editor
DEFINE _EDITOR=vi

-- Set error handling
WHENEVER SQLERROR CONTINUE

-- Column formatting for common queries
COLUMN owner FORMAT A30
COLUMN object_name FORMAT A30
COLUMN tablespace_name FORMAT A30
COLUMN file_name FORMAT A60
COLUMN username FORMAT A30
COLUMN sid FORMAT 9999
COLUMN serial# FORMAT 99999
COLUMN status FORMAT A10
