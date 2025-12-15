# oradba - Oracle Database Administration Toolset

[![CI](https://github.com/oehrlis/oradba/actions/workflows/ci.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/ci.yml)
[![Release](https://github.com/oehrlis/oradba/actions/workflows/release.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](VERSION)

A comprehensive toolset for Oracle Database administration and operations, designed for lab and engineering environments.

## Features

- **oraenv.sh**: Core environment setup script based on oratab and configuration files
- **Administration Scripts**: Collection of bash, SQL, and RMAN scripts
- **Easy Installation**: Self-contained installer with base64 payload
- **Automated Testing**: BATS-based test suite
- **CI/CD Ready**: GitHub Actions workflows included

## Project Structure

```
oradba/
├── srv/
│   ├── bin/         # Executable scripts
│   ├── lib/         # Library files and functions
│   ├── etc/         # Configuration files
│   ├── sql/         # SQL scripts
│   ├── rcv/         # RMAN recovery scripts
│   └── templates/   # Template files
├── tests/           # BATS test files
├── scripts/         # Build and utility scripts
├── doc/             # Developer documentation
└── .github/         # GitHub workflows
```

## Installation

Download and run the installer:

```bash
curl -o oradba_install.sh https://raw.githubusercontent.com/oehrlis/oradba/main/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh
```

Or with options:

```bash
./oradba_install.sh --prefix /opt/oradba --version 0.1.0
```

## Usage

### Setting Oracle Environment

```bash
source oraenv.sh ORCL
```

This will set up the environment for the ORACLE_SID "ORCL" based on your oratab configuration.

## Development

### Prerequisites

- Bash 4.0+
- BATS for testing
- Oracle Database (for testing database-specific scripts)

### Running Tests

```bash
./tests/run_tests.sh
```

### Building the Installer

```bash
./scripts/build_installer.sh
```

## Versioning

This project uses [Semantic Versioning](https://semver.org/).

Current version: **0.1.0**

## License

Copyright (c) 2025 Stefan Oehrli

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
