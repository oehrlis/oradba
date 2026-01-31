# Scripts and Commands

Command-line scripts and tools for OraDBA operations.

---

### ``

**Source:** `dbstatus.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and command-line options

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Usage information to stdout

---

### ``

!!! info "Notes"
    Shows options, examples, and requirements

---

### ``

**Source:** `dbstatus.sh`

---

### ``

---

### `version`

---

### ``

Display script version information

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Version string to stdout

---

### ``

!!! info "Notes"
    Simple version display and exit

---

### ``

**Source:** `dbstatus.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for database status display

---

### ``

**Arguments:**

- [OPTIONS] - Command-line options

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Database status information to stdout

---

### ``

!!! info "Notes"
    Parses arguments, validates environment, calls show_database_status

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 0

---

### ``

**Output:** Usage text, options, examples, notes to stdout

---

### ``

!!! info "Notes"
    Shows required connect string option, optional wallet dir, check/quiet modes

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `should_log`

---

### ``

Determine if a log message should be displayed based on level and mode

---

### ``

**Arguments:**

- $1 - Log level (DEBUG/INFO/ERROR)

---

### ``

**Returns:** 0 if should log, 1 if should suppress

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Suppresses DEBUG if DEBUG=false; suppresses all if QUIET=true

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `get_entry`

---

### ``

Retrieve a wallet entry value by key using mkstore

---

### ``

**Arguments:**

- $1 - Wallet entry key

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Entry value to stdout

---

### ``

!!! info "Notes"
    Uses mkstore -viewEntry; filters output to extract value after '= '

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `parse_args`

---

### ``

Parse command line arguments and validate required parameters

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exits if validation fails, otherwise returns 0

---

### ``

**Output:** Error message to stderr if connect string missing

---

### ``

!!! info "Notes"
    Sets global vars CONNECT_STRING, CHECK, QUIET, DEBUG, WALLET_DIR

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `validate_environment`

---

### ``

Validate wallet directory existence and mkstore availability

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1 on validation failure

---

### ``

**Output:** Error messages via oradba_log

---

### ``

!!! info "Notes"
    Checks wallet dir exists and is readable; checks mkstore command available

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `load_wallet_password`

---

### ``

Load wallet password from file, environment, or interactive prompt

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (sets global WALLET_PASSWORD)

---

### ``

**Output:** Debug message if loaded from file; prompt if interactive

---

### ``

!!! info "Notes"
    Tries ${WALLET_DIR}/.wallet_pwd (base64), then env var, then prompts

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `search_wallet`

---

### ``

Search wallet for connect string and retrieve password

---

### ``

**Arguments:**

- None (uses global CONNECT_STRING)

---

### ``

**Returns:** 0 if found, 1 if not found

---

### ``

**Output:** Password (quiet mode) or status messages (normal mode) to stdout

---

### ``

!!! info "Notes"
    Case-insensitive search; supports check mode (verify only) and quiet mode (password only)

---

### ``

**Source:** `get_seps_pwd.sh`

---

### ``

---

### `main`

---

### ``

Orchestrate wallet password retrieval workflow

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exit code from search_wallet (0 success, 1 failure)

---

### ``

**Output:** Depends on mode (quiet/check/normal)

---

### ``

!!! info "Notes"
    Workflow: parse args → validate → load password → search wallet

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information, options, examples, and common operation patterns

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 0

---

### ``

**Output:** Usage text, options, examples, pattern reference to stdout

---

### ``

!!! info "Notes"
    Shows watch mode, operation filters, interval config, common patterns for RMAN/DataPump

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `parse_args`

---

### ``

Parse command line arguments and set mode flags

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exits on unknown option

---

### ``

**Output:** Error messages to stderr for invalid options

---

### ``

!!! info "Notes"
    Sets OPERATION_FILTER, SHOW_ALL, WATCH_MODE, WATCH_INTERVAL, SID_LIST globals

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `monitor_longops`

---

### ``

Query v$session_longops for a specific SID and display results

---

### ``

**Arguments:**

- $1 - Oracle SID

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Formatted table with operation name, user, progress%, elapsed/remaining time, message to stdout

---

### ``

!!! info "Notes"
    Applies OPERATION_FILTER and SHOW_ALL filters; calculates elapsed/remaining minutes

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `display_header`

---

### ``

Display formatted header with timestamp and database info

---

### ``

**Arguments:**

- $1 - Oracle SID

---

### ``

**Returns:** None

---

### ``

**Output:** Header line with SID, hostname, timestamp, operation filter to stdout

---

### ``

!!! info "Notes"
    Shows monitoring context for watch mode refreshes

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `run_monitor`

---

### ``

Execute monitoring for all specified SIDs (single shot or watch mode)

---

### ``

**Arguments:**

- None (uses global SID_LIST, ORACLE_SID, WATCH_MODE, WATCH_INTERVAL)

---

### ``

**Returns:** 0 on success, 1 if no SID specified

---

### ``

**Output:** Monitoring results for each SID to stdout

---

### ``

!!! info "Notes"
    Watch mode clears screen and loops with WATCH_INTERVAL; sources oraenv per SID

---

### ``

**Source:** `longops.sh`

---

### ``

---

### `main`

---

### ``

Orchestrate long operations monitoring workflow

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exit code from run_monitor

---

### ``

**Output:** Depends on watch/filter modes

---

### ``

!!! info "Notes"
    Workflow: parse args → run monitor; defaults to $ORACLE_SID if no SIDs specified

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_pass`

---

### ``

Log successful check with green checkmark

---

### ``

**Arguments:**

- $1 - Success message

---

### ``

**Returns:** None

---

### ``

**Output:** Green ✓ followed by message (suppressed in quiet mode)

---

### ``

!!! info "Notes"
    Increments CHECKS_PASSED counter; respects --quiet flag

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_fail`

---

### ``

Log failed check with red X

---

### ``

**Arguments:**

- $1 - Failure message

---

### ``

**Returns:** None

---

### ``

**Output:** Red ✗ followed by message (always displayed)

---

### ``

!!! info "Notes"
    Increments CHECKS_FAILED counter; never suppressed (critical errors)

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_warn`

---

### ``

Log warning with yellow warning sign

---

### ``

**Arguments:**

- $1 - Warning message

---

### ``

**Returns:** None

---

### ``

**Output:** Yellow ⚠ followed by message (suppressed in quiet mode)

---

### ``

!!! info "Notes"
    Increments CHECKS_WARNING counter; respects --quiet flag

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_info`

---

### ``

Log informational message with blue info icon

---

### ``

**Arguments:**

- $1 - Informational message

---

### ``

**Returns:** None

---

### ``

**Output:** Blue ℹ followed by message (suppressed in quiet mode)

---

### ``

!!! info "Notes"
    Increments CHECKS_INFO counter; respects --quiet flag

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_debug`

---

### ``

Display debug message when debug mode is enabled

---

### ``

**Arguments:**

- $* - Message text

---

### ``

**Returns:** 0

---

### ``

**Output:** Debug message to stderr (only if ORADBA_DEBUG=true)

---

### ``

!!! info "Notes"
    Enable via ORADBA_DEBUG=true or --debug flag

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `log_header`

---

### ``

Display bold section header with underline

---

### ``

**Arguments:**

- $1 - Header text

---

### ``

**Returns:** None

---

### ``

**Output:** Blank line, bold header text, dynamic underline (suppressed in quiet mode)

---

### ``

!!! info "Notes"
    Underline matches header length; respects --quiet flag

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `usage`

---

### ``

Display comprehensive help information and exit

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 0

---

### ``

**Output:** Multi-section help (usage, options, exit codes, examples, checks, download)

---

### ``

!!! info "Notes"
    Shows script version, all command-line options, performed checks, standalone usage

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_system_info`

---

### ``

Display system information (OS, version, hostname, user, shell)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds)

---

### ``

**Output:** Formatted system information messages

---

### ``

!!! info "Notes"
    Informational only; uses uname, /etc/os-release, sw_vers (macOS)

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_system_tools`

---

### ``

Verify availability of critical system tools required for OraDBA

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all tools found, 1 if any missing

---

### ``

**Output:** Pass/fail for each tool: bash, tar, awk, sed, grep, find, sort, sha256sum/shasum, base64

---

### ``

!!! info "Notes"
    Critical check; missing tools prevent installation; shows versions in verbose mode

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_optional_tools`

---

### ``

Check availability of optional but recommended tools

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds, warnings only)

---

### ``

**Output:** Pass/warn for rlwrap, less, curl, wget with installation suggestions

---

### ``

!!! info "Notes"
    Informational; missing tools reduce user experience but don't block installation

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_github_connectivity`

---

### ``

Test connectivity to GitHub API for update/installation features

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds, informational)

---

### ``

**Output:** Pass/warn for GitHub API accessibility with workaround suggestions

---

### ``

!!! info "Notes"
    Tests api.github.com with 5s timeout; informational only, tarball fallback available

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_disk_space`

---

### ``

Verify sufficient disk space for OraDBA installation (100 MB required)

---

### ``

**Arguments:**

- None (uses $CHECK_DIR from command-line or default)

---

### ``

**Returns:** 0 if sufficient space, 1 if insufficient

---

### ``

**Output:** Checking directory, available space, required space, pass/fail status

---

### ``

!!! info "Notes"
    Critical check; finds existing parent if target doesn't exist; uses df -Pm

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_oracle_environment`

---

### ``

Check Oracle environment variables (ORACLE_HOME, ORACLE_BASE, ORACLE_SID, TNS_ADMIN)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds, informational)

---

### ``

**Output:** Pass/warn/info for each env var with paths and existence checks

---

### ``

!!! info "Notes"
    Informational only; validates directory existence for set variables; not required for installation

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_oracle_tools`

---

### ``

Check availability of Oracle tools (sqlplus, rman, lsnrctl, tnsping)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds, informational)

---

### ``

**Output:** Pass/warn for each tool with paths in verbose mode

---

### ``

!!! info "Notes"
    Skipped if ORACLE_HOME not set; informational only; warns if tools missing

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_database_connectivity`

---

### ``

Test database connectivity and process availability

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds, informational)

---

### ``

**Output:** Process status, connection test results, DB version in verbose mode

---

### ``

!!! info "Notes"
    Skipped if ORACLE_HOME/ORACLE_SID not set; checks pmon process, tests sqlplus connection with 5s timeout

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_oracle_versions`

---

### ``

Scan Oracle Inventory and common locations for installed Oracle Homes

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds, informational)

---

### ``

**Output:** Inventory path, Oracle Homes found with versions in verbose mode

---

### ``

!!! info "Notes"
    Reads /etc/oraInst.loc or /var/opt/oracle/oraInst.loc; parses inventory.xml; falls back to common locations

---

### ``

**Source:** `oradba_check.sh`

---

### ``

---

### `check_oradba_installation`

---

### ``

Verify OraDBA installation completeness and display installation info

---

### ``

**Arguments:**

- None (uses $CHECK_DIR)

---

### ``

**Returns:** 0 (always succeeds, informational)

---

### ``

**Output:** Directory existence, .install_info details, key directories (bin, lib, sql, etc)

---

### ``

!!! info "Notes"
    Informational; shows install metadata in verbose mode; warns if directories missing

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1

---

### ``

**Output:** Usage text, options, examples, environment variables to stdout

---

### ``

!!! info "Notes"
    Shows action modes (start/stop/restart/status), timeout config, SID selection

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `get_databases`

---

### ``

Parse oratab to extract database entries

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if oratab not found

---

### ``

**Output:** One line per database: SID:HOME:FLAG (excludes comments, empty lines, dummy entries)

---

### ``

!!! info "Notes"
    Filters out entries with flag=D; reads from ${ORATAB:-/etc/oratab}

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `should_autostart`

---

### ``

Prompt for justification when operating on multiple databases

---

### ``

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Database count

---

### ``

**Returns:** 0 if confirmed, 1 if cancelled or no justification

---

### ``

**Output:** Warning banner, prompts for justification and confirmation to stdout

---

### ``

!!! info "Notes"
    Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `ask_justification`

---

### ``

Prompt for justification when operating on multiple databases

---

### ``

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Database count

---

### ``

**Returns:** 0 if confirmed, 1 if cancelled or no justification

---

### ``

**Output:** Warning banner, prompts for justification and confirmation to stdout

---

### ``

!!! info "Notes"
    Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `start_database`

---

### ``

Start an Oracle database instance

---

### ``

**Arguments:**

- $1 - Database SID

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

---

### ``

!!! info "Notes"
    Sources environment for SID; checks if already running; executes STARTUP; optionally opens PDBs

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `open_all_pdbs`

---

### ``

Open all pluggable databases in a CDB

---

### ``

**Arguments:**

- $1 - Database SID (must be CDB)

---

### ``

**Returns:** None (always succeeds)

---

### ``

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

---

### ``

!!! info "Notes"
    Executes ALTER PLUGGABLE DATABASE ALL OPEN; checks for failures; warns if some PDBs fail

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `stop_database`

---

### ``

Stop an Oracle database instance with timeout and fallback

---

### ``

**Arguments:**

- $1 - Database SID

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Status messages via oradba_log, SQL output to ${LOGFILE}

---

### ``

!!! info "Notes"
    Tries SHUTDOWN IMMEDIATE with ${SHUTDOWN_TIMEOUT}; falls back to SHUTDOWN ABORT on timeout

---

### ``

**Source:** `oradba_dbctl.sh`

---

### ``

---

### `show_status`

---

### ``

Display current status of a database instance

---

### ``

**Arguments:**

- $1 - Database SID

---

### ``

**Returns:** 0 on success, 1 if environment sourcing fails

---

### ``

**Output:** One line: "SID: STATUS" or "SID: NOT RUNNING"

---

### ``

!!! info "Notes"
    Queries v$instance for status (OPEN/MOUNTED/etc.); sources environment per SID

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1

---

### ``

**Output:** Usage text, options, examples, environment variables to stdout

---

### ``

!!! info "Notes"
    Shows action modes (start/stop/restart/status), timeout config, connector selection

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `get_connectors`

---

### ``

Get Data Safe connectors from registry

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** One line per connector: NAME:HOME:AUTOSTART (excludes dummy entries)

---

### ``

!!! info "Notes"
    Uses oradba_registry API to get datasafe type installations

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `ask_justification`

---

### ``

Prompt for justification when operating on multiple connectors

---

### ``

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Connector count

---

### ``

**Returns:** 0 if confirmed, 1 if cancelled or no justification

---

### ``

**Output:** Warning banner, prompts for justification and confirmation to stdout

---

### ``

!!! info "Notes"
    Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `get_cman_instance_name`

---

### ``

Extract CMAN instance name from cman.ora configuration

---

### ``

**Arguments:**

- $1 - Connector home path

---

### ``

**Returns:** 0 on success, 1 if cman.ora not found

---

### ``

**Output:** CMAN instance name (defaults to "cust_cman" if not found)

---

### ``

!!! info "Notes"
    Parses first non-comment line with = sign from cman.ora

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `start_connector`

---

### ``

Start a Data Safe connector instance

---

### ``

**Arguments:**

- $1 - Connector name, $2 - Connector home path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Status messages via oradba_log

---

### ``

!!! info "Notes"
    Uses cmctl startup command; checks if already running first

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `stop_connector`

---

### ``

Stop a Data Safe connector instance with timeout and fallback

---

### ``

**Arguments:**

- $1 - Connector name, $2 - Connector home path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Status messages via oradba_log

---

### ``

!!! info "Notes"
    Uses cmctl shutdown command; attempts graceful shutdown with timeout

---

### ``

**Source:** `oradba_dsctl.sh`

---

### ``

---

### `show_status`

---

### ``

Display current status of a connector

---

### ``

**Arguments:**

- $1 - Connector name, $2 - Connector home path

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** One line: "NAME: STATUS"

---

### ``

!!! info "Notes"
    Uses plugin_check_status from datasafe_plugin if available

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_list`

---

### ``

List available SIDs and/or Homes

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_show`

---

### ``

Show detailed information about SID or Home

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_validate`

---

### ``

Validate current Oracle environment or specified target

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_status`

---

### ``

Check status of Oracle instance/service

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_changes`

---

### ``

Check for configuration file changes

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `cmd_version`

---

### ``

Display version information

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_env.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for Oracle Environment management utility

---

### ``

**Arguments:**

- $1 - Command (list|show|status|validate|changes|version|help)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Command output to stdout, errors to stderr

---

### ``

!!! info "Notes"
    Dispatches to cmd_* handler functions for each command

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and command reference

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Usage help to stdout

---

### ``

!!! info "Notes"
    Shows all extension management commands

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `validate_extension_name`

---

### ``

Validate extension name meets naming requirements

---

### ``

**Arguments:**

- $1 - Extension name

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

**Output:** Error messages to stderr

---

### ``

!!! info "Notes"
    Requirements: alphanumeric/dash/underscore, starts with letter

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `download_github_release`

---

### ``

Download latest extension template from GitHub

---

### ``

**Arguments:**

- $1 - Output file path for downloaded tarball

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Download status and tag name to stdout

---

### ``

!!! info "Notes"
    Downloads from oehrlis/oradba_extension repository

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `download_extension_from_github`

---

### ``

Download extension from GitHub repository

---

### ``

**Arguments:**

- $1 - Repository (owner/repo format)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Download status to stdout, errors to stderr

---

### ``

!!! info "Notes"
    Tries: specific release → latest release → tags → main/master branch

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `validate_extension_structure`

---

### ``

Validate extension has proper directory structure

---

### ``

**Arguments:**

- $1 - Extension directory path

---

### ``

**Returns:** 0 if valid structure, 1 otherwise

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Valid if has .extension file OR standard directories (bin/sql/rcv/etc/lib)

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `update_extension`

---

### ``

Update existing extension with backup of modified files

---

### ``

**Arguments:**

- $1 - Source directory path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Update status to stdout

---

### ``

!!! info "Notes"
    Creates .save backups of modified configuration files

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_create`

---

### ``

Create new extension from template

---

### ``

**Arguments:**

- $@ - Command-line options (--path, --template, --from-github)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Creation status and instructions to stdout

---

### ``

!!! info "Notes"
    Supports custom templates, GitHub templates, or embedded templates

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_add`

---

### ``

Add/install extension from source

---

### ``

**Arguments:**

- $@ - Source and command-line options

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Installation status to stdout

---

### ``

!!! info "Notes"
    Supports: GitHub repos (owner/repo[@version]), URLs, local tarballs

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `format_status`

---

### ``

Format extension status with color

---

### ``

**Arguments:**

- $1 - Status string ("Enabled" or "Disabled")

---

### ``

**Returns:** 0

---

### ``

**Output:** Colored status string to stdout

---

### ``

!!! info "Notes"
    Green for Enabled, Red for Disabled, Yellow for unknown

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_list`

---

### ``

List all installed extensions with details

---

### ``

**Arguments:**

- $@ - Command-line options (--verbose, -v)

---

### ``

**Returns:** 0

---

### ``

**Output:** Formatted table of extensions to stdout

---

### ``

!!! info "Notes"
    Shows: name, version, priority, status (enabled/disabled)

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_info`

---

### ``

Display detailed information about specific extension

---

### ``

**Arguments:**

- $1 - Extension name

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Extension metadata to stdout

---

### ``

!!! info "Notes"
    Shows: name, version, description, author, status, provides, path

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_validate`

---

### ``

Validate specific extension structure and metadata

---

### ``

**Arguments:**

- $1 - Extension name

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

**Output:** Validation results to stdout

---

### ``

!!! info "Notes"
    Checks: directory exists, .extension file, required fields, structure

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_validate_all`

---

### ``

Validate all installed extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all valid, 1 if any invalid

---

### ``

**Output:** Validation summary for all extensions to stdout

---

### ``

!!! info "Notes"
    Iterates through all extensions found by get_all_extensions()

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_discover`

---

### ``

Discover and list all extensions in search paths

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Discovered extensions with paths to stdout

---

### ``

!!! info "Notes"
    Searches in ORADBA_LOCAL_BASE and configured paths

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_paths`

---

### ``

Display extension search paths

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** List of extension search paths to stdout

---

### ``

!!! info "Notes"
    Shows configured ORADBA_LOCAL_BASE and extension directories

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_enabled`

---

### ``

List only enabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Formatted table of enabled extensions to stdout

---

### ``

!!! info "Notes"
    Filters extensions by enabled status

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_disabled`

---

### ``

List only disabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Formatted table of disabled extensions to stdout

---

### ``

!!! info "Notes"
    Filters extensions by disabled status

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_enabled`

---

### ``

List only enabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Formatted table of enabled extensions to stdout

---

### ``

!!! info "Notes"
    Filters extensions by enabled status

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `cmd_disabled`

---

### ``

List only disabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Formatted table of disabled extensions to stdout

---

### ``

!!! info "Notes"
    Filters extensions by disabled status

---

### ``

**Source:** `oradba_extension.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for extension management tool

---

### ``

**Arguments:**

- $1 - Command (add|create|list|info|validate|validate-all|discover|paths|enabled|disabled|enable|disable|help)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Command output to stdout, errors to stderr

---

### ``

!!! info "Notes"
    Dispatcher to cmd_* handler functions

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_main_help`

---

### ``

Display main OraDBA help menu with topic overview

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Formatted help menu (usage, topics, quick help, documentation, examples)

---

### ``

!!! info "Notes"
    Entry point for help system; shows available topics and resources

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_alias_help`

---

### ``

Display comprehensive alias reference documentation

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Alias help from ${ORADBA_PREFIX}/doc/alias_help.txt with navigation info

---

### ``

!!! info "Notes"
    Shows full alias list with usage; provides links to online docs and alih/alig commands

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_scripts_help`

---

### ``

List all available OraDBA scripts with descriptions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Formatted list of scripts from ${ORADBA_BIN_DIR} with extracted purpose lines

---

### ``

!!! info "Notes"
    Extracts purpose from script headers; shows SQL script location; provides usage info

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_variables_help`

---

### ``

Display currently set environment variables (ORADBA_* and Oracle)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Formatted lists of ORADBA_* and Oracle variables with descriptions of key vars

---

### ``

!!! info "Notes"
    Shows active environment; explains key configuration variables

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_config_help`

---

### ``

Display configuration system documentation and current settings

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Config hierarchy, file locations, precedence order, current values, examples

---

### ``

!!! info "Notes"
    Shows config system structure; explains override mechanism; provides edit commands

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_sql_help`

---

### ``

Display SQL*Plus scripts help and location info

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** SQL script location, usage within SQL*Plus, online documentation link

---

### ``

!!! info "Notes"
    Brief help; directs to oh.sql help within SQL*Plus for comprehensive info

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_online_help`

---

### ``

Open online OraDBA documentation in default browser

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds)

---

### ``

**Output:** Status message and URL

---

### ``

!!! info "Notes"
    Tries open (macOS), xdg-open (Linux), then fallback to URL display

---

### ``

**Source:** `oradba_help.sh`

---

### ``

---

### `show_main_help`

---

### ``

Display main OraDBA help menu with topic overview

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Formatted help menu (usage, topics, quick help, documentation, examples)

---

### ``

!!! info "Notes"
    Entry point for help system; shows available topics and resources

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `show_usage`

---

### ``

Display usage information

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `list_homes`

---

### ``

List registered Oracle Homes

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `show_home`

---

### ``

Show detailed information about an Oracle Home

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `add_home`

---

### ``

Add a new Oracle Home

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `remove_home`

---

### ``

Remove an Oracle Home from configuration

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `generate_home_name`

---

### ``

Generate home name from directory name and product type

---

### ``

**Arguments:**

- $1 - Directory name (basename of path)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized home name

---

### ``

!!! info "Notes"
    Java, JRE, and instant client use lowercase conventions

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `discover_homes`

---

### ``

Auto-discover Oracle Homes

---

### ``

---

### ``

---

### ``

---

### ``

!!! info "Notes"
    Wrapper around auto_discover_oracle_homes() in oradba_common.sh

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `validate_homes`

---

### ``

Validate Oracle Homes configuration

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `export_config`

---

### ``

Export Oracle Homes configuration

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `import_config`

---

### ``

Import Oracle Homes configuration

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `dedupe_homes`

---

### ``

Remove duplicate entries from configuration

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_homes.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for Oracle Homes management

---

### ``

**Arguments:**

- $1 - Command (list|show|add|remove|discover|validate|dedupe|export|import)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Command output to stdout, errors to stderr

---

### ``

!!! info "Notes"
    Dispatches to appropriate command handler function

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `determine_default_prefix`

---

### ``

Auto-detect default OraDBA installation prefix from Oracle environment

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if detection failed

---

### ``

**Output:** Installation prefix path to stdout (e.g., /opt/oracle/local/oradba)

---

### ``

!!! info "Notes"
    Priority: ORACLE_BASE > ORACLE_HOME > oratab > /opt/oracle > fail

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `log_info`

---

### ``

Display informational message with green [INFO] prefix

---

### ``

**Arguments:**

- $* - Message text

---

### ``

**Returns:** 0

---

### ``

**Output:** Colored message to stdout

---

### ``

!!! info "Notes"
    Simple installer logging, not the full oradba_log system

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `log_warn`

---

### ``

Display warning message with yellow [WARN] prefix

---

### ``

**Arguments:**

- $* - Message text

---

### ``

**Returns:** 0

---

### ``

**Output:** Colored message to stdout

---

### ``

!!! info "Notes"
    Simple installer logging

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `log_error`

---

### ``

Display error message with red [ERROR] prefix

---

### ``

**Arguments:**

- $* - Message text

---

### ``

**Returns:** 0

---

### ``

**Output:** Colored message to stderr

---

### ``

!!! info "Notes"
    Simple installer logging

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `log_debug`

---

### ``

Display debug message with [DEBUG] prefix when debug mode is enabled

---

### ``

**Arguments:**

- $* - Message text

---

### ``

**Returns:** 0

---

### ``

**Output:** Debug message to stderr (only if ORADBA_DEBUG=true)

---

### ``

!!! info "Notes"
    Enable via ORADBA_DEBUG=true or --debug flag

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_archived_version`

---

### ``

Check if version is pre-1.0 archived release and display notice

---

### ``

**Arguments:**

- $1 - Version string (e.g., "0.16.0")

---

### ``

**Returns:** 0 if archived (pre-1.0), 1 otherwise

---

### ``

**Output:** Archived version notice to stdout

---

### ``

!!! info "Notes"
    All 0.x.x versions are considered archived

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `cleanup`

---

### ``

Remove temporary directory on script exit

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Called automatically via trap EXIT

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `backup_modified_files`

---

### ``

Backup modified configuration files before update

---

### ``

**Arguments:**

- $1 - Installation prefix directory

---

### ``

**Returns:** 0

---

### ``

**Output:** Backup status messages to stdout

---

### ``

!!! info "Notes"
    Similar to RPM behavior - saves modified files with .save extension

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `usage`

---

### ``

Display installer usage information and examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Usage help to stdout

---

### ``

!!! info "Notes"
    Shows installation modes, location options, examples

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_required_tools`

---

### ``

Verify required system tools are available

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all required tools present, 1 otherwise

---

### ``

**Output:** Tool check results to stdout

---

### ``

!!! info "Notes"
    Checks: bash, tar, awk, sed, grep, sha256sum/shasum

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_optional_tools`

---

### ``

Check for optional tools and warn if missing

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always successful, warnings only)

---

### ``

**Output:** Optional tool status and installation hints to stdout

---

### ``

!!! info "Notes"
    Checks: rlwrap, less, crontab

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_disk_space`

---

### ``

Verify sufficient disk space for installation

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 if sufficient space, 1 otherwise

---

### ``

**Output:** Disk space check results to stdout

---

### ``

!!! info "Notes"
    Requires 100MB free space

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_permissions`

---

### ``

Verify write permissions for installation directory

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 if writable, 1 otherwise

---

### ``

**Output:** Permission check results to stdout

---

### ``

!!! info "Notes"
    Checks target directory or creates test file in parent

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `detect_profile_file`

---

### ``

Detect appropriate shell profile file for current user

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0

---

### ``

**Output:** Profile file path to stdout

---

### ``

!!! info "Notes"
    Priority: ~/.bash_profile > ~/.profile > ~/.zshrc > create ~/.bash_profile

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `profile_has_oradba`

---

### ``

Check if profile already has OraDBA integration

---

### ``

**Arguments:**

- $1 - Profile file path

---

### ``

**Returns:** 0 if integrated, 1 otherwise

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Checks for OraDBA marker comment or oraenv.sh source

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `update_profile`

---

### ``

Add OraDBA auto-loading to shell profile

---

### ``

**Arguments:**

- $1 - Installation prefix directory

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Profile update status and manual instructions to stdout

---

### ``

!!! info "Notes"
    Interactive prompt if TTY available (unless --silent or --update-profile)

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `run_preflight_checks`

---

### ``

Execute all pre-installation validation checks

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 if all checks pass, 1 on failure

---

### ``

**Output:** Check results and status to stdout

---

### ``

!!! info "Notes"
    Runs: required tools, optional tools, disk space, permissions

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `version_compare`

---

### ``

Compare two semantic version strings

---

### ``

**Arguments:**

- $1 - First version (e.g., "1.2.3")

---

### ``

**Returns:** 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Handles versions with or without 'v' prefix

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `get_installed_version`

---

### ``

Get currently installed OraDBA version

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0

---

### ``

**Output:** Version string to stdout (or "unknown" if not found)

---

### ``

!!! info "Notes"
    Reads version from VERSION file in install directory

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `check_existing_installation`

---

### ``

Check if OraDBA is already installed at target location

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 if installed, 1 otherwise

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Verifies directory exists and contains VERSION file and bin/ directory

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `backup_installation`

---

### ``

Create timestamped backup of existing installation

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Backup directory path to stdout, status to stderr

---

### ``

!!! info "Notes"
    Creates .backup.YYYYMMDD_HHMMSS directory

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `restore_from_backup`

---

### ``

Restore installation from backup directory

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Restore status to stdout

---

### ``

!!! info "Notes"
    Removes failed installation first

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `preserve_configs`

---

### ``

Save user configuration files before update

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0

---

### ``

**Output:** Preserved file list to stdout

---

### ``

!!! info "Notes"
    Preserves: .install_info, etc/oradba.conf, oratab.example

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `restore_configs`

---

### ``

Restore preserved configuration files after update

---

### ``

**Arguments:**

- $1 - Installation directory path

---

### ``

**Returns:** 0

---

### ``

**Output:** Restored file list to stdout

---

### ``

!!! info "Notes"
    Restores files preserved by preserve_configs function

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `perform_update`

---

### ``

Execute update of existing OraDBA installation

---

### ``

**Arguments:**

- None (uses global variables)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Update progress and status to stdout

---

### ``

!!! info "Notes"
    Orchestrates: backup, preserve configs, extract new version, restore configs

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `extract_embedded_payload`

---

### ``

Extract OraDBA from embedded base64 payload

---

### ``

**Arguments:**

- None (reads from $0 - the installer script itself)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Extraction status to stdout

---

### ``

!!! info "Notes"
    Looks for __PAYLOAD_BEGINS__ marker in script

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `prompt_oracle_base`

---

### ``

Interactively prompt for Oracle Base directory if not specified

---

### ``

**Arguments:**

- None (sets global ORACLE_BASE_PARAM)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Prompt and validation messages to stdout

---

### ``

!!! info "Notes"
    Skipped if ORACLE_BASE_PARAM set, silent mode, or ORACLE_BASE detected

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `validate_write_permissions`

---

### ``

Validate write permissions for installation target

---

### ``

**Arguments:**

- $1 - Target installation path

---

### ``

**Returns:** 0 if writable, 1 otherwise

---

### ``

**Output:** Permission errors and suggestions to stderr

---

### ``

!!! info "Notes"
    Checks target if exists, otherwise checks parent directory

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `create_temp_oratab`

---

### ``

Create temporary oratab for pre-Oracle installations

---

### ``

**Arguments:**

- $1 - Installation prefix directory

---

### ``

**Returns:** 0

---

### ``

**Output:** Oratab creation status and symlink instructions to stdout

---

### ``

!!! info "Notes"
    Creates etc/oratab in OraDBA directory if /etc/oratab missing

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `extract_local_tarball`

---

### ``

Extract OraDBA from local tarball file

---

### ``

**Arguments:**

- $1 - Path to local tarball file

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Extraction status to stdout

---

### ``

!!! info "Notes"
    Validates file exists and is readable

---

### ``

**Source:** `oradba_install.sh`

---

### ``

---

### `extract_github_release`

---

### ``

Download and extract OraDBA from GitHub releases

---

### ``

**Arguments:**

- $1 - Version string (optional, uses latest if empty)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Download and extraction status to stdout

---

### ``

!!! info "Notes"
    Queries GitHub API for latest version if not specified

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `usage`

---

### ``

Display comprehensive help for logrotate configuration management

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (prints to stdout)

---

### ``

**Output:** Multi-section help (scenarios, options, examples, notes for root/user modes)

---

### ``

!!! info "Notes"
    Explains both system-wide (root) and user-mode (non-root) operation scenarios

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `print_message`

---

### ``

Print colored message to stdout

---

### ``

**Arguments:**

- $1 - Color code (RED/GREEN/YELLOW), $2 - Message text

---

### ``

**Returns:** None

---

### ``

**Output:** Colored message followed by NC (no color) reset

---

### ``

!!! info "Notes"
    Uses echo -e for ANSI color codes

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `check_root`

---

### ``

Verify script is running as root (EUID 0)

---

### ``

**Arguments:**

- $1 - Operation name for error message (e.g., "--install")

---

### ``

**Returns:** 0 if root, 1 if not root

---

### ``

**Output:** Error message with sudo suggestion if not root

---

### ``

!!! info "Notes"
    Checks EUID; required for system-wide operations (/etc/logrotate.d)

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `install_logrotate`

---

### ``

Install logrotate configurations to system directory (requires root)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if not root or directories missing

---

### ``

**Output:** Installation progress, backup notices, summary, next steps

---

### ``

!!! info "Notes"
    Installs from ${TEMPLATE_DIR} to /etc/logrotate.d; backs up existing configs; sets 644 permissions

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `uninstall_logrotate`

---

### ``

Remove OraDBA logrotate configurations from system directory (requires root)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if not root

---

### ``

**Output:** Removal progress for each config, final count

---

### ``

!!! info "Notes"
    Removes oradba* and oracle-* files from /etc/logrotate.d

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `list_logrotate`

---

### ``

List all installed OraDBA logrotate configurations

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** File details (ls -lh) for each config, count, installation suggestion if none found

---

### ``

!!! info "Notes"
    Searches for oradba* and oracle-* in /etc/logrotate.d

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `test_logrotate`

---

### ``

Test logrotate configurations in dry-run mode (no actual rotation)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if configs found, 1 if none found

---

### ``

**Output:** Dry-run results for each config (logrotate -d, last 30 lines)

---

### ``

!!! info "Notes"
    Uses logrotate -d for debug/dry-run; safe to run without root

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `force_logrotate`

---

### ``

Force immediate log rotation for testing (requires root)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if not root or user aborts

---

### ``

**Output:** Warning, confirmation prompt, rotation progress for each config

---

### ``

!!! info "Notes"
    Uses logrotate -f -v; actually rotates logs; requires yes confirmation

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `customize_logrotate`

---

### ``

Generate customized logrotate configurations in ~/.oradba/logrotate/

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Environment detection, database list from oratab, generated configs, next steps

---

### ``

!!! info "Notes"
    Creates oracle-alert-custom.logrotate and oracle-trace-custom.logrotate with paths customized to ORACLE_BASE

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `install_user`

---

### ``

Set up user-mode logrotate configurations (non-root operation)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if logrotate command not found

---

### ``

**Output:** Setup progress, generated configs (alert, trace, listener), next steps for testing and automation

---

### ``

!!! info "Notes"
    Creates ~/.oradba/logrotate/ with user-specific configs and state directory; requires manual execution or crontab

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `run_user`

---

### ``

Run logrotate manually with user-specific configurations (non-root)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if not initialized or logrotate missing

---

### ``

**Output:** Processing status for each config, state file location

---

### ``

!!! info "Notes"
    Uses ~/.oradba/logrotate/state/logrotate.status for tracking; requires --install-user first

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `generate_cron`

---

### ``

Generate crontab entry for automated user-mode log rotation

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds)

---

### ``

**Output:** Crontab entry with full script path, daily 2 AM schedule, instructions

---

### ``

!!! info "Notes"
    Shows entry for manual addition to crontab; auto-detects script path; output redirected to null

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `show_version`

---

### ``

Display script version information

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Script name, version string, and OraDBA project description

---

### ``

!!! info "Notes"
    Uses SCRIPT_NAME and SCRIPT_VERSION constants

---

### ``

**Source:** `oradba_logrotate.sh`

---

### ``

---

### `main`

---

### ``

Entry point and command-line argument dispatcher

---

### ``

**Arguments:**

- $@ - Command-line arguments (see usage for options)

---

### ``

**Returns:** Exit code from selected operation (0 success, 1 error)

---

### ``

**Output:** Depends on selected operation (install/test/run/list/customize/help)

---

### ``

!!! info "Notes"
    Dispatches to system-wide (root) or user-mode functions; shows usage if invalid option or no args

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `usage`

---

### ``

Display help for Oracle listener control

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1

---

### ``

**Output:** Multi-section help (actions, options, arguments, examples, env vars)

---

### ``

!!! info "Notes"
    Shows start/stop/restart/status actions; supports multiple listeners

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `get_first_oracle_home`

---

### ``

Get first valid Oracle Home from oratab

---

### ``

**Arguments:**

- None (reads from ${ORATAB} or /etc/oratab)

---

### ``

**Returns:** 0 on success, 1 if oratab not found or no valid home

---

### ``

**Output:** Oracle Home path to stdout

---

### ``

!!! info "Notes"
    Skips entries marked :D (dummy); returns first active database home

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `set_listener_env`

---

### ``

Set Oracle environment for listener operations (ORACLE_HOME, PATH, TNS_ADMIN)

---

### ``

**Arguments:**

- $1 - Listener name (currently unused, reserved for future)

---

### ``

**Returns:** 0 on success, 1 if cannot determine Oracle Home

---

### ``

**Output:** None (sets environment variables)

---

### ``

!!! info "Notes"
    Gets Oracle Home from get_first_oracle_home; exports ORACLE_HOME, PATH, TNS_ADMIN

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `get_running_listeners`

---

### ``

Get list of all currently running listeners

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** List of listener names (one per line, sorted, unique)

---

### ``

!!! info "Notes"
    Uses lsnrctl services to detect running listeners; parses output for names

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `ask_justification`

---

### ``

Prompt for justification when operating on all listeners (safety check)

---

### ``

**Arguments:**

- $1 - Action name (start/stop/restart), $2 - Count of affected listeners

---

### ``

**Returns:** 0 if user confirms, 1 if cancelled or no justification

---

### ``

**Output:** Warning banner, prompts for justification and confirmation

---

### ``

!!! info "Notes"
    Skipped if FORCE_MODE=true; requires "yes" confirmation to proceed

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `start_listener`

---

### ``

Start specified Oracle listener

---

### ``

**Arguments:**

- $1 - Listener name

---

### ``

**Returns:** 0 on success, 1 if failed to set env or start

---

### ``

**Output:** Log messages; lsnrctl output redirected to LOGFILE

---

### ``

!!! info "Notes"
    Checks if already running first; uses lsnrctl start

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `stop_listener`

---

### ``

Stop specified Oracle listener

---

### ``

**Arguments:**

- $1 - Listener name

---

### ``

**Returns:** 0 on success, 1 if failed to set env or stop

---

### ``

**Output:** Log messages; lsnrctl output redirected to LOGFILE

---

### ``

!!! info "Notes"
    Checks if running first; uses lsnrctl stop

---

### ``

**Source:** `oradba_lsnrctl.sh`

---

### ``

---

### `show_status`

---

### ``

Display status of specified listener

---

### ``

**Arguments:**

- $1 - Listener name

---

### ``

**Returns:** 0 on success, 1 if failed to set environment

---

### ``

**Output:** Status output from lsnrctl status

---

### ``

!!! info "Notes"
    Uses lsnrctl status to display listener information

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `usage`

---

### ``

Display comprehensive usage information for RMAN wrapper script

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Usage help, options, examples to stdout

---

### ``

!!! info "Notes"
    Shows required/optional arguments, configuration, template tags

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `check_parallel_method`

---

### ``

Determine and validate parallel execution method

---

### ``

**Arguments:**

- None (uses global OPT_PARALLEL)

---

### ``

**Returns:** 0

---

### ``

**Output:** Method selection to log

---

### ``

!!! info "Notes"
    Sets PARALLEL_METHOD to "gnu_parallel" or "background"

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `load_rman_config`

---

### ``

Load SID-specific RMAN configuration file

---

### ``

**Arguments:**

- $1 - Oracle SID

---

### ``

**Returns:** 0 if loaded, 1 if not found

---

### ``

**Output:** Config loading status to log

---

### ``

!!! info "Notes"
    Location: \${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `process_template`

---

### ``

Process RMAN script template with tag substitution

---

### ``

**Arguments:**

- $1 - Input template file path

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Processed script to output file, status to log

---

### ``

!!! info "Notes"
    Replaces template tags: <ALLOCATE_CHANNELS>, <FORMAT>, <TAG>, etc.

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `execute_rman_for_sid`

---

### ``

Execute RMAN script for a specific Oracle SID

---

### ``

**Arguments:**

- $1 - Oracle SID

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** RMAN execution results to log and stdout

---

### ``

!!! info "Notes"
    Orchestrates: set environment, load config, process template, run RMAN

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `execute_parallel_background`

---

### ``

Execute RMAN for multiple SIDs using background jobs

---

### ``

**Arguments:**

- $@ - List of Oracle SIDs

---

### ``

**Returns:** 0 if all successful, 1 if any failed

---

### ``

**Output:** Parallel execution status to log

---

### ``

!!! info "Notes"
    Standard bash background jobs with wait

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `execute_parallel_gnu`

---

### ``

Execute RMAN for multiple SIDs using GNU parallel

---

### ``

**Arguments:**

- $@ - List of Oracle SIDs

---

### ``

**Returns:** 0 if all successful, 1 if any failed

---

### ``

**Output:** Parallel execution status to log

---

### ``

!!! info "Notes"
    Requires GNU parallel command installed

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `send_notification`

---

### ``

Send email notification on success or failure

---

### ``

**Arguments:**

- $1 - Status ("SUCCESS" or "FAILURE")

---

### ``

**Returns:** 0 on success, 1 if mail command unavailable

---

### ``

**Output:** Email sent to configured address

---

### ``

!!! info "Notes"
    Respects RMAN_NOTIFY_ON_SUCCESS and RMAN_NOTIFY_ON_ERROR flags

---

### ``

**Source:** `oradba_rman.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for RMAN wrapper script

---

### ``

**Arguments:**

- $@ - Command-line arguments

---

### ``

**Returns:** 0 if all operations successful, 1-3 for errors

---

### ``

**Output:** Execution status and results to stdout/log

---

### ``

!!! info "Notes"
    Parses arguments, validates requirements, orchestrates execution

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `usage`

---

### ``

Display help for Oracle services orchestration

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1

---

### ``

**Output:** Multi-section help (actions, options, config, examples, env vars)

---

### ``

!!! info "Notes"
    Shows start/stop/restart/status actions; explains config file usage

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `load_config`

---

### ``

Load oradba_services.conf or create from template

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Log messages for config loading/creation

---

### ``

!!! info "Notes"
    Sources config file; creates from template if missing; uses defaults if unavailable

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `start_listeners`

---

### ``

Start Oracle listeners using oradba_lsnrctl.sh

---

### ``

**Arguments:**

- None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Log messages with command execution and results

---

### ``

!!! info "Notes"
    Constructs oradba_lsnrctl.sh command with options; respects force mode

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `stop_listeners`

---

### ``

Stop Oracle listeners using oradba_lsnrctl.sh

---

### ``

**Arguments:**

- None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Log messages with command execution and results

---

### ``

!!! info "Notes"
    Constructs oradba_lsnrctl.sh stop command with options

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `start_databases`

---

### ``

Start Oracle databases using oradba_dbctl.sh

---

### ``

**Arguments:**

- None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Log messages with command execution and results

---

### ``

!!! info "Notes"
    Constructs oradba_dbctl.sh start command with options

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `stop_databases`

---

### ``

Stop Oracle databases using oradba_dbctl.sh

---

### ``

**Arguments:**

- None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Log messages with command execution and results

---

### ``

!!! info "Notes"
    Constructs oradba_dbctl.sh stop command with options

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `show_status`

---

### ``

Show status of all Oracle services (databases and listeners)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Combined status output from oradba_dbctl.sh and oradba_lsnrctl.sh

---

### ``

!!! info "Notes"
    Calls oradba_dbctl.sh status and oradba_lsnrctl.sh status

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `start_all`

---

### ``

Start all Oracle services in configured order

---

### ``

**Arguments:**

- None (uses STARTUP_ORDER from config)

---

### ``

**Returns:** 0 if all succeeded, 1 if any failures

---

### ``

**Output:** Log messages for each service startup, final summary

---

### ``

!!! info "Notes"
    Processes STARTUP_ORDER (default: listener,database); tracks success/failure counts

---

### ``

**Source:** `oradba_services.sh`

---

### ``

---

### `stop_all`

---

### ``

Stop all Oracle services in configured order

---

### ``

**Arguments:**

- None (uses SHUTDOWN_ORDER from config)

---

### ``

**Returns:** 0 if all succeeded, 1 if any failures

---

### ``

**Output:** Log messages for each service shutdown, final summary

---

### ``

!!! info "Notes"
    Processes SHUTDOWN_ORDER (default: database,listener); tracks success/failure counts

---

### ``

**Source:** `oradba_services_root.sh`

---

### ``

---

### `check_root`

---

### ``

Verify script is running with root privileges

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 1 if not root

---

### ``

**Output:** Error message via log_message if not root

---

### ``

!!! info "Notes"
    Required for systemd/init.d service management

---

### ``

**Source:** `oradba_services_root.sh`

---

### ``

---

### `check_oracle_user`

---

### ``

Verify Oracle OS user exists on system

---

### ``

**Arguments:**

- None (uses global ORACLE_USER)

---

### ``

**Returns:** Exits with code 1 if user doesn't exist

---

### ``

**Output:** Error message via log_message if user missing

---

### ``

!!! info "Notes"
    Checks user defined by ${ORACLE_USER} environment variable

---

### ``

**Source:** `oradba_services_root.sh`

---

### ``

---

### `check_services_script`

---

### ``

Validate oradba_services.sh exists and is executable

---

### ``

**Arguments:**

- None (uses global SERVICES_SCRIPT)

---

### ``

**Returns:** Exits with code 1 if script missing or not executable

---

### ``

**Output:** Error messages via log_message

---

### ``

!!! info "Notes"
    Checks ${ORADBA_BASE}/bin/oradba_services.sh

---

### ``

**Source:** `oradba_services_root.sh`

---

### ``

---

### `run_as_oracle`

---

### ``

Execute oradba_services.sh as Oracle user with sudo/su

---

### ``

**Arguments:**

- $1 - Action (start|stop|restart|status)

---

### ``

**Returns:** Exit code from services script

---

### ``

**Output:** Status messages via log_message; service script output

---

### ``

!!! info "Notes"
    Uses 'su - ${ORACLE_USER}' to execute; passes --force flag

---

### ``

**Source:** `oradba_services_root.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information and examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Usage text, actions, environment variables, examples

---

### ``

!!! info "Notes"
    Shows wrapper purpose and available service actions

---

### ``

**Source:** `oradba_setup.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information, commands, examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stdout)

---

### ``

**Output:** Usage text, commands, options, examples, description

---

### ``

!!! info "Notes"
    Shows post-installation tasks: link-oratab, check, show-config

---

### ``

**Source:** `oradba_setup.sh`

---

### ``

---

### `cmd_link_oratab`

---

### ``

Replace temp oratab with symlink to system /etc/oratab

---

### ``

**Arguments:**

- $1 - Force mode (true|false, default: false)

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** Status messages via oradba_log

---

### ``

!!! info "Notes"
    Creates symlink ${ORADBA_BASE}/etc/oratab → /etc/oratab; requires system oratab exists

---

### ``

**Source:** `oradba_setup.sh`

---

### ``

---

### `cmd_check`

---

### ``

Validate OraDBA installation health and requirements

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all checks pass, 1 if any check fails

---

### ``

**Output:** Check results (✓/✗) with status messages via oradba_log

---

### ``

!!! info "Notes"
    Checks OraDBA installation, oratab, Oracle Homes, directories, configuration files

---

### ``

**Source:** `oradba_setup.sh`

---

### ``

---

### `cmd_show_config`

---

### ``

Display current OraDBA configuration and environment

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (always succeeds)

---

### ``

**Output:** Formatted configuration details (paths, variables, hosts, databases) to stdout

---

### ``

!!! info "Notes"
    Shows OraDBA_BASE, PREFIX, config hierarchy, Oracle Homes, SIDs, key environment vars

---

### ``

**Source:** `oradba_setup.sh`

---

### ``

---

### `main`

---

### ``

Parse command and dispatch to appropriate subcommand

---

### ``

**Arguments:**

- Command line arguments (command + options)

---

### ``

**Returns:** Exit code from subcommand (0 success, 1 failure)

---

### ``

**Output:** Depends on selected command

---

### ``

!!! info "Notes"
    Commands: link-oratab, check, show-config, help; parses --force, --verbose, --help options

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `usage`

---

### ``

Display comprehensive help for SQL*Net configuration management

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (prints to stdout)

---

### ``

**Output:** Multi-section usage text (commands, options, templates, examples)

---

### ``

!!! info "Notes"
    Shows installation, setup, generation, testing, validation operations

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `get_tns_admin`

---

### ``

Determine TNS_ADMIN directory path

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** TNS_ADMIN directory path (TNS_ADMIN var, ORACLE_HOME/network/admin, or ~/.oracle/network/admin)

---

### ``

!!! info "Notes"
    Precedence: TNS_ADMIN env var, then ORACLE_HOME, finally HOME fallback

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `backup_file`

---

### ``

Create timestamped backup copy of file

---

### ``

**Arguments:**

- $1 - File path to backup

---

### ``

**Returns:** 0 if file backed up, 1 if file doesn't exist

---

### ``

**Output:** Success message with backup filename

---

### ``

!!! info "Notes"
    Backup format: <filename>.YYYYMMDD_HHMMSS.bak, preserves original file

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `is_readonly_home`

---

### ``

Detect Oracle read-only home configuration (18c+ feature)

---

### ``

**Arguments:**

- $1 - Oracle Home path (defaults to ORACLE_HOME env var)

---

### ``

**Returns:** 0 if read-only home detected, 1 if read-write or unsupported version

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Uses orabasehome utility; output != ORACLE_HOME indicates read-only mode

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `get_central_tns_admin`

---

### ``

Create directory structure for centralized TNS_ADMIN (admin/log/trace)

---

### ``

**Arguments:**

- $1 - ORACLE_SID (defaults to ORACLE_SID env var)

---

### ``

**Returns:** 0 on success, 1 if admin directory creation fails

---

### ``

**Output:** Success messages for created directories, final admin path to stdout

---

### ``

!!! info "Notes"
    Creates ${ORACLE_BASE}/network/${SID}/{admin,log,trace} with 755 permissions

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `create_tns_structure`

---

### ``

Create directory structure for centralized TNS_ADMIN (admin/log/trace)

---

### ``

**Arguments:**

- $1 - ORACLE_SID (defaults to ORACLE_SID env var)

---

### ``

**Returns:** 0 on success, 1 if admin directory creation fails

---

### ``

**Output:** Success messages for created directories, final admin path to stdout

---

### ``

!!! info "Notes"
    Creates ${ORACLE_BASE}/network/${SID}/{admin,log,trace} with 755 permissions

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `migrate_config_files`

---

### ``

Move SQL*Net config files from source to centralized target directory

---

### ``

**Arguments:**

- $1 - Source directory path, $2 - Target directory path

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Success/warning messages for each file operation, final count

---

### ``

!!! info "Notes"
    Handles sqlnet.ora, tnsnames.ora, ldap.ora, listener.ora; backs up before moving

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `create_symlinks`

---

### ``

Create symlinks in ORACLE_HOME/network/admin pointing to centralized config files

---

### ``

**Arguments:**

- $1 - Oracle Home path, $2 - Centralized admin directory path

---

### ``

**Returns:** 0 on success, 1 if ORACLE_HOME invalid

---

### ``

**Output:** Success messages for each symlink created, final count

---

### ``

!!! info "Notes"
    Handles read-only homes gracefully; skips if admin dir creation fails

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `update_sqlnet_paths`

---

### ``

Update sqlnet.ora with centralized log and trace directory paths

---

### ``

**Arguments:**

- $1 - sqlnet.ora file path, $2 - Base directory for logs/traces

---

### ``

**Returns:** 0 (always succeeds if file exists)

---

### ``

**Output:** Update confirmation message

---

### ``

!!! info "Notes"
    Removes existing LOG/TRACE_DIRECTORY lines, appends new paths for client/server

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `setup_tns_admin`

---

### ``

Complete setup of centralized TNS_ADMIN structure for one database

---

### ``

**Arguments:**

- $1 - ORACLE_SID (defaults to env var), $2 - ORACLE_HOME (defaults to env var)

---

### ``

**Returns:** 0 on success, 1 if SID/ORACLE_BASE missing or creation fails

---

### ``

**Output:** Progress messages, TNS_ADMIN path, profile export suggestion

---

### ``

!!! info "Notes"
    Orchestrates: structure creation, file migration, path updates, symlinks; exports TNS_ADMIN

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `setup_all_tns_admin`

---

### ``

Setup centralized TNS_ADMIN for all databases listed in oratab

---

### ``

**Arguments:**

- None (reads from ${ORATAB} or /etc/oratab)

---

### ``

**Returns:** 0 if all succeeded, 1 if any errors or oratab missing

---

### ``

**Output:** Progress for each database, final summary with success/error counts

---

### ``

!!! info "Notes"
    Skips ASM (+*) and agent entries; processes regular database SIDs only

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `install_sqlnet`

---

### ``

Install sqlnet.ora from template with variable substitution

---

### ``

**Arguments:**

- $1 - Template type (basic|secure, defaults to basic)

---

### ``

**Returns:** 0 on success, 1 if template not found

---

### ``

**Output:** Installation success message with target path, or error with available templates

---

### ``

!!! info "Notes"
    Uses envsubst if available, otherwise sed; backs up existing file; sets 644 permissions

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `generate_tnsnames`

---

### ``

Generate and append TNS alias entry to tnsnames.ora

---

### ``

**Arguments:**

- $1 - ORACLE_SID for alias

---

### ``

**Returns:** 0 on success, 1 if SID missing or entry already exists

---

### ``

**Output:** Success message or duplicate warning

---

### ``

!!! info "Notes"
    Auto-detects hostname (FQDN preferred) and uses port 1521; warns if alias exists

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `test_tnsalias`

---

### ``

Test TNS alias connectivity using tnsping and display entry details

---

### ``

**Arguments:**

- $1 - TNS alias name

---

### ``

**Returns:** 0 on success (always returns 0, shows results only)

---

### ``

**Output:** Tnsping results (if available) and TNS entry from tnsnames.ora

---

### ``

!!! info "Notes"
    Uses tnsping for connectivity test (3 attempts), then displays full alias definition

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `list_aliases`

---

### ``

List all TNS aliases defined in tnsnames.ora

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if tnsnames.ora not found

---

### ``

**Output:** Numbered list of all TNS aliases (sorted)

---

### ``

!!! info "Notes"
    Extracts alias names from lines matching pattern: ALIAS = ...

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `validate_config`

---

### ``

Validate SQL*Net configuration files and environment

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all checks pass, 1 if any errors found

---

### ``

**Output:** Validation results for each component (sqlnet.ora, tnsnames.ora, ORACLE_HOME)

---

### ``

!!! info "Notes"
    Checks file existence, readability, basic syntax; reports errors with count

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `backup_config`

---

### ``

Backup all SQL*Net configuration files with timestamps

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if no files found

---

### ``

**Output:** Backup confirmations for each file, final count

---

### ``

!!! info "Notes"
    Backs up sqlnet.ora, tnsnames.ora, ldap.ora using backup_file function

---

### ``

**Source:** `oradba_sqlnet.sh`

---

### ``

---

### `main`

---

### ``

Entry point and command-line argument dispatcher

---

### ``

**Arguments:**

- $@ - Command-line arguments (see usage for options)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Depends on selected operation (install/generate/test/list/validate/backup/setup)

---

### ``

!!! info "Notes"
    Dispatches to appropriate function based on first argument; shows usage if no args

---

### ``

**Source:** `oradba_validate.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information for validation script

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 (exits after display)

---

### ``

**Output:** Usage help to stdout

---

### ``

!!! info "Notes"
    Shows options and examples for running validation

---

### ``

**Source:** `oradba_validate.sh`

---

### ``

---

### `test_item`

---

### ``

Execute a single validation test and track results

---

### ``

**Arguments:**

- $1 - Test name (description)

---

### ``

**Returns:** 0 if test passes, 1 if test fails

---

### ``

**Output:** Test result with checkmark/X/warning (if verbose or failed)

---

### ``

!!! info "Notes"
    Updates global counters TOTAL, PASSED, FAILED, WARNINGS

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `check_version`

---

### ``

Read and return OraDBA version from VERSION file

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if version found, 1 if VERSION file missing

---

### ``

**Output:** Version string (e.g., "1.2.3") or "Unknown"

---

### ``

!!! info "Notes"
    Reads ${BASE_DIR}/VERSION; fallback for missing file

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `get_checksum_exclusions`

---

### ``

Parse .checksumignore file and generate awk exclusion patterns

---

### ``

**Arguments:**

- $1 - extension_path (extension directory containing .checksumignore)

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Space-separated awk patterns for field 2 matching (e.g., "$2 ~ /^log\// || $2 ~ /^\.extension$/")

---

### ``

!!! info "Notes"
    Always excludes .extension, .checksumignore, log/; converts glob patterns (* to .*, ? to .)

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `check_integrity`

---

### ``

Verify OraDBA installation integrity using SHA256 checksums

---

### ``

**Arguments:**

- $1 - skip_extensions (optional, defaults to "false"; if "true", skip extension verification)

---

### ``

**Returns:** 0 if all files verified, 1 if any mismatches or missing files

---

### ``

**Output:** Success/failure status, file counts, detailed error list for failures

---

### ``

!!! info "Notes"
    Reads .oradba.checksum; excludes .install_info; calls check_additional_files and check_extension_checksums

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `check_additional_files`

---

### ``

Detect user-added files not in official checksum (customizations)

---

### ``

**Arguments:**

- None (uses ${BASE_DIR})

---

### ``

**Returns:** None (always succeeds, informational)

---

### ``

**Output:** Warning list of additional files in managed directories (bin, doc, etc, lib, rcv, sql, templates)

---

### ``

!!! info "Notes"
    Helps identify user customizations before updates; shows backup commands if SHOW_BACKUP=true

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `check_extension_checksums`

---

### ``

Verify integrity of all enabled extensions using their .extension.checksum files

---

### ``

**Arguments:**

- None (scans ${BASE_DIR}/extensions and ${ORADBA_LOCAL_BASE})

---

### ``

**Returns:** 0 if all extensions verified, 1 if any failures

---

### ``

**Output:** Success/failure status for each enabled extension, verbose details in VERBOSE mode

---

### ``

!!! info "Notes"
    Checks only enabled extensions; respects .checksumignore; verifies managed dirs (bin,sql,rcv,etc,lib)

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `show_installed_extensions`

---

### ``

Display list of all installed extensions with status indicators

---

### ``

**Arguments:**

- None (sources lib/extensions.sh)

---

### ``

**Returns:** 0 (always succeeds)

---

### ``

**Output:** Formatted extension list: name, version, enabled/disabled status, checksum status (✓/✗)

---

### ``

!!! info "Notes"
    Sorted by priority; shows checksum status for enabled extensions; uses extensions.sh library

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `check_updates`

---

### ``

Query GitHub API for latest OraDBA release and compare with installed version

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if up-to-date, 1 if check failed, 2 if update available

---

### ``

**Output:** Current vs latest version, download instructions if update available

---

### ``

!!! info "Notes"
    Uses curl with 10s timeout; queries api.github.com/repos/oehrlis/oradba/releases/latest

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `version_info`

---

### ``

Display comprehensive version information, installation details, and integrity check

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Return code from check_integrity (0 if verified, 1 if failed)

---

### ``

**Output:** Version, install path, installation metadata, installed extensions, integrity status

---

### ``

!!! info "Notes"
    Reads .install_info for details; calls show_installed_extensions and check_integrity

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `usage`

---

### ``

Display comprehensive help information for version utility

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (prints to stdout)

---

### ``

**Output:** Multi-section help (options, examples, exit codes)

---

### ``

!!! info "Notes"
    Shows all command-line options for version checking, verification, updates

---

### ``

**Source:** `oradba_version.sh`

---

### ``

---

### `main`

---

### ``

Entry point and command-line argument dispatcher

---

### ``

**Arguments:**

- $@ - Command-line arguments (see usage for options)

---

### ``

**Returns:** Depends on selected operation (0 success, 1 error, 2 update available)

---

### ``

**Output:** Depends on selected operation (check/verify/update-check/info/help)

---

### ``

!!! info "Notes"
    Defaults to version_info if no action specified; parses --verbose and --show-backup flags

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_parse_args`

---

### ``

Parse command line arguments for oraenv.sh

---

### ``

**Arguments:**

- $@ - All command line arguments

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Sets global variables: REQUESTED_SID, SHOW_ENV, SHOW_STATUS, 

---

### ``

!!! info "Notes"
    Detects TTY for interactive mode, processes --silent, --status,

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_usage`

---

### ``

Display usage information for oraenv.sh

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (outputs to stderr)

---

### ``

**Output:** Usage message with arguments, options, examples, and environment

---

### ``

!!! info "Notes"
    Output goes to stderr so it's visible when script is sourced

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_find_oratab`

---

### ``

Locate the oratab file using standard search paths

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success (oratab found), 1 on error (not found)

---

### ``

**Output:** Echoes path to oratab file if found

---

### ``

!!! info "Notes"
    Checks ORATAB_FILE variable first, then uses get_oratab_path(),

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_gather_available_entries`

---

### ``

Gather available database SIDs and Oracle Homes from registry

---

### ``

**Arguments:**

- $1 - Path to oratab file

---

### ``

**Returns:** 0 on success, 1 if no entries found

---

### ``

**Output:** Populates referenced arrays with available entries

---

### ``

!!! info "Notes"
    Uses registry API (Phase 1) first, falls back to auto-discovery

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_display_selection_menu`

---

### ``

Display interactive selection menu for SIDs and Oracle Homes

---

### ``

**Arguments:**

- $1 - Name reference to SIDs array

---

### ``

**Returns:** None (outputs to stderr)

---

### ``

**Output:** Formatted menu with numbered entries showing Oracle Homes (with type)

---

### ``

!!! info "Notes"
    Oracle Homes are listed first, then database SIDs. Each entry is

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_parse_user_selection`

---

### ``

Parse and validate user selection from interactive prompt

---

### ``

**Arguments:**

- $1 - User selection (number or name)

---

### ``

**Returns:** 0 on success, 1 if no selection made

---

### ``

**Output:** Echoes selected SID or Oracle Home name

---

### ``

!!! info "Notes"
    Accepts either numeric selection (1-N) or direct name entry.

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_prompt_sid`

---

### ``

Get SID from user (interactive) or first entry (non-interactive)

---

### ``

**Arguments:**

- $1 - Path to oratab file

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Selected SID or Oracle Home name

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_apply_path_configs`

---

### ``

Apply Java and client path configurations after environment setup

---

### ``

**Arguments:**

- $1 - Product type (DATABASE, DATASAFE, OUD, etc.)

---

### ``

**Returns:** None (modifies PATH, exports JAVA_HOME and ORACLE_CLIENT_HOME)

---

### ``

**Output:** Applies Java and client path settings based on user configuration

---

### ``

!!! info "Notes"
    Should be called AFTER config files are loaded to honor user settings.

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_handle_oracle_home`

---

### ``

Setup environment for an Oracle Home (non-database installation)

---

### ``

**Arguments:**

- $1 - Oracle Home name from oradba_homes.conf

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Exports ORACLE_HOME, ORACLE_BASE, ORACLE_SID (empty for non-DB),

---

### ``

!!! info "Notes"
    Uses set_oracle_home_environment() from Oracle Homes management.

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_lookup_oratab_entry`

---

### ``

Lookup database entry from registry or oratab file

---

### ``

**Arguments:**

- $1 - Requested SID name

---

### ``

**Returns:** None (outputs via echo)

---

### ``

**Output:** Echoes oratab entry in format "SID:HOME:FLAGS" if found, empty if not

---

### ``

!!! info "Notes"
    Uses registry API (Phase 1) first via oradba_registry_get_by_name(),

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_auto_discover_instances`

---

### ``

Auto-discover running Oracle instances when oratab is empty

---

### ``

**Arguments:**

- $1 - Requested SID name (optional, for targeted discovery)

---

### ``

**Returns:** None (outputs via echo)

---

### ``

**Output:** Echoes discovered oratab entry in format "SID:HOME:FLAGS"

---

### ``

!!! info "Notes"
    Only runs if ORADBA_AUTO_DISCOVER_INSTANCES=true and oratab is empty.

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_apply_product_adjustments`

---

### ``

Apply product-specific path adjustments (e.g., DataSafe plugin)

---

### ``

**Arguments:**

- $1 - Oracle Home path from oratab

---

### ``

**Returns:** None (outputs via echo)

---

### ``

**Output:** Echoes "adjusted_home|datasafe_install_dir" pipe-delimited values

---

### ``

!!! info "Notes"
    Detects DataSafe installations by oracle_cman_home subdirectory,

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_setup_environment_variables`

---

### ``

Setup Oracle environment variables for database instance

---

### ``

**Arguments:**

- $1 - Actual SID from oratab (preserves case)

---

### ``

**Returns:** None (exports environment variables)

---

### ``

**Output:** Exports ORACLE_SID, ORACLE_HOME, ORACLE_BASE, ORACLE_STARTUP,

---

### ``

!!! info "Notes"
    Uses oradba_set_lib_path() with plugin system for library paths.

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_load_configurations`

---

### ``

Load hierarchical configurations and extensions for environment

---

### ``

**Arguments:**

- $1 - SID or Oracle Home name identifier

---

### ``

**Returns:** None (modifies environment)

---

### ``

**Output:** Loads configuration hierarchy: core → standard → customer → default

---

### ``

!!! info "Notes"
    Calls load_config() for hierarchical config merging. Later configs

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_set_environment`

---

### ``

Set Oracle environment for a database SID or Oracle Home

---

### ``

**Arguments:**

- $1 - Requested SID or Oracle Home name

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_unset_old_env`

---

### ``

Unset previous Oracle environment variables before setting new ones

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (modifies environment)

---

### ``

**Output:** Removes old ORACLE_HOME paths from PATH and LD_LIBRARY_PATH

---

### ``

!!! info "Notes"
    Uses sed to remove both "$ORACLE_HOME/bin:" and ":$ORACLE_HOME/bin"

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_show_environment`

---

### ``

Main orchestration function for oraenv.sh

---

### ``

**Arguments:**

- $@ - All command line arguments

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Sets Oracle environment, optionally displays status and environment

---

### ``

!!! info "Notes"
    Workflow: 1) Parse arguments, 2) Find oratab, 3) Get/prompt for SID,

---

### ``

**Source:** `oraenv.sh`

---

### ``

---

### `_oraenv_main`

---

### ``

Main orchestration function for oraenv.sh

---

### ``

**Arguments:**

- $@ - All command line arguments

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Sets Oracle environment, optionally displays status and environment

---

### ``

!!! info "Notes"
    Workflow: 1) Parse arguments, 2) Find oratab, 3) Get/prompt for SID,

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `show_usage`

---

### ``

Display usage information

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `get_db_status`

---

### ``

Get database instance status by checking pmon process

---

### ``

---

### ``

**Returns:** "up" or "down"

---

### ``

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `get_db_mode`

---

### ``

Get database open mode (OPEN, MOUNTED, etc.)

---

### ``

---

### ``

**Returns:** Open mode or "n/a"

---

### ``

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `get_listener_status`

---

### ``

Get listener status (legacy, kept for backward compatibility)

---

### ``

---

### ``

**Returns:** "up" or "down"

---

### ``

---

### ``

!!! info "Notes"
    Consider using plugin_check_listener_status() for new code

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `should_show_listener_section`

---

### ``

Check if listener section should be displayed using plugin system

---

### ``

**Arguments:**

- $1 - Array of database homes

---

### ``

**Returns:** 0 if section should be shown, 1 otherwise

---

### ``

---

### ``

!!! info "Notes"
    Uses plugin_should_show_listener() from database plugin

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `show_oracle_status_registry`

---

### ``

Display Oracle status using registry API (Phase 1)

---

### ``

**Arguments:**

- Array of installation objects from registry

---

### ``

---

### ``

---

### ``

!!! info "Notes"
    Uses plugin system for product-specific behavior

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `show_oracle_status_registry`

---

### ``

Display Oracle status using registry API (Phase 1)

---

### ``

**Arguments:**

- Array of installation objects from registry

---

### ``

---

### ``

---

### ``

!!! info "Notes"
    Uses plugin system for product-specific behavior

---

### ``

**Source:** `oraup.sh`

---

### ``

---

### `main`

---

### ``

Main entry point for Oracle status display utility

---

### ``

**Arguments:**

- [OPTIONS] - Command-line flags (-h|--help, -v|--verbose, -q|--quiet)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Oracle status information to stdout (unless --quiet)

---

### ``

!!! info "Notes"
    Quick status display for current Oracle environment

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `load_config`

---

### ``

Load configuration from multiple sources (script config, alt config, CLI config)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (sets global vars)

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Sources ${SCRIPT_CONF}, ${ETC_BASE}/*.conf, ${CONFIG_FILE}; sets SSH_USER, SSH_PORT, PEER_HOSTS

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information, options, examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 0

---

### ``

**Output:** Usage text, configuration summary, examples to stdout

---

### ``

!!! info "Notes"
    Shows required -p option for source peer; demonstrates two-phase sync pattern

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `should_log`

---

### ``

Determine if a log message should be displayed based on level and mode

---

### ``

**Arguments:**

- $1 - Log level (DEBUG/INFO/WARN/ERROR)

---

### ``

**Returns:** 0 if should log, 1 if should suppress

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Suppresses non-ERROR if QUIET=true; suppresses DEBUG if DEBUG=false

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `parse_args`

---

### ``

Parse command line arguments and validate required parameters

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exits on validation failure

---

### ``

**Output:** Error messages to stderr

---

### ``

!!! info "Notes"
    Validates -p (source peer) and source path required; sets REMOTE_PEER, SOURCE, PEER_HOSTS

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `perform_sync`

---

### ``

Two-phase sync: pull from source peer to local, then push to all other peers

---

### ``

**Arguments:**

- None (uses global REMOTE_PEER, SOURCE, PEER_HOSTS, REMOTE_BASE, RSYNC_OPTS)

---

### ``

**Returns:** 0 if all syncs succeed, 1 if phase 1 or any phase 2 sync fails

---

### ``

**Output:** Status messages via oradba_log; rsync output if verbose

---

### ``

!!! info "Notes"
    Phase 1: pull from REMOTE_PEER; Phase 2: push to peers (excluding source and self)

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `show_summary`

---

### ``

Display two-phase synchronization results summary

---

### ``

**Arguments:**

- None (uses global REMOTE_PEER, SYNC_SUCCESS, SYNC_FAILURE, VERBOSE, QUIET)

---

### ``

**Returns:** None

---

### ``

**Output:** Source peer, local host, successful/failed syncs to stdout (if verbose)

---

### ``

!!! info "Notes"
    Shows phase 1 source and phase 2 distribution results; only in verbose mode

---

### ``

**Source:** `sync_from_peers.sh`

---

### ``

---

### `main`

---

### ``

Orchestrate sync-from-peers workflow

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exit code 0 if all syncs succeed, 1 if any fail

---

### ``

**Output:** Depends on verbose/quiet mode

---

### ``

!!! info "Notes"
    Workflow: load config → parse args → perform sync → show summary; exits 1 if failures exist

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `load_config`

---

### ``

Load configuration from multiple sources (script config, alt config, CLI config)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** None (sets global vars)

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Sources ${SCRIPT_CONF}, ${ETC_BASE}/*.conf, ${CONFIG_FILE}; sets SSH_USER, SSH_PORT, PEER_HOSTS

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `usage`

---

### ``

Display usage information, options, examples

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** Exits with code 0

---

### ``

**Output:** Usage text, configuration summary, examples to stdout

---

### ``

!!! info "Notes"
    Shows rsync options, peer hosts, SSH config; demonstrates common use cases

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `should_log`

---

### ``

Determine if a log message should be displayed based on level and mode

---

### ``

**Arguments:**

- $1 - Log level (DEBUG/INFO/WARN/ERROR)

---

### ``

**Returns:** 0 if should log, 1 if should suppress

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Suppresses non-ERROR if QUIET=true; suppresses DEBUG if DEBUG=false

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `parse_args`

---

### ``

Parse command line arguments and validate required parameters

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exits on validation failure

---

### ``

**Output:** Error messages to stderr

---

### ``

!!! info "Notes"
    Sets DRYRUN, VERBOSE, DEBUG, DELETE, QUIET, PEER_HOSTS, REMOTE_BASE, SOURCE; validates source exists

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `perform_sync`

---

### ``

Execute rsync to each peer host

---

### ``

**Arguments:**

- None (uses global SOURCE, PEER_HOSTS, REMOTE_BASE, RSYNC_OPTS)

---

### ``

**Returns:** 0 if all syncs succeed, 1 if any fails

---

### ``

**Output:** Status messages via oradba_log; rsync output if verbose

---

### ``

!!! info "Notes"
    Skips local host; converts to absolute paths; tracks success/failure arrays

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `show_summary`

---

### ``

Display synchronization results summary

---

### ``

**Arguments:**

- None (uses global SYNC_SUCCESS, SYNC_FAILURE, VERBOSE, QUIET)

---

### ``

**Returns:** None

---

### ``

**Output:** Success/failure counts and lists to stdout (if verbose mode)

---

### ``

!!! info "Notes"
    Shows local host, successful peers, failed peers; only in verbose mode

---

### ``

**Source:** `sync_to_peers.sh`

---

### ``

---

### `main`

---

### ``

Orchestrate sync-to-peers workflow

---

### ``

**Arguments:**

- Command line arguments (passed as "$@")

---

### ``

**Returns:** Exit code 0 if all syncs succeed, 1 if any fail

---

### ``

**Output:** Depends on verbose/quiet mode

---

### ``

!!! info "Notes"
    Workflow: load config → parse args → perform sync → show summary; exits 1 if failures exist

---

