# Smart Test Selection

## Overview

OraDBA implements smart test selection to reduce test execution time during development. Instead of running
all 492 tests on every change, only tests affected by your changes are executed.

## How It Works

### Test Mapping

The `.testmap.yml` file defines:

- **Always Run Tests**: Core tests that always execute (installer, version, oraenv)
- **Source-to-Test Mappings**: Which test files run when specific source files change
- **Pattern Matching**: Flexible patterns for common scenarios

### Change Detection

- **Local Development**: Uses `git diff` against `origin/main`
- **CI/GitHub Actions**: Uses `dorny/paths-filter` for change detection
- **Fallback**: Runs all tests if changes can't be determined

## Usage

### Local Development

```bash
# Smart selection (default) - runs only affected tests
make test

# Show what would run without executing
make test DRY_RUN=1

# Run all tests (no smart selection)
make test-full

# Pre-commit checks (smart tests + linting)
make pre-commit

# Full CI pipeline (all tests + docs + build)
make ci
```

### Examples

**Scenario 1**: You modify `src/lib/common.sh`

```bash
$ make test DRY_RUN=1
Would execute 8 test file(s):
- test_installer.bats (always run)
- test_oradba_version.bats (always run)
- test_oraenv.bats (always run)
- test_common.bats (mapped)
- test_aliases.bats (mapped)
- test_db_functions.bats (mapped)
- test_oradba_check.bats (mapped)
- test_service_management.bats (mapped)
```

**Scenario 2**: You modify `src/bin/oradba_dbctl.sh`

```bash
$ make test DRY_RUN=1
Would execute 4 test file(s):
- test_installer.bats (always run)
- test_oradba_version.bats (always run)
- test_oraenv.bats (always run)
- test_service_management.bats (mapped)
```

**Scenario 3**: You modify only documentation or images (`*.md`, `*.png`, `*.excalidraw` files)

```bash
$ make test DRY_RUN=1
Would execute 3 test file(s):
- test_installer.bats (always run)
- test_oradba_version.bats (always run)
- test_oraenv.bats (always run)

# Only always-run tests are executed (no full test fallback)
```

## CI/CD Integration

### Regular Push/PR (Smart Selection)

On every push to `main` or `develop`:

```yaml
# .github/workflows/ci.yml
- Uses smart test selection
- Runs ~5-50 tests typically
- Fast feedback (1-3 minutes)
```

### Release Workflow (Full Tests)

On tag creation (e.g., `v0.10.0`):

```yaml
# .github/workflows/release.yml
- Runs complete test suite (492 tests)
- Ensures release quality
- Takes ~5-10 minutes
```

## Configuring Test Mappings

Edit `.testmap.yml` to adjust mappings:

```yaml
# Add new mapping
mappings:
  src/bin/my_new_script.sh:
    - test_my_new_script.bats

# Add to always-run tests
always_run:
  - test_installer.bats
  - test_oradba_version.bats
  - test_oraenv.bats
  - test_my_critical_feature.bats  # Add here

# Add pattern matching
patterns:
  - pattern: "^src/sql/.*\\.sql$"
    tests:
      - test_sql_scripts.bats  # When we add SQL tests
```

## Benefits

### Speed Improvements

| Scenario             | Old Behavior       | New Behavior       | Time Saved           |
|----------------------|--------------------|--------------------|----------------------|
| Change 1 script      | 492 tests (~8 min) | ~10 tests (~1 min) | 7 minutes            |
| Change lib/common.sh | 492 tests (~8 min) | ~50 tests (~2 min) | 6 minutes            |
| Documentation only   | 492 tests (~8 min) | 3 tests (~30 sec)  | 7.5 minutes          |
| Full CI/Release      | 492 tests (~8 min) | 492 tests (~8 min) | No change (intended) |

### Developer Experience

- **Faster feedback**: See results in 1-3 minutes instead of 8-10
- **Context retention**: Stay focused during quick iteration
- **Confidence**: Full test suite still runs on release
- **Transparency**: `DRY_RUN=1` shows exactly what will run

## Troubleshooting

### No Changes Detected

If you see "No changed files detected", the system falls back to full tests:

```bash
[WARN] No changed files detected
[WARN] Running full test suite as fallback
```

**Causes:**

- Fresh clone (no git history)
- Comparing against non-existent branch
- All changes already committed and pushed

**Solutions:**

- Run `make test-full` explicitly
- Check that `origin/main` exists: `git fetch origin`
- Use `--base HEAD~1` for last commit comparison

### Test Not Running

If a test you expect isn't running:

1. Check mapping in `.testmap.yml`
2. Run with verbose output:

   ```bash
   ./scripts/select_tests.sh --verbose --dry-run
   ```

3. Verify test file exists in `tests/` directory
4. Check pattern matching rules

### Force Full Test Run

If smart selection is causing issues:

```bash
# Always run all tests
make test-full

# Or set environment variable
FULL=1 make test

# In CI, use the full test job
```

## Technical Details

### Script: `scripts/select_tests.sh`

- Written in Bash for portability
- Parses YAML config (simplified parsing)
- Handles git operations gracefully
- Returns sorted, unique test list

### Makefile Integration

- `test`: Smart selection (default)
- `test-full`: All tests
- `ci`: Full tests + docs + build
- `pre-commit`: Smart tests + lint

### GitHub Actions

- Uses existing `dorny/paths-filter` for change detection
- Falls back to full suite if selection fails
- Groups output for readability
- Preserves test exit codes

## Future Enhancements

Potential improvements:

- [ ] Cache test results to skip passing tests
- [ ] Parallel test execution for large selections
- [ ] More sophisticated YAML parsing (use `yq` if available)
- [ ] Test coverage integration
- [ ] Performance profiling per test file
- [ ] Auto-generate mappings from `source` statements

## See Also

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [Development Guide](../doc/development.md) - Developer workflow
- [Makefile](../Makefile) - Available make targets
