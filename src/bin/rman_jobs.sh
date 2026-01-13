#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: rman_jobs.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Monitor RMAN operations in v$session_longops (wrapper for longops.sh)
# Notes......: Simple wrapper script for monitoring RMAN backup/restore operations
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute longops.sh with RMAN filter
exec "${SCRIPT_DIR}/longops.sh" --operation "RMAN%" "$@"

# --- EOF ----------------------------------------------------------------------
