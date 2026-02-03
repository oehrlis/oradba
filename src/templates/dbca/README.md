# DBCA Templates

Oracle Database Configuration Assistant (DBCA) response file templates for automated database creation.

## Overview

This directory contains DBCA response file templates that enable automated, standardized Oracle database creation
with consistent configurations across development, test, and production environments.

## Directory Structure

```text
src/templates/dbca/
├── README.md                           # This file
├── common/
│   └── dbca_common.rsp                # Common parameters reference
├── 19c/
│   ├── dbca_19c_general.rsp          # General purpose 19c
│   ├── dbca_19c_container.rsp        # Container database (CDB)
│   ├── dbca_19c_pluggable.rsp        # Pluggable database (PDB)
│   ├── dbca_19c_dev.rsp              # Development environment
│   ├── dbca_19c_rac.rsp              # RAC database
│   └── dbca_19c_dataguard.rsp        # Data Guard ready
├── 26ai/
│   ├── dbca_26ai_general.rsp         # General purpose 26ai
│   ├── dbca_26ai_container.rsp       # Container database (CDB)
│   ├── dbca_26ai_pluggable.rsp       # Pluggable database (PDB)
│   ├── dbca_26ai_dev.rsp             # Development environment
│   └── dbca_26ai_free.rsp            # Oracle 26ai Free edition
└── custom/
    └── .gitkeep                       # User custom templates
```

## Available Templates

### Oracle 19c

| Template      | File                     | Description                                              |
| ------------- | ------------------------ | -------------------------------------------------------- |
| **general**   | `dbca_19c_general.rsp`   | General purpose database for most production workloads   |
| **container** | `dbca_19c_container.rsp` | Container database (CDB) optimized for multiple PDBs     |
| **pluggable** | `dbca_19c_pluggable.rsp` | Create new pluggable database (PDB) in existing CDB      |
| **dev**       | `dbca_19c_dev.rsp`       | Development database with relaxed settings               |
| **rac**       | `dbca_19c_rac.rsp`       | RAC database for clustered environments                  |
| **dataguard** | `dbca_19c_dataguard.rsp` | Data Guard ready configuration                           |

### Oracle 26ai

| Template      | File                      | Description                                              |
| ------------- | ------------------------- | -------------------------------------------------------- |
| **general**   | `dbca_26ai_general.rsp`   | General purpose database with AI-enhanced features       |
| **container** | `dbca_26ai_container.rsp` | Container database (CDB) optimized for multiple PDBs     |
| **pluggable** | `dbca_26ai_pluggable.rsp` | Create new pluggable database (PDB) in existing CDB      |
| **dev**       | `dbca_26ai_dev.rsp`       | Development database with relaxed settings               |
| **free**      | `dbca_26ai_free.rsp`      | Oracle 26ai Free edition (2GB RAM, 12GB data limits)     |

## Usage

### Using oradba_dbca.sh Script

The `oradba_dbca.sh` helper script provides a convenient command-line interface for creating databases using these templates.

#### Basic Examples

```bash
# Create general purpose 19c database
oradba_dbca.sh --sid ORCL --version 19c

# Create container database with 4GB memory
oradba_dbca.sh --sid ORCL --version 19c --template container --memory 4096

# Create development database
oradba_dbca.sh --sid DEV --version 19c --template dev --memory 1024

# Create 26ai Free edition database
oradba_dbca.sh --sid FREE --version 26ai --template free

# Dry run (generate response file only, don't create database)
oradba_dbca.sh --sid ORCL --version 19c --dry-run

# List available templates
oradba_dbca.sh --show-templates
```

#### Advanced Examples

```bash
# Custom paths and settings
oradba_dbca.sh --sid PROD01 --version 19c --template general \
               --data-dir /u01/oradata/PROD01 \
               --fra-dir /u02/fra/PROD01 \
               --memory 8192 \
               --pdb-name PRODPDB

# Data Guard ready database
oradba_dbca.sh --sid PRIMARY --version 19c --template dataguard \
               --db-unique-name PRIMARY_SITE1 \
               --memory 4096

# Use custom template
oradba_dbca.sh --sid CUSTOM --version 19c \
               --custom-template /path/to/my_custom.rsp
```

#### Command-Line Options

```text
-s, --sid SID              Database SID (required)
-h, --oracle-home PATH     Oracle Home (default: $ORACLE_HOME)
-b, --oracle-base PATH     Oracle Base (default: $ORACLE_BASE)
-v, --version VERSION      Oracle version (19c, 26ai)
-t, --template TYPE        Template type (general, container, pluggable, dev, rac, dataguard, free)
-d, --data-dir PATH        Database files directory
-r, --fra-dir PATH         Fast Recovery Area directory
-m, --memory MB            Total memory in MB (default: 2048)
-c, --charset CHARSET      Character set (default: AL32UTF8)
-n, --ncharset NCHARSET    National charset (default: AL16UTF16)
-p, --pdb-name NAME        PDB name (default: PDB1)
--domain DOMAIN            Database domain (default: auto-detected)
--db-unique-name NAME      Database unique name (for Data Guard)
--sys-password PWD         SYS password (prompted if not provided)
--system-password PWD      SYSTEM password (prompted if not provided)
--custom-template FILE     Use custom response file
--dry-run                  Generate response file but don't create database
--show-templates           List available templates
-q, --quiet                Quiet mode
--help                     Show help
```

### Using DBCA Directly

You can also use the templates directly with DBCA after manual variable substitution.

```bash
# 1. Set environment
export ORACLE_SID=ORCL
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_BASE=/u01/app/oracle

# 2. Copy and customize template
cp src/templates/dbca/19c/dbca_19c_general.rsp /tmp/my_db.rsp

# 3. Edit template - replace all {{VARIABLE}} placeholders
vi /tmp/my_db.rsp

# 4. Create database
$ORACLE_HOME/bin/dbca -silent -createDatabase -responseFile /tmp/my_db.rsp
```

## Template Variables

All templates use the following variable placeholders that must be replaced with actual values:

| Variable                | Description                       | Example                                 |
| ----------------------- | --------------------------------- | --------------------------------------- |
| `{{ORACLE_SID}}`        | Database SID                      | ORCL, DEV01, PROD                       |
| `{{ORACLE_HOME}}`       | Oracle Home path                  | /u01/app/oracle/product/19.0.0/dbhome_1 |
| `{{ORACLE_BASE}}`       | Oracle Base path                  | /u01/app/oracle                         |
| `{{DATA_DIR}}`          | Database files directory          | /u01/app/oracle/oradata/ORCL            |
| `{{FRA_DIR}}`           | Fast Recovery Area                | /u01/app/oracle/fast_recovery_area/ORCL |
| `{{DOMAIN}}`            | Database domain                   | example.com, localdomain                |
| `{{SYS_PASSWORD}}`      | SYS user password                 | (secure password)                       |
| `{{SYSTEM_PASSWORD}}`   | SYSTEM user password              | (secure password)                       |
| `{{PDB_NAME}}`          | Pluggable DB name                 | PDB1, DEVPDB, PRODPDB                   |
| `{{MEMORY_MB}}`         | Total memory (MB)                 | 2048, 4096, 8192                        |
| `{{CHARSET}}`           | Character set                     | AL32UTF8, WE8ISO8859P1                  |
| `{{NCHARSET}}`          | National character set            | AL16UTF16, UTF8                         |
| `{{DB_UNIQUE_NAME}}`    | Database unique name (Data Guard) | PRIMARY_SITE1                           |
| `{{ASM_DISKGROUP}}`     | ASM disk group for data (RAC)     | DATA                                    |
| `{{ASM_FRA_DISKGROUP}}` | ASM disk group for FRA (RAC)      | FRA                                     |
| `{{NODELIST}}`          | Comma-separated node list (RAC)   | node1,node2                             |

## Custom Templates

You can create custom templates tailored to your specific requirements:

### Creating Custom Templates

1. **Copy an existing template** as starting point:

   ```bash
   cp src/templates/dbca/19c/dbca_19c_general.rsp \
      src/templates/dbca/custom/my_custom.rsp
   ```

2. **Modify parameters** as needed:

   - Adjust memory settings
   - Change character sets
   - Modify initialization parameters
   - Add custom INITPARAMS
   - Enable/disable features

3. **Use with oradba_dbca.sh**:

   ```bash
   oradba_dbca.sh --sid MYCDB --version 19c \
                  --custom-template src/templates/dbca/custom/my_custom.rsp
   ```

### Custom Template Best Practices

- Keep custom templates in the `custom/` directory
- Document customizations in template header comments
- Version control custom templates
- Test templates in development before production use
- Follow Oracle naming conventions
- Validate response file syntax before use

## Template Features

### General Purpose Template

- Balanced OLTP/OLAP settings
- Container database with 1 PDB
- Suitable for most production workloads
- Moderate memory allocation (2GB+)
- Archive log mode disabled by default

### Container Template

- Optimized for multiple PDBs (3 by default)
- Higher process limits (500)
- Larger FRA (40GB)
- Resource management for PDBs
- Production-ready configuration

### Development Template

- Relaxed settings for development
- Lower memory footprint (1-2GB)
- Sample schemas included
- Audit trail disabled
- Automatic maintenance disabled
- Single control file

### RAC Template

- ASM storage (not file system)
- Cluster-aware settings
- Archive log mode enabled
- Multiple control files
- Per-node memory allocation

### Data Guard Template

- Archive log mode enabled
- Multiple control files (3)
- Standby redo logs configured
- Data Guard specific init params
- FAL server/client settings

### Free Edition Template (26ai)

- Maximum 2GB RAM
- Maximum 12GB user data
- CPU limited to 2 threads
- Suitable for learning/testing
- Sample schemas included

## Configuration Guidelines

### Memory Recommendations

| Environment            | Recommended Memory |
| ---------------------- | ------------------ |
| Development            | 1024-2048 MB       |
| Test                   | 2048-4096 MB       |
| Production (small)     | 4096-8192 MB       |
| Production (medium)    | 8192-16384 MB      |
| Production (large)     | 16384+ MB          |
| RAC (per node)         | 8192+ MB           |

### Storage Recommendations

| Component              | Minimum | Recommended          |
| ---------------------- | ------- | -------------------- |
| Database files         | 10 GB   | 20+ GB               |
| Fast Recovery Area     | 20 GB   | 2-3x database size   |
| Total disk space       | 30 GB   | 60+ GB               |

### Character Set Guidelines

- **AL32UTF8**: Recommended for new databases (Unicode, maximum compatibility)
- **WE8ISO8859P1**: Western European (ISO 8859-1)
- **WE8MSWIN1252**: Windows Western European
- **AL16UTF16**: National character set (NCHAR/NVARCHAR2)

**Important**: Character set cannot be changed after database creation!

## Best Practices

### Database Creation

1. Always validate prerequisites before creation
2. Ensure sufficient disk space (30GB+ minimum)
3. Use appropriate memory settings for environment
4. Test templates in development first
5. Document customizations
6. Use version control for custom templates

### Security

1. Never commit passwords to version control
2. Use strong passwords for SYS/SYSTEM
3. Change default passwords immediately after creation
4. Enable audit trail for production databases
5. Review and harden initialization parameters
6. Consider Database Vault for sensitive data

### Production Databases

1. Enable archive log mode
2. Configure Fast Recovery Area
3. Create multiple control files in different locations
4. Use ASM storage if available
5. Set appropriate undo retention
6. Enable automatic maintenance tasks
7. Configure Enterprise Manager (if licensed)

### Development Databases

1. Use smaller memory footprint
2. Disable archive log mode
3. Include sample schemas for testing
4. Disable audit trail
5. Use relaxed settings for faster iteration

## Troubleshooting

### Common Issues

**Issue**: DBCA fails with "Insufficient memory"

```text
Solution: Increase memory allocation with --memory option
Example: --memory 4096
```

**Issue**: Database already exists

```text
Solution: Choose different SID or clean up existing database
Check: $ORACLE_HOME/dbs/init${ORACLE_SID}.ora
Check: /etc/oratab for existing entries
```

**Issue**: Disk space insufficient

```text
Solution: Free up disk space or use different directories
Check: df -h /u01/app/oracle/oradata
```

**Issue**: Template not found

```text
Solution: List available templates with --show-templates
Verify version and template combination is valid
```

**Issue**: Permission denied creating directories

```text
Solution: Ensure proper permissions on parent directories
Run as oracle user (not root)
```

### Log Locations

- **OraDBA logs**: Check `$ORADBA_LOG_DIR/oradba.log`
- **DBCA logs**: Check `$ORACLE_BASE/cfgtoollogs/dbca/${ORACLE_SID}/`
- **Database alert log**: Check `$ORACLE_BASE/diag/rdbms/${ORACLE_SID}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log`

## Version-Specific Notes

### Oracle 19c

- Long-term support release
- All templates tested and validated
- CDB/PDB architecture standard
- Data Guard template includes all required parameters
- RAC template requires Oracle Clusterware

### Oracle 26ai

- Latest release with AI-enhanced features
- Free edition available with 2GB RAM limit
- Enhanced container database capabilities
- AI-optimized initialization parameters
- Compatible with existing 19c infrastructure

## References

- [Oracle DBCA Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/creating-and-configuring-an-oracle-database-using-dbca.html)
- [Oracle Database Installation Guide](https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/index.html)
- [Oracle Initialization Parameters Reference](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/initialization-parameters-2.html)
- [Oracle Maximum Availability Architecture](https://www.oracle.com/database/technologies/high-availability/maa.html)

## Support

For issues or questions:

- GitHub Issues: [oehrlis/oradba/issues](https://github.com/oehrlis/oradba/issues)
- Documentation: [OraDBA Documentation](https://oehrlis.github.io/oradba/)

## License

Apache License Version 2.0, January 2004
See LICENSE file in repository root.
