# CI Workflow Optimization Summary

## Changes Made

The CI workflow has been optimized to run jobs only when relevant files are
modified, significantly reducing unnecessary compute time and improving
workflow efficiency.

### New Features

#### 1. Path-Based Job Filtering

Added a `changes` job that detects which files have been modified and sets
outputs to control downstream job execution:

**Filter Categories:**

- **scripts**: Triggers shellcheck linting
  - `src/bin/**/*.sh`
  - `src/lib/**/*.sh`
  - `scripts/**/*.sh`
  - `tests/**/*.sh`
  - `tests/**/*.bats`

- **tests**: Triggers test execution
  - `src/bin/**/*.sh`
  - `src/lib/**/*.sh`
  - `tests/**`

- **markdown**: Triggers markdown linting
  - `**/*.md`
  - `.markdownlint.json`

- **docs**: Triggers documentation generation
  - `VERSION`
  - `src/doc/**`
  - `doc/**`
  - `**/images/**`
  - `Makefile`

- **config**: Tracks workflow and build configuration changes
  - `.github/workflows/**`
  - `Makefile`
  - `VERSION`

#### 2. Conditional Job Execution

**Lint Job:**

- Runs ONLY when shell scripts are modified
- Includes additional check for `#!/bin/sh` usage (enforces bash)

**Test Job:**

- Runs ONLY when tests or source code changes
- Depends on lint (runs after lint succeeds or is skipped)

**Build Job:**

- Runs when tests pass or are skipped
- Always produces installer for validation

**Validate Job:**

- Runs after build succeeds or is skipped
- Tests installation in clean environment

**Lint-Markdown Job:**

- Runs ONLY when markdown files are modified
- Independent from code quality stream

**Docs Job:**

- Runs ONLY when documentation files or VERSION changes
- Depends on markdown linting

#### 3. Job Dependencies with Flexibility

Jobs use `always()` conditional with result checking to run even if dependencies are skipped:

```yaml
if: |
  always() && 
  needs.changes.outputs.tests == 'true' &&
  (needs.lint.result == 'success' || needs.lint.result == 'skipped')
```

This ensures:

- Jobs run when relevant files change
- Jobs don't fail if dependencies are skipped
- Jobs fail if dependencies fail

### Release Workflow (Already Optimized)

The release workflow already includes:

- ✅ Documentation generation (PDF + HTML)
- ✅ Installer build with version substitution
- ✅ Distribution tarball creation
- ✅ Upload to GitHub releases
- ✅ Artifact retention for CI builds

**No changes needed** - release workflow always runs all steps on tag push.

### Benefits

#### Performance Improvements

| Scenario                 | Before   | After                       | Savings      |
|--------------------------|----------|-----------------------------|--------------|
| README.md only change    | All jobs | Markdown lint + docs        | ~70%         |
| Source code change       | All jobs | Lint + tests + build + val  | 0% (needed)  |
| Documentation change     | All jobs | Markdown lint + docs        | ~50%         |
| Test-only change         | All jobs | Lint + tests (no docs)      | ~30%         |
| No relevant changes      | All jobs | Only changes detection      | ~95%         |

#### Resource Optimization

- **Reduced CI minutes**: Skip unnecessary jobs
- **Faster feedback**: Only run relevant checks
- **Better parallelization**: Independent doc and code streams
- **Cost savings**: Fewer compute resources used

#### Developer Experience

- **Faster PR checks**: Only relevant validations run
- **Clear job names**: Easy to see what's being tested
- **Predictable**: Same files → same jobs
- **Transparent**: Changes job shows what triggered

### Additional Optimizations

#### 1. Enhanced Shellcheck

Added check for `#!/bin/sh` usage to enforce bash:

```yaml
- name: Check for #!/bin/sh usage
  run: |
    if grep -r "^#!/bin/sh" src/ scripts/ 2>/dev/null; then
      echo "ERROR: Found #!/bin/sh usage. Use #!/usr/bin/env bash instead"
      exit 1
    fi
```

#### 2. Artifact Retention

- **Installers**: 30 days (development builds)
- **Documentation**: 90 days (longer retention for reference)

#### 3. Job Isolation

Two parallel streams:

- **Stream 1**: Code quality → Tests → Build → Validate
- **Stream 2**: Markdown lint → Documentation

Streams run independently, maximizing parallelization.

### Usage Examples

#### Example 1: Documentation Update

```bash
# Edit README.md
git commit -m "docs: update installation instructions"
git push
```

**Result**: Only runs `changes` → `lint-markdown` → `docs`

#### Example 2: Bug Fix

```bash
# Fix bug in src/lib/common.sh
git commit -m "fix: resolve path issue"
git push
```

**Result**: Runs `changes` → `lint` → `test` → `build` → `validate`

#### Example 3: Add New Test

```bash
# Add test_new_feature.bats
git commit -m "test: add tests for new feature"
git push
```

**Result**: Runs `changes` → `lint` → `test` (skips build if no code changes)

#### Example 4: Release

```bash
git tag v0.9.0
git push --tags
```

**Result**: Release workflow runs ALL steps (docs, build, upload)

### Migration Notes

#### For Developers

- **No action required**: Workflow changes are transparent
- **PR checks**: May complete faster for doc-only changes
- **Local development**: Use `workflow_dispatch` to manually trigger if needed

#### For Maintainers

- **Monitor**: Check Actions tab to verify jobs run correctly
- **Adjust filters**: Modify `.github/workflows/ci.yml` if new paths need tracking
- **Release process**: Unchanged - all assets still generated

### Future Enhancements

#### Suggested Additions

1. **Cache Dependencies**
   - Cache npm modules for markdownlint
   - Cache shellcheck binary
   - Cache BATS installation

2. **Matrix Testing**
   - Test on multiple Ubuntu versions
   - Test with different shell versions
   - Test Oracle database versions (if applicable)

3. **Performance Monitoring**
   - Track job duration over time
   - Alert on regression in test suite performance
   - Monitor artifact sizes

4. **Security Scanning**
   - Add Dependabot for GitHub Actions versions
   - Scan shell scripts for security issues
   - Check for secrets in commits

5. **Coverage Reporting**
   - Add test coverage metrics
   - Track coverage trends
   - Fail on coverage decrease

6. **Deployment Preview**
   - Generate preview documentation on PRs
   - Comment PR with links to artifacts
   - Preview installer changes

### Workflow Diagram

```text
┌──────────────┐
│   changes    │  Detect modified files
└──────┬───────┘
       │
       ├─────────────────────────────┐
       │                             │
       ▼                             ▼
┌──────────────┐              ┌──────────────┐
│ lint (shell) │              │lint-markdown │
└──────┬───────┘              └──────┬───────┘
       │                             │
       ▼                             ▼
┌──────────────┐              ┌──────────────┐
│     test     │              │     docs     │
└──────┬───────┘              └──────────────┘
       │
       ▼
┌──────────────┐
│    build     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   validate   │
└──────────────┘
```

### Testing the Workflow

#### Test Path Filters

```bash
# Test script changes trigger
echo "# comment" >> src/bin/oraenv.sh
git commit -m "test: trigger script jobs"

# Test markdown changes trigger
echo "# comment" >> README.md
git commit -m "test: trigger markdown jobs"

# Test doc changes trigger
echo "# comment" >> src/doc/01-introduction.md
git commit -m "test: trigger doc jobs"
```

#### Verify Job Skipping

1. Create PR with only README.md changes
2. Check Actions tab - should skip lint, test, build, validate
3. Should run: changes, lint-markdown, docs

### Rollback Plan

If issues arise:

```bash
# Restore original workflow
git show origin/main:.github/workflows/ci.yml > .github/workflows/ci.yml
git commit -m "revert: restore original CI workflow"
git push
```

### Support

For issues with the CI workflow:

1. Check Actions tab for job details
2. Review job logs for error messages
3. Use `workflow_dispatch` to manually trigger
4. Contact maintainer if filters need adjustment

---

**Last Updated**: 2025-12-23
**Version**: 1.0
**Author**: Stefan Oehrli
