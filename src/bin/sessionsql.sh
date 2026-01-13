#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: sessionsql.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Configure SQL*Plus session with dynamic terminal width
# Notes......: Wrapper script that detects terminal width and launches SQL*Plus
# Usage......: sessionsql.sh [connection_string]
# Reference..: Uses tput cols to detect terminal size
# ------------------------------------------------------------------------------

# Detect terminal width
if command -v tput &> /dev/null; then
    TERM_COLS=$(tput cols 2> /dev/null || echo 120)
else
    TERM_COLS=120
fi

# Detect terminal height
if command -v tput &> /dev/null; then
    TERM_LINES=$(tput lines 2> /dev/null || echo 50)
else
    TERM_LINES=50
fi

# Calculate pagesize (terminal height - 5 for headers/footers)
PAGESIZE=$((TERM_LINES - 5))
[[ $PAGESIZE -lt 10 ]] && PAGESIZE=10

# Get connection string if provided
CONN_STRING="${1:-/ as sysdba}"

# Source directory (location of this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/../sql"

# Check if sessionsql.sql exists
if [[ ! -f "${SQL_DIR}/sessionsql.sql" ]]; then
    echo "Error: sessionsql.sql not found in ${SQL_DIR}"
    exit 1
fi

# Launch SQL*Plus with dynamic settings
sqlplus -S "$CONN_STRING" << EOF
SET LINESIZE ${TERM_COLS}
SET PAGESIZE ${PAGESIZE}
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET WRAP ON
SET TRIMOUT ON
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF

PROMPT
PROMPT Session Configuration Applied:
PROMPT ========================================
PROMPT Terminal Size: ${TERM_COLS} columns x ${TERM_LINES} lines
SHOW LINESIZE
SHOW PAGESIZE
SHOW LONG
PROMPT ========================================
PROMPT
PROMPT Connected to:
SELECT 'Database: ' || name || ' (' || database_role || ')' FROM v\$database;
SELECT 'Instance: ' || instance_name || ' - ' || host_name FROM v\$instance;
PROMPT
PROMPT Type EXIT to quit or continue with SQL commands...
PROMPT

-- Keep session open for interactive use
SET SQLPROMPT "SQL> "
EOF
