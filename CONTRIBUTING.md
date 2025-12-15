# Contributing to oradba

Thank you for your interest in contributing to oradba! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment for all contributors

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
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes following the coding standards below
4. Add or update tests as needed
5. Update documentation as needed
6. Commit with clear messages: `git commit -m "Add feature: description"`
7. Push to your fork: `git push origin feature/my-feature`
8. Open a Pull Request

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

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode when appropriate: `set -e`, `set -u`, `set -o pipefail`
- Use meaningful variable names
- Add comments for complex logic
- Follow existing code style
- Use shellcheck to lint your code

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

- Update README.md for user-facing changes
- Update CHANGELOG.md following Keep a Changelog format
- Add inline comments for complex logic
- Update man pages or help text as needed

### Testing

- Add BATS tests for new functionality
- Ensure all tests pass before submitting PR
- Test on multiple environments when possible
- Include both positive and negative test cases

### Commit Messages

Follow conventional commits format:

```text
type(scope): subject

body

footer
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test changes
- `refactor`: Code refactoring
- `style`: Code style changes
- `chore`: Maintenance tasks

Examples:

```text
feat(oraenv): Add support for Oracle 23c
fix(installer): Handle spaces in installation path
docs(readme): Update installation instructions
test(common): Add tests for logging functions
```

## Release Process

1. Update VERSION file
2. Update CHANGELOG.md
3. Create and push tag: `git tag -a v0.1.0 -m "Release v0.1.0"`
4. GitHub Actions will create the release automatically

## Questions?

- Open an issue for questions
- Check existing documentation
- Review closed issues for similar questions

Thank you for contributing to oradba!
