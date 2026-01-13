# Development Guide

Guide for developers contributing to OraDBA Extension Template or creating extensions.

## Development Setup

### Prerequisites

- Bash 4.0 or later
- Git 2.20 or later
- Bats (Bash Automated Testing System) for tests
- ShellCheck for linting
- Oracle environment (optional, for testing)

### Clone Repository

```bash
# Clone extension template
git clone https://github.com/oehrlis/oradba_extension.git
cd oradba_extension

# Create new extension from template
git clone https://github.com/oehrlis/oradba_extension.git my_extension
cd my_extension
./scripts/rename-extension.sh my_extension
```

### Development Environment

Set up development environment:

```bash
# Install bats
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local

# Install shellcheck
# macOS
brew install shellcheck

# Linux
sudo apt install shellcheck  # Debian/Ubuntu
sudo yum install shellcheck  # RHEL/CentOS

# Verify installation
bats --version
shellcheck --version
```

## Creating a New Extension

### Step 1: Clone Template

```bash
# Clone template
git clone https://github.com/oehrlis/oradba_extension.git my_extension
cd my_extension
```

### Step 2: Rename Extension

```bash
# Rename to your extension name
./scripts/rename-extension.sh my_extension

# Verify renaming
grep -r "my_extension" .
```

### Step 3: Update Metadata

Edit `.extension` file:

```ini
EXTENSION_NAME="my_extension"
EXTENSION_VERSION="0.1.0"
EXTENSION_PRIORITY="50"
EXTENSION_DESCRIPTION="My custom OraDBA extension"
```

### Step 4: Implement Functionality

Create your scripts in appropriate directories:

```bash
# Add executable script
cat > bin/my_tool.sh <<'EOF'
#!/usr/bin/env bash
# My Extension Tool

# Load OraDBA environment
if [[ -z "${ORADBA_BASE}" ]]; then
    echo "Error: OraDBA not loaded"
    exit 1
fi

# Your implementation here
echo "My Extension Tool"
EOF

chmod +x bin/my_tool.sh
```

### Step 5: Add Tests

Create tests in `tests/`:

```bash
# Add test file
cat > tests/my_extension.bats <<'EOF'
#!/usr/bin/env bats

@test "Extension metadata exists" {
    [ -f .extension ]
}

@test "Extension has correct name" {
    grep -q 'EXTENSION_NAME="my_extension"' .extension
}

@test "My tool exists and is executable" {
    [ -x bin/my_tool.sh ]
}
EOF

# Run tests
bats tests/my_extension.bats
```

### Step 6: Build and Test

```bash
# Build package
make build

# Verify build
ls -l dist/

# Test installation
make install PREFIX=/tmp/oradba
```

## Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
vim bin/my_tool.sh

# Test changes
bats tests/

# Commit changes
git add .
git commit -m "Add my feature"
```

### 2. Testing

```bash
# Run all tests
make test

# Run specific test file
bats tests/my_extension.bats

# Run with verbose output
bats -t tests/

# Run shellcheck
shellcheck bin/*.sh lib/*.sh scripts/*.sh
```

### 3. Building

```bash
# Clean previous builds
make clean

# Build package
make build

# Check output
ls -lh dist/
```

### 4. Documentation

```bash
# Update README
vim README.md

# Update documentation
vim doc/index.md

# Build docs locally (if using mkdocs)
mkdocs serve
```

### 5. Release

```bash
# Update version
echo "1.0.0" > VERSION

# Update CHANGELOG
vim CHANGELOG.md

# Commit version bump
git add VERSION CHANGELOG.md
git commit -m "Bump version to 1.0.0"

# Tag release
git tag -a v1.0.0 -m "Release v1.0.0"

# Push changes
git push origin main --tags
```

## Project Structure

### Recommended Organization

```text
my_extension/
├── .extension              # Metadata
├── .checksumignore        # Integrity exclusions
├── VERSION                # Version number
├── README.md              # Overview
├── CHANGELOG.md           # Version history
├── LICENSE                # License
├── Makefile               # Build automation
├── bin/                   # Executable scripts
│   └── my_tool.sh
├── etc/                   # Configuration
│   └── my_extension.conf.example
├── lib/                   # Library functions
│   └── common.sh
├── sql/                   # SQL scripts
│   └── my_query.sql
├── rcv/                   # RMAN scripts
│   └── my_backup.rcv
├── doc/                   # Documentation
│   ├── index.md
│   ├── installation.md
│   ├── configuration.md
│   ├── reference.md
│   └── changelog.md
├── scripts/               # Build scripts
│   ├── build.sh
│   └── rename-extension.sh
└── tests/                 # Test suite
    └── my_extension.bats
```

### File Naming Conventions

- **Scripts:** `lowercase_with_underscores.sh`
- **SQL files:** `lowercase_with_underscores.sql`
- **RMAN files:** `lowercase_with_underscores.rcv`
- **Tests:** `test_feature.bats`
- **Documentation:** `lowercase_with_hyphens.md`

## Coding Standards

### Shell Script Standards

```bash
#!/usr/bin/env bash
#
# Script Name: my_tool.sh
# Description: Brief description of script purpose
# Author: Your Name
# Version: 1.0.0
#

# Strict error handling
set -euo pipefail

# Constants (uppercase)
readonly SCRIPT_NAME="$(basename "${0}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

# Variables (lowercase)
verbose=false
database_sid=""

# Functions
show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
    -h, --help              Show this help
    -v, --verbose           Verbose output
    -d, --database SID      Database SID
EOF
}

main() {
    # Main script logic
    echo "Main function"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "${1}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            verbose=true
            shift
            ;;
        -d|--database)
            database_sid="${2}"
            shift 2
            ;;
        *)
            echo "Unknown option: ${1}"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main
```

### SQL Script Standards

```sql
-- ============================================================================
-- Script Name: my_query.sql
-- Description: Brief description of SQL purpose
-- Author: Your Name
-- Version: 1.0.0
-- ============================================================================

-- Set formatting
SET LINESIZE 200
SET PAGESIZE 1000
SET FEEDBACK OFF
SET HEADING ON

-- Query with comments
SELECT 
    name,
    value
FROM 
    v$parameter
WHERE 
    name LIKE '%memory%'
ORDER BY 
    name;

-- Reset formatting
SET FEEDBACK ON
```

### RMAN Script Standards

```sql
-- ============================================================================
-- RMAN Script: my_backup.rcv
-- Description: Brief description of backup purpose
-- Author: Your Name
-- Version: 1.0.0
-- ============================================================================

-- Configuration
CONFIGURE RETENTION POLICY TO REDUNDANCY 2;
CONFIGURE BACKUP OPTIMIZATION ON;

-- Backup commands
RUN {
    ALLOCATE CHANNEL disk1 DEVICE TYPE DISK FORMAT '/backup/%U';
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
    RELEASE CHANNEL disk1;
}
```

## Testing Guidelines

### Test Structure

```bash
#!/usr/bin/env bats

# Setup function - runs before each test
setup() {
    # Set up test environment
    export TEST_DIR="${BATS_TEST_TMPDIR}/test_$$"
    mkdir -p "${TEST_DIR}"
}

# Teardown function - runs after each test
teardown() {
    # Clean up test environment
    rm -rf "${TEST_DIR}"
}

@test "Feature works as expected" {
    # Arrange
    local expected="expected_value"
    
    # Act
    local actual=$(my_function)
    
    # Assert
    [ "${actual}" = "${expected}" ]
}

@test "Error handling works" {
    # Should fail with error
    run my_function --invalid
    [ "${status}" -ne 0 ]
}
```

### Test Coverage

Aim for comprehensive test coverage:

- **Unit tests:** Test individual functions
- **Integration tests:** Test component interaction
- **End-to-end tests:** Test complete workflows
- **Error handling:** Test failure scenarios
- **Edge cases:** Test boundary conditions

### Running Tests

```bash
# All tests
bats tests/

# Specific file
bats tests/my_extension.bats

# Verbose output
bats -t tests/

# Parallel execution
bats -j 4 tests/

# Filter tests
bats --filter "my feature" tests/
```

## CI/CD Integration

### GitHub Actions

The template includes GitHub Actions workflows:

**.github/workflows/test.yml:**

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install bats
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          sudo ./install.sh /usr/local
      
      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck
      
      - name: Run tests
        run: make test
      
      - name: Run shellcheck
        run: shellcheck bin/*.sh lib/*.sh scripts/*.sh
```

**.github/workflows/build.yml:**

```yaml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build package
        run: make build
      
      - name: Create release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release-packages
          path: dist/*
```

## Documentation

### Writing Documentation

Follow these guidelines:

1. **Clear structure:** Use headings, lists, tables
2. **Examples:** Include code examples
3. **Screenshots:** Add visuals where helpful
4. **Links:** Cross-reference related docs
5. **Updates:** Keep docs in sync with code

### Documentation Files

Required documentation:

- **README.md:** Overview and quick start
- **doc/index.md:** Main documentation
- **doc/installation.md:** Installation guide
- **doc/configuration.md:** Configuration reference
- **doc/reference.md:** Complete API reference

### Markdown Standards

```markdown
# Main Heading

Brief introduction paragraph.

## Section Heading

Content with **bold** and *italic* text.

### Subsection

- Bullet points
- With multiple items

#### Example

\`\`\`bash
# Code example with syntax highlighting
echo "Hello, World!"
\`\`\`

#### Note

!!! note "Title"
    Admonition for important information
```

## Debugging

### Shell Script Debugging

```bash
# Enable debug mode
set -x

# Trace function calls
set -T

# Debug specific section
(set -x; my_function)

# Print variable values
echo "DEBUG: variable = ${variable}"

# Use logging
log_debug "Debug message with value: ${value}"
```

### Common Issues

**Issue:** Script fails with "command not found"

```bash
# Solution: Check PATH and ORACLE_HOME
echo "PATH: ${PATH}"
echo "ORACLE_HOME: ${ORACLE_HOME}"
which sqlplus
```

**Issue:** Permission denied

```bash
# Solution: Check file permissions
ls -l bin/my_tool.sh
chmod +x bin/my_tool.sh
```

**Issue:** Tests fail in CI but pass locally

```bash
# Solution: Check environment differences
# Add debug output to tests
@test "my test" {
    echo "PWD: ${PWD}"
    echo "PATH: ${PATH}"
    run my_command
    echo "Output: ${output}"
    echo "Status: ${status}"
    [ "${status}" -eq 0 ]
}
```

## Contributing

### Contribution Process

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Run full test suite
5. Update documentation
6. Submit pull request

### Pull Request Guidelines

- Clear description of changes
- Reference related issues
- Include tests for new features
- Update documentation
- Follow coding standards
- All tests passing

### Code Review

Code reviews check for:

- Correctness and functionality
- Test coverage
- Code quality and style
- Documentation completeness
- Security considerations
- Performance implications

## Best Practices

1. **Test thoroughly:** Write comprehensive tests
2. **Document clearly:** Keep docs up to date
3. **Version properly:** Follow semantic versioning
4. **Handle errors:** Robust error handling
5. **Log appropriately:** Useful logging messages
6. **Secure by default:** No hardcoded secrets
7. **Validate input:** Check user inputs
8. **Clean up:** Remove temporary files
9. **Be consistent:** Follow conventions
10. **Review regularly:** Code review everything

## Resources

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [Bats Documentation](https://bats-core.readthedocs.io/)
- [ShellCheck](https://www.shellcheck.net/)
- [OraDBA Documentation](https://code.oradba.ch/oradba/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)

## Next Steps

- See [Reference](reference.md) for API details
- See [Installation](installation.md) for setup
- See [Configuration](configuration.md) for customization
