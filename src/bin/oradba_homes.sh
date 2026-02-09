#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_homes.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.15
# Revision...: 1.0.0
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
if [[ -f "${ORADBA_PREFIX}/lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${ORADBA_PREFIX}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find common library at ${ORADBA_PREFIX}/lib/oradba_common.sh" >&2
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
    dedupe              Remove duplicate entries from configuration
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
    iclient         Oracle Instant Client
    java            Oracle Java/JDK
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
                oradba_log ERROR "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Check if config file exists
    if ! get_oracle_homes_path > /dev/null 2>&1; then
        oradba_log WARN "No Oracle Homes configuration found"
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
    while IFS='|' read -r name path ptype order alias_name desc version; do
        # Parse pipe-delimited: NAME|ORACLE_HOME|PRODUCT_TYPE|ORDER|ALIAS_NAME|DESCRIPTION|VERSION

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
                # Only prepend alias if description exists and is not empty
                if [[ -n "$desc" ]]; then
                    display_desc="[alias: $alias_name] $desc"
                else
                    display_desc="[alias: $alias_name]"
                fi
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
        oradba_log ERROR "Oracle Home name or path required"
        echo "Usage: $SCRIPT_NAME show <name|path>"
        return 1
    fi

    # If name looks like a path, try to find it by path
    if [[ "$name" == /* ]]; then
        # Search for home by path
        local homes_file
        homes_file=$(get_oracle_homes_path) || {
            oradba_log ERROR "No Oracle Homes configuration found"
            return 1
        }

        # Find name by matching path
        local found_name=""
        while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
            [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${h_name}" ]] && continue
            
            if [[ "${h_path}" == "${name}" ]]; then
                found_name="$h_name"
                break
            fi
        done < "${homes_file}"

        if [[ -n "$found_name" ]]; then
            name="$found_name"
        else
            oradba_log ERROR "Oracle Home with path '$name' not found"
            return 1
        fi
    fi

    # Parse home entry
    local home_info
    if ! home_info=$(parse_oracle_home "$name"); then
        oradba_log ERROR "Oracle Home '$name' not found"
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
                oradba_log ERROR "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Interactive mode if no options provided and we have a TTY
    if [[ -z "$name" ]]; then
        if [[ -t 0 ]]; then
            read -p "Oracle Home name: " name
        else
            oradba_log ERROR "Oracle Home name is required (--name)"
            return 1
        fi
    fi

    if [[ -z "$name" ]]; then
        oradba_log ERROR "Oracle Home name is required"
        return 1
    fi

    # Validate name format
    if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
        oradba_log ERROR "Invalid name. Use only letters, numbers, and underscores."
        return 1
    fi

    # Check if already exists
    if is_oracle_home "$name" 2> /dev/null; then
        oradba_log ERROR "Oracle Home '$name' already exists"
        return 1
    fi

    # Check for alias conflict with existing SIDs
    if [[ -n "$alias_name" ]]; then
        # Check if any SID would create the same alias (lowercase SID = alias)
        local oratab_file="${ORATAB_FILE:-/etc/oratab}"
        if [[ -f "$oratab_file" ]]; then
            while IFS=: read -r sid _home _flag; do
                [[ "$sid" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$sid" ]] && continue
                
                # SID creates lowercase alias
                local sid_alias="${sid,,}"
                if [[ "$sid_alias" == "$alias_name" ]]; then
                    oradba_log WARN "Alias '$alias_name' conflicts with SID '$sid' (which creates alias '$sid_alias')"
                    oradba_log WARN "This may cause confusion when sourcing environments"
                    if [[ -t 0 ]]; then
                        read -p "Continue anyway? [y/N]: " confirm
                        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                            echo "Cancelled."
                            return 0
                        fi
                    fi
                    break
                fi
            done < "$oratab_file"
        fi
    fi

    if [[ -z "$path" ]]; then
        if [[ -t 0 ]]; then
            read -p "ORACLE_HOME path: " path
        else
            oradba_log ERROR "ORACLE_HOME path is required (--path)"
            return 1
        fi
    fi

    if [[ -z "$path" ]]; then
        oradba_log ERROR "ORACLE_HOME path is required"
        return 1
    fi

    # Validate path exists
    if [[ ! -d "$path" ]]; then
        if [[ -t 0 ]]; then
            oradba_log WARN "Directory does not exist: $path"
            read -p "Continue anyway? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "Cancelled."
                return 0
            fi
        else
            oradba_log WARN "Directory does not exist: $path (continuing in non-interactive mode)"
        fi
    fi

    # Auto-detect product type if not specified
    if [[ -z "$ptype" ]]; then
        if [[ -d "$path" ]]; then
            ptype=$(detect_product_type "$path")
            oradba_log INFO "Auto-detected product type: $ptype"
        elif [[ -t 0 ]]; then
            read -p "Product type (database/oud/client/iclient/java/weblogic/oms/emagent/datasafe): " ptype
        else
            oradba_log ERROR "Product type is required when path doesn't exist (--type)"
            return 1
        fi
    fi

    # Validate product type
    case "$ptype" in
        database | oud | client | iclient | java | weblogic | oms | emagent | datasafe) ;;
        *)
            oradba_log ERROR "Invalid product type: $ptype"
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

    # Check for duplicates (by NAME or PATH)
    if [[ -f "$config_file" ]]; then
        # Check if NAME already exists
        if grep -q "^${name}:" "$config_file"; then
            oradba_log ERROR "Oracle Home '$name' already exists"
            oradba_log INFO "Use '$SCRIPT_NAME remove $name' to remove it first"
            return 1
        fi
        # Check if PATH already exists
        if grep -q ":${path}:" "$config_file"; then
            local existing_name
            existing_name=$(grep ":${path}:" "$config_file" | head -1 | cut -d':' -f1)
            oradba_log ERROR "Path '$path' is already registered as '$existing_name'"
            oradba_log INFO "Use '$SCRIPT_NAME remove $existing_name' to remove it first"
            return 1
        fi
    fi

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
# PRODUCT_TYPE  - database, oud, client, iclient, java, weblogic, oms, emagent, datasafe
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

    oradba_log INFO "Oracle Home '$name' added successfully"
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
        oradba_log DEBUG "Regenerated SID lists and aliases"
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
        oradba_log ERROR "Oracle Home name required"
        echo "Usage: $SCRIPT_NAME remove <name>"
        return 1
    fi

    # Check if exists
    if ! is_oracle_home "$name" 2> /dev/null; then
        oradba_log ERROR "Oracle Home '$name' not found"
        return 1
    fi

    # Get config file
    local config_file
    if ! config_file=$(get_oracle_homes_path); then
        oradba_log ERROR "Oracle Homes configuration not found"
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
        oradba_log INFO "Non-interactive mode: skipping confirmation"
    fi

    # Create backup
    cp "$config_file" "${config_file}.bak"

    # Remove entry
    sed -i.tmp "/^${name}:/d" "$config_file"
    rm -f "${config_file}.tmp"

    oradba_log INFO "Oracle Home '$name' removed successfully"
    echo ""

    # Regenerate SID lists and aliases in current shell
    if command -v generate_sid_lists &>/dev/null && command -v generate_oracle_home_aliases &>/dev/null; then
        generate_sid_lists "${ORATAB_FILE:-/etc/oratab}" 2>/dev/null
        generate_oracle_home_aliases 2>/dev/null
        oradba_log DEBUG "Regenerated SID lists and aliases"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: generate_home_name
# Purpose.: Generate home name from directory name and product type
# Args....: $1 - Directory name (basename of path)
#           $2 - Product type (java, iclient, client, etc.)
# Returns.: 0 on success
# Output..: Normalized home name
# Notes...: Java, JRE, and instant client use lowercase conventions
# ------------------------------------------------------------------------------
generate_home_name() {
    local dir_name="$1"
    local ptype="$2"
    local home_name
    
    # Special handling for java, iclient, datasafe products - use lowercase
    case "$ptype" in
        java)
            # Normalize Java/JDK/JRE names to lowercase jdkNNN or jreNNN
            if [[ "$dir_name" =~ ^[Jj][Dd][Kk][-_]?([0-9]+) ]]; then
                # JDK with version number: jdk17, jdk-17, JDK_17 -> jdk17
                home_name="jdk${BASH_REMATCH[1]}"
            elif [[ "$dir_name" =~ ^[Jj][Rr][Ee][-_]?([0-9]+) ]]; then
                # JRE with version number: jre8, jre-8, JRE_8 -> jre8
                home_name="jre${BASH_REMATCH[1]}"
            elif [[ "$dir_name" =~ ^[Jj]ava[-_]?([0-9]+) ]]; then
                # Java with version number: java17 -> jdk17
                home_name="jdk${BASH_REMATCH[1]}"
            else
                # No version number, use lowercase of original
                home_name=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]' | tr '.' '_' | tr '-' '_')
            fi
            ;;
        iclient)
            # Normalize instant client names to lowercase iclientNNN
            if [[ "$dir_name" =~ instantclient[-_]?([0-9]+) ]]; then
                # instantclient_19_8 -> iclient19
                local version="${BASH_REMATCH[1]}"
                # Extract major version only (first digits)
                version="${version%%[_.-]*}"
                home_name="iclient${version}"
            else
                # Use lowercase of original
                home_name=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]' | tr '.' '_' | tr '-' '_')
            fi
            ;;
        datasafe)
            # Sequential naming for DataSafe: dscon1, dscon2, etc.
            local config_file
            config_file=$(get_oracle_homes_path 2>/dev/null) || config_file=""
            local counter=1
            
            # Find next available dsconN number
            if [[ -f "$config_file" ]]; then
                while grep -q "^dscon${counter}:" "$config_file" 2>/dev/null; do
                    ((counter++))
                done
            fi
            
            home_name="dscon${counter}"
            ;;
        *)
            # Other products: use uppercase (backward compatible)
            home_name=$(echo "$dir_name" | tr '[:lower:]' '[:upper:]' | tr '.' '_' | tr '-' '_')
            ;;
    esac
    
    echo "$home_name"
    return 0
}

# ------------------------------------------------------------------------------
# Function: discover_homes
# Purpose.: Auto-discover Oracle Homes
# Notes...: Wrapper around auto_discover_oracle_homes() in oradba_common.sh
#           Supports legacy options for backward compatibility
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
                oradba_log ERROR "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if [[ -z "$base_dir" ]]; then
        oradba_log ERROR "ORACLE_BASE not set. Use --base to specify search directory."
        return 1
    fi

    if [[ ! -d "$base_dir" ]]; then
        oradba_log ERROR "Directory does not exist: $base_dir"
        return 1
    fi

    # Dry-run mode: just show what would be discovered without adding
    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "DRY RUN - No changes will be made"
        echo ""
    fi
    
    # If auto-add is enabled, just call the common function
    if [[ "$auto_add" == "true" ]] && [[ "$dry_run" == "false" ]]; then
        # Use common auto_discover_oracle_homes() function
        auto_discover_oracle_homes "${base_dir}/product"
        return $?
    fi
    
    # Otherwise, do a dry-run style discovery (show what would be added)
    echo ""
    echo "Discovering Oracle Homes under: $base_dir"
    echo "================================================================================"
    echo ""

    # Search for Oracle Homes under product directory
    local product_dir="${base_dir}/product"

    if [[ ! -d "$product_dir" ]]; then
        oradba_log WARN "No product directory found: $product_dir"
        return 0
    fi

    local found_count=0
    local -a validated_homes=()  # Track validated Oracle Homes to avoid subdirectory detection

    # Find directories that look like Oracle Homes
    while IFS= read -r -d '' dir; do
        # Skip if too deep or symbolic links
        [[ -L "$dir" ]] && continue
        
        # Skip if this is a subdirectory of an already-validated Oracle Home
        if type -t is_subdirectory_of_oracle_home >/dev/null 2>&1; then
            if is_subdirectory_of_oracle_home "$dir" "${validated_homes[@]}"; then
                continue
            fi
        fi
        
        # Skip common bundled components
        local dir_name
        dir_name=$(basename "$dir")
        if type -t is_bundled_component >/dev/null 2>&1; then
            if is_bundled_component "$dir_name"; then
                continue
            fi
        fi

        # Detect product type
        local ptype
        ptype=$(detect_product_type "$dir")

        # Skip unknown types
        [[ "$ptype" == "unknown" ]] && continue
        
        # Validate using plugin system before counting as found
        local plugin_file="${ORADBA_PREFIX}/lib/plugins/${ptype}_plugin.sh"
        local is_valid_home=false
        
        if [[ -f "$plugin_file" ]]; then
            # Source plugin and validate
            # shellcheck source=/dev/null
            source "$plugin_file" 2>/dev/null || true
            
            if declare -f plugin_validate_home >/dev/null 2>&1; then
                if plugin_validate_home "$dir" 2>/dev/null; then
                    is_valid_home=true
                    # Add to validated homes list to exclude its subdirectories
                    validated_homes+=("$dir")
                else
                    continue  # Validation failed
                fi
            else
                # No validation function - accept based on detect_product_type
                is_valid_home=true
                validated_homes+=("$dir")
            fi
        else
            # No plugin - accept based on detect_product_type (backward compatible)
            is_valid_home=true
            validated_homes+=("$dir")
        fi
        
        [[ "$is_valid_home" == "false" ]] && continue

        ((found_count++))

        # Generate name from path and product type
        local home_name
        home_name=$(generate_home_name "$dir_name" "$ptype")

        # Check if already registered
        if is_oracle_home "$home_name" 2> /dev/null; then
            echo "  [EXISTS] $home_name ($ptype) - $dir"
            continue
        fi
        
        # Check if path already exists (different name)
        local config_file
        config_file=$(get_oracle_homes_path 2>/dev/null) || config_file=""
        if [[ -f "$config_file" ]] && grep -q ":${dir}:" "$config_file"; then
            local existing_name
            existing_name=$(grep ":${dir}:" "$config_file" | head -1 | cut -d':' -f1)
            echo "  [EXISTS] $home_name ($ptype) - path registered as '$existing_name'"
            continue
        fi

        echo "  [FOUND]  $home_name ($ptype) - $dir"

    done < <(find "$product_dir" -maxdepth 3 -type d -print0 2> /dev/null)

    echo ""
    echo "Discovery Summary:"
    echo "  Found: $found_count Oracle Home(s)"

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
        oradba_log WARN "No Oracle Homes configuration found"
        return 0
    fi

    # Validate specific home or all
    local homes_to_check
    local field_sep=" "  # Default for parse_oracle_home
    if [[ -n "$name" ]]; then
        if ! is_oracle_home "$name" 2> /dev/null; then
            oradba_log ERROR "Oracle Home '$name' not found"
            return 1
        fi
        homes_to_check=$(parse_oracle_home "$name")
        field_sep=" "  # parse_oracle_home uses space separator
    else
        homes_to_check=$(list_oracle_homes)
        field_sep="|"  # list_oracle_homes uses pipe separator
    fi

    while read -r line; do
        [[ -z "$line" ]] && continue

        IFS="${field_sep}" read -r h_name h_path h_type h_order h_alias h_desc h_version <<< "$line"

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
        oradba_log WARN "No Oracle Homes configuration found"
        return 1
    }

    if [[ ! -f "$homes_file" ]]; then
        oradba_log WARN "Configuration file does not exist: $homes_file"
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
                oradba_log ERROR "Unknown option: $1"
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
            oradba_log ERROR "Input file does not exist: $input_file"
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
    local valid_lines=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip comments and empty lines
        if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
            continue
        fi

        ((valid_lines++))

        # Check field count (expect at least 3 fields: NAME:HOME:TYPE)
        local field_count
        field_count=$(echo "$line" | awk -F':' '{print NF}')

        if [[ $field_count -lt 3 ]]; then
            oradba_log ERROR "Line $line_num: Invalid format (expected NAME:HOME:TYPE:ORDER[:ALIAS][:DESC][:VERSION])"
            ((errors++))
            continue
        fi

        # Validate field values
        local h_name h_path h_type
        IFS=: read -r h_name h_path h_type _ <<< "$line"

        # Check name is not empty and alphanumeric
        if [[ -z "$h_name" ]] || [[ ! "$h_name" =~ ^[A-Za-z0-9_]+$ ]]; then
            oradba_log ERROR "Line $line_num: Invalid NAME '$h_name' (use only letters, numbers, underscores)"
            ((errors++))
        fi

        # Check path is absolute
        if [[ ! "$h_path" == /* ]]; then
            oradba_log ERROR "Line $line_num: Invalid path '$h_path' (must be absolute path)"
            ((errors++))
        fi

        # Check type is valid
        case "$h_type" in
            database|oud|client|iclient|java|weblogic|oms|emagent|datasafe) ;;
            *)
                oradba_log ERROR "Line $line_num: Invalid product type '$h_type'"
                ((errors++))
                ;;
        esac
    done < "$temp_file"

    # Check if we have any valid entries
    if [[ $valid_lines -eq 0 ]]; then
        oradba_log ERROR "No valid Oracle Home entries found in import file"
        rm -f "$temp_file"
        return 1
    fi

    if [[ $errors -gt 0 ]]; then
        oradba_log ERROR "Validation failed: $errors error(s) found in $line_num lines"
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
    count=$(grep -v -c "^#\|^$" "$homes_file" 2>/dev/null || echo "0")
    echo "Imported $count Oracle Home(s)"

    return 0
}

# ------------------------------------------------------------------------------
# Function: dedupe_homes
# Purpose.: Remove duplicate entries from configuration
# ------------------------------------------------------------------------------
dedupe_homes() {
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    # Check if config file exists
    if [[ ! -f "$homes_file" ]]; then
        oradba_log WARN "No Oracle Homes configuration found"
        return 0
    fi
    
    echo ""
    echo "Removing Duplicate Entries"
    echo "================================================================================"
    echo ""
    
    # Create temp file
    local temp_file="${homes_file}.dedup.$$"
    local seen_names=()
    local seen_paths=()
    local removed_count=0
    local kept_count=0
    
    # Copy header/comments
    grep -E '^#|^$' "$homes_file" > "$temp_file"
    
    # Process entries
    while IFS=':' read -r name path ptype order alias_name desc version; do
        # Skip comments and empty lines
        [[ -z "$name" ]] && continue
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        name=$(echo "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        path=$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Check for duplicate NAME
        local name_seen=false
        for seen in "${seen_names[@]}"; do
            if [[ "$seen" == "$name" ]]; then
                name_seen=true
                break
            fi
        done
        
        # Check for duplicate PATH
        local path_seen=false
        for seen in "${seen_paths[@]}"; do
            if [[ "$seen" == "$path" ]]; then
                path_seen=true
                break
            fi
        done
        
        if [[ "$name_seen" == "true" ]]; then
            echo "  Removed duplicate NAME: $name"
            ((removed_count++))
        elif [[ "$path_seen" == "true" ]]; then
            echo "  Removed duplicate PATH: $path (name: $name)"
            ((removed_count++))
        else
            # Keep this entry
            echo "${name}:${path}:${ptype}:${order}:${alias_name}:${desc}:${version}" >> "$temp_file"
            seen_names+=("$name")
            seen_paths+=("$path")
            ((kept_count++))
        fi
    done < "$homes_file"
    
    echo ""
    if [[ $removed_count -gt 0 ]]; then
        # Create backup
        cp "$homes_file" "${homes_file}.backup.$(date +%Y%m%d_%H%M%S)"
        # Replace with deduplicated version
        mv "$temp_file" "$homes_file"
        echo "✓ Removed $removed_count duplicate(s), kept $kept_count entry/entries"
        echo "  Backup created: ${homes_file}.backup.*"
    else
        rm -f "$temp_file"
        echo "✓ No duplicates found ($kept_count entry/entries)"
    fi
    echo ""
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Main entry point for Oracle Homes management
# Args....: $1 - Command (list|show|add|remove|discover|validate|dedupe|export|import)
#           $@ - Command-specific options and arguments
# Returns.: 0 on success, 1 on error
# Output..: Command output to stdout, errors to stderr
# Notes...: Dispatches to appropriate command handler function
#           Shows usage if no command or -h/--help provided
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
        dedupe)
            dedupe_homes "$@"
            ;;
        export)
            export_config "$@"
            ;;
        import)
            import_config "$@"
            ;;
        *)
            oradba_log ERROR "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function only when script is executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
