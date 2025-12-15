# Project Structure

This document describes the oradba project directory structure.

## Root Directory

The root directory contains only essential files and subdirectories for a clean organization:

```text
oradba/
├── srv/                    # Distribution files (installed on target systems)
├── scripts/                # Build, test, and utility scripts
├── tests/                  # BATS test suite
├── doc/                    # Developer documentation
├── .github/                # GitHub workflows and issue templates
├── VERSION                 # Semantic version number
├── README.md               # Main project documentation
├── CHANGELOG.md            # Version history and changes
├── CONTRIBUTING.md         # Contribution guidelines
├── LICENSE                 # Apache 2.0 license
├── PROJECT_SUMMARY.md      # Project overview
├── .gitignore              # Git ignore patterns
├── .markdownlint.json      # Markdown linting configuration
└── .markdownlint.yaml      # Alternative markdown config
```

## Directory Details

### srv/ - Distribution Files

Files that get installed on target systems:

```text
srv/
├── bin/                    # Executable scripts
│   └── oraenv.sh          # Core environment setup script
├── lib/                    # Shared libraries
│   └── common.sh          # Common utility functions
├── etc/                    # Configuration files
│   ├── oradba.conf        # System configuration
│   ├── oratab.example     # Example oratab file
│   └── oradba_config.example  # User config example
├── sql/                    # SQL scripts
│   ├── db_info.sql        # Database information
│   └── login.sql          # SQL*Plus login script
├── rcv/                    # RMAN recovery scripts
│   └── backup_full.rman   # Full backup script
├── templates/              # Script templates
│   └── script_template.sh # Bash script template
└── doc/                    # User documentation
    ├── README.md          # Documentation index
    ├── USAGE.md           # User guide
    └── TROUBLESHOOTING.md # Problem solving
```

### scripts/ - Build and Utility Scripts

Development and build scripts (not installed):

```text
scripts/
├── build_installer.sh      # Build self-contained installer
├── validate_project.sh     # Validate project structure
└── init_git.sh            # Initialize git repository
```

### tests/ - Test Suite

BATS test files:

```text
tests/
├── test_common.bats        # Common library tests
├── test_oraenv.bats        # Environment script tests
├── test_installer.bats     # Installer tests
└── run_tests.sh           # Test runner script
```

### doc/ - Developer Documentation

Documentation for developers:

```text
doc/
├── README.md               # Documentation index
├── QUICKSTART.md           # Quick start guide
├── DEVELOPMENT.md          # Developer guide
├── ARCHITECTURE.md         # System architecture
├── API.md                  # API documentation
├── MARKDOWN_LINTING.md     # Markdown linting guide
└── templates/              # File templates
    ├── header.sh          # Bash header template
    ├── header.sql         # SQL header template
    ├── header.rman        # RMAN header template
    └── header.conf        # Config header template
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
    ├── bug_report.md      # Bug report template
    ├── feature_request.md # Feature request template
    ├── task.md            # Task template
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
$ORADBA_PREFIX/srv/bin/oraenv.sh
$ORADBA_PREFIX/srv/lib/common.sh

# Build scripts (development)
./scripts/build_installer.sh
./scripts/validate_project.sh

# Tests (development)
./tests/run_tests.sh

# Documentation (development)
./doc/DEVELOPMENT.md
```

## Development Workflow

```bash
# 1. Make changes to source files in srv/
vim srv/bin/oraenv.sh

# 2. Run tests
./tests/run_tests.sh

# 3. Validate structure
./scripts/validate_project.sh

# 4. Build installer
./scripts/build_installer.sh

# 5. Test installation
sudo ./dist/oradba_install.sh --prefix /tmp/oradba-test
```

## Adding New Files

### New Script

1. Create in appropriate srv/ subdirectory
2. Use header template from doc/templates/
3. Add to tests/
4. Update documentation

### New Test

1. Create in tests/
2. Use .bats extension
3. Add to run_tests.sh if needed

### New Documentation

1. Developer docs in doc/
2. User docs in srv/doc/
3. Follow markdown linting rules
4. Update relevant README files

## Build Artifacts

Generated during build (gitignored):

```text
build/                      # Temporary build files
dist/                       # Distribution installer
└── oradba_install.sh      # Self-contained installer
```

## See Also

- [README.md](../README.md) - Main documentation
- [DEVELOPMENT.md](DEVELOPMENT.md) - Developer guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
