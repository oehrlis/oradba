# Database Operations

Database-specific operations including query execution, status checks, and database management.

---

### `check_database_connection` {: #check_database_connection }

Check if database is accessible and return connection status

**Source:** `oradba_db_functions.sh`

**Returns:** 0 if connected, 1 if not

---
### `format_uptime` {: #format_uptime }

Format uptime from timestamp

**Source:** `oradba_db_functions.sh`

**Returns:** Formatted string like "2025-12-15 20:37 (0d 0h 8m)"

---
### `get_database_open_mode` {: #get_database_open_mode }

Get the current database open mode

**Source:** `oradba_db_functions.sh`

**Returns:** Open mode string or empty if not accessible

---
### `query_database_info` {: #query_database_info }

Query v$database (available in MOUNT and higher)

**Source:** `oradba_db_functions.sh`

**Returns:** Pipe-separated values: DB_NAME|DB_UNIQUE_NAME|DBID|LOG_MODE|...

---
### `query_datafile_size` {: #query_datafile_size }

Query total datafile size (available in MOUNT and higher)

**Source:** `oradba_db_functions.sh`

**Returns:** Size in GB

---
### `query_instance_info` {: #query_instance_info }

Query v$instance and v$parameter (available in NOMOUNT and higher)

**Source:** `oradba_db_functions.sh`

**Returns:** Pipe-separated values: INSTANCE_NAME|STATUS|STARTUP_TIME|VERSION|...

---
### `query_memory_usage` {: #query_memory_usage }

Query current memory usage (available in MOUNT and OPEN)

**Source:** `oradba_db_functions.sh`

**Returns:** SGA|PGA in GB

---
### `query_pdb_info` {: #query_pdb_info }

Query pluggable database information (available in OPEN for CDB)

**Source:** `oradba_db_functions.sh`

**Returns:** PDB_NAME1(MODE1), PDB_NAME2(MODE2), ...

---
### `query_sessions_info` {: #query_sessions_info }

Query session information (available in MOUNT and OPEN)

**Source:** `oradba_db_functions.sh`

**Returns:** NON_ORACLE_USERS|NON_ORACLE_SESSIONS|ORACLE_USERS|ORACLE_SESSIONS

---
### `show_database_status` {: #show_database_status }

Display comprehensive database status based on open mode

**Source:** `oradba_db_functions.sh`

---
### `show_oracle_home_status` {: #show_oracle_home_status }

Display Oracle Home environment info for non-database homes

**Source:** `oradba_db_functions.sh`

---
