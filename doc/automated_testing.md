# OraDBA Automated Testing

This directory contains automated test scripts for OraDBA, designed to
partially automate the manual tests documented in `../doc/manual_testing.md`.

## Quick Start

Run automated tests in an Oracle 26ai Free Docker container:

```bash
# From project root
./tests/run_docker_tests.sh
```

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

**Environment Loading Tests:**

- Source oraenv.sh
- ORACLE_SID, ORACLE_HOME, ORACLE_BASE set correctly
- PATH updated
- Libraries loaded

**Auto-Discovery Tests:**

- Backup/restore oratab
- Verify running instances
- Clear oratab test
- Auto-discovery detection
- Persistence to oratab (system or local fallback)

**Oracle Homes Management Tests:**

- List homes
- Add home
- Show home details
- Export/import

**Database Status Tests:**

- oraup.sh execution
- Required sections present
- Listener status (if running)

**Aliases Tests:**

- Common aliases available (sq, cdh, cda, cdb, taa)

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

Total Tests:   42
Passed:        39
Failed:        0
Skipped:       3

Pass Rate:     93%

✓ ALL TESTS PASSED

Results saved to: /tmp/oradba_test_results_20260115_143022.log
```

## Manual Tests Coverage

These automated tests cover approximately **60-70%** of the manual tests in
`../doc/manual_testing.md`:

**Fully Automated:**

- ✅ Installation: Fresh installation (standalone)
- ✅ Installation: Fresh installation (with Oracle)
- ✅ Configuration: Environment loading
- ✅ Configuration: Oracle Homes management
- ✅ Daily Use: Database status checking
- ✅ Daily Use: Auto-discovery of running instances
- ✅ Daily Use: Common aliases

**Partially Automated:**

- ⚠️ Configuration: Configuration hierarchy (basic validation only)
- ⚠️ Daily Use: Environment switching (single switch tested)

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

- [ ] Add tests for PDB aliases
- [ ] Add tests for SQL scripts
- [ ] Add tests for RMAN integration
- [ ] Add tests for extension system
- [ ] Add performance benchmarks
- [ ] Support for Oracle 21c/23ai containers
- [ ] Parallel test execution
- [ ] HTML test report generation

## See Also

- [Manual Testing Guide](../doc/manual_testing.md) - Complete manual test procedures
- [Development Guide](../doc/development.md) - Development workflow
- [Release Testing Checklist](../doc/release-testing-checklist.md) - Pre-release verification
