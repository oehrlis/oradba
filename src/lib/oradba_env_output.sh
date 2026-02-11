#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_output.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Shared output formatting for environment/status display
# Notes......: Used by oraenv.sh and oradba_env.sh for consistent formatting
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

[[ -n "${ORADBA_ENV_OUTPUT_LOADED:-}" ]] && return 0
readonly ORADBA_ENV_OUTPUT_LOADED=1

ORADBA_ENV_OUTPUT_LABEL_WIDTH=15

# ------------------------------------------------------------------------------
# Function: oradba_env_output_divider
# Purpose.: Print a divider line
# ------------------------------------------------------------------------------
oradba_env_output_divider() {
    echo "-------------------------------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# Function: oradba_env_output_kv
# Purpose.: Print a label/value pair with consistent alignment
# Args....: $1 - Label
#           $2 - Value
#           $3 - Force output even if value is empty (true/false)
# ------------------------------------------------------------------------------
oradba_env_output_kv() {
    local label="$1"
    local value="$2"
    local force_output="${3:-false}"

    if [[ -n "${value}" ]] || [[ "${force_output}" == "true" ]]; then
        printf "%-${ORADBA_ENV_OUTPUT_LABEL_WIDTH}s : %s\n" "${label}" "${value}"
    fi
}

# ------------------------------------------------------------------------------
# Function: oradba_env_output_resolve_oracle_base
# Purpose.: Resolve ORACLE_BASE for output (never empty)
# Args....: $1 - ORACLE_HOME
# Output..: ORACLE_BASE string
# ------------------------------------------------------------------------------
oradba_env_output_resolve_oracle_base() {
    local oracle_home="$1"
    local oracle_base="${ORACLE_BASE:-}"

    if [[ -z "${oracle_base}" ]] && command -v derive_oracle_base &>/dev/null; then
        oracle_base=$(derive_oracle_base "${oracle_home}" 2>/dev/null || true)
    fi

    if [[ -z "${oracle_base}" ]]; then
        oracle_base="not set"
    fi

    echo "${oracle_base}"
}

# ------------------------------------------------------------------------------
# Function: oradba_env_output_print_home_section
# Purpose.: Print the home/environment section
# Args....: $1 - ORACLE_BASE
#           $2 - ORACLE_HOME
#           $3 - TNS_ADMIN
#           $4 - DATASAFE_HOME
#           $5 - JAVA_HOME
#           $6 - ORACLE_VERSION
#           $7 - PRODUCT_TYPE
# ------------------------------------------------------------------------------
oradba_env_output_print_home_section() {
    local oracle_base="$1"
    local oracle_home="$2"
    local tns_admin="$3"
    local datasafe_home="$4"
    local java_home="$5"
    local oracle_version="$6"
    local product_type="$7"

    oradba_env_output_divider
    oradba_env_output_kv "ORACLE_BASE" "${oracle_base}" true
    oradba_env_output_kv "ORACLE_HOME" "${oracle_home}"
    oradba_env_output_kv "TNS_ADMIN" "${tns_admin}"
    oradba_env_output_kv "DATASAFE_HOME" "${datasafe_home}"
    oradba_env_output_kv "JAVA_HOME" "${java_home}"
    oradba_env_output_kv "ORACLE_VERSION" "${oracle_version}"
    oradba_env_output_kv "PRODUCT_TYPE" "${product_type}"
    oradba_env_output_divider
}

# ------------------------------------------------------------------------------
# Function: show_oracle_home_status
# Purpose.: Display Oracle Home environment info for non-database homes
# Parameters: $1 - Override product type
#             $2 - Override ORACLE_HOME
#             $3 - Override instance name
#             $4 - Include instance/service section (true/false)
# ------------------------------------------------------------------------------
show_oracle_home_status() {
    local override_type="$1"
    local override_home="$2"
    local override_instance="$3"
    local include_instance="${4:-true}"
    local product_type="${override_type:-${ORADBA_CURRENT_HOME_TYPE:-Oracle Home}}"
    local oracle_home="${override_home:-${ORACLE_HOME:-}}"
    local instance_name="${override_instance:-${ORACLE_SID:-}}"
    local product_version=""
    local status=""
    local datasafe_home=""
    local meta_version=""
    local meta_port=""
    local meta_ports=""
    local meta_service=""
    local meta_java_home=""
    local meta_connections=""
    local meta_cman_start_date=""
    local meta_cman_uptime=""
    local meta_cman_gateways=""
    local metadata=""
    local product_type_lower="${product_type,,}"
    local tns_admin="${TNS_ADMIN:-}"
    local java_home=""

    if [[ "${product_type_lower}" == "datasafe" ]]; then
        datasafe_home="${DATASAFE_INSTALL_DIR:-${DATASAFE_HOME:-}}"
        if [[ -z "${datasafe_home}" ]]; then
            datasafe_home="${oracle_home}"
        fi
        if [[ -d "${datasafe_home}/oracle_cman_home" ]]; then
            oracle_home="${datasafe_home}/oracle_cman_home"
        fi
    fi

    if [[ -z "${tns_admin}" ]]; then
        if [[ -n "${oracle_home}" ]] && [[ -d "${oracle_home}/network/admin" ]]; then
            tns_admin="${oracle_home}/network/admin"
        elif [[ -n "${datasafe_home}" ]] && [[ -d "${datasafe_home}/network/admin" ]]; then
            tns_admin="${datasafe_home}/network/admin"
        fi
    fi

    if command -v execute_plugin_function_v2 &>/dev/null; then
        local metadata_home="${oracle_home}"
        if [[ -n "${datasafe_home}" ]]; then
            metadata_home="${datasafe_home}"
        fi
        execute_plugin_function_v2 "${product_type_lower}" "get_metadata" "${metadata_home}" "metadata" "${instance_name}" 2>/dev/null || true
    fi

    if [[ -n "${metadata}" ]]; then
        while IFS='=' read -r key value; do
            case "${key}" in
                version)
                    meta_version="${value}"
                    ;;
                port)
                    meta_port="${value}"
                    ;;
                ports)
                    meta_ports="${value}"
                    ;;
                service_name)
                    meta_service="${value}"
                    ;;
                java_home)
                    meta_java_home="${value}"
                    ;;
                connections)
                    meta_connections="${value}"
                    ;;
                cman_start_date)
                    meta_cman_start_date="${value}"
                    ;;
                cman_uptime)
                    meta_cman_uptime="${value}"
                    ;;
                cman_gateways)
                    meta_cman_gateways="${value}"
                    ;;
            esac
        done <<< "${metadata}"
    fi

    if [[ -n "${meta_version}" ]]; then
        product_version="${meta_version}"
    else
        product_version=$(get_oracle_version 2>/dev/null || echo "")
    fi

    if [[ "${product_version}" == "unknown" || "${product_version}" == "Unknown" ]]; then
        product_version=""
    fi

    if [[ -n "${meta_java_home}" ]]; then
        java_home="${meta_java_home}"
    elif [[ -n "${JAVA_HOME:-}" ]]; then
        java_home="${JAVA_HOME}"
    elif command -v oradba_resolve_java_home &>/dev/null && [[ -n "${oracle_home}" ]]; then
        java_home=$(oradba_resolve_java_home "${oracle_home}" 2>/dev/null || true)
    fi

    if [[ "${include_instance}" == "true" ]] && command -v oradba_get_product_status &>/dev/null; then
        case "${product_type_lower}" in
            client|iclient|java)
                status=""
                ;;
            *)
                status=$(oradba_get_product_status "${product_type}" "${instance_name}" "${oracle_home}" 2>/dev/null || true)
                if [[ "${status}" == "N/A" ]]; then
                    status=""
                fi
                ;;
        esac
    fi

    local oracle_base
    oracle_base=$(oradba_env_output_resolve_oracle_base "${oracle_home}")

    echo ""
    oradba_env_output_print_home_section "${oracle_base}" "${oracle_home}" "${tns_admin}" "${datasafe_home}" "${java_home}" "${product_version}" "${product_type}"

    if [[ "${include_instance}" != "true" ]]; then
        echo ""
        return 0
    fi

    local has_instance=false
    if [[ -n "${status}" ]]; then
        oradba_env_output_kv "STATUS" "${status}"
        has_instance=true
    fi
    if [[ -n "${meta_service}" ]]; then
        oradba_env_output_kv "SERVICE" "${meta_service}"
        has_instance=true
    fi
    if [[ -n "${meta_ports}" ]]; then
        oradba_env_output_kv "PORTS" "${meta_ports}"
        has_instance=true
    elif [[ -n "${meta_port}" ]]; then
        oradba_env_output_kv "PORT" "${meta_port}"
        has_instance=true
    fi
    if [[ -n "${meta_connections}" ]]; then
        oradba_env_output_kv "CONNECTIONS" "${meta_connections}"
        has_instance=true
    fi
    
    # Display CMAN status details for Data Safe
    if [[ -n "${meta_cman_start_date}" ]]; then
        oradba_env_output_kv "START DATE" "${meta_cman_start_date}"
        has_instance=true
    fi
    if [[ -n "${meta_cman_uptime}" ]]; then
        oradba_env_output_kv "UPTIME" "${meta_cman_uptime}"
        has_instance=true
    fi
    if [[ -n "${meta_cman_gateways}" ]]; then
        oradba_env_output_kv "GATEWAYS" "${meta_cman_gateways}"
        has_instance=true
    fi

    if [[ "${has_instance}" == "true" ]]; then
        oradba_env_output_divider
    fi

    echo ""
}
