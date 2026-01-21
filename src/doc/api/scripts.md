# Scripts and Commands

Command-line scripts and tools for OraDBA operations.

<!-- markdownlint-disable MD024 -->

---

## Functions

### `_oraenv_apply_product_adjustments` {: #-oraenv-apply-product-adjustments }

Apply product-specific path adjustments (e.g., DataSafe plugin)

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Oracle Home path from oratab

**Returns:** None (outputs via echo)

**Output:** Echoes "adjusted_home|datasafe_install_dir" pipe-delimited values

!!! info "Notes"
    Detects DataSafe installations by oracle_cman_home subdirectory,
    sources datasafe_plugin.sh, and calls plugin_adjust_environment().
    Returns original path if no adjustments needed. Plugin system allows
    extensible product-specific environment handling.

---

### `_oraenv_auto_discover_instances` {: #-oraenv-auto-discover-instances }

Auto-discover running Oracle instances when oratab is empty

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Requested SID name (optional, for targeted discovery)
- $2 - Path to oratab file

**Returns:** None (outputs via echo)

**Output:** Echoes discovered oratab entry in format "SID:HOME:FLAGS"

!!! info "Notes"
    Only runs if ORADBA_AUTO_DISCOVER_INSTANCES=true and oratab is empty.
    Uses discover_running_oracle_instances() to find running processes.
    Case-insensitive SID matching with awk. Optionally persists discoveries
    to oratab via persist_discovered_instances().

---

### `_oraenv_display_selection_menu` {: #-oraenv-display-selection-menu }

Display interactive selection menu for SIDs and Oracle Homes

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Name reference to SIDs array
- $2 - Name reference to Homes array

**Returns:** None (outputs to stderr)

**Output:** Formatted menu with numbered entries showing Oracle Homes (with type)

!!! info "Notes"
    Oracle Homes are listed first, then database SIDs. Each entry is
    numbered sequentially for user selection.

---

### `_oraenv_find_oratab` {: #-oraenv-find-oratab }

Locate the oratab file using standard search paths

**Source:** `oraenv.sh`

**Arguments:**

- None

**Returns:** 0 on success (oratab found), 1 on error (not found)

**Output:** Echoes path to oratab file if found

!!! info "Notes"
    Checks ORATAB_FILE variable first, then uses get_oratab_path(),
    finally falls back to ORATAB_ALTERNATIVES array. Sets ORATAB_FILE
    environment variable when found.

---

### `_oraenv_gather_available_entries` {: #-oraenv-gather-available-entries }

Gather available database SIDs and Oracle Homes from registry

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Path to oratab file
- $2 - Name reference to SIDs array
- $3 - Name reference to Homes array

**Returns:** 0 on success, 1 if no entries found

**Output:** Populates referenced arrays with available entries

!!! info "Notes"
    Uses registry API (Phase 1) first, falls back to auto-discovery
    if enabled. Separates database SIDs from non-database Oracle Homes.

---

### `_oraenv_handle_oracle_home` {: #-oraenv-handle-oracle-home }

Setup environment for an Oracle Home (non-database installation)

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Oracle Home name from oradba_homes.conf

**Returns:** 0 on success, 1 on error

**Output:** Exports ORACLE_HOME, ORACLE_BASE, ORACLE_SID (empty for non-DB),

!!! info "Notes"
    Uses set_oracle_home_environment() from Oracle Homes management.
    Unsets previous environment, derives ORACLE_BASE, loads hierarchical
    configuration, and logs environment details.

---

### `_oraenv_load_configurations` {: #-oraenv-load-configurations }

Load hierarchical configurations and extensions for environment

**Source:** `oraenv.sh`

**Arguments:**

- $1 - SID or Oracle Home name identifier

**Returns:** None (modifies environment)

**Output:** Loads configuration hierarchy: core → standard → customer → default

!!! info "Notes"
    Calls load_config() for hierarchical config merging. Later configs
    override earlier ones including aliases. Configures SQLPATH unless
    ORADBA_CONFIGURE_SQLPATH=false. Loads extensions via load_extensions()
    unless in basenv coexistence mode (unless ORADBA_EXTENSIONS_IN_COEXIST=true).

---

### `_oraenv_lookup_oratab_entry` {: #-oraenv-lookup-oratab-entry }

Lookup database entry from registry or oratab file

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Requested SID name
- $2 - Path to oratab file

**Returns:** None (outputs via echo)

**Output:** Echoes oratab entry in format "SID:HOME:FLAGS" if found, empty if not

!!! info "Notes"
    Uses registry API (Phase 1) first via oradba_registry_get_by_name(),
    falls back to direct oratab parsing with parse_oratab(). Converts
    registry format to oratab format for compatibility.

---

### `_oraenv_main` {: #-oraenv-main }

Main orchestration function for oraenv.sh

**Source:** `oraenv.sh`

**Arguments:**

- $@ - All command line arguments

**Returns:** 0 on success, 1 on error

**Output:** Sets Oracle environment, optionally displays status and environment

!!! info "Notes"
    Workflow: 1) Parse arguments, 2) Find oratab, 3) Get/prompt for SID,
    4) Set environment, 5) Show environment (if SHOW_ENV=true),
    6) Show database status (if SHOW_STATUS=true and available).
    Handles no-Oracle mode when oratab not found. Must be sourced, not executed.

---

### `_oraenv_main` {: #-oraenv-main }

Main orchestration function for oraenv.sh

**Source:** `oraenv.sh`

**Arguments:**

- $@ - All command line arguments

**Returns:** 0 on success, 1 on error

**Output:** Sets Oracle environment, optionally displays status and environment

!!! info "Notes"
    Workflow: 1) Parse arguments, 2) Find oratab, 3) Get/prompt for SID,
    4) Set environment, 5) Show environment (if SHOW_ENV=true),
    6) Show database status (if SHOW_STATUS=true and available).
    Handles no-Oracle mode when oratab not found. Must be sourced, not executed.

---

### `_oraenv_parse_args` {: #-oraenv-parse-args }

Parse command line arguments for oraenv.sh

**Source:** `oraenv.sh`

**Arguments:**

- $@ - All command line arguments

**Returns:** 0 on success, 1 on error

**Output:** Sets global variables: REQUESTED_SID, SHOW_ENV, SHOW_STATUS,

!!! info "Notes"
    Detects TTY for interactive mode, processes --silent, --status,
    --force, and --help flags

---

### `_oraenv_parse_user_selection` {: #-oraenv-parse-user-selection }

Parse and validate user selection from interactive prompt

**Source:** `oraenv.sh`

**Arguments:**

- $1 - User selection (number or name)
- $2 - Total number of available entries
- $3 - Name reference to SIDs array
- $4 - Name reference to Homes array

**Returns:** 0 on success, 1 if no selection made

**Output:** Echoes selected SID or Oracle Home name

!!! info "Notes"
    Accepts either numeric selection (1-N) or direct name entry.
    Numeric selection maps to arrays (Homes first, then SIDs).

---

### `_oraenv_prompt_sid` {: #-oraenv-prompt-sid }

Get SID from user (interactive) or first entry (non-interactive)

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Path to oratab file

**Returns:** 0 on success, 1 on error

**Output:** Selected SID or Oracle Home name

---

### `_oraenv_set_environment` {: #-oraenv-set-environment }

Set Oracle environment for a database SID or Oracle Home

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Requested SID or Oracle Home name
- $2 - Path to oratab file

**Returns:** 0 on success, 1 on error

---

### `_oraenv_setup_environment_variables` {: #-oraenv-setup-environment-variables }

Setup Oracle environment variables for database instance

**Source:** `oraenv.sh`

**Arguments:**

- $1 - Actual SID from oratab (preserves case)
- $2 - Oracle Home path (after product adjustments)
- $3 - Complete oratab entry (SID:HOME:FLAGS)
- $4 - DataSafe install directory (optional, empty if not DataSafe)

**Returns:** None (exports environment variables)

**Output:** Exports ORACLE_SID, ORACLE_HOME, ORACLE_BASE, ORACLE_STARTUP,

!!! info "Notes"
    Uses oradba_set_lib_path() with plugin system for library paths.
    Startup flag (Y/N) extracted from oratab entry field 3.

---

### `_oraenv_unset_old_env` {: #-oraenv-unset-old-env }

Unset previous Oracle environment variables before setting new ones

**Source:** `oraenv.sh`

**Arguments:**

- None

**Returns:** None (modifies environment)

**Output:** Removes old ORACLE_HOME paths from PATH and LD_LIBRARY_PATH

!!! info "Notes"
    Uses sed to remove both "$ORACLE_HOME/bin:" and ":$ORACLE_HOME/bin"
    patterns to handle paths at beginning, middle, or end of PATH/LD_LIBRARY_PATH.
    Prevents PATH pollution when switching between Oracle environments.

---

### `_oraenv_usage` {: #-oraenv-usage }

Display usage information for oraenv.sh

**Source:** `oraenv.sh`

**Arguments:**

- None

**Returns:** None (outputs to stderr)

**Output:** Usage message with arguments, options, examples, and environment

!!! info "Notes"
    Output goes to stderr so it's visible when script is sourced

---

### `add_home` {: #add-home }

Add a new Oracle Home

**Source:** `oradba_homes.sh`

---

### `ask_justification` {: #ask-justification }

Prompt for justification when operating on multiple databases

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Database count

**Returns:** 0 if confirmed, 1 if cancelled or no justification

**Output:** Warning banner, prompts for justification and confirmation to stdout

!!! info "Notes"
    Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed

---

### `ask_justification` {: #ask-justification }

Prompt for justification when operating on multiple databases

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Database count

**Returns:** 0 if confirmed, 1 if cancelled or no justification

**Output:** Warning banner, prompts for justification and confirmation to stdout

!!! info "Notes"
    Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed

---

### `ask_justification` {: #ask-justification }

Prompt for justification when operating on all listeners (safety check)

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Count of affected listeners

**Returns:** 0 if user confirms, 1 if cancelled or no justification

**Output:** Warning banner, prompts for justification and confirmation

!!! info "Notes"
    Skipped if FORCE_MODE=true; requires "yes" confirmation to proceed

---

### `backup_config` {: #backup-config }

Backup all SQL\*Net configuration files with timestamps

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if no files found

**Output:** Backup confirmations for each file, final count

!!! info "Notes"
    Backs up sqlnet.ora, tnsnames.ora, ldap.ora using backup_file function

---

### `backup_file` {: #backup-file }

Create timestamped backup copy of file

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - File path to backup

**Returns:** 0 if file backed up, 1 if file doesn't exist

**Output:** Success message with backup filename

!!! info "Notes"
    Backup format: \<filename\>.YYYYMMDD_HHMMSS.bak, preserves original file

---

### `backup_installation` {: #backup-installation }

Create timestamped backup of existing installation

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0 on success, 1 on failure

**Output:** Backup directory path to stdout, status to stderr

!!! info "Notes"
    Creates .backup.YYYYMMDD_HHMMSS directory
    Full recursive copy of entire installation
    Used before updates to enable rollback

---

### `backup_modified_files` {: #backup-modified-files }

Backup modified configuration files before update

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation prefix directory

**Returns:** 0

**Output:** Backup status messages to stdout

!!! info "Notes"
    Similar to RPM behavior - saves modified files with .save extension
    Compares checksums from .oradba.checksum file
    Only backs up etc/ files and .conf files
    Skips backup if .oradba.checksum doesn't exist (fresh install)

---

### `check_additional_files` {: #check-additional-files }

Detect user-added files not in official checksum (customizations)

**Source:** `oradba_version.sh`

**Arguments:**

- None (uses ${BASE_DIR})

**Returns:** None (always succeeds, informational)

**Output:** Warning list of additional files in managed directories (bin, doc, etc, lib, rcv, sql, templates)

!!! info "Notes"
    Helps identify user customizations before updates; shows backup commands if SHOW_BACKUP=true

---

### `check_archived_version` {: #check-archived-version }

Check if version is pre-1.0 archived release and display notice

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Version string (e.g., "0.16.0")

**Returns:** 0 if archived (pre-1.0), 1 otherwise

**Output:** Archived version notice to stdout

!!! info "Notes"
    All 0.x.x versions are considered archived
    Displays upgrade recommendation for production use

---

### `check_database_connectivity` {: #check-database-connectivity }

Test database connectivity and process availability

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds, informational)

**Output:** Process status, connection test results, DB version in verbose mode

!!! info "Notes"
    Skipped if ORACLE_HOME/ORACLE_SID not set; checks pmon process, tests sqlplus connection with 5s timeout

---

### `check_disk_space` {: #check-disk-space }

Verify sufficient disk space for installation

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0 if sufficient space, 1 otherwise

**Output:** Disk space check results to stdout

!!! info "Notes"
    Requires 100MB free space
    Checks parent directories if target doesn't exist
    Warns if unable to determine space (continues anyway)

---

### `check_disk_space` {: #check-disk-space }

Verify sufficient disk space for OraDBA installation (100 MB required)

**Source:** `oradba_check.sh`

**Arguments:**

- None (uses $CHECK_DIR from command-line or default)

**Returns:** 0 if sufficient space, 1 if insufficient

**Output:** Checking directory, available space, required space, pass/fail status

!!! info "Notes"
    Critical check; finds existing parent if target doesn't exist; uses df -Pm

---

### `check_existing_installation` {: #check-existing-installation }

Check if OraDBA is already installed at target location

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0 if installed, 1 otherwise

**Output:** None

!!! info "Notes"
    Verifies directory exists and contains VERSION file and bin/ directory
    Used to determine if doing fresh install or update

---

### `check_extension_checksums` {: #check-extension-checksums }

Verify integrity of all enabled extensions using their .extension.checksum files

**Source:** `oradba_version.sh`

**Arguments:**

- None (scans ${BASE_DIR}/extensions and ${ORADBA_LOCAL_BASE})

**Returns:** 0 if all extensions verified, 1 if any failures

**Output:** Success/failure status for each enabled extension, verbose details in VERBOSE mode

!!! info "Notes"
    Checks only enabled extensions; respects .checksumignore; verifies managed dirs (bin,sql,rcv,etc,lib)

---

### `check_github_connectivity` {: #check-github-connectivity }

Test connectivity to GitHub API for update/installation features

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** None (always succeeds, informational)

**Output:** Pass/warn for GitHub API accessibility with workaround suggestions

!!! info "Notes"
    Tests api.github.com with 5s timeout; informational only, tarball fallback available

---

### `check_integrity` {: #check-integrity }

Verify OraDBA installation integrity using SHA256 checksums

**Source:** `oradba_version.sh`

**Arguments:**

- $1 - skip_extensions (optional, defaults to "false"; if "true", skip extension verification)

**Returns:** 0 if all files verified, 1 if any mismatches or missing files

**Output:** Success/failure status, file counts, detailed error list for failures

!!! info "Notes"
    Reads .oradba.checksum; excludes .install_info; calls check_additional_files and check_extension_checksums

---

### `check_optional_tools` {: #check-optional-tools }

Check for optional tools and warn if missing

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0 (always successful, warnings only)

**Output:** Optional tool status and installation hints to stdout

!!! info "Notes"
    Checks: rlwrap, less, crontab
    Installation continues even if optional tools missing
    Provides installation commands for missing tools

---

### `check_optional_tools` {: #check-optional-tools }

Check availability of optional but recommended tools

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** None (always succeeds, warnings only)

**Output:** Pass/warn for rlwrap, less, curl, wget with installation suggestions

!!! info "Notes"
    Informational; missing tools reduce user experience but don't block installation

---

### `check_oracle_environment` {: #check-oracle-environment }

Check Oracle environment variables (ORACLE_HOME, ORACLE_BASE, ORACLE_SID, TNS_ADMIN)

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds, informational)

**Output:** Pass/warn/info for each env var with paths and existence checks

!!! info "Notes"
    Informational only; validates directory existence for set variables; not required for installation

---

### `check_oracle_tools` {: #check-oracle-tools }

Check availability of Oracle tools (sqlplus, rman, lsnrctl, tnsping)

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds, informational)

**Output:** Pass/warn for each tool with paths in verbose mode

!!! info "Notes"
    Skipped if ORACLE_HOME not set; informational only; warns if tools missing

---

### `check_oracle_user` {: #check-oracle-user }

Verify Oracle OS user exists on system

**Source:** `oradba_services_root.sh`

**Arguments:**

- None (uses global ORACLE_USER)

**Returns:** Exits with code 1 if user doesn't exist

**Output:** Error message via log_message if user missing

!!! info "Notes"
    Checks user defined by ${ORACLE_USER} environment variable

---

### `check_oracle_versions` {: #check-oracle-versions }

Scan Oracle Inventory and common locations for installed Oracle Homes

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds, informational)

**Output:** Inventory path, Oracle Homes found with versions in verbose mode

!!! info "Notes"
    Reads /etc/oraInst.loc or /var/opt/oracle/oraInst.loc; parses inventory.xml; falls back to common locations

---

### `check_oradba_installation` {: #check-oradba-installation }

Verify OraDBA installation completeness and display installation info

**Source:** `oradba_check.sh`

**Arguments:**

- None (uses $CHECK_DIR)

**Returns:** 0 (always succeeds, informational)

**Output:** Directory existence, .install_info details, key directories (bin, lib, sql, etc)

!!! info "Notes"
    Informational; shows install metadata in verbose mode; warns if directories missing

---

### `check_parallel_method` {: #check-parallel-method }

Determine and validate parallel execution method

**Source:** `oradba_rman.sh`

**Arguments:**

- None (uses global OPT_PARALLEL)

**Returns:** 0

**Output:** Method selection to log

!!! info "Notes"
    Sets PARALLEL_METHOD to "gnu_parallel" or "background"
    Falls back to background if GNU parallel not available

---

### `check_permissions` {: #check-permissions }

Verify write permissions for installation directory

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0 if writable, 1 otherwise

**Output:** Permission check results to stdout

!!! info "Notes"
    Checks target directory or creates test file in parent
    Suggests sudo if permissions insufficient

---

### `check_required_tools` {: #check-required-tools }

Verify required system tools are available

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0 if all required tools present, 1 otherwise

**Output:** Tool check results to stdout

!!! info "Notes"
    Checks: bash, tar, awk, sed, grep, sha256sum/shasum
    Mode-specific: base64 (embedded), curl/wget (github)
    Installation cannot proceed if required tools missing

---

### `check_root` {: #check-root }

Verify script is running as root (EUID 0)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- $1 - Operation name for error message (e.g., "--install")

**Returns:** 0 if root, 1 if not root

**Output:** Error message with sudo suggestion if not root

!!! info "Notes"
    Checks EUID; required for system-wide operations (/etc/logrotate.d)

---

### `check_root` {: #check-root }

Verify script is running with root privileges

**Source:** `oradba_services_root.sh`

**Arguments:**

- None

**Returns:** Exits with code 1 if not root

**Output:** Error message via log_message if not root

!!! info "Notes"
    Required for systemd/init.d service management

---

### `check_services_script` {: #check-services-script }

Validate oradba_services.sh exists and is executable

**Source:** `oradba_services_root.sh`

**Arguments:**

- None (uses global SERVICES_SCRIPT)

**Returns:** Exits with code 1 if script missing or not executable

**Output:** Error messages via log_message

!!! info "Notes"
    Checks ${ORADBA_BASE}/bin/oradba_services.sh

---

### `check_system_info` {: #check-system-info }

Display system information (OS, version, hostname, user, shell)

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** None (always succeeds)

**Output:** Formatted system information messages

!!! info "Notes"
    Informational only; uses uname, /etc/os-release, sw_vers (macOS)

---

### `check_system_tools` {: #check-system-tools }

Verify availability of critical system tools required for OraDBA

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** 0 if all tools found, 1 if any missing

**Output:** Pass/fail for each tool: bash, tar, awk, sed, grep, find, sort, sha256sum/shasum, base64

!!! info "Notes"
    Critical check; missing tools prevent installation; shows versions in verbose mode

---

### `check_updates` {: #check-updates }

Query GitHub API for latest OraDBA release and compare with installed version

**Source:** `oradba_version.sh`

**Arguments:**

- None

**Returns:** 0 if up-to-date, 1 if check failed, 2 if update available

**Output:** Current vs latest version, download instructions if update available

!!! info "Notes"
    Uses curl with 10s timeout; queries api.github.com/repos/oehrlis/oradba/releases/latest

---

### `check_version` {: #check-version }

Read and return OraDBA version from VERSION file

**Source:** `oradba_version.sh`

**Arguments:**

- None

**Returns:** 0 if version found, 1 if VERSION file missing

**Output:** Version string (e.g., "1.2.3") or "Unknown"

!!! info "Notes"
    Reads ${BASE_DIR}/VERSION; fallback for missing file

---

### `cleanup` {: #cleanup }

Remove temporary directory on script exit

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** None

!!! info "Notes"
    Called automatically via trap EXIT
    Removes TEMP_DIR if set and exists

---

### `cmd_add` {: #cmd-add }

Add/install extension from source

**Source:** `oradba_extension.sh`

**Arguments:**

- $@ - Source and command-line options

**Returns:** 0 on success, 1 on failure

**Output:** Installation status to stdout

!!! info "Notes"
    Supports: GitHub repos (owner/repo[@version]), URLs, local tarballs
    Validates structure, handles updates with --update flag
    Creates ORADBA_LOCAL_BASE if needed
    Extracts to target directory

---

### `cmd_changes` {: #cmd-changes }

Check for configuration file changes

**Source:** `oradba_env.sh`

---

### `cmd_check` {: #cmd-check }

Validate OraDBA installation health and requirements

**Source:** `oradba_setup.sh`

**Arguments:**

- None

**Returns:** 0 if all checks pass, 1 if any check fails

**Output:** Check results (✓/✗) with status messages via oradba_log

!!! info "Notes"
    Checks OraDBA installation, oratab, Oracle Homes, directories, configuration files

---

### `cmd_create` {: #cmd-create }

Create new extension from template

**Source:** `oradba_extension.sh`

**Arguments:**

- $@ - Command-line options (--path, --template, --from-github)

**Returns:** 0 on success, 1 on failure

**Output:** Creation status and instructions to stdout

!!! info "Notes"
    Supports custom templates, GitHub templates, or embedded templates
    Interactive name prompting if not provided
    Validates name and target path
    Extracts and renames template files

---

### `cmd_disabled` {: #cmd-disabled }

List only disabled extensions

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** Formatted table of disabled extensions to stdout

!!! info "Notes"
    Filters extensions by disabled status
    Shows: name, version
    Useful for identifying inactive extensions

---

### `cmd_discover` {: #cmd-discover }

Discover and list all extensions in search paths

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** Discovered extensions with paths to stdout

!!! info "Notes"
    Searches in ORADBA_LOCAL_BASE and configured paths
    Shows discovery process and results
    Uses extension auto-discovery mechanism

---

### `cmd_enabled` {: #cmd-enabled }

List only enabled extensions

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** Formatted table of enabled extensions to stdout

!!! info "Notes"
    Filters extensions by enabled status
    Shows: name, version, priority
    Uses is_extension_enabled() check

---

### `cmd_info` {: #cmd-info }

Display detailed information about specific extension

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Extension name

**Returns:** 0 on success, 1 if not found

**Output:** Extension metadata to stdout

!!! info "Notes"
    Shows: name, version, description, author, status, provides, path
    Reads from .extension file if available
    Falls back to directory structure analysis

---

### `cmd_link_oratab` {: #cmd-link-oratab }

Replace temp oratab with symlink to system /etc/oratab

**Source:** `oradba_setup.sh`

**Arguments:**

- $1 - Force mode (true|false, default: false)

**Returns:** 0 on success, 1 on failure

**Output:** Status messages via oradba_log

!!! info "Notes"
    Creates symlink ${ORADBA_BASE}/etc/oratab → /etc/oratab; requires system oratab exists

---

### `cmd_list` {: #cmd-list }

List all installed extensions with details

**Source:** `oradba_extension.sh`

**Arguments:**

- $@ - Command-line options (--verbose, -v)

**Returns:** 0

**Output:** Formatted table of extensions to stdout

!!! info "Notes"
    Shows: name, version, priority, status (enabled/disabled)
    Verbose mode adds: provides (bin/sql/rcv/etc/doc), path
    Uses get_all_extensions() from extensions.sh library

---

### `cmd_list` {: #cmd-list }

List available SIDs and/or Homes

**Source:** `oradba_env.sh`

---

### `cmd_paths` {: #cmd-paths }

Display extension search paths

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** List of extension search paths to stdout

!!! info "Notes"
    Shows configured ORADBA_LOCAL_BASE and extension directories
    Indicates which paths are active/available
    Useful for troubleshooting extension loading

---

### `cmd_show` {: #cmd-show }

Show detailed information about SID or Home

**Source:** `oradba_env.sh`

---

### `cmd_show_config` {: #cmd-show-config }

Display current OraDBA configuration and environment

**Source:** `oradba_setup.sh`

**Arguments:**

- None

**Returns:** None (always succeeds)

**Output:** Formatted configuration details (paths, variables, hosts, databases) to stdout

!!! info "Notes"
    Shows OraDBA_BASE, PREFIX, config hierarchy, Oracle Homes, SIDs, key environment vars

---

### `cmd_status` {: #cmd-status }

Check status of Oracle instance/service

**Source:** `oradba_env.sh`

---

### `cmd_validate` {: #cmd-validate }

Validate specific extension structure and metadata

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Extension name

**Returns:** 0 if valid, 1 if invalid

**Output:** Validation results to stdout

!!! info "Notes"
    Checks: directory exists, .extension file, required fields, structure
    Uses get_extension_path() and validate_extension_structure()
    Provides detailed validation report

---

### `cmd_validate` {: #cmd-validate }

Validate current Oracle environment or specified target

**Source:** `oradba_env.sh`

---

### `cmd_validate_all` {: #cmd-validate-all }

Validate all installed extensions

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0 if all valid, 1 if any invalid

**Output:** Validation summary for all extensions to stdout

!!! info "Notes"
    Iterates through all extensions found by get_all_extensions()
    Reports count of valid/invalid extensions
    Shows validation status per extension

---

### `cmd_version` {: #cmd-version }

Display version information

**Source:** `oradba_env.sh`

---

### `create_symlinks` {: #create-symlinks }

Create symlinks in ORACLE_HOME/network/admin pointing to centralized config files

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - Oracle Home path, $2 - Centralized admin directory path

**Returns:** 0 on success, 1 if ORACLE_HOME invalid

**Output:** Success messages for each symlink created, final count

!!! info "Notes"
    Handles read-only homes gracefully; skips if admin dir creation fails

---

### `create_temp_oratab` {: #create-temp-oratab }

Create temporary oratab for pre-Oracle installations

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation prefix directory

**Returns:** 0

**Output:** Oratab creation status and symlink instructions to stdout

!!! info "Notes"
    Creates etc/oratab in OraDBA directory if /etc/oratab missing
    Adds dummy entry if --dummy-home specified
    Provides instructions for symlinking after Oracle install
    Supports air-gapped and pre-Oracle environments

---

### `create_tns_structure` {: #create-tns-structure }

Create directory structure for centralized TNS_ADMIN (admin/log/trace)

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - ORACLE_SID (defaults to ORACLE_SID env var)

**Returns:** 0 on success, 1 if admin directory creation fails

**Output:** Success messages for created directories, final admin path to stdout

!!! info "Notes"
    Creates ${ORACLE_BASE}/network/${SID}/{admin,log,trace} with 755 permissions

---

### `create_tns_structure` {: #create-tns-structure }

Create directory structure for centralized TNS_ADMIN (admin/log/trace)

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - ORACLE_SID (defaults to ORACLE_SID env var)

**Returns:** 0 on success, 1 if admin directory creation fails

**Output:** Success messages for created directories, final admin path to stdout

!!! info "Notes"
    Creates ${ORACLE_BASE}/network/${SID}/{admin,log,trace} with 755 permissions

---

### `customize_logrotate` {: #customize-logrotate }

Generate customized logrotate configurations in ~/.oradba/logrotate/

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** Environment detection, database list from oratab, generated configs, next steps

!!! info "Notes"
    Creates oracle-alert-custom.logrotate and oracle-trace-custom.logrotate with paths customized to ORACLE_BASE

---

### `dedupe_homes` {: #dedupe-homes }

Remove duplicate entries from configuration

**Source:** `oradba_homes.sh`

---

### `detect_profile_file` {: #detect-profile-file }

Detect appropriate shell profile file for current user

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0

**Output:** Profile file path to stdout

!!! info "Notes"
    Priority: ~/.bash_profile \> ~/.profile \> ~/.zshrc \> create ~/.bash_profile
    .bashrc intentionally skipped (non-login shells)
    Creates .bash_profile if no profile exists

---

### `determine_default_prefix` {: #determine-default-prefix }

Auto-detect default OraDBA installation prefix from Oracle environment

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if detection failed

**Output:** Installation prefix path to stdout (e.g., /opt/oracle/local/oradba)

!!! info "Notes"
    Priority: ORACLE_BASE \> ORACLE_HOME \> oratab \> /opt/oracle \> fail
    Checks orabasetab, envVars.properties for ORACLE_BASE
    Falls back to path derivation and common locations

---

### `discover_homes` {: #discover-homes }

Auto-discover Oracle Homes

**Source:** `oradba_homes.sh`

---

### `display_header` {: #display-header }

Display formatted header with timestamp and database info

**Source:** `longops.sh`

**Arguments:**

- $1 - Oracle SID

**Returns:** None

**Output:** Header line with SID, hostname, timestamp, operation filter to stdout

!!! info "Notes"
    Shows monitoring context for watch mode refreshes

---

### `download_extension_from_github` {: #download-extension-from-github }

Download extension from GitHub repository

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Repository (owner/repo format)
- $2 - Version/tag (optional, uses latest if empty)
- $3 - Output file path

**Returns:** 0 on success, 1 on failure

**Output:** Download status to stdout, errors to stderr

!!! info "Notes"
    Tries: specific release → latest release → tags → main/master branch
    Normalizes GitHub URLs, validates repo format
    Supports both curl and wget
    Adds 'v' prefix to versions if missing

---

### `download_github_release` {: #download-github-release }

Download latest extension template from GitHub

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Output file path for downloaded tarball

**Returns:** 0 on success, 1 on failure

**Output:** Download status and tag name to stdout

!!! info "Notes"
    Downloads from oehrlis/oradba_extension repository
    Uses GitHub API to find latest release
    Validates downloaded file is valid gzip archive
    Falls back through tarball URLs if needed

---

### `execute_parallel_background` {: #execute-parallel-background }

Execute RMAN for multiple SIDs using background jobs

**Source:** `oradba_rman.sh`

**Arguments:**

- $@ - List of Oracle SIDs

**Returns:** 0 if all successful, 1 if any failed

**Output:** Parallel execution status to log

!!! info "Notes"
    Standard bash background jobs with wait
    Default parallel method if GNU parallel unavailable
    Updates FAILED_SIDS and SUCCESSFUL_SIDS arrays

---

### `execute_parallel_gnu` {: #execute-parallel-gnu }

Execute RMAN for multiple SIDs using GNU parallel

**Source:** `oradba_rman.sh`

**Arguments:**

- $@ - List of Oracle SIDs

**Returns:** 0 if all successful, 1 if any failed

**Output:** Parallel execution status to log

!!! info "Notes"
    Requires GNU parallel command installed
    Better load balancing and progress tracking than background
    Exports execute_rman_for_sid function for parallel

---

### `execute_rman_for_sid` {: #execute-rman-for-sid }

Execute RMAN script for a specific Oracle SID

**Source:** `oradba_rman.sh`

**Arguments:**

- $1 - Oracle SID

**Returns:** 0 on success, 1 on failure

**Output:** RMAN execution results to log and stdout

!!! info "Notes"
    Orchestrates: set environment, load config, process template, run RMAN
    Captures success/failure for notification
    Creates timestamped logs per SID

---

### `export_config` {: #export-config }

Export Oracle Homes configuration

**Source:** `oradba_homes.sh`

---

### `extract_embedded_payload` {: #extract-embedded-payload }

Extract OraDBA from embedded base64 payload

**Source:** `oradba_install.sh`

**Arguments:**

- None (reads from $0 - the installer script itself)

**Returns:** 0 on success, 1 on failure

**Output:** Extraction status to stdout

!!! info "Notes"
    Looks for \_\_PAYLOAD_BEGINS\_\_ marker in script
    Decodes base64 and extracts tar.gz to TEMP_DIR
    Includes filesystem sync and retry logic for containers
    Suggests alternative methods if payload missing/corrupted

---

### `extract_github_release` {: #extract-github-release }

Download and extract OraDBA from GitHub releases

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Version string (optional, uses latest if empty)

**Returns:** 0 on success, 1 on failure

**Output:** Download and extraction status to stdout

!!! info "Notes"
    Queries GitHub API for latest version if not specified
    Supports curl or wget for downloads
    Includes archived version notice for 0.x releases
    Verifies download and extracts to TEMP_DIR

---

### `extract_local_tarball` {: #extract-local-tarball }

Extract OraDBA from local tarball file

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Path to local tarball file

**Returns:** 0 on success, 1 on failure

**Output:** Extraction status to stdout

!!! info "Notes"
    Validates file exists and is readable
    Extracts to TEMP_DIR with filesystem sync for containers
    Includes retry logic for slow filesystem sync
    Used for air-gapped installations

---

### `force_logrotate` {: #force-logrotate }

Force immediate log rotation for testing (requires root)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if not root or user aborts

**Output:** Warning, confirmation prompt, rotation progress for each config

!!! info "Notes"
    Uses logrotate -f -v; actually rotates logs; requires yes confirmation

---

### `format_status` {: #format-status }

Format extension status with color

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Status string ("Enabled" or "Disabled")

**Returns:** 0

**Output:** Colored status string to stdout

!!! info "Notes"
    Green for Enabled, Red for Disabled, Yellow for unknown
    Uses terminal color codes if TTY detected

---

### `generate_cron` {: #generate-cron }

Generate crontab entry for automated user-mode log rotation

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** None (always succeeds)

**Output:** Crontab entry with full script path, daily 2 AM schedule, instructions

!!! info "Notes"
    Shows entry for manual addition to crontab; auto-detects script path; output redirected to null

---

### `generate_home_name` {: #generate-home-name }

Generate home name from directory name and product type

**Source:** `oradba_homes.sh`

**Arguments:**

- $1 - Directory name (basename of path)
- $2 - Product type (java, iclient, client, etc.)

**Returns:** 0 on success

**Output:** Normalized home name

!!! info "Notes"
    Java, JRE, and instant client use lowercase conventions

---

### `generate_tnsnames` {: #generate-tnsnames }

Generate and append TNS alias entry to tnsnames.ora

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - ORACLE_SID for alias

**Returns:** 0 on success, 1 if SID missing or entry already exists

**Output:** Success message or duplicate warning

!!! info "Notes"
    Auto-detects hostname (FQDN preferred) and uses port 1521; warns if alias exists

---

### `get_checksum_exclusions` {: #get-checksum-exclusions }

Parse .checksumignore file and generate awk exclusion patterns

**Source:** `oradba_version.sh`

**Arguments:**

- $1 - extension_path (extension directory containing .checksumignore)

**Returns:** 0 (always succeeds)

**Output:** Space-separated awk patterns for field 2 matching (e.g., "$2 ~ /^log\// || $2 ~ /^\.extension$/")

!!! info "Notes"
    Always excludes .extension, .checksumignore, log/; converts glob patterns (\* to .*, ? to .)

---

### `get_databases` {: #get-databases }

Parse oratab to extract database entries

**Source:** `oradba_dbctl.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if oratab not found

**Output:** One line per database: SID:HOME:FLAG (excludes comments, empty lines, dummy entries)

!!! info "Notes"
    Filters out entries with flag=D; reads from ${ORATAB:-/etc/oratab}

---

### `get_db_mode` {: #get-db-mode }

Get database open mode (OPEN, MOUNTED, etc.)

**Source:** `oraup.sh`

**Returns:** Open mode or "n/a"

---

### `get_db_status` {: #get-db-status }

Get database instance status by checking pmon process

**Source:** `oraup.sh`

**Returns:** "up" or "down"

---

### `get_entry` {: #get-entry }

Retrieve a wallet entry value by key using mkstore

**Source:** `get_seps_pwd.sh`

**Arguments:**

- $1 - Wallet entry key

**Returns:** 0 on success

**Output:** Entry value to stdout

!!! info "Notes"
    Uses mkstore -viewEntry; filters output to extract value after '= '

---

### `get_first_oracle_home` {: #get-first-oracle-home }

Get first valid Oracle Home from oratab

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- None (reads from ${ORATAB} or /etc/oratab)

**Returns:** 0 on success, 1 if oratab not found or no valid home

**Output:** Oracle Home path to stdout

!!! info "Notes"
    Skips entries marked :D (dummy); returns first active database home

---

### `get_installed_version` {: #get-installed-version }

Get currently installed OraDBA version

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0

**Output:** Version string to stdout (or "unknown" if not found)

!!! info "Notes"
    Reads version from VERSION file in install directory
    Returns "unknown" if VERSION file missing

---

### `get_listener_status` {: #get-listener-status }

Get listener status

**Source:** `oraup.sh`

**Returns:** "up" or "down"

---

### `get_running_listeners` {: #get-running-listeners }

Get list of all currently running listeners

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** List of listener names (one per line, sorted, unique)

!!! info "Notes"
    Uses lsnrctl services to detect running listeners; parses output for names

---

### `get_tns_admin` {: #get-tns-admin }

Determine TNS_ADMIN directory path

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** TNS_ADMIN directory path (TNS_ADMIN var, ORACLE_HOME/network/admin, or ~/.oracle/network/admin)

!!! info "Notes"
    Precedence: TNS_ADMIN env var, then ORACLE_HOME, finally HOME fallback

---

### `import_config` {: #import-config }

Import Oracle Homes configuration

**Source:** `oradba_homes.sh`

---

### `install_logrotate` {: #install-logrotate }

Install logrotate configurations to system directory (requires root)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if not root or directories missing

**Output:** Installation progress, backup notices, summary, next steps

!!! info "Notes"
    Installs from ${TEMPLATE_DIR} to /etc/logrotate.d; backs up existing configs; sets 644 permissions

---

### `install_sqlnet` {: #install-sqlnet }

Install sqlnet.ora from template with variable substitution

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - Template type (basic|secure, defaults to basic)

**Returns:** 0 on success, 1 if template not found

**Output:** Installation success message with target path, or error with available templates

!!! info "Notes"
    Uses envsubst if available, otherwise sed; backs up existing file; sets 644 permissions

---

### `install_user` {: #install-user }

Set up user-mode logrotate configurations (non-root operation)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if logrotate command not found

**Output:** Setup progress, generated configs (alert, trace, listener), next steps for testing and automation

!!! info "Notes"
    Creates ~/.oradba/logrotate/ with user-specific configs and state directory; requires manual execution or crontab

---

### `is_readonly_home` {: #is-readonly-home }

Detect Oracle read-only home configuration (18c+ feature)

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - Oracle Home path (defaults to ORACLE_HOME env var)

**Returns:** 0 if read-only home detected, 1 if read-write or unsupported version

**Output:** None

!!! info "Notes"
    Uses orabasehome utility; output != ORACLE_HOME indicates read-only mode
    Read-only homes use ORACLE_BASE_HOME and ORACLE_BASE_CONFIG for writable files

---

### `list_aliases` {: #list-aliases }

List all TNS aliases defined in tnsnames.ora

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if tnsnames.ora not found

**Output:** Numbered list of all TNS aliases (sorted)

!!! info "Notes"
    Extracts alias names from lines matching pattern: ALIAS = ...

---

### `list_homes` {: #list-homes }

List registered Oracle Homes

**Source:** `oradba_homes.sh`

---

### `list_logrotate` {: #list-logrotate }

List all installed OraDBA logrotate configurations

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** File details (ls -lh) for each config, count, installation suggestion if none found

!!! info "Notes"
    Searches for oradba\* and oracle-* in /etc/logrotate.d

---

### `load_config` {: #load-config }

Load configuration from multiple sources (script config, alt config, CLI config)

**Source:** `sync_to_peers.sh`

**Arguments:**

- None

**Returns:** None (sets global vars)

**Output:** None

!!! info "Notes"
    Sources ${SCRIPT_CONF}, ${ETC_BASE}/*.conf, ${CONFIG_FILE}; sets SSH_USER, SSH_PORT, PEER_HOSTS

---

### `load_config` {: #load-config }

Load oradba_services.conf or create from template

**Source:** `oradba_services.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** Log messages for config loading/creation

!!! info "Notes"
    Sources config file; creates from template if missing; uses defaults if unavailable

---

### `load_config` {: #load-config }

Load configuration from multiple sources (script config, alt config, CLI config)

**Source:** `sync_from_peers.sh`

**Arguments:**

- None

**Returns:** None (sets global vars)

**Output:** None

!!! info "Notes"
    Sources ${SCRIPT_CONF}, ${ETC_BASE}/*.conf, ${CONFIG_FILE}; sets SSH_USER, SSH_PORT, PEER_HOSTS

---

### `load_rman_config` {: #load-rman-config }

Load SID-specific RMAN configuration file

**Source:** `oradba_rman.sh`

**Arguments:**

- $1 - Oracle SID

**Returns:** 0 if loaded, 1 if not found

**Output:** Config loading status to log

!!! info "Notes"
    Location: \${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf
    Sets variables: RMAN_CHANNELS, RMAN_FORMAT, RMAN_TAG, etc.
    CLI options override config file settings

---

### `load_wallet_password` {: #load-wallet-password }

Load wallet password from file, environment, or interactive prompt

**Source:** `get_seps_pwd.sh`

**Arguments:**

- None

**Returns:** None (sets global WALLET_PASSWORD)

**Output:** Debug message if loaded from file; prompt if interactive

!!! info "Notes"
    Tries ${WALLET_DIR}/.wallet_pwd (base64), then env var, then prompts

---

### `log_error` {: #log-error }

Display error message with red [ERROR] prefix

**Source:** `oradba_install.sh`

**Arguments:**

- $* - Message text

**Returns:** 0

**Output:** Colored message to stderr

!!! info "Notes"
    Simple installer logging

---

### `log_fail` {: #log-fail }

Log failed check with red X

**Source:** `oradba_check.sh`

**Arguments:**

- $1 - Failure message

**Returns:** None

**Output:** Red ✗ followed by message (always displayed)

!!! info "Notes"
    Increments CHECKS_FAILED counter; never suppressed (critical errors)

---

### `log_header` {: #log-header }

Display bold section header with underline

**Source:** `oradba_check.sh`

**Arguments:**

- $1 - Header text

**Returns:** None

**Output:** Blank line, bold header text, dynamic underline (suppressed in quiet mode)

!!! info "Notes"
    Underline matches header length; respects --quiet flag

---

### `log_info` {: #log-info }

Display informational message with green [INFO] prefix

**Source:** `oradba_install.sh`

**Arguments:**

- $* - Message text

**Returns:** 0

**Output:** Colored message to stdout

!!! info "Notes"
    Simple installer logging, not the full oradba_log system

---

### `log_info` {: #log-info }

Log informational message with blue info icon

**Source:** `oradba_check.sh`

**Arguments:**

- $1 - Informational message

**Returns:** None

**Output:** Blue ℹ followed by message (suppressed in quiet mode)

!!! info "Notes"
    Increments CHECKS_INFO counter; respects --quiet flag

---

### `log_pass` {: #log-pass }

Log successful check with green checkmark

**Source:** `oradba_check.sh`

**Arguments:**

- $1 - Success message

**Returns:** None

**Output:** Green ✓ followed by message (suppressed in quiet mode)

!!! info "Notes"
    Increments CHECKS_PASSED counter; respects --quiet flag

---

### `log_warn` {: #log-warn }

Display warning message with yellow [WARN] prefix

**Source:** `oradba_install.sh`

**Arguments:**

- $* - Message text

**Returns:** 0

**Output:** Colored message to stdout

!!! info "Notes"
    Simple installer logging

---

### `log_warn` {: #log-warn }

Log warning with yellow warning sign

**Source:** `oradba_check.sh`

**Arguments:**

- $1 - Warning message

**Returns:** None

**Output:** Yellow ⚠ followed by message (suppressed in quiet mode)

!!! info "Notes"
    Increments CHECKS_WARNING counter; respects --quiet flag

---

### `main` {: #main }

Main entry point for extension management tool

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Command (add|create|list|info|validate|validate-all|discover|paths|enabled|disabled|help)
- $@ - Command-specific arguments

**Returns:** 0 on success, 1 on error

**Output:** Command output to stdout, errors to stderr

!!! info "Notes"
    Dispatcher to cmd_\* handler functions
    Shows usage for unknown commands or help flags

---

### `main` {: #main }

Orchestrate long operations monitoring workflow

**Source:** `longops.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exit code from run_monitor

**Output:** Depends on watch/filter modes

!!! info "Notes"
    Workflow: parse args → run monitor; defaults to $ORACLE_SID if no SIDs specified

---

### `main` {: #main }

Main entry point for database status display

**Source:** `dbstatus.sh`

**Arguments:**

- [OPTIONS] - Command-line options

**Returns:** 0 on success, 1 on error

**Output:** Database status information to stdout

!!! info "Notes"
    Parses arguments, validates environment, calls show_database_status
    Requires ORACLE_HOME and ORACLE_SID (or --sid option)

---

### `main` {: #main }

Orchestrate wallet password retrieval workflow

**Source:** `get_seps_pwd.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exit code from search_wallet (0 success, 1 failure)

**Output:** Depends on mode (quiet/check/normal)

!!! info "Notes"
    Workflow: parse args → validate → load password → search wallet

---

### `main` {: #main }

Main entry point for Oracle Homes management

**Source:** `oradba_homes.sh`

**Arguments:**

- $1 - Command (list|show|add|remove|discover|validate|dedupe|export|import)
- $@ - Command-specific options and arguments

**Returns:** 0 on success, 1 on error

**Output:** Command output to stdout, errors to stderr

!!! info "Notes"
    Dispatches to appropriate command handler function
    Shows usage if no command or -h/--help provided

---

### `main` {: #main }

Entry point and command-line argument dispatcher

**Source:** `oradba_version.sh`

**Arguments:**

- $@ - Command-line arguments (see usage for options)

**Returns:** Depends on selected operation (0 success, 1 error, 2 update available)

**Output:** Depends on selected operation (check/verify/update-check/info/help)

!!! info "Notes"
    Defaults to version_info if no action specified; parses --verbose and --show-backup flags

---

### `main` {: #main }

Parse command and dispatch to appropriate subcommand

**Source:** `oradba_setup.sh`

**Arguments:**

- Command line arguments (command + options)

**Returns:** Exit code from subcommand (0 success, 1 failure)

**Output:** Depends on selected command

!!! info "Notes"
    Commands: link-oratab, check, show-config, help; parses --force, --verbose, --help options

---

### `main` {: #main }

Main entry point for RMAN wrapper script

**Source:** `oradba_rman.sh`

**Arguments:**

- $@ - Command-line arguments

**Returns:** 0 if all operations successful, 1-3 for errors

**Output:** Execution status and results to stdout/log

!!! info "Notes"
    Parses arguments, validates requirements, orchestrates execution
    Supports single/parallel execution, dry-run mode
    Sends notifications on completion
    Exit codes: 0=success, 1=failed, 2=invalid args, 3=critical error

---

### `main` {: #main }

Entry point and command-line argument dispatcher

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $@ - Command-line arguments (see usage for options)

**Returns:** 0 on success, 1 on error

**Output:** Depends on selected operation (install/generate/test/list/validate/backup/setup)

!!! info "Notes"
    Dispatches to appropriate function based on first argument; shows usage if no args

---

### `main` {: #main }

Orchestrate sync-to-peers workflow

**Source:** `sync_to_peers.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exit code 0 if all syncs succeed, 1 if any fail

**Output:** Depends on verbose/quiet mode

!!! info "Notes"
    Workflow: load config → parse args → perform sync → show summary; exits 1 if failures exist

---

### `main` {: #main }

Entry point and command-line argument dispatcher

**Source:** `oradba_logrotate.sh`

**Arguments:**

- $@ - Command-line arguments (see usage for options)

**Returns:** Exit code from selected operation (0 success, 1 error)

**Output:** Depends on selected operation (install/test/run/list/customize/help)

!!! info "Notes"
    Dispatches to system-wide (root) or user-mode functions; shows usage if invalid option or no args

---

### `main` {: #main }

Entry point and topic dispatcher

**Source:** `oradba_help.sh`

**Arguments:**

- $1 - Topic name (aliases/scripts/variables/config/sql/online) or empty for main help

**Returns:** 0 on success, 1 on unknown topic

**Output:** Depends on selected topic

!!! info "Notes"
    Routes to appropriate show_\*_help function; defaults to main help

---

### `main` {: #main }

Main entry point for Oracle Environment management utility

**Source:** `oradba_env.sh`

**Arguments:**

- $1 - Command (list|show|status|validate|changes|version|help)
- $@ - Command-specific options and arguments

**Returns:** 0 on success, 1 on error

**Output:** Command output to stdout, errors to stderr

!!! info "Notes"
    Dispatches to cmd_\* handler functions for each command
    Shows usage for unknown commands or help flags
    Can be sourced or executed directly

---

### `main` {: #main }

Orchestrate sync-from-peers workflow

**Source:** `sync_from_peers.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exit code 0 if all syncs succeed, 1 if any fail

**Output:** Depends on verbose/quiet mode

!!! info "Notes"
    Workflow: load config → parse args → perform sync → show summary; exits 1 if failures exist

---

### `main` {: #main }

Main entry point for Oracle status display utility

**Source:** `oraup.sh`

**Arguments:**

- [OPTIONS] - Command-line flags (-h|--help, -v|--verbose, -q|--quiet)

**Returns:** 0 on success, 1 on error

**Output:** Oracle status information to stdout (unless --quiet)

!!! info "Notes"
    Quick status display for current Oracle environment
    Shows databases, listeners, and Oracle Homes status
    Part of oraenv/oraup quick environment switching workflow

---

### `migrate_config_files` {: #migrate-config-files }

Move SQL\*Net config files from source to centralized target directory

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - Source directory path, $2 - Target directory path

**Returns:** 0 (always succeeds)

**Output:** Success/warning messages for each file operation, final count

!!! info "Notes"
    Handles sqlnet.ora, tnsnames.ora, ldap.ora, listener.ora; backs up before moving

---

### `monitor_longops` {: #monitor-longops }

Query v$session_longops for a specific SID and display results

**Source:** `longops.sh`

**Arguments:**

- $1 - Oracle SID

**Returns:** 0 on success

**Output:** Formatted table with operation name, user, progress%, elapsed/remaining time, message to stdout

!!! info "Notes"
    Applies OPERATION_FILTER and SHOW_ALL filters; calculates elapsed/remaining minutes

---

### `open_all_pdbs` {: #open-all-pdbs }

Open all pluggable databases in a CDB

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Database SID (must be CDB)

**Returns:** None (always succeeds)

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

!!! info "Notes"
    Executes ALTER PLUGGABLE DATABASE ALL OPEN; checks for failures; warns if some PDBs fail

---

### `parse_args` {: #parse-args }

Parse command line arguments and set mode flags

**Source:** `longops.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exits on unknown option

**Output:** Error messages to stderr for invalid options

!!! info "Notes"
    Sets OPERATION_FILTER, SHOW_ALL, WATCH_MODE, WATCH_INTERVAL, SID_LIST globals

---

### `parse_args` {: #parse-args }

Parse command line arguments and validate required parameters

**Source:** `get_seps_pwd.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exits if validation fails, otherwise returns 0

**Output:** Error message to stderr if connect string missing

!!! info "Notes"
    Sets global vars CONNECT_STRING, CHECK, QUIET, DEBUG, WALLET_DIR

---

### `parse_args` {: #parse-args }

Parse command line arguments and validate required parameters

**Source:** `sync_to_peers.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exits on validation failure

**Output:** Error messages to stderr

!!! info "Notes"
    Sets DRYRUN, VERBOSE, DEBUG, DELETE, QUIET, PEER_HOSTS, REMOTE_BASE, SOURCE; validates source exists

---

### `parse_args` {: #parse-args }

Parse command line arguments and validate required parameters

**Source:** `sync_from_peers.sh`

**Arguments:**

- Command line arguments (passed as "$@")

**Returns:** Exits on validation failure

**Output:** Error messages to stderr

!!! info "Notes"
    Validates -p (source peer) and source path required; sets REMOTE_PEER, SOURCE, PEER_HOSTS

---

### `perform_sync` {: #perform-sync }

Execute rsync to each peer host

**Source:** `sync_to_peers.sh`

**Arguments:**

- None (uses global SOURCE, PEER_HOSTS, REMOTE_BASE, RSYNC_OPTS)

**Returns:** 0 if all syncs succeed, 1 if any fails

**Output:** Status messages via oradba_log; rsync output if verbose

!!! info "Notes"
    Skips local host; converts to absolute paths; tracks success/failure arrays

---

### `perform_sync` {: #perform-sync }

Two-phase sync: pull from source peer to local, then push to all other peers

**Source:** `sync_from_peers.sh`

**Arguments:**

- None (uses global REMOTE_PEER, SOURCE, PEER_HOSTS, REMOTE_BASE, RSYNC_OPTS)

**Returns:** 0 if all syncs succeed, 1 if phase 1 or any phase 2 sync fails

**Output:** Status messages via oradba_log; rsync output if verbose

!!! info "Notes"
    Phase 1: pull from REMOTE_PEER; Phase 2: push to peers (excluding source and self)

---

### `perform_update` {: #perform-update }

Execute update of existing OraDBA installation

**Source:** `oradba_install.sh`

**Arguments:**

- None (uses global variables)

**Returns:** 0 on success, 1 on failure

**Output:** Update progress and status to stdout

!!! info "Notes"
    Orchestrates: backup, preserve configs, extract new version, restore configs
    Version comparison with --force override
    Automatic rollback on failure
    Preserves user customizations

---

### `preserve_configs` {: #preserve-configs }

Save user configuration files before update

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path
- $2 - Temporary config directory path

**Returns:** 0

**Output:** Preserved file list to stdout

!!! info "Notes"
    Preserves: .install_info, etc/oradba.conf, oratab.example
    Copies to temporary directory for restoration after update
    Used to maintain user customizations across updates

---

### `print_message` {: #print-message }

Print colored message to stdout

**Source:** `oradba_logrotate.sh`

**Arguments:**

- $1 - Color code (RED/GREEN/YELLOW), $2 - Message text

**Returns:** None

**Output:** Colored message followed by NC (no color) reset

!!! info "Notes"
    Uses echo -e for ANSI color codes

---

### `process_template` {: #process-template }

Process RMAN script template with tag substitution

**Source:** `oradba_rman.sh`

**Arguments:**

- $1 - Input template file path
- $2 - Output file path
- $3 - Number of channels (optional)
- $4 - Format pattern (optional)
- $5 - Backup tag (optional)
- $6 - Compression level (optional)
- $7 - Backup path (optional)

**Returns:** 0 on success, 1 on error

**Output:** Processed script to output file, status to log

!!! info "Notes"
    Replaces template tags: \<ALLOCATE_CHANNELS\>, \<FORMAT\>, \<TAG\>, etc.
    Supports tablespaces, datafiles, PDB selections
    Handles FRA vs explicit backup paths

---

### `profile_has_oradba` {: #profile-has-oradba }

Check if profile already has OraDBA integration

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Profile file path

**Returns:** 0 if integrated, 1 otherwise

**Output:** None

!!! info "Notes"
    Checks for OraDBA marker comment or oraenv.sh source
    Prevents duplicate profile entries

---

### `prompt_oracle_base` {: #prompt-oracle-base }

Interactively prompt for Oracle Base directory if not specified

**Source:** `oradba_install.sh`

**Arguments:**

- None (sets global ORACLE_BASE_PARAM)

**Returns:** 0 on success, 1 on error

**Output:** Prompt and validation messages to stdout

!!! info "Notes"
    Skipped if ORACLE_BASE_PARAM set, silent mode, or ORACLE_BASE detected
    Validates absolute path and parent directory permissions
    Default: /opt/oracle

---

### `remove_home` {: #remove-home }

Remove an Oracle Home from configuration

**Source:** `oradba_homes.sh`

---

### `restore_configs` {: #restore-configs }

Restore preserved configuration files after update

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path
- $2 - Temporary config directory path

**Returns:** 0

**Output:** Restored file list to stdout

!!! info "Notes"
    Restores files preserved by preserve_configs function
    Creates parent directories as needed
    Removes temporary directory after restoration

---

### `restore_from_backup` {: #restore-from-backup }

Restore installation from backup directory

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path
- $2 - Backup directory path

**Returns:** 0 on success, 1 on failure

**Output:** Restore status to stdout

!!! info "Notes"
    Removes failed installation first
    Renames backup directory back to original location
    Used for rollback if update fails

---

### `run_as_oracle` {: #run-as-oracle }

Execute oradba_services.sh as Oracle user with sudo/su

**Source:** `oradba_services_root.sh`

**Arguments:**

- $1 - Action (start|stop|restart|status)

**Returns:** Exit code from services script

**Output:** Status messages via log_message; service script output

!!! info "Notes"
    Uses 'su - ${ORACLE_USER}' to execute; passes --force flag

---

### `run_monitor` {: #run-monitor }

Execute monitoring for all specified SIDs (single shot or watch mode)

**Source:** `longops.sh`

**Arguments:**

- None (uses global SID_LIST, ORACLE_SID, WATCH_MODE, WATCH_INTERVAL)

**Returns:** 0 on success, 1 if no SID specified

**Output:** Monitoring results for each SID to stdout

!!! info "Notes"
    Watch mode clears screen and loops with WATCH_INTERVAL; sources oraenv per SID

---

### `run_preflight_checks` {: #run-preflight-checks }

Execute all pre-installation validation checks

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation directory path

**Returns:** 0 if all checks pass, 1 on failure

**Output:** Check results and status to stdout

!!! info "Notes"
    Runs: required tools, optional tools, disk space, permissions
    Stops installation if critical checks fail
    Optional tool checks only warn, don't block

---

### `run_user` {: #run-user }

Run logrotate manually with user-specific configurations (non-root)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if not initialized or logrotate missing

**Output:** Processing status for each config, state file location

!!! info "Notes"
    Uses ~/.oradba/logrotate/state/logrotate.status for tracking; requires --install-user first

---

### `search_wallet` {: #search-wallet }

Search wallet for connect string and retrieve password

**Source:** `get_seps_pwd.sh`

**Arguments:**

- None (uses global CONNECT_STRING)

**Returns:** 0 if found, 1 if not found

**Output:** Password (quiet mode) or status messages (normal mode) to stdout

!!! info "Notes"
    Case-insensitive search; supports check mode (verify only) and quiet mode (password only)

---

### `send_notification` {: #send-notification }

Send email notification on success or failure

**Source:** `oradba_rman.sh`

**Arguments:**

- $1 - Status ("SUCCESS" or "FAILURE")

**Returns:** 0 on success, 1 if mail command unavailable

**Output:** Email sent to configured address

!!! info "Notes"
    Respects RMAN_NOTIFY_ON_SUCCESS and RMAN_NOTIFY_ON_ERROR flags
    Includes script log path, SID lists, and execution summary
    Requires mail command (sendmail/mailx)

---

### `set_listener_env` {: #set-listener-env }

Set Oracle environment for listener operations (ORACLE_HOME, PATH, TNS_ADMIN)

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- $1 - Listener name (currently unused, reserved for future)

**Returns:** 0 on success, 1 if cannot determine Oracle Home

**Output:** None (sets environment variables)

!!! info "Notes"
    Gets Oracle Home from get_first_oracle_home; exports ORACLE_HOME, PATH, TNS_ADMIN

---

### `setup_all_tns_admin` {: #setup-all-tns-admin }

Setup centralized TNS_ADMIN for all databases listed in oratab

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None (reads from ${ORATAB} or /etc/oratab)

**Returns:** 0 if all succeeded, 1 if any errors or oratab missing

**Output:** Progress for each database, final summary with success/error counts

!!! info "Notes"
    Skips ASM (+*) and agent entries; processes regular database SIDs only

---

### `setup_tns_admin` {: #setup-tns-admin }

Complete setup of centralized TNS_ADMIN structure for one database

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - ORACLE_SID (defaults to env var), $2 - ORACLE_HOME (defaults to env var)

**Returns:** 0 on success, 1 if SID/ORACLE_BASE missing or creation fails

**Output:** Progress messages, TNS_ADMIN path, profile export suggestion

!!! info "Notes"
    Orchestrates: structure creation, file migration, path updates, symlinks; exports TNS_ADMIN

---

### `should_log` {: #should-log }

Determine if a log message should be displayed based on level and mode

**Source:** `get_seps_pwd.sh`

**Arguments:**

- $1 - Log level (DEBUG/INFO/ERROR)

**Returns:** 0 if should log, 1 if should suppress

**Output:** None

!!! info "Notes"
    Suppresses DEBUG if DEBUG=false; suppresses all if QUIET=true

---

### `should_log` {: #should-log }

Determine if a log message should be displayed based on level and mode

**Source:** `sync_to_peers.sh`

**Arguments:**

- $1 - Log level (DEBUG/INFO/WARN/ERROR)

**Returns:** 0 if should log, 1 if should suppress

**Output:** None

!!! info "Notes"
    Suppresses non-ERROR if QUIET=true; suppresses DEBUG if DEBUG=false

---

### `should_log` {: #should-log }

Determine if a log message should be displayed based on level and mode

**Source:** `sync_from_peers.sh`

**Arguments:**

- $1 - Log level (DEBUG/INFO/WARN/ERROR)

**Returns:** 0 if should log, 1 if should suppress

**Output:** None

!!! info "Notes"
    Suppresses non-ERROR if QUIET=true; suppresses DEBUG if DEBUG=false

---

### `show_alias_help` {: #show-alias-help }

Display comprehensive alias reference documentation

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Alias help from ${ORADBA_PREFIX}/doc/alias_help.txt with navigation info

!!! info "Notes"
    Shows full alias list with usage; provides links to online docs and alih/alig commands

---

### `show_config_help` {: #show-config-help }

Display configuration system documentation and current settings

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Config hierarchy, file locations, precedence order, current values, examples

!!! info "Notes"
    Shows config system structure; explains override mechanism; provides edit commands

---

### `show_home` {: #show-home }

Show detailed information about an Oracle Home

**Source:** `oradba_homes.sh`

---

### `show_installed_extensions` {: #show-installed-extensions }

Display list of all installed extensions with status indicators

**Source:** `oradba_version.sh`

**Arguments:**

- None (sources lib/extensions.sh)

**Returns:** 0 (always succeeds)

**Output:** Formatted extension list: name, version, enabled/disabled status, checksum status (✓/✗)

!!! info "Notes"
    Sorted by priority; shows checksum status for enabled extensions; uses extensions.sh library

---

### `show_main_help` {: #show-main-help }

Display main OraDBA help menu with topic overview

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Formatted help menu (usage, topics, quick help, documentation, examples)

!!! info "Notes"
    Entry point for help system; shows available topics and resources

---

### `show_online_help` {: #show-online-help }

Open online OraDBA documentation in default browser

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (always succeeds)

**Output:** Status message and URL

!!! info "Notes"
    Tries open (macOS), xdg-open (Linux), then fallback to URL display

---

### `show_oracle_status` {: #show-oracle-status }

Display comprehensive Oracle status overview

**Source:** `oraup.sh`

---

### `show_oracle_status_registry` {: #show-oracle-status-registry }

Display Oracle status using registry API (Phase 1)

**Source:** `oraup.sh`

**Arguments:**

- Array of installation objects from registry

!!! info "Notes"
    Uses plugin system for product-specific behavior

---

### `show_scripts_help` {: #show-scripts-help }

List all available OraDBA scripts with descriptions

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Formatted list of scripts from ${ORADBA_BIN_DIR} with extracted purpose lines

!!! info "Notes"
    Extracts purpose from script headers; shows SQL script location; provides usage info

---

### `show_sql_help` {: #show-sql-help }

Display SQL\*Plus scripts help and location info

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** SQL script location, usage within SQL\*Plus, online documentation link

!!! info "Notes"
    Brief help; directs to oh.sql help within SQL\*Plus for comprehensive info

---

### `show_status` {: #show-status }

Display current status of a database instance

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Database SID

**Returns:** 0 on success, 1 if environment sourcing fails

**Output:** One line: "SID: STATUS" or "SID: NOT RUNNING"

!!! info "Notes"
    Queries v$instance for status (OPEN/MOUNTED/etc.); sources environment per SID

---

### `show_status` {: #show-status }

Display status of specified listener

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- $1 - Listener name

**Returns:** 0 on success, 1 if failed to set environment

**Output:** Status output from lsnrctl status

!!! info "Notes"
    Uses lsnrctl status to display listener information

---

### `show_status` {: #show-status }

Show status of all Oracle services (databases and listeners)

**Source:** `oradba_services.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** Combined status output from oradba_dbctl.sh and oradba_lsnrctl.sh

!!! info "Notes"
    Calls oradba_dbctl.sh status and oradba_lsnrctl.sh status

---

### `show_summary` {: #show-summary }

Display synchronization results summary

**Source:** `sync_to_peers.sh`

**Arguments:**

- None (uses global SYNC_SUCCESS, SYNC_FAILURE, VERBOSE, QUIET)

**Returns:** None

**Output:** Success/failure counts and lists to stdout (if verbose mode)

!!! info "Notes"
    Shows local host, successful peers, failed peers; only in verbose mode

---

### `show_summary` {: #show-summary }

Display two-phase synchronization results summary

**Source:** `sync_from_peers.sh`

**Arguments:**

- None (uses global REMOTE_PEER, SYNC_SUCCESS, SYNC_FAILURE, VERBOSE, QUIET)

**Returns:** None

**Output:** Source peer, local host, successful/failed syncs to stdout (if verbose)

!!! info "Notes"
    Shows phase 1 source and phase 2 distribution results; only in verbose mode

---

### `show_usage` {: #show-usage }

Display usage information

**Source:** `oradba_homes.sh`

---

### `show_usage` {: #show-usage }

Display usage information

**Source:** `oraup.sh`

---

### `show_variables_help` {: #show-variables-help }

Display currently set environment variables (ORADBA_\* and Oracle)

**Source:** `oradba_help.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Formatted lists of ORADBA_\* and Oracle variables with descriptions of key vars

!!! info "Notes"
    Shows active environment; explains key configuration variables

---

### `show_version` {: #show-version }

Display script version information

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 (always succeeds)

**Output:** Script name, version string, and OraDBA project description

!!! info "Notes"
    Uses SCRIPT_NAME and SCRIPT_VERSION constants

---

### `start_all` {: #start-all }

Start all Oracle services in configured order

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses STARTUP_ORDER from config)

**Returns:** 0 if all succeeded, 1 if any failures

**Output:** Log messages for each service startup, final summary

!!! info "Notes"
    Processes STARTUP_ORDER (default: listener,database); tracks success/failure counts

---

### `start_database` {: #start-database }

Start an Oracle database instance

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Database SID

**Returns:** 0 on success, 1 on failure

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

!!! info "Notes"
    Sources environment for SID; checks if already running; executes STARTUP; optionally opens PDBs

---

### `start_databases` {: #start-databases }

Start Oracle databases using oradba_dbctl.sh

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)

**Returns:** 0 on success, 1 on failure

**Output:** Log messages with command execution and results

!!! info "Notes"
    Constructs oradba_dbctl.sh start command with options

---

### `start_listener` {: #start-listener }

Start specified Oracle listener

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- $1 - Listener name

**Returns:** 0 on success, 1 if failed to set env or start

**Output:** Log messages; lsnrctl output redirected to LOGFILE

!!! info "Notes"
    Checks if already running first; uses lsnrctl start

---

### `start_listeners` {: #start-listeners }

Start Oracle listeners using oradba_lsnrctl.sh

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)

**Returns:** 0 on success, 1 on failure

**Output:** Log messages with command execution and results

!!! info "Notes"
    Constructs oradba_lsnrctl.sh command with options; respects force mode

---

### `stop_all` {: #stop-all }

Stop all Oracle services in configured order

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses SHUTDOWN_ORDER from config)

**Returns:** 0 if all succeeded, 1 if any failures

**Output:** Log messages for each service shutdown, final summary

!!! info "Notes"
    Processes SHUTDOWN_ORDER (default: database,listener); tracks success/failure counts

---

### `stop_database` {: #stop-database }

Stop an Oracle database instance with timeout and fallback

**Source:** `oradba_dbctl.sh`

**Arguments:**

- $1 - Database SID

**Returns:** 0 on success, 1 on failure

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

!!! info "Notes"
    Tries SHUTDOWN IMMEDIATE with ${SHUTDOWN_TIMEOUT}; falls back to SHUTDOWN ABORT on timeout

---

### `stop_databases` {: #stop-databases }

Stop Oracle databases using oradba_dbctl.sh

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)

**Returns:** 0 on success, 1 on failure

**Output:** Log messages with command execution and results

!!! info "Notes"
    Constructs oradba_dbctl.sh stop command with options

---

### `stop_listener` {: #stop-listener }

Stop specified Oracle listener

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- $1 - Listener name

**Returns:** 0 on success, 1 if failed to set env or stop

**Output:** Log messages; lsnrctl output redirected to LOGFILE

!!! info "Notes"
    Checks if running first; uses lsnrctl stop

---

### `stop_listeners` {: #stop-listeners }

Stop Oracle listeners using oradba_lsnrctl.sh

**Source:** `oradba_services.sh`

**Arguments:**

- None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)

**Returns:** 0 on success, 1 on failure

**Output:** Log messages with command execution and results

!!! info "Notes"
    Constructs oradba_lsnrctl.sh stop command with options

---

### `test_item` {: #test-item }

Execute a single validation test and track results

**Source:** `oradba_validate.sh`

**Arguments:**

- $1 - Test name (description)
- $2 - Test command to execute
- $3 - Test type (required|optional, default: required)

**Returns:** 0 if test passes, 1 if test fails

**Output:** Test result with checkmark/X/warning (if verbose or failed)

!!! info "Notes"
    Updates global counters TOTAL, PASSED, FAILED, WARNINGS
    Optional tests show warning symbol instead of failure

---

### `test_logrotate` {: #test-logrotate }

Test logrotate configurations in dry-run mode (no actual rotation)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 if configs found, 1 if none found

**Output:** Dry-run results for each config (logrotate -d, last 30 lines)

!!! info "Notes"
    Uses logrotate -d for debug/dry-run; safe to run without root

---

### `test_tnsalias` {: #test-tnsalias }

Test TNS alias connectivity using tnsping and display entry details

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - TNS alias name

**Returns:** 0 on success (always returns 0, shows results only)

**Output:** Tnsping results (if available) and TNS entry from tnsnames.ora

!!! info "Notes"
    Uses tnsping for connectivity test (3 attempts), then displays full alias definition

---

### `uninstall_logrotate` {: #uninstall-logrotate }

Remove OraDBA logrotate configurations from system directory (requires root)

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if not root

**Output:** Removal progress for each config, final count

!!! info "Notes"
    Removes oradba\* and oracle-* files from /etc/logrotate.d

---

### `update_extension` {: #update-extension }

Update existing extension with backup of modified files

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Source directory path
- $2 - Extension name
- $3 - Target directory path

**Returns:** 0 on success, 1 on failure

**Output:** Update status to stdout

!!! info "Notes"
    Creates .save backups of modified configuration files
    Compares checksums if .extension.checksum exists
    Similar to RPM update behavior for configs

---

### `update_profile` {: #update-profile }

Add OraDBA auto-loading to shell profile

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Installation prefix directory

**Returns:** 0 on success, 1 on error

**Output:** Profile update status and manual instructions to stdout

!!! info "Notes"
    Interactive prompt if TTY available (unless --silent or --update-profile)
    Creates backup of profile before modification
    Adds oraenv.sh sourcing and oraup.sh status display
    Respects UPDATE_PROFILE variable (yes/no/auto)

---

### `update_sqlnet_paths` {: #update-sqlnet-paths }

Update sqlnet.ora with centralized log and trace directory paths

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- $1 - sqlnet.ora file path, $2 - Base directory for logs/traces

**Returns:** 0 (always succeeds if file exists)

**Output:** Update confirmation message

!!! info "Notes"
    Removes existing LOG/TRACE_DIRECTORY lines, appends new paths for client/server

---

### `usage` {: #usage }

Display usage information and command reference

**Source:** `oradba_extension.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Usage help to stdout

!!! info "Notes"
    Shows all extension management commands
    Includes add, create, list, info, validate, discover, paths, enabled/disabled

---

### `usage` {: #usage }

Display usage information, options, examples, and common operation patterns

**Source:** `longops.sh`

**Arguments:**

- None

**Returns:** Exits with code 0

**Output:** Usage text, options, examples, pattern reference to stdout

!!! info "Notes"
    Shows watch mode, operation filters, interval config, common patterns for RMAN/DataPump

---

### `usage` {: #usage }

Display usage information and command-line options

**Source:** `dbstatus.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Usage information to stdout

!!! info "Notes"
    Shows options, examples, and requirements

---

### `usage` {: #usage }

Display installer usage information and examples

**Source:** `oradba_install.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Usage help to stdout

!!! info "Notes"
    Shows installation modes, location options, examples
    Includes pre-Oracle installation instructions

---

### `usage` {: #usage }

Display usage information for validation script

**Source:** `oradba_validate.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Usage help to stdout

!!! info "Notes"
    Shows options and examples for running validation

---

### `usage` {: #usage }

Display usage information and examples

**Source:** `get_seps_pwd.sh`

**Arguments:**

- None

**Returns:** Exits with code 0

**Output:** Usage text, options, examples, notes to stdout

!!! info "Notes"
    Shows required connect string option, optional wallet dir, check/quiet modes

---

### `usage` {: #usage }

Display comprehensive help information for version utility

**Source:** `oradba_version.sh`

**Arguments:**

- None

**Returns:** None (prints to stdout)

**Output:** Multi-section help (options, examples, exit codes)

!!! info "Notes"
    Shows all command-line options for version checking, verification, updates

---

### `usage` {: #usage }

Display usage information, commands, examples

**Source:** `oradba_setup.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Usage text, commands, options, examples, description

!!! info "Notes"
    Shows post-installation tasks: link-oratab, check, show-config

---

### `usage` {: #usage }

Display comprehensive usage information for RMAN wrapper script

**Source:** `oradba_rman.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Usage help, options, examples to stdout

!!! info "Notes"
    Shows required/optional arguments, configuration, template tags
    Comprehensive RMAN backup automation documentation

---

### `usage` {: #usage }

Display comprehensive help for SQL\*Net configuration management

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None

**Returns:** None (prints to stdout)

**Output:** Multi-section usage text (commands, options, templates, examples)

!!! info "Notes"
    Shows installation, setup, generation, testing, validation operations

---

### `usage` {: #usage }

Display usage information and examples

**Source:** `oradba_dbctl.sh`

**Arguments:**

- None

**Returns:** Exits with code 1

**Output:** Usage text, options, examples, environment variables to stdout

!!! info "Notes"
    Shows action modes (start/stop/restart/status), timeout config, SID selection

---

### `usage` {: #usage }

Display help for Oracle listener control

**Source:** `oradba_lsnrctl.sh`

**Arguments:**

- None

**Returns:** Exits with code 1

**Output:** Multi-section help (actions, options, arguments, examples, env vars)

!!! info "Notes"
    Shows start/stop/restart/status actions; supports multiple listeners

---

### `usage` {: #usage }

Display usage information, options, examples

**Source:** `sync_to_peers.sh`

**Arguments:**

- None

**Returns:** Exits with code 0

**Output:** Usage text, configuration summary, examples to stdout

!!! info "Notes"
    Shows rsync options, peer hosts, SSH config; demonstrates common use cases

---

### `usage` {: #usage }

Display help for Oracle services orchestration

**Source:** `oradba_services.sh`

**Arguments:**

- None

**Returns:** Exits with code 1

**Output:** Multi-section help (actions, options, config, examples, env vars)

!!! info "Notes"
    Shows start/stop/restart/status actions; explains config file usage

---

### `usage` {: #usage }

Display comprehensive help for logrotate configuration management

**Source:** `oradba_logrotate.sh`

**Arguments:**

- None

**Returns:** None (prints to stdout)

**Output:** Multi-section help (scenarios, options, examples, notes for root/user modes)

!!! info "Notes"
    Explains both system-wide (root) and user-mode (non-root) operation scenarios

---

### `usage` {: #usage }

Display comprehensive help information and exit

**Source:** `oradba_check.sh`

**Arguments:**

- None

**Returns:** Exits with code 0

**Output:** Multi-section help (usage, options, exit codes, examples, checks, download)

!!! info "Notes"
    Shows script version, all command-line options, performed checks, standalone usage

---

### `usage` {: #usage }

Display usage information

**Source:** `oradba_env.sh`

---

### `usage` {: #usage }

Display usage information, options, examples

**Source:** `sync_from_peers.sh`

**Arguments:**

- None

**Returns:** Exits with code 0

**Output:** Usage text, configuration summary, examples to stdout

!!! info "Notes"
    Shows required -p option for source peer; demonstrates two-phase sync pattern

---

### `usage` {: #usage }

Display usage information and examples

**Source:** `oradba_services_root.sh`

**Arguments:**

- None

**Returns:** None (outputs to stdout)

**Output:** Usage text, actions, environment variables, examples

!!! info "Notes"
    Shows wrapper purpose and available service actions

---

### `validate_config` {: #validate-config }

Validate SQL\*Net configuration files and environment

**Source:** `oradba_sqlnet.sh`

**Arguments:**

- None

**Returns:** 0 if all checks pass, 1 if any errors found

**Output:** Validation results for each component (sqlnet.ora, tnsnames.ora, ORACLE_HOME)

!!! info "Notes"
    Checks file existence, readability, basic syntax; reports errors with count

---

### `validate_environment` {: #validate-environment }

Validate wallet directory existence and mkstore availability

**Source:** `get_seps_pwd.sh`

**Arguments:**

- None

**Returns:** Exits with code 1 on validation failure

**Output:** Error messages via oradba_log

!!! info "Notes"
    Checks wallet dir exists and is readable; checks mkstore command available

---

### `validate_extension_name` {: #validate-extension-name }

Validate extension name meets naming requirements

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Extension name

**Returns:** 0 if valid, 1 if invalid

**Output:** Error messages to stderr

!!! info "Notes"
    Requirements: alphanumeric/dash/underscore, starts with letter
    Example valid names: myext, my_ext, my-ext-123

---

### `validate_extension_structure` {: #validate-extension-structure }

Validate extension has proper directory structure

**Source:** `oradba_extension.sh`

**Arguments:**

- $1 - Extension directory path

**Returns:** 0 if valid structure, 1 otherwise

**Output:** None

!!! info "Notes"
    Valid if has .extension file OR standard directories (bin/sql/rcv/etc/lib)
    Used to verify downloaded/extracted extensions

---

### `validate_homes` {: #validate-homes }

Validate Oracle Homes configuration

**Source:** `oradba_homes.sh`

---

### `validate_write_permissions` {: #validate-write-permissions }

Validate write permissions for installation target

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - Target installation path

**Returns:** 0 if writable, 1 otherwise

**Output:** Permission errors and suggestions to stderr

!!! info "Notes"
    Checks target if exists, otherwise checks parent directory
    Suggests sudo or alternative location if no permissions
    Handles root directory edge case

---

### `version` {: #version }

Display script version information

**Source:** `dbstatus.sh`

**Arguments:**

- None

**Returns:** 0 (exits after display)

**Output:** Version string to stdout

!!! info "Notes"
    Simple version display and exit

---

### `version_compare` {: #version-compare }

Compare two semantic version strings

**Source:** `oradba_install.sh`

**Arguments:**

- $1 - First version (e.g., "1.2.3")
- $2 - Second version (e.g., "1.2.4")

**Returns:** 0 if v1 == v2, 1 if v1 \> v2, 2 if v1 \< v2

**Output:** None

!!! info "Notes"
    Handles versions with or without 'v' prefix
    Compares major.minor.patch numerically
    Ignores pre-release suffixes (e.g., -beta)

---

### `version_info` {: #version-info }

Display comprehensive version information, installation details, and integrity check

**Source:** `oradba_version.sh`

**Arguments:**

- None

**Returns:** Return code from check_integrity (0 if verified, 1 if failed)

**Output:** Version, install path, installation metadata, installed extensions, integrity status

!!! info "Notes"
    Reads .install_info for details; calls show_installed_extensions and check_integrity

---
