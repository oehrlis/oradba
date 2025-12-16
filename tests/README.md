# OraDBA Test Suite

BATS (Bash Automated Testing System) test suite for OraDBA functionality.

## Test Files

- **[test_common.bats](test_common.bats)** - Common library functions (11 tests)
- **[test_db_functions.bats](test_db_functions.bats)** - Database operations
  (23 tests)
- **[test_oraenv.bats](test_oraenv.bats)** - Environment setup (25 tests)
- **[test_installer.bats](test_installer.bats)** - Build and install (3 tests)
- **[test_oradba_version.bats](test_oradba_version.bats)** - Version management
  (12 tests)

**Total: 78 tests** (3 skipped integration tests)

## Running Tests

Run all tests:

```bash
make test
```

Run specific test file:

```bash
bats tests/test_oraenv.bats
./tests/run_tests.sh test_oraenv.bats
```

Run individual test:

```bash
bats tests/test_common.bats --filter "log_info"
```

## Requirements

- BATS framework (`brew install bats-core` or `apt install bats`)
- Oracle Database (for db_functions integration tests)
- Valid oratab entries (see `src/etc/oratab.example`)

## Test Structure

The test suite includes 106 tests across 6 test files:

- **test_aliases.bats** (28 tests) - Dynamic alias generation functions
- **test_common.bats** (11 tests) - Common library functions
- **test_db_functions.bats** (35 tests) - Database interaction functions
- **test_installer.bats** (3 tests) - Installer build validation
- **test_oradba_version.bats** (15 tests) - Version management utility
- **test_oraenv.bats** (26 tests) - Environment setup script

Tests use standard BATS format with `setup()` and `teardown()` functions.
Each test file focuses on a specific module or script.

## Documentation

See [DEVELOPMENT.md](../doc/DEVELOPMENT.md) for:

- Writing new tests
- Test coverage guidelines
- CI/CD integration
- Mocking strategies
