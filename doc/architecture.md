<!-- markdownlint-disable MD013 -->
# oradba Architecture

## Overview

oradba is a professional Oracle Database administration toolset built on a modular, library-based architecture. The system evolved through multiple phases:

- **Phase 1-4** (v0.19.0-v0.22.0): Configuration system with parsing, validation, and management
- **v1.0.0**: Modular library system with 6 specialized libraries
- **v1.2.2+**: Registry API and Plugin System for unified Oracle product management

## System Architecture

![OraDBA System Architecture](images/architecture-system.png)

The OraDBA system consists of multiple layers working together:

- **Entry Points**: oraenv.sh wrapper, oradba_env.sh builder, oradba_homes.sh manager
- **Registry API** (v1.2.2+): Unified access to oratab and oradba_homes.conf with consistent interface
- **Plugin System** (v1.2.2+): Product-specific plugins for database, datasafe, client, iclient, oud
- **Environment Management Libraries**: Parser, Builder, Validator, Config Manager, Status Display, Change Tracker
- **Core Libraries**: oradba_common.sh (logging/utilities), oradba_db_functions.sh, oradba_aliases.sh
- **Configuration System**: 6-level hierarchical configuration (core → standard → local → customer → SID → runtime)
- **Oracle Integration**: oratab, oradba_homes.conf, Oracle instances, listeners, PDBs

### Interactive Architecture Diagrams

For detailed visual documentation of workflows and component interactions, see the **[Architecture Diagrams Index](images/README.md)**:

- **[Configuration System](images/config-workflow-highlevel.md)** - 5-layer hierarchy and loading flow
- **[oraenv Workflow](images/oraenv-workflow-highlevel.md)** - Environment setup (interactive/non-interactive)
- **[oraup Workflow](images/oraup-workflow-highlevel.md)** - Status display with Registry API integration
- **[Plugin System](images/plugin-system.md)** - 8-function interface and lifecycle

These Mermaid diagrams are interactive and render automatically in VS Code, GitHub, and modern documentation sites.

## Core Components

### 0. Registry API and Plugin System (v1.2.2+)

#### Registry API (oradba_registry.sh)

**Purpose**: Unified interface for accessing Oracle installation metadata from both oratab and oradba_homes.conf.

**Key Features**:

- Single API for all Oracle installations regardless of source
- Consistent pipe-delimited format: `type|name|home|version|flags|order|alias|desc`
- Efficient querying by name, type, or all entries
- Product type detection with plugin integration
- Supports databases (from oratab) and other Oracle products (from oradba_homes.conf)

**Core Functions**:

```bash
# Get all Oracle installations (databases + other products)
oradba_registry_get_all

# Get specific installation by name (SID or Home name)
oradba_registry_get_by_name "ORCLCDB"

# Get all installations of a specific type
oradba_registry_get_by_type "database"

# Get only database entries (from oratab)
oradba_registry_get_databases

# Extract specific field from entry
oradba_registry_get_field "ORCLCDB" "home"
```

**Output Format**:

```text
database|ORCLCDB|/u01/app/oracle/product/23/dbhomeFree|23.6.0|N|1||Oracle 23ai Database
client|client19|/u01/app/oracle/product/19/client|19.0.0||2|client19|Oracle 19c Client
datasafe|dsconn1|/u01/app/oracle/dsconn1|N/A||3||Data Safe Connector
```

**Benefits**:

- Eliminates duplicate parsing logic across 20+ files
- Single source of truth for Oracle installation data
- Easy to query and filter installations
- Consistent format regardless of source (oratab vs oradba_homes.conf)

#### Plugin System

**Purpose**: Product-specific behavior encapsulation with consistent interface.

**Supported Products** (5 plugins):

1. **database_plugin.sh** - Oracle Database (RDBMS)
2. **datasafe_plugin.sh** - Data Safe On-Premises Connectors
3. **client_plugin.sh** - Oracle Full Client
4. **iclient_plugin.sh** - Oracle Instant Client
5. **oud_plugin.sh** - Oracle Unified Directory

**Plugin Interface** (8 required functions):

```bash
# Auto-detect installations of this product type
plugin_detect_installation()

# Validate that a path is a valid installation
plugin_validate_home "$oracle_home"

# Adjust ORACLE_HOME if needed (e.g., DataSafe oracle_cman_home)
plugin_adjust_environment "$oracle_home"

# Check if instance/service is running
plugin_check_status "$oracle_home" "$instance_name"

# Get product metadata (version, edition, etc.)
plugin_get_metadata "$oracle_home"

# Should this product show listener status?
plugin_should_show_listener  # Returns 0 (yes) or 1 (no)

# Discover instances for this Oracle Home
plugin_discover_instances "$oracle_home"

# Does this product support SID aliases?
plugin_supports_aliases  # Returns 0 (yes) or 1 (no)
```

**Plugin Architecture Benefits**:

- **Encapsulation**: Product-specific logic in dedicated plugins
- **Consistency**: All plugins implement same interface
- **Extensibility**: Easy to add new product types
- **Testability**: Each plugin independently tested (99 tests total)
- **Maintainability**: Changes to one product don't affect others

**Example - DataSafe Plugin**:

The DataSafe plugin consolidates logic that was duplicated across 8+ files:

```bash
# Adjusts ORACLE_HOME from base path to oracle_cman_home
plugin_adjust_environment() {
    local base_path="$1"
    if [[ -d "${base_path}/oracle_cman_home" ]]; then
        echo "${base_path}/oracle_cman_home"
    else
        echo "${base_path}"
    fi
}

# Uses explicit environment for cmctl (fixes Bug #83)
plugin_check_status() {
    local cman_home=$(plugin_adjust_environment "$1")
    ORACLE_HOME="${cman_home}" \
    LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
    "${cman_home}/bin/cmctl" status 2>/dev/null
}
```

**Integration Points**:

- Registry API uses plugins for product type detection
- oraenv.sh uses registry API for unified installation lookup
- Environment builder uses plugins for product-specific adjustments
- Status checker uses plugins for service status verification

### 1. Environment Management

#### oraenv.sh Wrapper

**Purpose**: Lightweight wrapper that calls oradba_env.sh for environment setup.

**Key Features**:

- Argument parsing and validation
- Calls oradba_env.sh with SID or Oracle Home name
- Minimal logic - delegates to main builder
- Maintains compatibility with existing workflows

#### oradba_env.sh - Main Environment Builder

**Purpose**: Build complete Oracle environment using Environment Management libraries.

**Key Features**:

- Load and coordinate Environment Management libraries
- Parse hierarchical configuration files
- Build Oracle environment (PATH, LD_LIBRARY_PATH, etc.)
- Validate Oracle installations
- Generate aliases with coexistence mode support
- Display environment status

**Flow**:

![oraenv.sh Execution Flow](images/oraenv-flow.png)

The execution flow shows:

1. Wrapper receives SID/Home name
2. Load Environment Management libraries
3. Parser merges 6 configuration levels
4. Builder constructs environment variables
5. Validator checks Oracle installation
6. Status display shows summary

### 2. Environment Management Library System

![Environment Management Library Architecture](images/phase1-3-libraries.png)

#### Phase 1: Configuration Parser (oradba_env_parser.sh)

**Purpose**: Parse and merge hierarchical configuration files.

**Key Functions**:

- `parse_config_file` - Parse individual config file
- `merge_configs` - Merge multiple configurations
- `resolve_variables` - Resolve variable references

**Configuration Hierarchy**:

1. oradba_core.conf (core system settings)
2. oradba_standard.conf (standard Oracle paths)
3. oradba_local.conf (auto-detected local settings)
4. oradba_customer.conf (site-specific customizations)
5. sid.SID.conf or sid._DEFAULT_.conf (database-specific)
6. Environment variables (highest priority)

#### Phase 2: Environment Builder (oradba_env_builder.sh)

**Purpose**: Build Oracle environment from parsed configuration.

**Key Functions**:

- `build_oracle_env` - Construct complete environment
- `derive_oracle_base` - Auto-derive ORACLE_BASE from ORACLE_HOME
- `construct_path` - Build PATH with Oracle binaries
- `set_tns_admin` - Configure TNS_ADMIN

#### Phase 3: Validation & Management

**oradba_env_validator.sh**:

- `validate_oracle_home` - Check ORACLE_HOME exists and is valid
- `detect_product_type` - Identify product types (delegates to plugin system):
  - **database**: Oracle Database (rdbms/ directory, oracle binary)
  - **datasafe**: Data Safe Connector (oracle_cman_home/, cmctl)
  - **client**: Full Client (sqlplus, network/admin, no rdbms/)
  - **iclient**: Instant Client (libclntsh.so, no bin/ directory)
  - **oud**: Oracle Unified Directory (setup, oudBase, OpenDJ.jar)
  - **grid**: Grid Infrastructure (crsctl, asmcmd)
  - **wls**: WebLogic Server
- `detect_version` - Determine Oracle version
- Uses **plugin system** for product-specific validation and detection

**oradba_env_config.sh**:

- `get_config_value` - Retrieve configuration setting
- `set_config_value` - Update configuration

**oradba_env_status.sh**:

- `show_environment` - Display current environment
- `show_config_sources` - Show which configs were loaded
- `oradba_check_db_status` - Check database status (OPEN/MOUNTED/etc.)
- `oradba_check_listener_status` - Check listener status
- `oradba_check_datasafe_status` - Check Data Safe connector status (cmctl)

**oradba_env_changes.sh**:

- `oradba_check_config_changes` - Detect configuration changes
- `oradba_auto_reload_on_change` - Auto-reload on changes

### 3. Oracle Homes Management (oradba_homes.sh)

**Purpose**: Manage multiple Oracle installations through oradba_homes.conf.

**Key Features**:

- Register Oracle Homes with metadata (name, path, type, version, alias)
- List and query registered homes  
- Export/import configuration for backup and migration
- Support for different product types:
  - **RDBMS**: Oracle Database (Standard/Enterprise Edition)
  - **CLIENT**: Full Oracle Client with admin tools
  - **ICLIENT**: Oracle Instant Client (lightweight, no bin directory)
  - **GRID**: Grid Infrastructure (CRS/ASM)
  - **ASM**: Automatic Storage Management
  - **DATASAFE**: Data Safe On-Premises Connectors (uses oracle_cman_home)
  - **OUD**: Oracle Unified Directory
  - **WLS**: WebLogic Server
  - **OMS**: Oracle Management Server

**Configuration File** (`oradba_homes.conf`):

```text
# NAME:PATH:TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION
DBHOMEFREE:/u01/app/oracle/product/23/dbhomeFree:database:1:rdbms23:Oracle 23ai Free:2326
DBHOME19:/u01/app/oracle/product/19/dbhome_1:database:2:rdbms19:Oracle 19c:1920
```

### 4. Common Libraries

**oradba_common.sh** - Core utilities (1800+ lines, 130+ functions):

- **Logging**: `oradba_log()` with levels (DEBUG, INFO, WARN, ERROR)
- **Validation**: `verify_oracle_env()`, `command_exists()`
- **Oracle Utilities**: `parse_oratab()`, `detect_oracle_version()`, `derive_oracle_base()`
- **Configuration**: `get_oratab_path()`, `get_oracle_homes_path()`
- **Display**: `show_config()`, `show_sqlpath()`, `show_path()`

**oradba_db_functions.sh** - Database operations:

- Database start/stop/status
- Listener management
- Session management
- Query execution helpers

**oradba_aliases.sh** - Safe alias generation:

- `safe_alias()` - Respects coexistence mode
- Standard aliases (sq, rmanc, cdh, taa, via, etc.)
- PDB-specific aliases for multitenant databases
- Coexistence with TVD BasEnv

### 5. Configuration System

**Hierarchy**:

![Configuration Hierarchy](images/config-hierarchy.png)

Configuration flows through six levels, processed by Environment Management libraries:

1. **Core** (`oradba_core.conf`) - System defaults, installation paths
2. **Standard** (`oradba_standard.conf`) - Standard Oracle paths and settings
3. **Local** (`oradba_local.conf`) - Auto-detected local settings, coexistence mode
4. **Customer** (`oradba_customer.conf`) - Site-specific customizations
5. **SID** (`sid.SID.conf` or `sid._DEFAULT_.conf`) - Database-specific settings
6. **Runtime** - Environment variables and command-line arguments (highest priority)

**Processing Flow**:

1. Parser (oradba_env_parser.sh) reads and merges all 6 levels
2. Builder (oradba_env_builder.sh) constructs environment from merged config
3. Validator (oradba_env_validator.sh) verifies Oracle installation

### 6. Installation System

**Build Process**:

![Installation Process](images/installation-flow.png)

The installation system creates a self-contained, self-extracting installer with embedded source files.

## Directory Structure

```text
oradba/
├── src/                    # Distribution files
│   ├── bin/               # Executable scripts
│   ├── lib/               # Libraries
│   │   ├── plugins/       # Product-specific plugins (v1.2.2+)
│   │   │   ├── plugin_interface.sh    # Plugin interface definition
│   │   │   ├── database_plugin.sh     # Oracle Database
│   │   │   ├── datasafe_plugin.sh     # Data Safe Connectors
│   │   │   ├── client_plugin.sh       # Full Client
│   │   │   ├── iclient_plugin.sh      # Instant Client
│   │   │   └── oud_plugin.sh          # Oracle Unified Directory
│   │   ├── oradba_registry.sh         # Registry API (v1.2.2+)
│   │   ├── oradba_common.sh           # Core utilities
│   │   ├── oradba_env_parser.sh       # Configuration parser
│   │   ├── oradba_env_builder.sh      # Environment builder
│   │   ├── oradba_env_validator.sh    # Validation
│   │   └── ... (other libraries)
│   ├── etc/               # Configuration
│   ├── sql/               # SQL scripts
│   ├── rcv/               # RMAN scripts
│   ├── templates/         # Templates
│   └── doc/               # User documentation
├── scripts/               # Build and utility scripts
├── tests/                 # Test suite
│   ├── test_database_plugin.bats      # Database plugin tests (16 tests)
│   ├── test_datasafe_plugin.bats      # DataSafe plugin tests (17 tests)
│   ├── test_client_plugin.bats        # Client plugin tests (12 tests)
│   ├── test_iclient_plugin.bats       # Instant Client plugin tests (15 tests)
│   ├── test_oud_plugin.bats           # OUD plugin tests (15 tests)
│   ├── test_plugin_interface.bats     # Interface compliance (24 tests)
│   └── ... (892+ core tests)
├── doc/                   # Developer documentation
└── .github/               # CI/CD workflows
```

## Data Flow

### Registry API and Plugin Integration

```text
┌─────────────────────────────────────────────────────────────────┐
│                        User Request                              │
│              (SID name or Oracle Home name)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Registry API Layer                            │
│                 (oradba_registry.sh)                            │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  get_all()   │  │get_by_name() │  │get_by_type() │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          └──────────────────┴──────────────────┘
                             │
          ┌──────────────────┴──────────────────┐
          │                                     │
          ▼                                     ▼
┌──────────────────┐                 ┌──────────────────┐
│     oratab       │                 │ oradba_homes.conf│
│   (Databases)    │                 │  (Other Products)│
└────────┬─────────┘                 └────────┬─────────┘
         │                                     │
         └──────────────────┬──────────────────┘
                            │
                            ▼
         ┌─────────────────────────────────────┐
         │    Product Type Detection            │
         │    (via Plugin System)               │
         └─────────┬───────────────────────────┘
                   │
     ┌─────────────┴─────────────┬─────────────┬─────────────┐
     │                           │             │             │
     ▼                           ▼             ▼             ▼
┌─────────┐   ┌──────────┐  ┌────────┐  ┌─────────┐  ┌─────────┐
│database_│   │datasafe_ │  │client_ │  │iclient_ │  │  oud_   │
│plugin.sh│   │plugin.sh │  │plugin.sh│ │plugin.sh│  │plugin.sh│
└────┬────┘   └────┬─────┘  └────┬───┘  └────┬────┘  └────┬────┘
     │             │             │           │            │
     │  ┌──────────┴─────────────┴───────────┴────────────┘
     │  │          Plugin Interface (8 functions)
     │  │  • validate_home()    • check_status()
     │  │  • adjust_environment() • discover_instances()
     │  │  • get_metadata()      • should_show_listener()
     │  └──• supports_aliases()  • detect_installation()
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│              Unified Oracle Environment                          │
│  • ORACLE_HOME (adjusted if needed)                            │
│  • ORACLE_SID                                                   │
│  • Product-specific environment variables                       │
│  • Status information                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Environment Setup Sequence

![Configuration Loading Sequence](images/config-sequence.png)

The environment setup follows a structured, library-based sequence:

1. **Wrapper** (oraenv.sh) receives SID or Oracle Home name
2. **Registry API** (oradba_registry.sh) queries oratab and oradba_homes.conf for unified installation data
3. **Plugin System** detects product type and validates Oracle Home
4. **Main Builder** (oradba_env.sh) coordinates the process
5. **Parser** (oradba_env_parser.sh) loads and merges 6 configuration levels
6. **Builder** (oradba_env_builder.sh) constructs environment with plugin adjustments
7. **Validator** (oradba_env_validator.sh) checks ORACLE_HOME using plugins
8. **Status** (oradba_env_status.sh) displays environment summary with plugin status checks
9. **Aliases** (oradba_aliases.sh) generates database and PDB shortcuts

### Configuration Processing Pipeline

```text
Config Files → Parser → Merged Config → Builder → Environment Variables → Validator → Active Environment
```

The parser reads from multiple sources (6 config files), resolves variable references, and produces a single merged configuration. The builder uses this to construct the Oracle environment, which the validator then verifies.

## Design Principles

1. **Library-Based Architecture**: Environment Management libraries provide modular, testable components
2. **Registry API** (v1.2.2+): Single source of truth for Oracle installation metadata
3. **Plugin System** (v1.2.2+): Product-specific logic encapsulated in dedicated plugins
4. **Separation of Concerns**: Parser, Builder, Validator, Registry, Plugins have distinct responsibilities
5. **Hierarchical Configuration**: 6-level override system provides flexibility without complexity
6. **Auto-Detection**: Intelligently derives ORACLE_BASE, product type, version via plugins
7. **Validation First**: Extensive checking before environment activation using plugin validators
8. **Coexistence**: Safe operation alongside TVD BasEnv via safe_alias()
9. **Comprehensive Testing**: 99 plugin tests + 892 core tests ensure reliability
10. **Professional Logging**: Structured logging with oradba_log() throughout

## Key Features

- **Registry API** (v1.2.2+): Unified interface for oratab and oradba_homes.conf access
- **Plugin System** (v1.2.2+): 5 product plugins with consistent 8-function interface
- **Oracle Homes Management**: Track multiple Oracle installations with metadata
- **Product Type Detection**: Automatic identification via plugin validation
- **Export/Import**: Backup and migrate Oracle Homes configuration  
- **Status Checking**: Query database, listener, ASM, OUD, WebLogic, DataSafe status via plugins
- **Change Detection**: Auto-reload on configuration file changes
- **PDB Support**: Auto-generate aliases for multitenant databases
- **Smart Test Selection**: Fast CI with 60-second test runs
- **Comprehensive Plugin Tests**: 99 plugin tests validate all product types
- **Self-Extracting Installer**: Single-file distribution with embedded payload

## References

- [development.md](development.md) - Development guide
- [README.md](README.md) - Developer documentation index
- [../README.md](../README.md) - Main project documentation
- [Environment Management Design](oradba-env-design.md) - Detailed Environment Management library architecture
