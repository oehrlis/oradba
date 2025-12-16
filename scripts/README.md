# OraDBA Build and Validation Scripts

Utility scripts for building, testing, and maintaining OraDBA.

## Available Scripts

- **[build_installer.sh](build_installer.sh)** - Build self-contained installer
- **[validate_project.sh](validate_project.sh)** - Validate project structure
  and compliance

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

## Documentation

See [DEVELOPMENT.md](../doc/DEVELOPMENT.md) for:

- Build process details
- Release procedures
- CI/CD integration
- Contributing guidelines
