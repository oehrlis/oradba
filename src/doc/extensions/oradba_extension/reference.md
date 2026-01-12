# Reference

Complete reference for OraDBA Extension Template scripts, tools, and components.

## Directory Structure

```text
oradba_extension/
├── .extension                 # Extension metadata
├── .checksumignore           # Integrity check exclusions
├── bin/                      # Executable scripts
│   └── extension_tool.sh     # Example extension tool
├── etc/                      # Configuration files
│   └── extension-template.conf.example
├── lib/                      # Library functions
│   └── common.sh            # Common functions
├── rcv/                     # RMAN recovery scripts
│   └── extension_backup.rcv
├── sql/                     # SQL scripts
│   ├── extension_comprehensive.sql
│   ├── extension_query.sql
│   └── extension_simple.sql
├── scripts/                 # Build and maintenance scripts
│   ├── build.sh            # Build package
│   └── rename-extension.sh # Rename helper
└── tests/                   # Test suite
    └── template_helpers.bats
```

## Scripts Reference

### bin/extension_tool.sh

Example executable script showing OraDBA integration patterns.

**Usage:**

```bash
extension_tool.sh [OPTIONS]
```

**Options:**

```text
-h, --help              Show help message
-v, --verbose           Enable verbose output
-d, --database SID      Specify database SID
-q, --quiet             Suppress non-error output
```

**Examples:**

```bash
# Basic usage
extension_tool.sh

# With specific database
extension_tool.sh -d ORCL

# Verbose mode
extension_tool.sh -v
```

**Exit Codes:**

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Oracle environment error

### scripts/build.sh

Build distribution package for the extension.

**Usage:**

```bash
./scripts/build.sh [VERSION]
```

**Arguments:**

- `VERSION` - Version number (default: from VERSION file)

**Process:**

1. Validates extension structure
2. Generates checksums for integrity verification
3. Creates tarball with version
4. Generates SHA256 checksum file
5. Creates installer script

**Output Files:**

```text
dist/
├── oradba_extension_1.0.0.tar.gz
├── oradba_extension_1.0.0.tar.gz.sha256
└── oradba_extension_1.0.0_installer.sh
```

**Examples:**

```bash
# Build with version from VERSION file
./scripts/build.sh

# Build specific version
./scripts/build.sh 1.2.3

# Check build output
ls -lh dist/
```

### scripts/rename-extension.sh

Rename extension to create new extension from template.

**Usage:**

```bash
./scripts/rename-extension.sh <new-name>
```

**Arguments:**

- `new-name` - New extension name (lowercase, alphanumeric, hyphens/underscores)

**Operations:**

1. Validates new name format
2. Updates `.extension` metadata
3. Renames files and directories
4. Updates references in scripts
5. Updates documentation
6. Updates test files

**Examples:**

```bash
# Rename to 'backup'
./scripts/rename-extension.sh backup

# Rename to 'my_monitor'
./scripts/rename-extension.sh my_monitor
```

**Files Modified:**

- `.extension` - Updates EXTENSION_NAME
- All files in `bin/`, `sql/`, `rcv/` - Renames containing 'extension'
- Configuration files in `etc/`
- Test files
- Documentation files

## SQL Scripts

### sql/extension_simple.sql

Simple SQL query template for basic database queries.

**Purpose:** Demonstrate simple query execution pattern.

**Usage:**

```sql
@extension_simple.sql
```

**Output:** Basic database information (database name, instance, version).

### sql/extension_query.sql

Parameterized SQL query template.

**Purpose:** Show parameterized query pattern with bind variables.

**Usage:**

```sql
@extension_query.sql PARAMETER_VALUE
```

**Parameters:**

- Parameter values passed as script arguments

**Output:** Query results based on parameters.

### sql/extension_comprehensive.sql

Complex SQL script with formatting and reporting.

**Purpose:** Comprehensive query template with formatted output.

**Features:**

- Column formatting
- Report headers/footers
- Multiple queries
- Summary statistics

**Usage:**

```sql
@extension_comprehensive.sql
```

**Output:** Formatted report with multiple sections.

## RMAN Scripts

### rcv/extension_backup.rcv

RMAN backup script template.

**Purpose:** Template for RMAN backup operations.

**Features:**

- Backup configuration
- Channel allocation
- Backup sets
- Archive log handling
- Deletion policies

**Usage:**

```bash
rman target / @extension_backup.rcv
```

**Configuration:**

Edit script to customize:

```sql
-- Configuration
CONFIGURE RETENTION POLICY TO REDUNDANCY 2;
CONFIGURE BACKUP OPTIMIZATION ON;

-- Backup commands
BACKUP DATABASE PLUS ARCHIVELOG;
DELETE NOPROMPT OBSOLETE;
```

**Logs:**

RMAN logs written to `$ORADBA_PREFIX/log/rman_backup_<timestamp>.log`

## Library Functions

### lib/common.sh

Common functions for extension scripts.

**Functions:**

#### log_message()

Log message with timestamp.

```bash
log_message "INFO" "Starting process"
```

**Parameters:**

- `$1` - Log level (INFO, WARN, ERROR)
- `$2` - Message text

#### validate_oracle_env()

Validate Oracle environment is properly set.

```bash
if ! validate_oracle_env; then
    echo "Oracle environment not set"
    exit 1
fi
```

**Checks:**

- `ORACLE_HOME` is set and valid
- `ORACLE_SID` is set
- Oracle binaries are accessible

**Returns:** 0 if valid, 1 if invalid

#### get_oracle_version()

Get Oracle database version.

```bash
version=$(get_oracle_version)
echo "Oracle version: ${version}"
```

**Output:** Version string (e.g., "19.0.0.0.0")

#### execute_sql()

Execute SQL statement and return results.

```bash
result=$(execute_sql "SELECT name FROM v\$database")
```

**Parameters:**

- `$1` - SQL statement

**Output:** Query results

**Returns:** 0 on success, 1 on error

## Extension Metadata

### .extension File

Core metadata file for the extension.

**Format:**

```ini
EXTENSION_NAME="extension"
EXTENSION_VERSION="1.0.0"
EXTENSION_PRIORITY="50"
EXTENSION_DESCRIPTION="OraDBA extension template"
```

**Fields:**

| Field                 | Description       | Format                  | Example            |
|-----------------------|-------------------|-------------------------|--------------------|
| EXTENSION_NAME        | Unique identifier | lowercase, alphanumeric | `backup`           |
| EXTENSION_VERSION     | Semantic version  | MAJOR.MINOR.PATCH       | `1.2.3`            |
| EXTENSION_PRIORITY    | Load order        | 1-99                    | `50`               |
| EXTENSION_DESCRIPTION | Brief description | text                    | `Backup utilities` |

### .checksumignore File

Files/patterns excluded from integrity verification.

**Syntax:**

```text
# Comment
pattern          # Exclude matching files
directory/       # Exclude entire directory
*.ext           # Wildcard pattern
!include.txt    # Include (negates previous exclusion)
```

**Common Patterns:**

```text
# Always exclude
.extension
.checksumignore

# Logs and temporary files
log/
*.log
*.tmp
*.swp

# User configurations
etc/*.conf
!etc/*.conf.example

# Credentials
*.key
*.pem
*.pwd
keystore/

# Version control
.git/
.gitignore
```

## Makefile Targets

### make build

Build distribution package.

```bash
make build
```

**Actions:**

- Runs validation
- Executes `scripts/build.sh`
- Creates distribution files

### make clean

Remove build artifacts.

```bash
make clean
```

**Removes:**

- `dist/` directory
- Temporary files
- Build logs

### make test

Run test suite.

```bash
make test
```

**Executes:**

- Bats test files in `tests/`
- Validates extension structure
- Checks file integrity

### make install

Install extension locally for testing.

```bash
make install PREFIX=/path/to/oradba
```

**Parameters:**

- `PREFIX` - OraDBA installation directory

**Actions:**

- Extracts to `${PREFIX}/local/<extension>`
- Sets permissions
- Validates installation

## Test Suite

### tests/template_helpers.bats

Test suite for template functionality.

**Run Tests:**

```bash
# All tests
bats tests/

# Specific file
bats tests/template_helpers.bats

# Verbose output
bats -t tests/template_helpers.bats
```

**Test Categories:**

- Metadata validation
- File structure checks
- Script execution tests
- Build process validation
- Integrity verification

**Example Tests:**

```bash
@test "Extension metadata file exists" {
    [ -f .extension ]
}

@test "Extension has valid name" {
    grep -q "EXTENSION_NAME=" .extension
}

@test "Build script exists and is executable" {
    [ -x scripts/build.sh ]
}
```

## Integration with OraDBA

### Loading Process

1. OraDBA discovers extension in `${ORADBA_LOCAL_BASE}/`
2. Reads `.extension` metadata
3. Validates extension structure
4. Verifies checksums (optional)
5. Sources shell scripts from `bin/`
6. Adds SQL scripts to search path
7. Registers RMAN scripts

### Environment Variables

Extensions have access to:

```bash
ORADBA_BASE           # OraDBA installation
ORADBA_PREFIX         # Configuration/logs
ORADBA_LOCAL_BASE     # Local extensions
ORACLE_BASE           # Oracle base
ORACLE_HOME           # Oracle home
ORACLE_SID            # Database SID
```

### Logging Integration

Use OraDBA logging functions:

```bash
log_info "Information message"
log_warn "Warning message"
log_error "Error message"
```

**Log Location:** `${ORADBA_PREFIX}/log/oradba.log`

### Alias Integration

Register aliases in shell scripts:

```bash
# Register alias
alias myext_backup='extension_tool.sh --backup'

# Check if alias exists
if alias myext_backup &>/dev/null; then
    echo "Alias registered"
fi
```

## API Reference

### Shell Function API

Functions available to extension scripts:

| Function | Description | Returns |
| -------- | ----------- | ------- |
| `log_info` | Log info message | 0 |
| `log_warn` | Log warning | 0 |
| `log_error` | Log error | 0 |
| `get_ora_env` | Get Oracle env var | string |
| `set_ora_env` | Set Oracle environment | 0/1 |
| `check_oracle_home` | Validate ORACLE_HOME | 0/1 |
| `execute_sql_script` | Run SQL script | 0/1 |
| `execute_rman_script` | Run RMAN script | 0/1 |

### Exit Codes

Standard exit codes for extension scripts:

| Code | Meaning |
| ---- | ------- |
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Oracle environment error |
| 4 | Database connection error |
| 5 | SQL execution error |
| 6 | RMAN execution error |
| 10+ | Extension-specific errors |

## Next Steps

- See [Installation](installation.md) for setup
- See [Configuration](configuration.md) for customization
- See [Development](development.md) for contributing
