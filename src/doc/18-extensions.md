# Extension System

The OraDBA extension system allows you to add custom scripts and tools without modifying
the core OraDBA installation. Extensions are automatically discovered and integrated into
your environment.

## What are Extensions?

Extensions are directories parallel to your OraDBA installation that contain custom:

- **Scripts** (`bin/`) - Added to PATH automatically
- **SQL Scripts** (`sql/`) - Added to SQLPATH for SQL*Plus
- **RMAN Scripts** (`rcv/`) - Available for RMAN operations
- **Configuration** (`etc/`) - Example configurations
- **Libraries** (`lib/`) - Shared bash libraries

## Quick Start

### Creating an Extension

1. **Create extension directory**:

   ```bash
   mkdir -p /opt/oracle/local/customer/bin
   mkdir -p /opt/oracle/local/customer/sql
   ```

2. **Add your scripts**:

   ```bash
   # Add a custom database script
   cat > /opt/oracle/local/customer/bin/check_db.sh << 'EOF'
   #!/usr/bin/env bash
   echo "Custom database check for ${ORACLE_SID}"
   sqlplus -s / as sysdba << SQL
   SELECT name, open_mode FROM v\$database;
   SQL
   EOF
   
   chmod +x /opt/oracle/local/customer/bin/check_db.sh
   ```

3. **Source OraDBA environment**:

   ```bash
   source oraenv.sh FREE
   # Extension is auto-discovered and loaded
   
   check_db.sh  # Your script is now in PATH
   ```

### Optional: Add Metadata

Create a `.extension` file for better tracking:

```bash
cat > /opt/oracle/local/customer/.extension << 'EOF'
name: customer
version: 1.0.0
priority: 10
author: DBA Team
description: Customer-specific Oracle tools and scripts
EOF
```

## Extension Discovery

OraDBA automatically discovers extensions in `${ORADBA_LOCAL_BASE}` (typically
`/opt/oracle/local`). Extensions are identified by:

1. **Metadata file**: Directories with `.extension` file
2. **Content directories**: Directories with `bin/`, `sql/`, or `rcv/` subdirectories

The core OraDBA installation (`/opt/oradba`) is excluded from discovery.

## Managing Extensions

Use the `oradba_extension.sh` command-line tool:

### List Extensions

```bash
# Show all extensions
oradba_extension.sh list

# NAME                 VERSION      PRIORITY   STATUS
# ----                 -------      --------   ------
# customer             1.0.0        10         Enabled
# monitoring           2.1.0        20         Enabled

# Show detailed information
oradba_extension.sh list --verbose
```

### Show Extension Information

```bash
oradba_extension.sh info customer

# Extension Information
# =====================
# Name:        customer
# Version:     1.0.0
# Enabled:     yes
# Priority:    10
# Path:        /opt/oracle/local/customer
# ...
```

### Validate Extensions

```bash
# Validate specific extension
oradba_extension.sh validate customer

# Validate all extensions
oradba_extension.sh validate-all
```

### Other Commands

```bash
# Show auto-discovered extensions
oradba_extension.sh discover

# Display search paths
oradba_extension.sh paths

# List only enabled extensions
oradba_extension.sh enabled

# List only disabled extensions
oradba_extension.sh disabled
```

## Priority and Load Order

Extensions support priority-based loading (lower number = higher priority):

```bash
# In .extension file
priority: 10
```

Extensions are loaded in PATH as:

1. Core OraDBA (`${ORADBA_BIN}`)
2. Extensions (by priority: 10, 20, 30, ...)
3. Oracle Home (`${ORACLE_HOME}/bin`)
4. System PATH

This ensures:

- OraDBA core commands are always available
- High-priority extensions can override Oracle tools
- Low-priority extensions don't interfere with core functionality

## Configuration

### Enable/Disable Extensions

In `oradba_customer.conf`:

```bash
# Disable specific extension
export ORADBA_EXT_CUSTOMER_ENABLED="false"

# Enable extension (default)
export ORADBA_EXT_CUSTOMER_ENABLED="true"
```

### Override Priority

```bash
# Change priority (lower = higher priority)
export ORADBA_EXT_CUSTOMER_PRIORITY="5"
```

### Manual Extension Paths

```bash
# Add extensions not in ORADBA_LOCAL_BASE
export ORADBA_EXTENSION_PATHS="/data/ext1:/opt/custom/ext2"
```

### Disable Auto-Discovery

```bash
# Disable auto-discovery (use only manual paths)
export ORADBA_AUTO_DISCOVER_EXTENSIONS="false"
```

## Extension Structure

### Minimal Extension

```text
/opt/oracle/local/customer/
└── bin/
    └── my_script.sh
```

### Complete Extension

```text
/opt/oracle/local/customer/
├── .extension              # Metadata (optional)
├── README.md              # Documentation (recommended)
├── bin/                   # Executable scripts (added to PATH)
│   ├── tool1.sh
│   └── tool2.sh
├── sql/                   # SQL scripts (added to SQLPATH)
│   ├── query1.sql
│   └── query2.sql
├── rcv/                   # RMAN scripts (ORADBA_RCV_PATHS)
│   └── backup.rman
├── etc/                   # Configuration examples
│   └── config.example
└── lib/                   # Shared libraries
    └── functions.sh
```

## Navigation Aliases

OraDBA creates navigation aliases for each extension:

```bash
# If extension name is "customer"
cdecustomer              # cd to extension directory

# If extension name is "monitoring"
cdemonitoring           # cd to monitoring extension
```

## Best Practices

1. **Use Metadata Files**: Always create `.extension` for version tracking
2. **Document Your Extensions**: Include README.md with usage instructions
3. **Version Control**: Keep extensions in version control (git)
4. **Test Validation**: Run `oradba_extension.sh validate` before deployment
5. **Avoid Core Conflicts**: Don't override core OraDBA commands
6. **Use Unique Names**: Choose distinctive script names to avoid conflicts
7. **Log Appropriately**: Extensions share `${ORADBA_LOG}` by default
8. **Provide Configuration Examples**: Use `etc/` for config templates

## Examples

### Database Monitoring Extension

```bash
mkdir -p /opt/oracle/local/monitoring/{bin,sql}

# Add monitoring script
cat > /opt/oracle/local/monitoring/bin/check_tablespaces.sh << 'EOF'
#!/usr/bin/env bash
sqlplus -s / as sysdba @${ORADBA_LOCAL_BASE}/monitoring/sql/tablespaces.sql
EOF

# Add SQL query
cat > /opt/oracle/local/monitoring/sql/tablespaces.sql << 'EOF'
SET PAGESIZE 100 LINESIZE 200
SELECT tablespace_name, 
       ROUND(used_space*8192/1024/1024,2) used_mb,
       ROUND(tablespace_size*8192/1024/1024,2) size_mb,
       ROUND(used_percent,2) pct_used
FROM dba_tablespace_usage_metrics
ORDER BY pct_used DESC;
EOF

chmod +x /opt/oracle/local/monitoring/bin/check_tablespaces.sh
```

### Backup Extension

```bash
mkdir -p /opt/oracle/local/backup/{bin,rcv}

# Add backup script
cat > /opt/oracle/local/backup/bin/backup_db.sh << 'EOF'
#!/usr/bin/env bash
rman target / @${ORADBA_LOCAL_BASE}/backup/rcv/level0.rman
EOF

# Add RMAN script
cat > /opt/oracle/local/backup/rcv/level0.rman << 'EOF'
RUN {
  BACKUP DATABASE PLUS ARCHIVELOG;
  DELETE NOPROMPT OBSOLETE;
}
EOF

chmod +x /opt/oracle/local/backup/bin/backup_db.sh
```

## Troubleshooting

### Extension Not Found

**Problem**: Extension doesn't appear in `oradba_extension.sh list`

**Solutions**:

1. Check directory location:

   ```bash
   ls -la ${ORADBA_LOCAL_BASE}
   ```

2. Verify content directories exist:

   ```bash
   ls -la /opt/oracle/local/customer/bin
   ```

3. Check discovery setting:

   ```bash
   echo ${ORADBA_AUTO_DISCOVER_EXTENSIONS}
   ```

### Scripts Not in PATH

**Problem**: Extension scripts not available after sourcing oraenv

**Solutions**:

1. Verify files are executable:

   ```bash
   chmod +x /opt/oracle/local/customer/bin/*.sh
   ```

2. Check PATH includes extension:

   ```bash
   echo ${PATH} | tr ':' '\n' | grep customer
   ```

3. Source oraenv again:

   ```bash
   source oraenv.sh ${ORACLE_SID}
   ```

### Priority Issues

**Problem**: Wrong extension loads first

**Solution**: Set priority explicitly:

```bash
# In oradba_customer.conf
export ORADBA_EXT_IMPORTANT_PRIORITY="5"   # Loads last (appears first in PATH)
export ORADBA_EXT_OTHER_PRIORITY="50"      # Loads first (appears later in PATH)
```

## See Also {.unlisted .unnumbered}

- **[Extension System Documentation](https://github.com/oehrlis/oradba/blob/main/doc/extension-system.md)** -
  Complete technical reference
- **[Example Extension](https://github.com/oehrlis/oradba/tree/main/doc/examples/extensions/customer)** -
  Reference implementation
- **[Configuration Guide](05-configuration.md)** - Configuration hierarchy
- **[Troubleshooting](12-troubleshooting.md)** - General troubleshooting

---

**Next Chapter**: [Usage Guide](16-usage.md) | **Previous Chapter**: [Service Management](17-service-management.md)
