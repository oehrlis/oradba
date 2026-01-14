# Function Header Standardization Plan

**Date:** 2026-01-14  
**Phase:** 5.3 - Documentation Improvements  
**Status:** Planning Document

---

## Overview

This document outlines the plan to standardize function headers across the OraDBA codebase
to improve maintainability and documentation quality.

---

## Current Standard

Based on recently implemented Phase 1-3 libraries, the standard format is:

```bash
# ------------------------------------------------------------------------------
# Function: function_name
# Purpose.: Brief description of what the function does
# Args....: $1 - First argument description
#          $2 - Second argument description (optional)
# Returns.: 0 on success, 1 on error
# Output..: Description of what the function outputs
# Notes...: Additional important information (optional)
# ------------------------------------------------------------------------------
function_name() {
    # Implementation
}
```

### Key Elements

- **Function:** Name of the function
- **Purpose.:** One-line description (note the period after Purpose)
- **Args....:** Parameter descriptions with $1, $2, etc. (note the periods)
- **Returns.:** Return codes and their meanings
- **Output..:** What the function prints/outputs
- **Notes...:** Optional additional context

---

## Current Status

### Files with Good Headers ✅

- `src/lib/oradba_env_parser.sh` - All functions properly documented
- `src/lib/oradba_env_builder.sh` - All functions properly documented
- `src/lib/oradba_env_validator.sh` - All functions properly documented
- `src/lib/oradba_env_config.sh` - All functions properly documented
- `src/lib/oradba_env_status.sh` - All functions properly documented
- `src/lib/oradba_env_changes.sh` - All functions properly documented

### Files Needing Updates ⚠️

- `src/lib/oradba_common.shmmon.sh` - ~130 functions, many missing proper headers
- `src/lib/oradba_aliases.sh` - Several functions need header updates
- `src/lib/oradba_db_functions.sh` - Several functions need header updates
- `src/lib/extensions.sh` - Several functions need header updates

---

## Functions Needing Headers (oradba_common.sh)

### Priority 1: Core Utilities (High Usage)

- `get_script_dir()` - Path resolution utility
- `init_logging()` - Logging initialization
- `init_session_log()` - Session log setup
- `oradba_log()` - Main logging function (already has good docs)
- `execute_db_query()` - Database query execution
- `get_oratab_path()` - Oratab file location
- `is_dummy_sid()` - SID validation
- `command_exists()` - Command availability check
- `alias_exists()` - Alias existence check
- `safe_alias()` - Safe alias creation

### Priority 2: Oracle Environment (Medium Usage)

- `verify_oracle_env()` - Environment validation
- `get_oracle_version()` - Version detection
- `parse_oratab()` - Oratab parsing
- `generate_sid_lists()` - SID list generation
- `generate_oracle_home_aliases()` - Home alias creation
- `export_oracle_base_env()` - ORACLE_BASE setup
- `resolve_oracle_home_name()` - Home name resolution
- `get_oracle_home_alias()` - Home alias lookup
- `detect_oracle_version()` - Version detection
- `derive_oracle_base()` - ORACLE_BASE derivation

### Priority 3: Configuration & Display (Low Usage)

- `configure_sqlpath()` - SQLPATH configuration
- `show_sqlpath()` - SQLPATH display
- `show_path()` - PATH display
- `show_config()` - Configuration display
- `set_install_info()` - Installation metadata
- `init_install_info()` - Installation init

---

## Implementation Strategy

### Phase 1: Update High-Priority Functions (5.3)

Focus on most-used functions in oradba_common.sh:

- Logging functions (init_logging, oradba_log, etc.)
- Core utilities (get_script_dir, command_exists, etc.)
- Database functions (execute_db_query, get_oratab_path, etc.)

**Target:** Add headers to 20 most-used functions  
**Timeline:** Phase 5.3 (current phase)

### Phase 2: Complete oradba_common.sh (5.4)

- Update remaining ~110 functions
- Ensure consistency across all functions
- Verify all parameters are documented

**Target:** 100% header coverage in oradba_common.sh  
**Timeline:** Phase 5.4

### Phase 3: Update Other Libraries (Future)

- oradba_aliases.sh
- oradba_db_functions.sh
- extensions.sh

**Target:** All libraries with consistent headers  
**Timeline:** Phase 6

---

## Header Template

Copy-paste template for quick implementation:

```bash
# ------------------------------------------------------------------------------
# Function: FUNCTION_NAME
# Purpose.: BRIEF_DESCRIPTION
# Args....: $1 - PARAMETER_1_DESCRIPTION
#          $2 - PARAMETER_2_DESCRIPTION (optional)
# Returns.: 0 on success, 1 on error
# Output..: WHAT_IT_OUTPUTS
# Notes...: ADDITIONAL_CONTEXT (optional)
# ------------------------------------------------------------------------------
```

---

## Quality Checks

Before committing header updates:

1. **Shellcheck:** Ensure no syntax errors introduced
2. **Lint:** Run `make lint` to verify formatting
3. **Tests:** Run `make test` to ensure no behavioral changes
4. **Consistency:** Verify alignment of periods after keywords
5. **Completeness:** All required fields present (Function, Purpose, Args, Returns)

---

## Success Criteria

- ✅ All public functions have standardized headers
- ✅ All parameters documented with types and optionality
- ✅ Return codes clearly documented
- ✅ Output behavior described
- ✅ Special cases noted in Notes section
- ✅ Consistent formatting across codebase

---

## References

- Phase 1-3 libraries serve as reference implementations
- See `src/lib/oradba_env_parser.sh` for excellent examples
- Current functions with good headers:
  - `oradba_parse_oratab()` (oradba_env_parser.sh:28)
  - `oradba_parse_homes()` (oradba_env_parser.sh:67)
  - `oradba_get_file_signature()` (oradba_env_changes.sh:20)

---

## Progress Tracking

### Completed

- ✅ Phase 1-3 libraries (6 files, ~50 functions)
- ✅ Test requirements documentation
- ✅ init_session_log() header added

### In Progress

- ⏳ oradba_common.sh high-priority functions

### Pending

- ⏳ oradba_common.sh remaining functions
- ⏳ oradba_aliases.sh, oradba_db_functions.sh, extensions.sh

---

**Note:** This is a living document. Update as progress is made. Function headers
improve code maintainability, help new contributors, and enable better documentation
generation in the future.
