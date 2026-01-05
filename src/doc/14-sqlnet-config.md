<!-- markdownlint-disable MD036 -->
# SQL*Net Configuration

**Purpose:** Guide to managing Oracle SQL*Net configuration using OraDBA templates and tools.

**Audience:** DBAs configuring Oracle network connectivity.

**Prerequisites:**

- TNS_ADMIN directory configured
- Appropriate permissions to modify network configuration files

## Overview

This chapter covers managing Oracle SQL*Net configuration using OraDBA templates
and tools for sqlnet.ora, tnsnames.ora, and ldap.ora files.

OraDBA provides comprehensive SQL*Net configuration templates and management tools
to simplify Oracle network setup, improve security, and ensure consistent
configurations across environments.

## Quick Start

### Install Basic Configuration

For development or test environments:

```bash
# Install basic sqlnet.ora
oradba_sqlnet.sh --install basic

# Validate configuration
oradba_sqlnet.sh --validate
```

### Install Secure Configuration

For production environments:

```bash
# Install secure sqlnet.ora with encryption
oradba_sqlnet.sh --install secure

# Validate configuration
oradba_sqlnet.sh --validate
```

### Add Database Connection

```bash
# Generate tnsnames entry for your database
oradba_sqlnet.sh --generate PRODDB

# Test the connection
oradba_sqlnet.sh --test PRODDB

# List all TNS aliases
oradba_sqlnet.sh --list
```

## Centralized TNS_ADMIN Setup

OraDBA v0.2.0+ supports centralized SQL*Net configuration management, particularly useful for:

- **Multiple Oracle Homes** - Manage configurations independently per database
- **Read-Only Oracle Homes** - Oracle 18c+ feature with logically read-only ORACLE_HOME
- **Simplified Administration** - Single location for all SQL*Net configurations
- **Better Logging** - Separate log/trace directories per database

### Understanding Read-Only Oracle Homes

Oracle 18c introduced the read-only Oracle Home feature, where:

- `ORACLE_HOME` is logically read-only (configuration immutable)
- `ORACLE_BASE_HOME` stores writable Oracle Home files
- `ORACLE_BASE_CONFIG` stores configuration files
- Use `orabasehome` command to detect mode:
  - If output = `$ORACLE_HOME` → Read-Write mode
  - If output = `$ORACLE_BASE/homes/HOME_NAME` → Read-Only mode

```bash
# Check if Oracle Home is read-only
cd $ORACLE_HOME/bin
./orabasehome
# Output: /u01/app/oracle/homes/OraDB19Home1 (read-only mode)
# Output: /u01/app/oracle/product/19c/dbhome_1 (read-write mode)
```

**Note:** If `orabasehome` command doesn't exist, your Oracle version doesn't support read-only homes.

### Centralized Structure

OraDBA creates this directory structure:

```text
$ORACLE_BASE/network/
├── SID1/
│   ├── admin/       # Configuration files (sqlnet.ora, tnsnames.ora, etc.)
│   ├── log/         # SQL*Net client logs
│   └── trace/       # SQL*Net client traces
├── SID2/
│   ├── admin/
│   ├── log/
│   └── trace/
└── ...
```

### Setup Single Database

```bash
# Setup centralized TNS_ADMIN for specific database
oradba_sqlnet.sh --setup PRODDB
```

This will:

1. Create directory structure: `$ORACLE_BASE/network/PRODDB/{admin,log,trace}`
2. Migrate existing files from `$ORACLE_HOME/network/admin`:
   - sqlnet.ora
   - tnsnames.ora
   - ldap.ora
   - listener.ora (if exists)
3. Backup original files with timestamp
4. Create symlinks in `$ORACLE_HOME/network/admin` → centralized location
5. Update sqlnet.ora with correct LOG_DIRECTORY and TRACE_DIRECTORY paths

### Setup All Databases

```bash
# Setup centralized TNS_ADMIN for all databases in /etc/oratab
oradba_sqlnet.sh --setup-all
```

Processes all databases defined in `/etc/oratab`, creating centralized structures for each.

### Benefits

**For Read-Only Homes:**

- Configuration stored outside ORACLE_HOME (required)
- Complies with Oracle 18c+ architecture
- Enables patching without configuration impact

**For Multiple Homes:**

- Independent configurations per database
- No configuration conflicts
- Easier troubleshooting (separate logs per database)

**For All Environments:**

- Centralized backup location
- Simplified configuration management
- Clear separation: code vs. configuration
- Version control friendly (config outside ORACLE_HOME)

### Environment Variables

After setup, set TNS_ADMIN in your profile:

```bash
# In .bash_profile or similar
export ORACLE_SID=PRODDB
export TNS_ADMIN=$ORACLE_BASE/network/$ORACLE_SID/admin
```

Or source OraDBA environment scripts which set TNS_ADMIN automatically.

## Available Templates

### sqlnet.ora Templates

#### Basic Template

**File:** `sqlnet.ora.basic`  
**Use Case:** Development and test environments

Features:

- TNSNAMES, EZCONNECT, and HOSTNAME naming methods
- Basic timeout settings (60s inbound, 120s outbound)
- ADR diagnostics enabled
- Dead connection detection (10 minutes)
- Commented wallet configuration

Example content:

```text
NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)
DIAG_ADR_ENABLED = ON
SQLNET.EXPIRE_TIME = 10
SQLNET.INBOUND_CONNECT_TIMEOUT = 60
SQLNET.OUTBOUND_CONNECT_TIMEOUT = 120
```

#### Secure Template

**File:** `sqlnet.ora.secure`  
**Use Case:** Production environments requiring encryption

Features:

- **Network Encryption:** AES256/192/128 (REQUIRED)
- **Data Integrity:** SHA256/384/512 checksums (REQUIRED)
- **Authentication:** TCPS and BEQ support
- **Security:** Case-sensitive logon, minimum Oracle 12c
- **Wallet:** Pre-configured for credential storage

Example content:

```text
SQLNET.ENCRYPTION_CLIENT = REQUIRED
SQLNET.ENCRYPTION_SERVER = REQUIRED
SQLNET.ENCRYPTION_TYPES_CLIENT = (AES256, AES192, AES128)
SQLNET.CRYPTO_CHECKSUM_CLIENT = REQUIRED
SQLNET.CRYPTO_CHECKSUM_SERVER = REQUIRED
```

**Important:** Network encryption requires Oracle Advanced Security license.

### tnsnames.ora Template

**File:** `tnsnames.ora.template`  
**Use Case:** Connection descriptor examples

Includes examples for:

1. **Basic Connection**

   ```text
   ORCL =
     (DESCRIPTION =
       (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
       (CONNECT_DATA =
         (SERVER = DEDICATED)
         (SERVICE_NAME = orcl)
       )
     )
   ```

2. **Failover Configuration**
   - Automatic failover to secondary node
   - Configurable retry count and delay
   - TYPE = SELECT for session failover

3. **Load Balancing**
   - Distributes connections across multiple nodes
   - LOAD_BALANCE = ON
   - Multiple ADDRESS entries

4. **Secure TCPS Connection**
   - SSL/TLS encryption (port 2484)
   - Certificate DN validation
   - Production security

5. **PDB Connection**
   - Connect directly to pluggable database
   - SERVICE_NAME = pdb_name

6. **RAC Connection**
   - SCAN listener address
   - High availability setup

7. **Connection Pooling**
   - SERVER = POOLED
   - Connection class specification

8. **Data Guard Standby**
   - Connect to standby database
   - Separate service name

9. **Custom Timeouts**
   - CONNECT_TIMEOUT
   - TRANSPORT_CONNECT_TIMEOUT
   - RETRY_COUNT

### ldap.ora Template

**File:** `ldap.ora.template`  
**Use Case:** LDAP directory naming

Features:

- Oracle Internet Directory (OID) configuration
- Active Directory (AD) support
- SSL/TLS for secure LDAP
- Authentication credentials
- Cache configuration

Example content:

```text
DEFAULT_ADMIN_CONTEXT = "dc=example,dc=com"
DIRECTORY_SERVERS = (ldap.example.com:389:636)
DIRECTORY_SERVER_TYPE = OID
```

## Management Tool

### oradba_sqlnet.sh

Comprehensive SQL*Net configuration management script.

#### Synopsis

```bash
oradba_sqlnet.sh [OPTIONS]
```

#### Options

| Option               | Description                                 |
|----------------------|---------------------------------------------|
| `-i, --install TYPE` | Install template (basic\|secure)            |
| `-g, --generate SID` | Generate tnsnames entry for SID             |
| `-v, --validate`     | Validate current configuration              |
| `-b, --backup`       | Backup current configuration                |
| `-t, --test ALIAS`   | Test TNS alias connection                   |
| `-l, --list`         | List all TNS aliases                        |
| `-s, --setup [SID]`  | Setup centralized TNS_ADMIN structure       |
| `-a, --setup-all`    | Setup TNS_ADMIN for all databases in oratab |
| `-h, --help`         | Show help message                           |

#### Examples

**Setup Centralized Configuration**

```bash
# Setup for specific database
oradba_sqlnet.sh --setup PRODDB

# Setup for all databases in /etc/oratab
oradba_sqlnet.sh --setup-all
```

**Install Templates**

```bash
# Install basic template
oradba_sqlnet.sh --install basic

# Install secure template with encryption
oradba_sqlnet.sh --install secure
```

**Generate TNS Entries**

```bash
# Generate entry for PRODDB
oradba_sqlnet.sh --generate PRODDB

# Generate entry for TESTDB
oradba_sqlnet.sh --generate TESTDB
```

**Validate Configuration**

```bash
# Validate current configuration
oradba_sqlnet.sh --validate

# Output example:
# Validating SQL*Net configuration...
# TNS_ADMIN: /u01/app/oracle/network/admin
# [OK] sqlnet.ora exists
# [OK] sqlnet.ora is readable
# [OK] tnsnames.ora exists
# [OK] Configuration validation passed
```

**Backup Configuration**

```bash
# Backup all configuration files
oradba_sqlnet.sh --backup

# Creates timestamped backups:
# sqlnet.ora.20251219_143022.bak
# tnsnames.ora.20251219_143022.bak
```

**Test Connections**

```bash
# Test TNS alias
oradba_sqlnet.sh --test PRODDB

# Shows:
# - tnsping results
# - Connection descriptor
# - Connection status
```

**List TNS Aliases**

```bash
# List all defined aliases
oradba_sqlnet.sh --list

# Output:
# TNS Aliases in /u01/app/oracle/network/admin/tnsnames.ora:
# 1  ORCL
# 2  PRODDB
# 3  TESTDB
```

## Configuration Files

### File Locations

Configuration files are stored in `$TNS_ADMIN` or `$ORACLE_HOME/network/admin`:

```text
$TNS_ADMIN/
├── sqlnet.ora       # Network configuration
├── tnsnames.ora     # Connection descriptors
└── ldap.ora         # LDAP naming (optional)
```

OraDBA automatically detects the correct location:

1. `$TNS_ADMIN` (if set)
2. `$ORACLE_HOME/network/admin` (if ORACLE_HOME set)
3. `$HOME/.oracle/network/admin` (fallback)

### Variable Substitution

Templates support environment variable substitution:

| Variable         | Description           | Example                     |
|------------------|-----------------------|-----------------------------|
| `${ORACLE_BASE}` | Oracle base directory | /u01/app/oracle             |
| `${ORACLE_SID}`  | Database SID          | PRODDB                      |
| `${ORACLE_HOME}` | Oracle home           | /u01/app/oracle/product/19c |

Example template:

```text
WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = ${ORACLE_BASE}/admin/${ORACLE_SID}/wallet)
    )
  )
```

After substitution:

```text
WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /u01/app/oracle/admin/PRODDB/wallet)
    )
  )
```

## Security Configuration

### Network Encryption

The secure template enables Oracle Advanced Security features:

**Encryption Settings:**

```text
SQLNET.ENCRYPTION_CLIENT = REQUIRED
SQLNET.ENCRYPTION_SERVER = REQUIRED
SQLNET.ENCRYPTION_TYPES_CLIENT = (AES256, AES192, AES128)
SQLNET.ENCRYPTION_TYPES_SERVER = (AES256, AES192, AES128)
```

**Encryption Levels:**

- `REQUIRED` - Connections must be encrypted (recommended for production)
- `REQUESTED` - Encryption preferred but not mandatory
- `ACCEPTED` - Accept encrypted or unencrypted

**Cipher Suites:**

- **AES256** - Strongest encryption (recommended)
- **AES192** - Strong encryption
- **AES128** - Standard encryption

### Data Integrity

Checksumming prevents data tampering:

```text
SQLNET.CRYPTO_CHECKSUM_CLIENT = REQUIRED
SQLNET.CRYPTO_CHECKSUM_SERVER = REQUIRED
SQLNET.CRYPTO_CHECKSUM_TYPES_CLIENT = (SHA256, SHA384, SHA512)
SQLNET.CRYPTO_CHECKSUM_TYPES_SERVER = (SHA256, SHA384, SHA512)
```

**Hash Algorithms:**

- **SHA512** - Strongest integrity protection
- **SHA384** - Strong integrity protection
- **SHA256** - Standard integrity protection

### Authentication

**Supported Methods:**

- **BEQ** - for native operating system authentication for operating systems other than Microsoft Windows.
- **TCPS** - TCP with SSL/TLS
- **KERBEROS5** - Kerberos authentication

```text
SQLNET.AUTHENTICATION_SERVICES = (TCPS, BEQ)
```

### Secure Connections (TCPS)

For SSL/TLS encrypted connections:

```text
ORCL_SECURE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCPS)(HOST = db.example.com)(PORT = 2484))
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
      (SECURITY = 
        (SSL_SERVER_CERT_DN = "CN=db.example.com,OU=IT,O=Corp,C=US")
      )
    )
  )
```

**Requirements:**

- Oracle Wallet with certificates
- Server certificate configuration
- Port 2484 (default TCPS port)

## High Availability

### Failover Configuration

Automatic client failover to secondary nodes:

```text
ORCL_FO =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = node1)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = node2)(PORT = 1521))
      (FAILOVER = ON)
      (LOAD_BALANCE = OFF)
    )
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
      (FAILOVER_MODE =
        (TYPE = SELECT)
        (METHOD = BASIC)
        (RETRIES = 3)
        (DELAY = 5)
      )
    )
  )
```

**Failover Types:**

- **SESSION** - Reconnect after connection loss
- **SELECT** - Reconnect and restore SELECT state

**Failover Methods:**

- **BASIC** - Failover on connection failure
- **PRECONNECT** - Maintain backup connection

### Load Balancing

Distribute connections across multiple nodes:

```text
ORCL_LB =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (LOAD_BALANCE = ON)
      (ADDRESS = (PROTOCOL = TCP)(HOST = node1)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = node2)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = node3)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
```

**Benefits:**

- Even distribution of client connections
- Better resource utilization
- Improved scalability

### RAC Configuration

Oracle RAC SCAN listener:

```text
ORCL_RAC =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = scan.example.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
```

**Best Practices:**

- Use SCAN address for RAC clusters
- Single entry for entire cluster
- Automatic load balancing and failover

## Best Practices

### Development Environments

1. Use `sqlnet.ora.basic` template
2. Enable diagnostics for troubleshooting
3. Set reasonable timeouts (60/120 seconds)
4. Include HOSTNAME naming for flexibility

### Production Environments

1. Use `sqlnet.ora.secure` template
2. Enable encryption (REQUIRED level)
3. Enable checksumming for integrity
4. Use wallet-based authentication
5. Set minimum logon version to 12+
6. Disable unnecessary naming methods
7. Regular security audits

### Network Configuration

1. **Timeouts:**
   - Development: 60s inbound, 120s outbound
   - Production: 60s inbound, 120s outbound
   - Aggressive failover: 30s inbound, 30s outbound

2. **Dead Connection Detection:**
   - Set `SQLNET.EXPIRE_TIME` (10 minutes recommended)
   - Helps detect broken connections
   - Sends keep-alive packets

3. **Connection Retry:**
   - Set `RETRY_COUNT` for transient failures
   - Configure `RETRY_DELAY` between attempts
   - Use for unreliable networks

### Backup and Recovery

1. **Always backup before changes:**

   ```bash
   oradba_sqlnet.sh --backup
   ```

2. **Test changes in non-production first**

3. **Keep backup files for rollback:**

   ```bash
   # Restore from backup
   cp sqlnet.ora.20251219_143022.bak sqlnet.ora
   ```

4. **Document custom changes in comments**

### Validation

1. **Validate after changes:**

   ```bash
   oradba_sqlnet.sh --validate
   ```

2. **Test connections:**

   ```bash
   oradba_sqlnet.sh --test PRODDB
   tnsping PRODDB
   ```

3. **Check syntax with tnsping:**

   ```bash
   tnsping <alias> 3
   ```

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to database

**Solution:**

```bash
# 1. Validate configuration
oradba_sqlnet.sh --validate

# 2. Test TNS alias
oradba_sqlnet.sh --test PRODDB

# 3. Use tnsping
tnsping PRODDB

# 4. Check listener status
lsnrctl status
```

**Common Causes:**

- TNS alias not defined
- Wrong host/port in tnsnames.ora
- Listener not running
- Network connectivity issues
- Firewall blocking connections

### Encryption Issues

**Problem:** ORA-12650: No common encryption checksumming types

**Cause:** Client and server encryption settings don't match

**Solution:**

```bash
# 1. Check encryption settings on both sides
grep ENCRYPTION sqlnet.ora

# 2. Ensure compatible cipher suites
# Client: SQLNET.ENCRYPTION_TYPES_CLIENT = (AES256, AES192, AES128)
# Server: SQLNET.ENCRYPTION_TYPES_SERVER = (AES256, AES192, AES128)

# 3. Change REQUIRED to REQUESTED for testing
SQLNET.ENCRYPTION_CLIENT = REQUESTED
```

### TNS-12154: Could not resolve service name

**Cause:** TNS alias not found in tnsnames.ora

**Solution:**

```bash
# 1. List available aliases
oradba_sqlnet.sh --list

# 2. Generate missing entry
oradba_sqlnet.sh --generate PRODDB

# 3. Verify TNS_ADMIN
echo $TNS_ADMIN

# 4. Check tnsnames.ora location
ls -l $TNS_ADMIN/tnsnames.ora
```

### Performance Issues

**Problem:** Slow connection establishment

**Causes and Solutions:**

1. **High timeout values:**

   ```text
   # Reduce timeouts
   SQLNET.INBOUND_CONNECT_TIMEOUT = 30
   SQLNET.OUTBOUND_CONNECT_TIMEOUT = 30
   ```

2. **HOSTNAME naming overhead:**

   ```text
   # Remove HOSTNAME from naming methods
   NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT)
   ```

3. **Network latency:**

   ```text
   # Enable TCP_NODELAY
   TCP.NODELAY = YES
   ```

### Wallet Issues

**Problem:** Cannot access wallet

**Solution:**

```bash
# 1. Check wallet location
grep WALLET_LOCATION sqlnet.ora

# 2. Verify wallet exists and has correct permissions
ls -l $ORACLE_BASE/admin/$ORACLE_SID/wallet/

# 3. Test wallet access
mkstore -wrl $WALLET_LOCATION -list
```

### Trace and Diagnostics

**Enable tracing for troubleshooting:**

```text
# In sqlnet.ora
TRACE_LEVEL_CLIENT = 16
TRACE_LEVEL_SERVER = 16
TRACE_DIRECTORY_CLIENT = /tmp/oracle_trace
LOG_DIRECTORY_CLIENT = /tmp/oracle_log
```

**After troubleshooting, disable tracing:**

```text
TRACE_LEVEL_CLIENT = OFF
TRACE_LEVEL_SERVER = OFF
```

## Integration with OraDBA

### With oraenv.sh

OraDBA's `oraenv.sh` automatically sets TNS_ADMIN:

```bash
# Source oraenv
. oraenv PRODDB

# TNS_ADMIN is now set
echo $TNS_ADMIN
# /u01/app/oracle/admin/PRODDB/network/admin
```

### With oradba_install.sh

Templates are installed to:

```text
/usr/local/oradba/templates/sqlnet/
```

### Configuration Hierarchy

OraDBA respects this precedence:

1. `$TNS_ADMIN/sqlnet.ora` (highest priority)
2. `$ORACLE_HOME/network/admin/sqlnet.ora`
3. `$HOME/.oracle/network/admin/sqlnet.ora` (fallback)

## Compliance and Standards

### PCI-DSS Requirements

For PCI-DSS compliance:

1. Use `sqlnet.ora.secure` template
2. Enable AES256 encryption (REQUIRED)
3. Enable SHA256+ checksums
4. Set minimum logon version 12+
5. Regular security audits

### HIPAA Compliance

For HIPAA compliance:

1. Encrypt all database connections
2. Use strong authentication (wallet/Kerberos)
3. Audit configuration changes
4. Maintain encryption key management

### SOX Requirements

For SOX compliance:

1. Version control configurations
2. Change management process
3. Access control for configurations
4. Regular compliance reviews

## Advanced Topics

### Multiple TNS_ADMIN Locations

Support database-specific configurations:

```bash
# Set in profile
export TNS_ADMIN=/u01/app/oracle/admin/${ORACLE_SID}/network/admin

# Or per-connection
TNS_ADMIN=/custom/path sqlplus user/pass@PRODDB
```

### Connection Pooling

Optimize application connections:

```text
PRODDB_POOL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db.example.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = POOLED)
      (SERVICE_NAME = proddb)
      (POOL_CONNECTION_CLASS = MYAPP)
    )
  )
```

### LDAP Integration

Centralized naming with Oracle Internet Directory:

```bash
# Install LDAP template
cp $ORADBA_BASE/templates/sqlnet/ldap.ora.template $TNS_ADMIN/ldap.ora

# Configure for your environment
vi $TNS_ADMIN/ldap.ora

# Update sqlnet.ora
NAMES.DIRECTORY_PATH= (LDAP, TNSNAMES)
```

## See Also

- [Environment Management](04-environment.md) - TNS_ADMIN configuration
- [Configuration](05-configuration.md) - OraDBA configuration system
- [Aliases](06-aliases.md) - Network configuration file aliases (vit, vil, visql)
- [Troubleshooting](12-troubleshooting.md) - Network troubleshooting

## Navigation

**Previous:** [Quick Reference](13-reference.md)  
**Next:** [Log Management](15-log-management.md)
