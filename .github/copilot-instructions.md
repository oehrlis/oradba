# GitHub Copilot Instructions for OraDBA

## Project Overview

OraDBA is a comprehensive Oracle Database administration toolkit for Unix/Linux environments. It provides environment management, automation tools, and integration with Oracle products including Database, Data Safe On-Premises Connectors, Instant Client, OUD, Java, WebLogic, and EM.

**Current Version**: v0.19.0  
**Architecture**: Registry API + Plugin System + Environment Management Libraries  
**Test Coverage**: 1086 tests (100% passing)  
**Documentation**: 437 functions (100% documented)  
**Plugin Interface**: v2.0.0 (11 required functions per plugin)

## Code Quality Standards

### Shell Scripting

- **Always use**: `#!/usr/bin/env bash` (never `#!/bin/sh`)
- **Strict mode**: Consider using for critical scripts:
  ```bash
  set -e  # Exit on error
  set -u  # Exit on undefined variable
  set -o pipefail  # Exit on pipe failure
  ```
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
- `java` - Oracle Java (JDK/JRE)
- `weblogic` - WebLogic Server (planned)
- `grid` - Grid Infrastructure (future)
- `oms` - Enterprise Manager OMS (future)
- `emagent` - Enterprise Manager Agent (future)

## Architecture Deep Dive (v0.19.0+)

### Registry API

The Registry API provides unified access to Oracle installations via `src/lib/oradba_registry.sh`:

**Core Functions**:
- `get_all_installations()` - List all Oracle Homes (oratab + oradba_homes.conf)
- `get_installation_by_name()` - Get specific installation metadata
- `get_installations_by_type()` - Filter by product type (database, client, etc.)
- `get_database_installations()` - Get only database entries from oratab

**Registry Sources**:
1. `/etc/oratab` or `/var/opt/oracle/oratab` - Database installations (SID-based)
2. `${ORADBA_BASE}/etc/oradba_homes.conf` - Non-database Oracle Homes (product-based)

**Output Format**: Pipe-delimited fields
```
NAME|TYPE|ORACLE_HOME|VERSION|EDITION|AUTOSTART|DESCRIPTION
```

### Plugin System (Interface v1.0.0)

Each plugin implements 11 required functions defined in `src/lib/plugins/plugin_interface.sh`.

> **📖 Complete Specification**: See [doc/plugin-standards.md](../doc/plugin-standards.md) for:
> - Official plugin interface v1.0.0 specification
> - Exit code standards and return value conventions  
> - Function templates for all 11 required functions
> - Subshell execution model and Oracle environment requirements
> - Testing requirements and best practices

**Required Metadata**:
```bash
export plugin_name="database"          # Product identifier
export plugin_version="1.0.0"          # Plugin version
export plugin_description="Description" # Human-readable description
```

**Required Functions** (11):
1. `plugin_detect_installation()` - Auto-detect product installations
2. `plugin_validate_home()` - Validate ORACLE_HOME path
3. `plugin_adjust_environment()` - Adjust path for product (e.g., append /bin)
4. `plugin_check_status()` - Check if product is available
5. `plugin_get_metadata()` - Get product metadata (version, edition, etc.)
6. `plugin_should_show_listener()` - Whether to display listener status
7. `plugin_discover_instances()` - Find product instances (databases, OUD instances)
8. `plugin_supports_aliases()` - Support SID aliases?
9. `plugin_build_path()` - Build PATH components
10. `plugin_build_lib_path()` - Build LD_LIBRARY_PATH components
11. `plugin_get_config_section()` - Get config section name

**Current Plugins** (6):
- `database_plugin.sh` - Oracle Database (CDB/PDB support)
- `datasafe_plugin.sh` - Data Safe On-Premises Connector
- `client_plugin.sh` - Full Oracle Client
- `iclient_plugin.sh` - Instant Client
- `oud_plugin.sh` - Oracle Unified Directory
- `java_plugin.sh` - Oracle Java (JDK/JRE detection)

### Plugin Standards Compliance

**All plugin development must follow [doc/plugin-standards.md](../doc/plugin-standards.md):**

- **11 required functions** - No exceptions, implement all
- **Exit code contract** - 0=success, 1=N/A, 2=error
- **No sentinel strings** - Never echo "ERR", "unknown", "N/A" on stdout
- **Subshell isolation** - Plugins execute in isolated subshells
- **Oracle environment** - ORACLE_HOME and LD_LIBRARY_PATH guaranteed available
- **Function headers** - Document all functions (Purpose, Args, Returns, Output)

**When implementing/reviewing plugin code:**
1. ✅ Check exit codes match specification (0/1/2)
2. ✅ Verify stdout contains only clean data (no error strings)
3. ✅ Confirm all 11 required functions implemented
4. ✅ Ensure Oracle environment assumptions are documented
5. ✅ Add comprehensive tests for all plugin functions

**Quick Exit Code Reference:**
- Return 0 with clean data = Success
- Return 1 with no/empty data = Not Applicable (expected)
- Return 2 with no data = Error/Unavailable (failure)

**See**: [Plugin Standards](../doc/plugin-standards.md) and [Plugin Development Guide](../doc/plugin-development.md)

### Environment Management Libraries

Six specialized libraries in `src/lib/`:

1. **oradba_env_parser.sh** - Parse oratab and oradba_homes.conf
2. **oradba_env_builder.sh** - Build environment variables (PATH, LD_LIBRARY_PATH, etc.)
3. **oradba_env_validator.sh** - Validate Oracle environment setup
4. **oradba_env_config.sh** - Manage configuration files
5. **oradba_env_status.sh** - Display environment status
6. **oradba_env_changes.sh** - Detect and highlight environment changes

### Oracle Homes Management

**oradba_homes.conf Format**:
```properties
# NAME:TYPE:ORACLE_HOME:VERSION:EDITION:DESCRIPTION
cman01:datasafe:/u01/app/oracle/cman01:N/A:N/A:Data Safe Connector
jdk17:java:/u01/app/oracle/product/jdk-17:17.0.1:JDK:Java Development Kit
```

**Fields**:
- **NAME**: Unique identifier (used for environment switching)
- **TYPE**: Product type (database, datasafe, client, iclient, oud, java, weblogic)
- **ORACLE_HOME**: Installation path
- **VERSION**: Product version (from oracle binary or "N/A")
- **EDITION**: Edition (EE, SE2, PE, JDK, JRE, "N/A")
- **DESCRIPTION**: Human-readable description

## Development Workflow

### Branch Strategy & Commits

**Branch Naming**:
- Features: `feat/issue-XX-description` (e.g., `feat/issue-89-api-reference`)
- Bug fixes: `fix/issue-XX-description` (e.g., `fix/issue-85-path-issue`)
- Main branch: `main` (no develop branch)
- Merge strategy: Merge commits

**Commit Messages**:
- Conventional commits **recommended** (not strict)
- Format: `type: description` (e.g., `feat: add API reference generation`)
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

**Example Workflow**:
```bash
# Create feature branch
git checkout -b feat/issue-92-developer-docs

# Make changes, test locally
make test
make lint

# Commit changes
git add .
git commit -m "docs: add developer documentation guide"

# Push and create PR
git push origin feat/issue-92-developer-docs
```

### Pull Request Checklist

Before submitting PR, ensure:
- ✅ All tests pass (`make test`)
- ✅ All linting passes (`make lint`)
- ✅ Developer documentation updated (if applicable)
- ✅ User documentation updated (if user-facing changes)
- ✅ CHANGELOG.md updated
- ✅ Function headers complete (Purpose, Args, Returns, Output)
- ✅ Backward compatibility maintained (from v0.19.0+)

### Release Process (Maintainer Reference)

**Version Management**:
1. Manual testing by maintainer
2. Update VERSION file (semantic versioning)
3. Update CHANGELOG.md with release notes
4. Update `doc/releases/vX.Y.Z.md` (consumed by release workflow)

**Tag & Release**:
```bash
# Create annotated tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin main --tags
```

**Automated Steps** (via GitHub Actions):
- Build artifacts created by release workflow
- Documentation site deployed by doc workflow
- GitHub release created automatically

**Manual Steps**:
- Update extension repositories (if needed)
- No announcements required

### Making Changes

1. **Test locally**: Run relevant tests with `bats tests/test_*.bats` or `make test`
2. **Lint code**: Run `make lint` (all linters) or `make lint-shell`/`make lint-markdown` before committing
3. **Update tests**: Add/update tests for new functionality
4. **Update docs**: Keep CHANGELOG.md and release notes in sync
5. **Commit messages**: Use conventional commits format (recommended):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for code refactoring
   - `test:` for test updates

### Testing

OraDBA has comprehensive test coverage with BATS unit/integration tests and Docker-based tests against real Oracle databases.

- **Smart test selection**: `make test` - Runs only affected tests (~1-3 min)
- **Full test suite**: `make test-full` - All BATS tests (~10 min, use before releases)
- **Pre-commit checks**: `make pre-commit` - Smart tests + linting (~2-4 min)
- **Full CI pipeline**: `make ci` - Full tests + docs + build (~10-15 min, use sparingly)
- **Docker integration**: `make test-docker` - Real Oracle DB tests (~3 min)
- **Specific test**: `bats tests/test_file.bats -f "test name"`
- **Test mapping**: Edit `.testmap.yml` to map source files to test files
- **Test coverage**: Aim for high coverage of critical functions

**Performance Optimization**: When analyzing test results, save output to a log file first to avoid running tests multiple times:
```bash
# Instead of multiple separate runs (each 10-20 min), do this once:
bats tests/test_*.bats > /tmp/test_results.log 2>&1

# Then analyze the log file multiple times:
grep -E "^(ok|not ok)" /tmp/test_results.log | tail -30   # Failed tests
tail -3 /tmp/test_results.log                             # Summary
grep -E "^[0-9]+ tests," /tmp/test_results.log            # Test count
```
This prevents the test suite from running 3x when session crashes or requires re-analysis.

### Documentation

- **User docs**: Update `src/doc/*.md` for user-facing changes
- **Developer docs**: Update `doc/*.md` for architecture, development guides
- **Release notes**: Update `doc/releases/v*.md` for releases
- **CHANGELOG**: Keep `CHANGELOG.md` current with all changes
- **Function headers**: Document all functions with purpose, args, returns, output
- **Alias help**: Update `src/doc/alias_help.txt` when aliases change
- **Templates**: Reuse/adapt templates from `doc/templates/` (header.sh, header.sql, etc.)

### Code Templates

**Function Header Template** (based on `doc/templates/header.sh`):
```bash
# ------------------------------------------------------------------------------
# Function: function_name
# Purpose.: Brief description of what the function does
# Args....: $1 - Description of first argument
#           $2 - Description of second argument (optional)
# Returns.: 0 on success, 1 on error
# Output..: Description of what gets printed to stdout
# Notes...: Additional context, usage examples, or warnings (optional)
# ------------------------------------------------------------------------------
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"
    
    # Function implementation
}
```

**VSCode Snippets** (not in git, document in developer docs):
- Trigger: `orafunc` for function header template
- Location: `.vscode/oradba.code-snippets`
- Include: Function headers, test templates, plugin templates

### Validation Scripts

Update validation/check scripts when project structure or requirements change:

- **Installation checks**: `src/bin/oradba_check.sh` - Update when installation requirements change
- **Installation validation**: `src/bin/oradba_validate.sh` - Update when scripts/libs change (Registry API, plugins, 437 functions)
- **Project structure**: `scripts/validate_project.sh` - Update when project structure changes (src/, lib/plugins/, etc.)
- **Test environment**: `scripts/validate_test_environment.sh` - Update when test structure changes (1086 tests, Docker setup)

## Autonomous Implementation Guidelines

When implementing issues autonomously (especially via Copilot Agent):

### Prerequisites
1. **Read the issue completely** - Understand objectives, tasks, success criteria
2. **Read related documentation** - Check doc/architecture.md, CONTRIBUTING.md, related source files
3. **Analyze existing patterns** - Find similar implementations to follow
4. **Verify test coverage** - Check if tests exist for the area being modified
5. **Check copilot-instructions.md** - Follow project-specific patterns and standards

### Implementation Process
1. **Create branch** - Use descriptive name: `feat/issue-XX-description` or `fix/issue-XX-description`
2. **Read existing code** - Understand current implementation before changing
3. **Follow patterns** - Match existing code style, naming, structure
4. **Document changes** - Update function headers, comments, documentation
5. **Add tests** - Create/update BATS tests for new functionality
6. **Validate** - Run `make test` and `make lint` before committing
7. **Atomic commits** - One logical change per commit with clear messages
8. **Update CHANGELOG** - Add entry describing the change

### Validation Before Completion
- ✅ All tests pass (`make test`)
- ✅ Linting passes (`make lint`)
- ✅ Function headers complete (Purpose, Args, Returns, Output)
- ✅ Documentation updated (if user-facing changes)
- ✅ CHANGELOG.md updated
- ✅ Commit messages follow conventional commits

### When to Ask for Clarification
- Ambiguous requirements or success criteria
- Multiple valid implementation approaches
- Breaking changes that affect backward compatibility
- Design decisions that impact future development
- Missing information about expected behavior

## Common Patterns

### Database Queries (v0.13.2+)

Always use `execute_db_query()` instead of inline sqlplus calls:

```bash
# Good - escape $ in SQL, use execute_db_query()
local query="SELECT name FROM v\$database;"
local db_name
db_name=$(execute_db_query "$query" "raw")

# For pipe-delimited output (extracts first line)
local query="SELECT name || '|' || db_unique_name FROM v\$database;"
local db_info
db_info=$(execute_db_query "$query" "delimited")

# With error handling
if ! result=$(execute_db_query "$query" "raw"); then
    oradba_log ERROR "Failed to query database"
    return 1
fi

# Bad - inline sqlplus (old pattern, avoid)
result=$(sqlplus -s / as sysdba <<EOF
    SELECT name FROM v$database;
EOF
)
```

**Key points:**
- Always escape dollar signs in SQL: `v\$database` not `v$database`
- Use `raw` format for single values or multi-line output
- Use `delimited` format for pipe-separated values (first line only)
- Check return status for error handling

### Logging (v0.13.1+)

Use `oradba_log` function for all logging:

```bash
# Recommended (new syntax)
oradba_log INFO "Database started successfully"
oradba_log WARN "Archive log directory is 90% full"
oradba_log ERROR "Connection to database failed"
oradba_log DEBUG "SQL query: ${sql_query}"

# Configure log level
export ORADBA_LOG_LEVEL=DEBUG  # Show all messages
export ORADBA_LOG_LEVEL=WARN   # Show only WARN and ERROR
```

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
    oradba_log ERROR "Invalid input: $arg"
    return 1
fi

# Handle command failures
if ! critical_command; then
    oradba_log ERROR "Command failed"
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
4. Run smart test suite: `make test` for quick validation
5. **Before release**: Run full test suite: `make test-full` or `make ci` (~10 min)
6. Run linting: `make lint`
7. Commit changes with descriptive message
8. Create annotated git tag: `git tag -a vX.Y.Z -m "Release message"`
9. Push commits and tags: `git push origin main && git push origin vX.Y.Z`

**Note**: Full test suite (`make test-full`/`make ci`) takes ~10 minutes. Use sparingly during development, but always before releases.

## When Generating Code

- Follow existing patterns in similar functions
- Use consistent indentation (4 spaces for bash)
- Add appropriate error handling
- Include function documentation header
- Consider backward compatibility
- Add test cases for new functionality
- Update relevant documentation
- **Always ask clarifying questions** when requirements are unclear
- **Ask before breaking compatibility** - Confirm with user when changes might break existing functionality
- **Avoid hardcoded figures** - Use dynamic detection instead of fixed counts/numbers unless necessary

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

## Temporary Files and Working Documents

Use `.github/.scratch/` for temporary files created during development:
- Issue analysis documents
- Draft implementations  
- AI/Copilot-generated summaries
- Working files that need to be shared between online and local Copilot

This directory is gitignored except for its README.md.
