<!-- markdownlint-disable MD013 -->
# Developer Documentation

Welcome to the OraDBA developer documentation. This directory contains technical documentation for contributors, maintainers, and developers working on the OraDBA v0.19.0+ project.

**Audience:** Project contributors, developers extending OraDBA, maintainers

**For Users:** See [User Documentation](../src/doc/index.md) for usage guides and reference materials.

## Quick Navigation

| Category               | Document                                     | Status      | Description                                         |
|------------------------|----------------------------------------------|-------------|-----------------------------------------------------|
| **Getting Started**    | [development.md](development.md)             | ✅ Current  | Complete development guide - setup, workflow, CI/CD |
| **Architecture**       | [architecture.md](architecture.md)           | ✅ Current  | Registry API, Plugin System, v0.19.0+ architecture  |
| **API Reference**      | [api.md](api.md)                             | ✅ Current  | Registry API, Plugin Interface, core libraries      |
| **Extension System**   | [extension-system.md](extension-system.md)   | ⏳ Review   | Extension development guide and API                 |
| **Testing**            | [automated_testing.md](automated_testing.md) | ⏳ Review   | Automated testing guide and framework               |
| **Testing**            | [manual_testing.md](manual_testing.md)       | ⏳ Review   | Manual testing procedures                           |
| **Environment Design** | [oradba-env-design.md](oradba-env-design.md) | 📚 Archive  | Original design document (historical reference)     |
| **Archive**            | [archive/](archive/)                         | 📚          | Historical docs, completed plans, legacy references |
| **Diagrams**           | [images/](images/)                           | ✅          | Mermaid diagrams (Registry API, Plugin System)      |

## Key Changes in v0.19.0+

**Registry API** - Unified interface for all Oracle installations (oratab + oradba_homes.conf)  
**Plugin System** - 6 product-specific plugins (database, datasafe, client, iclient, oud, java)  
**Environment Libraries** - Parser, Builder, Validator, Config, Status, Changes  
**No Backward Compatibility** - Clean architecture without legacy basenv coexistence

See [architecture.md](architecture.md) for complete details.

## Getting Started

New to OraDBA development? Start here:

1. **[development.md](development.md)** - Read the complete development guide

   - Quick start for developers
   - v0.19.0+ architecture overview (Registry API, Plugin System, Environment Libraries)
   - Plugin development guide with 8-function template
   - Project structure with all 6 plugins
   - Testing framework (108+ plugin tests, 900+ core tests)
   - CI/CD pipeline and workflows
   - Code quality standards

2. **[architecture.md](architecture.md)** - Understand the system design

   - Registry API - Unified interface for all Oracle installations
   - Plugin System - 6 product-specific plugins with standard interface
   - Environment Management Libraries - Parser, Builder, Validator, Config, Status, Changes
   - Data flow diagrams (Mermaid)
   - Design principles and patterns

3. **[api.md](api.md)** - Learn the API
   - Registry API functions (get_all, get_by_name, get_by_type, get_by_home, get_status, validate_entry)
   - Plugin Interface (8 required functions per plugin)
   - Core utility functions
   - Database operation helpers

## Core Documentation

### Development & Workflow

**[development.md](development.md)** - Complete development guide

- **Architecture**: Registry API, Plugin System (6 plugins), Environment Libraries
- **Plugin Development**: 8-function interface, detection, validation, metadata extraction
- **Project Structure**: All 6 plugins (database, datasafe, client, iclient, oud, java)
- **Testing**: 108+ plugin tests, 900+ core tests, 68 Docker integration tests
- **Smart Test Selection**: ~1-3 min during development, ~8-10 min full suite
- **CI/CD Pipeline**: GitHub Actions with automated testing and release
- **Configuration**: 6-level hierarchical system
- **Make Targets**: test, test-full, test-docker, lint, build, ci, pre-commit

**Quick development cycle:**

```bash
# Clone and setup
git clone https://github.com/oehrlis/oradba.git
cd oradba

# Development
make test              # Smart test selection (~1-3 min)
make lint              # Lint shell + markdown
make pre-commit        # Smart tests + lint (~2-4 min)

# Building
make build             # Build installer
make test-full         # Full test suite (~8-10 min)
make ci                # Complete CI pipeline (~10-15 min)
```

### Architecture & Design

**[architecture.md](architecture.md)** - v0.19.0+ System Architecture

- **Registry API**: Unified access to oratab + oradba_homes.conf
  - Auto-synchronization of database entries
  - Colon-delimited output format
  - 6 core functions for all operations
- **Plugin System**: 6 product-specific plugins
  - database_plugin.sh (16 tests) - Oracle Database
  - datasafe_plugin.sh (17 tests) - Data Safe On-Premises Connector
  - client_plugin.sh (12 tests) - Oracle Full Client
  - iclient_plugin.sh (15 tests) - Oracle Instant Client
  - oud_plugin.sh (15 tests) - Oracle Unified Directory
  - java_plugin.sh (22 tests) - Java JDK/JRE
  - 8-function standard interface
- **Environment Management Libraries**: 6 specialized libraries
- **Data Flow**: Mermaid diagram showing Registry API integration
- **Design Principles**: Modularity, testability, extensibility

**[oradba-env-design.md](oradba-env-design.md)** - Historical Design Document

- Original environment library design rationale
- Parser, Builder, Validator, Config Manager patterns
- Implementation details and testing strategies
- **Status**: Archived for reference, see architecture.md for current design

### Technical Reference

**[api.md](api.md)** - Complete API Documentation

- **Registry API** (oradba_registry.sh)
  - `oradba_registry_get_all` - Get all Oracle installations
  - `oradba_registry_get_by_name` - Get by NAME (SID or home name)
  - `oradba_registry_get_by_type` - Get by product type
  - `oradba_registry_get_by_home` - Get by ORACLE_HOME path
  - `oradba_registry_get_status` - Check service status
  - `oradba_registry_validate_entry` - Validate entry
- **Plugin Interface** (8 required functions)
  - `plugin_detect_installation` - Auto-discover installations
  - `plugin_validate_home` - Validate ORACLE_HOME
  - `plugin_adjust_environment` - Adjust PATH/environment
  - `plugin_check_status` - Check service status
  - `plugin_get_metadata` - Extract version/edition
  - `plugin_should_show_listener` - Show listener status?
  - `plugin_discover_instances` - Find instances
  - `plugin_supports_aliases` - Generate aliases?
- **Core Utilities**: Logging, PATH management, database operations
- **Environment Management Libraries**: Parser, Builder, Validator, Config, Status, Changes

**[extension-system.md](extension-system.md)** - Extension Development

- Extension framework overview
- Extension structure and metadata (.extension file)
- Lifecycle and configuration management
- Creating custom extensions
- Testing and debugging
- Integration examples

## Diagrams

**[images/registry-api-flow.md](images/registry-api-flow.md)** - Registry API Data Flow (Mermaid)  
Complete flowchart showing unified access to oratab and oradba_homes.conf, auto-sync, plugin integration, and Registry consumers.

**[images/plugin-system.md](images/plugin-system.md)** - Plugin System Overview (Mermaid)  
Shows all 6 plugins, discovery mechanism, and 8-function interface.

Additional diagrams embedded in [development.md](development.md):

- CI/CD Pipeline
- Testing Strategy

## Testing & Release

**Current Test Coverage:**

- **Plugin Tests**: 108+ tests across 6 plugins
  - database (16), datasafe (17), client (12), iclient (15), oud (15), java (22)
  - Common interface validation (24 tests)
- **Core Tests**: 900+ tests for core functionality
- **Docker Integration**: 68 tests against real Oracle 26ai Free database
- **Total**: 1000+ tests with ~98% pass rate

**Testing Workflow:**

```bash
make test              # Smart selection (~1-3 min) - development
make test-full         # All tests (~8-10 min) - before commits
make test-docker       # Docker integration (~3 min)
make pre-commit        # Smart + lint (~2-4 min) - pre-commit hook
make ci                # Full pipeline (~10-15 min) - before releases
```

**[release-testing-checklist.md](release-testing-checklist.md)** - Pre-release Testing

- Installation testing (multiple platforms)
- Core functionality verification
- Plugin system testing (all 6 plugins)
- Configuration system testing
- Documentation validation
- Upgrade testing
  - Phase 4: Code Quality & Standards ✅
  - Phase 5: CHANGELOG Consolidation ✅
- Phase 6: README & Main Docs ⏳ **IN PROGRESS**
- Phase 7-9: Pre-Release Testing → Version Prep → Release & Announce

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

- **Version:** v1.0.0-dev (Phase 6 of 9 - README & Main Docs in progress)
- **Last Stable Release:** v0.18.5
- **Architecture:** Modular library system (6 environment libraries + 3 core utilities + 1 extension framework)
- **Functions:** 133 total (47 environment + 66 core + 20 extension)
- **Lines of Code:** ~10,500 (library code)
- **Tests:** 1082 BATS tests across 65 test files, 100% pass rate (1041 passed, 41 skipped integration tests)
- **Test Framework:** BATS (Bash Automated Testing System)
- **CI/CD:** GitHub Actions with smart test selection
- **Code Quality:** Shellcheck clean (0 errors, 0 warnings), shfmt formatted
- **Documentation:** 3,000+ lines of user and developer documentation
- **Versioning:** Semantic Versioning 2.0.0

## Library Organization

OraDBA v1.0.0 is built on a modular library architecture:

1. **Environment Management Libraries** (oradba_env_*): 6 libraries, 47 functions
   - Modern environment configuration system
   - Parser → Builder → Validator → Config → Status → Changes

2. **Core Utility Libraries**: 3 libraries, 66 functions
   - oradba_common.sh, oradba_db_functions.sh, oradba_aliases.sh
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
