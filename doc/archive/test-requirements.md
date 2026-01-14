# Test Requirements for High-Priority Scripts

**Date:** 2026-01-14  
**Phase:** 5.2 - Script Enhancements  
**Status:** Requirements Defined

---

## Overview

This document outlines test requirements for high-priority scripts that currently lack
dedicated BATS test files. These tests should be implemented in future phases to improve
code coverage and reliability.

**Current Test Coverage:** 892 tests via `make test-full`

---

## 1. oradba_env.sh (CRITICAL)

**Priority:** CRITICAL  
**Script Type:** Main environment orchestrator  
**Complexity:** High

### Test Requirements

#### Unit Tests (Isolated Functions)

- Environment detection and validation
- SID argument parsing
- Configuration file sourcing order
- Error handling for missing files
- Help and version display

#### Integration Tests  

- Full environment setup with valid SID
- Environment setup without SID (default behavior)
- Multiple rapid sourcing (idempotency)
- Integration with oraenv.sh wrapper
- Interaction with oradba_homes.conf

#### Edge Cases

- Invalid SID handling
- Missing Oracle homes
- Corrupted configuration files
- Pre-Oracle installation mode
- Coexistence mode (basenv)

**Estimated Tests:** 30-40 tests

---

## 2. oradba_dbctl.sh

**Priority:** HIGH  
**Script Type:** Database control wrapper  
**Complexity:** Medium-High

### Test Requirements

#### Unit Tests

- Command-line argument parsing (start/stop/restart/status)
- SID validation and selection
- Environment sourcing per SID
- Shutdown timeout handling
- PDB opening logic

#### Integration Tests (Mocked)

- Start operation with valid SID
- Stop operation with graceful shutdown
- Restart sequence
- Status display
- Multiple SID handling
- Force mode operations

#### Edge Cases

- Invalid SID provided
- Timeout during shutdown
- Database already running/stopped
- Missing ORACLE_HOME
- Permission issues

**Estimated Tests:** 25-30 tests

---

## 3. oradba_lsnrctl.sh

**Priority:** HIGH  
**Script Type:** Listener control wrapper  
**Complexity:** Medium

### Test Requirements

#### Unit Tests

- Command-line argument parsing
- Listener name parsing
- ORACLE_HOME detection
- TNS_ADMIN configuration

#### Integration Tests (Mocked)

- Start default listener
- Start named listener
- Stop listener
- Restart sequence
- Status display
- Multiple listener handling

#### Edge Cases

- No Oracle homes available
- Missing listener.ora
- TNS_ADMIN not set
- Listener already running/stopped

**Estimated Tests:** 20-25 tests

---

## 4. oradba_services.sh

**Priority:** HIGH  
**Script Type:** Service orchestration  
**Complexity:** High

### Test Requirements

#### Unit Tests

- Configuration file loading
- Service order parsing
- Dependency validation
- Start/stop sequence generation

#### Integration Tests (Mocked)

- Start all services in order
- Stop all services in reverse order
- Restart sequence
- Status display for all services
- Selective service control
- Configuration template auto-copy

#### Edge Cases

- Missing configuration file
- Circular dependencies
- Service start failures mid-sequence
- Timeout handling
- Lock file conflicts

**Estimated Tests:** 30-35 tests

---

## 5. oradba_validate.sh

**Priority:** MEDIUM (recently updated)  
**Script Type:** Installation validator  
**Complexity:** Medium

### Test Requirements

#### Unit Tests

- Directory existence checks
- File existence checks
- Permission checks
- Checksum validation
- Pre-Oracle mode detection

#### Integration Tests

- Full validation pass (all files present)
- Partial installation (missing optional files)
- Modified files detection
- Pre-Oracle vs. Oracle installed modes
- Verbose vs. quiet output

#### Edge Cases

- Completely missing installation
- Corrupted checksum file
- Permission issues
- Symlink handling

**Estimated Tests:** 20-25 tests

---

## Implementation Strategy

### Phase 1: Critical Tests (oradba_env.sh)

- Focus on core environment setup
- Test configuration loading
- Validate SID handling
- **Target:** v0.24.0

### Phase 2: Control Scripts

- oradba_dbctl.sh, oradba_lsnrctl.sh
- Focus on mocked integration tests
- **Target:** v0.25.0

### Phase 3: Service Orchestration

- oradba_services.sh
- Complex dependency handling
- **Target:** v0.26.0

### Phase 4: Validation & Utilities

- oradba_validate.sh
- Additional utility scripts
- **Target:** v0.27.0

---

## Test Infrastructure

### Existing Patterns

- Use BATS (Bash Automated Testing System)
- Mock external dependencies (sqlplus, lsnrctl, etc.)
- Use temporary directories for file operations
- Isolate tests from real Oracle installations

### Helper Functions Needed

- `mock_oratab()` - Create temporary oratab
- `mock_oracle_home()` - Create fake ORACLE_HOME structure
- `mock_config_files()` - Generate test configurations
- `setup_test_env()` - Initialize test environment
- `teardown_test_env()` - Clean up after tests

### Test Organization

```text
tests/
├── test_oradba_env.bats          # Main environment tests
├── test_oradba_dbctl.bats        # Database control tests
├── test_oradba_lsnrctl.bats      # Listener control tests
├── test_oradba_services.bats     # Service orchestration tests
├── helpers/
│   ├── mock_oracle.bash          # Oracle mocking helpers
│   └── test_config.bash          # Configuration helpers
```

---

## Success Criteria

- **Code Coverage:** 70%+ for critical scripts
- **Reliability:** All tests pass consistently
- **Speed:** Full test suite completes in <5 minutes
- **Maintainability:** Tests are well-documented and easy to update
- **CI Integration:** Tests run automatically on commits

---

## References

- Existing test patterns: tests/test_oradba_homes.bats (53 tests)
- BATS documentation: <https://github.com/bats-core/bats-core>
- Mocking patterns: tests/test_oradba_common.bats

---

**Note:** This is a planning document. Actual test implementation will occur in future
phases based on priority and resource availability. The 892 existing tests provide good
coverage for library functions and several key scripts.
