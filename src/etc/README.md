# Configuration Files

OraDBA configuration files, examples, and rlwrap integration files.

## Overview

This directory contains the configuration hierarchy for OraDBA, including core settings, standard aliases, customer customizations, and SID-specific configurations. It also includes rlwrap configuration files for command-line completion in Oracle tools.

## Configuration Files

| File | Type | Description |
|------|------|-------------|
| [oradba_core.conf](oradba_core.conf) | Core | Base configuration (required) |
| [oradba_standard.conf](oradba_standard.conf) | Standard | Default aliases and functions |
| [oradba_customer.conf.example](oradba_customer.conf.example) | Example | Customer customization template |
| [sid._DEFAULT_.conf](sid._DEFAULT_.conf) | Default | Default SID configuration |
| [sid.ORCL.conf.example](sid.ORCL.conf.example) | Example | SID-specific configuration template |
| [oradba_config.example](oradba_config.example) | Legacy | Old configuration format (deprecated) |
| [oratab.example](oratab.example) | Reference | Sample oratab file |

## rlwrap Files

| File | Description |
|------|-------------|
| [rlwrap_filter_oracle](rlwrap_filter_oracle) | Password masking filter for Oracle tools |
| [rlwrap_sqlplus_completions](rlwrap_sqlplus_completions) | SQL*Plus command completion |
| [rlwrap_rman_completions](rlwrap_rman_completions) | RMAN command completion |
| [rlwrap_lsnrctl_completions](rlwrap_lsnrctl_completions) | lsnrctl command completion |
| [rlwrap_adrci_completions](rlwrap_adrci_completions) | ADRCI command completion |

## Configuration Hierarchy

OraDBA uses a 5-level configuration hierarchy:

```
1. oradba_core.conf          # Core settings (always loaded)
2. oradba_standard.conf      # Standard aliases (always loaded)
3. sid._DEFAULT_.conf        # Default SID settings
4. sid.<SID>.conf            # Specific SID settings (if exists)
5. oradba_customer.conf      # Customer overrides (if exists)
```

### Load Order

When you source `oraenv.sh`:

1. **Core** configuration loaded first
2. **Standard** aliases and functions loaded
3. **Default** SID settings applied
4. **SID-specific** settings override defaults (if file exists)
5. **Customer** settings override everything (if file exists)

This allows progressive customization while maintaining a stable base.

## Usage

### Basic Configuration

OraDBA works out-of-the-box with default configuration. No setup required for basic usage:

```bash
source oraenv.sh FREE
# All standard aliases and functions available
```

### Customer Customization

Create customer configuration for site-specific settings:

```bash
# Copy example template
cp $ORADBA_BASE/etc/oradba_customer.conf.example \
   $ORADBA_BASE/etc/oradba_customer.conf

# Edit customizations
vi $ORADBA_BASE/etc/oradba_customer.conf

# Add custom settings
export ORADBA_LOG_LEVEL="DEBUG"
export ORADBA_CUSTOMIZE_PS1="false"
alias myalias="echo 'Custom alias'"
```

### SID-Specific Configuration

Create configuration for specific database:

```bash
# Copy example template
cp $ORADBA_BASE/etc/sid.ORCL.conf.example \
   $ORADBA_BASE/etc/sid.PRODDB.conf

# Edit SID-specific settings
vi $ORADBA_BASE/etc/sid.PRODDB.conf

# Add settings specific to PRODDB
export ORADBA_NO_PDB_ALIASES="true"
export TNS_ADMIN="/opt/oracle/network/admin"
```

### rlwrap Configuration

rlwrap is automatically used for Oracle tools when available:

```bash
# Install rlwrap
brew install rlwrap    # macOS
apt install rlwrap     # Debian/Ubuntu

# OraDBA automatically configures rlwrap for:
# - SQL*Plus (sqlplus, sqls)
# - RMAN (rman)
# - lsnrctl
# - adrci

# Password filtering is automatic
sqlplus user/pass@db   # Password masked in history
```

## Configuration Variables

### Core Variables (oradba_core.conf)

```bash
ORADBA_VERSION          # OraDBA version
ORADBA_BASE             # Installation directory
ORADBA_LOG_LEVEL        # Logging level (INFO, WARN, ERROR, DEBUG)
ORADBA_BANNER           # Show banner on load (true/false)
```

### Standard Variables (oradba_standard.conf)

```bash
ORADBA_CUSTOMIZE_PS1    # Customize prompt (true/false)
ORADBA_NO_PDB_ALIASES   # Disable PDB aliases (true/false)
ORADBA_COLOR_PROMPT     # Enable colored prompt (true/false)
```

### User Variables (oradba_customer.conf)

Any bash variables, functions, or aliases can be added.

## Examples

### Disable PDB Aliases Globally

```bash
# In oradba_customer.conf
export ORADBA_NO_PDB_ALIASES="true"
```

### Disable PDB Aliases for Specific SID

```bash
# In sid.PRODCDB.conf
export ORADBA_NO_PDB_ALIASES="true"
```

### Custom Logging

```bash
# In oradba_customer.conf
export ORADBA_LOG_LEVEL="DEBUG"
export ORADBA_LOG_FILE="${HOME}/.oradba/oradba.log"
```

### Custom Aliases

```bash
# In oradba_customer.conf
alias mybackup="rman target / @${HOME}/scripts/backup.rman"
alias checklog="tail -100 ${ORACLE_BASE}/diag/rdbms/*/alert_*.log"
```

### Custom Functions

```bash
# In oradba_customer.conf
check_db() {
    sqlplus -s / as sysdba <<EOF
    SELECT name, open_mode FROM v\$database;
    EXIT
EOF
}
```

## oratab Integration

OraDBA uses standard Oracle oratab file:

```bash
# Location
/etc/oratab              # Linux
/var/opt/oracle/oratab   # Solaris

# Format
FREE:/opt/oracle/product/23ai/free:N
ORCL:/opt/oracle/product/19c/dbhome:Y
```

See [oratab.example](oratab.example) for sample entries.

## Documentation

- **[Configuration Guide](../doc/05-configuration.md)** - Complete configuration documentation
- **[Environment Management](../doc/04-environment.md)** - Using oraenv.sh
- **[rlwrap Integration](../doc/11-rlwrap.md)** - rlwrap features and customization
- **[Troubleshooting](../doc/12-troubleshooting.md)** - Common configuration issues

## Development

### Adding Configuration Options

1. Add variable to appropriate configuration file
2. Document variable purpose and default value
3. Update configuration documentation
4. Add validation in `lib/common.sh` if needed
5. Write tests for configuration behavior

### Configuration Best Practices

1. **Use hierarchy** - Place settings at appropriate level
2. **Document changes** - Comment custom settings
3. **Test carefully** - Configuration errors can break environment
4. **Version control** - Track custom configurations
5. **Backup** - Keep backup of working configurations

See [development.md](../../doc/development.md) for coding standards.
