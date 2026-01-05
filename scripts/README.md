# OraDBA Build and Validation Scripts

Utility scripts for building, testing, and maintaining OraDBA.

## Available Scripts

- **[build_installer.sh](build_installer.sh)** - Build self-contained installer
- **[select_tests.sh](select_tests.sh)** - Pick BATS tests based on changed files
- **[validate_project.sh](validate_project.sh)** - Validate project structure and compliance

## Usage

### Build Installer

```bash
make build
# or directly
./scripts/build_installer.sh
```

Creates `dist/oradba_install.sh` with embedded payload.

### Validate Project

```bash
make lint
# or directly
./scripts/validate_project.sh
```

Runs markdownlint and shellcheck validation.

### Select Tests

```bash
# Show which tests would run
./scripts/select_tests.sh --dry-run --verbose

# Compare against a different base
./scripts/select_tests.sh --base main

# Force all tests
./scripts/select_tests.sh --full
```

Uses `.testmap.yml` to map file changes to BATS tests.

## Documentation

See [DEVELOPMENT.md](../doc/DEVELOPMENT.md) for:

- Build process details
- Release procedures
- CI/CD integration
- Contributing guidelines
