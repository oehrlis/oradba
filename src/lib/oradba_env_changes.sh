#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# Name......: oradba_env_changes.sh
# Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date......: 2026-01-14
# Version...: 0.20.0
# Purpose...: Configuration change detection for Oracle environments
# Notes.....: Part of Phase 3 implementation
# ---------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_CHANGES_LOADED:-}" ]] && return 0
readonly ORADBA_ENV_CHANGES_LOADED=1

# Default cache directory
: "${ORADBA_CACHE_DIR:=${ORADBA_BASE}/var/cache}"

# ------------------------------------------------------------------------------
# Function: oradba_get_file_signature
# Purpose.: Get file signature (timestamp:size)
# Args....: $1 - File path
# Returns.: 0 on success, 1 on failure
# Output..: File signature string
# ------------------------------------------------------------------------------
oradba_get_file_signature() {
    local file="$1"
    
    [[ ! -f "$file" ]] && return 1
    
    # Get timestamp and size
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local mtime size
        mtime=$(stat -f "%m" "$file" 2>/dev/null)
        size=$(stat -f "%z" "$file" 2>/dev/null)
        echo "${mtime}:${size}"
    else
        # Linux
        stat -c '%Y:%s' "$file" 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# Function: oradba_store_file_signature
# Purpose.: Store file signature for future comparison
# Args....: $1 - File path to monitor
#          $2 - Signature storage file (optional, auto-generated if not provided)
# Returns.: 0 on success, 1 on failure
# ------------------------------------------------------------------------------
oradba_store_file_signature() {
    local file="$1"
    local sig_file="${2:-}"
    
    [[ ! -f "$file" ]] && return 1
    
    # Auto-generate signature file path if not provided
    if [[ -z "$sig_file" ]]; then
        local filename
        filename=$(basename "$file")
        sig_file="${ORADBA_CACHE_DIR}/${filename}.sig"
    fi
    
    # Ensure cache directory exists
    mkdir -p "$(dirname "$sig_file")" 2>/dev/null
    
    # Get and store signature
    local signature
    signature=$(oradba_get_file_signature "$file")
    
    if [[ -n "$signature" ]]; then
        echo "$signature" > "$sig_file"
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_check_file_changed
# Purpose.: Check if file has changed since last signature
# Args....: $1 - File path to check
#          $2 - Signature storage file (optional, auto-generated if not provided)
# Returns.: 0 if changed, 1 if not changed or error
# Output..: Change message (if changed)
# ------------------------------------------------------------------------------
oradba_check_file_changed() {
    local file="$1"
    local sig_file="${2:-}"
    
    [[ ! -f "$file" ]] && return 1
    
    # Auto-generate signature file path if not provided
    if [[ -z "$sig_file" ]]; then
        local filename
        filename=$(basename "$file")
        sig_file="${ORADBA_CACHE_DIR}/${filename}.sig"
    fi
    
    # Get current signature
    local current_sig
    current_sig=$(oradba_get_file_signature "$file")
    
    [[ -z "$current_sig" ]] && return 1
    
    # Get stored signature
    local stored_sig
    stored_sig=$(cat "$sig_file" 2>/dev/null)
    
    # If no stored signature, file is considered new/changed
    if [[ -z "$stored_sig" ]]; then
        echo "New file detected: $file"
        oradba_store_file_signature "$file" "$sig_file"
        return 0
    fi
    
    # Compare signatures
    if [[ "$current_sig" != "$stored_sig" ]]; then
        echo "File changed: $file"
        oradba_store_file_signature "$file" "$sig_file"
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_check_config_changes
# Purpose.: Check if any configuration files have changed
# Args....: None
# Returns.: 0 if changes detected, 1 if no changes
# Output..: List of changed files
# ------------------------------------------------------------------------------
oradba_check_config_changes() {
    local changed=1
    local changes=()
    
    # Files to monitor
    local config_files=(
        "/etc/oratab"
        "${ORADBA_BASE}/etc/oradba_homes.conf"
        "${ORADBA_BASE}/etc/oradba_core.conf"
        "${ORADBA_BASE}/etc/oradba_standard.conf"
        "${ORADBA_BASE}/etc/oradba_local.conf"
        "${ORADBA_BASE}/etc/oradba_customer.conf"
    )
    
    # Check SID-specific config if ORACLE_SID is set
    if [[ -n "${ORACLE_SID:-}" ]]; then
        config_files+=("${ORADBA_BASE}/etc/sid/sid.${ORACLE_SID}.conf")
    fi
    
    # Check each file
    for file in "${config_files[@]}"; do
        [[ ! -f "$file" ]] && continue
        
        if oradba_check_file_changed "$file"; then
            changes+=("$file")
            changed=0
        fi
    done
    
    # Output changes if any
    if [[ ${#changes[@]} -gt 0 ]]; then
        for change in "${changes[@]}"; do
            echo "$change"
        done
    fi
    
    return $changed
}

# ------------------------------------------------------------------------------
# Function: oradba_init_change_tracking
# Purpose.: Initialize change tracking for all config files
# Args....: None
# Returns.: 0 on success
# Output..: Initialization message
# ------------------------------------------------------------------------------
oradba_init_change_tracking() {
    # Ensure cache directory exists
    mkdir -p "${ORADBA_CACHE_DIR}" 2>/dev/null
    
    # Files to monitor
    local config_files=(
        "/etc/oratab"
        "${ORADBA_BASE}/etc/oradba_homes.conf"
        "${ORADBA_BASE}/etc/oradba_core.conf"
        "${ORADBA_BASE}/etc/oradba_standard.conf"
        "${ORADBA_BASE}/etc/oradba_local.conf"
        "${ORADBA_BASE}/etc/oradba_customer.conf"
    )
    
    local count=0
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            oradba_store_file_signature "$file"
            ((count++))
        fi
    done
    
    echo "Initialized change tracking for $count configuration files"
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_clear_change_tracking
# Purpose.: Clear all change tracking data
# Args....: None
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_clear_change_tracking() {
    if [[ -d "${ORADBA_CACHE_DIR}" ]]; then
        rm -f "${ORADBA_CACHE_DIR}"/*.sig 2>/dev/null
        echo "Cleared change tracking data"
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_auto_reload_on_change
# Purpose.: Check for changes and reload environment if needed
# Args....: None
# Returns.: 0 if environment reloaded, 1 if no changes
# Output..: Reload message if environment was reloaded
# ------------------------------------------------------------------------------
oradba_auto_reload_on_change() {
    local changes
    
    # Check for changes
    changes=$(oradba_check_config_changes)
    
    if [[ -n "$changes" ]]; then
        echo "Configuration changes detected:"
        echo "$changes"
        
        # If we have a current SID, reload its environment
        if [[ -n "${ORACLE_SID:-}" ]]; then
            echo "Reloading environment for ${ORACLE_SID}..."
            # This would need to call the environment builder
            # oradba_build_environment "$ORACLE_SID"
            return 0
        fi
        
        echo "No active environment to reload. Please source environment manually."
        return 0
    fi
    
    return 1
}
