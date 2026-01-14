# Legacy Code Analysis Report

**Date:** 2026-01-14  
**Phase:** 5.1 - Code Quality Improvements  
**Status:** Analysis Complete

---

## Executive Summary

This report identifies orphaned functions, scripts, and test files in the
OraDBA codebase as part of Phase 5 code quality improvements. The analysis
helps prioritize cleanup and refactoring efforts.

### Key Findings

- **3 Orphaned Functions** identified in oradba_common.shmmon.sh
- **18 Scripts without tests** identified
- **18 Test files** testing library modules (not scripts)
- Most functions are actively used; orphaned items are candidates for removal

---

## 1. Orphaned Functions

### 1.1 Complete Orphans (Not Used Anywhere)

These functions are defined but never called:

| Function                  | Library   | Recommendation                              |
|---------------------------|-----------|---------------------------------------------|
| `detect_basenv`           | oradba_common.sh | **REMOVE** - Likely legacy basenv detection |
| `get_oracle_home_version` | oradba_common.sh | **REMOVE** - Superseded                     |
| `show_version_info`       | oradba_common.sh | **REMOVE** - Replaced by script             |

**Action:** Remove these 3 functions in Phase 5.1

### 1.2 Low-Usage Functions (<3 usages)

These functions have limited usage and may need review:

#### oradba_common.sh

- `get_script_dir` (2 uses)
- `alias_exists` (2 uses)
- `verify_oracle_env` (2 uses)
- `get_oracle_version` (2 uses)
- `export_oracle_base_env` (2 uses)
- `resolve_oracle_home_name` (2 uses)
- `get_oracle_home_alias` (1 use)
- `detect_oracle_version` (2 uses)
- `derive_oracle_base` (2 uses)
- `set_install_info` (1 use)
- `init_install_info` (2 uses)
- `configure_sqlpath` (2 uses)
- `show_sqlpath` (2 uses)
- `show_path` (1 use)
- `show_config` (1 use)

#### Other Libraries

- `generate_base_aliases` - oradba_aliases.sh (2 uses)
- `show_oracle_home_status` - oradba_db_functions.sh (2 uses)
- `extension_provides` - extensions.sh (1 use)
- `create_extension_alias` - extensions.sh (2 uses)
- `list_extensions` - extensions.sh (1 use)
- `show_extension_info` - extensions.sh (2 uses)
- `oradba_auto_reload_on_change` - oradba_env_changes.sh (2 uses)

**Action:** Review context of usage. These may be:

- Utility functions called sparingly (KEEP)
- Candidates for consolidation (REFACTOR)
- Legacy functions no longer needed (REMOVE)

#### Review Completed

After analyzing usage context, all low-usage functions are legitimate utilities:

**KEEP - Core Utilities (oradba_common.sh):**

- `get_script_dir` (2 uses) - Used in tests, utility for path resolution
- `alias_exists` (2 uses) - Internal helper for alias management
- `verify_oracle_env` (2 uses) - Used in tests, validates environment
- `get_oracle_version` (2 uses) - Used in oradba_db_functions.sh, core functionality
- `export_oracle_base_env` (2 uses) - Used in oraenv.sh, critical for setup
- `resolve_oracle_home_name` (2 uses) - Internal, used twice in oradba_common.sh
- `get_oracle_home_alias` (1 use) - Internal helper for home management
- `detect_oracle_version` (2 uses) - Used in oradba_homes.sh, core function
- `derive_oracle_base` (2 uses) - Used in oraenv.sh, critical for base setup
- `set_install_info` (1 use) - Used in tests, version tracking
- `init_install_info` (2 uses) - Used in tests, version initialization
- `configure_sqlpath` (2 uses) - Used in oraenv.sh, configures SQL environment
- `show_sqlpath` (2 uses) - Display utility, may be user-facing in future
- `show_path` (1 use) - Display utility, mirrors show_sqlpath pattern
- `show_config` (1 use) - Display utility, shows config hierarchy (user-facing)

**KEEP - Extension System (extensions.sh):**

- `generate_base_aliases` (2 uses) - Called at init, essential for alias system
- `extension_provides` (1 use) - Internal helper for extension detection
- `create_extension_alias` (2 uses) - Used in extension loading, essential
- `list_extensions` (1 use) - User-facing command, likely to gain more usage
- `show_extension_info` (2 uses) - Used in oradba_extension.sh, user-facing

**KEEP - Other Modules:**

- `show_oracle_home_status` (2 uses) - oradba_db_functions.sh, displays home info
- `oradba_auto_reload_on_change` (2 uses) - oradba_env_changes.sh, exported func

**Rationale:** All functions serve legitimate purposes:

- Internal utilities with focused usage (alias_exists, resolve_oracle_home_name)
- Core setup functions (export_oracle_base_env, derive_oracle_base)
- User-facing display functions (show_config, show_sqlpath, show_path)
- Extension system infrastructure (all extensions.sh functions)
- Test support (set_install_info, init_install_info, verify_oracle_env)

Low usage count doesn't indicate technical debt - these are specialized
functions called at specific points in the lifecycle (init, setup, display).

**Action:** No removals needed. Mark review as complete.

---

## 2. Scripts Without Tests

The following scripts lack dedicated BATS test files:

| Script                    | Category  | Priority | Notes                                     |
|---------------------------|-----------|----------|-------------------------------------------|
| `dbstatus.sh`             | Legacy?   | LOW      | May be superseded by oradba_env.sh status |
| `exp_jobs.sh`             | Job Wrap  | MEDIUM   | Part of export/import job system          |
| `imp_jobs.sh`             | Job Wrap  | MEDIUM   | Part of export/import job system          |
| `rman_jobs.sh`            | Job Wrap  | MEDIUM   | RMAN backup job wrapper                   |
| `oradba_dbctl.sh`         | Control   | HIGH     | Database control - needs tests            |
| `oradba_lsnrctl.sh`       | Control   | HIGH     | Listener control - needs tests            |
| `oradba_services.sh`      | Service   | HIGH     | Service orchestration - needs tests       |
| `oradba_services_root.sh` | Service   | HIGH     | Root service management - needs tests     |
| `oradba_env.sh`           | Core      | CRITICAL | **Main environment script**               |
| `oradba_extension.sh`     | Extension | MEDIUM   | Extension management                      |
| `oradba_install.sh`       | Setup     | MEDIUM   | Installation script                       |
| `oradba_setup.sh`         | Setup     | MEDIUM   | Setup script                              |
| `oradba_logrotate.sh`     | Utility   | LOW      | Log rotation utility                      |
| `oradba_validate.sh`      | Utility   | MEDIUM   | Environment validation                    |
| `sessionsql.sh`           | Legacy?   | LOW      | Session SQL utility - check if used       |
| `sync_from_peers.sh`      | Sync      | LOW      | Peer sync - specialized use case          |
| `sync_to_peers.sh`        | Sync      | LOW      | Peer sync - specialized use case          |
| `get_seps_pwd.sh`         | Utility   | LOW      | Password utility - has tests              |

**Recommendations:**

1. **High Priority Tests** (Phase 5):
   - oradba_env.sh
   - oradba_dbctl.sh
   - oradba_lsnrctl.sh
   - oradba_services.sh
   - oradba_services_root.sh

2. **Medium Priority Tests** (Phase 6):
   - Job wrappers (exp_jobs.sh, imp_jobs.sh, rman_jobs.sh)
   - Extension and setup scripts
   - oradba_validate.sh

3. **Low Priority / Consider Removal**:
   - dbstatus.sh (superseded by oradba_env.sh status?)
   - sessionsql.sh (check usage)
   - Sync scripts (if not actively used)

---

## 3. Test Files Analysis

### 3.1 Library Test Files (18 files)

These test **libraries**, not standalone scripts - this is **CORRECT** and expected:

| Test File                        | Tests                       | Status   |
|----------------------------------|-----------------------------|----------|
| test_oradba_aliases.bats                | oradba_aliases.sh library          | ✅ VALID |
| test_oradba_common.bats                 | oradba_common.sh library           | ✅ VALID |
| test_oradba_db_functions.bats           | oradba_db_functions.sh library     | ✅ VALID |
| test_execute_db_query.bats       | execute_db_query() function | ✅ VALID |
| test_extensions.bats             | extensions.sh library       | ✅ VALID |
| test_installer.bats              | Installation functions      | ✅ VALID |
| test_job_wrappers.bats           | Job wrapper functions       | ✅ VALID |
| test_logging.bats                | Logging functions           | ✅ VALID |
| test_logging_infrastructure.bats | Log infrastructure          | ✅ VALID |
| test_oracle_homes.bats           | Oracle Homes functions      | ✅ VALID |
| test_oradba_env_changes.bats     | oradba_env_changes.sh       | ✅ VALID |
| test_oradba_env_config.bats      | oradba_env_config.sh        | ✅ VALID |
| test_oradba_env_parser.bats      | oradba_env_parser.sh        | ✅ VALID |
| test_oradba_env_status.bats      | oradba_env_status.bats      | ✅ VALID |
| test_oratab_priority.bats        | Oratab priority handling    | ✅ VALID |
| test_service_management.bats     | Service management tests    | ✅ VALID |
| test_sid_config.bats             | SID configuration           | ✅ VALID |
| test_sync_scripts.bats           | Sync script tests           | ✅ VALID |

**Action:** No changes needed. These tests are correctly structured to test library functionality.

### 3.2 Script Test Files (Existing)

Scripts with test coverage (run via `make test-full`, 892 tests total):

| Script            | Test File                | Status            |
|-------------------|--------------------------|-------------------|
| oradba_check.sh   | test_oradba_check.bats   | ✅ HAS TESTS      |
| oradba_help.sh    | test_oradba_help.bats    | ✅ HAS TESTS      |
| oradba_homes.sh   | test_oradba_homes.bats   | ✅ HAS TESTS (53) |
| oradba_rman.sh    | test_oradba_rman.bats    | ✅ HAS TESTS      |
| oradba_sqlnet.sh  | test_oradba_sqlnet.bats  | ✅ HAS TESTS      |
| oradba_version.sh | test_oradba_version.bats | ✅ HAS TESTS      |
| oraenv.sh         | test_oraenv.bats         | ✅ HAS TESTS      |
| oraup.sh          | test_oraup.bats          | ✅ HAS TESTS      |
| longops.sh        | test_longops.bats        | ✅ HAS TESTS      |
| get_seps_pwd.sh   | test_get_seps_pwd.bats   | ✅ HAS TESTS      |

---

## 4. Documentation Gaps

Most scripts are not documented in user-facing documentation. This is tracked separately in Phase 5.3.

---

## 5. Recommended Actions

### Phase 5.1 - Immediate Cleanup

1. **Remove 3 orphaned functions from oradba_common.sh:**

   ```bash
   - detect_basenv()
   - get_oracle_home_version()
   - show_version_info()
   ```

2. **Review low-usage functions** - Determine if they are:
   - Utility functions (keep)
   - Redundant (consolidate)
   - Legacy (remove)

3. **Identify truly legacy scripts:**
   - dbstatus.sh - Check if superseded by oradba_env.sh status
   - sessionsql.sh - Verify usage in production

### Phase 5.2 - Add Critical Tests

Create BATS tests for high-priority scripts:

1. oradba_env.sh (CRITICAL)
2. oradba_dbctl.sh
3. oradba_lsnrctl.sh
4. oradba_services.sh
5. oradba_services_root.sh

### Phase 5.3 - Documentation

- Document all user-facing scripts
- Update architecture diagrams
- Create command reference

### Phase 6 - Remaining Tests

Add tests for medium-priority scripts:

- Job wrappers
- Extension management
- Setup and installation scripts

---

## 6. Success Metrics

- **Code Reduction:** Remove orphaned functions (target: 3+ functions)
- **Test Coverage:** Increase from current ~30 script tests to 35+ tests
- **Documentation:** All user-facing scripts documented
- **Maintainability:** Clear ownership and purpose for all code

---

## Appendix: Analysis Methodology

```bash
# Count function usage across codebase
grep -r "\bfunction_name\b" src/ tests/ --include="*.sh" --include="*.bats"
```

**Script Analysis:**

```bash
# Check for corresponding test files
for script in src/bin/*.sh; do
    test_file="tests/test_$(basename $script .sh).bats"
    [[ -f $test_file ]] || echo "Missing: $test_file"
done
```

**Test File Analysis:**

```bash
# Check for orphaned test files
for test in tests/test_*.bats; do
    script="src/bin/$(basename $test | sed 's/test_//' | sed 's/.bats/.sh/')"
    [[ -f $script ]] || echo "Orphaned: $test"
done
```

---

**Next Steps:** Begin implementation of Phase 5.1 cleanup tasks.
