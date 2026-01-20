#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: java_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.20
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Java installations
# Notes....: Manages Java installations under $ORACLE_BASE/product
#            Supports version detection from java -version
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="java"
export plugin_version="1.0.0"
export plugin_description="Oracle Java plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect Java installations under $ORACLE_BASE/product
# Returns.: 0 on success
# Output..: List of Java installation paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a java_homes=()
    local oracle_base="${ORACLE_BASE:-/opt/oracle}"
    
    # Check for Java installations under $ORACLE_BASE/product/java*
    if [[ -d "${oracle_base}/product" ]]; then
        while IFS= read -r -d '' java_dir; do
            if [[ -x "${java_dir}/bin/java" ]]; then
                java_homes+=("${java_dir}")
            fi
        done < <(find "${oracle_base}/product" -maxdepth 1 -type d -name "java*" -print0 2>/dev/null)
    fi
    
    # Check for jdk* directories as well
    if [[ -d "${oracle_base}/product" ]]; then
        while IFS= read -r -d '' jdk_dir; do
            if [[ -x "${jdk_dir}/bin/java" ]]; then
                java_homes+=("${jdk_dir}")
            fi
        done < <(find "${oracle_base}/product" -maxdepth 1 -type d -name "jdk*" -print0 2>/dev/null)
    fi
    
    # Deduplicate and print
    printf '%s\n' "${java_homes[@]}" | sort -u
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is a Java installation
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for bin/java executable
    [[ ! -x "${home_path}/bin/java" ]] && return 1
    
    # Optionally check for bin/javac (JDK vs JRE)
    # For now, accept both JRE and JDK
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for Java (no adjustment needed)
# Args....: $1 - Path to Java home
# Returns.: 0 on success
# Output..: Path unchanged
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check Java installation status
# Args....: $1 - Path to Java home
#           $2 - Ignored
# Returns.: 0 if available, 1 if not
# Output..: Status string
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    
    if [[ -x "${home_path}/bin/java" ]]; then
        echo "available"
        return 0
    else
        echo "unavailable"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get Java installation metadata
# Args....: $1 - Path to Java home
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    echo "product=java"
    
    # Get version if possible
    version=$(plugin_get_version "${home_path}")
    echo "version=${version}"
    
    # Detect if JDK or JRE
    if [[ -x "${home_path}/bin/javac" ]]; then
        echo "type=JDK"
    else
        echo "type=JRE"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Java should NOT show listener status
# Returns.: 1 (never show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Java doesn't have instances
# Returns.: 0 on success
# Output..: Empty
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Java doesn't support instance aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_path
# Purpose.: Get PATH components for Java
# Args....: $1 - JAVA_HOME path
# Returns.: 0 on success
# Output..: bin directory path
# ------------------------------------------------------------------------------
plugin_build_path() {
    local home_path="$1"
    
    if [[ -d "${home_path}/bin" ]]; then
        echo "${home_path}/bin"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for Java
# Args....: $1 - JAVA_HOME path
# Returns.: 0 on success
# Output..: Library path components
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    local -a lib_paths=()
    
    # Add server library path if it exists
    [[ -d "${home_path}/lib/server" ]] && lib_paths+=("${home_path}/lib/server")
    [[ -d "${home_path}/lib" ]] && lib_paths+=("${home_path}/lib")
    
    # For older Java versions
    [[ -d "${home_path}/jre/lib/amd64/server" ]] && lib_paths+=("${home_path}/jre/lib/amd64/server")
    [[ -d "${home_path}/jre/lib/amd64" ]] && lib_paths+=("${home_path}/jre/lib/amd64")
    
    # Print paths if any found
    if [[ ${#lib_paths[@]} -gt 0 ]]; then
        local IFS=:
        echo "${lib_paths[*]}"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for Java
# Returns.: 0 on success
# Output..: "JAVA"
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "JAVA"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for Java
# Returns.: 0 on success
# Output..: List of required binaries
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "java"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get Java version
# Args....: $1 - Installation path
# Returns.: 0 on success, 1 on error
# Output..: Java version string (e.g., "17.0.1", "1.8.0_291", "21.0.2")
# Notes...: Parses output from java -version
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    local java_bin="${home_path}/bin/java"
    local version_output
    local version
    
    # Check if java executable exists
    [[ ! -x "${java_bin}" ]] && { echo "ERR"; return 1; }
    
    # Get version from java -version (stderr)
    version_output=$("${java_bin}" -version 2>&1 | head -1)
    
    # Parse version from different formats:
    # - Java 8:  java version "1.8.0_291"
    # - Java 11+: openjdk version "17.0.1" or java version "21.0.2"
    
    if [[ "${version_output}" =~ version\ \"([0-9._]+)\" ]]; then
        version="${BASH_REMATCH[1]}"
        
        # Normalize 1.8.0_291 to 8.0.291 for consistency
        if [[ "${version}" =~ ^1\.([0-9]+)\.0_([0-9]+)$ ]]; then
            version="${BASH_REMATCH[1]}.0.${BASH_REMATCH[2]}"
        elif [[ "${version}" =~ ^1\.([0-9]+)\.0$ ]]; then
            version="${BASH_REMATCH[1]}.0.0"
        fi
        
        echo "${version}"
        return 0
    fi
    
    # Fallback
    echo "ERR"
    return 1
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Java plugin loaded (v${plugin_version})"
