# OraDBA Shell Libraries

Shared shell libraries providing common functionality for OraDBA scripts.

## Available Libraries

- **[common.sh](common.sh)** - Core utility functions (logging, oratab parsing, etc.)
- **[db_functions.sh](db_functions.sh)** - Database query and status functions

## Usage

Source libraries in your scripts:

```bash
source "${ORADBA_BASE}/lib/common.sh"
source "${ORADBA_BASE}/lib/db_functions.sh"
```

## Documentation

See [DEVELOPMENT.md](../../doc/DEVELOPMENT.md) for detailed API documentation
and coding guidelines.

## Functions Overview

### common.sh

- Logging (log_info, log_error, log_debug)
- oratab parsing (parse_oratab, list_oracle_sids)
- Environment validation
- Configuration management

### db_functions.sh

- Database status queries
- PDB information
- Memory and resource monitoring
- SQL execution helpers

For complete function signatures and usage, see the source files.
