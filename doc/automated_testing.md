# OraDBA Automated Testing

This directory contains automated test scripts for OraDBA, designed to
automate the majority of tests documented in `manual_testing.md`.

## Test Coverage

**Current Coverage**: ~75-85% of manual tests are now automated
**Test Suites**: 26 test functions covering installation, configuration, and operations
**Estimated Tests**: ~85 individual test cases
**Platform**: Oracle 26ai Free Docker container

See [Manual Tests Coverage](#manual-tests-coverage) section below for detailed breakdown.

## Quick Start

Run automated tests in an Oracle 26ai Free Docker container:

```bash
# From project root
./tests/run_docker_tests.sh
```

**Expected Duration**: 5-8 minutes (includes container startup and ~85 tests)

## Test Architecture

The automated testing system consists of two main components:

1. **run_docker_tests.sh** - Orchestration wrapper that:
   - Builds OraDBA distribution
   - Manages Docker container lifecycle
   - Copies results back to host
   - Handles cleanup

2. **docker_automated_tests.sh** - Core test suite with 26 test functions:
   - Installation tests (8 tests)
   - Environment tests (20+ tests)
   - Operations tests (30+ tests)
   - Configuration tests (15+ tests)
   - Integration tests (12+ tests)

**Test Pattern**: Each test suite follows a consistent pattern:

- Check prerequisites/availability
- Execute operation/command
- Validate results
- Handle errors gracefully (PASS/FAIL/SKIP)

## Test Scripts

### run_docker_tests.sh

Wrapper script that:

1. Builds OraDBA distribution (`make build`)
2. Pulls/starts Oracle 26ai Free Docker container
3. Waits for database to be ready
4. Runs automated tests inside container
5. Collects and saves test results
6. Cleans up container

**Usage:**

```bash
# Run with defaults
./tests/run_docker_tests.sh

# Keep container running after tests (for inspection)
./tests/run_docker_tests.sh --keep-container

# Skip build step (use existing dist/)
./tests/run_docker_tests.sh --no-build

# Use different Docker image
./tests/run_docker_tests.sh --image container-registry.oracle.com/database/free:23.6.0.0
```

**Environment Variables:**

- `ORADBA_TEST_IMAGE` - Docker image to use (default: `container-registry.oracle.com/database/free:latest`)

### docker_automated_tests.sh

Core test script that runs inside the container. Tests:

**Installation Tests:**

- Build artifacts exist
- Fresh installation
- Directory structure
- VERSION file
- Core libraries (6 environment libs)
- Configuration files
- Update/reinstall capability
- Force reinstall with --force flag

**Environment Loading Tests:**

- Source oraenv.sh
- ORACLE_SID, ORACLE_HOME, ORACLE_BASE set correctly
- PATH updated
- Libraries loaded (6 environment libraries)

**Auto-Discovery Tests:**

- Backup/restore oratab
- Verify running instances
- Clear oratab test
- Auto-discovery detection
- Persistence to oratab (system or local fallback)

**Oracle Homes Management Tests:**

- List homes
- Add home with metadata (name, type, alias, description)
- Show home details
- Export/import functionality
- Discover homes with auto-add
- Remove home (cleanup)

**Listener Control Tests:**

- Listener control tool availability
- Listener status check
- Stop/start listener operations
- Verify listener state changes

**Database Control Tests:**

- Database control tool availability
- Database status check
- Stop/start database operations
- Database status after restart

**Validation and Checking Tests:**

- Validation tool (oradba_validate.sh)
- Check tool (oradba_check.sh)
- Verbose checking options

**Enhanced Extensions Tests:**

- Extension tool availability
- List extension templates
- Create extension from template
- Verify extension structure

**Enhanced Oracle Homes Tests:**

- Discover with auto-add
- List homes after discovery
- Show discovered home details
- Export/import configurations

**Environment Management Tests:**

- Environment management tool (oradba_env.sh)
- Environment info/list/status commands
- Different output formats (json, xml, csv, table)
- Environment validation

**Output Format Tests:**

- Status output formats
- List command variations
- Format options testing

**Utilities Tests:**

- Core utility scripts availability
- Additional utility scripts
- Help functionality
- Version information

**Database Status Tests:**

- oraup.sh execution
- Required sections present (plugin architecture)
- Listener status (if running)

**Aliases Tests:**

- Common aliases available (sq, cdh, cda, cdb, taa)

**SQL Scripts Tests:**

- SQL directory and scripts availability
- Key SQL scripts present (afails, al, longops, session, taa)
- SQL script execution test

**RMAN Integration Tests:**

- RMAN control tool (oradba_rman.sh)
- RMAN scripts directory
- RMAN connectivity test

**Log Management Tests:**

- Log rotation tool (oradba_logrotate.sh)
- Help command
- Dry-run test

**SQL*Net Configuration Tests:**

- SQLNet configuration tool (oradba_sqlnet.sh)
- Show configuration
- TNS_ADMIN setting verification

**Service Management Tests:**

- Service management tool (oradba_services.sh)
- Service configuration file
- Service status and list commands

**Help System Tests:**

- Help tool availability (oradba_help.sh)
- General help command
- Command-specific help
- Documentation files

**Configuration Files Tests:**

- Core and standard configuration readability
- Configuration sections validation
- Template files availability

**Database Operations Tests:**

- Database connectivity
- Version and status queries
- Long operations monitoring

**Can be run standalone inside container:**

```bash
# Inside Oracle container
chmod +x /oradba/tests/docker_automated_tests.sh
/oradba/tests/docker_automated_tests.sh
```

## Test Results

Test results are saved to `/tmp/oradba_test_results_YYYYMMDD_HHMMSS.log` with:

- Timestamped log of all test executions
- PASS/FAIL/SKIP status for each test
- Summary with pass rate
- Overall assessment

**Example Output:**

```text
================================================================================
TEST SUMMARY
================================================================================

Total Tests:   85
Passed:        78
Failed:        0
Skipped:       7

Pass Rate:     92%

✓ ALL TESTS PASSED

Results saved to: /tmp/oradba_test_results_20260119_143022.log
```

## Manual Tests Coverage

These automated tests cover approximately **75-85%** of the manual tests in
`../doc/manual_testing.md`:

**Fully Automated:**

- ✅ Installation: Fresh installation (standalone)
- ✅ Installation: Fresh installation (with Oracle)
- ✅ Installation: Update/reinstall
- ✅ Configuration: Environment loading
- ✅ Configuration: Oracle Homes management
- ✅ Configuration: Configuration files validation
- ✅ Daily Use: Database status checking
- ✅ Daily Use: Auto-discovery of running instances
- ✅ Daily Use: Common aliases
- ✅ Daily Use: Database operations (connectivity, queries)
- ✅ Daily Use: SQL scripts availability and execution
- ✅ Daily Use: RMAN integration
- ✅ Daily Use: Listener control operations
- ✅ Daily Use: Database control operations
- ✅ Daily Use: Service management
- ✅ Daily Use: SQL*Net configuration
- ✅ Daily Use: Log management (logrotate)
- ✅ Daily Use: Help system
- ✅ Daily Use: Environment validation tools

**Partially Automated:**

- ⚠️ Configuration: Configuration hierarchy (basic validation only)
- ⚠️ Daily Use: Environment switching (single switch tested)
- ⚠️ Daily Use: Extension system (basic creation tested)

**Not Automated (Still Manual):**

- ❌ Installation: Upgrade installation (requires prior version)
- ❌ Configuration: Coexistence with TVD BasEnv
- ❌ Daily Use: Multi-user environment testing
- ❌ Daily Use: Information commands (detailed verification)
- ❌ Edge Cases: Permission issues (requires specific setup)
- ❌ Edge Cases: Special characters in paths

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: OraDBA Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Docker Tests
        run: |
          ./tests/run_docker_tests.sh
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: /tmp/oradba_test_results_*.log
```

## Customization

### Custom Installation Prefix

```bash
# Inside container
ORADBA_TEST_PREFIX=/custom/path /oradba/tests/docker_automated_tests.sh
```

### Skip Specific Test Suites

Edit `docker_automated_tests.sh` and comment out test suites in `main()`:

```bash
main() {
    # test_installation
    test_environment_loading
    test_auto_discovery
    # test_oracle_homes
    test_database_status
    test_aliases
    
    print_summary
}
```

## Troubleshooting

### Container Won't Start

```bash
# Check if port 1521 is in use
lsof -i :1521

# Check Docker logs
docker logs oradba-test-XXXXX
```

### Database Takes Too Long

Edit `run_docker_tests.sh` and increase `max_wait`:

```bash
wait_for_database() {
    local max_wait=300  # Increase to 5 minutes
    # ...
}
```

### Tests Fail Inside Container

Keep container running for manual inspection:

```bash
./tests/run_docker_tests.sh --keep-container

# Then connect
docker exec -it oradba-test-XXXXX bash

# Manually run tests
/oradba/tests/docker_automated_tests.sh
```

## Future Enhancements

- [ ] Add tests for PDB (Pluggable Database) operations
- [ ] Add tests for Data Guard configurations
- [ ] Add tests for Oracle Unified Directory (OUD)
- [ ] Add tests for WebLogic integration
- [ ] Add tests for DataSafe connector operations
- [ ] Add performance benchmarks
- [ ] Support for Oracle 21c/23ai containers (in addition to 26ai)
- [ ] Parallel test execution for faster runs
- [ ] HTML test report generation
- [ ] Integration with CI/CD for automated regression testing
- [ ] Multi-version testing (test against multiple Oracle versions)
- [ ] Network configuration tests (TNS, Easy Connect)
- [ ] Wallet and encryption tests
- [ ] Backup and recovery scenarios

## See Also

- [Manual Testing Guide](manual_testing.md) - Complete manual test procedures
- [Development Guide](development.md) - Development workflow
- [Release Testing Checklist](release-testing-checklist.md) - Pre-release verification
