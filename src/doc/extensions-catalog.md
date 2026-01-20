# Extensions Catalog

**Purpose:** Catalog of available OraDBA v0.19.x extensions with links to their repositories.

**Audience:** Users looking to extend OraDBA functionality.

OraDBA v0.19.x supports extensions to add custom functionality without modifying the core installation. Official extensions are listed below with links to their documentation in their respective GitHub repositories.

All extensions work with OraDBA's Registry API and Plugin System, supporting databases and other Oracle product types.

## Official Extensions

??? info "Extension System Overview"
    Extensions are separate packages that integrate with OraDBA v0.19.x to provide additional
    functionality. Each extension:

    - Has its own repository and version numbers
    - Follows the standard OraDBA directory structure (bin/, sql/, rcv/, lib/, etc.)
    - Is automatically discovered when placed parallel to OraDBA installation
    - Works with the Registry API and Plugin System
    - Maintains its own documentation in its GitHub repository
    - Can be installed using the OraDBA extension management tools
    
    For details on creating extensions, see the [Extension System Guide](extensions.md).

## Available Extensions

<!-- This section is automatically updated by the documentation build workflow -->
<!-- EXTENSIONS_LIST_START -->
### OraDBA Extension Template

**Repository:** [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)  
**Category:** Development  
**Status:** Active  

Template and example for creating OraDBA extensions

[View Documentation](https://github.com/oehrlis/oradba_extension#readme){ .md-button }

### OraDBA Data Safe Extension

**Repository:** [oehrlis/odb_datasafe](https://github.com/oehrlis/odb_datasafe)  
**Category:** Operations  
**Status:** Active  

Tools for managing Oracle Data Safe targets in OCI with simplified CLI and comprehensive logging

[View Documentation](https://github.com/oehrlis/odb_datasafe#readme){ .md-button }

### OraDBA AutoUpgrade Extension

**Repository:** [oehrlis/odb_autoupgrade](https://github.com/oehrlis/odb_autoupgrade)  
**Category:** Operations  
**Status:** Active  

Oracle AutoUpgrade wrapper scripts with ready-to-use configs for database upgrades

[View Documentation](https://github.com/oehrlis/odb_autoupgrade#readme){ .md-button }

<!-- EXTENSIONS_LIST_END -->

## Contributing Extensions

To have your extension listed here:

1. **Follow the structure** - Use the standard OraDBA extension layout
2. **Add documentation** - Include markdown docs in your repository's README
3. **Submit a request** - Open an issue or PR to add your extension to this catalog
4. **Review process** - Extensions are reviewed for quality and compatibility

### Extension Documentation

Each extension maintains its own documentation in its GitHub repository. At minimum,
the README should include:

- Overview and features
- Installation instructions
- Configuration options
- Usage examples and command reference
- Changelog and version history

See the [Extension Template](https://github.com/oehrlis/oradba_extension) for a
complete example with comprehensive documentation structure.

## Creating Your Own Extension

See the [Extension System Guide](extensions.md) for detailed instructions on creating custom extensions.
