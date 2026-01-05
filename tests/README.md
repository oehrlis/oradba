# Test Suite

BATS (Bash Automated Testing System) test suite for OraDBA functionality.

## Overview

The OraDBA test suite provides comprehensive testing of shell scripts, library
functions, and utilities. Tests use BATS framework and are organized by component,
with unit tests for libraries and integration tests for scripts.

## Test Files

| Test File                                                    | Component             | Tests | Description                           |
|--------------------------------------------------------------|-----------------------|-------|---------------------------------------|
| [test_aliases.bats](test_aliases.bats)                       | lib/aliases.sh        | 38    | Alias generation and management       |
| [test_common.bats](test_common.bats)                         | lib/common.sh         | 32    | Core utility functions                |
| [test_db_functions.bats](test_db_functions.bats)             | lib/db_functions.sh   | 24    | Database query and status functions   |
| [test_execute_db_query.bats](test_execute_db_query.bats)     | lib/common.sh         | 22    | SQL query execution                   |
| [test_extensions.bats](test_extensions.bats)                 | lib/extensions.sh     | 42    | Extension discovery and loading       |
| [test_get_seps_pwd.bats](test_get_seps_pwd.bats)             | bin/get_seps_pwd.sh   | 31    | Wallet password utility               |
| [test_installer.bats](test_installer.bats)                   | bin/oradba_install.sh | 64    | Installation and updates              |
| [test_job_wrappers.bats](test_job_wrappers.bats)             | bin/*_jobs.sh         | 39    | Job monitoring wrappers               |
| [test_logging.bats](test_logging.bats)                       | lib/common.sh         | 28    | Unified logging system                |
| [test_longops.bats](test_longops.bats)                       | bin/longops.sh        | 26    | Long operations monitoring            |
| [test_oradba_check.bats](test_oradba_check.bats)             | bin/oradba_check.sh   | 24    | System prerequisites checking         |
| [test_oradba_help.bats](test_oradba_help.bats)               | bin/oradba_help.sh    | 12    | Help system and documentation         |
| [test_oradba_rman.bats](test_oradba_rman.bats)               | bin/oradba_rman.sh    | 44    | RMAN wrapper and backup management    |
| [test_oradba_sqlnet.bats](test_oradba_sqlnet.bats)           | bin/oradba_sqlnet.sh  | 51    | SQL*Net configuration management      |
| [test_oradba_version.bats](test_oradba_version.bats)         | bin/oradba_version.sh | 17    | Version and integrity checking        |
| [test_oraenv.bats](test_oraenv.bats)                         | bin/oraenv.sh         | 25    | Environment setup and switching       |
| [test_oraup.bats](test_oraup.bats)                           | bin/oraup.sh          | 20    | Environment status display            |
| [test_service_management.bats](test_service_management.bats) | bin/oradba_dbctl.sh   | 51    | Database service lifecycle management |
| [test_sid_config.bats](test_sid_config.bats)                 | Configuration         | 17    | SID-specific configuration loading    |
| [test_sync_scripts.bats](test_sync_scripts.bats)             | bin/sync_*.sh         | 51    | Peer synchronization scripts          |

**Total: 658 tests** (comprehensive coverage across all components)

**Latest Updates (v0.14.0)**:

- test_oradba_rman.bats: Added 9 tests for RMAN v0.14.0 features (backup path, dry-run, cleanup)
- test_oradba_check.bats: Enhanced system prerequisites validation tests
- test_oradba_version.bats: Added extension checksum verification tests

## Running Tests

### All Tests

```bash
# Via Makefile
make test

# Or directly
./tests/run_tests.sh

# Or via BATS
bats tests/
```

### Specific Test File

```bash
# Via test runner
./tests/run_tests.sh test_oraenv.bats

# Or directly with BATS
bats tests/test_oraenv.bats
```

### Individual Test

```bash
# Run test matching filter
bats tests/test_common.bats --filter "log_info"

# Run by line number
bats tests/test_common.bats:45
```

### Test Output Options

```bash
# Verbose output (show all test names)
bats --verbose tests/

# Tap output format
bats --tap tests/

# Pretty formatting (default)
bats --pretty tests/

# Show timing
bats --timing tests/
```

## Requirements

### Software

- **BATS Core** - Testing framework

  ```bash
  # macOS
  brew install bats-core
  
  # Debian/Ubuntu
  apt install bats
  
  # RHEL/Oracle Linux
  yum install bats
  ```

- **BATS Support Libraries** (optional, for enhanced features)

  ```bash
  brew tap kaos/shell
  brew install bats-assert bats-support
  ```

### Oracle Database (Optional)

Some integration tests require Oracle Database:

- Oracle Database 12c or higher
- Valid oratab entries
- Database instance running
- SQL*Plus available

Tests requiring database are skipped if unavailable.

## Test Structure

### Test Organization

```text
tests/
├── test_common.bats           # Unit tests for lib/common.sh
├── test_db_functions.bats     # Unit tests for lib/db_functions.sh
├── test_oraenv.bats           # Integration tests for oraenv.sh
├── test_installer.bats        # Build system tests
├── test_oradba_version.bats   # Version utility tests
└── run_tests.sh               # Test runner script
```

### Test Format

Each test file follows standard BATS structure:

```bash
#!/usr/bin/env bats
# Test suite for component

setup() {
    # Run before each test
    load test_helper
    setup_test_environment
}

teardown() {
    # Run after each test
    cleanup_test_environment
}

@test "descriptive test name" {
    # Test code
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected" ]]
}
```

## Test Categories

### Unit Tests

Test individual functions in isolation:

- **test_common.bats** - Logging, oratab parsing, utilities
- **test_db_functions.bats** - Database query functions
- **test_installer.bats** - Build script validation

### Integration Tests

Test complete workflows:

- **test_oraenv.bats** - Environment sourcing, alias generation
- **test_oradba_version.bats** - Version checking, updates

### Mocked Tests

Tests that mock external dependencies:

- Database connections (when DB unavailable)
- File system operations
- External commands

## Test Coverage

Current coverage by component:

| Component         | Functions    | Tested | Coverage |
|-------------------|--------------|--------|----------|
| common.sh         | ~30          | 11     | 37%      |
| db_functions.sh   | ~15          | 23     | 100%*    |
| oraenv.sh         | Main script  | 25     | High     |
| oradba_version.sh | Main script  | 12     | High     |
| Installer         | Build system | 3      | Basic    |

*Some tests skipped without database

## Writing Tests

### Test Template

```bash
#!/usr/bin/env bats
# Tests for your_component

load test_helper

setup() {
    # Setup test environment
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/.."
    source "${ORADBA_BASE}/src/lib/common.sh"
}

@test "function returns expected value" {
    run your_function "arg1"
    [ "$status" -eq 0 ]
    [ "$output" = "expected output" ]
}

@test "function handles error correctly" {
    run your_function "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}
```

### Best Practices

1. **Descriptive names** - Test name explains what is being tested
2. **Single assertion** - Each test checks one thing
3. **Setup/teardown** - Clean environment for each test
4. **Mock dependencies** - Isolate component under test
5. **Test edge cases** - Empty inputs, invalid data, etc.
6. **Skip gracefully** - Skip tests requiring unavailable resources

### Assertions

```bash
# Status checks
[ "$status" -eq 0 ]        # Success
[ "$status" -ne 0 ]        # Failure

# Output matching
[ "$output" = "exact" ]    # Exact match
[[ "$output" =~ "regex" ]] # Regex match
[ -z "$output" ]           # Empty output
[ -n "$output" ]           # Non-empty output

# File checks
[ -f "$file" ]             # File exists
[ -d "$dir" ]              # Directory exists
[ -x "$script" ]           # File executable

# Variable checks
[ "$var" = "value" ]       # String equality
[ "$var" -eq 10 ]          # Numeric equality
```

## Continuous Integration

Tests are run automatically on:

- Every commit (GitHub Actions)
- Pull requests
- Release builds

### CI Configuration

See `.github/workflows/test.yml` for CI setup.

## Troubleshooting

### BATS Not Found

```bash
# Install BATS
brew install bats-core  # macOS
apt install bats        # Debian/Ubuntu
```

### Tests Fail with Database Errors

Some tests require Oracle Database. Either:

1. Install and start Oracle Database
2. Configure oratab entries
3. Or skip database tests (automatically skipped if DB unavailable)

### Permission Errors

```bash
# Make test scripts executable
chmod +x tests/*.bats
chmod +x tests/run_tests.sh
```

## Documentation

- **[Development Guide](../doc/development.md)** - Coding standards and testing guidelines
- **[BATS Documentation](https://bats-core.readthedocs.io/)** - BATS framework reference
- **[Test Helpers](https://github.com/bats-core/bats-support)** - BATS support library

## Development

### Adding New Tests

1. Create new `.bats` file or add to existing
2. Follow naming convention: `test_<component>.bats`
3. Include setup and teardown functions
4. Write tests with descriptive names
5. Test locally before committing
6. Update this README with test counts

### Running Tests During Development

```bash
# Quick check
bats tests/test_common.bats

# Watch for changes (requires entr)
find src tests -name '*.sh' -o -name '*.bats' | entr bats tests/

# Run specific component tests
make test-common
make test-oraenv
```

See [development.md](../doc/development.md) for complete testing guidelines.
