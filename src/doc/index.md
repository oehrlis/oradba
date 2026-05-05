# OraDBA User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Version:** 0.24.x | **Audience:** Database administrators, operators, and users managing Oracle environments

!!! info "For Developers"
    See [Developer Documentation](https://github.com/oehrlis/oradba/tree/main/doc)
    for contribution guides, API reference, and technical architecture.

## Documentation Formats

The complete OraDBA user documentation is available in multiple formats:

- **[Online Documentation](https://oehrlis.github.io/oradba/)** - Browse with search and navigation
- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** - Download for
  offline use

## Documentation Structure

### Getting Started

| Document                              | Description                         |
| ------------------------------------- | ----------------------------------- |
| [Introduction](introduction.md)       | What is OraDBA and why use it       |
| [Installation](installation.md)       | Complete installation guide         |
| [Quick Start](quickstart.md)          | Get up and running in 5 minutes     |

### Configuration & Environment

| Document                                             | Description                         |
| ---------------------------------------------------- | ----------------------------------- |
| [Configuration System](configuration.md)             | 6-level configuration hierarchy     |
| [Advanced Configuration](advanced-configuration.md)  | Multi-version, Grid, ROOH, products |
| [Environment Management](environment.md)             | Registry API and Plugin System      |

### Commands & Features

| Document                            | Description                            |
|-------------------------------------|----------------------------------------|
| [Aliases Reference](aliases.md)     | Aliases, PDB aliases, rlwrap           |
| [Functions Reference](functions.md) | Available shell functions              |
| [SQL Scripts](sql-scripts.md)       | SQL script library reference           |
| [RMAN Scripts](rman-scripts.md)     | RMAN backup script templates           |

### Extensions & Customization

| Document                          | Description                                     |
| --------------------------------- | ----------------------------------------------- |
| [Extension System](extensions.md) | Creating, managing, and available extensions    |

### Operations & Support

| Document                                            | Description                             |
| --------------------------------------------------- | --------------------------------------- |
| [Service and Log Operations](operations.md)         | Service management and log rotation     |
| [SQL*Net Configuration](sqlnet-config.md)           | SQLNet and network configuration        |
| [Troubleshooting](troubleshooting.md)               | Common issues and solutions             |

## Quick Start

```bash
# Install
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh && ./oradba_install.sh

# Set environment and start working
source /opt/oradba/bin/oraenv.sh FREE
sq          # sqlplus / as sysdba
alih        # Show all aliases
```

See [Quick Start Guide](quickstart.md) for detailed first steps.

## Finding What You Need

| If you want to...      | Start here                                    |
|------------------------|-----------------------------------------------|
| Learn what OraDBA is   | [Introduction](introduction.md)               |
| Install OraDBA         | [Installation](installation.md)               |
| Get started quickly    | [Quick Start](quickstart.md)                  |
| Customize your setup   | [Configuration System](configuration.md)      |
| See available commands | [Aliases Reference](aliases.md) or run `alih` |
| Extend functionality   | [Extension System](extensions.md)             |
| Fix issues             | [Troubleshooting](troubleshooting.md)         |
| Quick command lookup   | [Quick Start](quickstart.md)                  |
| See practical examples | [Quick Start](quickstart.md)                  |

## Support

- **Issues & Bugs:** <https://github.com/oehrlis/oradba/issues>
- **Discussions & Questions:** <https://github.com/oehrlis/oradba/discussions>
- **Source Code:** <https://github.com/oehrlis/oradba>

## License

Copyright © 2026 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](https://github.com/oehrlis/oradba/blob/main/LICENSE) for details.

---

**OraDBA v1.0.0** - Modern Oracle Database Administration Toolset
