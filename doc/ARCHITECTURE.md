<!-- markdownlint-disable MD013 -->
# oradba Architecture

## Overview

oradba is designed as a modular toolset for Oracle Database administration with a focus on environment management, automation, and maintainability.

## System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                         oradba System                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   oraenv.sh  │  │   Scripts    │  │   SQL/RMAN   │     │
│  │  Environment │  │  Management  │  │   Scripts    │     │
│  │    Setup     │  │              │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                   ┌────────▼────────┐                      │
│                   │   common.sh     │                      │
│                   │   Library       │                      │
│                   └────────┬────────┘                      │
│                            │                                │
│                   ┌────────▼────────┐                      │
│                   │  Configuration  │                      │
│                   │   oradba.conf   │                      │
│                   └─────────────────┘                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Environment Management (oraenv.sh)

**Purpose**: Set up Oracle environment variables based on oratab configuration.

**Key Features**:

- Parse oratab file
- Set ORACLE_SID, ORACLE_HOME, ORACLE_BASE
- Configure PATH and LD_LIBRARY_PATH
- Handle TNS_ADMIN and NLS settings

**Flow**:

```text
User invokes oraenv.sh
    ↓
Parse arguments
    ↓
Locate oratab file
    ↓
Read SID configuration
    ↓
Validate ORACLE_HOME
    ↓
Set environment variables
    ↓
Display environment summary
```

### 2. Common Library (common.sh)

**Purpose**: Provide reusable functions across all scripts.

**Categories**:

- **Logging**: Info, warn, error, debug messages
- **Validation**: Command existence, directory validation
- **Oracle**: Environment verification, version detection
- **Parsing**: oratab parsing, configuration reading

### 3. Configuration System

**Hierarchy**:

1. System defaults (`srv/etc/oradba.conf`)
2. User overrides (`~/.oradba_config`)
3. Environment variables
4. Command-line arguments

### 4. Installation System

**Build Process**:

```text
Source Files (srv/)
    ↓
Tarball Creation
    ↓
Base64 Encoding
    ↓
Embed in Installer
    ↓
Self-Extracting Script
```

## Directory Structure

```text
oradba/
├── srv/                    # Distribution files
│   ├── bin/               # Executable scripts
│   ├── lib/               # Libraries
│   ├── etc/               # Configuration
│   ├── sql/               # SQL scripts
│   ├── rcv/               # RMAN scripts
│   ├── templates/         # Templates
│   └── doc/               # User documentation
├── scripts/               # Build and utility scripts
├── tests/                 # Test suite
├── doc/                   # Developer documentation
└── .github/               # CI/CD workflows
```

## Data Flow

### Environment Setup

```text
User → oraenv.sh → oratab → ORACLE_HOME → Environment Variables → Shell
```

### Script Execution

```text
Script → common.sh → Configuration → Validation → Execution → Logging
```

## Design Principles

1. **Modularity**: Each component has a single responsibility
2. **Reusability**: Common functions in shared library
3. **Configuration**: Hierarchical configuration system
4. **Validation**: Extensive error checking and validation
5. **Documentation**: Comprehensive inline and external docs
6. **Testing**: BATS tests for all components
7. **Portability**: POSIX-compliant where possible

## Extension Points

### Adding New Scripts

1. Use script template from `srv/templates/`
2. Source common library
3. Follow naming conventions
4. Add appropriate tests
5. Update documentation

### Adding New Functions

1. Add to `srv/lib/common.sh`
2. Document parameters and return values
3. Add unit tests
4. Update API documentation

## Security Considerations

- No hardcoded credentials
- Configuration files with appropriate permissions
- Input validation on all parameters
- Safe handling of environment variables
- Logging of security-relevant operations

## Performance Considerations

- Minimal external dependencies
- Efficient oratab parsing
- Caching where appropriate
- Fast environment setup

## Future Architecture

### Planned Enhancements

- Plugin system for extensions
- Remote database management
- Multi-database operations
- Configuration management database
- Web-based dashboard (optional)

## References

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [API.md](API.md) - API documentation
- [README.md](../README.md) - Main documentation
