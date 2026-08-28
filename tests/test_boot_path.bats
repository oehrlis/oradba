#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: test_boot_path.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.08.28
# Revision...: 1.0.5
# Purpose....: Regression test for the non-interactive boot path. Guards the
#              defect class that produced v1.0.1 through v1.0.4: a bare ${VAR}
#              reference under `set -euo pipefail` aborts the script when the
#              caller's environment does not define the variable.
# Notes......: Needs no Oracle and no container. Every one of those defects
#              fires while sourcing or during argument parsing, long before any
#              Oracle contact, so an empty environment reproduces all of them in
#              milliseconds. `systemd` starts oradba through `su - oracle -c`
#              with no profile loaded: HOME, PATH, USER, LOGNAME and SHELL are
#              set, everything Oracle-related is not. boot_env() models exactly
#              that, and deliberately does NOT set ORACLE_HOME, ORACLE_SID,
#              ORACLE_BASE or TNS_ADMIN. Runs under bash >= 4.0 because oradba
#              uses `declare -A`; macOS /bin/bash 3.2 would fail on the shell,
#              not on the code under test.
# ------------------------------------------------------------------------------

setup() {
    ORADBA_SRC="${BATS_TEST_DIRNAME}/../src"
    BOOT_HOME="${BATS_TEST_TMPDIR}/boot_home"
    mkdir -p "${BOOT_HOME}"

    # The target platform is Oracle Linux with bash 4.4+; oradba uses
    # `declare -A`. macOS ships bash 3.2 as /bin/bash, which fails on that with
    # "declare: -A: invalid option" - a platform artefact, not a boot-path
    # defect, and one that would mask the real findings. Resolve a bash >= 4.0
    # and skip loudly if there is none.
    BOOT_BASH=""
    local candidate
    for candidate in "${BASH}" "$(command -v bash || true)" /usr/local/bin/bash \
        /opt/homebrew/bin/bash /bin/bash; do
        [ -n "${candidate}" ] || continue
        [ -x "${candidate}" ] || continue
        local major
        major="$("${candidate}" -c 'echo "${BASH_VERSINFO[0]}"' 2> /dev/null || echo 0)"
        if [ "${major:-0}" -ge 4 ]; then
            BOOT_BASH="${candidate}"
            break
        fi
    done
    if [ -z "${BOOT_BASH}" ]; then
        skip "no bash >= 4.0 found - cannot model the Oracle Linux boot path"
    fi
}

# ------------------------------------------------------------------------------
# Function: boot_env
# Purpose.: Run a bash snippet in the environment systemd/su hands to oradba
# Params..: $1 - bash snippet to execute under `set -euo pipefail`
# Returns.: exit code of the snippet
# Output..: stdout and stderr of the snippet
# Notes...: `env -i` clears the environment; only the variables `su - oracle -c`
#           guarantees are put back. Do not add Oracle variables here - their
#           absence is the whole point of this file.
# ------------------------------------------------------------------------------
boot_env() {
    env -i \
        HOME="${BOOT_HOME}" \
        PATH="$(dirname "${BOOT_BASH}"):/usr/bin:/bin:/usr/sbin:/sbin" \
        USER="oracle" \
        LOGNAME="oracle" \
        SHELL="${BOOT_BASH}" \
        "${BOOT_BASH}" -c "set -euo pipefail
$1"
}

# ------------------------------------------------------------------------------
# Layer 1+2: the config files must survive being sourced with no Oracle env
# ------------------------------------------------------------------------------

@test "boot path: oradba_core.conf sources with an empty environment" {
    run boot_env "export ORADBA_PREFIX='${ORADBA_SRC}'
source '${ORADBA_SRC}/etc/oradba_core.conf'"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"unbound variable"* ]]
}

@test "boot path: oradba_standard.conf sources after core.conf with an empty environment" {
    run boot_env "export ORADBA_PREFIX='${ORADBA_SRC}'
source '${ORADBA_SRC}/etc/oradba_core.conf'
source '${ORADBA_SRC}/etc/oradba_standard.conf'"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"unbound variable"* ]]
}

@test "boot path: no config file expands a bare \$VAR inside a default value" {
    # Regression for oradba_standard.conf:71, which shipped
    #   RLWRAP_OPTS="${RLWRAP_OPTS:--i -c -f $ORACLE_HOME/bin/sqlplus}"
    # The *default* referenced ORACLE_HOME with a bare $, so an unset
    # RLWRAP_OPTS aborted the boot. Only the bare form is matched on purpose:
    # a nested ${OTHER} inside a default is legitimate here (core.conf sets
    # ORADBA_PREFIX before it is used), while a bare $VAR inside a default is
    # never intentional in this codebase. Escaped \$ sequences are stripped
    # first - those are literals for later evaluation (the PS1 prompt), not
    # expansions at source time.
    run bash -c "
        for f in '${ORADBA_SRC}'/etc/*.conf; do
            sed 's/\\\\[\$]//g' \"\${f}\" |
                grep -nE '[\$][{][A-Za-z_][A-Za-z0-9_]*:[-+][^}]*[\$][A-Za-z_]' |
                sed \"s|^|\${f}:|\"
        done
        true"
    [ "${output}" = "" ]
}

# ------------------------------------------------------------------------------
# Layer 3: libraries must load standalone, include guards included
# ------------------------------------------------------------------------------

@test "boot path: oradba_common.sh sources with an empty environment" {
    run boot_env "source '${ORADBA_SRC}/lib/oradba_common.sh'"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"unbound variable"* ]]
}

@test "boot path: oradba_env_parser.sh include guard survives the first load" {
    # Regression for the guard that read ${ORADBA_ENV_PARSER_LOADED} bare and
    # therefore aborted on the very first source.
    run boot_env "source '${ORADBA_SRC}/lib/oradba_env_parser.sh'"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"unbound variable"* ]]
}

@test "boot path: every library sources twice without tripping its include guard" {
    # oradba_common.sh is the documented prerequisite for the other libraries,
    # so it is loaded first on purpose - a library refusing to load standalone
    # is by design, an include guard aborting on reload is the defect (5).
    local lib
    for lib in "${ORADBA_SRC}"/lib/*.sh; do
        [ "$(basename "${lib}")" = "oradba_common.sh" ] && continue
        run boot_env "source '${ORADBA_SRC}/lib/oradba_common.sh'
source '${lib}'
source '${lib}'"
        [ "${status}" -eq 0 ] || {
            echo "double-source failed: ${lib}"
            echo "${output}"
            false
        }
    done

    # oradba_common.sh itself must also tolerate a reload.
    run boot_env "source '${ORADBA_SRC}/lib/oradba_common.sh'
source '${ORADBA_SRC}/lib/oradba_common.sh'"
    [ "${status}" -eq 0 ]
}

# ------------------------------------------------------------------------------
# Layer 4: entry points must parse arguments without an Oracle environment
# ------------------------------------------------------------------------------

@test "boot path: oraenv.sh survives being sourced with an empty environment" {
    # oraenv.sh refuses to run when executed ("must be sourced"), so executing
    # it proves nothing - it exits before reaching the code that carried defect
    # 6 (ORACLE_HOME unbound at line 1368). Source it, which is how the profile
    # and every consumer actually load it.
    run boot_env "source '${ORADBA_SRC}/bin/oraenv.sh' || true
echo SOURCED_OK"
    [[ "${output}" == *"SOURCED_OK"* ]]
    [[ "${output}" != *"unbound variable"* ]]
    [[ "${output}" != *"command not found"* ]]
}

@test "boot path: entry scripts answer --help with an empty environment" {
    # --help must never touch Oracle. A failure here is the boot path aborting
    # during sourcing or argument parsing, which is what defects 1, 3 and 6 did.
    local script
    for script in oradba_services.sh oradba_services_root.sh \
        oradba_lsnrctl.sh oradba_dbctl.sh oradba_dsctl.sh oradba_rman.sh; do
        [ -f "${ORADBA_SRC}/bin/${script}" ] || continue
        run boot_env "'${ORADBA_SRC}/bin/${script}' --help"
        [[ "${output}" != *"unbound variable"* ]] || {
            echo "unbound variable in ${script} --help:"
            echo "${output}"
            false
        }
        [[ "${output}" != *"command not found"* ]] || {
            echo "command not found in ${script} --help:"
            echo "${output}"
            false
        }
    done
}

@test "boot path: oradba_services.sh start --force does not abort on unbound variables" {
    # The exact systemd invocation. It is expected to fail (no Oracle here), but
    # it must fail on Oracle grounds, never with `unbound variable` or
    # `log_message: command not found` (defects 1 and 2).
    #
    # ORADBA_LOG points the log directory at a writable path. Without it the
    # script aborts on an unwritable /var/log/oracle before it ever reaches the
    # defect sites, which made this test pass vacuously against v1.0.0. The lab
    # host has a writable /var/log/oracle, so this models the real boot rather
    # than a macOS artefact. ORADBA_LOG is the hook the scripts already honour:
    #   LOGFILE="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}.log"
    run boot_env "export ORADBA_LOG='${BATS_TEST_TMPDIR}'
'${ORADBA_SRC}/bin/oradba_services.sh' start --force"
    [[ "${output}" != *"unbound variable"* ]]
    [[ "${output}" != *"command not found"* ]]
}

@test "boot path: oradba_lsnrctl.sh start does not abort on unbound TNS_ADMIN" {
    # Regression for defect 3: TNS_ADMIN unbound, listener never started.
    run boot_env "export ORADBA_LOG='${BATS_TEST_TMPDIR}'
'${ORADBA_SRC}/bin/oradba_lsnrctl.sh' status"
    [[ "${output}" != *"TNS_ADMIN: unbound variable"* ]]
    [[ "${output}" != *"unbound variable"* ]]
}

# ------------------------------------------------------------------------------
# Layer 5: logging must not abort its caller and must not need a system dir
# ------------------------------------------------------------------------------

@test "boot path: oradba_log writes without aborting when no log dir is writable" {
    # Regression for defect 2 (a log write aborted its caller) and for M7
    # (_oradba_log_to_file creating a root-owned /var/log/oracle).
    run boot_env "source '${ORADBA_SRC}/lib/oradba_common.sh'
oradba_log INFO 'boot path probe' || true
echo LOGGED_OK"
    [[ "${output}" == *"LOGGED_OK"* ]]
    [[ "${output}" != *"unbound variable"* ]]
}
