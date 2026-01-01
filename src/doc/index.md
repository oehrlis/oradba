# OraDBA User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Audience:** Database administrators, operators, and users of OraDBA

!!! info "For Developers"
    See [Developer Documentation](https://github.com/oehrlis/oradba/tree/main/doc) for contribution guides and technical details.

## 📖 Documentation Formats

The complete OraDBA user documentation is available in multiple formats:

- **[Online Documentation](https://oehrlis.github.io/oradba/)** - Browse with search and navigation
- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** - Download for offline use
- **[HTML User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)** - Single-page HTML version

## 📚 Documentation Structure

Use the navigation menu to explore:

### Getting Started
Learn the basics and get OraDBA up and running quickly.

### Configuration
Customize OraDBA to match your environment and preferences.

### Scripts & Tools
Discover the powerful SQL scripts, RMAN templates, and shell functions.

### Operations
Daily operations, troubleshooting, and reference materials.

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

| If you want to... | Start here |
|-------------------|------------|
| Learn what OraDBA is | [Introduction](01-introduction.md) |
| Install OraDBA | [Installation](02-installation.md) |
| Get started quickly | [Quick Start](03-quickstart.md) |
| Customize your setup | [Configuration System](05-configuration.md) |
| See available commands | [Aliases Reference](06-aliases.md) or run `alih` |
| Fix issues | [Troubleshooting](12-troubleshooting.md) |
| Quick command lookup | [Quick Reference](13-reference.md) |
| See practical examples | [Usage Guide](16-usage.md) |

## 💬 Support

- **Issues & Bugs:** <https://github.com/oehrlis/oradba/issues>
- **Discussions & Questions:** <https://github.com/oehrlis/oradba/discussions>
- **Source Code:** <https://github.com/oehrlis/oradba>

## 📄 License

Copyright © 2025 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](../../LICENSE) for details.
