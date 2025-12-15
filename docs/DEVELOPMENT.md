# Development Guide

This guide provides detailed information for developers working on oradba.

## Project Structure

```
oradba/
├── .github/
│   └── workflows/        # GitHub Actions CI/CD workflows
│       ├── ci.yml        # Continuous integration
│       ├── release.yml   # Release automation
│       └── dependency-review.yml
├── srv/                  # Server/service files
│   ├── bin/             # Executable scripts
│   │   └── oraenv.sh    # Core environment setup script
│   ├── lib/             # Library functions
│   │   └── common.sh    # Common utility functions
│   ├── etc/             # Configuration files
│   │   └── oradba.conf  # Main configuration
│   ├── sql/             # SQL scripts
│   │   ├── db_info.sql  # Database information
│   │   └── login.sql    # SQL*Plus login script
│   ├── rcv/             # RMAN recovery scripts
│   │   └── backup_full.rman
│   └── templates/       # Template files
│       └── script_template.sh
├── test/                # BATS test files
│   ├── test_common.bats
│   ├── test_oraenv.bats
│   ├── test_installer.bats
│   └── run_tests.sh     # Test runner
├── build/               # Build artifacts (gitignored)
├── dist/                # Distribution files (gitignored)
├── build_installer.sh   # Installer builder
├── VERSION              # Semantic version
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

## Core Components

### oraenv.sh

The core script that sets up Oracle environment variables based on oratab configuration.

**Key Features:**
- Reads oratab file
- Sets ORACLE_SID, ORACLE_HOME, ORACLE_BASE
- Updates PATH and LD_LIBRARY_PATH
- Handles TNS_ADMIN and NLS settings
- Must be sourced, not executed

**Usage:**
```bash
source oraenv.sh ORCL
```

### common.sh

Library of common functions used across scripts.

**Key Functions:**
- `log_info()`, `log_error()`, `log_warn()`, `log_debug()`
- `command_exists()` - Check command availability
- `verify_oracle_env()` - Validate Oracle environment
- `parse_oratab()` - Parse oratab entries
- `export_oracle_base_env()` - Set common Oracle variables

### Configuration

Main configuration file: [srv/etc/oradba.conf](srv/etc/oradba.conf)

**Key Settings:**
- `ORADBA_PREFIX` - Installation directory
- `ORATAB_FILE` - Path to oratab
- `DEBUG` - Debug mode toggle
- `LOG_DIR` - Log directory
- `BACKUP_DIR` - Backup location

## Development Workflow

### 1. Making Changes

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
vim srv/bin/oraenv.sh

# Test changes
./test/run_tests.sh
```

### 2. Testing

```bash
# Run all tests
./test/run_tests.sh

# Run specific test file
bats test/test_common.bats

# Run with debug output
DEBUG=1 bats test/test_common.bats
```

### 3. Linting

```bash
# Install shellcheck
brew install shellcheck  # macOS
sudo apt-get install shellcheck  # Ubuntu

# Lint all scripts
find . -name "*.sh" -not -path "./dist/*" -not -path "./build/*" | xargs shellcheck
```

### 4. Building

```bash
# Build installer
./build_installer.sh

# Test installer locally
sudo ./dist/oradba_install.sh --prefix /tmp/oradba-test
```

## Testing Guide

### BATS Testing Framework

BATS (Bash Automated Testing System) is used for all tests.

**Test Structure:**
```bash
#!/usr/bin/env bats

setup() {
    # Setup before each test
}

teardown() {
    # Cleanup after each test
}

@test "test description" {
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}
```

**Common Assertions:**
- `[ "$status" -eq 0 ]` - Command succeeded
- `[ "$status" -ne 0 ]` - Command failed
- `[[ "$output" =~ "pattern" ]]` - Output matches pattern
- `[ -f "file" ]` - File exists
- `[ -d "dir" ]` - Directory exists

### Writing Tests

1. **Unit Tests** - Test individual functions
   ```bash
   @test "log_info outputs correct format" {
       run log_info "Test message"
       [ "$status" -eq 0 ]
       [[ "$output" =~ \[INFO\] ]]
   }
   ```

2. **Integration Tests** - Test script interactions
   ```bash
   @test "oraenv sets environment correctly" {
       source oraenv.sh TESTDB
       [ "$ORACLE_SID" = "TESTDB" ]
   }
   ```

3. **Mock Data** - Create temporary test data
   ```bash
   setup() {
       TEST_DIR=$(mktemp -d)
       cat > "$TEST_DIR/oratab" <<EOF
   TESTDB:/oracle/19c:N
   EOF
   }
   ```

## CI/CD Pipeline

### GitHub Actions Workflows

1. **CI Workflow** ([.github/workflows/ci.yml](.github/workflows/ci.yml))
   - Triggered on push/PR to main/develop
   - Runs shellcheck linting
   - Executes BATS tests
   - Builds installer
   - Validates installation

2. **Release Workflow** ([.github/workflows/release.yml](.github/workflows/release.yml))
   - Triggered on version tags (v*.*.*)
   - Builds installer
   - Creates GitHub release
   - Uploads artifacts

3. **Dependency Review**
   - Runs on pull requests
   - Security scanning

### Creating a Release

```bash
# Update version
echo "0.2.0" > VERSION

# Update changelog
vim CHANGELOG.md

# Commit changes
git add VERSION CHANGELOG.md
git commit -m "chore: Bump version to 0.2.0"

# Create and push tag
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin main --tags
```

## Installer Architecture

### Build Process

The installer is created by `build_installer.sh`:

1. Creates tarball of srv/ directory and documentation
2. Generates installer script with embedded base64 payload
3. Appends base64-encoded tarball to installer script
4. Makes installer executable

### Installer Features

- Self-contained (no external dependencies)
- Base64-encoded payload
- Customizable installation prefix
- Permission handling
- User ownership support
- Symbolic link creation

### Installer Usage

```bash
# Basic installation
./oradba_install.sh

# Custom prefix
./oradba_install.sh --prefix /usr/local/oradba

# As specific user
sudo ./oradba_install.sh --user oracle
```

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backward-compatible functionality
- **PATCH** version: Backward-compatible bug fixes

Version is stored in `VERSION` file and used by:
- Installer script
- Release workflow
- Documentation

## Best Practices

### Bash Scripting

1. **Use strict mode**
   ```bash
   set -e  # Exit on error
   set -u  # Exit on undefined variable
   set -o pipefail  # Exit on pipe failure
   ```

2. **Quote variables**
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

3. **Use local variables in functions**
   ```bash
   my_function() {
       local var="value"
       # Function body
   }
   ```

4. **Check command existence**
   ```bash
   if command_exists "oracle"; then
       # Use command
   fi
   ```

### Documentation

1. Add header comments to all scripts
2. Document function parameters and return values
3. Update README.md for user-visible changes
4. Keep CHANGELOG.md updated

### Testing

1. Write tests for new functionality
2. Test error conditions
3. Use meaningful test descriptions
4. Clean up test artifacts in teardown

## Troubleshooting

### Common Issues

**BATS not found:**
```bash
# macOS
brew install bats-core

# Ubuntu
sudo apt-get install bats
```

**Permission denied:**
```bash
chmod +x script.sh
```

**Tests failing:**
```bash
# Run with debug
DEBUG=1 ./test/run_tests.sh

# Run specific test
bats -t test/test_common.bats
```

## Resources

- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [BATS Documentation](https://bats-core.readthedocs.io/)
- [ShellCheck](https://www.shellcheck.net/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

## Getting Help

- Open an issue on GitHub
- Review existing documentation
- Check closed issues for solutions
- Read the test files for examples
