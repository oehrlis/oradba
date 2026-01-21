# Contributing to oradba

Thank you for your interest in contributing to oradba! This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors:

- **Be respectful and inclusive**: Treat all contributors with respect, regardless of their background, experience level, or perspective
- **Focus on constructive feedback**: Provide helpful, actionable feedback that improves the project
- **Help create a welcoming environment**: Be patient with newcomers and help them understand our processes
- **Collaborate openly**: Share knowledge, ask questions, and work together to solve problems
- **Assume good intentions**: Approach disagreements with empathy and understanding

Unacceptable behavior includes harassment, discriminatory language, personal attacks, or any conduct that creates an unwelcoming environment.

### Security Reporting

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email security concerns to: stefan.oehrli@oradba.ch
3. Include detailed information about the vulnerability
4. Allow reasonable time for a fix before public disclosure

We take security seriously and will respond promptly to valid reports.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Oracle version, etc.)

### Suggesting Features

1. Check if the feature has been requested in Issues
2. Create a new issue with:
   - Clear description of the feature
   - Use case and benefits
   - Possible implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch following the naming convention below
3. Make your changes following the coding standards below
4. Add or update tests as needed
5. Update documentation as needed
6. Commit with clear messages following conventional commits format
7. Push to your fork
8. Open a Pull Request with a clear description

## Git Workflow and Branch Strategy

### Branch Naming Convention

Use descriptive branch names that include the issue number and a brief description:

- **Features**: `feat/issue-XX-description`
  - Example: `feat/issue-92-developer-docs`
- **Bug fixes**: `fix/issue-XX-description`
  - Example: `fix/issue-85-path-deduplication`
- **Documentation**: `docs/issue-XX-description`
  - Example: `docs/issue-89-api-reference`
- **Refactoring**: `refactor/issue-XX-description`
  - Example: `refactor/issue-78-plugin-system`

### Branch Structure

- **Main branch**: `main` - Production-ready code, protected
- **Feature branches**: Created from `main`, merged back to `main`
- **No develop branch**: We use direct merging to `main` with CI validation

### Merge Strategy

- **Merge commits**: We use merge commits to preserve the full history
- **No force push**: Never force push to shared branches
- **No rebase**: Avoid rebasing after pushing to maintain history

### Pull Request Process

Before submitting your PR, complete the following checklist:

#### Pre-Submission Checklist

- [ ] All tests pass: `make test` (smart tests) or `make test-full` (complete suite)
- [ ] All linting passes: `make lint`
- [ ] Function headers are complete (Purpose, Args, Returns, Output)
- [ ] Developer documentation updated (if architectural changes)
- [ ] User documentation updated (if user-facing changes)
- [ ] CHANGELOG.md updated with your changes
- [ ] Backward compatibility maintained (from v0.19.0+)
- [ ] New functionality includes tests
- [ ] Commit messages follow conventional commits format

#### Review Process

1. Automated checks must pass (CI/CD pipeline)
2. Code review by maintainer
3. Discussion and iteration as needed
4. Approval and merge by maintainer

See [doc/development-workflow.md](doc/development-workflow.md) for detailed development workflow.

## Development Setup

### Prerequisites

- Bash 4.0+
- BATS for testing
- shellcheck for linting
- Oracle Database (for testing database-specific features)

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/oehrlis/oradba.git
cd oradba

# Run tests
./tests/run_tests.sh

# Build installer
./scripts/build_installer.sh
```

## Coding Standards

### Bash Scripts

Follow these essential rules for all shell scripts:

#### Shebang and Basic Rules

- **Always use**: `#!/usr/bin/env bash` (never `#!/bin/sh`)
- **Strict mode**: Consider enabling for critical scripts:

  ```bash
  set -e          # Exit on error
  set -u          # Exit on undefined variable
  set -o pipefail # Exit on pipe failure
  ```

- **ShellCheck compliance**: All code must pass `make lint` with no warnings
- **Quote variables**: Always quote variables: `"${variable}"` not `$variable`

#### Common Patterns

**SC2155 warnings** - Declare and assign separately to avoid masking return values:

```bash
# Bad - masks function return value
local result="$(command)"

# Good - preserves return value
local result
result="$(command)"
```

**Error handling**:

```bash
# Check critical operations
if ! critical_command; then
    oradba_log ERROR "Command failed"
    return 1
fi

# Or use short form for simple checks
command || return 1
```

**Array handling** - Use proper bash arrays, not space-separated strings:

```bash
# Good - proper array
local -a paths=()
paths+=("${path}")

# Bad - string concatenation
local paths=""
paths="${paths} ${path}"
```

#### Naming Conventions

- **Public functions**: Use `oradba_` prefix (e.g., `oradba_dedupe_path`)
- **Internal functions**: Use descriptive names without prefix (e.g., `validate_home_path`)
- **Configuration variables**: Use `ORADBA_` prefix (e.g., `ORADBA_SHOW_DUMMY_ENTRIES`)
- **Environment variables**: Follow Oracle conventions (e.g., `ORACLE_HOME`, `ORACLE_SID`)

#### Function Documentation

All functions must have a complete header with Purpose, Args, Returns, and Output.
See [doc/function-header-guide.md](doc/function-header-guide.md) for detailed guidelines.

Example:

```bash
# ------------------------------------------------------------------------------
# Function: oradba_dedupe_path
# Purpose.: Remove duplicate entries from PATH-like variables
# Args....: $1 - Path string (colon-separated)
# Returns.: 0 on success, 1 on error
# Output..: Deduplicated path string
# ------------------------------------------------------------------------------
oradba_dedupe_path() {
    local input_path="$1"
    # Function implementation
}
```

### Script Structure

```bash
#!/usr/bin/env bash
# Script description
# Copyright notice

# Constants
CONST_NAME="value"

# Functions
function_name() {
    local var="value"
    # Function body
}

# Main execution
main() {
    # Main logic
}

main "$@"
```

### Documentation

- **Update README.md** for user-facing changes
- **Update CHANGELOG.md** following [Keep a Changelog](https://keepachangelog.com/) format
- **Add inline comments** for complex logic
- **Function headers**: All functions must have complete headers with Purpose, Args, Returns, Output
  - See [doc/function-header-guide.md](doc/function-header-guide.md) for standards
- **Update help text** for user-facing commands
- **Cross-reference documentation**: Ensure all links work correctly

### Testing

OraDBA has two complementary test frameworks:

#### BATS Tests (Unit & Functional)

- Add BATS tests for new functionality in `tests/test_*.bats`
- Ensure all tests pass before submitting PR: `make test-full`
- Test on multiple environments when possible
- Include both positive and negative test cases
- Update `.testmap.yml` for smart test selection

**Run tests**:

```bash
make test        # Smart selection (fast, ~1-3 min)
make test-full   # All 1086 tests (~10 min)
bats tests/test_file.bats  # Specific file
```

#### Docker Integration Tests (Manual)

For changes affecting database operations, listener control, or RMAN:

1. **Test locally** with Docker:

   ```bash
   docker run -it --rm -v $PWD:/oradba \
     container-registry.oracle.com/database/free:latest \
     bash -c "cd /oradba && bash tests/docker_automated_tests.sh"
   ```

2. **Or trigger GitHub Actions workflow**:
   - Go to: Actions → Docker Integration Tests → Run workflow
   - Wait ~20-40 minutes for results
   - Download test results artifact

**When to run Docker tests**:

- Before major releases (v0.x.0)
- After database control changes (`oradba_dbctl.sh`, `oradba_lsnrctl.sh`)
- After RMAN script modifications
- After service management changes
- When troubleshooting integration issues

See [tests/README.md](tests/README.md) for detailed test documentation.

### Commit Messages

We recommend following conventional commits format, though it's not strictly enforced:

```text
type(scope): subject

body

footer
```

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test changes
- `refactor`: Code refactoring
- `style`: Code style changes
- `chore`: Maintenance tasks

**Examples**:

```text
feat(oraenv): Add support for Oracle 23c
fix(installer): Handle spaces in installation path
docs(readme): Update installation instructions
test(common): Add tests for logging functions
refactor(plugin): Consolidate DataSafe logic
```

**Best practices**:

- Keep subject line under 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- Reference issue numbers when applicable
- Provide context in the body for complex changes

## Release Process (For Maintainers)

This section is for project maintainers who create releases.

### Pre-Release Testing

1. **Manual testing**: Test critical functionality on target environments
2. **Full test suite**: Run `make test-full` or `make ci` (~10 minutes)
3. **Docker integration tests**: Run against real Oracle databases if changes affect DB operations
4. **Verify all CI checks pass** on the main branch

### Version Management

OraDBA follows [Semantic Versioning](https://semver.org/):

- **Major version (X.0.0)**: Breaking changes
- **Minor version (0.X.0)**: New features, backward compatible
- **Patch version (0.0.X)**: Bug fixes, backward compatible

### Release Steps

1. **Update VERSION file**:

   ```bash
   echo "0.19.2" > VERSION
   ```

2. **Update CHANGELOG.md**:
   - Move items from `[Unreleased]` to new version section
   - Add release date
   - Follow [Keep a Changelog](https://keepachangelog.com/) format

3. **Create release notes**: Update `doc/releases/vX.Y.Z.md`
   - This file is consumed by the GitHub Actions release workflow
   - Include highlights, breaking changes, new features, bug fixes
   - Use template from previous releases

4. **Commit changes**:

   ```bash
   git add VERSION CHANGELOG.md doc/releases/vX.Y.Z.md
   git commit -m "chore: prepare release vX.Y.Z"
   git push origin main
   ```

5. **Verify CI passes** on main branch

6. **Create and push annotated tag**:

   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin main --tags
   ```

### Automated Release Process

Once the tag is pushed, GitHub Actions automatically:

1. Builds the installer with embedded tarball
2. Creates GitHub release with release notes
3. Uploads build artifacts
4. Deploys documentation site (via separate workflow)

### Post-Release Tasks

1. **Update extension repositories** (if needed):
   - Update any dependent extension projects
   - Ensure compatibility with new version

2. **Monitor release**:
   - Check GitHub Actions workflow completion
   - Verify artifacts are uploaded correctly
   - Test download and installation from release page

### Release Checklist

- [ ] All tests pass (`make test-full`)
- [ ] All linting passes (`make lint`)
- [ ] VERSION file updated
- [ ] CHANGELOG.md updated
- [ ] Release notes created in `doc/releases/vX.Y.Z.md`
- [ ] Changes committed and pushed to main
- [ ] CI passes on main branch
- [ ] Annotated tag created and pushed
- [ ] GitHub Actions release workflow completed
- [ ] Artifacts available on release page
- [ ] Documentation site updated
- [ ] Extension repositories updated (if applicable)

### Rollback Procedure

If a release has critical issues:

1. Delete the tag from GitHub and locally:

   ```bash
   git tag -d vX.Y.Z
   git push origin :refs/tags/vX.Y.Z
   ```

2. Delete the GitHub release
3. Fix the issue
4. Create a new patch release (e.g., vX.Y.Z+1)

## Questions?

- Open an issue for questions
- Check existing documentation
- Review closed issues for similar questions

Thank you for contributing to oradba!
