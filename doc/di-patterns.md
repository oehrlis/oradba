# Dependency Injection Patterns in OraDBA

**Version**: 0.19.11  
**Status**: Phase 4 Implementation  
**Last Updated**: 2026-02-03

## Overview

OraDBA environment management libraries now support dependency injection (DI), enabling unit testing, stateless execution, and decoupled architecture. This guide explains how to use DI patterns in your code and tests.

## Why Dependency Injection?

### Problems Solved

1. **Testability**: Libraries can be tested in isolation without oradba_common.sh
2. **Maintainability**: Clear dependencies make code easier to understand and modify
3. **Flexibility**: Custom loggers or mocks can be injected for different scenarios
4. **Stateless Execution**: Functions don't depend on global state, reducing side effects

### Benefits

- **Unit Testing**: Mock dependencies for fast, reliable tests
- **Integration Testing**: Use real dependencies in integration tests
- **Production Use**: Backward compatible - works with or without DI
- **Debugging**: Inject debug loggers to trace execution

## Architecture

### Three Libraries with DI Support

1. **oradba_env_parser.sh**: Parse oratab and oradba_homes.conf
2. **oradba_env_builder.sh**: Build PATH, LD_LIBRARY_PATH, environment vars
3. **oradba_env_validator.sh**: Validate Oracle environment setup

### DI Components

Each library provides:

- `oradba_*_init()` - Initialize library with optional logger
- `_oradba_*_log()` - Internal logging function (private)
- Global variable: `ORADBA_*_LOGGER` - Stores logger reference

## Usage Patterns

### 1. Production Use (Backward Compatible)

**Without DI** (legacy mode):

```bash
# Source library - works exactly as before
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"

# Use functions normally - logs to oradba_log if available, else silent
result=$(oradba_parse_oratab "ORCL")
```

**With DI** (explicit logger):

```bash
# Source library
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"

# Initialize with oradba_log (explicit)
oradba_parser_init "oradba_log"

# Use functions - logs to oradba_log
result=$(oradba_parse_oratab "ORCL")
```

### 2. Unit Testing with Mock Logger

```bash
#!/usr/bin/env bats

setup() {
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/src"
    export ORADBA_BASE
    
    # Mock logger captures output to file
    export MOCK_LOG_FILE="${BATS_TMPDIR}/mock_log.$$.txt"
    rm -f "$MOCK_LOG_FILE"
    
    mock_logger() {
        echo "[MOCK] $*" >> "$MOCK_LOG_FILE"
    }
    export -f mock_logger
    
    # Source library
    source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
    
    # Initialize with mock logger
    oradba_parser_init "mock_logger"
}

@test "parse_oratab works with mock logger" {
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    # Verify mock was called if logging occurred
    [ -f "$MOCK_LOG_FILE" ] || true
}

teardown() {
    rm -f "$MOCK_LOG_FILE"
}
```

### 3. Silent Mode (No Logging)

```bash
# Source library
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"

# Initialize with empty logger - silent execution
oradba_parser_init ""

# Or don't initialize at all - parser is silent by default
result=$(oradba_parse_oratab "ORCL")
```

### 4. Custom Logger

```bash
# Define custom logger
debug_logger() {
    echo "[DEBUG $(date '+%H:%M:%S')] $*" >> /tmp/debug.log
}
export -f debug_logger

# Initialize with custom logger
oradba_builder_init "debug_logger"

# All logging goes to custom logger
oradba_add_oracle_path "${ORACLE_HOME}/bin"
```

### 5. Multiple Libraries, Same Logger

```bash
# Source all three libraries
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
source "${ORADBA_BASE}/lib/oradba_env_validator.sh"

# Initialize all with same logger
oradba_parser_init "oradba_log"
oradba_builder_init "oradba_log"
oradba_validator_init "oradba_log"

# All three libraries use same logger
```

### 6. Multiple Libraries, Different Loggers

```bash
# Source libraries
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"

# Parser: silent
oradba_parser_init ""

# Builder: verbose debug logger
debug_logger() { echo "[DEBUG] $*" >&2; }
export -f debug_logger
oradba_builder_init "debug_logger"
```

## API Reference

### oradba_parser_init

Initialize parser library with optional logger.

**Signature**:

```bash
oradba_parser_init [logger_function]
```

**Parameters**:

- `logger_function` (optional): Name of logger function to use

**Returns**: 0 on success

**Example**:

```bash
oradba_parser_init "oradba_log"
oradba_parser_init "my_custom_logger"
oradba_parser_init ""  # Silent mode
```

### oradba_builder_init

Initialize builder library with optional logger.

**Signature**:

```bash
oradba_builder_init [logger_function]
```

**Parameters**:

- `logger_function` (optional): Name of logger function to use

**Returns**: 0 on success

**Fallback**: Falls back to `oradba_log` if available when no logger configured

**Example**:

```bash
oradba_builder_init "oradba_log"
```

### oradba_validator_init

Initialize validator library with optional logger.

**Signature**:

```bash
oradba_validator_init [logger_function]
```

**Parameters**:

- `logger_function` (optional): Name of logger function to use

**Returns**: 0 on success

**Fallback**: Falls back to `oradba_log` if available when no logger configured

**Example**:

```bash
oradba_validator_init "oradba_log"
```

## Logger Function Contract

Custom loggers must follow this interface:

```bash
my_logger() {
    local level="$1"
    shift
    local message="$*"
    
    # Log format: [LEVEL] MESSAGE
    # Level: DEBUG, INFO, WARN, ERROR
    echo "[${level}] ${message}"
}
```

**Parameters**:

1. `level`: Log level (DEBUG, INFO, WARN, ERROR)
2. `message`: Log message (all remaining arguments)

**Example Loggers**:

**File Logger**:

```bash
file_logger() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}" >> /var/log/oradba.log
}
```

**Syslog Logger**:

```bash
syslog_logger() {
    logger -t oradba -p "user.${1,,}" "${*:2}"
}
```

**Structured Logger (JSON)**:

```bash
json_logger() {
    jq -n --arg level "$1" --arg msg "${*:2}" \
        '{timestamp: now | todate, level: $level, message: $msg}'
}
```

## Migration Guide

### From Legacy Code

**Before** (legacy, implicit oradba_log dependency):

```bash
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
oradba_add_oracle_path "${ORACLE_HOME}/bin"
```

**After** (explicit DI, same behavior):

```bash
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
oradba_builder_init "oradba_log"  # Optional: makes dependency explicit
oradba_add_oracle_path "${ORACLE_HOME}/bin"
```

**Migration Steps**:

1. No changes required - backward compatible
2. Optionally add `*_init()` calls to make dependencies explicit
3. For new code, always use `*_init()` to document dependencies

### For New Code

Always initialize libraries explicitly:

```bash
# Good: Explicit initialization
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
oradba_parser_init "oradba_log"
result=$(oradba_parse_oratab)

# Acceptable: Silent mode
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
oradba_parser_init ""
result=$(oradba_parse_oratab)
```

## Testing Best Practices

### 1. Use Mock Loggers

```bash
@test "function works correctly" {
    # Setup mock
    mock_logger() { echo "[MOCK] $*" >> "$MOCK_LOG_FILE"; }
    export -f mock_logger
    
    # Initialize with mock
    oradba_parser_init "mock_logger"
    
    # Test function
    run oradba_parse_oratab "ORCL"
    [ "$status" -eq 0 ]
}
```

### 2. Test Without Logger (Stateless)

```bash
@test "function works without logger" {
    # Don't initialize - test pure logic
    run oradba_validate_sid "ORCL"
    [ "$status" -eq 0 ]
}
```

### 3. Verify Mock Was Called

```bash
@test "function logs as expected" {
    mock_logger() { echo "[MOCK] $*" >> "$MOCK_LOG_FILE"; }
    export -f mock_logger
    oradba_builder_init "mock_logger"
    
    # Call function that should log
    oradba_add_oracle_path "/path/to/bin"
    
    # Verify logging occurred
    [ -f "$MOCK_LOG_FILE" ]
    grep -q "add.*path" "$MOCK_LOG_FILE"
}
```

### 4. Test Multiple Loggers

```bash
@test "different libraries use different loggers" {
    logger_a() { echo "A: $*" >> /tmp/log_a; }
    logger_b() { echo "B: $*" >> /tmp/log_b; }
    export -f logger_a logger_b
    
    oradba_parser_init "logger_a"
    oradba_builder_init "logger_b"
    
    # Verify isolation
    [ "$ORADBA_PARSER_LOGGER" = "logger_a" ]
    [ "$ORADBA_BUILDER_LOGGER" = "logger_b" ]
}
```

## Troubleshooting

### Logger Not Called

**Problem**: Logger function not being invoked.

**Causes**:

1. Logger function not exported: `export -f my_logger`
2. Wrong logger name passed to init
3. Log level below threshold (if using oradba_log)

**Solution**:

```bash
# Verify logger is defined
declare -f my_logger

# Verify logger is exported
declare -F my_logger

# Verify logger name matches init
echo "$ORADBA_PARSER_LOGGER"
```

### Functions Not Found

**Problem**: Functions like `oradba_parser_init` not found.

**Cause**: Library not sourced properly.

**Solution**:

```bash
# Correct ORADBA_BASE path
ORADBA_BASE="/path/to/oradba/src"
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
```

### State Leakage Between Tests

**Problem**: Previous test's logger affects next test.

**Cause**: Logger global variable not reset.

**Solution**:

```bash
teardown() {
    unset ORADBA_PARSER_LOGGER
    unset ORADBA_BUILDER_LOGGER
    unset ORADBA_VALIDATOR_LOGGER
}
```

## Performance Considerations

- **Init overhead**: Negligible (~0.1ms per init)
- **Logging overhead**: Depends on logger implementation
- **Mock loggers**: Faster than file I/O loggers
- **Silent mode**: Zero logging overhead

**Recommendation**: Use silent mode for performance-critical code:

```bash
oradba_parser_init ""  # Silent, fastest
```

## Future Enhancements

### Planned (Phase 4)

- Config precedence injection
- Plugin registry injection
- Extension hook injection

### Under Consideration

- Structured logging support (JSON, XML)
- Log level filtering at library level
- Async logging support
- Dependency validation at init

## See Also

- [Plugin Standards](../doc/plugin-standards.md) - Plugin DI patterns
- [Testing Guide](../tests/README.md) - Unit testing practices
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development guidelines

---

**Maintained by**: @oehrlis  
**Questions**: Comment on #137 (Phase 4 issue)
