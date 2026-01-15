# OraDBA Build and Validation Scripts

Utility scripts for building, testing, and maintaining OraDBA.

## Available Scripts

- **[build_installer.sh](build_installer.sh)** - Build self-contained installer
- **[build_pdf.sh](build_pdf.sh)** - Build PDF documentation using Docker/Pandoc
- **[select_tests.sh](select_tests.sh)** - Pick BATS tests based on changed files
- **[validate_project.sh](validate_project.sh)** - Validate project structure and compliance
- **[validate_test_environment.sh](validate_test_environment.sh)** - Validate testing environment for v1.0.0
- **[archive_github_releases.sh](archive_github_releases.sh)** - Archive GitHub release notes locally

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

Validates project structure, checks all required files, and verifies file counts.

### Validate Test Environment

```bash
./scripts/validate_test_environment.sh
```

Validates testing environment setup for v1.0.0 release, checks BATS installation,
version files, and test infrastructure.

### Build PDF Documentation

```bash
make docs-pdf
# or directly
./scripts/build_pdf.sh
```

Builddevelopment.md](../doc/developmentith Pandoc and Eisvogel template.

### Archive GitHub Releases

```bash
./scripts/archive_github_releases.sh
```

Downloads and archives GitHub release notes to `doc/releases/archive/`.

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
