#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2016
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_conventions_defaults.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.10.12
# Purpose....: Fallback defaults from the conventions page: ORACLE_BASE
#              (/u00/app/oracle, #225) and the control-script log directory
#              (/tmp fallback, M7) - both with a WARN, never silent
# Usage......: bats test_conventions_defaults.bats
# Reference..: https://github.com/oehrlis/oradba - src/doc/conventions.md
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    BIN_DIR="${PROJECT_ROOT}/src/bin"
    CONTROL_SCRIPTS=(oradba_dsctl.sh oradba_rman.sh oradba_services.sh
        oradba_lsnrctl.sh oradba_dbctl.sh oradba_services_root.sh)
}

# Run a snippet with oradba_common.sh loaded and a clean ORACLE_BASE
common_run() {
    run env -u ORACLE_BASE -u ORADBA_DEFAULT_ORACLE_BASE ORADBA_BASE="${ORADBA_BASE}" \
        "$@"
}

@test "oradba_default_oracle_base returns ORACLE_BASE when set, without WARN" {
    run env ORACLE_BASE=/opt/site/oracle ORADBA_BASE="${ORADBA_BASE}" bash -c '
        set -euo pipefail; source "${ORADBA_BASE}/lib/oradba_common.sh"
        oradba_default_oracle_base'
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/site/oracle" ]
}

@test "oradba_default_oracle_base falls back to /u00/app/oracle with WARN" {
    common_run bash -c '
        set -euo pipefail; source "${ORADBA_BASE}/lib/oradba_common.sh"
        oradba_default_oracle_base'
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARN"*"ORACLE_BASE not set"* ]]
    [ "${lines[-1]}" = "/u00/app/oracle" ]
}

@test "oradba_default_oracle_base honours ORADBA_DEFAULT_ORACLE_BASE" {
    common_run ORADBA_DEFAULT_ORACLE_BASE=/u01/app/oracle bash -c '
        set -euo pipefail; source "${ORADBA_BASE}/lib/oradba_common.sh"
        oradba_default_oracle_base 2>/dev/null'
    [ "$status" -eq 0 ]
    [ "$output" = "/u01/app/oracle" ]
}

@test "oradba_resolve_log_file uses ORADBA_LOG when writable, without WARN" {
    run env ORADBA_LOG="${BATS_TEST_TMPDIR}/logs" ORADBA_BASE="${ORADBA_BASE}" bash -c '
        set -euo pipefail; source "${ORADBA_BASE}/lib/oradba_common.sh"
        oradba_resolve_log_file x.log'
    [ "$status" -eq 0 ]
    [ "$output" = "${BATS_TEST_TMPDIR}/logs/x.log" ]
    [ -d "${BATS_TEST_TMPDIR}/logs" ]
}

@test "all six control scripts resolve their log file through oradba_resolve_log_file" {
    local script
    for script in "${CONTROL_SCRIPTS[@]}"; do
        grep -q 'oradba_resolve_log_file' "${BIN_DIR}/${script}" || {
            echo "missing in ${script}"
            return 1
        }
    done
    run grep -n '/var/log/oracle}/\|^LOGFILE="/var/log/oracle' \
        "${CONTROL_SCRIPTS[@]/#/${BIN_DIR}/}"
    [ "$status" -eq 1 ]
}

@test "no /u01/app/oracle runtime fallback left for ORACLE_BASE" {
    run grep -rn 'ORACLE_BASE:-/u01/app/oracle\|ORACLE_BASE:-/opt/oracle' "${PROJECT_ROOT}/src" \
        --include='*.sh'
    [ "$status" -eq 1 ]
}

@test "oradba_logrotate.sh resolve_oracle_base warns and uses the default" {
    local script="${BATS_TEST_TMPDIR}/rob.sh"
    {
        echo 'set -euo pipefail'
        echo 'YELLOW="" NC=""'
        sed -n '/^print_message() {/,/^}/p' "${BIN_DIR}/oradba_logrotate.sh"
        sed -n '/^resolve_oracle_base() {/,/^}/p' "${BIN_DIR}/oradba_logrotate.sh"
        echo 'resolve_oracle_base'
    } > "$script"
    run env -u ORACLE_BASE -u ORADBA_DEFAULT_ORACLE_BASE bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARN: ORACLE_BASE not set"* ]]
    [ "${lines[-1]}" = "/u00/app/oracle" ]
}

@test "oradba_dbca.sh uses ORACLE_DATA and ORACLE_ARCH roots when set" {
    grep -qF 'DATA_DIR="${DATA_DIR:-${ORACLE_DATA}/oradata/${DB_UNIQUE_NAME}}"' "${BIN_DIR}/oradba_dbca.sh"
    grep -qF 'FRA_DIR="${FRA_DIR:-${ORACLE_ARCH}/fast_recovery_area}"' "${BIN_DIR}/oradba_dbca.sh"
}
