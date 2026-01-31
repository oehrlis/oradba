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
# Notes...: Excludes JRE subdirectories within JDK installations
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a java_homes=()
    local oracle_base="${ORACLE_BASE:-/opt/oracle}"
    
    # Skip if product directory doesn't exist
    [[ ! -d "${oracle_base}/product" ]] && return 0
    
    # Check for Java installations under $ORACLE_BASE/product/java*
    while IFS= read -r -d '' java_dir; do
        if [[ -x "${java_dir}/bin/java" ]]; then
            java_homes+=("${java_dir}")
        fi
    done < <(find "${oracle_base}/product" -maxdepth 1 -type d -name "java*" -print0 2>/dev/null)
    
    # Check for jdk* directories as well
    while IFS= read -r -d '' jdk_dir; do
        if [[ -x "${jdk_dir}/bin/java" ]]; then
            java_homes+=("${jdk_dir}")
        fi
    done < <(find "${oracle_base}/product" -maxdepth 1 -type d -name "jdk*" -print0 2>/dev/null)
    
    # Check for jre* directories, but ONLY if they are standalone (not inside a JDK)
    while IFS= read -r -d '' jre_dir; do
        # Skip if this is a jre subdirectory within a JDK
        local parent_dir
        parent_dir=$(dirname "${jre_dir}")
        
        # If parent has javac (it's a JDK), skip this JRE
        if [[ -x "${parent_dir}/bin/javac" ]]; then
            continue
        fi
        
        # This is a standalone JRE, include it
        if [[ -x "${jre_dir}/bin/java" ]]; then
            java_homes+=("${jre_dir}")
        fi
    done < <(find "${oracle_base}/product" -maxdepth 2 -type d -name "jre" -print0 2>/dev/null)
    
    # Deduplicate and print
    if [[ ${#java_homes[@]} -gt 0 ]]; then
        printf '%s\n' "${java_homes[@]}" | sort -u
    fi
    
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
    
    # Get version using plugin_get_version
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    else
        echo "version=N/A"
    fi
    
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
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for Java
# Args....: $1 - Input JAVA_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: For Java, base is same as JAVA_HOME
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for Java
# Args....: $1 - JAVA_HOME
#           $2 - Not used for Java
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds environment for Java
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")
    
    echo "JAVA_HOME=${home_path}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate Java instances
# Args....: $1 - JAVA_HOME path
# Returns.: 0 on success
# Output..: Empty (Java doesn't have instances)
# Notes...: Java installations don't have instances
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    # Java doesn't have instances
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
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for Java
# Args....: $1 - JAVA_HOME path
# Returns.: 0 on success
# Output..: bin directory path
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
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
# Returns.: 0 on success with clean version string to stdout
#           1 when version not applicable (no output)
#           2 on error or unavailable (no output)
# Output..: Java version string (e.g., "17.0.1", "8.0.291", "21.0.2")
# Notes...: Parses output from java -version
#           No sentinel strings (ERR, unknown, N/A) in output
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    local java_bin="${home_path}/bin/java"
    local version_output
    local version
    
    # Check if home path exists
    [[ ! -d "${home_path}" ]] && return 2
    
    # Check if java executable exists
    [[ ! -x "${java_bin}" ]] && return 2
    
    # Get version from java -version (stderr)
    version_output=$("${java_bin}" -version 2>&1 | head -1)
    [[ -z "${version_output}" ]] && return 2
    
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
    
    # Version extraction failed
    return 2
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Java plugin loaded (v${plugin_version})"
