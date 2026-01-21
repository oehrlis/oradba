# Consolidated Release Notes: v0.10.0 - v0.18.5

This document consolidates major OraDBA releases from v0.10.0 through v0.18.5,
covering the period before the v0.19.0 architecture refactoring that introduced
the Registry API and Plugin System.

## Purpose

These consolidated release notes preserve historical context for OraDBA's
evolution through multiple major milestones. Each section below documents
significant features and changes that shaped OraDBA into a comprehensive Oracle
Database administration toolkit.

**Note**: For complete change history including all patch releases (v0.10.1-v0.18.4), see:

- [CHANGELOG.md](../../CHANGELOG.md) - Complete change log
- [GitHub Releases](https://github.com/oehrlis/oradba/releases) - All releases with downloads

---

## Milestone Releases

### v0.18.5 (2026-01-13) - Pre-1.0 Final Release

**Release Type:** Minor Release  
**Compatibility:** Backward compatible with v0.18.x

#### Overview

Final pre-architecture-refactor release addressing configuration and environment
management improvements including template organization, intelligent ORACLE_BASE
derivation, Oracle version detection, and better handling of non-root environments.

#### Key Features

##### Template File Organization

- Moved `oradba_homes.conf.template` from `src/etc/` to `src/templates/etc/`
- Consistent with other configuration templates
- Improved discoverability and organization

##### Intelligent ORACLE_BASE Derivation

- New `derive_oracle_base()` function walks up directory tree
- Searches for Oracle base indicators: `product/`, `oradata/`, `oraInventory/`
- Correctly handles complex paths like `/appl/oracle/product/26.0.0/client`
- Falls back to traditional two-levels-up method if needed

##### Oracle Version Detection

- Added VERSION field to `oradba_homes.conf` format
- Auto-detection from sqlplus, OPatch, inventory XML, or path parsing
- Format: `NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION`
- Version values: `AUTO` (dynamic), `XXYZ` (specific), `ERR` (non-database products)

##### Non-Root ORATAB Access

- Dynamic `ORATAB_FILE` determination via `get_oratab_path()`
- Priority: `ORADBA_ORATAB` → `/etc/oratab` → `/var/opt/oracle/oratab` → `${ORADBA_BASE}/etc/oratab` → `${HOME}/.oratab`
- Fixed `vio` alias to work when `/etc/oratab` not accessible

##### Non-Database Home Support

- Enhanced `oraup.sh` to handle non-database Oracle Homes
- Works for client, datasafe, oud, weblogic, oms, emagent products

#### Technical Details

**New Functions:**

- `derive_oracle_base()` - Intelligent ORACLE_BASE derivation from ORACLE_HOME
- `detect_oracle_version()` - Multi-method version detection
- `get_oracle_home_version()` - Get version for named home (handles AUTO detection)

**Updated Functions:**

- All Oracle Home parsing functions updated for VERSION field
- `parse_oracle_home()` returns 7 fields instead of 6
- Backward compatibility maintained for old 6-field format

---

### v0.18.0 (2026-01-10) - Oracle Homes Support

**Release Type:** Major Feature Release  
**Focus:** Multi-Product Oracle Environment Management

#### Overview

Extends OraDBA beyond database-only management to support all Oracle products
including Oracle Unified Directory (OUD), WebLogic Server, Oracle Client,
Enterprise Manager, Data Safe connectors, and more.

#### Key Features

##### Oracle Homes Infrastructure

Core framework for managing non-database Oracle products:

**Configuration File:** `${ORADBA_BASE}/etc/oradba_homes.conf`

```bash
# Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:DESCRIPTION
OUD12:/u01/app/oracle/product/12.2.1.4/oud:oud:10:Oracle Unified Directory 12c
WLS14:/u01/app/oracle/product/14.1.1.0/wls:weblogic:20:WebLogic Server 14c
CLIENT19:/u01/app/oracle/product/19.0.0.0/client:client:30:Oracle Client 19c
```

**Supported Product Types:**

- `database` - Oracle Database (existing)
- `oud` - Oracle Unified Directory
- `client` - Oracle Client
- `weblogic` - WebLogic Server
- `oms` - Enterprise Manager OMS
- `emagent` - Enterprise Manager Agent
- `datasafe` - Oracle Data Safe

**Core Functions:**

- `get_oracle_homes_path()` - Configuration file location
- `parse_oracle_home()` - Parse home entry by name
- `list_oracle_homes()` - List all homes sorted by order
- `detect_product_type()` - Auto-detect type from filesystem
- `set_oracle_home_environment()` - Set product-specific variables
- `is_oracle_home()` - Distinguish Oracle Homes from database SIDs

##### Unified Environment Setup

Enhanced `oraenv.sh` for both databases and Oracle products:

```bash
# Setup database (existing)
source oraenv.sh DB19C

# Setup OUD instance
source oraenv.sh OUD12

# Interactive menu shows both
source oraenv.sh
```

**Interactive Menu:**

```text
Available Oracle Environments:
────────────────────────────────────────────────────
Oracle Homes:
  [oud]      OUD12       - Oracle Unified Directory 12c
  [weblogic] WLS14       - WebLogic Server 14c
  [client]   CLIENT19    - Oracle Client 19c

Database Instances:
  DB19C      (/u01/app/oracle/product/19.3.0/dbhome_1) : Y
  ORCL       (/u01/app/oracle/product/19.0.0/dbhome_2) : Y
```

##### Management CLI Tool

New `oradba_homes.sh` command-line tool:

```bash
# List all registered homes
oradba_homes.sh list

# Filter by product type
oradba_homes.sh list --type oud

# Add new Oracle Home
oradba_homes.sh add --name WLS14 --path /path/to/wls --type weblogic

# Auto-discover under $ORACLE_BASE/product
oradba_homes.sh discover --auto-add

# Validate configuration
oradba_homes.sh validate
```

**Features:**

- Auto-detection of product types from filesystem markers
- Interactive mode with prompts and validation
- Non-interactive mode for CI/CD environments
- Dry-run mode for preview
- Automatic backup before removal

#### Use Cases

**Multi-Product Environments:**

- Register all Oracle products in single configuration
- Switch environments seamlessly
- Unified management interface

**Auto-Discovery:**

- Fresh installation detection
- Automatic registration of discovered products
- Validation of all configurations

**CI/CD Integration:**

- Non-interactive discovery and validation
- Automated testing workflows

#### Testing

**Comprehensive Test Coverage:**

- Unit tests (28 tests): Parsing, detection, environment setting
- Integration tests (3 tests): Environment setup validation
- Management tool tests (39 tests): All commands tested
- **Total: 70 tests (100% passing)**

---

### v0.17.0 (2026-01-09) - Pre-Oracle Installation Support

**Release Type:** Major Feature Release  
**Focus:** CI/CD and Docker Bootstrap

#### Overview

Introduces Pre-Oracle Installation Support, enabling OraDBA installation and
configuration before Oracle Database is present. Major enhancement for CI/CD
pipelines, Docker multi-stage builds, and phased deployments.

#### Key Features

##### Pre-Oracle Installation

Install OraDBA before Oracle Database exists:

```bash
# User-level installation (no root/Oracle required)
./oradba_install.sh --user-level

# Base directory installation
./oradba_install.sh --base /opt

# Silent mode for automation
./oradba_install.sh --user-level --silent
```

**New Installation Parameters:**

- `--user-level`: Install to ~/oradba (no root/Oracle required)
- `--base PATH`: Install to PATH/local/oradba
- `--prefix PATH`: Direct installation path
- `--dummy-home PATH`: Custom dummy ORACLE_HOME for testing
- `--silent`: Non-interactive mode (no prompts)

**Temporary oratab Management:**

- Creates `${ORADBA_BASE}/etc/oratab` when system oratab missing
- Ready for post-Oracle linking
- Documents temporary nature in file header

##### Centralized oratab Priority System

New `get_oratab_path()` function provides consistent oratab detection:

**Priority Order:**

1. `$ORADBA_ORATAB` - Explicit override
2. `/etc/oratab` - System default (Linux/most Unix)
3. `/var/opt/oracle/oratab` - Alternative location (Solaris/AIX)
4. `${ORADBA_BASE}/etc/oratab` - Temporary (pre-Oracle)
5. `${HOME}/.oratab` - User fallback

**Integration:**

- All oratab-related functions use centralized detection
- Updated: `is_dummy_sid()`, `parse_oratab()`, `generate_sid_lists()`
- Updated: `oraenv.sh`, `oraup.sh` for consistent behavior

##### Setup Helper Command

New `oradba_setup.sh` utility:

```bash
# Link to system oratab after Oracle installation
oradba_setup.sh link-oratab

# Validate installation health
oradba_setup.sh check

# Display current configuration
oradba_setup.sh show-config
```

**Features:**

- Automatic backup before modifications
- Force mode for overwriting
- Comprehensive validation checks
- Color-coded output

##### No-Oracle Mode

Graceful degradation when Oracle not detected:

```bash
# Environment with no Oracle
source oraenv.sh
echo $ORADBA_NO_ORACLE_MODE  # Shows: true

# Status display with guidance
oraup.sh
# Shows: "No Oracle databases found" with setup instructions
```

##### Context-Aware Validation

Enhanced `oradba_validate.sh` with installation mode detection:

- Detects pre-Oracle vs Oracle Installed mode
- Context-aware Oracle environment checks
- Tailored next-steps guidance
- No false failures in pre-Oracle scenarios

#### Use Cases

**CI/CD Pipeline Bootstrap:**

```yaml
jobs:
  setup:
    steps:
      - name: Install OraDBA (Pre-Oracle)
        run: bash install.sh --user-level --silent
      - name: Install Oracle Database
        run: # Oracle installation steps
      - name: Link OraDBA
        run: ~/oradba/bin/oradba_setup.sh link-oratab
```

**Docker Multi-Stage Build:**

```dockerfile
FROM oraclelinux:8-slim AS oradba-prep
RUN useradd -m -u 54321 oracle
USER oracle
RUN curl -L https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh | \
    bash -s -- --user-level --silent

FROM oradba-prep AS oracle-db
USER root
# ... install Oracle Database ...
USER oracle
RUN /home/oracle/oradba/bin/oradba_setup.sh link-oratab
```

**Phased Deployment:**

```bash
# Day 1: Prepare system
./oradba_install.sh --base /opt

# Day 2: Install Oracle
install_oracle.sh
oradba_setup.sh link-oratab
```

#### Testing

- 9 new tests for oratab priority system
- All existing tests pass with pre-Oracle mode
- Comprehensive validation for all scenarios

---

### v0.15.0 (2026-01-07) - Extension System Enhancements

**Release Type:** Minor Feature Release  
**Focus:** Extension Template Management & Integrity Checking

#### Overview

Introduces significant improvements to the extension system including automated
template management from GitHub, customizable integrity checking with
`.checksumignore` support, and streamlined build processes.

#### Key Features

##### Extension Template Repository Migration

Templates moved to dedicated GitHub repository:

- **New Repository:** [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)
- **Automated Downloads:** Build process downloads latest template
- **Version Caching:** Templates cached in `templates/oradba_extension/`
- **Version Tracking:** Template version stored in `.version` file
- **Reduced Duplication:** Eliminates template duplication

**Workflow:**

1. Build queries GitHub API for latest release
2. Compares with cached version
3. Downloads tarball if newer or missing
4. Includes template in distribution

##### Checksum Exclusion Support

New `.checksumignore` file for customizable integrity checking:

```text
# Runtime files
cache/
*.tmp

# Credentials
keystore/
*.key

# User-specific configs
etc/*.local
```

**Features:**

- Per-extension configuration
- Glob pattern support (`*`, `?`, directory matching)
- Default exclusions: `.extension`, `.checksumignore`, `log/`
- Common use cases: runtime files, credentials, user configs

**Implementation:**

- `get_checksum_exclusions()` function in `oradba_version.sh`
- Pattern parsing converts globs to awk regex
- Backward compatible (works without `.checksumignore`)

##### Build Process Enhancements

New make targets:

- `make download-extensions` - Manual template download
- `make clean-extensions` - Clean downloaded templates
- Automated version checking
- Integrated cleanup in `make clean-all`

#### Technical Details

**Files Changed:**

- `scripts/build_installer.sh` - GitHub template download logic
- `src/bin/oradba_extension.sh` - Updated template path
- `src/bin/oradba_version.sh` - `.checksumignore` support
- `Makefile` - New extension management targets

**Template Location Change:**

| Old Path                                                      | New Path                                               |
|---------------------------------------------------------------|--------------------------------------------------------|
| `src/templates/extensions/customer-extension-template.tar.gz` | `templates/oradba_extension/extension-template.tar.gz` |

#### Migration

No migration required. To use new features:

1. **Add `.checksumignore` to extensions:**

   ```bash
   cat > .checksumignore << 'EOF'
   log/
   keystore/
   *.tmp
   EOF
   ```

2. **Update custom templates** (reference oradba_extension v0.2.0)

#### Testing

- ✅ All 52 existing extension tests pass
- ✅ Template download verified
- ✅ `.checksumignore` in template
- ✅ Pattern matching validated
- ✅ Backward compatibility confirmed

---

### v0.14.0 (2026-01-05) - Critical RMAN Bug Fix + Features

**Release Type:** Critical Bug Fix + Feature Release  
**Priority:** HIGH - All users with automated RMAN backups should upgrade

#### 🔴 CRITICAL UPDATE

**Problem:** RMAN always returns exit code 0, even on errors. The wrapper used
`tee` which masked the exit code, causing all backups to be reported as successful
regardless of outcome.

**Impact:** Production backup failures going undetected, compromising disaster recovery.

**Solution:** Multi-layer error detection:

1. Capture RMAN exit code before pipe: `${PIPESTATUS[0]}`
2. Pattern matching for `RMAN-00569` error in log file
3. Fail if either exit code non-zero OR error pattern found
4. Always save processed .rcv script for troubleshooting

#### Key Features

##### Backup Path Configuration

Configure backup destination per SID or override via CLI:

```bash
# Configuration file (per-SID)
export RMAN_BACKUP_PATH="/backup/prod"

# CLI override
oradba_rman.sh --sid PROD --rcv backup_full.rcv --backup-path /backup/prod_daily

# Template usage
BACKUP DATABASE FORMAT '<BACKUP_PATH>/%d_full_%U.bkp';
```

##### Enhanced Dry-Run Mode

Comprehensive preview without executing RMAN:

```bash
oradba_rman.sh --sid FREE --rcv backup_full.rcv --dry-run
```

Features:

- Saves processed script to log directory
- Displays complete generated RMAN script
- Shows exact command that would be executed
- Perfect for debugging template processing

##### Automatic Script Preservation

Every execution saves processed RMAN script:

- Location: Same as RMAN log file
- Naming: `<script>_YYYYMMDD_HHMMSS.rcv`
- Benefits: Post-execution troubleshooting, audit trail

##### Cleanup Control

```bash
oradba_rman.sh --sid FREE --rcv backup_full.rcv --no-cleanup
```

Preserves temp directory for debugging parallel execution.

##### Extension Checksum Verification

New `check_extension_checksums()` function:

```bash
# Create checksum file
find . -type f ! -name '.*.checksum' -exec sha256sum {} \; > .customer.checksum

# Verify integrity
oradba_version.sh --verify
```

Features:

- Auto-discovers `.{extension}.checksum` files
- Verifies each file against current state
- Color-coded reporting: [OK], [X] with details

#### Information Display Enhancements

**Configuration Viewer (`cfg` alias):**

```bash
$ cfg  # or: show_config

OraDBA Configuration Hierarchy:
================================
1. Core Configuration:
   [[OK] loaded] /opt/oradba/etc/oradba_core.conf
...
```

**PATH Viewer (`pth` alias):**

```bash
$ pth  # or: show_path

Current PATH:
=============
1. /opt/oradba/bin
2. /u01/app/oracle/product/19c/dbhome_1/bin
...
```

#### Logging Infrastructure

Core logging infrastructure with persistent file logging:

**New Functions:**

1. `init_logging()` - Initialize main log directory
2. `init_session_log()` - Create per-session log
3. Enhanced `oradba_log()` - Improved logging with caller info

**Usage:**

```bash
init_logging
init_session_log
oradba_log INFO "Starting backup process"
oradba_log ERROR "Backup failed"
```

**Function Rename:** `log()` → `oradba_log()` to avoid conflicts with `log` alias

#### Bug Fixes

**SID Config Auto-Creation:**

- Fixed wrong variable name in `oradba_standard.conf`
- Fixed wrong regex pattern in `oradba_common.sh`
- Fixed logic error after v0.13.5 refactoring

#### Standalone Prerequisites Checker

`oradba_check.sh` now available as standalone release artifact:

```bash
curl -L -o oradba_check.sh https://github.com/oehrlis/oradba/releases/download/v0.14.0/oradba_check.sh
chmod +x oradba_check.sh
./oradba_check.sh
```

#### Testing

- 9 new BATS tests for RMAN error detection
- 23 comprehensive tests for logging infrastructure
- All tests pass

---

### v0.13.0 (2026-01-02) - RMAN Wrapper Script

**Release Type:** Major Feature Release  
**Focus:** Enterprise RMAN Automation

#### Overview

Introduces comprehensive RMAN wrapper script with template processing, parallel
execution, and automated notifications for enterprise-grade backup management.

#### Key Features

RMAN Wrapper Script

Comprehensive shell wrapper for executing RMAN scripts:

**Template Processing:**

- `<ALLOCATE_CHANNELS>` - Automatic channel allocation
- `<FORMAT>` - Dynamic backup format strings
- `<TAG>` - Dynamic backup tags
- `<COMPRESSION>` - Compression levels (NONE|LOW|MEDIUM|HIGH)

**Parallel Execution:**

- Background jobs method (default)
- GNU parallel support (auto-detected)
- Configurable parallelism level

**Dual Logging:**

- Generic wrapper log in `${ORADBA_LOG}`
- SID-specific RMAN output in `${ORADBA_ORA_ADMIN_SID}/log`

**Email Notifications:**

- Configurable per-SID settings
- Simple integration with mail/sendmail

**SID-Specific Configuration:**

- Location: `${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf`
- Override via command-line arguments

#### Usage Examples

```bash
# Single database backup
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 2

# Custom settings with notification
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --channels 4 \
    --compression HIGH \
    --format "/backup/%d_%T_%U.bkp" \
    --tag MONTHLY_BACKUP \
    --notify dba@example.com

# Dry run
oradba_rman.sh --sid FREE --rcv backup_full.rcv --dry-run
```

#### New Features

**Base Directory Aliases:**

- `cdbase` - Change to `$ORADBA_BASE` directory
- Extension aliases via `cde<name>` pattern

**RMAN Script Convention:**

- `.rcv` - RMAN scripts with template tags (new standard)
- `.rman` - Static RMAN scripts (legacy, still supported)

#### Bug Fixes

**Extension Discovery:**

Fixed critical bug where `oradba_extension.sh list` showed empty extensions:

- Enhanced directory exclusion in `discover_extensions()`
- Properly skips main OraDBA installation directory
- Handles cases where OraDBA installed within `${ORADBA_LOCAL_BASE}`

#### Documentation

- **`src/doc/09-rman-scripts.md`**: Complete RMAN wrapper documentation (comprehensive)
- **`src/rcv/README.md`**: Template system documentation
- Updated main README with RMAN features

#### Testing

- 36 BATS tests (35 passing, 1 skipped)
- Full coverage: Argument parsing, template processing, configuration, parallel execution, dry-run, logging, error handling

---

### v0.12.0 (2026-01-02) - Extension System

**Release Type:** Major Feature Release  
**Focus:** Modular Plugin Architecture

#### Overview

Introduces Extension System, a modular plugin architecture that allows users to
add custom scripts and tools without modifying core OraDBA installation.

#### Key Features

Extension System Architecture

Three core components:

1. **`lib/extensions.sh`**: Core library (550+ lines) with discovery, loading, management
2. **`bin/oradba_extension.sh`**: Management CLI tool (596 lines) with 8 commands
3. **`tests/test_extensions.bats`**: Comprehensive test suite (31 tests)

**Features:**

- **Auto-Discovery:** Discovers extensions in `${ORADBA_LOCAL_BASE}`
- **Directory Structure:** Support for `bin/`, `sql/`, `rcv/`, `etc/`, `lib/`
- **Metadata Files:** Optional `.extension` files in YAML-like format
- **Priority-Based Loading:** Control load order with numeric priorities
- **Configuration Overrides:** Per-extension enable/disable and priority
- **Automatic Integration:** Extensions integrate into PATH, SQLPATH, RMAN paths
- **Navigation Aliases:** Auto-generated `cde<name>` aliases
- **Coexistence Mode:** Extensions respect OraDBA coexistence settings

#### Management Tool

```bash
# List all extensions
oradba_extension.sh list

# Show detailed information
oradba_extension.sh info customer

# Validate extension structure
oradba_extension.sh validate customer

# View enabled/disabled extensions
oradba_extension.sh enabled
oradba_extension.sh disabled
```

**Commands:**

- `list` - Show all extensions with status, version, priority
- `info` - Display detailed extension information
- `validate` - Validate extension structure and configuration
- `validate-all` - Validate all discovered extensions
- `discover` - Show auto-discovered extensions
- `paths` - Display extension search paths
- `enabled` - List only enabled extensions
- `disabled` - List only disabled extensions

#### Configuration Variables

```bash
# Core configuration
ORADBA_AUTO_DISCOVER_EXTENSIONS  # Enable/disable auto-discovery (default: true)
ORADBA_EXTENSION_PATHS           # Colon-separated manual paths
ORADBA_EXTENSIONS_IN_COEXIST     # Load with BasEnv (default: false)
ORADBA_RCV_PATHS                 # RMAN script search paths

# Per-extension overrides
ORADBA_EXT_<NAME>_ENABLED        # Enable/disable specific extension
ORADBA_EXT_<NAME>_PRIORITY       # Override priority
```

#### PATH Integration

Extensions integrated with careful ordering:

1. Core OraDBA (`${ORADBA_BIN}`)
2. Extensions (by priority: high priority loaded last, appears first)
3. Oracle Home (`${ORACLE_HOME}/bin`)
4. System PATH

High-priority extensions can override Oracle tools while respecting core OraDBA commands.

#### Bug Fixes

**Extension Priority Sorting:**

- Fixed ordering so high-priority extensions load last and appear first in PATH

#### Testing

- 31 BATS test cases
- Coverage: Discovery, metadata parsing, priority configuration, PATH integration, validation

#### Migration

No migration required. To start using:

```bash
# Create extension directory
mkdir -p /opt/oracle/local/customer/bin

# Add scripts
cp my_script.sh /opt/oracle/local/customer/bin/
chmod +x /opt/oracle/local/customer/bin/my_script.sh

# Optional: Add metadata
cat > /opt/oracle/local/customer/.extension << EOF
name: customer
version: 1.0.0
priority: 10
description: Customer-specific Oracle tools
EOF

# Source OraDBA
source oraenv.sh
# Extension auto-loaded
```

---

### v0.10.0 (2026-01-01) - Enterprise Service Management & Smart Testing

**Release Type:** Major Feature Release  
**Focus:** Production Service Management & Development Acceleration

#### Overview

Major feature release introducing enterprise-grade Oracle service management and
intelligent test selection system that accelerates development by 67%.

#### Key Features

##### Enterprise Service Management

Complete lifecycle control for Oracle databases and listeners:

**Core Scripts:**

- `oradba_dbctl.sh` - Database lifecycle management
  - Honors `:Y` flag in oratab for auto-start
  - Configurable shutdown timeout (default 180s)
  - Optional PDB opening with `--open-pdbs`
  - Force mode for automation
  - Justification logging for audit trails

- `oradba_lsnrctl.sh` - Listener management
  - Automatic discovery from oratab
  - Multiple listener support
  - Status reporting

- `oradba_services.sh` - Orchestrated management
  - Configurable startup/shutdown order
  - Default: start listeners→databases, stop databases→listeners
  - Unified status reporting

- `oradba_services_root.sh` - Root wrapper
  - Executes as oracle user from root
  - Used by systemd and init.d

**System Integration:**

- systemd unit file (`oradba.service`)
- init.d/chkconfig script for Red Hat and Debian
- Complete installation instructions

**New Aliases (11):**

```bash
# Database: dbctl, dbstart, dbstop, dbrestart
# Listener: lsnrctl, lsnrstart, lsnrstop, lsnrrestart, lsnrstatus
# Combined: orastart, orastop, orarestart, orastatus
```

**Configuration:**

- `oradba_services.conf` for orchestration
- STARTUP_ORDER and SHUTDOWN_ORDER customization
- DB_OPTIONS and LSNR_OPTIONS pass-through

**Testing:**

- 51 BATS automated tests + interactive suite
- Script validation, help output, configuration, templates

##### Smart Test Selection

Intelligent testing that runs only affected tests:

**Performance:**

| Scenario       | Before            | After             | Time Saved      |
|----------------|-------------------|-------------------|-----------------|
| Single script  | 492 tests (8 min) | ~10 tests (1 min) | **7 minutes**   |
| Library change | 492 tests (8 min) | ~50 tests (2 min) | **6 minutes**   |
| Documentation  | 492 tests (8 min) | 3 tests (30 sec)  | **7.5 minutes** |

**Components:**

- `.testmap.yml` - Configuration-driven test mapping
- `scripts/select_tests.sh` - Intelligent selection script
- `doc/smart-test-selection.md` - Complete guide

**Features:**

- Runs only affected tests (492 → 5-50 typical)
- Always-run core tests: installer, version, oraenv
- Pattern matching for flexible selection
- Git-based change detection with fallback
- Configuration-based mapping

**Make Targets:**

```bash
make test              # Smart selection (1-3 min)
make test-full         # All tests (8-10 min)
make test DRY_RUN=1    # Preview selected tests
make pre-commit        # Smart tests + linting (2-4 min)
```

**CI/CD Integration:**

- CI: Smart selection for fast feedback (1-3 min)
- Release: Full suite for quality assurance (8-10 min)

##### Visual Documentation

11 updated diagrams with Mermaid definitions:

1. CI/CD Pipeline
2. Test Strategy
3. Development Workflow
4. Architecture System
5. oraenv.sh Flow
6. Configuration Hierarchy
7. Configuration Sequence
8. Installation Flow
9. Alias Generation
10. Performance Comparison
11. Test Selection Decision

**Formats:**

- Mermaid definitions in `doc/images/source/diagrams-mermaid.md`
- PNG exports updated
- Excalidraw sources for visual editing
- GitHub-renderable and version-controllable

#### Bug Fixes

- **Session Info Query:** Corrected to work in MOUNT and OPEN states
- **Memory Usage Query:** Corrected to work in MOUNT and OPEN states

#### Statistics

- **Files Changed:** 21 files (1,324 insertions, 81 deletions)
- **New Aliases:** 11 service management aliases
- **New Tests:** 51 BATS tests for service management
- **Total Tests:** 492 tests (all passing)
- **Documentation:** 657 lines for service management, 228 lines for smart testing
- **Diagrams:** 11 updated with Mermaid definitions

---

## Patch Release Summary

For detailed changes in patch releases (v0.10.1-v0.18.4), refer to:

- [CHANGELOG.md](../../CHANGELOG.md) - Complete change history
- [GitHub Releases](https://github.com/oehrlis/oradba/releases) - All releases with assets

**Patch releases included:**

- v0.18.x: v0.18.1, v0.18.2, v0.18.3, v0.18.4 (bug fixes, minor improvements)
- v0.14.x: v0.14.1, v0.14.2 (bug fixes, performance improvements)
- v0.13.x: v0.13.1, v0.13.2, v0.13.3, v0.13.4, v0.13.5 (maintenance, bug fixes)
- v0.12.x: v0.12.1 (bug fixes)
- v0.11.x: v0.11.0, v0.11.1 (minor features, bug fixes)
- v0.10.x: v0.10.1, v0.10.2, v0.10.3, v0.10.4, v0.10.5 (maintenance, bug fixes)

---

## Legacy Releases

For releases before v0.10.0 (v0.2.0 - v0.9.5):

- See [CHANGELOG.md](../../CHANGELOG.md)
- See [GitHub Releases](https://github.com/oehrlis/oradba/releases)

---

## Historical Context

OraDBA v0.19.0 (January 21, 2026) represents a complete architectural rewrite with:

- **Registry API**: Unified installation management
- **Plugin System**: 9 product types with standardized interface
- **Environment Builder**: 6 specialized environment libraries

These consolidated release notes (v0.10.0 - v0.18.5) document the evolution
leading to v0.19.0's architecture refactoring. Earlier releases used a different
architecture and are maintained for historical reference only.

---

## Contributors

- Stefan Oehrli ([@oehrlis](https://github.com/oehrlis))

## Resources

- **Repository**: [github.com/oehrlis/oradba](https://github.com/oehrlis/oradba)
- **Documentation**: [OraDBA User Guide](https://oehrlis.github.io/oradba/)
- **Issues**: [GitHub Issues](https://github.com/oehrlis/oradba/issues)
- **Current Release**: [v0.19.0](../v0.19.0.md)

---

**Generated:** January 21, 2026  
**Covers:** OraDBA releases v0.10.0 through v0.18.5
