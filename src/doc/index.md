# OraDBA User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Audience:** Database administrators, operators, and users of OraDBA

!!! info "For Developers"
    See [Developer Documentation](https://github.com/oehrlis/oradba/tree/main/doc)
    for contribution guides and technical details.

## 📖 Documentation Formats

The complete OraDBA user documentation is available in multiple formats:

- **[Online Documentation](https://oehrlis.github.io/oradba/)** - Browse with search and navigation
- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** - Download for
  offline use
- **[HTML User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)** - Single-page
  HTML version

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

See [Quick Start Guide](quickstart.md) for detailed first steps.

## Finding What You Need

| If you want to...      | Start here                                       |
|------------------------|--------------------------------------------------|
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

Copyright © 2025 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](https://github.com/oehrlis/oradba/blob/main/LICENSE) for details.
