<!-- markdownlint-disable MD013 -->
# Developer Documentation

Welcome to the OraDBA developer documentation. This directory contains technical documentation for contributors, maintainers, and developers working on the OraDBA v1.0.0 project.

**Audience:** Project contributors, developers extending OraDBA, maintainers

**For Users:** See [User Documentation](../src/doc/index.md) for usage guides and reference materials.

## Quick Navigation

| Category | Document | Description |
| -------- | -------- | ----------- |
| **Getting Started** | [development.md](development.md) | Complete development guide - setup, workflow, testing, CI/CD |
| **Architecture** | [architecture.md](architecture.md) | System design, components, and architectural decisions |
| **API Reference** | [api.md](api.md) | Complete function reference for all libraries |
| **Environment Design** | [oradba-env-design.md](oradba-env-design.md) | Environment library architecture and design patterns |
| **Extension System** | [extension-system.md](extension-system.md) | Extension development guide and API |
| **Testing** | [release-testing-checklist.md](release-testing-checklist.md) | Pre-release testing checklist |
| **Release Planning** | [v1.0.0-release-plan.md](v1.0.0-release-plan.md) | v1.0.0 release preparation roadmap |
| **Archive** | [archive/](archive/) | Historical and detailed implementation documentation |

## Getting Started

New to OraDBA development? Start here:

1. **[development.md](development.md)** - Read the complete development guide

   - Project structure and setup
   - Development workflow and Git practices
   - Testing with BATS framework
   - CI/CD integration
   - Code quality standards
   - Building and releasing

2. **[architecture.md](architecture.md)** - Understand the system design
   - Library-based architecture
   - Configuration system
   - Environment loading
   - Extension framework

3. **[api.md](api.md)** - Learn the API

   - Core utility functions
   - Environment management functions
   - Extension framework functions

## Core Documentation

### Development & Workflow

**[development.md](development.md)** - Complete development guide (42K, comprehensive)

- Project structure and components
- Development environment setup
- Testing with BATS framework
- Smart test selection
- CI/CD integration with GitHub Actions
- Code quality (shellcheck, shfmt)
- Documentation standards (markdown linting)
- Build process and release workflow
- Contribution guidelines

**Quick development cycle:**

```bash
# Clone and setup
git clone https://github.com/oehrlis/oradba.git
cd oradba
make help

# Development
make test              # Run all tests
make lint              # Lint shell scripts + markdown
make check             # Run tests + lint

# Building
make build             # Build installer
make dist              # Create distribution archive
```

### Architecture & Design

**[architecture.md](architecture.md)** - System architecture

- Overall design principles and philosophy
- Library-based modular architecture
- Component interactions
- Configuration system hierarchy (6 levels)
- Environment loading sequence
- Alias generation mechanism
- Extension framework integration

**[oradba-env-design.md](oradba-env-design.md)** - Environment library design (46K, detailed)

- Environment Management Libraries (oradba_env_*)
- Parser, Builder, Validator, Config Manager
- Status Display and Change Tracking
- Design patterns and best practices
- Implementation details
- Testing strategies

### Technical Reference

**[api.md](api.md)** - Complete API documentation (43K)

- **Core Utility Libraries**
  - common.sh (50 functions) - Logging, validation, config management
  - db_functions.sh (11 functions) - Database operations
  - aliases.sh (5 functions) - Alias management
- **Environment Management Libraries** (6 libraries, 47 functions)
  - Environment parsing, building, validation
  - Configuration management
  - Status display and change tracking
- **Extension Framework**
  - extensions.sh (20 functions) - Extension lifecycle management
- Function signatures, parameters, return codes
- Usage examples and best practices

**[extension-system.md](extension-system.md)** - Extension development (21K)

- Extension framework overview
- Extension structure and metadata
- Lifecycle (discover → load → activate → manage)
- Configuration management
- Best practices and patterns
- Creating custom extensions
- Testing and debugging
- Integration examples

## Testing & Release

**[release-testing-checklist.md](release-testing-checklist.md)** - Pre-release testing checklist

- Installation testing (multiple platforms)
- Core functionality verification
- Extension system testing
- Configuration system testing
- Performance testing
- Documentation validation
- Upgrade testing

**[v1.0.0-release-plan.md](v1.0.0-release-plan.md)** - v1.0.0 release preparation

- 9 phases: Documentation → Testing → Release
- Estimated 52-78 hours
- Phase 1: Development Documentation ⏳ **IN PROGRESS**
- Phase 2-9: User Docs, Testing, Quality, Final Release

## Templates & Standards

**[templates/](templates/)** - File templates

- Shell script header template
- SQL script header template
- RMAN script header template
- Configuration file template

**Documentation Standards:**

- Use ATX-style headers (`#` instead of underlines)
- One sentence per line for easier diffs
- Code blocks must specify language (`bash`, `sql`, etc.)
- Internal links use relative paths
- Run `make lint-md` to validate markdown

**Code Standards:**

- Shellcheck clean (no errors)
- shfmt formatted (Google style)
- Function headers required (see [src/lib/README.md](../src/lib/README.md))
- BATS tests for all functions

## Historical & Archived Documentation

**[archive/](archive/)** - Historical and detailed implementation documentation

The archive contains:

- **Temporary Planning Docs** - Phase 5 planning documents (function headers, legacy analysis, smart testing, version management)
- **Detailed Implementation Docs** - Deep dives into specific systems (CI optimization, markdown linting, extension implementation patterns)

These documents provide historical context and detailed implementation notes but have been consolidated into the core documentation above.

## Project Statistics

- **Version:** v1.0.0-dev (preparing for v1.0.0 release)
- **Last Release:** v0.18.5
- **Libraries:** 10 (66 core functions + 47 environment + 20 extension = 133 total)
- **Lines of Code:** 10,586 (library code only)
- **Test Framework:** BATS (Bash Automated Testing System)
- **CI/CD:** GitHub Actions
- **Code Quality:** shellcheck, shfmt, markdownlint
- **Versioning:** Semantic Versioning 2.0.0

## Library Organization

OraDBA v1.0.0 is built on a modular library architecture:

1. **Environment Management Libraries** (oradba_env_*): 6 libraries, 47 functions
   - Modern environment configuration system
   - Parser → Builder → Validator → Config → Status → Changes

2. **Core Utility Libraries**: 3 libraries, 66 functions
   - common.sh, db_functions.sh, aliases.sh
   - Foundational utilities used throughout OraDBA

3. **Extension Framework**: extensions.sh, 20 functions
   - Plugin system for extending OraDBA
   - Metadata-driven lifecycle management

See [src/lib/README.md](../src/lib/README.md) for complete library documentation.

## Quick Reference

### Common Development Tasks

```bash
# Testing
make test              # Run all tests
make test-fast         # Smart test selection (changed files only)
make test-unit         # Unit tests only
make test-integration  # Integration tests only

# Code Quality
make lint              # Lint shell scripts
make lint-md           # Lint markdown
make format            # Format shell scripts
make check             # Test + lint everything

# Building
make build             # Build installer
make dist              # Create distribution archive
make clean             # Clean build artifacts

# Version Management
make version-bump-patch    # Bump patch version (x.y.Z)
make version-bump-minor    # Bump minor version (x.Y.0)
make version-bump-major    # Bump major version (X.0.0)
make tag                   # Create git tag

# Release
make release           # Full release process
```

### Development Workflow

1. **Clone:** `git clone https://github.com/oehrlis/oradba.git`
2. **Branch:** `git checkout -b feature/your-feature`
3. **Develop:** Make changes, add tests
4. **Test:** `make test-fast` (or `make test` for full suite)
5. **Quality:** `make lint` and `make format`
6. **Commit:** Follow conventional commits
7. **Push:** `git push origin feature/your-feature`
8. **PR:** Create pull request on GitHub

## Contributing to Documentation

### Documentation Standards

- **Markdown Style:**
  - Use ATX-style headers (`#` instead of underlines)
  - One sentence per line for easier diffs and reviews
  - Code blocks must specify language (`bash`, `sql`, etc.)
  - Use tables for structured data
  - Use lists for sequences and options

- **Links:**
  - Internal links use relative paths
  - External links use full URLs with https
  - Check all links work before committing

- **Code Examples:**
  - Must be tested and working
  - Include expected output where helpful
  - Add comments for complex examples

- **Function Headers:**
  - Required for all new functions
  - Follow standardized format (see [src/lib/README.md](../src/lib/README.md))
  - Include Purpose, Args, Returns, Output, Notes

### Adding New Documentation

1. **Create file** in appropriate directory:
   - `doc/` for developer/internal documentation
   - `src/doc/` for user-facing documentation
2. **Add standard header** with title and description
3. **Update relevant README.md** to include link
4. **Ensure all links work**
5. **Validate:** Run `make lint-md`
6. **Include in pull request** with context

### Documentation Types

| Type | Location | Purpose | Audience |
| ---- | -------- | ------- | -------- |
| **Developer Docs** | `doc/` | Architecture, API, internals, contribution guides | Contributors, maintainers |
| **User Docs** | `src/doc/` | Usage guides, troubleshooting, reference | End users, administrators |
| **Library Docs** | `src/lib/README.md` | Function reference, usage examples | Developers, extension authors |
| **Folder READMEs** | Various | Brief overview, file list, navigation | All audiences |
| **Code Comments** | In-line | Implementation details, complex logic | Developers |

## External Resources

- **Main Repository:** <https://github.com/oehrlis/oradba>
- **Issue Tracker:** <https://github.com/oehrlis/oradba/issues>
- **Discussions:** <https://github.com/oehrlis/oradba/discussions>
- **Releases:** <https://github.com/oehrlis/oradba/releases>
- **CI/CD Pipeline:** <https://github.com/oehrlis/oradba/actions>

## Related Documentation

- **[User Documentation](../src/doc/index.md)** - Complete usage guides and reference
- **[Library Documentation](../src/lib/README.md)** - Function reference for all libraries
- **[Project README](../README.md)** - Project overview and quick start
- **[Contributing Guidelines](../CONTRIBUTING.md)** - How to contribute to OraDBA
- **[Changelog](../CHANGELOG.md)** - Complete release history and changes

---

**OraDBA v1.0.0-dev** - Preparing for v1.0.0 Release  
For questions or feedback, open an issue or start a discussion on GitHub.
