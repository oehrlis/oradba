# Extensions

OraDBA supports extensions to add custom functionality without modifying the core
installation. Official extensions are listed below and their documentation is
integrated into this site.

## Official Extensions

??? info "Extension System Overview"
    Extensions are separate packages that integrate with OraDBA to provide additional
    functionality. Each extension:

    - Has its own repository and version numbers
    - Follows the standard OraDBA directory structure (bin/, sql/, rcv/, lib/, etc.)
    - Is automatically discovered when placed parallel to OraDBA installation
    - Has its documentation maintained in its own repository (in `doc/` directory)
    - Documentation is linked here but maintained separately from main OraDBA docs
    
    For details on creating extensions, see the [Extension System Guide](extensions.md).

## Available Extensions

<!-- This section is automatically updated by the documentation build workflow -->
<!-- EXTENSIONS_LIST_START -->
### OraDBA Extension Template

**Repository:** [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)  
**Category:** Development  
**Status:** Active  

Template and example for creating OraDBA extensions

[View Documentation](extensions/oradba_extension/index.md){ .md-button }

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
2. **Add documentation** - Include markdown docs in a `docs/` directory in your repo
3. **Submit a request** - Open an issue or PR to add your extension to the registry
4. **Review process** - Extensions are reviewed for quality and compatibility

### Extension Documentation Requirements

Each extension should provide documentation in its `doc/` directory:

- `index.md` - Overview, installation, quick start
- `configuration.md` - Configuration options and examples
- `reference.md` - Command/script reference
- `changelog.md` - Version history

**Note:** Extension documentation is maintained separately in each extension's
repository and linked from this catalog. It is not included in the main
OraDBA PDF documentation.

See the [Extension Template](https://github.com/oehrlis/oradba_extension) for examples.

## Creating Your Own Extension

See the [Extension System Guide](extensions.md) for detailed instructions on creating custom extensions.
