# OraDBA Extension Templates

This directory contains ready-to-use extension templates that can be extracted to create custom OraDBA extensions.

## Available Templates

### customer-extension-template.tar.gz

A complete example extension demonstrating the OraDBA extension system.

**Contents:**

- `customer/bin/` - Example executable scripts (auto-added to PATH)
- `customer/etc/` - Configuration files
- `customer/sql/` - SQL scripts (auto-added to SQLPATH)
- `customer/rcv/` - RMAN scripts (auto-discoverable)
- `customer/.extension` - Metadata file
- `customer/README.md` - Documentation

## Quick Start

### 1. Extract Template

Extract to your local extensions directory:

```bash
# Extract to default location
cd ${ORADBA_LOCAL_BASE}
tar xzf ${ORADBA_BASE}/templates/extensions/customer-extension-template.tar.gz

# Or extract to custom location
mkdir -p /opt/oracle/local
cd /opt/oracle/local
tar xzf ${ORADBA_BASE}/templates/extensions/customer-extension-template.tar.gz
```

### 2. Customize

Rename and modify the extension:

```bash
cd ${ORADBA_LOCAL_BASE}
mv customer mycompany

# Edit metadata
vim mycompany/.extension

# Edit configuration
vim mycompany/etc/customer.conf.example
mv mycompany/etc/customer.conf.example mycompany/etc/mycompany.conf

# Customize scripts
vim mycompany/bin/customer_tool.sh
```

### 3. Activate

The extension will be auto-discovered on next environment load:

```bash
# Reload environment
source ${ORADBA_BASE}/bin/oraenv.sh ${ORACLE_SID}

# Verify extension loaded
oradba_extension.sh list

# Extension scripts are now in PATH
which customer_tool.sh
```

## Extension Structure

```text
myextension/
├── .extension                  # Metadata (optional but recommended)
│   ├── name=myextension
│   ├── version=1.0.0
│   └── description=...
├── README.md                   # Documentation
├── bin/                        # Executables (added to PATH)
│   └── mytool.sh
├── etc/                        # Configuration files
│   └── myconfig.conf
├── sql/                        # SQL scripts (added to SQLPATH)
│   └── myquery.sql
└── rcv/                        # RMAN scripts
    └── mybackup.rman
```

## Extension Discovery

OraDBA automatically discovers extensions in:

1. `${ORADBA_LOCAL_BASE}/` - Local extensions (default: `/opt/oracle/local/`)
2. `${ORADBA_PREFIX}/extensions/` - System-wide extensions

**Discovery rules:**

- Looks for directories with `bin/`, `sql/`, `rcv/`, or `etc/` subdirectories
- Reads `.extension` metadata file if present
- Skips hidden directories (starting with `.`)
- Processes in alphabetical order

## Managing Extensions

```bash
# List all extensions
oradba_extension.sh list

# Show detailed info
oradba_extension.sh info customer

# Show loaded paths
echo $PATH
echo $SQLPATH
```

## Creating Extensions from Scratch

Instead of using the template, you can create extensions manually:

```bash
# Create structure
mkdir -p ${ORADBA_LOCAL_BASE}/myext/{bin,etc,sql,rcv}

# Create metadata
cat > ${ORADBA_LOCAL_BASE}/myext/.extension <<EOF
name=myext
version=1.0.0
description=My custom extension
author=Your Name
EOF

# Add your scripts
vim ${ORADBA_LOCAL_BASE}/myext/bin/mytool.sh
chmod +x ${ORADBA_LOCAL_BASE}/myext/bin/mytool.sh

# Reload environment
source ${ORADBA_BASE}/bin/oraenv.sh
```

## Packaging Extensions

To distribute your extension:

```bash
# Create tarball
cd ${ORADBA_LOCAL_BASE}
tar czf myext-1.0.0.tar.gz myext/

# Users can extract it
tar xzf myext-1.0.0.tar.gz -C ${ORADBA_LOCAL_BASE}/
```

## Best Practices

1. **Use .extension metadata** - Helps document and version your extension
2. **Include README.md** - Document what your extension does and how to use it
3. **Follow naming conventions** - Use descriptive, unique names
4. **Version your extensions** - Track changes and compatibility
5. **Test in isolation** - Ensure scripts work without depending on other extensions
6. **Use configuration files** - Keep settings separate from code
7. **Document dependencies** - Note any required tools or Oracle versions

## Examples

See `doc/examples/extensions/` in the OraDBA repository for complete working examples.

## Documentation

For more information about the extension system:

- [Extension System Guide](../../doc/extension-system.md)
- [API Documentation](../../doc/api.md#extension-system)
- User Guide: `oradba help extensions`

## Support

- GitHub: <https://github.com/oehrlis/oradba>
- Documentation: <https://code.oradba.ch/oradba>
- Issues: <https://github.com/oehrlis/oradba/issues>
