# Function Header Standards

This document defines the standard format for function headers in OraDBA. All 437+ functions
in the codebase follow these standards to ensure consistent, comprehensive documentation.

## Why Function Headers Matter

- **Self-documentation**: Functions document themselves without external tools
- **Quick reference**: Developers understand function usage at a glance
- **Maintenance**: Clear specifications prevent bugs during modifications
- **Code review**: Reviewers can verify implementation matches specification
- **Documentation extraction**: Headers can be extracted for API documentation

## Standard Format

### Complete Header Template

All functions must include this header structure:

```bash
# ------------------------------------------------------------------------------
# Function: function_name
# Purpose.: Brief description of what the function does (one line)
# Args....: $1 - Description of first argument
#           $2 - Description of second argument (optional)
#           $3 - Description of third argument (default: value)
# Returns.: 0 on success, 1 on error/validation failure, 2 on specific condition
# Output..: Description of what gets printed to stdout
# Notes...: Additional context, usage examples, or warnings (optional)
# ------------------------------------------------------------------------------
function_name() {
    local arg1="$1"
    local arg2="${2:-}"
    local arg3="${3:-default}"
    
    # Function implementation
}
```

### Field Descriptions

#### Function

- **Format**: `# Function: function_name`
- **Purpose**: The exact function name used in code
- **Rules**: Must match the actual function declaration exactly

#### Purpose

- **Format**: `# Purpose.: Brief description`
- **Purpose**: One-line summary of what the function does
- **Rules**:
  - Keep it concise (one line, under 80 characters preferred)
  - Use imperative mood ("Remove duplicates" not "Removes duplicates")
  - Focus on what, not how

**Examples**:

```bash
# Good
# Purpose.: Remove duplicate entries from PATH-like variables

# Bad (too verbose)
# Purpose.: This function takes a colon-separated path string and removes
#           any duplicate directory entries that appear multiple times

# Bad (wrong tense)
# Purpose.: Removes duplicate entries from PATH-like variables
```

#### Args

- **Format**: `# Args....: $N - Description`
- **Purpose**: Document each positional parameter
- **Rules**:
  - List all parameters in order ($1, $2, $3, ...)
  - Mark optional parameters: `$2 - Description (optional)`
  - Document defaults: `$3 - Description (default: value)`
  - Use consistent terminology across codebase

**Examples**:

```bash
# Required argument
# Args....: $1 - ORACLE_HOME path

# Optional argument
# Args....: $1 - SID to find (optional, if empty returns all)

# Argument with default
# Args....: $1 - Log level (default: INFO)

# Multiple arguments
# Args....: $1 - ORACLE_HOME path
#           $2 - Product type (optional, lowercase: database, client, etc.)
#           $3 - Validation level (default: basic)
```

**No arguments**:

```bash
# Args....: None
```

#### Returns

- **Format**: `# Returns.: Exit code and meaning`
- **Purpose**: Document function return codes
- **Rules**:
  - Always document return codes
  - Use standard conventions: 0=success, 1=error, 2+=specific conditions
  - Be explicit about all possible return values

**Examples**:

```bash
# Simple return
# Returns.: 0 on success, 1 on error

# Multiple return codes
# Returns.: 0 if running, 1 if stopped, 2 if unavailable

# Detailed returns
# Returns.: 0 on success
#           1 on validation error
#           2 on missing dependency
#           3 on timeout
```

#### Output

- **Format**: `# Output..: Description of stdout/stderr/side effects`
- **Purpose**: Document what the function produces
- **Rules**:
  - Describe stdout output (what gets printed)
  - Document side effects (files created, variables set, etc.)
  - Specify format for structured output

**Examples**:

```bash
# Simple output
# Output..: Deduplicated path string

# Structured output
# Output..: Pipe-delimited format: NAME|TYPE|ORACLE_HOME|VERSION

# Side effects
# Output..: Creates ORADBA_LOG_DIR, sets ORADBA_LOG_FILE, ORADBA_ERROR_LOG

# No output
# Output..: None (modifies PATH in place)
```

#### Notes (Optional)

- **Format**: `# Notes...: Additional context`
- **Purpose**: Document important details that don't fit elsewhere
- **Rules**:
  - Use for warnings, gotchas, version info, or examples
  - Keep concise but informative
  - Can span multiple lines

**Examples**:

```bash
# Version information
# Notes...: New in v0.13.2 - Eliminates SQL*Plus boilerplate duplication

# Warning
# Notes...: This function modifies the global PATH variable

# Usage example
# Notes...: Example: oradba_add_oracle_path "/u01/app/oracle/product/19c" "database"

# Implementation detail
# Notes...: Uses plugin_build_bin_path() from product-specific plugins
#           Falls back to basic bin directory for unknown products
```

## Complete Examples

### Example 1: Simple Utility Function

```bash
# ------------------------------------------------------------------------------
# Function: oradba_dedupe_path
# Purpose.: Remove duplicate entries from PATH-like variables
# Args....: $1 - Path string (colon-separated)
# Returns.: 0 on success
# Output..: Deduplicated path string
# ------------------------------------------------------------------------------
oradba_dedupe_path() {
    local input_path="$1"
    local -a seen_paths
    local -a result_paths
    local dir
    
    # Split on colon and process each directory
    IFS=':' read -ra dirs <<< "$input_path"
    for dir in "${dirs[@]}"; do
        [[ -z "$dir" ]] && continue
        
        # Check if we've seen this path before
        local already_seen=0
        for seen in "${seen_paths[@]}"; do
            if [[ "$dir" == "$seen" ]]; then
                already_seen=1
                break
            fi
        done
        
        # Add if not seen
        if [[ $already_seen -eq 0 ]]; then
            seen_paths+=("$dir")
            result_paths+=("$dir")
        fi
    done
    
    # Join with colons
    local IFS=":"
    echo "${result_paths[*]}"
}
```

### Example 2: Function with Multiple Arguments

```bash
# ------------------------------------------------------------------------------
# Function: oradba_add_oracle_path
# Purpose.: Add Oracle binaries to PATH using plugin system
# Args....: $1 - ORACLE_HOME path
#           $2 - Product type (optional, lowercase: database, client, iclient, etc.)
# Returns.: 0 on success, 1 on error
# Output..: Modified PATH environment variable
# Notes...: Uses plugin_build_bin_path() from product-specific plugins
#           Falls back to basic bin directory for unknown products
# ------------------------------------------------------------------------------
oradba_add_oracle_path() {
    local oracle_home="$1"
    local product_type="${2:-database}"
    
    [[ -z "${oracle_home}" ]] && return 1
    [[ ! -d "${oracle_home}" ]] && return 1
    
    # Load plugin for product type
    if ! load_plugin "${product_type}"; then
        oradba_log WARN "Unknown product type ${product_type}, using default path"
        export PATH="${oracle_home}/bin:${PATH}"
        return 0
    fi
    
    # Use plugin to build path
    local plugin_path
    plugin_path=$(plugin_build_bin_path "${oracle_home}")
    
    # Add to PATH
    export PATH="${plugin_path}:${PATH}"
    return 0
}
```

### Example 3: Function with Complex Return Codes

```bash
# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if product instance is running
# Args....: $1 - Installation path
#           $2 - Instance name (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Uses explicit environment (not current shell environment)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    
    [[ ! -d "${home_path}" ]] && echo "unavailable" && return 2
    
    # Check if process is running
    if pgrep -f "${instance_name}" > /dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}
```

### Example 4: Function with Structured Output

```bash
# ------------------------------------------------------------------------------
# Function: get_all_installations
# Purpose.: List all Oracle installations from oratab and oradba_homes.conf
# Args....: None
# Returns.: 0 on success
# Output..: Pipe-delimited format: NAME|TYPE|ORACLE_HOME|VERSION|EDITION|AUTOSTART|DESCRIPTION
# Notes...: Combines entries from both sources, databases listed first
# ------------------------------------------------------------------------------
get_all_installations() {
    local -a installations=()
    
    # Get database entries from oratab
    while IFS='|' read -r sid home flag; do
        [[ -z "${sid}" ]] && continue
        installations+=("${sid}|database|${home}|unknown|unknown|${flag}|Database instance")
    done < <(parse_oratab)
    
    # Get non-database entries from oradba_homes.conf
    while IFS=':' read -r name type home version edition desc; do
        [[ -z "${name}" ]] && continue
        installations+=("${name}|${type}|${home}|${version}|${edition}|N|${desc}")
    done < <(parse_homes_conf)
    
    # Output all installations
    printf '%s\n' "${installations[@]}"
    return 0
}
```

## Common Patterns

### Function with No Arguments

```bash
# ------------------------------------------------------------------------------
# Function: init_logging
# Purpose.: Initialize logging infrastructure and create log directories
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: Creates ORADBA_LOG_DIR, sets ORADBA_LOG_FILE, ORADBA_ERROR_LOG
# Notes...: Falls back to ${HOME}/.oradba/logs if /var/log not writable
# ------------------------------------------------------------------------------
```

### Function with Optional Arguments

```bash
# ------------------------------------------------------------------------------
# Function: oradba_parse_oratab
# Purpose.: Parse /etc/oratab file and find SID entry
# Args....: $1 - SID to find (optional, if empty returns all)
# Returns.: 0 on success, 1 on error
# Output..: Format: SID|ORACLE_HOME|FLAG
# ------------------------------------------------------------------------------
```

### Function with Multiple Return Meanings

```bash
# ------------------------------------------------------------------------------
# Function: validate_oracle_home
# Purpose.: Validate ORACLE_HOME path and check accessibility
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 if valid and accessible
#           1 if path doesn't exist
#           2 if path exists but not accessible
#           3 if path exists but missing required binaries
# Output..: Error message to stderr on validation failure
# ------------------------------------------------------------------------------
```

## VSCode Snippets

Add these snippets to your VSCode settings (`.vscode/oradba.code-snippets`) for quick header insertion:

### Basic Function Header

```json
{
  "OraDBA Function Header": {
    "prefix": "orafunc",
    "body": [
      "# ------------------------------------------------------------------------------",
      "# Function: ${1:function_name}",
      "# Purpose.: ${2:Brief description}",
      "# Args....: $$1 - ${3:First argument description}",
      "# Returns.: ${4:0 on success, 1 on error}",
      "# Output..: ${5:Description of output}",
      "# ------------------------------------------------------------------------------",
      "${1:function_name}() {",
      "    local arg1=\"$$1\"",
      "    ${0}",
      "}"
    ],
    "description": "Insert OraDBA function header template"
  }
}
```

### Function Header with Notes

```json
{
  "OraDBA Function Header with Notes": {
    "prefix": "orafuncn",
    "body": [
      "# ------------------------------------------------------------------------------",
      "# Function: ${1:function_name}",
      "# Purpose.: ${2:Brief description}",
      "# Args....: $$1 - ${3:First argument description}",
      "#           $$2 - ${4:Second argument description (optional)}",
      "# Returns.: ${5:0 on success, 1 on error}",
      "# Output..: ${6:Description of output}",
      "# Notes...: ${7:Additional context or usage notes}",
      "# ------------------------------------------------------------------------------",
      "${1:function_name}() {",
      "    local arg1=\"$$1\"",
      "    local arg2=\"$${2:-}\"",
      "    ${0}",
      "}"
    ],
    "description": "Insert OraDBA function header with Notes field"
  }
}
```

### Plugin Function Header

```json
{
  "OraDBA Plugin Function Header": {
    "prefix": "oraplugin",
    "body": [
      "# ------------------------------------------------------------------------------",
      "# Function: plugin_${1:function_name}",
      "# Purpose.: ${2:Brief description}",
      "# Args....: $$1 - ${3:First argument description}",
      "# Returns.: ${4:0 on success, 1 on error}",
      "# Output..: ${5:Description of output}",
      "# Notes...: ${6:Part of plugin interface v1.0.0}",
      "# ------------------------------------------------------------------------------",
      "plugin_${1:function_name}() {",
      "    local arg1=\"$$1\"",
      "    ${0}",
      "}"
    ],
    "description": "Insert OraDBA plugin function header"
  }
}
```

## Documentation Extraction

Function headers can be extracted automatically for API documentation:

### Extract All Functions

```bash
# Extract all function headers
grep -A 7 "^# Function:" src/lib/*.sh

# Count documented functions
grep -c "^# Function:" src/lib/*.sh

# List functions by file
for file in src/lib/*.sh; do
    echo "=== $file ==="
    grep "^# Function:" "$file" | sed 's/# Function: /  - /'
done
```

### Generate API Reference

```bash
# Generate markdown API reference
cat > doc/api-reference.md << 'EOF'
# OraDBA API Reference

## Core Functions (oradba_common.sh)
EOF

awk '/^# Function:/ {
    getline purpose; sub(/^# Purpose.: /, "", purpose)
    getline args; sub(/^# Args....: /, "", args)
    getline returns; sub(/^# Returns.: /, "", returns)
    getline output; sub(/^# Output..: /, "", output)
    
    print "\n### " substr($0, 13)
    print "\n**Purpose**: " purpose
    print "\n**Arguments**: " args
    print "\n**Returns**: " returns
    print "\n**Output**: " output
}' src/lib/oradba_common.sh >> doc/api-reference.md
```

## Best Practices

### DO

✅ **Keep headers current**: Update headers when changing function behavior
✅ **Be specific**: "Remove duplicate entries" is better than "Clean up path"
✅ **Document side effects**: Mention environment variables, files created, etc.
✅ **Use consistent terminology**: Match variable names between header and code
✅ **Document all returns**: Even if it's just "0 on success, 1 on error"

### DON'T

❌ **Don't be vague**: Avoid "Process data" or "Handle input"
❌ **Don't document implementation details** in Purpose (use Notes for that)
❌ **Don't skip optional arguments**: Mark them as (optional)
❌ **Don't forget return codes**: Every function should document returns
❌ **Don't use past tense**: "Removes" not "Removed"

## Checklist

Before submitting a pull request, verify:

- [ ] All new functions have complete headers
- [ ] Function names in headers match actual declarations
- [ ] All arguments are documented in order
- [ ] Optional arguments are marked as (optional)
- [ ] Default values are documented
- [ ] Return codes are specified
- [ ] Output format is described
- [ ] Side effects are documented
- [ ] Purpose uses imperative mood
- [ ] Headers use standard OraDBA format

## References

- [CONTRIBUTING.md](../CONTRIBUTING.md) - General contribution guidelines
- [development-workflow.md](development-workflow.md) - Development workflow guide
- [architecture.md](architecture.md) - System architecture overview
- [Header template](templates/header.sh) - Standard file header template
