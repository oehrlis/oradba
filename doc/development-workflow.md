# Development Workflow Guide

This guide provides a comprehensive workflow for OraDBA contributors, covering setup,
development, testing, and debugging processes.

## Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/oradba.git
cd oradba

# 2. View available commands
make help

# 3. Run tests
make test          # Smart test selection (~1-3 min)

# 4. Run linting
make lint          # All linters

# 5. Make changes and test
# ... edit files ...
make test          # Run affected tests
make lint          # Check code quality

# 6. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feat/issue-XX-description
```

## Development Environment Setup

### Prerequisites

#### Required Tools

- **Bash 4.0+**: Core scripting environment
- **Git**: Version control
- **BATS**: Testing framework (`apt install bats` or `brew install bats-core`)
- **shellcheck**: Shell script linter (`apt install shellcheck` or `brew install shellcheck`)

#### Optional Tools

- **markdownlint**: Markdown linting (`npm install -g markdownlint-cli`)
- **shfmt**: Shell script formatter (`brew install shfmt` or download from GitHub)
- **Docker**: Integration testing (`docker.com`)
- **rlwrap**: Command history for SQL*Plus/RMAN

### Installation

```bash
# Install BATS (Ubuntu/Debian)
sudo apt update
sudo apt install bats

# Install shellcheck
sudo apt install shellcheck

# Install markdownlint (requires Node.js)
npm install -g markdownlint-cli

# Install shfmt (optional)
GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

### IDE Setup

#### VSCode (Recommended)

1. **Install extensions**:
   - ShellCheck (`timonwong.shellcheck`)
   - Bash IDE (`mads-hartmann.bash-ide-vscode`)
   - markdownlint (`DavidAnson.vscode-markdownlint`)

2. **Create workspace settings** (`.vscode/settings.json`):

   ```json
   {
     "shellcheck.enable": true,
     "shellcheck.run": "onSave",
     "files.associations": {
       "*.bats": "shellscript"
     },
     "editor.rulers": [80, 100],
     "files.trimTrailingWhitespace": true,
     "files.insertFinalNewline": true
   }
   ```

3. **Add function header snippets** (`.vscode/oradba.code-snippets`):
   - See [function-header-guide.md](function-header-guide.md#vscode-snippets)

#### Vim/Neovim

```vim
" Add to .vimrc or init.vim
" Run shellcheck on save
autocmd BufWritePost *.sh :!shellcheck %

" Set up BATS syntax highlighting
au BufNewFile,BufRead *.bats set filetype=sh

" Set rulers
set colorcolumn=80,100
```

## Development Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch (use issue number)
git checkout -b feat/issue-92-developer-docs

# Or for bug fixes
git checkout -b fix/issue-85-path-issue
```

### 2. Make Changes

Follow these practices:

- **Small commits**: One logical change per commit
- **Test frequently**: Run `make test` after each significant change
- **Lint as you go**: Run `make lint-shell` before committing
- **Update documentation**: Keep docs in sync with code changes

### 3. Testing Strategy

#### Test Selection Decision Tree

```text
What are you working on?

├─ New function/feature
│  └─ → Write BATS unit tests first (TDD)
│      → Run: bats tests/test_yourfile.bats
│
├─ Bug fix
│  └─ → Add BATS test reproducing the bug
│      → Fix the bug
│      → Verify test passes
│      → Run: make test (smart selection)
│
├─ Database operations (SQL, queries, status)
│  └─ → BATS tests for logic
│      → Docker integration tests for DB interaction
│      → Run: make test-docker (if available)
│
├─ Listener/Service control
│  └─ → BATS tests for command construction
│      → Docker integration tests for actual control
│      → Manual testing in test environment
│
├─ Documentation only
│  └─ → No functional tests needed
│      → Run: make lint-markdown
│      → Verify links work
│
└─ Refactoring (no behavior change)
   └─ → Existing tests should still pass
       → Run: make test-full
       → Verify no regressions
```

#### Running Tests

```bash
# Smart test selection (fast, ~1-3 min)
make test

# Run specific test file
bats tests/test_oradba_common.bats

# Run specific test
bats tests/test_oradba_common.bats -f "test_oradba_log"

# Full test suite (~10 min, use before releases)
make test-full

# Docker integration tests (~3 min, if Docker available)
make test-docker

# Pre-commit checks (smart tests + linting, ~2-4 min)
make pre-commit

# Full CI pipeline (use sparingly, ~10-15 min)
make ci
```

#### Test Mapping

OraDBA uses `.testmap.yml` for smart test selection:

```yaml
# Map source files to test files
src/lib/oradba_common.sh:
  - tests/test_oradba_common.bats
  - tests/test_logging.bats

src/lib/plugins/database_plugin.sh:
  - tests/test_database_plugin.bats
  - tests/test_plugin_interface.bats
```

**Update `.testmap.yml`** when adding new files or tests.

### 4. Debugging Techniques

#### Bash Debugging

```bash
# Enable debug output
set -x          # Print commands and arguments as executed
set -v          # Print shell input lines as read

# Or run script with debugging
bash -x src/bin/oraenv.sh

# Conditional debugging
export ORADBA_DEBUG=true
# Check in code:
[[ "${ORADBA_DEBUG}" == "true" ]] && set -x
```

#### Function-Level Debugging

```bash
# Add debug logging to function
function my_function() {
    oradba_log DEBUG "Entering my_function with args: $*"
    oradba_log DEBUG "ORACLE_HOME=${ORACLE_HOME}"
    
    # ... function code ...
    
    oradba_log DEBUG "Exiting my_function with return code $?"
}

# Enable debug logging
export ORADBA_LOG_LEVEL=DEBUG
```

#### BATS Test Debugging

```bash
# Run single test with output
bats tests/test_file.bats -f "test name" --tap

# Print debug output in test
@test "my test" {
    echo "Debug: variable=$variable" >&3
    run my_function
    echo "Output: $output" >&3
    echo "Status: $status" >&3
    [ "$status" -eq 0 ]
}

# Run with verbose output
bats tests/test_file.bats --trace
```

#### Common Issues

**Issue**: Tests fail locally but pass in CI

```bash
# Possible causes:
# 1. Environment differences
env | grep ORADBA    # Check environment variables

# 2. File paths
pwd                  # Verify working directory
ls -la               # Check file permissions

# 3. Dependencies
which bats shellcheck  # Verify tools available
```

**Issue**: Function returns wrong value

```bash
# Add return code logging
function my_function() {
    local result
    result=$(some_command)
    local rc=$?
    oradba_log DEBUG "some_command returned: $rc, output: $result"
    return $rc
}
```

**Issue**: PATH not set correctly

```bash
# Debug PATH issues
echo "PATH before: $PATH"
oradba_add_oracle_path "/path/to/oracle/home"
echo "PATH after: $PATH"

# Check for duplicates
echo "$PATH" | tr ':' '\n' | sort | uniq -d
```

### 5. Code Review Checklist

Before submitting PR:

#### Code Quality

- [ ] All new functions have complete headers
- [ ] Variable names are descriptive
- [ ] Error handling is present
- [ ] shellcheck passes with no warnings
- [ ] No hardcoded paths (use configuration)
- [ ] Backward compatibility maintained

#### Testing

- [ ] New functionality has tests
- [ ] All tests pass: `make test`
- [ ] Edge cases are tested
- [ ] Error conditions are tested
- [ ] `.testmap.yml` updated if needed

#### Documentation

- [ ] Function headers complete
- [ ] README.md updated (if user-facing)
- [ ] CHANGELOG.md updated
- [ ] Inline comments for complex logic
- [ ] Cross-references are correct

#### Git Hygiene

- [ ] Commit messages follow conventions
- [ ] One logical change per commit
- [ ] No unrelated changes included
- [ ] No debug code left in
- [ ] No commented-out code

### 6. Commit and Push

```bash
# Stage changes
git add src/lib/oradba_common.sh
git add tests/test_oradba_common.bats
git add doc/

# Commit with conventional message
git commit -m "feat: add PATH deduplication function

- Add oradba_dedupe_path() to remove duplicates
- Add comprehensive tests with 10 test cases
- Update documentation with usage examples
- Resolves #85"

# Push to your fork
git push origin feat/issue-85-path-deduplication
```

## Local vs CI Testing

### Local Testing (Fast Iteration)

**Use for**:

- During development
- Quick validation of changes
- Testing specific functionality
- Debugging issues

**Commands**:

```bash
make test          # Smart selection (~1-3 min)
bats tests/test_specific.bats  # Specific test
make lint-shell    # Shell linting only
```

### CI Testing (Comprehensive Validation)

**Use for**:

- Before submitting PR
- After major changes
- Before releases
- Verifying cross-platform compatibility

**Commands**:

```bash
make test-full     # All tests (~10 min)
make lint          # All linters
make ci            # Full pipeline (~10-15 min)
```

**CI Workflow** (automatic on PR):

1. Checkout code
2. Install dependencies
3. Run shellcheck on all scripts
4. Run markdownlint on docs
5. Run full BATS test suite
6. Generate test coverage report
7. Build installer artifact

## Development Tools

### Makefile Targets

```bash
make help          # Show all available targets

# Development
make test          # Smart test selection
make test-full     # All tests
make lint          # Run all linters
make lint-shell    # Shell linting only
make lint-markdown # Markdown linting only
make format        # Format shell scripts (if shfmt available)

# Quality Gates
make pre-commit    # Smart tests + linting
make pre-push      # Full tests + linting
make ci            # Complete CI pipeline

# Build
make build         # Build installer
make clean         # Clean build artifacts

# Info
make version       # Show version
make status        # Git status
```

### Helper Scripts

```bash
# Validate project structure
./scripts/validate_project.sh

# Validate installation
./scripts/validate_installation.sh

# Validate test environment
./scripts/validate_test_environment.sh

# Build installer
./scripts/build_installer.sh
```

### Git Aliases (Optional)

Add to `~/.gitconfig`:

```ini
[alias]
    # Quick status
    st = status -sb
    
    # Pretty log
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    
    # Show changed files
    changed = diff --name-only
    
    # Amend last commit
    amend = commit --amend --no-edit
    
    # Push current branch
    pushb = push -u origin HEAD
```

## Best Practices

### DO

✅ **Test frequently**: Run tests after each change
✅ **Commit small**: One logical change per commit
✅ **Update docs**: Keep documentation in sync
✅ **Use linters**: Fix shellcheck warnings
✅ **Read existing code**: Match existing patterns
✅ **Ask questions**: Open discussion issues for clarification

### DON'T

❌ **Don't skip tests**: Always run tests before pushing
❌ **Don't commit broken code**: Even to feature branches
❌ **Don't ignore linter warnings**: Fix or suppress with justification
❌ **Don't change unrelated code**: Stay focused on the issue
❌ **Don't commit secrets**: Check before committing
❌ **Don't force push**: Especially to shared branches

## Troubleshooting

### Tests Won't Run

```bash
# Check BATS installation
which bats
bats --version

# Verify test files are executable
chmod +x tests/*.bats

# Check for syntax errors
bash -n tests/test_file.bats
```

### ShellCheck Errors

```bash
# View shellcheck output
shellcheck src/bin/script.sh

# Get explanation for error
shellcheck -x SC2155

# Suppress specific warning (with justification)
# shellcheck disable=SC2155  # Explanation why this is safe
local var="$(command)"
```

### Make Commands Fail

```bash
# Verify make is installed
which make

# Check Makefile syntax
make -n test  # Dry run

# Verbose output
make test V=1
```

## Next Steps

- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
- Read [function-header-guide.md](function-header-guide.md) for documentation standards
- Check [plugin-development.md](plugin-development.md) for plugin development
- See [architecture.md](architecture.md) for system architecture

## Resources

- **BATS Documentation**: <https://bats-core.readthedocs.io/>
- **ShellCheck Wiki**: <https://www.shellcheck.net/wiki/>
- **Bash Reference**: <https://www.gnu.org/software/bash/manual/>
- **Conventional Commits**: <https://www.conventionalcommits.org/>
- **Keep a Changelog**: <https://keepachangelog.com/>
