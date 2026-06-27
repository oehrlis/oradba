#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_bootstrap.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.27
# Revision...: 0.29.0
# Purpose....: Shared bootstrap loader for OraDBA bin scripts
# Notes......: Source this file instead of resolving ORADBA_BASE ad hoc in each
#              bin script. Idempotent - safe to source multiple times.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Idempotency guard
[[ -n "${_ORADBA_BOOTSTRAP_LOADED:-}" ]] && return 0
readonly _ORADBA_BOOTSTRAP_LOADED=1

# Resolve ORADBA_BASE from this file's location (lib/ -> parent = install root)
# This works whether the script is called directly or sourced.
if [[ -z "${ORADBA_BASE:-}" ]]; then
    if [[ -n "${ORADBA_PREFIX:-}" ]]; then
        echo "WARNING: ORADBA_PREFIX is deprecated; use ORADBA_BASE instead" >&2
        export ORADBA_BASE="${ORADBA_PREFIX}"
    else
        export ORADBA_BASE
        ORADBA_BASE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
fi
export ORADBA_BASE

# Keep ORADBA_PREFIX in sync for one-release compatibility
export ORADBA_PREFIX="${ORADBA_PREFIX:-${ORADBA_BASE}}"

# Source oradba_common.sh (which sources sub-libraries transitively)
_ORADBA_BOOTSTRAP_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_ORADBA_BOOTSTRAP_DIR}/oradba_common.sh" ]]; then
    source "${_ORADBA_BOOTSTRAP_DIR}/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh at ${_ORADBA_BOOTSTRAP_DIR}/oradba_common.sh" >&2
    # shellcheck disable=SC2317
    return 1 2> /dev/null || exit 1
fi
unset _ORADBA_BOOTSTRAP_DIR
