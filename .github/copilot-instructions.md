# GitHub Copilot Instructions for OraDBA

## Project Overview

OraDBA is a comprehensive Oracle Database administration toolkit for Unix/Linux environments. It provides environment management, automation tools, and integration with Oracle products including Database, Data Safe On-Premises Connectors, Instant Client, OUD, WebLogic, and EM.

## Code Quality Standards

### Shell Scripting

- **Always use**: `#!/usr/bin/env bash` (never `#!/bin/sh`)
- **ShellCheck compliance**: All code must pass `make lint` with no warnings
- **SC2155 warnings**: Declare and assign separately to avoid masking return values
  ```bash
  # Bad
  local result="$(command)"
  
  # Good
  local result
  result="$(command)"
  ```
- **Error handling**: Use `|| return 1` for critical operations
- **Quote variables**: Always quote variables: `"${variable}"` not `$variable`
- **Array handling**: Use proper bash arrays, not space-separated strings

### Naming Conventions

- **Functions**: Use `oradba_` prefix for public functions (e.g., `oradba_dedupe_path`)
- **Internal functions**: Use descriptive names without prefix (e.g., `validate_home_path`)
- **Configuration variables**: Use `ORADBA_` prefix (e.g., `ORADBA_SHOW_DUMMY_ENTRIES`)
- **Environment variables**: Follow Oracle conventions (e.g., `ORACLE_HOME`, `ORACLE_SID`)

## Project Structure

```
oradba/
├── src/
│   ├── bin/          # Executable scripts (oradba_*.sh, oraup.sh, etc.)
│   ├── lib/          # Library functions (oradba_common.sh, etc.)
│   ├── etc/          # Configuration files (oradba_core.conf, etc.)
│   ├── sql/          # SQL scripts
│   └── doc/          # User documentation
├── tests/            # BATS test files (test_*.bats)
├── doc/              # Developer documentation
│   └── releases/     # Release notes
├── scripts/          # Build and utility scripts
└── templates/        # Template files

```

## Key Architectural Patterns

### Product Type Detection

1. **Always check config first**: Use `get_oracle_home_type()` to read from `oradba_homes.conf`
2. **Filesystem fallback**: Use `detect_product_type()` if not in config
3. **Pattern**:
   ```bash
   if product_type=$(get_oracle_home_type "${name}" 2>/dev/null) && [[ -n "${product_type}" ]] && [[ "${product_type}" != "unknown" ]]; then
       # Use config type
       :
   else
       # Fallback to filesystem detection
       product_type=$(detect_product_type "${oracle_home}")
   fi
   ```

### PATH Management

- **Deduplication**: Always deduplicate PATH after modifications
- **Single source of truth**: Use `oradba_dedupe_path()` function
- **Final cleanup**: Run deduplication after loading all config files
- **Validation**: Check directory existence before adding to PATH

### Configuration Loading Order

1. `oradba_core.conf` - Core system settings (read-only)
2. `oradba_standard.conf` - Standard defaults
3. `oradba_local.conf` - Site-specific (optional)
4. `oradba_customer.conf` - User customizations (recommended)
5. `sid.<SID>.conf` - SID-specific overrides (optional)

### Supported Product Types

- `database` - Oracle Database (RDBMS)
- `client` - Oracle Full Client
- `iclient` - Oracle Instant Client
- `datasafe` - Oracle Data Safe On-Premises Connector
- `oud` - Oracle Unified Directory
- `weblogic` - WebLogic Server
- `grid` - Grid Infrastructure
- `oms` - Enterprise Manager OMS
- `emagent` - Enterprise Manager Agent

## Development Workflow

### Making Changes

1. **Test locally**: Run relevant tests with `bats tests/test_*.bats`
2. **Lint code**: Run `make lint` before committing
3. **Update tests**: Add/update tests for new functionality
4. **Update docs**: Keep CHANGELOG.md and release notes in sync
5. **Commit messages**: Use conventional commits format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for code refactoring
   - `test:` for test updates

### Testing

- **Unit tests**: Located in `tests/test_*.bats`
- **Run specific test**: `bats tests/test_file.bats -f "test name"`
- **Run optimzed tests**: `make test` Run smart test selection (only tests affected by changes). Dependency is configured in `.testmap.yml`
- **Run all tests**: `make test-full` or `bats tests/`
- **Test coverage**: Aim for high coverage of critical functions

### Documentation

- **User docs**: Update `src/doc/*.md` for user-facing changes
- **Release notes**: Update `doc/releases/v*.md` for releases
- **CHANGELOG**: Keep `CHANGELOG.md` current with all changes
- **Function headers**: Document all functions with purpose, args, returns, output

## Common Patterns

### Function Documentation

```bash
# ------------------------------------------------------------------------------
# Function: function_name
# Purpose.: Brief description of what the function does
# Args....: $1 - Description of first argument
#           $2 - Description of second argument (optional)
# Returns.: 0 on success, 1 on error
# Output..: Description of what gets printed to stdout
# Notes...: Additional context, usage examples, or warnings
# ------------------------------------------------------------------------------
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"
    
    # Function implementation
}
```

### Configuration Variables

```bash
# Variable description (what it controls)
# Default: value (backward compatible)
# Set to false/true to enable/disable feature
export ORADBA_FEATURE_NAME="${ORADBA_FEATURE_NAME:-true}"
```

### Error Handling

```bash
# Check required conditions
[[ -z "${required_var}" ]] && return 1
[[ ! -d "${required_dir}" ]] && return 1

# Validate input
if ! validate_input "$arg"; then
    log_error "Invalid input: $arg"
    return 1
fi

# Handle command failures
if ! critical_command; then
    log_error "Command failed"
    return 1
fi
```

### Duplicate Prevention

When adding entries to configuration files:
1. Check if NAME already exists
2. Check if PATH already exists
3. Provide clear error messages
4. Offer cleanup commands

### Version Detection

1. Try installed location: `bin/../VERSION`
2. Try repository location: `src/bin/../../VERSION`
3. Fallback to hardcoded version
4. Always handle file-not-found gracefully

## DataSafe Specific Patterns

- **PATH**: Use `oracle_cman_home/bin` not just `bin`
- **LD_LIBRARY_PATH**: Use `oracle_cman_home/lib`
- **Status check**: Use `cmctl status` directly (fast)
- **Version**: Show as "N/A" (no sqlplus available)
- **Validation**: Skip sqlplus checks

## Instant Client Specific Patterns

- **PATH**: Add `ORACLE_HOME` directly (no bin subdirectory)
- **LD_LIBRARY_PATH**: Add `ORACLE_HOME` directly
- **Detection**: Check for `libclntsh.so` and absence of `bin/` directory
- **Validation**: Skip database-specific checks

## Backward Compatibility

- Always maintain backward compatibility for configuration variables
- Support old field names in parsing functions
- Provide fallbacks for missing features
- Document breaking changes clearly in release notes

## Performance Considerations

- Minimize subprocess calls (fork overhead)
- Use bash built-ins when possible
- Cache results of expensive operations
- Direct status checks (avoid Python/wrapper overhead)

## Anti-Patterns to Avoid

- ❌ Hardcoded paths (use configuration variables)
- ❌ Assuming Oracle Database is always installed
- ❌ Using `sed -i` directly (platform differences)
- ❌ Exporting functions unnecessarily (pollutes environment)
- ❌ Duplicate code (create shared functions)
- ❌ Silent failures (always log errors)
- ❌ Assuming product types from home names

## Release Process

1. Update VERSION file
2. Update CHANGELOG.md with all changes
3. Update release notes in `doc/releases/v*.md`
4. Run smart test suite: `make test`
5. Optional run full test suite: `make test-full`
6. Run linting: `make lint`
7. Commit changes with descriptive message
8. Create annotated git tag: `git tag -a vX.Y.Z -m "Release message"`
9. Push commits and tags: `git push origin main && git push origin vX.Y.Z`

## When Generating Code

- Follow existing patterns in similar functions
- Use consistent indentation (4 spaces for bash)
- Add appropriate error handling
- Include function documentation header
- Consider backward compatibility
- Add test cases for new functionality
- Update relevant documentation

## Integration Points

- **oratab**: Central registry for database SIDs
- **oradba_homes.conf**: Registry for non-database Oracle Homes
- **Extensions**: Auto-discovered from `${ORADBA_LOCAL_BASE}/*/bin/*.sh`
- **Configuration hierarchy**: Core → Standard → Local → Customer → SID
- **Environment switching**: Single source for SID or Home name

## Security Considerations

- Sanitize user input
- Validate paths before use
- Use secure defaults
- Avoid password leakage in logs
- Use rlwrap filters for sensitive commands (sqlplus, rman)

## Debugging

- Use `ORADBA_DEBUG=true` for verbose output
- Check `${ORADBA_LOG}` for log files
- Run with `bash -x` for execution trace
- Use `oradba_log DEBUG "message"` for debug output
