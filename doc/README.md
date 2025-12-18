<!-- markdownlint-disable MD013 -->
# Developer Documentation

Welcome to the oradba developer documentation. This directory contains technical documentation for contributors, maintainers, and developers working on the OraDBA project.

**Audience:** Project contributors, developers extending OraDBA, maintainers

**For Users:** See [User Documentation](../src/doc/README.md) for usage guides and reference materials.

## Getting Started

Start here if you're new to OraDBA development:

1. **[QUICKSTART.md](QUICKSTART.md)** - Installation, system setup, and first steps
2. **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflow, testing, and contribution process
3. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design, components, and decisions

## Core Documentation

### Development

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Complete development guide
  - Project structure and components
  - Development workflow and Git practices
  - Testing with BATS framework
  - Code quality and linting
  - Building and releasing
  - Contribution guidelines

### Architecture & Design

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
  - Overall design principles
  - Component interactions
  - Configuration system hierarchy
  - Environment loading sequence
  - Alias generation mechanism

- **[STRUCTURE.md](STRUCTURE.md)** - Project structure
  - Directory organization
  - File naming conventions
  - Module boundaries

### Technical Reference

- **[API.md](API.md)** - Internal API documentation
  - Library functions in `src/lib/common.sh`
  - Script interfaces and contracts
  - Environment variables
  - Return codes and error handling

- **[VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md)** - Version system internals
  - Semantic versioning implementation
  - Version comparison functions
  - Installation metadata
  - Update checking mechanism

### Configuration & Features

- **[CONFIGURATION.md](CONFIGURATION.md)** - Configuration system deep dive
  - 5-level hierarchy implementation
  - Configuration file formats
  - Override mechanisms
  - SID-specific configurations
  - Customer customization patterns

- **[ALIASES.md](ALIASES.md)** - Alias system reference
  - All 50+ aliases with implementations
  - Alias generation code
  - Dynamic alias creation
  - Customization options

- **[PDB_ALIASES.md](PDB_ALIASES.md)** - PDB alias subsystem
  - PDB detection logic
  - Auto-generated PDB aliases
  - Configuration options
  - Implementation details

- **[RLWRAP_FILTER.md](RLWRAP_FILTER.md)** - Password filtering
  - Perl RlwrapFilter integration
  - Password detection patterns
  - Configuration and troubleshooting

### Standards & Tools

- **[MARKDOWN_LINTING.md](MARKDOWN_LINTING.md)** - Documentation standards
  - Markdown linting rules
  - markdownlint configuration
  - Documentation best practices

- **[templates/](templates/)** - File templates
  - Shell script header template
  - SQL script header template
  - RMAN script header template
  - Configuration file template

## Quick Reference

### Common Development Tasks

```bash
# Clone and setup
git clone https://github.com/oehrlis/oradba.git
cd oradba
make help

# Development cycle
make test              # Run all tests
make lint              # Lint shell scripts
make format            # Format code
make check             # Run tests + lint

# Building
make build             # Build installer
make dist              # Create distribution archive

# Version management
make version-bump-patch    # Bump patch version
make tag                   # Create git tag
```

### Project Statistics

- **Languages:** Bash, SQL, RMAN
- **Test Framework:** BATS (Bash Automated Testing System)
- **CI/CD:** GitHub Actions
- **Code Quality:** shellcheck, shfmt, markdownlint
- **Versioning:** Semantic Versioning 2.0.0

## Contributing to Documentation

### Documentation Standards

- Use ATX-style headers (`#` instead of underlines)
- One sentence per line for easier diffs
- Code blocks must specify language (```bash, ```sql, etc.)
- Internal links use relative paths
- External links use full URLs
- Follow [markdownlint](MARKDOWN_LINTING.md) rules

### Adding New Documentation

1. Create file in appropriate directory (`doc/` for dev, `src/doc/` for user)
2. Add standard header with title and description
3. Update relevant README.md index
4. Ensure all links work
5. Run `make lint-md` to validate markdown
6. Include in pull request

### Documentation Types

- **Developer docs** (`doc/`) - Architecture, API, internals, contribution guides
- **User docs** (`src/doc/`) - Usage guides, troubleshooting, reference materials
- **Folder READMEs** - Brief overview, file list, links to detailed docs
- **Code comments** - Inline documentation for complex logic

## External Resources

- **Main Repository:** <https://github.com/oehrlis/oradba>
- **Issue Tracker:** <https://github.com/oehrlis/oradba/issues>
- **Discussions:** <https://github.com/oehrlis/oradba/discussions>
- **Releases:** <https://github.com/oehrlis/oradba/releases>
- **CI/CD:** <https://github.com/oehrlis/oradba/actions>

## Related Documentation

- **[User Documentation](../src/doc/README.md)** - For OraDBA users
- **[Project README](../README.md)** - Project overview
- **[Contributing Guidelines](../CONTRIBUTING.md)** - How to contribute
- **[Changelog](../CHANGELOG.md)** - Release history
