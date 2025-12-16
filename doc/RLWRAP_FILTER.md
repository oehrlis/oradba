# RLWRAP Filter for Password Hiding

## Overview

The OraDBA rlwrap filter provides password hiding functionality for SQL*Plus and
RMAN command history. When enabled, passwords entered in interactive sessions are
not saved to the readline history file.

## Prerequisites

- `rlwrap` installed
- Perl with `RlwrapFilter` module

To install the Perl module:

```bash
# RHEL/Oracle Linux
sudo cpan RlwrapFilter

# Or install from distribution packages if available
sudo yum install perl-RlwrapFilter
```

## Configuration

### Enable Password Filtering

Add to your `oradba_customer.conf`:

```bash
# Enable rlwrap password filter
export ORADBA_RLWRAP_FILTER="true"
```

### Custom Filter Path

If you have a custom filter script:

```bash
export ORADBA_RLWRAP_FILTER_PATH="/path/to/your/filter"
```

## Features

### Password Prompt Detection

The filter detects common Oracle password prompts:

- `password:`
- `Enter password:`
- `SYS password:`
- `SYSTEM password:`
- `RMAN password:`
- `Catalog password:`
- `Target password:`

### CONNECT Command Masking

CONNECT commands with embedded passwords are masked:

```sql
-- Input:
CONNECT user/password@database

-- Saved in history as:
CONNECT user/@database
```

### CREATE USER Masking

CREATE/ALTER USER statements with passwords are masked:

```sql
-- Input:
CREATE USER myuser IDENTIFIED BY mypassword;

-- Saved in history as:
CREATE USER myuser IDENTIFIED BY ***HIDDEN***;
```

## Affected Aliases

When `ORADBA_RLWRAP_FILTER=true`, these aliases use the filter:

- `sqh` - SQL*Plus with history and password filter
- `sqlplush` - SQL*Plus /nolog with history and password filter  
- `sqoh` - SQL*Plus as SYSOPER with history and password filter
- `rmanh` - RMAN with history and password filter
- `rmanch` - RMAN with catalog and password filter

## Testing

1. Enable the filter:

    ```bash
    export ORADBA_RLWRAP_FILTER="true"
    source oraenv.sh ORCL
    ```

2. Use sqh to connect:

    ```bash
    sqh
    SQL> CONNECT sys/oracle@orcl as sysdba
    ```

3. Check history (Ctrl+R or ~/.sqlplus_history):

    ```bash
    # Password should be masked or not present
    ```

## Limitations

- Only works with rlwrap-enabled aliases (sqh, rmanh, not sq or rman)
- Requires Perl RlwrapFilter module
- May not catch all password patterns in complex SQL scripts
- Filter runs for each command, minimal performance impact

## Troubleshooting

### Filter Not Working

Check if rlwrap filter is executable:

```bash
ls -l ${ORADBA_ETC}/rlwrap_filter_oracle
```

Should show: `-rwxr-xr-x`

### Module Not Found

Install RlwrapFilter:

```bash
sudo cpan RlwrapFilter
```

Or check your Perl module path:

```bash
perl -e 'print join("\n", @INC)'
```

### Test Filter Manually

```bash
echo "test" | rlwrap -z ${ORADBA_ETC}/rlwrap_filter_oracle cat
```

## Security Considerations

- The filter helps prevent passwords from appearing in:
  - `~/.sqlplus_history`
  - `~/.rman_history`  
  - Command history (Ctrl+R searches)

- Passwords may still appear in:
  - Process listings (`ps aux`)
  - Shell history (`~/.bash_history`) if typed at command line
  - SQL audit logs
  - Alert logs (failed connections)

- For maximum security:
  - Use Oracle Wallet for password management
  - Use Kerberos or other external authentication
  - Avoid embedding passwords in scripts
  - Set proper permissions on history files

## Examples

### Enable for All Users

In `/etc/oradba/oradba_customer.conf`:

```bash
export ORADBA_RLWRAP_FILTER="true"
```

### Enable for Specific User

In `~/.oradba/oradba_customer.conf`:

```bash
export ORADBA_RLWRAP_FILTER="true"
```

### Enable for Specific SID

In `sid.PRODDB.conf`:

```bash
export ORADBA_RLWRAP_FILTER="true"
```

### Disable Temporarily

```bash
export ORADBA_RLWRAP_FILTER="false"
source oraenv.sh ORCL
```

## References

- rlwrap man page: `man rlwrap`
- rlwrap filters: `/usr/share/rlwrap/filters/`
- RlwrapFilter CPAN: <https://metacpan.org/pod/RlwrapFilter>
