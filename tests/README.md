# OraDBA Test Suite

BATS (Bash Automated Testing System) test suite for OraDBA functionality.

## Test Files

- **[test_common.bats](test_common.bats)** - Tests for common.sh library
- **[test_db_functions.bats](test_db_functions.bats)** - Tests for database
  functions
- **[test_oraenv.bats](test_oraenv.bats)** - Tests for oraenv.sh script
- **[test_installer.bats](test_installer.bats)** - Tests for installer

## Running Tests

Run all tests:

```bash
make test
```

Run specific test file:

```bash
./tests/run_tests.sh test_oraenv.bats
```

## Requirements

- BATS framework
- Oracle Database (for db_functions tests)
- Valid oratab entries

## Documentation

See [DEVELOPMENT.md](../doc/DEVELOPMENT.md) for:

- Writing new tests
- Test coverage guidelines
- CI/CD integration
- Mocking strategies
