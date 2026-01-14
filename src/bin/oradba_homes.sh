#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_homes.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Manage Oracle Homes configuration for non-database products
# Notes......: Provides commands to add, remove, list, and discover Oracle Homes
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_PREFIX="$(dirname "$SCRIPT_DIR")"

# Set ORADBA_BASE for configuration
export ORADBA_BASE="${ORADBA_BASE:-${ORADBA_PREFIX}}"

# Source common library
if [[ -f "${ORADBA_PREFIX}/lib/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "${ORADBA_PREFIX}/lib/common.sh"
else
    echo "ERROR: Cannot find common library at ${ORADBA_PREFIX}/lib/common.sh" >&2
    exit 1
fi

# Script name for logging
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# ------------------------------------------------------------------------------
# Function: show_usage
# Purpose.: Display usage information
# ------------------------------------------------------------------------------
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME <command> [options]

Manage Oracle Homes configuration for non-database Oracle products.

COMMANDS:
    list                List all registered Oracle Homes
    show <name>         Show detailed information about an Oracle Home
    add                 Add a new Oracle Home (interactive or with options)
    remove <name>       Remove an Oracle Home from configuration
    discover            Auto-discover Oracle Homes under ORACLE_BASE
    validate [name]     Validate Oracle Home(s) configuration
    export              Export configuration to stdout
    import [file]       Import configuration from file or stdin

LIST OPTIONS:
    -t, --type <type>   Filter by product type (oud, client, weblogic, etc.)
    -v, --verbose       Show detailed information

ADD OPTIONS:
    -n, --name <name>       Oracle Home name (required)
    -p, --path <path>       ORACLE_HOME path (required)
    -t, --type <type>       Product type (auto-detected if not specified)
    -a, --alias <name>      Alias name for shortcuts (default: same as name)
    -o, --order <num>       Display order (default: 50)
    -d, --desc <text>       Description
    -v, --version <ver>     Oracle version (AUTO, XXYZ, or ERR; default: AUTO)

DISCOVER OPTIONS:
    -b, --base <path>       Base directory to search (default: $ORACLE_BASE)
    --auto-add              Automatically add discovered homes
    --dry-run               Show what would be discovered without adding

IMPORT OPTIONS:
    --force                 Force import without confirmation
    --no-backup             Skip backup of existing configuration

GLOBAL OPTIONS:
    -h, --help              Show this help message
    -q, --quiet             Minimal output
    --verbose               Detailed output

PRODUCT TYPES:
    database        Oracle Database
    oud             Oracle Unified Directory
    client          Oracle Client
    weblogic        WebLogic Server
    oms             Enterprise Manager OMS
    emagent         Enterprise Manager Agent
    datasafe        Oracle Data Safe

EXAMPLES:
    # List all Oracle Homes
    $SCRIPT_NAME list

    # List Oracle Homes by type
    $SCRIPT_NAME list --type oud

    # Add Oracle Home manually
    $SCRIPT_NAME add --name OUD12 --path /u01/app/oracle/oud12 --type oud

    # Add with custom alias name
    $SCRIPT_NAME add --name OUD12C --path /u01/app/oracle/oud12 --alias oud12

    # Add with auto-detection
    $SCRIPT_NAME add --name WLS14 --path /u01/app/oracle/wls14

    # Discover Oracle Homes
    $SCRIPT_NAME discover

    # Discover and auto-add
    $SCRIPT_NAME discover --auto-add

    # Show details of an Oracle Home
    $SCRIPT_NAME show OUD12

    # Remove an Oracle Home
    $SCRIPT_NAME remove OUD12

    # Validate configuration
    $SCRIPT_NAME validate

    # Export configuration (for backup)
    $SCRIPT_NAME export > oradba_homes_backup.conf

    # Import configuration from file
    $SCRIPT_NAME import oradba_homes_backup.conf

    # Import from stdin
    cat oradba_homes_backup.conf | $SCRIPT_NAME import

CONFIGURATION:
    Oracle Homes are stored in: \${ORADBA_BASE}/etc/oradba_homes.conf
    Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER[:ALIAS_NAME][:DESCRIPTION][:VERSION]

EOF
}

# ------------------------------------------------------------------------------
# Function: list_homes
# Purpose.: List registered Oracle Homes
# ------------------------------------------------------------------------------
list_homes() {
    local filter_type=""
    local verbose=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t | --type)
                filter_type="$2"
                shift 2
                ;;
            -v | --verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Check if config file exists
    if ! get_oracle_homes_path > /dev/null 2>&1; then
        log_warn "No Oracle Homes configuration found"
        echo "To add Oracle Homes, use: $SCRIPT_NAME add"
        return 0
    fi

    # Get homes list
    local homes_output
    if [[ -n "$filter_type" ]]; then
        homes_output=$(list_oracle_homes "$filter_type")
    else
        homes_output=$(list_oracle_homes)
    fi

    if [[ -z "$homes_output" ]]; then
        echo "No Oracle Homes registered."
        echo "To add Oracle Homes, use: $SCRIPT_NAME add"
        return 0
    fi

    # Display header
    echo ""
    echo "Registered Oracle Homes"
    echo "================================================================================"

    if [[ "$verbose" == "true" ]]; then
        printf "%-15s %-12s %-12s %-5s %s\n" "NAME" "TYPE" "STATUS" "ORDER" "PATH"
        echo "--------------------------------------------------------------------------------"
    else
        printf "%-15s %-12s %-12s %s\n" "NAME" "TYPE" "STATUS" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
    fi

    # Display homes
    while read -r line; do
        # Parse: NAME ORACLE_HOME PRODUCT_TYPE ORDER ALIAS_NAME DESCRIPTION VERSION
        read -r name path ptype order alias_name desc version <<< "$line"

        # Check status
        local status
        if [[ -d "$path" ]]; then
            status="available"
        else
            status="missing"
        fi

        if [[ "$verbose" == "true" ]]; then
            printf "%-15s %-12s %-12s %-5s %s\n" "$name" "$ptype" "$status" "$order" "$path"
        else
            # Show alias name if different from name
            local display_desc="$desc"
            if [[ "$alias_name" != "$name" ]]; then
                display_desc="[alias: $alias_name] $desc"
            fi
            printf "%-15s %-12s %-12s %s\n" "$name" "$ptype" "$status" "$display_desc"
        fi
    done <<< "$homes_output"

    echo ""
}

# ------------------------------------------------------------------------------
# Function: show_home
# Purpose.: Show detailed information about an Oracle Home
# ------------------------------------------------------------------------------
show_home() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "Oracle Home name required"
        echo "Usage: $SCRIPT_NAME show <name>"
        return 1
    fi

    # Parse home entry
    local home_info
    if ! home_info=$(parse_oracle_home "$name"); then
        log_error "Oracle Home '$name' not found"
        return 1
    fi

    # Extract details
    read -r h_name h_path h_type h_order h_alias h_desc h_version <<< "$home_info"

    # Get additional info
    local status="missing"
    local detected_type="unknown"
    local detected_version="Unknown"

    if [[ -d "$h_path" ]]; then
        status="available"
        detected_type=$(detect_product_type "$h_path")
        # Get actual version if AUTO
        if [[ "${h_version}" == "AUTO" ]]; then
            detected_version=$(detect_oracle_version "$h_path" "$detected_type")
        else
            detected_version="${h_version}"
        fi
    fi

    # Display information
    echo ""
    echo "Oracle Home Details: $name"
    echo "================================================================================"
    echo "Name              : $h_name"
    echo "Alias Name        : $h_alias"
    echo "ORACLE_HOME       : $h_path"
    echo "Product Type      : $h_type"
    echo "Detected Type     : $detected_type"
    echo "Version (config)  : ${h_version:-AUTO}"
    echo "Version (detected): $detected_version"
    echo "Display Order     : $h_order"
    echo "Status            : $status"
    echo "Description       : $h_desc"
    echo ""

    # Show directory contents if available
    if [[ -d "$h_path" ]]; then
        echo "Directory Contents:"
        echo "--------------------------------------------------------------------------------"
        find "$h_path" -maxdepth 1 -ls 2> /dev/null | head -10
        echo ""
    else
        echo "⚠ Warning: Oracle Home directory does not exist"
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# Function: add_home
# Purpose.: Add a new Oracle Home
# ------------------------------------------------------------------------------
add_home() {
    local name=""
    local path=""
    local ptype=""
    local order="50"
    local alias_name=""
    local desc=""
    local version="AUTO"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --name)
                name="$2"
                shift 2
                ;;
            -p | --path)
                path="$2"
                shift 2
                ;;
            -t | --type)
                ptype="$2"
                shift 2
                ;;
            -a | --alias)
                alias_name="$2"
                shift 2
                ;;
            -o | --order)
                order="$2"
                shift 2
                ;;
            -d | --desc)
                desc="$2"
                shift 2
                ;;
            -v | --version)
                version="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Interactive mode if no options provided and we have a TTY
    if [[ -z "$name" ]]; then
        if [[ -t 0 ]]; then
            read -p "Oracle Home name: " name
        else
            log_error "Oracle Home name is required (--name)"
            return 1
        fi
    fi

    if [[ -z "$name" ]]; then
        log_error "Oracle Home name is required"
        return 1
    fi

    # Validate name format
    if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
        log_error "Invalid name. Use only letters, numbers, and underscores."
        return 1
    fi

    # Check if already exists
    if is_oracle_home "$name" 2> /dev/null; then
        log_error "Oracle Home '$name' already exists"
        return 1
    fi

    if [[ -z "$path" ]]; then
        if [[ -t 0 ]]; then
            read -p "ORACLE_HOME path: " path
        else
            log_error "ORACLE_HOME path is required (--path)"
            return 1
        fi
    fi

    if [[ -z "$path" ]]; then
        log_error "ORACLE_HOME path is required"
        return 1
    fi

    # Validate path exists
    if [[ ! -d "$path" ]]; then
        if [[ -t 0 ]]; then
            log_warn "Directory does not exist: $path"
            read -p "Continue anyway? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "Cancelled."
                return 0
            fi
        else
            log_warn "Directory does not exist: $path (continuing in non-interactive mode)"
        fi
    fi

    # Auto-detect product type if not specified
    if [[ -z "$ptype" ]]; then
        if [[ -d "$path" ]]; then
            ptype=$(detect_product_type "$path")
            log_info "Auto-detected product type: $ptype"
        elif [[ -t 0 ]]; then
            read -p "Product type (database/oud/client/weblogic/oms/emagent/datasafe): " ptype
        else
            log_error "Product type is required when path doesn't exist (--type)"
            return 1
        fi
    fi

    # Validate product type
    case "$ptype" in
        database | oud | client | weblogic | oms | emagent | datasafe) ;;
        *)
            log_error "Invalid product type: $ptype"
            return 1
            ;;
    esac

    if [[ -z "$desc" ]]; then
        if [[ -t 0 ]]; then
            read -p "Description (optional): " desc
        fi
        # Always set default if still empty
        if [[ -z "$desc" ]]; then
            desc="$ptype Oracle Home"
        fi
    fi

    # Set alias_name default if not provided
    if [[ -z "$alias_name" ]]; then
        if [[ -t 0 ]]; then
            # Suggest lowercase name as default (consistent with SID aliases)
            local default_alias="${name,,}"
            read -p "Alias name (default: $default_alias): " alias_name
        fi
        # Use lowercase home name as default alias (consistent with SID aliases)
        if [[ -z "$alias_name" ]]; then
            alias_name="${name,,}"
        fi
    fi

    # Get config file path
    local config_file="${ORADBA_BASE}/etc/oradba_homes.conf"

    # Create directory if needed
    mkdir -p "${ORADBA_BASE}/etc"

    # Create config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
# ------------------------------------------------------------------------------
# Oracle Homes Configuration
# ------------------------------------------------------------------------------
# Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER[:ALIAS_NAME][:DESCRIPTION][:VERSION]
#
# NAME          - Unique identifier (auto-discovered or user-defined)
# ORACLE_HOME   - Full path to Oracle Home directory
# PRODUCT_TYPE  - database, oud, client, weblogic, oms, emagent, datasafe
# ORDER         - Display order (numeric, lower = displayed first)
# ALIAS_NAME    - Optional alias for shortcuts (defaults to NAME)
# DESCRIPTION   - Human-readable description
# VERSION       - Oracle version (AUTO, XXYZ, or ERR; default: AUTO)
#
# Examples:
# OUD12:/u01/app/oracle/product/12.2.1.4/oud:oud:10:oud12:Oracle Unified Directory 12c:ERR
# CLIENT19:/u01/app/oracle/product/19.0.0.0/client:client:20:client:Oracle Client 19c:AUTO
# CLIENT23:/appl/oracle/product/23.26.0.0/client:client:25:cli260:Oracle Client 23ai:AUTO
# WLS14:/u01/app/oracle/product/14.1.1.0/wls:weblogic:30:wls:WebLogic Server 14c:ERR
# ------------------------------------------------------------------------------

EOF
    fi

    # Add entry with alias_name and version
    echo "${name}:${path}:${ptype}:${order}:${alias_name}:${desc}:${version}" >> "$config_file"

    log_info "Oracle Home '$name' added successfully"
    echo ""
    echo "Configuration:"
    echo "  Name        : $name"
    echo "  Alias Name  : $alias_name"
    echo "  Path        : $path"
    echo "  Type        : $ptype"
    echo "  Order       : $order"
    echo "  Description : $desc"
    echo "  Version     : $version"
    echo ""
    echo "To set environment: source oraenv.sh $name"
    echo ""

    # Regenerate SID lists and aliases in current shell
    if command -v generate_sid_lists &>/dev/null && command -v generate_oracle_home_aliases &>/dev/null; then
        generate_sid_lists "${ORATAB_FILE:-/etc/oratab}" 2>/dev/null
        generate_oracle_home_aliases 2>/dev/null
        log_debug "Regenerated SID lists and aliases"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: remove_home
# Purpose.: Remove an Oracle Home from configuration
# ------------------------------------------------------------------------------
remove_home() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "Oracle Home name required"
        echo "Usage: $SCRIPT_NAME remove <name>"
        return 1
    fi

    # Check if exists
    if ! is_oracle_home "$name" 2> /dev/null; then
        log_error "Oracle Home '$name' not found"
        return 1
    fi

    # Get config file
    local config_file
    if ! config_file=$(get_oracle_homes_path); then
        log_error "Oracle Homes configuration not found"
        return 1
    fi

    # Confirm removal
    echo ""
    echo "Remove Oracle Home: $name"

    if [[ -t 0 ]]; then
        read -p "Are you sure? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return 0
        fi
    else
        log_info "Non-interactive mode: skipping confirmation"
    fi

    # Create backup
    cp "$config_file" "${config_file}.bak"

    # Remove entry
    sed -i.tmp "/^${name}:/d" "$config_file"
    rm -f "${config_file}.tmp"

    log_info "Oracle Home '$name' removed successfully"
    echo ""

    # Regenerate SID lists and aliases in current shell
    if command -v generate_sid_lists &>/dev/null && command -v generate_oracle_home_aliases &>/dev/null; then
        generate_sid_lists "${ORATAB_FILE:-/etc/oratab}" 2>/dev/null
        generate_oracle_home_aliases 2>/dev/null
        log_debug "Regenerated SID lists and aliases"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: discover_homes
# Purpose.: Auto-discover Oracle Homes
# ------------------------------------------------------------------------------
discover_homes() {
    local base_dir="${ORACLE_BASE:-}"
    local auto_add=false
    local dry_run=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b | --base)
                base_dir="$2"
                shift 2
                ;;
            --auto-add)
                auto_add=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if [[ -z "$base_dir" ]]; then
        log_error "ORACLE_BASE not set. Use --base to specify search directory."
        return 1
    fi

    if [[ ! -d "$base_dir" ]]; then
        log_error "Directory does not exist: $base_dir"
        return 1
    fi

    echo ""
    echo "Discovering Oracle Homes under: $base_dir"
    echo "================================================================================"
    echo ""

    # Search for Oracle Homes under product directory
    local product_dir="${base_dir}/product"

    if [[ ! -d "$product_dir" ]]; then
        log_warn "No product directory found: $product_dir"
        return 0
    fi

    local found_count=0
    local added_count=0

    # Find directories that look like Oracle Homes
    while IFS= read -r -d '' dir; do
        # Skip if too deep or symbolic links
        [[ -L "$dir" ]] && continue

        # Detect product type
        local ptype
        ptype=$(detect_product_type "$dir")

        # Skip unknown types
        [[ "$ptype" == "unknown" ]] && continue

        ((found_count++))

        # Generate name from path
        local dir_name
        dir_name=$(basename "$dir")
        local home_name
        home_name=$(echo "$dir_name" | tr '[:lower:]' '[:upper:]' | tr '.' '_')

        # Check if already registered
        if is_oracle_home "$home_name" 2> /dev/null; then
            echo "  [EXISTS] $home_name ($ptype) - $dir"
            continue
        fi

        echo "  [FOUND]  $home_name ($ptype) - $dir"

        if [[ "$auto_add" == "true" ]] && [[ "$dry_run" == "false" ]]; then
            # Add automatically
            if add_home --name "$home_name" --path "$dir" --type "$ptype" \
                --order "$((50 + found_count * 10))" \
                --desc "Auto-discovered $ptype" > /dev/null 2>&1; then
                echo "           → Added successfully"
                ((added_count++))
            else
                echo "           → Failed to add"
            fi
        fi

    done < <(find "$product_dir" -maxdepth 2 -type d -print0 2> /dev/null)

    echo ""
    echo "Discovery Summary:"
    echo "  Found: $found_count Oracle Home(s)"

    if [[ "$auto_add" == "true" ]]; then
        echo "  Added: $added_count Oracle Home(s)"
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  (Dry run - no changes made)"
    fi

    echo ""

    if [[ $found_count -gt 0 ]] && [[ "$auto_add" == "false" ]]; then
        echo "To add discovered homes, use: $SCRIPT_NAME discover --auto-add"
        echo ""
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: validate_homes
# Purpose.: Validate Oracle Homes configuration
# ------------------------------------------------------------------------------
validate_homes() {
    local name="$1"
    local error_count=0
    local warn_count=0

    echo ""
    echo "Validating Oracle Homes Configuration"
    echo "================================================================================"
    echo ""

    # Check if config file exists
    local config_file
    if ! config_file=$(get_oracle_homes_path); then
        log_warn "No Oracle Homes configuration found"
        return 0
    fi

    # Validate specific home or all
    local homes_to_check
    if [[ -n "$name" ]]; then
        if ! is_oracle_home "$name" 2> /dev/null; then
            log_error "Oracle Home '$name' not found"
            return 1
        fi
        homes_to_check=$(parse_oracle_home "$name")
    else
        homes_to_check=$(list_oracle_homes)
    fi

    while read -r line; do
        [[ -z "$line" ]] && continue

        read -r h_name h_path h_type h_order h_alias h_desc h_version <<< "$line"

        echo "Checking: $h_name ($h_type)"

        # Check if path exists
        if [[ ! -d "$h_path" ]]; then
            echo "  ✗ ERROR: Directory does not exist: $h_path"
            ((error_count++))
        else
            echo "  ✓ Directory exists: $h_path"

            # Verify detected type matches configured type
            local detected
            detected=$(detect_product_type "$h_path")

            if [[ "$detected" != "$h_type" ]]; then
                echo "  ⚠ WARNING: Detected type ($detected) differs from configured ($h_type)"
                ((warn_count++))
            else
                echo "  ✓ Product type verified: $h_type"
            fi
        fi

        echo ""
    done <<< "$homes_to_check"

    echo "Validation Summary:"
    echo "  Errors  : $error_count"
    echo "  Warnings: $warn_count"
    echo ""

    if [[ $error_count -eq 0 ]] && [[ $warn_count -eq 0 ]]; then
        echo "✓ All Oracle Homes are valid"
        echo ""
        return 0
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: export_config
# Purpose.: Export Oracle Homes configuration
# ------------------------------------------------------------------------------
export_config() {
    # Check if config file exists
    local homes_file
    homes_file=$(get_oracle_homes_path 2>/dev/null) || {
        log_warn "No Oracle Homes configuration found"
        return 1
    }

    if [[ ! -f "$homes_file" ]]; then
        log_warn "Configuration file does not exist: $homes_file"
        return 1
    fi

    # Output export header
    cat << EOF
# ======================================================================
# Oracle Homes Configuration Export
# ======================================================================
# Exported: $(date '+%Y-%m-%d %H:%M:%S')
# OraDBA Version: 0.21.0
# Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION
# ======================================================================

EOF

    # Output the configuration
    cat "$homes_file"

    return 0
}

# ------------------------------------------------------------------------------
# Function: import_config
# Purpose.: Import Oracle Homes configuration
# ------------------------------------------------------------------------------
import_config() {
    local input_file=""
    local _force=false
    local backup=true

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                _force=true
                shift
                ;;
            --no-backup)
                backup=false
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                return 1
                ;;
            *)
                input_file="$1"
                shift
                ;;
        esac
    done

    # Determine homes file location
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"

    # Create backup if file exists and backup is enabled
    if [[ -f "$homes_file" ]] && [[ "$backup" == "true" ]]; then
        local backup_file
        backup_file="${homes_file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$homes_file" "$backup_file"
        echo "Created backup: $backup_file"
    fi

    # Read from stdin or file
    local temp_file
    temp_file=$(mktemp)

    if [[ -n "$input_file" ]] && [[ "$input_file" != "-" ]]; then
        if [[ ! -f "$input_file" ]]; then
            log_error "Input file does not exist: $input_file"
            rm -f "$temp_file"
            return 1
        fi
        cat "$input_file" > "$temp_file"
    else
        cat > "$temp_file"
    fi

    # Validate the input
    local errors=0
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # Check field count (expect at least 7 fields)
        local field_count
        field_count=$(echo "$line" | awk -F':' '{print NF}')

        if [[ $field_count -lt 3 ]]; then
            log_error "Line $line_num: Invalid format (expected NAME:HOME:TYPE:...)"
            ((errors++))
        fi
    done < "$temp_file"

    if [[ $errors -gt 0 ]]; then
        log_error "Validation failed: $errors error(s) found"
        rm -f "$temp_file"
        return 1
    fi

    # Ensure directory exists
    mkdir -p "$(dirname "$homes_file")"

    # Import the configuration
    cp "$temp_file" "$homes_file"
    rm -f "$temp_file"

    echo "Successfully imported Oracle Homes configuration"
    echo "Configuration file: $homes_file"

    # Show summary
    local count
    count=$(grep -v "^#" "$homes_file" | grep -v "^$" | wc -l | tr -d ' ')
    echo "Imported $count Oracle Home(s)"

    return 0
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local command="${1:-}"

    if [[ -z "$command" ]] || [[ "$command" == "-h" ]] || [[ "$command" == "--help" ]]; then
        show_usage
        exit 0
    fi

    shift

    case "$command" in
        list)
            list_homes "$@"
            ;;
        show)
            show_home "$@"
            ;;
        add)
            add_home "$@"
            ;;
        remove)
            remove_home "$@"
            ;;
        discover)
            discover_homes "$@"
            ;;
        validate)
            validate_homes "$@"
            ;;
        export)
            export_config "$@"
            ;;
        import)
            import_config "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
