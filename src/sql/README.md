# SQL Scripts

SQL scripts for Oracle Database administration and diagnostics.

## Overview

This directory contains SQL scripts for database queries, user information, and
session management. These scripts are designed to be executed directly from
SQL*Plus or SQLcl, and can be used standalone or invoked by OraDBA aliases.

## Available Scripts

| Script                             | Description                                    |
|------------------------------------|------------------------------------------------|
| [db_info.sql](db_info.sql)         | Database instance and version information      |
| [login.sql](login.sql)             | SQL*Plus login script (glogin.sql replacement) |
| [sessionsql.sql](sessionsql.sql)   | Session query and diagnostic script            |
| [ssec_usrinf.sql](ssec_usrinf.sql) | Security user information report               |
| [whoami.sql](whoami.sql)           | Current user and session details               |

**Total Scripts:** 5

## Usage

### From SQL*Plus/SQLcl

```sql
-- Run whoami script
SQL> @${ORADBA_BASE}/sql/whoami.sql

-- Or use short path if SQLPATH is configured
SQL> @whoami
```

### From Shell (via aliases)

```bash
# Use the 'sql' alias to run SQL scripts
sql @whoami

# Or invoke directly
sqlplus / as sysdba @$ORADBA_BASE/sql/db_info.sql
```

### Login Script

The `login.sql` script is automatically executed when starting SQL*Plus if `SQLPATH` includes the sql directory:

```bash
export SQLPATH=$ORADBA_BASE/sql:$SQLPATH
sqlplus / as sysdba
# login.sql runs automatically, setting up formatting and aliases
```

## Script Features

### Database Information (db_info.sql)

- Database name and version
- Instance details
- Startup time and status
- Character set information
- Database options installed

### Session Information (whoami.sql)

- Current user and schema
- Session ID and serial#
- Connection details
- Privilege information
- Current container (for CDB/PDB)

### User Security Report (ssec_usrinf.sql)

- User account status
- Password profile
- Granted roles and privileges
- Last login information
- Account expiry details

## Customization

### Adding Custom Scripts

1. Place SQL scripts in this directory
2. Follow naming convention (lowercase, descriptive)
3. Include header comment with description
4. Test with different privilege levels

### Login Script Customization

Create `~/.sqlplus/login.sql` for user-specific settings that override the default `login.sql`.

## Integration

### SQLPATH Configuration

OraDBA automatically configures `SQLPATH` to include this directory:

```bash
SQLPATH=$ORADBA_BASE/sql:$ORACLE_HOME/sqlplus/admin
```

This allows running scripts by name without full path:

```sql
SQL> @whoami
```

### Alias Integration

Several OraDBA aliases invoke these scripts:

- `sql` - Start SQL*Plus with configured SQLPATH
- `sqls` - SQL*Plus as SYSDBA
- Custom aliases can reference scripts in this directory

## Documentation

- **[SQL Scripts](../doc/08-sql-scripts.md)** - Detailed script documentation
- **[Configuration](../doc/05-configuration.md)** - SQLPATH configuration
- **[Aliases](../doc/06-aliases.md)** - Shell aliases for SQL scripts

## Development

### Script Guidelines

1. **Header**: Include standard header with purpose, author, version
2. **Comments**: Document parameters and requirements
3. **Privileges**: Note minimum required privileges
4. **Output**: Format output for readability
5. **Errors**: Handle common error conditions gracefully

### Testing

Test scripts with different:

- Privilege levels (regular user, DBA, SYSDBA)
- Database versions (12c, 19c, 21c, 23ai)
- Container contexts (CDB$ROOT, PDB)

See [development.md](../../doc/development.md) for coding standards.
