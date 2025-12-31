# OraDBA User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Audience:** Database administrators, operators, and users of OraDBA

**For Developers:** See [Developer Documentation](../../doc/README.md) for contribution guides and technical details.

## 📖 Documentation Formats

The complete OraDBA user documentation is available in multiple formats:

- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)**  
  Download for offline use
- **[HTML User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)**  
  Single-page HTML version
- **Browse Online** - Individual chapters below

## 📚 Documentation Chapters

### Getting Started

- **[Introduction](01-introduction.md)** - Overview, features, benefits, and design philosophy
- **[Installation](02-installation.md)** - Prerequisites, installation methods, verification
- **[Quick Start](03-quickstart.md)** - First steps, oratab setup, common tasks
- **[Environment Management](04-environment.md)** - Using oraenv.sh, environment variables, modes

### Configuration & Customization

- **[Configuration System](05-configuration.md)** - Hierarchical configuration, files, variables
- **[Aliases](06-aliases.md)** - Complete reference for 50+ shell aliases
- **[PDB Aliases](07-pdb-aliases.md)** - Pluggable database aliases for multitenant

### Scripts & Tools

- **[SQL Scripts](08-sql-scripts.md)** - Database administration SQL scripts
- **[RMAN Scripts](09-rman-scripts.md)** - Backup and recovery templates
- **[Database Functions](10-functions.md)** - Shell functions for database queries
- **[rlwrap Filter](11-rlwrap.md)** - Password filtering for command history

### Operations & Reference

- **[Troubleshooting](12-troubleshooting.md)** - Common issues and solutions
- **[Quick Reference](13-reference.md)** - Command reference card for daily use
- **[SQL*Net Configuration](14-sqlnet-config.md)** - Managing SQL*Net with templates
- **[Log Management](15-log-management.md)** - Log rotation and management
- **[Usage Guide](16-usage.md)** - Practical examples and integration patterns

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

See [Quick Start Guide](03-quickstart.md) for detailed first steps.

## 📁 Additional Resources

- **SQL Scripts** - [../sql/](../sql/) - Database queries and information scripts
- **RMAN Scripts** - [../rcv/](../rcv/) - Backup and recovery templates
- **Configuration** - [../etc/](../etc/) - Example configurations and templates
- **Binaries** - [../bin/](../bin/) - Core scripts and utilities
- **Libraries** - [../lib/](../lib/) - Shared shell function libraries

## 🔍 Finding What You Need

- **First time user?** → [Introduction](01-introduction.md) → [Installation](02-installation.md) → [Quick Start](03-quickstart.md)
- **Need to customize?** → [Configuration System](05-configuration.md)
- **Looking for aliases?** → [Aliases](06-aliases.md) or run `alih` command
- **Having problems?** → [Troubleshooting](12-troubleshooting.md)
- **Quick lookup?** → [Quick Reference](13-reference.md)
- **Practical examples?** → [Usage Guide](16-usage.md)

## 💬 Support

- **Issues & Bugs:** <https://github.com/oehrlis/oradba/issues>
- **Discussions & Questions:** <https://github.com/oehrlis/oradba/discussions>
- **Source Code:** <https://github.com/oehrlis/oradba>

## 📄 License

Copyright © 2025 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](../../LICENSE) for details.
