#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: generate_api_docs.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.21
# Revision...: 0.19.1
# Purpose....: Generate API reference documentation from function headers
# Notes......: Extracts function headers from source files and generates
#              organized markdown documentation with categories and index.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e
set -o pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_LIB_DIR="${PROJECT_ROOT}/src/lib"
SRC_BIN_DIR="${PROJECT_ROOT}/src/bin"
OUTPUT_DIR="${PROJECT_ROOT}/src/doc/api"
TEMP_DIR="/tmp/oradba_api_docs_$$"

# Category mappings
declare -A CATEGORY_MAP=(
    ["oradba_common.sh"]="common"
    ["oradba_db_functions.sh"]="database"
    ["oradba_registry.sh"]="registry"
    ["oradba_aliases.sh"]="aliases"
    ["oradba_env_builder.sh"]="environment"
    ["oradba_env_changes.sh"]="environment"
    ["oradba_env_config.sh"]="environment"
    ["oradba_env_parser.sh"]="environment"
    ["oradba_env_status.sh"]="environment"
    ["oradba_env_validator.sh"]="environment"
    ["extensions.sh"]="extensions"
    ["*_plugin.sh"]="plugins"
    ["plugin_interface.sh"]="plugins"
    ["oradba_*.sh"]="scripts"
    ["*.sh"]="scripts"
)

declare -A CATEGORY_TITLES=(
    ["common"]="Core Utilities"
    ["database"]="Database Operations"
    ["registry"]="Registry API"
    ["aliases"]="Alias Management"
    ["environment"]="Environment Management"
    ["extensions"]="Extension System"
    ["plugins"]="Plugin Interface"
    ["scripts"]="Scripts and Commands"
)

declare -A CATEGORY_DESCRIPTIONS=(
    ["common"]="Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities."
    ["database"]="Database-specific operations including query execution, status checks, and database management."
    ["registry"]="Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf."
    ["aliases"]="Alias generation and management for database environments."
    ["environment"]="Environment management libraries for building, parsing, validating, and tracking Oracle environments."
    ["extensions"]="Extension system for loading and managing OraDBA extensions."
    ["plugins"]="Plugin interface for product-specific functionality (database, client, datasafe, java, etc.)."
    ["scripts"]="Command-line scripts and tools for OraDBA operations."
)

# ------------------------------------------------------------------------------
# Function: cleanup
# Purpose.: Clean up temporary files on exit
# Args....: None
# Returns.: 0 on success
# Output..: None
# ------------------------------------------------------------------------------
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Function: get_category
# Purpose.: Determine category for a source file
# Args....: $1 - File path
# Returns.: 0 on success
# Output..: Category name
# ------------------------------------------------------------------------------
get_category() {
    local file_path="$1"
    local basename_file
    basename_file="$(basename "$file_path")"
    
    # Check specific file mappings first
    if [[ -n "${CATEGORY_MAP[$basename_file]:-}" ]]; then
        echo "${CATEGORY_MAP[$basename_file]}"
        return 0
    fi
    
    # Check pattern mappings
    if [[ "$basename_file" == *_plugin.sh ]]; then
        echo "plugins"
    elif [[ "$basename_file" == oradba_*.sh ]]; then
        echo "scripts"
    else
        echo "scripts"
    fi
}

# ------------------------------------------------------------------------------
# Function: extract_function_header
# Purpose.: Extract a complete function header from a file
# Args....: $1 - File path
#           $2 - Function name
# Returns.: 0 on success
# Output..: Function header in structured format
# ------------------------------------------------------------------------------
extract_function_header() {
    local file_path="$1"
    local function_name="$2"
    
    # Find the function header (look for "# Function: name")
    awk -v fname="$function_name" '
    /^# Function:/ {
        if ($0 ~ fname) {
            found = 1
            function_line = $0
            sub(/^# Function: /, "", function_line)
            next
        }
    }
    found && /^# Purpose\.:/ {
        purpose = $0
        sub(/^# Purpose\.: /, "", purpose)
        next
    }
    found && /^# Args\.\.\.\./ {
        if (args != "") args = args "\n"
        args = args $0
        sub(/^# Args\.\.\.\.: /, "", args)
        next
    }
    found && /^# Returns\./ {
        returns = $0
        sub(/^# Returns\.: /, "", returns)
        next
    }
    found && /^# Output\.\./ {
        output = $0
        sub(/^# Output\.\.: /, "", output)
        next
    }
    found && /^# Notes\.\.\./ {
        notes = $0
        sub(/^# Notes\.\.\.: /, "", notes)
        next
    }
    found && /^# -+/ && !separator_seen {
        separator_seen = 1
        next
    }
    found && separator_seen && /^[a-zA-Z_][a-zA-Z0-9_]*\(\)/ {
        # Found function declaration
        print "FUNCTION:" function_line
        print "PURPOSE:" purpose
        print "ARGS:" args
        print "RETURNS:" returns
        print "OUTPUT:" output
        if (notes != "") print "NOTES:" notes
        exit
    }
    ' "$file_path"
}

# ------------------------------------------------------------------------------
# Function: scan_file_for_functions
# Purpose.: Scan a file and extract all function headers
# Args....: $1 - File path
# Returns.: 0 on success
# Output..: Function headers in structured format
# ------------------------------------------------------------------------------
scan_file_for_functions() {
    local file_path="$1"
    local category
    category="$(get_category "$file_path")"
    
    # Extract all function names from the file
    grep "^# Function:" "$file_path" | sed 's/^# Function: //' | while read -r function_name; do
        echo "FILE:$file_path"
        echo "CATEGORY:$category"
        extract_function_header "$file_path" "$function_name"
        echo "---"
    done
}

# ------------------------------------------------------------------------------
# Function: generate_markdown_function
# Purpose.: Generate markdown documentation for a single function
# Args....: $1 - Function data (from scan_file_for_functions)
# Returns.: 0 on success
# Output..: Markdown formatted function documentation
# ------------------------------------------------------------------------------
generate_markdown_function() {
    local function_name=""
    local purpose=""
    local args=""
    local returns=""
    local output=""
    local notes=""
    local file_path=""
    
    # Parse the function data
    while IFS=: read -r key value; do
        case "$key" in
            FUNCTION) function_name="$value" ;;
            PURPOSE) purpose="$value" ;;
            ARGS) 
                if [[ -z "$args" ]]; then
                    args="$value"
                else
                    args="$args"$'\n'"$value"
                fi
                ;;
            RETURNS) returns="$value" ;;
            OUTPUT) output="$value" ;;
            NOTES) notes="$value" ;;
            FILE) file_path="$value" ;;
        esac
    done
    
    # Generate markdown
    echo "### \`${function_name}\`"
    echo ""
    
    if [[ -n "$purpose" ]]; then
        echo "$purpose"
        echo ""
    fi
    
    if [[ -n "$file_path" ]]; then
        local basename_file
        basename_file="$(basename "$file_path")"
        echo "**Source:** \`${basename_file}\`"
        echo ""
    fi
    
    if [[ -n "$args" ]]; then
        echo "**Arguments:**"
        echo ""
        # Process args line by line
        echo "$args" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                echo "- $line"
            fi
        done
        echo ""
    fi
    
    if [[ -n "$returns" ]]; then
        echo "**Returns:** $returns"
        echo ""
    fi
    
    if [[ -n "$output" ]]; then
        echo "**Output:** $output"
        echo ""
    fi
    
    if [[ -n "$notes" ]]; then
        echo "!!! info \"Notes\""
        echo "    $notes"
        echo ""
    fi
    
    echo "---"
    echo ""
}

# ------------------------------------------------------------------------------
# Function: create_output_directory
# Purpose.: Create output directory structure
# Args....: None
# Returns.: 0 on success
# Output..: Creates directories
# ------------------------------------------------------------------------------
create_output_directory() {
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEMP_DIR"
    echo "[INFO] Created output directory: $OUTPUT_DIR"
}

# ------------------------------------------------------------------------------
# Function: scan_all_files
# Purpose.: Scan all source files and extract function headers
# Args....: None
# Returns.: 0 on success
# Output..: Creates temporary files with function data
# ------------------------------------------------------------------------------
scan_all_files() {
    echo "[INFO] Scanning source files for functions..."
    
    local total_functions=0
    
    # Scan lib files
    for file in "$SRC_LIB_DIR"/*.sh "$SRC_LIB_DIR"/plugins/*.sh; do
        if [[ -f "$file" ]]; then
            local count
            count=$(grep -c "^# Function:" "$file" 2>/dev/null || echo "0")
            if [[ "$count" -gt 0 ]]; then
                echo "[INFO]   $(basename "$file"): $count functions"
                scan_file_for_functions "$file" > "$TEMP_DIR/$(basename "$file").data"
                ((total_functions += count))
            fi
        fi
    done
    
    # Scan bin files
    for file in "$SRC_BIN_DIR"/*.sh; do
        if [[ -f "$file" ]]; then
            local count
            count=$(grep -c "^# Function:" "$file" 2>/dev/null || echo "0")
            if [[ "$count" -gt 0 ]]; then
                echo "[INFO]   $(basename "$file"): $count functions"
                scan_file_for_functions "$file" > "$TEMP_DIR/$(basename "$file").data"
                ((total_functions += count))
            fi
        fi
    done
    
    echo "[INFO] Total functions found: $total_functions"
}

# ------------------------------------------------------------------------------
# Function: generate_category_page
# Purpose.: Generate markdown page for a category
# Args....: $1 - Category name
# Returns.: 0 on success
# Output..: Creates category markdown file
# ------------------------------------------------------------------------------
generate_category_page() {
    local category="$1"
    local output_file="${OUTPUT_DIR}/${category}.md"
    local title="${CATEGORY_TITLES[$category]}"
    local description="${CATEGORY_DESCRIPTIONS[$category]}"
    
    echo "[INFO] Generating category page: ${category}.md"
    
    # Create header
    cat > "$output_file" << EOF
# ${title}

${description}

---

EOF
    
    # Find all functions in this category and add them
    local function_count=0
    for data_file in "$TEMP_DIR"/*.data; do
        if [[ -f "$data_file" ]]; then
            # Split the file into individual function blocks
            awk '/^FILE:/ { if (NR > 1) print "---"; } { print }' "$data_file" | \
            awk -v cat="$category" '
                BEGIN { RS="---"; FS="\n" }
                {
                    if ($0 ~ "CATEGORY:" cat) {
                        print $0
                        print "---"
                    }
                }
            ' | while IFS= read -r block; do
                if [[ "$block" == "---" ]]; then
                    continue
                elif [[ -n "$block" ]]; then
                    generate_markdown_function <<< "$block" >> "$output_file"
                    ((function_count++)) || true
                fi
            done
        fi
    done
    
    echo "[INFO]   Added $function_count functions to ${category}.md"
}

# ------------------------------------------------------------------------------
# Function: generate_index_page
# Purpose.: Generate API reference index page
# Args....: None
# Returns.: 0 on success
# Output..: Creates index.md
# ------------------------------------------------------------------------------
generate_index_page() {
    local output_file="${OUTPUT_DIR}/index.md"
    
    echo "[INFO] Generating index page"
    
    cat > "$output_file" << 'EOF'
# API Reference

Complete function reference for OraDBA libraries and scripts.

## Overview

OraDBA provides a comprehensive set of shell functions organized into logical categories. All functions follow standardized header documentation including purpose, arguments, return codes, and output specifications.

## Categories

### [Core Utilities](common.md)

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

**Key Functions:**

- `oradba_log` - Unified logging with configurable levels
- `oradba_dedupe_path` - Remove duplicate PATH entries
- `detect_product_type` - Detect Oracle product type from filesystem
- `parse_oratab` - Parse oratab file entries
- `verify_oracle_env` - Verify Oracle environment variables

### [Registry API](registry.md)

Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.

**Key Functions:**

- `oradba_registry_get_all` - Get all installations
- `oradba_registry_get_by_name` - Get installation by name
- `oradba_registry_get_by_type` - Get installations by type
- `oradba_registry_get_status` - Check service status
- `oradba_registry_validate_entry` - Validate entry

### [Plugin Interface](plugins.md)

Plugin interface for product-specific functionality supporting database, client, datasafe, java, oud, and other Oracle products.

**Required Plugin Functions:**

- `plugin_detect_installation` - Auto-discover installations
- `plugin_validate_home` - Validate ORACLE_HOME
- `plugin_adjust_environment` - Adjust environment variables
- `plugin_check_status` - Check service status
- `plugin_get_metadata` - Extract version and edition
- `plugin_should_show_listener` - Determine if listener applies
- `plugin_discover_instances` - Find instances
- `plugin_get_instance_status` - Get instance status
- `plugin_get_instance_type` - Get instance type
- `plugin_get_pdb_status` - Get PDB status
- `plugin_get_version` - Extract version

### [Environment Management](environment.md)

Environment management libraries for building, parsing, validating, and tracking Oracle environments.

**Includes:**

- `oradba_env_parser.sh` - Configuration parsing and merging
- `oradba_env_builder.sh` - Environment variable building
- `oradba_env_validator.sh` - Environment validation
- `oradba_env_config.sh` - Configuration management
- `oradba_env_status.sh` - Status display
- `oradba_env_changes.sh` - Change detection

### [Database Operations](database.md)

Database-specific operations including query execution, status checks, and database management.

**Key Functions:**

- `execute_db_query` - Execute SQL with simplified interface
- `check_database_status` - Check if database is running
- `check_listener_status` - Check listener status
- `get_database_version` - Get Oracle database version

### [Alias Management](aliases.md)

Alias generation and management for database environments.

**Key Functions:**

- `generate_aliases_for_sid` - Generate database aliases
- `clear_aliases` - Clear OraDBA-generated aliases

### [Extension System](extensions.md)

Extension system for loading and managing OraDBA extensions.

**Key Functions:**

- `load_extension` - Load extension from directory
- `list_extensions` - List available extensions
- `extension_discover` - Discover extension directories

### [Scripts and Commands](scripts.md)

Command-line scripts and tools for OraDBA operations including environment management, service control, and system utilities.

**Includes:**

- `oradba_env.sh` - Environment switching
- `oradba_homes.sh` - Oracle Home management
- `oradba_dbctl.sh` - Database control
- `oradba_services.sh` - Service management
- `oradba_install.sh` - Installation script
- And more...

## Quick Reference

### Common Patterns

#### Check Database Status

```bash
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

status=$(check_database_status "FREE")
if [[ "$status" == "RUNNING" ]]; then
    echo "Database is up"
fi
```

#### List All Installations

```bash
source "${ORADBA_BASE}/lib/oradba_registry.sh"

oradba_registry_get_all | while IFS=: read -r name home type version auto_start desc; do
    echo "Found $type: $name at $home"
done
```

#### Execute Database Query

```bash
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

query="SELECT name FROM v\$database;"
db_name=$(execute_db_query "$query" "raw")
echo "Database: $db_name"
```

#### Load Plugin and Check Status

```bash
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"

if plugin_validate_home "$ORACLE_HOME"; then
    status=$(plugin_check_status "$ORACLE_HOME" "$ORACLE_SID")
    echo "Status: $status"
fi
```

## See Also

- [Function Index](function-index.md) - Alphabetical function list
- [Architecture Documentation](../../doc/architecture.md) - System design
- [Development Guide](../../doc/development.md) - Development workflow
- [Function Header Guide](../../doc/function-header-guide.md) - Header standards

---

**API Reference Version:** 1.0  
**Last Generated:** [AUTO_GENERATED_DATE]  
**OraDBA Version:** v0.19.1+
EOF

    # Replace placeholder with current date
    local current_date
    current_date=$(date '+%Y-%m-%d')
    sed -i "s/\[AUTO_GENERATED_DATE\]/$current_date/" "$output_file"
}

# ------------------------------------------------------------------------------
# Function: generate_function_index
# Purpose.: Generate alphabetical function index
# Args....: None
# Returns.: 0 on success
# Output..: Creates function-index.md
# ------------------------------------------------------------------------------
generate_function_index() {
    local output_file="${OUTPUT_DIR}/function-index.md"
    
    echo "[INFO] Generating function index"
    
    cat > "$output_file" << 'EOF'
# Function Index

Alphabetical index of all OraDBA functions with links to detailed documentation.

---

EOF
    
    # Collect all functions with their category
    declare -A function_to_category
    
    for data_file in "$TEMP_DIR"/*.data; do
        if [[ -f "$data_file" ]]; then
            awk '
                /^FUNCTION:/ { func = substr($0, 10) }
                /^CATEGORY:/ { cat = substr($0, 10); print func "|" cat }
            ' "$data_file"
        fi
    done | sort -u | while IFS='|' read -r func cat; do
        echo "- [\`${func}\`](${cat}.md#${func}) - ${CATEGORY_TITLES[$cat]}"
    done >> "$output_file"
    
    echo "[INFO]   Function index generated"
}

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
main() {
    echo "========================================================================"
    echo "OraDBA API Documentation Generator"
    echo "========================================================================"
    echo ""
    
    create_output_directory
    scan_all_files
    
    echo ""
    echo "[INFO] Generating category pages..."
    
    # Generate pages for each category
    for category in common registry plugins environment database aliases extensions scripts; do
        generate_category_page "$category"
    done
    
    echo ""
    generate_index_page
    generate_function_index
    
    echo ""
    echo "========================================================================"
    echo "API documentation generated successfully!"
    echo "Output directory: $OUTPUT_DIR"
    echo "========================================================================"
    echo ""
    echo "Generated files:"
    ls -lh "$OUTPUT_DIR"/*.md
    echo ""
}

# Run main function
main "$@"
