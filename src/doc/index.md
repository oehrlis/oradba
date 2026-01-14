# OraDBA v1.0.0 User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Version:** 1.0.0 | **Audience:** Database administrators, operators, and users of OraDBA

!!! info "For Developers"
    See [Developer Documentation](https://github.com/oehrlis/oradba/tree/main/doc)
    for contribution guides, API reference, and technical architecture.

## 📖 Documentation Formats

The complete OraDBA user documentation is available in multiple formats:

- **[Online Documentation](https://oehrlis.github.io/oradba/)** - Browse with search and navigation
- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** - Download for
  offline use
- **[HTML User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)** - Single-page
  HTML version

## 📚 Documentation Structure

### Getting Started

| Document                                        | Description                        |
| ----------------------------------------------- | ---------------------------------- |
| [Introduction](introduction.md)                 | What is OraDBA and why use it      |
| [Quick Start](quickstart.md)                    | Get up and running in 5 minutes    |
| [Installation](installation.md)                 | Complete installation guide        |
| [Installation (Docker)](installation-docker.md) | Docker-specific installation       |
| [Usage Guide](usage.md)                         | Daily usage patterns and workflows |

### Configuration & Environment

| Document                                    | Description                        |
| ------------------------------------------- | ---------------------------------- |
| [Configuration System](configuration.md)    | 6-level configuration hierarchy    |
| [Environment Management](environment.md)    | Environment variables and setup    |
| [SQLNet Configuration](sqlnet-config.md)    | SQLNet and network configuration   |

### Commands & Features

| Document                                    | Description                            |
|---------------------------------------------|----------------------------------------|
| [Aliases Reference](aliases.md)             | Shell command aliases (sq, alih, etc.) |
| [PDB Aliases](pdb-aliases.md)               | Pluggable database shortcuts           |
| [Functions Reference](functions.md)         | Available shell functions              |
| [Service Management](service-management.md) | Database service operations            |
| [SQL Scripts](sql-scripts.md)               | SQL script library reference           |
| [RMAN Scripts](rman-scripts.md)             | RMAN backup script templates           |
| [rlwrap Filter](rlwrap.md)                  | SQLPlus command-line enhancement       |

### Extensions & Customization

| Document                                    | Description                     |
| ------------------------------------------- | ------------------------------- |
| [Extension System](extensions.md)           | Creating and using extensions   |
| [Extension Catalog](extensions-catalog.md)  | Available extensions directory  |

### Operations & Support

| Document                                | Description                          |
| --------------------------------------- | ------------------------------------ |
| [Log Management](log-management.md)     | Logging system and troubleshooting   |
| [Troubleshooting](troubleshooting.md)   | Common issues and solutions          |
| [Quick Reference](reference.md)         | Command quick reference card         |

## 🚀 Quick Start

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
| Quick command lookup   | [Quick Reference](reference.md)               |
| See practical examples | [Usage Guide](usage.md)                       |

## 💬 Support

- **Issues & Bugs:** <https://github.com/oehrlis/oradba/issues>
- **Discussions & Questions:** <https://github.com/oehrlis/oradba/discussions>
- **Source Code:** <https://github.com/oehrlis/oradba>

## 📄 License

Copyright © 2026 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](https://github.com/oehrlis/oradba/blob/main/LICENSE) for details.

---

**OraDBA v1.0.0** - Modern Oracle Database Administration Toolset
