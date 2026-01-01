# Project Structure

This document describes the oradba project directory structure.

## Root Directory

The root directory contains only essential files and subdirectories for a clean organization:

```text
oradba/
├── src/                    # Distribution files (installed on target systems)
├── scripts/                # Build, test, and utility scripts
├── tests/                  # BATS test suite
├── doc/                    # Developer documentation
├── .github/                # GitHub workflows and issue templates
├── VERSION                 # Semantic version number
├── Makefile                # Development workflow automation
├── README.md               # Main project documentation
├── CHANGELOG.md            # Version history and changes
├── CONTRIBUTING.md         # Contribution guidelines
├── LICENSE                 # Apache 2.0 license
├── oradba.code-workspace   # VS Code workspace configuration
├── .gitignore              # Git ignore patterns
├── .markdownlint.json      # Markdown linting configuration
└── .markdownlint.yaml      # Alternative markdown config
```

## Directory Details

### src/ - Distribution Files

Files that get installed on target systems:

```text
src/
├── bin/                    # Executable scripts (17 scripts)
│   ├── oraenv.sh          # Core environment setup script
│   ├── oradba_install.sh  # Installation script
│   ├── oradba_version.sh  # Version management
│   ├── oradba_check.sh    # Configuration validation
│   ├── oradba_sqlnet.sh   # SQL*Net configuration
│   ├── oradba_logrotate.sh # Log rotation management
│   ├── oradba_validate.sh # System validation
│   ├── dbstatus.sh        # Database status checker
│   ├── oraup.sh           # Database startup helper
│   ├── longops.sh         # Long operations monitor
│   ├── sessionsql.sh      # Session SQL management
│   ├── get_seps_pwd.sh    # SEPS password retrieval
│   ├── sync_to_peers.sh   # Peer synchronization (to)
│   ├── sync_from_peers.sh # Peer synchronization (from)
│   ├── exp_jobs.sh        # Export job wrapper
│   ├── imp_jobs.sh        # Import job wrapper
│   └── rman_jobs.sh       # RMAN job wrapper
├── lib/                    # Shared libraries (3 libraries)
│   ├── common.sh          # Common utility functions
│   ├── aliases.sh         # Alias generation library
│   └── db_functions.sh    # Database functions library
├── etc/                    # Configuration files (13 files)
│   ├── oradba_core.conf   # Core system configuration
│   ├── oradba_standard.conf # Standard configuration
│   ├── oradba_customer.conf.example # Customer config template
│   ├── oradba_config.example # User config example
│   ├── oratab.example     # Example oratab file
│   ├── sid._DEFAULT_.conf # Default SID configuration
│   ├── sid.ORACLE_SID.conf.example # SID-specific config template
│   ├── rlwrap_filter_oracle # rlwrap filter for Oracle CLI
│   ├── rlwrap_sqlplus_completions # SQL*Plus completions
│   ├── rlwrap_rman_completions # RMAN completions
│   ├── rlwrap_lsnrctl_completions # LSNRCTL completions
│   ├── rlwrap_adrci_completions # ADRCI completions
│   └── README.md          # Configuration documentation
├── sql/                    # SQL scripts (126 scripts)
│   ├── Multiple audit scripts (aud_*.sql)
│   ├── Security scripts (sec_*.sql)
│   ├── TDE scripts (tde_*.sql)
│   ├── Verification scripts (verify_*.sql)
│   └── Various utility scripts
├── rcv/                    # RMAN recovery scripts
│   ├── backup_full.rman   # Full backup script
│   └── README.md          # RMAN documentation
├── templates/              # Configuration templates
│   ├── script_template.sh # Bash script template
│   ├── logrotate/         # Log rotation templates
│   │   ├── oradba.logrotate
│   │   ├── oracle-alert.logrotate
│   │   ├── oracle-audit.logrotate
│   │   ├── oracle-listener.logrotate
│   │   ├── oracle-trace.logrotate
│   │   └── README.md
│   ├── sqlnet/            # SQL*Net templates
│   │   ├── sqlnet.ora.basic
│   │   ├── sqlnet.ora.secure
│   │   ├── tnsnames.ora.template
│   │   ├── ldap.ora.template
│   │   └── README.md
│   └── README.md          # Templates documentation
└── doc/                    # User documentation (17 chapters)
    ├── 01-introduction.md # Introduction
    ├── 02-installation.md # Installation guide
    ├── 03-quickstart.md   # Quick start guide
    ├── 04-environment.md  # Environment management
    ├── 05-configuration.md # Configuration system
    ├── 06-aliases.md      # Alias reference
    ├── 07-pdb-aliases.md  # PDB alias reference
    ├── 08-sql-scripts.md  # SQL scripts reference
    ├── 09-rman-scripts.md # RMAN script templates
    ├── 10-functions.md    # Database functions library
    ├── 11-rlwrap.md       # rlwrap configuration
    ├── 12-troubleshooting.md # Troubleshooting guide
    ├── 13-reference.md    # Quick reference
    ├── 14-sqlnet-config.md # SQL*Net configuration
    ├── 15-log-management.md # Log management
    ├── 16-usage.md        # Usage guide
    ├── alias_help.txt     # Alias help text
    └── README.md          # Documentation index
```

### scripts/ - Build and Utility Scripts

Development and build scripts (not installed):

```text
scripts/
├── build_installer.sh      # Build self-contained installer
├── validate_project.sh     # Validate project structure
└── README.md              # Scripts documentation
```

### tests/ - Test Suite

BATS test files:

```text
tests/
├── test_common.bats        # Common library tests
├── test_oraenv.bats        # Environment script tests
├── test_installer.bats     # Installer tests
├── test_aliases.bats       # Alias generation tests
├── test_db_functions.bats  # Database functions tests
├── test_oradba_version.bats # Version management tests
├── test_oradba_check.bats  # Configuration validation tests
├── test_oradba_sqlnet.bats # SQL*Net configuration tests
├── test_sid_config.bats    # SID configuration tests
├── test_get_seps_pwd.bats  # SEPS password tests
├── test_sync_scripts.bats  # Peer sync script tests
├── test_longops.bats       # Long operations tests
├── test_oraup.bats         # Database startup tests
├── test_job_wrappers.bats  # Job wrapper tests
├── test_aliases_manual.sh  # Manual alias testing
├── test_version.sh        # Version test script
├── run_tests.sh           # Test runner script
└── README.md              # Test documentation
```

### doc/ - Developer Documentation

Documentation for developers:

```text
doc/
├── README.md               # Documentation index
├── structure.md            # This document - project structure
├── development.md          # Developer guide
├── architecture.md         # System architecture
├── api.md                  # API documentation
├── markdown-linting.md     # Markdown linting guide
├── version-management.md   # Version management guide
├── ci_optimization.md      # CI/CD optimization guide
├── metadata.yml            # Documentation metadata for Pandoc
├── images/                 # Documentation images
│   ├── architecture-system.png
│   ├── config-hierarchy.png
│   ├── config-sequence.png
│   ├── dev-workflow.png
│   ├── installation-flow.png
│   ├── oraenv-flow.png
│   ├── alias-generation.png
│   ├── cicd-pipeline.png
│   ├── test-strategy.png
│   ├── README.md
│   └── source/            # Excalidraw source files
│       ├── architecture-system.excalidraw
│       ├── config-hierarchy.excalidraw
│       ├── config-sequence.excalidraw
│       ├── dev-workflow.excalidraw
│       ├── installation-flow.excalidraw
│       ├── oraenv-flow.excalidraw
│       ├── alias-generation.excalidraw
│       ├── cicd-pipeline.excalidraw
│       └── test-strategy.excalidraw
└── templates/              # File templates
    ├── header.sh          # Bash header template
    ├── header.sql         # SQL header template
    ├── header.rman        # RMAN header template
    ├── header.conf        # Config header template
    ├── pandoc-style.css   # Pandoc CSS stylesheet
    └── README.md          # Templates documentation
```

### .github/ - GitHub Configuration

GitHub Actions workflows and issue templates:

```text
.github/
├── workflows/              # CI/CD pipelines
│   ├── ci.yml             # Continuous integration
│   ├── release.yml        # Release automation
│   └── dependency-review.yml  # Security scanning
└── ISSUE_TEMPLATE/         # Issue templates
    ├── bug_report.yml     # Bug report template
    ├── feature_request.yml # Feature request template
    ├── task.yml           # Task template
    └── config.yml         # Template configuration
```

## File Organization Principles

1. **Clean Root**: Only essential files in root directory
2. **Logical Grouping**: Related files grouped in subdirectories
3. **Separation of Concerns**: Distribution vs. development files
4. **Clear Naming**: Descriptive directory and file names
5. **Documentation**: Each directory has README or documentation

## Path References

When referencing paths in scripts:

```bash
# Distribution files (installed)
$ORADBA_PREFIX/src/bin/oraenv.sh
$ORADBA_PREFIX/src/lib/common.sh
$ORADBA_PREFIX/src/lib/aliases.sh
$ORADBA_PREFIX/src/lib/db_functions.sh

# Build scripts (development)
./scripts/build_installer.sh
./scripts/validate_project.sh

# Tests (development)
./tests/run_tests.sh

# Documentation (development)
./doc/development.md
./doc/architecture.md
```

## Development Workflow

```bash
# 1. Make changes to source files in src/
vim src/bin/oraenv.sh

# 2. Run tests
make test
# or
./tests/run_tests.sh

# 3. Lint code
make lint

# 4. Format code (if needed)
make format

# 5. Validate structure
./scripts/validate_project.sh

# 6. Build installer
make build
# or
./scripts/build_installer.sh

# 7. Test installation
sudo ./dist/oradba_install.sh --prefix /tmp/oradba-test

# 8. Run full CI pipeline locally
make ci
```

## Adding New Files

### New Script

1. Create in appropriate src/bin/ directory
2. Use header template from doc/templates/header.sh
3. Add tests to tests/ (e.g., test_scriptname.bats)
4. Update documentation in src/doc/
5. Run `make lint` to validate

### New Library Function

1. Add to src/lib/common.sh or src/lib/db_functions.sh
2. Use header template from doc/templates/
3. Add tests to tests/test_common.bats or tests/test_db_functions.bats
4. Update documentation in src/doc/10-functions.md

### New SQL Script

1. Create in src/sql/
2. Use header template from doc/templates/header.sql
3. Follow naming conventions (e.g., aud_*.sql for audit scripts)
4. Update src/doc/08-sql-scripts.md

### New Test

1. Create in tests/ with .bats extension
2. Follow existing test patterns
3. Add to run_tests.sh if needed
4. Run `make test` to verify

### New Documentation

1. Developer docs in doc/
2. User docs in src/doc/ (use NN-name.md format for chapters)
3. Follow markdown linting rules (.markdownlint.yaml)
4. Update relevant README files
5. Run `make lint-markdown` to validate

## Build Artifacts

Generated during build (gitignored):

```text
build/                      # Temporary build files
dist/                       # Distribution installer
└── oradba_install.sh      # Self-contained installer
```

## See Also

- [README.md](../README.md) - Main documentation
- [development.md](development.md) - Developer guide
- [architecture.md](architecture.md) - System architecture
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [Makefile](../Makefile) - Development workflow automation
