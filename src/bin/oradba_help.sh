#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_help.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.02
# Version....: v0.10.4
# Purpose....: Quick help system showing available help resources
# Notes......: Routes to existing help commands and documentation
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0
# ------------------------------------------------------------------------------

# Script metadata (unused but kept for consistency)
# shellcheck disable=SC2034
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
# shellcheck disable=SC2034
SCRIPT_VERSION="0.10.4"
readonly SCRIPT_VERSION

# Color definitions
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_GREEN='\033[32m'
readonly COLOR_YELLOW='\033[33m'
readonly COLOR_BLUE='\033[34m'

# Show main help menu
show_main_help() {
    cat << 'EOF'
===============================================================================
                          OraDBA Help System
===============================================================================

Quick access to OraDBA help resources. For comprehensive documentation,
visit https://oehrlis.github.io/oradba/

USAGE
    oradba help [TOPIC]

TOPICS
    aliases         Shell aliases for database administration
    scripts         Available OraDBA scripts
    variables       Environment variables (ORADBA_*, ORACLE_*)
    config          Configuration system and files
    sql             SQL*Plus scripts and helpers
    online          Open online documentation

QUICK HELP
    alih            Display alias reference
    version         Show OraDBA version and installation info
    oraenv.sh -h    Environment setup help

DOCUMENTATION
    Online:  https://oehrlis.github.io/oradba/
    PDF:     ${ORADBA_PREFIX}/doc/oradba-user-guide.pdf (if available)
    Local:   ${ORADBA_PREFIX}/doc/

EXAMPLES
    oradba help aliases      # Show alias help
    oradba help variables    # List environment variables
    oradba help scripts      # List available scripts

For detailed documentation on any topic, visit the online docs.

EOF
}

# Show alias help
show_alias_help() {
    echo -e "${COLOR_BOLD}OraDBA Aliases${COLOR_RESET}\n"
    echo "Quick alias reference (comprehensive list):"
    echo ""

    if [[ -f "${ORADBA_PREFIX}/doc/alias_help.txt" ]]; then
        cat "${ORADBA_PREFIX}/doc/alias_help.txt"
    else
        echo "Alias help file not found."
    fi

    echo -e "\n${COLOR_BLUE}For detailed alias documentation:${COLOR_RESET}"
    echo "  Online: https://oehrlis.github.io/oradba/06-aliases/"
    echo "  Command: alih"
    echo "  Search: alig <pattern>"
}

# Show available scripts
show_scripts_help() {
    echo -e "${COLOR_BOLD}OraDBA Scripts${COLOR_RESET}\n"
    echo "Available scripts in ${ORADBA_BIN_DIR:-${ORADBA_PREFIX}/bin}:"
    echo ""

    local bin_dir="${ORADBA_BIN_DIR:-${ORADBA_PREFIX}/bin}"
    if [[ -d "$bin_dir" ]]; then
        echo "Core Scripts:"
        for script in "$bin_dir"/*.sh; do
            if [[ -f "$script" ]]; then
                local name
                name=$(basename "$script")
                # Extract purpose from header if available
                local purpose
                purpose=$(grep -m 1 "^# Purpose" "$script" | sed 's/^# Purpose\.*: *//' | cut -c1-60)
                printf "  ${COLOR_GREEN}%-25s${COLOR_RESET} %s\n" "$name" "$purpose"
            fi
        done
    fi

    echo ""
    echo -e "${COLOR_BLUE}Usage:${COLOR_RESET}"
    echo "  script.sh --help    # Show detailed help for any script"
    echo ""
    echo -e "${COLOR_BLUE}SQL Scripts:${COLOR_RESET}"
    echo "  Location: ${ORADBA_PREFIX}/sql/"
    echo "  Help: oh.sql help   (within SQL*Plus)"
    echo ""
    echo -e "${COLOR_BLUE}For more information:${COLOR_RESET}"
    echo "  https://oehrlis.github.io/oradba/08-sql-scripts/"
}

# Show environment variables
show_variables_help() {
    echo -e "${COLOR_BOLD}OraDBA Environment Variables${COLOR_RESET}\n"
    echo "Currently set variables:"
    echo ""

    echo -e "${COLOR_GREEN}OraDBA Variables:${COLOR_RESET}"
    env | grep "^ORADBA_" | sort | while IFS= read -r line; do
        echo "  $line"
    done

    echo ""
    echo -e "${COLOR_GREEN}Oracle Variables:${COLOR_RESET}"
    for var in ORACLE_SID ORACLE_HOME ORACLE_BASE TNS_ADMIN NLS_LANG; do
        if [[ -n "${!var}" ]]; then
            echo "  $var=${!var}"
        fi
    done

    echo ""
    echo -e "${COLOR_BLUE}Key Variables:${COLOR_RESET}"
    echo "  ORADBA_PREFIX        Installation directory"
    echo "  ORADBA_DEBUG         Debug mode (true/false)"
    echo "  ORADBA_LOAD_ALIASES  Load aliases (true/false)"
    echo "  ORACLE_SID           Current database instance"
    echo "  ORACLE_HOME          Oracle software location"
    echo ""
    echo -e "${COLOR_BLUE}For detailed configuration:${COLOR_RESET}"
    echo "  https://oehrlis.github.io/oradba/05-configuration/"
}

# Show configuration help
show_config_help() {
    echo -e "${COLOR_BOLD}OraDBA Configuration System${COLOR_RESET}\n"
    echo "Configuration files (loaded in order, later overrides earlier):"
    echo ""

    local etc_dir="${ORADBA_ETC:-${ORADBA_PREFIX}/etc}"
    local config_files=(
        "oradba_core.conf:Core system settings"
        "oradba_standard.conf:Standard environment and aliases"
        "oradba_customer.conf:Your custom settings (optional)"
        "sid._DEFAULT_.conf:Default SID settings (optional)"
        "sid.${ORACLE_SID}.conf:Current SID settings (optional)"
    )

    for entry in "${config_files[@]}"; do
        IFS=':' read -r file desc <<< "$entry"
        local full_path="${etc_dir}/${file}"
        if [[ -f "$full_path" ]]; then
            printf "  ${COLOR_GREEN}✓${COLOR_RESET} %-30s %s\n" "$file" "$desc"
        else
            printf "  ${COLOR_YELLOW}○${COLOR_RESET} %-30s %s\n" "$file" "$desc"
        fi
    done

    echo ""
    echo -e "${COLOR_BLUE}Edit configuration:${COLOR_RESET}"
    echo "  vic    # Edit customer config"
    echo "  vii    # Edit SID-specific config"
    echo ""
    echo -e "${COLOR_BLUE}For detailed information:${COLOR_RESET}"
    echo "  https://oehrlis.github.io/oradba/05-configuration/"
}

# Show SQL help
show_sql_help() {
    echo -e "${COLOR_BOLD}OraDBA SQL Scripts${COLOR_RESET}\n"
    echo "SQL*Plus scripts location: ${ORADBA_PREFIX}/sql/"
    echo ""
    echo -e "${COLOR_GREEN}Quick Start:${COLOR_RESET}"
    echo "  sq              # Connect as SYSDBA"
    echo "  @oh.sql help    # Show SQL script help (within SQL*Plus)"
    echo ""
    echo -e "${COLOR_GREEN}Key Scripts:${COLOR_RESET}"
    echo "  login.sql       Automatic login configuration"
    echo "  db_info.sql     Database information summary"
    echo "  sessionsql.sql  Session-aware SQL*Plus setup"
    echo ""
    echo -e "${COLOR_BLUE}For more scripts:${COLOR_RESET}"
    echo "  ls ${ORADBA_PREFIX}/sql/"
    echo "  https://oehrlis.github.io/oradba/08-sql-scripts/"
}

# Open online documentation
show_online_help() {
    local url="https://oehrlis.github.io/oradba/"
    echo -e "${COLOR_BOLD}Opening Online Documentation${COLOR_RESET}"
    echo ""
    echo "URL: $url"
    echo ""

    # Try to open in browser
    if command -v open > /dev/null 2>&1; then
        open "$url"
        echo "Documentation opened in your default browser."
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$url"
        echo "Documentation opened in your default browser."
    else
        echo "Please open the URL manually in your browser."
    fi
}

# Main
main() {
    # Handle 'oradba help <topic>' and 'oradba <topic>' formats
    local topic="${1:-}"

    # If first arg is 'help', shift to get actual topic
    if [[ "$topic" == "help" ]]; then
        topic="${2:-}"
    fi

    case "$topic" in
        "")
            show_main_help
            ;;
        aliases | alias)
            show_alias_help
            ;;
        scripts | script)
            show_scripts_help
            ;;
        variables | vars | var | env)
            show_variables_help
            ;;
        config | configuration | conf)
            show_config_help
            ;;
        sql)
            show_sql_help
            ;;
        online | docs | web)
            show_online_help
            ;;
        -h | --help | help)
            show_main_help
            ;;
        *)
            echo "Unknown topic: $topic"
            echo ""
            echo "Available topics: aliases, scripts, variables, config, sql, online"
            echo "Use 'oradba help' for the main help menu."
            exit 1
            ;;
    esac
}

main "$@"
