# OraDBA Repository Inventory — v0.24.11

**Generated:** 2026-06-26\
**Repository:** /Users/stefan.oehrli/Repos/own/oehrlis/oradba\
**Version:** 0.24.11 (from VERSION file and CHANGELOG)\
**Git:** main branch, latest commit `b76fe9c` (2026-06-25)

----------------------------------------------------------------------------------------------------

## 1. Directory Structure (2-3 Levels)

| Path             | Purpose                                              | File Count |
|------------------|------------------------------------------------------|------------|
| `src/bin/`       | Executable CLI scripts and entry points              | 30         |
| `src/lib/`       | Shared library files and plugin system               | 25         |
| `src/etc/`       | Configuration files and templates                    | 10         |
| `src/doc/`       | API documentation and reference                      | 29         |
| `src/sql/`       | SQL scripts for Oracle administration                | 157        |
| `src/templates/` | Installation templates (DBCA, init.d, systemd, etc.) | 14         |
| `doc/`           | User documentation, guides, release notes            | UNKNOWN    |
| `scripts/`       | Build and utility scripts                            | UNKNOWN    |
| `tests/`         | Test suite (manual and automated)                    | UNKNOWN    |
| `build/`         | Build artifacts                                      | UNKNOWN    |
| `dist/`          | Distribution packages                                | UNKNOWN    |

----------------------------------------------------------------------------------------------------

## 2. Shared Libraries (src/lib/)

| File                           | LOC  | Functions | Purpose                                                        |
|--------------------------------|------|-----------|----------------------------------------------------------------|
| `oradba_common.sh`             | 1718 | 29        | Core logging, config loading, oratab parsing, Oracle discovery |
| `oradba_home_discovery.sh`     | 1008 | 15        | Detect and enumerate Oracle ORACLE_HOME installations          |
| `oradba_env_builder.sh`        | 1014 | 18        | Build environment variables from configuration                 |
| `extensions.sh`                | 803  | 18        | Extension system for custom user-defined behavior              |
| `oradba_registry.sh`           | 376  | 8         | Registry API (installation registration and tracking)          |
| `oradba_env_parser.sh`         | 404  | 10        | Parse hierarchical environment declarations                    |
| `oradba_env_validator.sh`      | 425  | 9         | Validate environment settings and detect conflicts             |
| `oradba_env_status.sh`         | 427  | 7         | Query instance/process status                                  |
| `oradba_env_config.sh`         | 399  | 8         | Configuration file management and fallback                     |
| `oradba_db_functions.sh`       | 447  | 10        | Database-specific helper functions                             |
| `oradba_env_changes.sh`        | 255  | 7         | Track and report environment changes                           |
| `oradba_env_output.sh`         | 285  | 5         | Format and display environment information                     |
| `oradba_aliases.sh`            | 277  | 6         | Shell alias definitions and management                         |
| `oradba_database_discovery.sh` | 441  | 5         | Discover databases from oratab and processes                   |
| `oradba_version_metadata.sh`   | 192  | 6         | Version tracking and compatibility metadata                    |

**Total Core Libraries:** 15 files, ~9,471 LOC, 151 exported functions

----------------------------------------------------------------------------------------------------

## 3. Plugin System (src/lib/plugins/)

### 3.1 Plugin Discovery & Loading Mechanism

Plugins are discovered and loaded via explicit sourcing on demand:

- **Discovery pattern:** Scripts grep for plugin files in `${ORADBA_BASE}/lib/plugins/`

- **Load-on-demand:** Each calling script sources plugins based on context

  - `oraenv.sh`: sources `datasafe_plugin.sh` for DataSafe environment setup
  - `oradba_env.sh`: sources `datasafe_plugin.sh` when DataSafe mode enabled
  - `oradba_homes.sh`: iterates plugins with `source "$plugin_file" 2>/dev/null || true`
  - `oraup.sh`: uses `execute_plugin_function_v2` to call plugin functions selectively
  - `oradba_dsctl.sh`: sources `datasafe_plugin.sh` at startup

- **No auto-discovery loader:** No centralized `load_all_plugins.sh` — each script manages its own
  plugin sourcing

- **Interface contract:** All plugins implement 13 core functions (from `plugin_interface.sh`)

### 3.2 Plugin Inventory

| File                  | LOC | Functions | Product Type                                   |
|-----------------------|-----|-----------|------------------------------------------------|
| `plugin_interface.sh` | 406 | 19        | Interface template (13 universal + 6 optional) |
| `datasafe_plugin.sh`  | 888 | 24        | Oracle Data Safe connectivity & environment    |
| `database_plugin.sh`  | 443 | 16        | Oracle Database (core)                         |
| `oud_plugin.sh`       | 481 | 18        | Oracle Unified Directory (LDAP)                |
| `iclient_plugin.sh`   | 462 | 16        | Instant Client                                 |
| `java_plugin.sh`      | 362 | 16        | Java/JDK                                       |
| `client_plugin.sh`    | 313 | 15        | Oracle Client tools                            |
| `weblogic_plugin.sh`  | 300 | 16        | Oracle WebLogic Server                         |
| `emagent_plugin.sh`   | 225 | 16        | Oracle Enterprise Manager Agent                |
| `oms_plugin.sh`       | 225 | 16        | Oracle Management Server                       |

**Total Plugins:** 9 product plugins + 1 interface template, ~4,005 LOC, 158 exported functions

### 3.3 Plugin Interface Specification

All plugins expose 13 universal core functions (from `plugin_interface.sh:60-406`):

1. `plugin_detect_installation()` — Auto-discover installations
2. `plugin_validate_home()` — Validate ORACLE_HOME path
3. `plugin_adjust_environment()` — Adjust paths (e.g., DataSafe appends `/oracle_cman_home`)
4. `plugin_build_base_path()` — Resolve ORACLE_BASE_HOME vs ORACLE_HOME
5. `plugin_build_env()` — Build environment variables
6. `plugin_check_status()` — Query service/instance status
7. `plugin_get_metadata()` — Retrieve installation metadata
8. `plugin_discover_instances()` — Discover instances/domains
9. `plugin_get_instance_list()` — Enumerate instances
10. `plugin_supports_aliases()` — Support SID-like aliases?
11. `plugin_build_bin_path()` — Get PATH components
12. `plugin_build_lib_path()` — Get LD_LIBRARY_PATH components
13. `plugin_get_config_section()` — Get config section name

----------------------------------------------------------------------------------------------------

## 4. Entry Points (src/bin/)

### 4.1 Primary Entry Points

| Script              | Purpose                             | Accepts Input                                  | `set -euo pipefail` |
|---------------------|-------------------------------------|------------------------------------------------|---------------------|
| `oraenv.sh`         | Environment setup (must be sourced) | ORACLE_SID, flags                              | **NOT SET**         |
| `oradba_install.sh` | Universal installer                 | --prefix, --local, --github, flags             | **YES**             |
| `oradba_env.sh`     | Environment management CLI          | list, show, status, validate, changes, version | **NOT SET**         |
| `oradba_dsctl.sh`   | DataSafe control/status             | start, stop, restart, status                   | **YES**             |
| `oraup.sh`          | Oracle status overview              | -h, -v, -q flags                               | **YES**             |

### 4.2 Secondary / Specialized Entry Points (25 scripts)

| Script                                       | Purpose                         | `set -euo pipefail`                |
|----------------------------------------------|---------------------------------|------------------------------------|
| `oradba_check.sh`                            | Pre-installation checks         | **YES**                            |
| `oradba_dbctl.sh`                            | Database instance control       | **YES**                            |
| `oradba_homes.sh`                            | Oracle Home registry management | **NOT SET**                        |
| `oradba_extension.sh`                        | Extension system management     | `set -o pipefail` (missing -e, -u) |
| `oradba_rman.sh`                             | RMAN backup management          | **YES**                            |
| `oradba_validate.sh`                         | Environment validation          | **YES**                            |
| `oradba_version.sh`                          | Version information             | **YES**                            |
| `oradba_sqlnet.sh`                           | SQLNet/TNS configuration        | **YES**                            |
| `oradba_lsnrctl.sh`                          | Listener management             | **YES**                            |
| `oradba_services.sh`                         | Oracle service management       | **YES**                            |
| `oradba_dbca.sh`                             | DBCA wrapper                    | **YES**                            |
| `oradba_logrotate.sh`                        | Log rotation management         | **YES**                            |
| `oradba_help.sh`                             | Help documentation              | **YES**                            |
| `oradba_datasafe_debug.sh`                   | DataSafe debugging              | **YES**                            |
| `dbstatus.sh`                                | Quick database status           | **YES**                            |
| `longops.sh`                                 | Monitor long-running operations | **YES**                            |
| `oradba_services_root.sh`                    | Root-level service setup        | **YES**                            |
| `get_seps_pwd.sh`                            | Password retrieval utility      | **YES**                            |
| `exp_jobs.sh`, `imp_jobs.sh`, `rman_jobs.sh` | Job status utilities            | **YES**                            |
| `sync_from_peers.sh`, `sync_to_peers.sh`     | Configuration sync              | **YES**                            |

**Total:** 30 executable scripts in `src/bin/`

----------------------------------------------------------------------------------------------------

## 5. CLI Surface & Flags

### 5.1 oraenv.sh (Sourced Environment Script)

**Flags:**

- `--fast-silent` — Skip verbose output
- `--status` — Show status and exit

**No subcommands (functional interface)** — sets environment variables directly.

### 5.2 oradba_install.sh (Universal Installer)

**Installation Modes (case statement):**

- `embedded` — Self-extracting from embedded payload
- `local` — Install from local tarball
- `github` — Download and install from GitHub releases

**Flags:**

- `--prefix <PATH>` — Installation directory
- `--base <PATH>` — Oracle Base path
- `--user-level` — Install in user home
- `--user <USER>` — Run as specific user
- `--local <FILE>` — Use local tarball
- `--github` — Use GitHub releases
- `--version <VERSION>` — Specific version to install
- `--update` — Update existing installation
- `--force` — Force overwrite
- `--update-profile` / `--no-update-profile` — Profile integration
- `--auto-discover-oratab` — Auto-discover oratab
- `--auto-discover-products` — Auto-discover product homes
- `--silent` — Quiet operation
- `--debug` — Debug mode
- `--dummy-home` — Create dummy ORACLE_HOME

### 5.3 oradba_env.sh (Environment Management CLI)

**Subcommands (case statement on \$command):**

- `list` — List available environments
- `show` — Display environment settings
- `status` — Check environment status
- `validate` — Validate environment
- `changes` — Show environment changes
- `version` — Display version information

**Sub-filters for `sids` (case on \$flag):** \[UNKNOWN — requires deeper parsing\]

### 5.4 oradba_dsctl.sh (DataSafe Control)

**Subcommands (case statement on \$ACTION):**

- `start` — Start DataSafe connector
- `stop` — Stop DataSafe connector
- `restart` — Restart DataSafe connector
- `status` — Report status

### 5.5 oraup.sh (Status Overview)

**Flags:**

- `-h, --help` — Show help
- `-v, --verbose` — Verbose output
- `-q, --quiet` — Minimal output

**No subcommands** — single unified status view.

----------------------------------------------------------------------------------------------------

## 6. Configuration Files & Load Order

### 6.1 Configuration Files

| File                    | Location               | Loaded By                                 | Required            |
|-------------------------|------------------------|-------------------------------------------|---------------------|
| `oradba_core.conf`      | `src/etc/`             | All scripts via `load_config_file()`      | **YES**             |
| `oradba_standard.conf`  | `src/etc/`             | `load_config()` in oraenv.sh              | **WARN if missing** |
| `oradba_customer.conf`  | `src/etc/` (optional)  | `load_config()` in oraenv.sh              | No                  |
| `sid._DEFAULT_.conf`    | `src/etc/`             | `load_config()` for SID-specific fallback | No                  |
| `sid.<ORACLE_SID>.conf` | `src/etc/`             | `load_config()` when SID set              | No                  |
| `oradba_services.conf`  | `src/etc/`             | oradba_services.sh                        | No                  |
| `oradba_local.conf`     | Installation directory | oraenv.sh (Phase 1)                       | No                  |

### 6.2 Configuration Load Hierarchy

Load order (from `src/lib/oradba_common.sh:1053`):

``` text
1. oradba_core.conf (required)
2. oradba_standard.conf (warn if missing)
3. oradba_customer.conf (optional)
4. sid._DEFAULT_.conf (optional fallback)
5. sid.<ORACLE_SID>.conf (optional, SID-specific)
6. Environment variable overrides
```

**Load Pattern:** Later configs override earlier settings. All variables auto-exported via `set -a`.

### 6.3 Config Variable Deduplication

- Loads via `load_config_file()` (oradba_common.sh:1005-1040)
- PATH deduplication after each config: uses `oradba_dedupe_path()` if available, else awk
- Purpose: Prevent duplicate entries in PATH from repeated config loads

----------------------------------------------------------------------------------------------------

## 7. Version & Release Markers

| Location                       | Content                           | Notes                                          |
|--------------------------------|-----------------------------------|------------------------------------------------|
| `VERSION` (root)               | `0.24.11`                         | Single-line version identifier                 |
| `CHANGELOG.md`                 | `## [0.24.11] - 2026-06-25`       | Full semantic versioning + dates               |
| `src/bin/oradba_install.sh:23` | `INSTALLER_VERSION="__VERSION__"` | Placeholder (filled by build)                  |
| `src/bin/oraenv.sh:9`          | `Revision...: 0.21.0`             | Script-level revision (inconsistent with repo) |
| `src/bin/oradba_env.sh:23`     | `SCRIPT_VERSION="1.0.0"`          | Per-script version                             |

**Version Discrepancy:** Repository is v0.24.11, but many scripts show v0.21.0 (last update:
2026-02-11).

----------------------------------------------------------------------------------------------------

## 8. `set -euo pipefail` Usage Map

### Scripts WITH `set -euo pipefail` (25 scripts)

- oradba_install.sh, oradba_dsctl.sh, oraup.sh, oradba_check.sh, oradba_datasafe_debug.sh
- oradba_dbca.sh, oradba_dbctl.sh, oradba_help.sh, oradba_logrotate.sh, oradba_lsnrctl.sh
- oradba_rman.sh, oradba_services.sh, oradba_services_root.sh, oradba_setup.sh, oradba_sqlnet.sh
- oradba_validate.sh, oradba_version.sh, dbstatus.sh, exp_jobs.sh, get_seps_pwd.sh
- imp_jobs.sh, longops.sh, rman_jobs.sh, sessionsql.sh, sync_from_peers.sh, sync_to_peers.sh

### Scripts WITHOUT `set -euo pipefail` (6 scripts)

| Script                | Issue                                                                   |
|-----------------------|-------------------------------------------------------------------------|
| `oraenv.sh`           | Must be sourced (no set statement) — depends on caller's error handling |
| `oradba_env.sh`       | Must be sourced (no set statement) — depends on caller's error handling |
| `oradba_homes.sh`     | Missing `set -euo pipefail` — should be added                           |
| `oradba_extension.sh` | `set -o pipefail` only (missing `-e -u`) — incomplete error handling    |

**Summary:**

- **25 / 31 scripts** have correct `set -euo pipefail`
- **2 / 31** are sourced scripts (oraenv.sh, oradba_env.sh) — exempt by design
- **1 / 31** incomplete (oradba_extension.sh needs `-e -u` added)
- **1 / 31** missing entirely (oradba_homes.sh needs full statement)
- **Compliance: 81%** (25/31 fully compliant; 87% if excluding sourced scripts)

----------------------------------------------------------------------------------------------------

## 9. Recent Change Hotspots (git log --oneline -50)

### By Area

| Area                                    | Count | Recent Commits (first 3)                                                         |
|-----------------------------------------|-------|----------------------------------------------------------------------------------|
| **Bug Fixes (fix)**                     | 7     | b76fe9c (dsctl log dir), 5e89542 (oraup Data Safe), 4db7ccf (oraup ((idx++)))    |
| **Release / Version (chore/release)**   | 10    | 7147a20 (v0.24.10), c045a63 (v0.24.9), 9a3d1d3 (v0.24.8)                         |
| **Features (feat)**                     | 3     | c3ccf2c (service triggers), f8c3b46 (docs site_url), 0e40ca4 (SQL audit scripts) |
| **Documentation (docs)**                | 11    | 05a0e44 (logo/links), b5c134e (version), 32793df (PDF layout)                    |
| **Configuration / Maintenance (chore)** | 8     | fcf0286 (.claude ignore), 6934354 (markdown lint), 1348adf (version injection)   |
| **CI/CD**                               | 6     | c207df7 (pandoc fix), c696312 (pipeline hardening), b167978 (Claude workflows)   |
| **Testing**                             | 2     | fa36489 (test fixes), 6eeaa12 (test alignment)                                   |

### Hotspot Trends

1. **Version Management Heavy:** 10 of 50 commits are chore(release) — indicates regular,
    disciplined release cadence (6-8 days between releases)
2. **DataSafe Stability Issues:** 2 recent fixes (dsctl log dir, oraup status) suggest active
    maintenance of connector
3. **Documentation Priority:** 11 commits to docs (PDF generation, site structure, API docs)
4. **CI/CD Hardening:** 6 commits to scripts, GitHub Actions, build process
5. **SQL Script Expansion:** Major feature in mid-March added 18 new audit analysis scripts

### Commit Message Quality

- **All commits:** Follow conventional commits format (`type(scope): description`)
- **No "Co-Authored" tags:** All commits attributed to Stefan Oehrli
- **Scope examples:** dsctl, oraup, install, docs, sql, ci, tests, release

----------------------------------------------------------------------------------------------------

## 10. Build & Distribution

| Item                | Notes                                                               |
|---------------------|---------------------------------------------------------------------|
| `scripts/`          | Build automation directory (UNKNOWN contents)                       |
| `build/`            | Build output directory (UNKNOWN contents)                           |
| `dist/`             | Distribution packages (UNKNOWN contents)                            |
| `Makefile`          | Build orchestration (not examined)                                  |
| `oradba_install.sh` | Self-extracting installer (embeds payload or downloads from GitHub) |

----------------------------------------------------------------------------------------------------

## 11. Summary Tables

### Library Metrics

| Category                   | Count  | LOC         | Functions |
|----------------------------|--------|-------------|-----------|
| Core Libraries (src/lib/)  | 15     | ~9,471      | 151       |
| Plugins (src/lib/plugins/) | 10     | ~4,005      | 158       |
| **Total Shared Code**      | **25** | **~13,476** | **309**   |

### Entry Points

| Category              | Count  |
|-----------------------|--------|
| Primary (main CLI)    | 5      |
| Secondary/Specialized | 25     |
| **Total**             | **30** |

### Error Handling Compliance

| Status                   | Count | Percentage |
|--------------------------|-------|------------|
| Full `set -euo pipefail` | 26    | 87%        |
| Sourced (exempt)         | 2     | 6%         |
| Incomplete (needs fix)   | 1     | 3%         |
| Missing (needs addition) | 1     | 3%         |

### Configuration

| Metric             | Value                       |
|--------------------|-----------------------------|
| Core Config Files  | 7                           |
| Config Load Levels | 6-level hierarchy           |
| Auto-Export        | Yes (via `set -a`)          |
| Deduplication      | PATH only (after each load) |

----------------------------------------------------------------------------------------------------

## 12. Not Determined (UNKNOWN)

- Build system details (`Makefile` flags, targets, dependencies)
- Distribution package formats and sizes
- Integration test details (tests/manual, tests/results structure)
- SQL script inventory categorization (157 files not individually audited)
- Template rendering pipeline (DBCA, init.d, logrotate, sqlnet, systemd)
- Extension discovery mechanism (extensibility pattern in extensions.sh)
- Release artifact generation process
- Exact plugin loading order when multiple plugins are sourced
- oradba_homes.sh detailed CLI surface (sub-filters not fully parsed)
- Specific contents of doc/, scripts/, build/, dist/ directories
