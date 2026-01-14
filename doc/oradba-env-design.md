# oradba Environment Management System - Design Document

**Version:** 1.0  
**Date:** 2026-01-14  
**Status:** Design Phase

---

## 1. Executive Summary

This document defines the architecture for oradba's environment management system,
designed to provide a modern, maintainable alternative to basenv while maintaining
Oracle standard compatibility.

### Key Principles

- **Oracle Standard Compliance**: 100% compatible with `/etc/oratab` format
- **Pure Bash**: No external dependencies beyond POSIX tools
- **Human & Machine Friendly**: Easy to read and maintain
- **Extensible**: Support for future RAC, PDB, ASM features

---

## 2. Requirements Summary

### Must-Have Features

- ✅ Standard oratab support (SID:HOME:FLAG)
- ✅ Environment without Oracle DB (OUD, WLS, DataSafe, Client-only)
- ✅ Correct PATH and LD_LIBRARY_PATH management
- ✅ Multiple Oracle homes support
- ✅ Dummy SIDs for pre-installation environment setup
- ✅ ASM instance support (+ASM*)
- ✅ Read-Only Oracle Home (ROOH) detection
- ✅ Manual and scripted maintenance (oradba_homes.sh)
- ✅ SID-specific configuration files
- ✅ Validation and health checks

### Nice-to-Have Features

- 🔄 Change detection and auto-reload
- 🔄 Shell completion (bash/zsh)
- 🔄 RAC support (admin/policy-managed)
- 🔄 PDB-aware environments

### Out of Scope

- ❌ Windows native support (bash on WSL acceptable)
- ❌ Backward compatibility with basenv

---

## 3. File Structure & Formats

### 3.1 Core Configuration Files

```text
$ORADBA_BASE/
├── etc/
│   ├── oratab                    # Standard Oracle inventory (managed by Oracle)
│   ├── oradba_homes.conf         # Oracle home registry (enhanced metadata)
│   ├── oradba_core.conf          # Core system defaults (shipped)
│   ├── oradba_standard.conf      # Standard environment settings
│   ├── oradba_local.conf         # Site-specific overrides
│   ├── oradba_customer.conf      # Customer customizations
│   └── sid/
│       ├── sid.<SID>.conf        # SID-specific configs
│       ├── sid.<OUDINSTANCE>.conf # OUD instance configs
│       └── sid.<WLSDOMAIN>.conf  # WLS domain configs
└── var/
    └── cache/
        └── oradba_env.cache      # Parsed environment cache (optional)
```

### 3.2 File Format Specifications

#### 3.2.1 oratab (Oracle Standard - Read/Write)

**Location**: `/etc/oratab` (symlink to `$ORADBA_BASE/etc/oratab`)

**Format**: `<SID>:<ORACLE_HOME>:<FLAG>`

**Standard Flags**:

- `Y` - Auto-start on system boot
- `N` - Do not auto-start
- `D` - Dummy SID (environment only, no database)

**Extended Flags** (oradba-specific, optional):

- `A` - ASM instance
- `S` - Standby database
- `C` - Cluster/RAC database
- `R` - Read-only home

**Examples**:

```text
# Standard database instances
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
CDB1:/u01/app/oracle/product/21.0.0/dbhome_1:Y

# ASM instances
+ASM:/u01/app/oracle/product/19.0.0/grid:Y

# Dummy SIDs for pre-installation
db23c:/u01/app/oracle/product/23.0.0/dbhome_1:D

# RAC instances (future)
PROD1:/u01/app/oracle/product/19.0.0/dbhome_1:C

# Standby databases (future)
STDBY:/u01/app/oracle/product/19.0.0/dbhome_1:S
```

**Parsing Rules**:

- Lines starting with `#` are comments
- Empty lines ignored
- Multiple SIDs can share the same ORACLE_HOME
- First match wins for SID lookup
- Fields separated by colon (`:`)

---

#### 3.2.2 oradba_homes.conf (oradba Enhanced Metadata)

**Location**: `$ORADBA_BASE/etc/oradba_homes.conf`

**Purpose**: Extended Oracle home registry with versioning and product info

**Format**: Semicolon-delimited (`;`) for easy parsing and human readability

**Fields**:

```text
ORACLE_HOME;Product;Version;Edition;Position;Dummy_SID;Short_Name;Description
```

**Field Definitions**:

| Field       | Type    | Description                   | Example                                   |
|-------------|---------|-------------------------------|-------------------------------------------|
| ORACLE_HOME | Path    | Absolute path to Oracle home  | `/u01/app/oracle/product/19.0.0/dbhome_1` |
| Product     | String  | Product type                  | `RDBMS`, `GRID`, `CLIENT`, `OUD`, `WLS`   |
| Version     | String  | Version in XYYZZ format       | `190000` (19.0.0), `210300` (21.3.0)      |
| Edition     | String  | License edition               | `EE`, `SE2`, `XE`, `FREE`, `GRID`, `N/A`  |
| Position    | Integer | Display order (10, 20, 30...) | `10`                                      |
| Dummy_SID   | String  | Dummy SID for this home       | `db19c`, `grid19c`                        |
| Short_Name  | String  | Human-readable short name     | `19c`, `21c Free`                         |
| Description | String  | Optional description          | `Oracle Database 19c Enterprise Edition`  |

**Example**:

```conf
# Format: ORACLE_HOME;Product;Version;Edition;Position;Dummy_SID;Short_Name;Description
#
# RDBMS Homes
/u01/app/oracle/product/19.0.0/dbhome_1;RDBMS;190000;EE;10;db19c;19c EE;Oracle Database 19c Enterprise Edition
/u01/app/oracle/product/21.0.0/dbhome_1;RDBMS;210000;FREE;20;db21c;21c Free;Oracle Database 21c Free
/u01/app/oracle/product/23.0.0/dbhome_1;RDBMS;230000;FREE;30;db23c;23ai Free;Oracle Database 23ai Free

# Grid Infrastructure / ASM
/u01/app/oracle/product/19.0.0/grid;GRID;190000;GRID;15;grid19c;Grid 19c;Oracle Grid Infrastructure 19c

# Client-only installations
/u01/app/oracle/product/19.0.0/client;CLIENT;190000;N/A;40;client19c;Client 19c;Oracle Client 19c

# Oracle Unified Directory
/u01/app/oracle/product/oud12c;OUD;120214;N/A;50;oud12c;OUD 12c;Oracle Unified Directory 12.2.1.4

# WebLogic Server
/u01/app/oracle/middleware/wls14c;WLS;141100;N/A;60;wls14c;WLS 14c;WebLogic Server 14.1.1.0
```

**Parsing Rules**:

- Lines starting with `#` are comments
- Empty lines ignored
- Fields separated by semicolon (`;`)
- Whitespace around delimiters is trimmed
- Position determines display order (ascending)
- Dummy SID creates entry in environment even without oratab

---

#### 3.2.3 Generic Configuration Files

**Files** (loaded in order):

1. `oradba_core.conf` - Shipped with oradba, DO NOT MODIFY
2. `oradba_standard.conf` - Standard environment template
3. `oradba_local.conf` - Site/host-specific settings
4. `oradba_customer.conf` - Customer customizations

**Format**: Shell variable syntax with section markers

```bash
# Section: [DEFAULT]
# Applied to all environments

export EDITOR=vi
export ORACLE_TERM=xterm
export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"

# Section: [RDBMS]
# Applied only to RDBMS homes

TNS_ADMIN="${ORACLE_HOME}/network/admin"
SQLPATH="${ORADBA_BASE}/sql:${ORACLE_HOME}/rdbms/admin"

# Section: [GRID]
# Applied only to Grid Infrastructure homes

ORACLE_TERM=hft

# Section: [ASM]
# Applied to ASM instances

# No specific settings yet

# Section: [OUD]
# Applied to OUD instances

OUD_INSTANCE_HOME="${ORACLE_HOME}/instances/${ORACLE_SID}"

# Section: [WLS]
# Applied to WebLogic domains

DOMAIN_HOME="${WLS_DOMAIN_BASE}/${ORACLE_SID}"
```

**Variable Expansion**:

- `${ORACLE_HOME}` - Current Oracle home
- `${ORACLE_SID}` - Current SID
- `${ORADBA_BASE}` - oradba installation directory
- Other environment variables available

---

#### 3.2.4 SID-Specific Configuration Files

**Location**: `$ORADBA_BASE/etc/sid/sid.<SID>.conf`

**Purpose**: Override settings for specific SID/instance/domain

**Format**: Same as generic configs, section-based

**Example** (`sid.FREE.conf`):

```bash
# Section: [FREE]

# Database-specific paths
TNS_ADMIN=/u01/app/oracle/network/FREE
SQLPATH=/home/oracle/sql/FREE:${ORACLE_HOME}/rdbms/admin

# Custom aliases
alias alertlog='tail -f ${ORACLE_BASE}/diag/rdbms/free/FREE/trace/alert_FREE.log'
alias pfile='vi ${ORACLE_HOME}/dbs/initFREE.ora'

# Database metadata (for oradba tools)
export ORADBA_DB_TYPE="FREE"
export ORADBA_DB_ROLE="PRIMARY"
export ORADBA_AUTO_START="NO"
export ORADBA_BACKUP_POLICY="DAILY"
```

---

## 4. Core Components Architecture

### 4.1 Component Overview

```text
oradba.sh env <SID>
    ↓
oradba_env_core.sh (sourced)
    ├── oradba_env_parser.sh    - Parse oratab, oradba_homes.conf
    ├── oradba_env_builder.sh   - Build environment variables
    ├── oradba_env_validator.sh - Validate environment
    └── oradba_env_cache.sh     - Cache management (optional)
```

### 4.2 Function Libraries

#### 4.2.1 oradba_env_parser.sh

**Purpose**: Parse configuration files

**Key Functions**:

```bash
oradba_parse_oratab()           # Parse /etc/oratab
oradba_parse_homes()            # Parse oradba_homes.conf
oradba_find_sid()               # Lookup SID in oratab
oradba_find_home()              # Lookup ORACLE_HOME
oradba_get_home_metadata()      # Get home info from oradba_homes.conf
oradba_list_all_sids()          # List all available SIDs
```

#### 4.2.2 oradba_env_builder.sh

**Purpose**: Construct environment variables

**Key Functions**:

```bash
oradba_build_environment()      # Main builder
oradba_set_oracle_vars()        # Set ORACLE_HOME, ORACLE_SID, etc.
oradba_set_path()               # Construct PATH
oradba_set_lib_path()           # Construct LD_LIBRARY_PATH
oradba_detect_rooh()            # Detect Read-Only Oracle Home
oradba_set_nls_vars()           # Set NLS_* variables
oradba_apply_config_section()   # Apply config file sections
oradba_apply_sid_config()       # Apply SID-specific config
```

#### 4.2.3 oradba_env_validator.sh

**Purpose**: Validate environment

**Key Functions**:

```bash
oradba_validate_oracle_home()   # Check ORACLE_HOME exists
oradba_validate_sid()           # Check SID validity
oradba_check_oracle_binaries()  # Verify sqlplus, etc. exist
oradba_check_db_running()       # Check if database is running
oradba_get_db_version()         # Detect Oracle version
```

#### 4.2.4 oradba_env_cache.sh

**Purpose**: Performance optimization via caching

**Key Functions**:

```bash
oradba_cache_build()            # Build cache from configs
oradba_cache_load()             # Load cached environment
oradba_cache_is_valid()         # Check if cache is up-to-date
oradba_cache_invalidate()       # Clear cache
```

---

## 5. Environment Setup Flow

### 5.1 Main Workflow

```text
User executes: . oradba.sh env FREE
    ↓
1. Parse Arguments
    ├── Extract SID/HOME from arguments
    ├── Validate input format
    └── Set operation mode (set/list/show/clear)
    ↓
2. Load Configuration Files
    ├── Source oradba_core.conf (system defaults)
    ├── Source oradba_standard.conf
    ├── Source oradba_local.conf
    └── Source oradba_customer.conf
    ↓
3. Parse Tab Files
    ├── Parse /etc/oratab → find SID → get ORACLE_HOME
    ├── Parse oradba_homes.conf → get home metadata
    └── Determine product type (RDBMS/GRID/CLIENT/OUD/WLS)
    ↓
4. Build Environment
    ├── Set ORACLE_HOME, ORACLE_SID, ORACLE_BASE
    ├── Detect Read-Only Oracle Home
    ├── Set ORACLE_UNQNAME, DBID (if available)
    ├── Construct PATH (prepend/append logic)
    ├── Construct LD_LIBRARY_PATH (lib/lib64 handling)
    ├── Set NLS_* variables
    ├── Set TNS_ADMIN, SQLPATH
    └── Set product-specific variables (ASM/GRID/OUD/WLS)
    ↓
5. Apply Configuration Overlays
    ├── Apply [DEFAULT] section from all configs
    ├── Apply [RDBMS]/[GRID]/[OUD]/[WLS] section
    ├── Apply [ASM] section if applicable
    └── Apply sid.<SID>.conf if exists
    ↓
6. Validate & Export
    ├── Validate ORACLE_HOME exists
    ├── Check critical binaries (sqlplus, etc.)
    ├── Set ORADBA_ENV_LOADED=1
    ├── Set ORADBA_CURRENT_SID=$SID
    ├── Export all variables
    └── Display environment summary
```

---

## 6. Key Implementation Details

### 6.1 PATH Management

**Objectives**:

- Add Oracle binaries to PATH
- Handle multiple Oracle homes (prevent duplicates)
- Preserve user's existing PATH entries
- Order: Oracle bins → System bins

**Strategy**:

```bash
# Remove old Oracle paths from PATH
oradba_clean_path() {
    local new_path=""
    local IFS=":"
    for dir in $PATH; do
        # Skip Oracle directories
        [[ "$dir" =~ /oracle/ ]] && continue
        [[ "$dir" =~ /grid/ ]] && continue
        [[ -n "$new_path" ]] && new_path="${new_path}:"
        new_path="${new_path}${dir}"
    done
    export PATH="$new_path"
}

# Add Oracle paths
oradba_add_oracle_path() {
    local oracle_home="$1"
    
    # Priority order:
    # 1. $ORACLE_HOME/bin (highest priority)
    # 2. $ORACLE_HOME/OPatch
    # 3. Grid Infrastructure bin (if different from ORACLE_HOME)
    
    local new_path="${oracle_home}/bin"
    
    [[ -d "${oracle_home}/OPatch" ]] && \
        new_path="${new_path}:${oracle_home}/OPatch"
    
    # If RDBMS and separate Grid home exists, add it
    if [[ -n "$GRID_HOME" ]] && [[ "$GRID_HOME" != "$oracle_home" ]]; then
        [[ -d "${GRID_HOME}/bin" ]] && \
            new_path="${new_path}:${GRID_HOME}/bin"
    fi
    
    export PATH="${new_path}:${PATH}"
}
```

---

### 6.2 LD_LIBRARY_PATH Management

**Objectives**:

- Add Oracle libraries to LD_LIBRARY_PATH
- Handle lib vs lib64 (32-bit vs 64-bit)
- Support ROOH (Read-Only Oracle Home)
- Handle platform differences (Linux/Solaris/HP-UX)

**Strategy**:

```bash
oradba_set_lib_path() {
    local oracle_home="$1"
    local lib_path=""
    
    # Determine platform library variable
    local lib_var="LD_LIBRARY_PATH"
    case "$(uname -s)" in
        HP-UX)   lib_var="SHLIB_PATH" ;;
        AIX)     lib_var="LIBPATH" ;;
        Darwin)  lib_var="DYLD_LIBRARY_PATH" ;;
    esac
    
    # Add Oracle libraries (prefer lib64 on 64-bit)
    if [[ -d "${oracle_home}/lib64" ]]; then
        lib_path="${oracle_home}/lib64"
    fi
    
    if [[ -d "${oracle_home}/lib" ]]; then
        [[ -n "$lib_path" ]] && lib_path="${lib_path}:"
        lib_path="${lib_path}${oracle_home}/lib"
    fi
    
    # Add Grid libraries if separate
    if [[ -n "$GRID_HOME" ]] && [[ "$GRID_HOME" != "$oracle_home" ]]; then
        [[ -d "${GRID_HOME}/lib" ]] && \
            lib_path="${lib_path}:${GRID_HOME}/lib"
    fi
    
    # Preserve existing library path
    eval "local existing=\"\${${lib_var}}\""
    if [[ -n "$existing" ]]; then
        lib_path="${lib_path}:${existing}"
    fi
    
    export ${lib_var}="$lib_path"
}
```

---

### 6.3 Read-Only Oracle Home Detection

**Implementation**:

```bash
oradba_detect_rooh() {
    local oracle_home="$1"
    local oracle_base=""
    local is_rooh=0
    
    # Check for orabasetab file (12.2+)
    if [[ -f "${oracle_home}/install/orabasetab" ]]; then
        # Format: ORACLE_HOME:ORACLE_BASE:ORACLE_HOME_NAME:Y/N
        # Last field Y = Read-Only Home
        while IFS=: read -r home base name rooh_flag; do
            if [[ "$home" == "$oracle_home" ]] && [[ "$rooh_flag" == "Y" ]]; then
                is_rooh=1
                oracle_base="$base"
                break
            fi
        done < "${oracle_home}/install/orabasetab"
    fi
    
    # Export variables
    export ORACLE_BASE="${oracle_base}"
    export ORADBA_ROOH="${is_rooh}"
    
    # Set dbs directory based on ROOH
    if [[ $is_rooh -eq 1 ]]; then
        export ORADBA_DBS="${oracle_base}/dbs"
    else
        export ORADBA_DBS="${oracle_home}/dbs"
    fi
    
    return $is_rooh
}
```

---

### 6.4 ASM Instance Handling

**Detection**:

```bash
oradba_is_asm_instance() {
    local sid="$1"
    [[ "$sid" =~ ^\+ASM ]] && return 0 || return 1
}

oradba_set_asm_environment() {
    # ASM uses sysasm privilege instead of sysdba
    export ORACLE_SYSASM="TRUE"
    
    # ASM-specific aliases
    alias sqlasm='sqlplus / as sysasm'
    alias asmcmd='asmcmd'
    
    # Grid home should be in PATH
    export ORACLE_HOME="${GRID_HOME}"
}
```

---

### 6.5 Configuration Section Processing

**Parser**:

```bash
oradba_apply_config_section() {
    local config_file="$1"
    local section="$2"  # e.g., DEFAULT, RDBMS, ASM
    
    [[ ! -f "$config_file" ]] && return 0
    
    local in_section=0
    local line
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line="${line##*( )}"
        line="${line%%*( )}"
        
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [[ "$current_section" == "$section" ]]; then
                in_section=1
            else
                in_section=0
            fi
            continue
        fi
        
        # Process variable assignments in active section
        if [[ $in_section -eq 1 ]]; then
            # Handle export statements
            if [[ "$line" =~ ^export ]]; then
                eval "$line"
            # Handle aliases
            elif [[ "$line" =~ ^alias ]]; then
                eval "$line"
            # Handle direct assignments
            elif [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
                eval "export $line"
            fi
        fi
    done < "$config_file"
}
```

---

## 7. Command Interface

### 7.1 Main Command: oradba.sh env

**Usage**:

```bash
# Source environment for a SID
. oradba.sh env <SID>
. oradba.sh env FREE

# Source environment by Oracle Home path
. oradba.sh env /u01/app/oracle/product/19.0.0/dbhome_1

# List all available SIDs
oradba.sh env list
oradba.sh env list --verbose

# Show current environment
oradba.sh env show

# Clear Oracle environment
oradba.sh env clear

# Validate environment
oradba.sh env validate [SID]

# Show environment variables that would be set (dry-run)
oradba.sh env preview <SID>
```

---

### 7.2 Management Tool: oradba_homes.sh

**Usage**:

```bash
# List all Oracle homes
oradba_homes.sh list

# Add Oracle home
oradba_homes.sh add <ORACLE_HOME> [options]
  --product RDBMS|GRID|CLIENT|OUD|WLS
  --version 190000
  --edition EE|SE2|XE|FREE
  --dummy-sid db19c
  --description "Oracle 19c EE"

# Remove Oracle home
oradba_homes.sh remove <ORACLE_HOME>

# Update Oracle home metadata
oradba_homes.sh update <ORACLE_HOME> [options]

# Scan and auto-detect Oracle homes
oradba_homes.sh scan [--path /u01/app/oracle]

# Validate oradba_homes.conf
oradba_homes.sh validate

# Export/Import
oradba_homes.sh export > homes_backup.conf
oradba_homes.sh import < homes_backup.conf
```

---

## 8. Change Detection Implementation

### 8.1 Strategy

**Approach**: Timestamp + Size comparison (simpler than MD5, sufficient for most cases)

**Files to Monitor**:

- `/etc/oratab`
- `$ORADBA_BASE/etc/oradba_homes.conf`
- `$ORADBA_BASE/etc/oradba_*.conf`
- `$ORADBA_BASE/etc/sid/sid.<CURRENT_SID>.conf`

**Implementation**:

```bash
oradba_check_config_changes() {
    # Store metadata: timestamp:size
    local oratab_meta="${ORADBA_CACHE_DIR}/oratab.meta"
    local homes_meta="${ORADBA_CACHE_DIR}/homes.meta"
    
    local changed=0
    
    # Check oratab
    if [[ -f "/etc/oratab" ]]; then
        local current_meta="$(stat -c '%Y:%s' /etc/oratab 2>/dev/null)"
        local stored_meta="$(cat "$oratab_meta" 2>/dev/null)"
        
        if [[ "$current_meta" != "$stored_meta" ]]; then
            echo "INFO: /etc/oratab changed"
            echo "$current_meta" > "$oratab_meta"
            changed=1
        fi
    fi
    
    # Check oradba_homes.conf
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    if [[ -f "$homes_file" ]]; then
        local current_meta="$(stat -c '%Y:%s' "$homes_file" 2>/dev/null)"
        local stored_meta="$(cat "$homes_meta" 2>/dev/null)"
        
        if [[ "$current_meta" != "$stored_meta" ]]; then
            echo "INFO: oradba_homes.conf changed"
            echo "$current_meta" > "$homes_meta"
            changed=1
        fi
    fi
    
    return $changed
}

# Auto-reload if changes detected
if oradba_check_config_changes; then
    echo "Configuration files changed. Re-sourcing oradba environment..."
    oradba_reload_base_environment
fi
```

---

## 9. Validation Framework

### 9.1 Validation Levels

**Level 1 - Basic**:

- ORACLE_HOME exists
- ORACLE_HOME is readable
- oratab entry exists

**Level 2 - Standard**:

- Critical binaries exist (sqlplus, etc.)
- Library directories exist
- Basic connectivity (can connect to idle instance)

**Level 3 - Full**:

- Database is accessible
- Version detection
- Configuration consistency checks
- Permission validation

**Implementation**:

```bash
oradba_validate() {
    local sid="$1"
    local level="${2:-standard}"  # basic|standard|full
    
    local errors=0
    local warnings=0
    
    echo "Validating environment for SID: $sid (level: $level)"
    echo "========================================"
    
    # Level 1: Basic
    if [[ ! -d "$ORACLE_HOME" ]]; then
        echo "ERROR: ORACLE_HOME does not exist: $ORACLE_HOME"
        ((errors++))
        return 1
    fi
    echo "✓ ORACLE_HOME exists: $ORACLE_HOME"
    
    if [[ ! -r "$ORACLE_HOME" ]]; then
        echo "ERROR: ORACLE_HOME is not readable"
        ((errors++))
    else
        echo "✓ ORACLE_HOME is readable"
    fi
    
    # Level 2: Standard
    if [[ "$level" != "basic" ]]; then
        local binaries=("sqlplus" "tnsping" "lsnrctl")
        for bin in "${binaries[@]}"; do
            if [[ -x "${ORACLE_HOME}/bin/${bin}" ]]; then
                echo "✓ ${bin} found"
            else
                echo "WARNING: ${bin} not found or not executable"
                ((warnings++))
            fi
        done
        
        # Check library directories
        if [[ -d "${ORACLE_HOME}/lib" ]] || [[ -d "${ORACLE_HOME}/lib64" ]]; then
            echo "✓ Library directories exist"
        else
            echo "ERROR: No lib directories found"
            ((errors++))
        fi
    fi
    
    # Level 3: Full
    if [[ "$level" == "full" ]]; then
        # Try to detect version
        local version=$(oradba_get_db_version)
        if [[ -n "$version" ]]; then
            echo "✓ Oracle version: $version"
        else
            echo "WARNING: Could not detect Oracle version"
            ((warnings++))
        fi
        
        # Try basic SQL*Plus connectivity
        if echo "exit" | sqlplus -s / as sysdba > /dev/null 2>&1; then
            echo "✓ SQL*Plus connectivity successful"
        else
            echo "WARNING: Could not connect with SQL*Plus"
            ((warnings++))
        fi
    fi
    
    echo ""
    echo "Summary: $errors error(s), $warnings warning(s)"
    return $errors
}
```

---

## 10. Implementation Roadmap

### Phase 1: Core Foundation (Week 1-2)

- [ ] Create `oradba_env_parser.sh` with oratab parsing
- [ ] Create `oradba_env_builder.sh` with basic environment setup
- [ ] Implement PATH and LD_LIBRARY_PATH management
- [ ] Create `oradba_homes.conf` parser
- [ ] Basic integration with `oradba.sh env` command
- [ ] Unit tests for parsers

### Phase 2: Configuration System (Week 3)

- [ ] Implement section-based config file processing
- [ ] Apply generic configs (core/standard/local/customer)
- [ ] Apply SID-specific configs
- [ ] Variable expansion in config files
- [ ] Config validation

### Phase 3: Advanced Features (Week 4)

- [ ] Read-Only Oracle Home detection
- [ ] ASM instance handling
- [ ] Change detection mechanism
- [ ] Environment caching (optional)
- [ ] Validation framework

### Phase 4: Management Tools (Week 5)

- [ ] Enhance `oradba_homes.sh` to use new parsers
- [ ] Auto-scan functionality
- [ ] Export/import functionality
- [ ] Configuration migration from old format

### Phase 5: Testing & Documentation (Week 6)

- [ ] Comprehensive testing (19c, 21c, 23ai, Free)
- [ ] Test with ASM instances
- [ ] Test with client-only installations
- [ ] Test with OUD/WLS (if available)
- [ ] Update user documentation
- [ ] Create migration guide

### Phase 6: Nice-to-Have Features (Future)

- [ ] Shell completion (bash/zsh)
- [ ] RAC support (admin-managed)
- [ ] RAC support (policy-managed)
- [ ] PDB-aware environments
- [ ] Interactive TUI for environment selection

---

## 11. Testing Strategy

### 11.1 Test Scenarios

**Basic Tests**:

- Parse empty oratab
- Parse oratab with single entry
- Parse oratab with multiple SIDs, same home
- Parse oratab with comments and empty lines
- Source environment for valid SID
- Handle non-existent SID gracefully

**Advanced Tests**:

- Multiple Oracle homes (different versions)
- ASM instance environment
- Dummy SID environment
- ROOH detection and handling
- Config file section processing
- Config file variable expansion

**Edge Cases**:

- Missing oratab file
- Missing oradba_homes.conf
- Circular variable references in configs
- Very long PATH/LD_LIBRARY_PATH
- Special characters in paths
- Symlinked Oracle homes

### 11.2 Test Structure

```bash
tests/
├── test_oradba_env_parser.sh
├── test_oradba_env_builder.sh
├── test_oradba_env_validator.sh
├── test_integration.sh
└── fixtures/
    ├── oratab.sample
    ├── oradba_homes.sample.conf
    └── configs/
        ├── oradba_core.conf
        └── sid.TEST.conf
```

---

## 12. Migration from Current System

### 12.1 Current State Assessment

- Analyze existing `oradba_homes.sh` implementation
- Identify dependencies
- Map current environment variables to new system
- Document current config file formats

### 12.2 Migration Steps

1. Create parallel implementation (don't break existing)
2. Implement backward compatibility layer
3. Migrate config files with conversion script
4. Test extensively with existing installations
5. Provide deprecation warnings
6. Complete migration in next major version

---

## 13. Open Questions & Decisions Needed

### 13.1 File Locations

- **Q**: Should `/etc/oratab` always be a symlink to `$ORADBA_BASE/etc/oratab`?
  - **Consideration**: System may already have oratab managed by Oracle installer
  - **Recommendation**: Read from `/etc/oratab` if exists, fallback to `$ORADBA_BASE/etc/oratab`

### 13.2 Caching

- **Q**: Implement caching from day one or add later?
  - **Recommendation**: Add in Phase 3, keep it optional

### 13.3 Error Handling

- **Q**: Behavior when SID not found?
  - **Option A**: Exit with error
  - **Option B**: Show available SIDs and prompt
  - **Recommendation**: Option A for scripting, Option B for interactive

### 13.4 Product Detection

- **Q**: How to detect product type if not in oradba_homes.conf?
  - **Heuristics**:
    - Check for `grid` in path → GRID
    - Check for `sqlplus` → RDBMS
    - Check for `oud-setup` → OUD
    - Check for `wlst.sh` → WLS

---

## 14. Success Criteria

- ✅ Source environment in < 0.5 seconds (without cache)
- ✅ Source environment in < 0.1 seconds (with cache)
- ✅ 100% oratab format compatibility
- ✅ Support 0 to N Oracle homes
- ✅ Work with empty/missing oratab
- ✅ Pass all test scenarios
- ✅ Documentation complete
- ✅ Zero dependencies beyond bash + POSIX tools

---

## 15. References

### Basenv Analysis

- oraenv.ksh: Wrapper with change detection
- oraenv.tvdp: Perl-based environment generator  
- BELIB.pm: Core parsing functions
- oratab format: Standard Oracle inventory
- sidtab format: Extended SID metadata
- orahometab format: Oracle home registry

### oradba Current Implementation

- oradba_homes.sh: Home management tool
- oradba.sh env: Environment command
- Configuration hierarchy: core → standard → local → customer
