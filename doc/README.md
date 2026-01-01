<!-- markdownlint-disable MD013 -->
# Developer Documentation

Welcome to the oradba developer documentation. This directory contains technical documentation for contributors, maintainers, and developers working on the OraDBA project.

**Audience:** Project contributors, developers extending OraDBA, maintainers

**For Users:** See [User Documentation](../src/doc/README.md) for usage guides and reference materials.

## Getting Started

Start here if you're new to OraDBA development:

1. **[development.md](development.md)** - Development workflow, testing, and contribution process
2. **[architecture.md](architecture.md)** - System design, components, and decisions

## Core Documentation

### Development

- **[development.md](development.md)** - Complete development guide
  - Project structure and components
  - Development workflow and Git practices
  - Testing with BATS framework
  - Smart test selection for fast feedback
  - Code quality and linting
  - Building and releasing
  - Contribution guidelines

- **[smart-test-selection.md](smart-test-selection.md)** - Smart Test Selection
  - Overview and how it works
  - Usage examples and scenarios
  - Performance comparisons
  - Configuration and test mapping
  - CI/CD integration
  - Troubleshooting guide

### Architecture & Design

- **[architecture.md](architecture.md)** - System architecture
  - Overall design principles
  - Component interactions
  - Configuration system hierarchy
  - Environment loading sequence
  - Alias generation mechanism

- **[structure.md](structure.md)** - Project structure
  - Directory organization
  - File naming conventions
  - Module boundaries

### Technical Reference

- **[api.md](api.md)** - Internal API documentation
  - Library functions in `src/lib/common.sh`
  - Script interfaces and contracts
  - Environment variables
  - Return codes and error handling

- **[version-management.md](version-management.md)** - Version system internals
  - Semantic versioning implementation
  - Version comparison functions
  - Installation metadata
  - Update checking mechanism

### Configuration & Features

> **Note:** User-facing documentation for configuration, aliases, PDB aliases, and rlwrap filter has been migrated to the user documentation in `../src/doc/`:
>
> - Configuration: `../src/doc/05-configuration.md`
> - Shell Aliases: `../src/doc/06-aliases.md`
> - PDB Aliases: `../src/doc/07-pdb-aliases.md`
> - rlwrap Filter: `../src/doc/11-rlwrap.md`

### Standards & Tools

- **[markdown-linting.md](markdown-linting.md)** - Documentation standards
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
- Code blocks must specify language (```bash,```sql, etc.)
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
