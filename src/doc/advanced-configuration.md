# Advanced Configuration Guide

**Purpose:** Comprehensive guide for advanced OraDBA v0.19.x configuration scenarios including multi-version Oracle
Homes, Grid Infrastructure, Read-Only Oracle Homes, and product-specific configurations.

**Audience:** System administrators and DBAs managing complex Oracle environments with multiple products, versions, or
specialized configurations.

## Introduction

This guide covers advanced configuration scenarios that go beyond basic OraDBA setup. You'll learn how to manage
multiple Oracle Home versions, configure Grid Infrastructure environments, work with Read-Only Oracle Homes, customize
PATH behavior, and configure product-specific settings for Data Safe, Oracle Unified Directory (OUD), Java, and
WebLogic Server (WLS).

OraDBA v0.19.x uses the Registry API and Plugin System to manage all 8 supported product types, making it easy to work
with databases, clients, and other Oracle products in complex environments.

**Prerequisites:**

- OraDBA v0.19.x installed and basic configuration completed (see [Installation](installation.md))
- Familiarity with basic OraDBA concepts (see [Configuration System](configuration.md))
- Understanding of Registry API and Plugin System (see [Environment Management](environment.md))
- Root or sudo access may be required for some configurations

## Multi-Version Oracle Home Management

Managing multiple Oracle Database versions is a common requirement in enterprise environments. OraDBA's Registry API
provides comprehensive support for registering, discovering, and switching between different Oracle product
installations across all 8 product types.

### Understanding Oracle Homes Registry

OraDBA maintains a registry of Oracle Homes separate from the oratab file. This allows you to manage Oracle Homes for
products that don't use oratab (like OUD, WLS) alongside traditional databases.

**Key concepts:**

- **Oracle Home**: Installation directory for any Oracle product
- **Product Type**: RDBMS, CLIENT, ICLIENT, GRID, ASM, DATASAFE, OUD, WLS
- **Alias**: Short name for quick environment switching (e.g., `db19c`, `oud12`)
- **Auto-discovery**: Automatic detection of Oracle installations on your system

### Discovering Multiple Oracle Homes

#### Automatic Discovery During Installation

OraDBA v0.19.8+ supports automatic discovery during installation:

```bash
# Install with auto-discovery enabled
bash oradba_install.sh --enable-auto-discover --update-profile

# Manual activation after installation
echo 'export ORADBA_AUTO_DISCOVER_HOMES="true"' >> ~/.bash_profile
```

When `--enable-auto-discover` is used during installation, OraDBA will:

- Add `export ORADBA_AUTO_DISCOVER_HOMES="true"` to your shell profile
- Automatically discover Oracle Homes on first login
- Register new Oracle products in `oradba_homes.conf`

#### Manual Discovery

Use the auto-discovery feature to find all Oracle installations:

```bash
# Discover and list all Oracle products
oradba_homes.sh discover

# Review discovered homes before adding
oradba_homes.sh discover --dry-run

# Auto-discover and add all found homes
oradba_homes.sh discover --auto-add

# Discover specific product types only
oradba_homes.sh discover --type RDBMS --auto-add
```

**Discovery locations:**

- `/u01/app/oracle/product` (standard Oracle Base structure)
- `/opt/oracle/product` (alternative installations)
- `${ORACLE_BASE}/product` (if ORACLE_BASE is set)
- Grid Infrastructure homes in `/u01/app/grid` or `/u01/app/oracle/grid`

### Registering Multiple Database Versions

Add multiple Oracle Database versions manually:

```bash
# Register Oracle 19c home
oradba_homes.sh add --name db19c \
    --path /u01/app/oracle/product/19.0.0/dbhome_1 \
    --type RDBMS \
    --version 19.3.0.0.0

# Register Oracle 21c home
oradba_homes.sh add --name db21c \
    --path /u01/app/oracle/product/21.0.0/dbhome_1 \
    --type RDBMS \
    --version 21.3.0.0.0

# Register Oracle 23ai home
oradba_homes.sh add --name db23ai \
    --path /u01/app/oracle/product/23.0.0/dbhome_1 \
    --type RDBMS \
    --version 23.4.0.24.05

# List all registered homes
oradba_homes.sh list
```

### Switching Between Oracle Homes

Use the alias to quickly switch environments:

```bash
# Switch to 19c environment
source oraenv.sh db19c

# Verify the ORACLE_HOME
echo $ORACLE_HOME
# Output: /u01/app/oracle/product/19.0.0/dbhome_1

# Switch to 21c environment
source oraenv.sh db21c

# Switch to specific database SID (uses oratab)
source oraenv.sh PRODDB
```

**Important notes:**

- Switching Oracle Homes cleans previous Oracle paths from PATH and LD_LIBRARY_PATH
- Environment variables are completely rebuilt for the target home
- Aliases are reloaded to match the target environment
- Database-specific configurations are applied if available

### Exporting and Importing Oracle Homes Configuration

For consistency across multiple servers or backup purposes:

```bash
# Export current Oracle Homes registry
oradba_homes.sh export > /backup/oracle_homes.conf

# Export to specific file
oradba_homes.sh export --output /etc/oracle/homes_backup.conf

# Import on another server
oradba_homes.sh import /backup/oracle_homes.conf

# Verify imported homes
oradba_homes.sh list
```

**Use cases:**

- Standardizing development, test, and production environments
- Disaster recovery documentation
- Automated provisioning scripts
- Team knowledge sharing

### Working with Oracle Client Installations

Oracle Client and Instant Client have different directory structures:

```bash
# Full Oracle Client
oradba_homes.sh add --name client19c \
    --path /u01/app/oracle/product/19.0.0/client_1 \
    --type CLIENT

# Instant Client (no traditional bin directory)
oradba_homes.sh add --name iclient21 \
    --path /opt/oracle/instantclient_21_1 \
    --type ICLIENT

# Switch to client environment
source oraenv.sh client19c

# Verify sqlplus is accessible
which sqlplus
```

**Instant Client considerations:**

- Libraries are in the main directory, not in lib/
- sqlplus may be directly in the instant client directory
- TNS_ADMIN should be set separately for tnsnames.ora location

## ASM and Grid Infrastructure Configuration

Automatic Storage Management (ASM) and Grid Infrastructure require special configuration in OraDBA environments. This
section covers best practices for these configurations.

### Understanding Grid Infrastructure Architecture

Grid Infrastructure provides cluster-ready services including:

- **Oracle Clusterware**: High availability infrastructure
- **ASM**: Automatic Storage Management for database files
- **Grid Naming Service (GNS)**: Dynamic cluster node registration
- **Cluster Time Synchronization Service (CTSS)**
- **Oracle Notification Service (ONS)**

**Key variables:**

- `GRID_HOME`: Grid Infrastructure installation directory
- `ASM_HOME`: Usually same as GRID_HOME
- `ORACLE_HOME`: Database home (separate from Grid)

### Registering Grid Infrastructure Home

Grid Infrastructure must be registered separately from database homes:

```bash
# Register Grid Infrastructure 19c
oradba_homes.sh add --name grid19c \
    --path /u01/app/grid/product/19.0.0/grid_home \
    --type GRID \
    --version 19.3.0.0.0

# Verify registration
oradba_homes.sh list --type GRID

# Set environment for Grid home
source oraenv.sh grid19c
```

### Configuring ASM Instance

ASM instances appear in oratab with special naming (+ASM):

```bash
# Typical ASM entry in /etc/oratab
+ASM:/u01/app/grid/product/19.0.0/grid_home:N

# Set environment for ASM
source oraenv.sh +ASM

# Verify ASM environment
echo $ORACLE_SID
# Output: +ASM

echo $ORACLE_HOME
# Output: /u01/app/grid/product/19.0.0/grid_home

# Connect to ASM instance
sqlplus / as sysasm
```

**ASM-specific aliases:**

```bash
# After sourcing ASM environment
sq              # sqlplus / as sysasm (not sysdba for ASM)
cdh             # cd $ORACLE_HOME
taa             # tail -f ASM alert log
```

### Database with Separate Grid Infrastructure

Most production databases use Grid Infrastructure for listeners and ASM:

```bash
# Configuration in oradba_customer.conf
[RDBMS]
GRID_HOME=/u01/app/grid/product/19.0.0/grid_home

# Or in database-specific config: /opt/oradba/etc/sid.PRODDB.conf
[PRODDB]
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
GRID_HOME=/u01/app/grid/product/19.0.0/grid_home
```

When `GRID_HOME` is set, OraDBA automatically:

- Adds Grid bin directory to PATH (before ORACLE_HOME/bin)
- Uses Grid listener (lsnrctl from GRID_HOME)
- Uses Grid ASM utilities (asmcmd, asmca)
- Maintains separate alert logs for database and Grid

### Managing Grid Listeners

Grid Infrastructure manages listeners differently:

```bash
# Set environment for database using Grid
source oraenv.sh PRODDB

# Check listener status (uses Grid listener)
lsnrctl status

# Start/stop listener (uses Grid home)
lsnrctl start
lsnrctl stop

# View listener log location
echo $GRID_HOME/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log
```

**Important:** When Grid Infrastructure is present:

- Don't use database home listener commands
- Use `srvctl` for listener management in clusters
- Listener configuration is in `$GRID_HOME/network/admin`

### ASM Disk Groups and Database Files

Configure database to use ASM storage:

```bash
# Set environment for database
source oraenv.sh PRODDB

# Check ASM disk groups (requires ASM environment or Grid tools)
asmcmd lsdg

# View database file locations
sqlplus / as sysdba <<EOF
SELECT name, file_name FROM dba_data_files;
SELECT member FROM v\$logfile;
SELECT name FROM v\$controlfile;
EOF
```

### Troubleshooting Grid Infrastructure Issues

Common Grid Infrastructure problems:

#### Issue: Cannot start listener - permission denied

```bash
# Check: Grid services should run as grid owner
ps -ef | grep tnslsnr

# Fix: Use correct OS user
su - grid
source oraenv.sh +ASM
lsnrctl start
```

#### Issue: ASM instance not showing in oraup.sh

```bash
# Check: Verify ASM entry in oratab
grep +ASM /etc/oratab

# Fix: Add ASM to oratab
echo "+ASM:/u01/app/grid/product/19.0.0/grid_home:N" >> /etc/oratab
```

#### Issue: Wrong listener being used

```bash
# Check: Verify GRID_HOME is set
source oraenv.sh PRODDB
echo $GRID_HOME

# Fix: Set in database config
vi /opt/oradba/etc/sid.PRODDB.conf
# Add:
# [PRODDB]
# GRID_HOME=/u01/app/grid/product/19.0.0/grid_home
```

## Read-Only Oracle Home (ROOH) Setups

Read-Only Oracle Home (ROOH) is a security feature introduced in Oracle 18c that separates binaries from configuration
and runtime files. OraDBA automatically detects and configures ROOH environments.

### Understanding ROOH Architecture

In ROOH configurations:

- **ORACLE_HOME**: Read-only binaries and libraries
- **ORACLE_BASE_HOME**: Instance-specific configuration files
- **ORACLE_BASE_CONFIG**: Separate configuration location (optional)

**Directory structure:**

```text
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1  (read-only)
    ├── bin/           (read-only binaries)
    ├── lib/           (read-only libraries)
    └── rdbms/         (read-only files)

ORACLE_BASE_HOME=/u01/app/oracle/homes/OraDB19Home1  (writable)
    ├── dbs/           (init.ora, spfile, password files)
    ├── network/admin/ (tnsnames.ora, sqlnet.ora)
    └── rdbms/audit/   (audit files)
```

### Detecting ROOH Configuration

OraDBA automatically detects ROOH using the `orabasehome` utility:

```bash
# Set environment for ROOH database
source oraenv.sh ROOHDB

# Check if ROOH is detected
echo $ORADBA_ROOH
# Output: true (if ROOH) or false (if traditional)

# View ORACLE_BASE_HOME
echo $ORACLE_BASE_HOME
# Output: /u01/app/oracle/homes/OraDB19Home1

# Check dbs directory location
echo $ORADBA_DBS
# Output: /u01/app/oracle/homes/OraDB19Home1/dbs (ROOH)
#     or: /u01/app/oracle/product/19.0.0/dbhome_1/dbs (traditional)
```

### Configuring ROOH in OraDBA

No special configuration is required - ROOH is automatically detected. However, you can override locations:

```bash
# In /opt/oradba/etc/sid.ROOHDB.conf
[ROOHDB]
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
ORACLE_BASE=/u01/app/oracle
ORACLE_BASE_HOME=/u01/app/oracle/homes/OraDB19Home1

# Optional: Explicitly set dbs location
# ORADBA_DBS=${ORACLE_BASE_HOME}/dbs
```

### Working with ROOH Configurations

Common operations adapt automatically to ROOH:

```bash
# Set environment
source oraenv.sh ROOHDB

# Configuration files use ORACLE_BASE_HOME
cdh             # cd $ORACLE_HOME (read-only binaries)
cdb             # cd $ORACLE_BASE_HOME (writable config)
cdn             # cd $ORACLE_BASE_HOME/network/admin

# Editing init.ora
vi $ORACLE_BASE_HOME/dbs/initROOHDB.ora

# Creating password file (prompts for password)
orapwd file=$ORACLE_BASE_HOME/dbs/orapwROOHDB
# Alternative: Use environment variable
# orapwd file=$ORACLE_BASE_HOME/dbs/orapwROOHDB password=${ORACLE_PWD}

# Checking tnsnames
cat $ORACLE_BASE_HOME/network/admin/tnsnames.ora
```

### Benefits of ROOH

**Security advantages:**

- Binary files cannot be modified by oracle user
- Reduced attack surface for malware
- Easier compliance auditing
- Clear separation of code and data

**Operational advantages:**

- Multiple databases can share same ORACLE_HOME
- Simplified patching (update ORACLE_HOME, restart databases)
- Easier home cloning and standardization
- Reduced storage for multiple databases

### ROOH Best Practices

1. **Set ORACLE_HOME ownership to root**

   ```bash
   # As root user
   chown -R root:oinstall $ORACLE_HOME
   chmod -R o-w $ORACLE_HOME
   ```

2. **Keep ORACLE_BASE_HOME writable by oracle**

   ```bash
   # As oracle user
   chown -R oracle:oinstall $ORACLE_BASE_HOME
   ```

3. **Document ROOH configuration**

   ```bash
   # Create documentation file
   cat > $ORACLE_BASE/rooh_config.txt <<EOF
   Database: ROOHDB
   ORACLE_HOME: $ORACLE_HOME (read-only, owned by root)
   ORACLE_BASE_HOME: $ORACLE_BASE_HOME (writable, owned by oracle)
   Configuration: ROOH enabled since database creation
   EOF
   ```

4. **Test patching procedures**
   - Verify read-only ORACLE_HOME doesn't affect patching
   - Test database restart after ORACLE_HOME patching
   - Ensure ORACLE_BASE_HOME remains unchanged

### Troubleshooting ROOH

#### Issue: Cannot write to $ORACLE_HOME/dbs

```bash
# Symptom: Permission denied when creating spfile or password file

# Check: Verify ROOH detection
source oraenv.sh ROOHDB
echo $ORADBA_ROOH
echo $ORADBA_DBS

# Fix: Files should be in ORACLE_BASE_HOME/dbs (prompts for password)
orapwd file=$ORACLE_BASE_HOME/dbs/orapwROOHDB
# Alternative: Use environment variable for automation
# orapwd file=$ORACLE_BASE_HOME/dbs/orapwROOHDB password=${ORACLE_PWD}
```

#### Issue: tnsnames.ora not found

```bash
# Check: TNS_ADMIN should point to ORACLE_BASE_HOME
echo $TNS_ADMIN

# Fix: OraDBA sets this automatically, but verify:
ls -l $ORACLE_BASE_HOME/network/admin/tnsnames.ora
```

#### Issue: ROOH not detected automatically

```bash
# Check: Verify orabasehome utility exists
$ORACLE_HOME/bin/orabasehome

# Manual workaround: Set in database config
vi /opt/oradba/etc/sid.ROOHDB.conf
# Add:
# ORACLE_BASE_HOME=/u01/app/oracle/homes/OraDB19Home1
```

## Custom PATH and LD_LIBRARY_PATH Manipulation

OraDBA automatically manages PATH and LD_LIBRARY_PATH, but advanced scenarios may require customization. This section
covers safe manipulation techniques.

### Understanding OraDBA Path Management

OraDBA constructs paths in this order:

1. **Clean existing Oracle paths**: Removes old Oracle directories
2. **Add ORADBA_BIN_DIR**: OraDBA tools (`/opt/oradba/bin`)
3. **Add ORACLE_HOME/bin**: Oracle binaries
4. **Add GRID_HOME/bin**: Grid Infrastructure (if configured)
5. **Add OPatch directory**: Patching tools
6. **Deduplicate**: Remove duplicate entries
7. **Prepend user paths**: From configuration files

**Final PATH structure:**

```text
/opt/oradba/bin:/u01/app/grid/19c/bin:/u01/app/oracle/product/19c/bin:/usr/local/bin:/usr/bin:/bin
```

### Adding Custom Directories to PATH

Use configuration files to add custom paths:

```bash
# Global custom paths in /opt/oradba/etc/oradba_customer.conf
[CORE]
# Prepend custom tools (highest priority)
PATH_PREPEND=/opt/custom_tools/bin:/usr/local/sbin

# Append custom tools (lowest priority)
PATH_APPEND=/opt/legacy_tools/bin

# Alternative format using variable expansion
PATH_PREPEND=${ORADBA_LOCAL_BASE}/custom/bin
```

**Database-specific paths:**

```bash
# In /opt/oradba/etc/sid.PRODDB.conf
[PRODDB]
# Add database-specific tools
PATH_PREPEND=/opt/proddb_tools/bin

# This PATH only active when: source oraenv.sh PRODDB
```

### Customizing LD_LIBRARY_PATH

Library path configuration follows similar patterns:

```bash
# In /opt/oradba/etc/oradba_customer.conf
[CORE]
# Add custom libraries
LD_LIBRARY_PATH_PREPEND=/opt/custom_libs/lib

# For Instant Client integration
LD_LIBRARY_PATH_PREPEND=/opt/oracle/instantclient_19_8

# With variable expansion
LD_LIBRARY_PATH_PREPEND=${ORADBA_LOCAL_BASE}/libs/lib64
```

**Common use cases:**

- Third-party Oracle tools (SQL Developer, TOAD)
- Custom PL/SQL external procedures
- Java applications using JDBC thick driver
- Pro*C compiled applications

### Product-Specific Path Configuration

Different Oracle products need different path structures:

```bash
# RDBMS configuration
[RDBMS]
PATH_PREPEND=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch
LD_LIBRARY_PATH=${ORACLE_HOME}/lib

# Grid Infrastructure configuration
[GRID]
PATH_PREPEND=${GRID_HOME}/bin:${ORACLE_HOME}/bin
LD_LIBRARY_PATH=${GRID_HOME}/lib:${ORACLE_HOME}/lib

# Instant Client configuration
[ICLIENT]
PATH_PREPEND=${ORACLE_HOME}
LD_LIBRARY_PATH=${ORACLE_HOME}

# OUD configuration
[OUD]
PATH_PREPEND=${ORACLE_HOME}/bin:${ORACLE_HOME}/oud/bin
```

### Advanced Path Manipulation Techniques

#### Technique 1: Conditional paths based on hostname

```bash
# In /opt/oradba/etc/oradba_customer.conf
[CORE]
# Development servers get extra tools
# Note: Conditional logic in config files should be used sparingly
# Consider using separate config files per environment instead
if [[ "$(hostname)" =~ dev ]]; then
    PATH_PREPEND=/opt/devtools/bin
fi
# Alternative: Create separate oradba_customer.conf.dev and link it
```

#### Technique 2: Version-specific paths

```bash
# Database-specific config
[PRODDB]
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1

# Add version-specific libraries
if [[ "${ORACLE_HOME}" =~ 19 ]]; then
    LD_LIBRARY_PATH_PREPEND=/opt/libs/oracle19
elif [[ "${ORACLE_HOME}" =~ 21 ]]; then
    LD_LIBRARY_PATH_PREPEND=/opt/libs/oracle21
fi
```

#### Technique 3: Insert paths at specific positions

```bash
# Use functions to manipulate PATH programmatically
# In custom extension script

# Insert path after specific directory
oradba_insert_path_after() {
    local insert_dir="$1"
    local after_dir="$2"
    # Implementation uses string manipulation
    # See oradba_env_builder.sh for reference
}
```

### PATH Troubleshooting and Debugging

Enable debug mode to see path construction:

```bash
# Temporary debug
export ORADBA_DEBUG=true
source oraenv.sh PRODDB
# Displays: PATH construction steps, configuration loading, variable expansion

# Persistent debug in config
# /opt/oradba/etc/oradba_customer.conf
[CORE]
ORADBA_DEBUG=true
```

**Verify final paths:**

```bash
# After sourcing environment
source oraenv.sh PRODDB

# Display PATH with one directory per line
echo $PATH | tr ':' '\n' | nl

# Check for duplicates
echo $PATH | tr ':' '\n' | sort | uniq -d

# Verify command locations
which sqlplus
which lsnrctl
which rman
```

**Common path issues:**

1. **Wrong sqlplus version used**

   ```bash
   # Symptom: Old Oracle Client sqlplus instead of ORACLE_HOME version
   
   # Check
   which sqlplus
   sqlplus -V
   
   # Fix: Ensure ORACLE_HOME/bin is early in PATH
   echo $PATH | grep -o "[^:]*oracle[^:]*" | head -1
   ```

2. **Library not found errors**

   ```bash
   # Symptom: error while loading shared libraries: libclntsh.so
   
   # Check
   echo $LD_LIBRARY_PATH
   ldd $(which sqlplus) | grep "not found"
   
   # Fix: Add ORACLE_HOME/lib
   export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
   ```

3. **Custom tools not found**

   ```bash
   # Symptom: command not found for custom scripts
   
   # Check configuration
   grep PATH_PREPEND /opt/oradba/etc/oradba_customer.conf
   
   # Verify directory exists and is readable
   ls -ld /opt/custom_tools/bin
   ```

## Product-Specific Configurations

OraDBA supports multiple Oracle products beyond traditional databases. This section covers configuration for DataSafe,
Oracle Unified Directory (OUD), and WebLogic Server (WLS).

### Oracle Data Safe On-Premises Connector

Data Safe On-Premises Connector provides secure communication between on-premises databases and Oracle Cloud Data Safe
service.

**Registration:**

```bash
# Register Data Safe connector home
oradba_homes.sh add --name datasafe1 \
    --path /u01/app/oracle/product/datasafe \
    --type DATASAFE \
    --version 2.0.0

# List Data Safe homes
oradba_homes.sh list --type DATASAFE
```

**Configuration structure:**

```text
/u01/app/oracle/product/datasafe/
    ├── oracle_cman_home/         (Connection Manager)
    │   ├── bin/                  (cmctl, lsnrctl)
    │   └── network/admin/        (cman.ora, tnsnames.ora)
    ├── agent/                    (Data Safe agent)
    └── config/                   (Connector configuration)
```

**Setting environment:**

```bash
# Set Data Safe environment
source oraenv.sh datasafe1

# Verify paths
echo $ORACLE_HOME
# Output: /u01/app/oracle/product/datasafe

# Data Safe specific variables
echo $TNS_ADMIN
# Output: /u01/app/oracle/product/datasafe/oracle_cman_home/network/admin

# Check Connection Manager
cmctl show service

# Check listener
lsnrctl status CMAN_LISTENER
```

**Configuration file:**

```bash
# /opt/oradba/etc/oradba_customer.conf
[DATASAFE]
# Data Safe specific paths
PATH_PREPEND=${ORACLE_HOME}/oracle_cman_home/bin:${ORACLE_HOME}/agent/bin
TNS_ADMIN=${ORACLE_HOME}/oracle_cman_home/network/admin

# Service management
DATASAFE_SERVICE_NAME=datasafe-connector
DATASAFE_AGENT_HOME=${ORACLE_HOME}/agent
```

**Managing Data Safe services:**

```bash
# Set environment
source oraenv.sh datasafe1

# Start Connection Manager
cmctl start cman

# Check status
cmctl show status

# View agent status
cd $ORACLE_HOME/agent/bin
./agentctl status

# Stop services
cmctl stop cman
```

**Using oradba_dsctl.sh for Connector Management:**

The `oradba_dsctl.sh` script provides unified control for Data Safe connectors, similar to `oradba_dbctl.sh` for databases.

```bash
# Start all connectors with autostart enabled (Y flag in oradba_homes.conf)
oradba_dsctl.sh start

# Start specific connector
oradba_dsctl.sh start datasafe1

# Start multiple connectors
oradba_dsctl.sh start datasafe1 datasafe2

# Stop connector with custom timeout
oradba_dsctl.sh stop datasafe1 --timeout 120

# Stop all connectors (requires justification)
oradba_dsctl.sh stop

# Force stop without confirmation
oradba_dsctl.sh stop --force

# Restart connector
oradba_dsctl.sh restart datasafe1

# Check status of all connectors
oradba_dsctl.sh status

# Check status with debug logging
oradba_dsctl.sh status --debug

# Enable autostart for connector (in oradba_homes.conf)
oradba_homes.sh update --name datasafe1 --autostart Y
```

**Script features:**

- Integrates with oradba_registry API for automatic connector discovery
- Uses `cmctl` for connector management (startup/shutdown)
- Supports graceful shutdown with configurable timeout (default: 180s)
- Process-based fallback when graceful shutdown times out
- Comprehensive logging using `oradba_log`
- Justification prompt for bulk operations
- Debug mode support via `--debug` flag or `ORADBA_DEBUG` environment variable

**Troubleshooting Data Safe:**

```bash
# Check: Connection Manager listener
lsnrctl status CMAN_LISTENER

# Check: Agent connectivity
cd $ORACLE_HOME/agent/bin
./agentctl check

# Check: Network configuration
cat $TNS_ADMIN/cman.ora
cat $TNS_ADMIN/tnsnames.ora

# Check: Logs
tail -f $ORACLE_HOME/oracle_cman_home/diag/tnslsnr/*/cman_listener/trace/cman_listener.log
tail -f $ORACLE_HOME/agent/logs/agent.log
```

### Oracle Unified Directory (OUD)

Oracle Unified Directory is an LDAP directory server for enterprise identity management.

**Registration:**

```bash
# Register OUD 12c home
oradba_homes.sh add --name oud12 \
    --path /u01/app/oracle/product/12.2.1.4/oud \
    --type OUD \
    --version 12.2.1.4.0

# Register OUD instance directory
oradba_homes.sh add --name oud_instance1 \
    --path /u01/app/oracle/admin/oud_instance1 \
    --type OUD \
    --version 12.2.1.4.0
```

**OUD directory structure:**

```text
/u01/app/oracle/product/12.2.1.4/oud/    (OUD_HOME - binaries)
    ├── bin/                              (setup, oud-setup, etc.)
    ├── lib/                              (Java libraries)
    └── config/                           (Default templates)

/u01/app/oracle/admin/oud_instance1/     (OUD_INSTANCE_HOME - runtime)
    ├── OUD/                              (Server instance)
    ├── config/                           (Instance configuration)
    ├── logs/                             (Server logs)
    └── db/                               (LDAP data)
```

**Setting environment:**

```bash
# Set OUD home environment
source oraenv.sh oud12

# Verify OUD paths
echo $ORACLE_HOME
echo $OUD_HOME
# Both output: /u01/app/oracle/product/12.2.1.4/oud

# Set instance environment
export OUD_INSTANCE_HOME=/u01/app/oracle/admin/oud_instance1

# Verify OUD commands available
which dsconfig
which ldapsearch
which status
```

**Configuration:**

```bash
# /opt/oradba/etc/sid.oud_instance1.conf
[OUD_INSTANCE1]
ORACLE_HOME=/u01/app/oracle/product/12.2.1.4/oud
OUD_HOME=${ORACLE_HOME}
OUD_INSTANCE_HOME=/u01/app/oracle/admin/oud_instance1
OUD_INSTANCE_NAME=oud_instance1

# Path configuration
PATH_PREPEND=${OUD_INSTANCE_HOME}/OUD/bin:${OUD_HOME}/bin
CLASSPATH=${OUD_HOME}/lib/*

# Java settings
JAVA_HOME=/usr/java/latest
```

**Managing OUD instances:**

```bash
# Set environment
source oraenv.sh oud_instance1

# Check OUD status
cd $OUD_INSTANCE_HOME/OUD/bin
./status --bindDN "cn=Directory Manager"

# Start OUD server
./start-ds

# Stop OUD server
./stop-ds

# View OUD configuration
./dsconfig --help

# Search LDAP directory (prompts for password with -W)
ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -W -b "dc=example,dc=com" "(objectclass=*)"
# Alternative: Use password file
# ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -y ~/.oud_password -b "dc=example,dc=com" "(objectclass=*)"
```

**OUD-specific aliases:**

```bash
# Add to /opt/oradba/etc/oradba_customer.conf
[OUD]
# Directory aliases
alias oud_home='cd ${OUD_HOME}'
alias oud_inst='cd ${OUD_INSTANCE_HOME}'
alias oud_logs='cd ${OUD_INSTANCE_HOME}/logs && ls -ltr'
alias oud_bin='cd ${OUD_INSTANCE_HOME}/OUD/bin'

# Command shortcuts
alias oud_status='${OUD_INSTANCE_HOME}/OUD/bin/status'
alias oud_start='${OUD_INSTANCE_HOME}/OUD/bin/start-ds'
alias oud_stop='${OUD_INSTANCE_HOME}/OUD/bin/stop-ds'
```

**Troubleshooting OUD:**

```bash
# Check: Java version
java -version
# OUD requires Java 8 or 11

# Check: OUD process
ps -ef | grep "org.opends.server.core.DirectoryServer"

# Check: Listening ports
netstat -an | grep "1389\|1636"

# Check: Instance logs
tail -f $OUD_INSTANCE_HOME/logs/server.out
tail -f $OUD_INSTANCE_HOME/OUD/logs/errors

# Check: Configuration backend (prompts for password with -W)
./ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -W \
    -b "cn=config" "(objectclass=*)" dn
# Alternative: Use password file
# ./ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -y ~/.oud_password \
#     -b "cn=config" "(objectclass=*)" dn
```

### WebLogic Server (WLS)

WebLogic Server is Oracle's Java EE application server, often used with Oracle Fusion Middleware products.

**Registration:**

```bash
# Register WLS 14c home
oradba_homes.sh add --name wls14 \
    --path /u01/app/oracle/middleware/wls14 \
    --type WLS \
    --version 14.1.1.0.0

# Register domain home
oradba_homes.sh add --name wls_domain1 \
    --path /u01/app/oracle/admin/domains/domain1 \
    --type WLS \
    --version 14.1.1.0.0
```

**WLS directory structure:**

```text
/u01/app/oracle/middleware/wls14/         (WLS_HOME - binaries)
    ├── wlserver/                         (WebLogic Server)
    │   ├── server/bin/                   (startWebLogic.sh, etc.)
    │   └── common/bin/                   (wlst.sh, commEnv.sh)
    └── oracle_common/                    (Fusion Middleware common)

/u01/app/oracle/admin/domains/domain1/   (DOMAIN_HOME - runtime)
    ├── bin/                              (startWebLogic.sh, domain scripts)
    ├── config/                           (config.xml, domain config)
    ├── servers/                          (AdminServer, managed servers)
    └── logs/                             (Domain logs)
```

**Setting environment:**

```bash
# Set WLS home environment
source oraenv.sh wls14

# Verify WLS paths
echo $ORACLE_HOME
echo $WLS_HOME
# Both output: /u01/app/oracle/middleware/wls14

# Set domain environment
export DOMAIN_HOME=/u01/app/oracle/admin/domains/domain1

# Source domain environment
cd $DOMAIN_HOME/bin
. ./setDomainEnv.sh
```

**Configuration:**

```bash
# /opt/oradba/etc/sid.wls_domain1.conf
[WLS_DOMAIN1]
ORACLE_HOME=/u01/app/oracle/middleware/wls14
WLS_HOME=${ORACLE_HOME}/wlserver
DOMAIN_HOME=/u01/app/oracle/admin/domains/domain1
DOMAIN_NAME=domain1

# Path configuration
PATH_PREPEND=${DOMAIN_HOME}/bin:${WLS_HOME}/server/bin:${WLS_HOME}/common/bin

# Java settings
JAVA_HOME=/usr/java/latest
MW_HOME=${ORACLE_HOME}

# WebLogic settings
USER_MEM_ARGS="-Xms512m -Xmx1024m"
```

**Managing WebLogic domains:**

```bash
# Set environment
source oraenv.sh wls_domain1

# Start Admin Server
cd $DOMAIN_HOME/bin
./startWebLogic.sh

# Start Admin Server in background
nohup ./startWebLogic.sh > /dev/null 2>&1 &

# Start Managed Server
./startManagedWebLogic.sh ManagedServer1 t3://localhost:7001

# Stop servers
./stopWebLogic.sh
./stopManagedWebLogic.sh ManagedServer1

# Access WLST (WebLogic Scripting Tool)
cd $WLS_HOME/common/bin
./wlst.sh
```

**WLS-specific aliases:**

```bash
# Add to /opt/oradba/etc/oradba_customer.conf
[WLS]
# Directory aliases
alias wls_home='cd ${WLS_HOME}'
alias wls_domain='cd ${DOMAIN_HOME}'
alias wls_logs='cd ${DOMAIN_HOME}/servers/AdminServer/logs && ls -ltr'
alias wls_bin='cd ${DOMAIN_HOME}/bin'

# Command shortcuts
alias wls_start='cd ${DOMAIN_HOME}/bin && ./startWebLogic.sh'
alias wls_stop='cd ${DOMAIN_HOME}/bin && ./stopWebLogic.sh'
alias wls_console='echo "Admin Console: http://$(hostname):7001/console"'
alias wlst='${WLS_HOME}/common/bin/wlst.sh'
```

**Troubleshooting WLS:**

```bash
# Check: Java version
java -version
# WLS 14c requires Java 8 or 11

# Check: WebLogic processes
ps -ef | grep "weblogic.Server"
ps -ef | grep "weblogic.NodeManager"

# Check: Admin Server listening
netstat -an | grep 7001
curl -I http://localhost:7001/console

# Check: Domain logs
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log
tail -f $DOMAIN_HOME/servers/AdminServer/logs/access.log

# Check: Server status via WLST
wlst.sh <<EOF
connect('weblogic','${ADMIN_PASSWORD}','t3://localhost:7001')
serverRuntime()
print 'Server State:', cmo.getState()
disconnect()
exit()
EOF
# Note: Set ADMIN_PASSWORD environment variable or use password file
```

## Configuration Troubleshooting

This section provides systematic approaches to diagnosing and resolving configuration issues.

### Diagnostic Tools

**Built-in diagnostic commands:**

```bash
# Environment validation (supports Oracle Home names from oradba_homes.conf)
oradba_env.sh validate                  # Validate current environment
oradba_env.sh validate PRODDB          # Validate specific database SID
oradba_env.sh validate dscontest       # Validate DataSafe connector (v1.2.0+)
oradba_env.sh validate /path/to/home   # Validate by path

# Configuration status (works with Oracle Homes and database SIDs)
oradba_env.sh status                   # Status of current environment
oradba_env.sh status PRODDB           # Status of specific database
oradba_env.sh status dscontest        # Status of DataSafe connector (v1.2.0+)

# Oracle environment information
oradba_env.sh list                     # List all SIDs and Oracle Homes
oradba_env.sh list sids               # List only database SIDs (with flags: DUMMY/AUTO-START/MANUAL)
oradba_env.sh list homes              # List only Oracle Homes
oradba_env.sh show                    # Show current SID details (defaults to $ORACLE_SID)
oradba_env.sh show PRODDB             # Show database details
oradba_env.sh show dscontest          # Show Oracle Home details (v1.2.0+)

# Change detection
oradba_env.sh changes

# Oracle Homes listing
oradba_homes.sh list

# Prerequisites check
oradba_check.sh --verbose
```

**Debug mode:**

```bash
# Enable debug output
export ORADBA_DEBUG=true
source oraenv.sh PRODDB

# Or set persistently in config
echo "ORADBA_DEBUG=true" >> /opt/oradba/etc/oradba_customer.conf
```

### Common Configuration Problems

#### Problem: Environment not loading

```bash
# Symptom: source oraenv.sh PRODDB has no effect

# Diagnosis steps:
# 1. Check PRODDB exists in oratab
grep PRODDB /etc/oratab

# 2. Verify OraDBA installation
ls -l /opt/oradba/bin/oraenv.sh

# 3. Check configuration files syntax
bash -n /opt/oradba/etc/*.conf

# 4. Review logs
tail -f /opt/oradba/log/oradba_env.log

# 5. Try with debug
export ORADBA_DEBUG=true
source oraenv.sh PRODDB
```

#### Problem: Wrong ORACLE_HOME set

```bash
# Symptom: ORACLE_HOME points to unexpected location

# Diagnosis:
# 1. Check oratab entry
grep PRODDB /etc/oratab

# 2. Check Oracle Homes registry
oradba_homes.sh list

# 3. Check database-specific config
cat /opt/oradba/etc/sid.PRODDB.conf

# 4. Check configuration hierarchy
oradba_env.sh show PRODDB

# Fix: Update oratab or config file with correct path
```

#### Problem: PATH not including expected directories

```bash
# Symptom: Commands not found or wrong version

# Diagnosis:
# 1. Display current PATH
echo $PATH | tr ':' '\n' | nl

# 2. Check configuration for PATH_PREPEND/PATH_APPEND
grep PATH /opt/oradba/etc/oradba_customer.conf
grep PATH /opt/oradba/etc/sid.*.conf

# 3. Check path cleaning
# OraDBA removes Oracle paths before rebuilding
export ORADBA_DEBUG=true
source oraenv.sh PRODDB | grep "PATH"

# Fix: Add directories using PATH_PREPEND in config
```

#### Problem: Libraries not found (LD_LIBRARY_PATH)

```bash
# Symptom: error while loading shared libraries: libclntsh.so.19.1

# Diagnosis:
# 1. Check LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH | tr ':' '\n' | nl

# 2. Verify library exists
find $ORACLE_HOME -name "libclntsh.so*"

# 3. Check library dependencies
ldd $(which sqlplus) | grep "not found"

# Fix: Set LD_LIBRARY_PATH in config
echo "LD_LIBRARY_PATH_PREPEND=\${ORACLE_HOME}/lib" >> /opt/oradba/etc/oradba_customer.conf
```

#### Problem: Configuration changes not taking effect

```bash
# Symptom: Modified configuration not applied

# Diagnosis:
# 1. Check file was saved
cat /opt/oradba/etc/oradba_customer.conf | grep "YOUR_CHANGE"

# 2. Check syntax errors
bash -n /opt/oradba/etc/oradba_customer.conf

# 3. Re-source environment
source oraenv.sh PRODDB

# 4. Check variable value
echo $VARIABLE_YOU_SET

# Common causes:
# - Syntax error in config file
# - File permissions (not readable)
# - Wrong section name [PRODDB] vs [RDBMS]
# - Variable typo
```

### Configuration Validation

**Validate configuration hierarchy:**

```bash
# Show all configuration sources for a SID
oradba_env.sh show PRODDB

# Output shows:
# 1. oradba_core.conf settings
# 2. oradba_standard.conf settings
# 3. oradba_local.conf settings
# 4. oradba_customer.conf settings (your changes)
# 5. sid._DEFAULT_.conf settings
# 6. sid.PRODDB.conf settings
```

**Test configuration without activating:**

```bash
# Parse configuration without setting environment
oradba_env.sh parse PRODDB --dry-run

# Shows what would be set without actually setting it
```

**Verify Oracle installation:**

```bash
# Run basic validation
oradba_env.sh validate PRODDB

# Validation levels:
# - basic: ORACLE_HOME exists, binaries present
# - standard: Database connectivity, listener status
# - full: Complete Oracle environment verification

# Full validation
oradba_env.sh validate PRODDB --level full
```

### Log File Analysis

**OraDBA logs:**

```bash
# Main environment log
tail -f /opt/oradba/log/oradba_env.log

# Filter for errors
grep -i error /opt/oradba/log/oradba_env.log

# Filter for specific SID
grep PRODDB /opt/oradba/log/oradba_env.log

# Filter by date
grep "2024-01-15" /opt/oradba/log/oradba_env.log
```

**Understanding log levels:**

```text
[ERROR] - Critical issues preventing operation
[WARN]  - Warnings about unusual conditions
[INFO]  - Normal operational messages
[DEBUG] - Detailed debugging information (only when ORADBA_DEBUG=true)
```

### Performance Issues

**Slow environment loading:**

```bash
# Symptom: source oraenv.sh takes several seconds

# Diagnosis:
# 1. Enable timing
time source oraenv.sh PRODDB

# 2. Check for slow operations in debug mode
export ORADBA_DEBUG=true
time source oraenv.sh PRODDB | grep -E "seconds|ms"

# Common causes:
# - Network-mounted ORACLE_HOME (NFS latency)
# - Large number of configuration files
# - Complex variable expansion
# - Slow database status check

# Fix options:
# - Disable status display: ORADBA_SHOW_DB_STATUS=false
# - Reduce configuration complexity
# - Use local ORACLE_HOME instead of NFS
```

**Memory usage:**

```bash
# Check environment variables size
env | grep ORA | wc -l
env | grep ORA | wc -c

# Large environments (1000+ variables) may need limits adjustment
```

## Best Practices for Teams

When multiple DBAs and administrators work with OraDBA, following these practices ensures consistency and reduces
conflicts.

### Standardized Configuration Strategy

**Team configuration hierarchy:**

```text
Core config     (oradba_core.conf)      → OraDBA maintainers only
Standard config (oradba_standard.conf)  → OraDBA maintainers only
Local config    (oradba_local.conf)     → Auto-generated, don't edit
Customer config (oradba_customer.conf)  → Team standards, approved changes
SID default     (sid._DEFAULT_.conf)    → Database defaults template
SID specific    (sid.DBNAME.conf)       → Individual DBA, specific needs
```

**Recommendation:**

- **oradba_customer.conf**: Team-wide settings (approved by team lead)
- **sid._DEFAULT_.conf**: Common database defaults (backup paths, log settings)
- **sid.DBNAME.conf**: Database-specific overrides (different ORACLE_HOME, Grid)

### Version Control for Configurations

Store team configurations in version control:

```bash
# Create configuration repository
mkdir -p /opt/oracle/config_repo
cd /opt/oracle/config_repo
git init

# Add team configurations
cp /opt/oradba/etc/oradba_customer.conf .
cp /opt/oradba/etc/sid._DEFAULT_.conf .

# Add database-specific configs
cp /opt/oradba/etc/sid.*.conf .

# Commit
git add .
git commit -m "Initial OraDBA configuration"

# Push to team repository
git remote add origin https://git.company.com/dba/oradba-config.git
git push -u origin main
```

**Configuration deployment:**

```bash
# On new server or after updates
cd /opt/oracle/config_repo
git pull

# Deploy team configurations
cp oradba_customer.conf /opt/oradba/etc/
cp sid._DEFAULT_.conf /opt/oradba/etc/
cp sid.*.conf /opt/oradba/etc/ 2>/dev/null || true

# Reload environment
source oraenv.sh PRODDB
```

### Documentation Standards

**Maintain configuration documentation:**

```bash
# Create README in config repository
cat > /opt/oracle/config_repo/README.md <<'EOF'
# OraDBA Configuration - DBA Team

## Overview
Team-standard OraDBA configurations for all database servers.

## Configuration Files

### oradba_customer.conf
Team-wide settings:
- Standard backup paths: /backup
- Standard log paths: /opt/oradba/log
- Custom tools: /opt/dba_tools/bin in PATH

### sid._DEFAULT_.conf
Database defaults:
- BACKUP_DIR=/backup/${ORACLE_SID}
- LOG_DIR=/opt/oradba/log/${ORACLE_SID}

### sid.PRODDB.conf
Production database specific:
- ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
- GRID_HOME=/u01/app/grid/product/19.0.0/grid_home
- Special monitoring paths

## Change Management
1. Propose changes via pull request
2. Review by team lead required
3. Test on DEV servers first
4. Document changes in CHANGELOG.md

## Deployment
See deployment.sh script for automated rollout.
EOF
```

**Change management process:**

1. Create feature branch for changes
2. Test on development server
3. Submit pull request
4. Team lead reviews and approves
5. Merge to main branch
6. Deploy to production servers

### Oracle Homes Standardization

**Maintain team Oracle Homes registry:**

```bash
# Export standard Oracle Homes configuration
oradba_homes.sh export > /opt/oracle/config_repo/oracle_homes.conf

# Commit to repository
cd /opt/oracle/config_repo
git add oracle_homes.conf
git commit -m "Updated Oracle Homes registry"
git push

# Deploy to new servers
oradba_homes.sh import /opt/oracle/config_repo/oracle_homes.conf
```

**Naming conventions:**

```bash
# Standardize Oracle Home naming across team
db19c      → Oracle Database 19c (19.3.0.0.0)
db21c      → Oracle Database 21c (21.3.0.0.0)
grid19c    → Grid Infrastructure 19c
client19c  → Oracle Client 19c
oud12      → Oracle Unified Directory 12c
```

### Shared Scripts and Extensions

**Team extension for common tools:**

```bash
# Create team extension
oradba_extension.sh create dba_team

# Add team-specific scripts
cd /opt/oracle/local/dba_team
cat > bin/backup_all.sh <<'EOF'
#!/usr/bin/env bash
# Team standard backup script
for sid in $(grep -v "^#" /etc/oratab | cut -d: -f1); do
    # Source environment using dot notation for compatibility
    . oraenv.sh $sid --silent
    oradba_rman.sh --sid $sid --rcv backup_full.rcv
done
EOF

chmod +x bin/backup_all.sh

# Update extension metadata
cat > .extension <<'EOF'
NAME="dba_team"
DESCRIPTION="DBA Team Shared Scripts"
VERSION="1.0.0"
AUTHOR="DBA Team"
LOAD_ORDER=50
EOF
```

**Share extension via repository:**

```bash
# Create extensions repository
mkdir -p /opt/oracle/extensions_repo
cd /opt/oracle/extensions_repo

# Add team extension
cp -r /opt/oracle/local/dba_team .
git init
git add .
git commit -m "Initial DBA team extension"

# Deploy to other servers
git clone https://git.company.com/dba/oradba-extensions.git /tmp/ext
cp -r /tmp/ext/dba_team /opt/oracle/local/
```

### Environment Consistency Checks

**Audit script for team consistency:**

```bash
# Create consistency check script
cat > /opt/dba_tools/bin/oradba_audit.sh <<'EOF'
#!/usr/bin/env bash
# Check OraDBA consistency across servers

echo "=== OraDBA Configuration Audit ==="
echo "Server: $(hostname)"
echo "Date: $(date)"
echo

# Check OraDBA version
echo "OraDBA Version:"
cat /opt/oradba/VERSION

# Check team configuration exists
echo "Team Configuration:"
if [[ -f /opt/oradba/etc/oradba_customer.conf ]]; then
    md5sum /opt/oradba/etc/oradba_customer.conf
else
    echo "ERROR: oradba_customer.conf not found"
fi

# Check Oracle Homes count
echo "Oracle Homes Registered:"
oradba_homes.sh list | tail -n +2 | wc -l

# Check databases in oratab
echo "Databases in oratab:"
grep -v "^#" /etc/oratab | grep -v "^$" | wc -l

# List SID configs
echo "Database Specific Configs:"
ls -1 /opt/oradba/etc/sid.*.conf 2>/dev/null | wc -l

echo
echo "=== End Audit ==="
EOF

chmod +x /opt/dba_tools/bin/oradba_audit.sh
```

**Run consistency checks:**

```bash
# Run on all servers
for server in dbserver1 dbserver2 dbserver3; do
    echo "=== $server ==="
    ssh $server /opt/dba_tools/bin/oradba_audit.sh
    echo
done
```

### Training and Onboarding

**New team member checklist:**

1. **Install OraDBA**

   ```bash
   curl -L https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh \
       | bash
   ```

2. **Deploy team configurations**

   ```bash
   cd /tmp
   git clone https://git.company.com/dba/oradba-config.git
   cd oradba-config
   ./deploy.sh
   ```

3. **Import Oracle Homes**

   ```bash
   oradba_homes.sh import /tmp/oradba-config/oracle_homes.conf
   ```

4. **Test environment**

   ```bash
   source oraenv.sh TESTDB
   sq
   # Try SQL*Plus connection
   ```

5. **Review team documentation**
   - Configuration standards
   - Naming conventions
   - Change management process
   - Common troubleshooting steps

**Training resources for teams:**

```bash
# Create team training directory
mkdir -p /opt/oracle/training/oradba

# Add quick reference cards
cat > /opt/oracle/training/oradba/quickref.md <<'EOF'
# OraDBA Quick Reference - DBA Team

## Setting Environment
source oraenv.sh DBNAME       # Set environment for database
source oraenv.sh              # Interactive selection
free                          # Shortcut for FREE database

## Common Commands
sq                           # sqlplus / as sysdba
sq pdb1                      # sqlplus to PDB
cdh                          # cd $ORACLE_HOME
taa                          # tail -f alert.log

## Service Management
orastart                     # Start all services
orastop                      # Stop all services
dbstart                      # Start databases only
lsnrstart                    # Start listener only

## Status Checks
oraup.sh                     # Show all environments
dbstatus.sh                  # Current database status
orastatus                    # All services status

## Configuration
vi /opt/oradba/etc/oradba_customer.conf    # Team config
vi /opt/oradba/etc/sid.DBNAME.conf         # DB specific

## Help
alih                         # All aliases with descriptions
oraenv.sh --help            # Environment help
EOF
```

### Monitoring and Alerting

**Configuration change monitoring:**

```bash
# Monitor team configuration changes
cat > /opt/dba_tools/bin/config_watch.sh <<'EOF'
#!/usr/bin/env bash
# Monitor OraDBA configuration changes

CONFIG_DIR="/opt/oradba/etc"
CHECKSUMS="/var/tmp/oradba_checksums.txt"
ALERT_EMAIL="dba-team@company.com"

# Generate current checksums
current_checksums=$(md5sum $CONFIG_DIR/*.conf 2>/dev/null)

# Compare with previous
if [[ -f "$CHECKSUMS" ]]; then
    if ! diff -q <(echo "$current_checksums") "$CHECKSUMS" > /dev/null; then
        # Configuration changed
        echo "OraDBA configuration changed on $(hostname)" | \
            mail -s "OraDBA Config Change Alert" "$ALERT_EMAIL"
    fi
fi

# Save current checksums
echo "$current_checksums" > "$CHECKSUMS"
EOF

chmod +x /opt/dba_tools/bin/config_watch.sh

# Add to cron (daily check)
echo "0 8 * * * /opt/dba_tools/bin/config_watch.sh" | crontab -
```

### Knowledge Sharing

**Team wiki integration:**

1. **Document common scenarios** in team wiki
2. **Link to OraDBA documentation** for reference
3. **Share troubleshooting experiences** in team meetings
4. **Create runbooks** for standard procedures
5. **Maintain FAQ** for OraDBA questions

**Communication channels:**

- Team chat channel for quick questions
- Monthly review of configuration changes
- Quarterly OraDBA training sessions
- Annual review of team standards

## Summary

This advanced configuration guide covered:

- **Multi-version Oracle Home Management**: Registering, discovering, and switching between multiple Oracle
  installations
- **ASM and Grid Infrastructure**: Configuring Grid homes, ASM instances, and managing Grid services
- **Read-Only Oracle Home (ROOH)**: Understanding ROOH architecture, automatic detection, and configuration
- **Custom PATH and LD_LIBRARY_PATH**: Advanced path manipulation techniques and troubleshooting
- **Product-Specific Configurations**: Setting up DataSafe connectors, OUD, and WebLogic Server
- **Configuration Troubleshooting**: Diagnostic tools, common problems, and systematic resolution approaches
- **Best Practices for Teams**: Standardization, version control, documentation, and team coordination

For additional assistance:

- **User Documentation**: [OraDBA User Guide](https://code.oradba.ch/oradba)
- **Configuration Reference**: [Configuration System](configuration.md)
- **Environment Management**: [Environment Management Guide](environment.md)
- **Troubleshooting**: [Troubleshooting Guide](troubleshooting.md)
- **Extensions**: [Extension System Guide](extensions.md)
- **GitHub Issues**: [Report Issues](https://github.com/oehrlis/oradba/issues)
- **GitHub Discussions**: [Ask Questions](https://github.com/oehrlis/oradba/discussions)
