-- ------------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- ------------------------------------------------------------------------------
-- Name.......: oh.sql (OraDBA Help)
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.01.01
-- Revision...: 0.9.3
-- Purpose....: Display available SQL scripts with names and purposes
-- Notes......: Reads script headers to extract names and purposes from SQLPATH
-- Usage......: @oh [filter]
--              filter - optional pattern to match script names (e.g., 'aud' or 'tde')
-- Reference..: https://github.com/oehrlis/oradba
-- License....: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
-- ------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 200
SET TRIMSPOOL ON

-- Get optional filter parameter
COLUMN 1 NEW_VALUE filter_param NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE filter_pattern = '&1'

PROMPT
PROMPT OraDBA SQL Scripts Help
PROMPT ================================================================================

-- Use HOST command to extract script info from headers
-- Note: Using CONCAT to avoid && being interpreted as SQL*Plus variable
SET DEFINE ON
HOST bash -c 'sqlpath="${SQLPATH:-$PWD}"; filter="&filter_pattern"; echo ""; echo "Location: $sqlpath"; if [ -n "$filter" ]; then echo "Filter: *${filter}*"; fi; echo ""; printf "%-30s %s\n" "Script" "Purpose"; printf "%-30s %s\n" "------------------------------" "------------------------------------------------------------"; IFS=":"; for dir in $sqlpath; do if [ -d "$dir" ]; then cd "$dir" 2>/dev/null || continue; for f in *.sql; do if [ -f "$f" ]; then if [ -z "$filter" ] || echo "$f" | grep -qi "$filter"; then purpose=$(head -20 "$f" | grep -i "^--.*Purpose" | head -1 | sed "s/.*Purpose[.:]*//;s/^[[:space:]]*//;s/[[:space:]]*$//" | cut -c1-60); if [ -n "$purpose" ]; then printf "%-30s %s\n" "$f" "$purpose"; fi; fi; fi; done; fi; done | sort -u'

PROMPT
PROMPT ================================================================================
PROMPT Common Aliases: @who @audit @apol @logins @afails @tde @tdeops
PROMPT Categories: aud_* tde_* sec_* dba_* mon_* util_* net_*
PROMPT Documentation: $ORADBA_PREFIX/doc/08-sql-scripts.md
PROMPT

SET FEEDBACK ON
SET VERIFY ON
SET HEADING ON
SET PAGESIZE 66
-- EOF -------------------------------------------------------------------------
