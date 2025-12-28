# rlwrap Filter Configuration

**Purpose:** Guide to optional password filtering for rlwrap-enabled Oracle tool aliases.

**Audience:** Users concerned with command history security.

**Prerequisites:**
- rlwrap installed
- Perl with RlwrapFilter module

## Introduction

OraDBA supports optional password filtering for rlwrap-enabled aliases. When
enabled, passwords are hidden from command history files, improving security
when using interactive Oracle tools.

## What is rlwrap?

[rlwrap](https://github.com/hanslub42/rlwrap) (readline wrapper) provides
command-line history and editing for programs that don't natively support it.
OraDBA automatically uses rlwrap with SQL*Plus, RMAN, and other Oracle tools
when available.

**Benefits:**

- Command history (up/down arrows)
- Tab completion with keywords
- Line editing (Emacs/vi modes)
- History search (Ctrl+R)
- Optional password filtering

## Password Filtering

Password filtering removes sensitive information from command history, preventing:

- Plain-text passwords in `~/.sqlplus_history`
- Connection strings with passwords in `~/.rman_history`
- CREATE/ALTER USER statements with passwords

**Example:**

```sql
-- Input command:
CONNECT scott/tiger@orcl

-- Saved in history as:
CONNECT scott/@orcl
```

## Requirements

### 1. Install rlwrap

**RHEL/Oracle Linux/CentOS:**

```bash
sudo yum install rlwrap
```

**Ubuntu/Debian:**

```bash
sudo apt-get install rlwrap
```

**macOS:**

```bash
brew install rlwrap
```

### 2. Install Perl RlwrapFilter Module

The password filter requires the Perl RlwrapFilter module:

```bash
# Check if installed
perl -MRlwrapFilter -e 'print "OK\n"'

# Install using CPAN
sudo cpan RlwrapFilter

# Or on Debian/Ubuntu
sudo apt-get install libterm-readline-gnu-perl
```

## Enable Password Filtering

### Global Configuration

Enable for all databases in `oradba_customer.conf`:

```bash
# Enable password filtering
export ORADBA_RLWRAP_FILTER="true"
```

### Per-Database Configuration

Enable for specific database in `sid.FREE.conf`:

```bash
# Enable password filtering only for FREE database
export ORADBA_RLWRAP_FILTER="true"
```

### Apply Configuration

```bash
# Reload environment
source oraenv.sh FREE

# Test - check alias definition
type sqh

# Should show -z option with filter path
# rlwrap ... -z "/opt/oradba/etc/rlwrap_filter_oracle" sqlplus / as sysdba
```

## What Gets Filtered

### SQL*Plus Commands

```sql
-- CONNECT statements
CONNECT user/password@db        → CONNECT user/@db
conn user/password              → conn user/

-- CREATE/ALTER USER
CREATE USER scott IDENTIFIED BY tiger;
                                → CREATE USER scott IDENTIFIED BY ***FILTERED***;

ALTER USER scott IDENTIFIED BY newpass;
                                → ALTER USER scott IDENTIFIED BY ***FILTERED***;
```

### RMAN Commands

```rman
-- CONNECT statements
CONNECT TARGET user/password@db  → CONNECT TARGET user/@db
CONNECT CATALOG rman/password@cat → CONNECT CATALOG rman/@cat
```

## Affected Aliases

When `ORADBA_RLWRAP_FILTER=true`, these aliases use password filtering:

**SQL*Plus:**

- `sqh` - SQL*Plus as SYSDBA with rlwrap
- `sqlplush` - SQL*Plus /nolog with rlwrap
- `sqoh` - SQL*Plus as SYSOPER with rlwrap

**RMAN:**

- `rmanh` - RMAN with rlwrap
- `rmanch` - RMAN with catalog and rlwrap

**ADRCI:**

- `adrcih` - ADRCI with rlwrap

## Testing Password Filtering

### Test Setup

```bash
# Enable filtering
export ORADBA_RLWRAP_FILTER="true"
source oraenv.sh FREE

# Connect using filtered alias
sqh
```

### Test Scenarios

```sql
-- Test 1: CONNECT with password
SQL> CONNECT system/password@orcl
Connected.

-- Test 2: CREATE USER
SQL> CREATE USER testuser IDENTIFIED BY testpass;
User created.

-- Exit and check history
SQL> EXIT

# Check history file
$ tail ~/.sqlplus_history

# Should show filtered versions:
# CONNECT system/@orcl
# CREATE USER testuser IDENTIFIED BY ***FILTERED***;
```

## Troubleshooting

### Filter Not Working

**Check if filter is enabled:**

```bash
echo $ORADBA_RLWRAP_FILTER
# Should show: true
```

**Check alias configuration:**

```bash
type sqh
# Should include: -z "/opt/oradba/etc/rlwrap_filter_oracle"
```

**Verify filter script exists:**

```bash
ls -l /opt/oradba/etc/rlwrap_filter_oracle
# Should exist and be executable
```

**Check Perl module:**

```bash
perl -MRlwrapFilter -e 'print "OK\n"'
# Should print: OK
```

### rlwrap Not Found

```bash
# Check if rlwrap is installed
which rlwrap

# Install if missing
# RHEL/OL
sudo yum install rlwrap

# Ubuntu/Debian
sudo apt-get install rlwrap

# macOS
brew install rlwrap
```

### Perl Module Missing

```bash
# Check for module
perl -MRlwrapFilter -e 'print "OK\n"'

# Install if missing
sudo cpan RlwrapFilter

# Or on Debian/Ubuntu
sudo apt-get install libterm-readline-gnu-perl libreadline-dev
```

### History Still Shows Passwords

**Possible causes:**

1. **Filter not enabled** - Check `ORADBA_RLWRAP_FILTER=true`
2. **Not using filtered alias** - Use `sqh` not `sq`
3. **Old history entries** - Filter doesn't retroactively clean history
4. **Perl module not installed** - Check RlwrapFilter module

**Clean old history:**

```bash
# Backup and clean SQL*Plus history
mv ~/.sqlplus_history ~/.sqlplus_history.bak

# Backup and clean RMAN history
mv ~/.rman_history ~/.rman_history.bak
```

## Security Considerations

1. **Not Perfect** - Filter catches common patterns but may miss some edge cases
2. **Old History** - Doesn't clean existing history files
3. **Other Tools** - Only works with rlwrap-enabled aliases
4. **Local Security** - History files stored locally; secure your workstation
5. **Production** - Consider using Oracle Wallet for production connections
6. **SSH Sessions** - History files remain on remote server if using SSH
7. **Backup History** - Consider deleting old history files before enabling filter

## Best Practices

1. **Enable in development** - Use for convenience and security in dev/test
2. **Use Wallet in production** - Oracle Wallet for production connections
3. **Regularly clean history** - Periodically remove old history files
4. **Test the filter** - Verify filtering works after enabling
5. **Document usage** - Note which environments use filtering
6. **Secure workstation** - History files only as secure as your workstation
7. **Consider alternatives** - OS authentication, Kerberos, Wallet for production

## Alternative Security Methods

Instead of or in addition to password filtering:

### Oracle Wallet

```bash
# Create wallet
mkstore -wrl /home/oracle/wallet -create

# Add credentials
mkstore -wrl /home/oracle/wallet -createCredential ORCL scott tiger

# Connect without password
sqlplus /@ORCL
```

### OS Authentication

```bash
# Connect as sysdba without password
sqlplus / as sysdba
```

### Kerberos Authentication

Configure Kerberos for enterprise authentication (no passwords needed).

## Disable Password Filtering

To disable password filtering:

```bash
# In oradba_customer.conf or sid.*.conf
export ORADBA_RLWRAP_FILTER="false"

# Or unset the variable
unset ORADBA_RLWRAP_FILTER

# Reload environment
source oraenv.sh FREE
```

Aliases will continue to use rlwrap but without password filtering.

## See Also

- [Aliases](06-aliases.md) - Complete alias reference with rlwrap
- [Configuration](05-configuration.md) - Setting ORADBA_RLWRAP_FILTER
- [Troubleshooting](12-troubleshooting.md) - rlwrap issues

## Navigation

**Previous:** [Database Functions Library](10-functions.md)  
**Next:** [Troubleshooting Guide](12-troubleshooting.md)
