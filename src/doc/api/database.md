# Database Operations

Database-specific operations including query execution, status checks, and database management.

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `check_database_connection`

---

### ``

Check if database is accessible and return connection status

---

### ``

---

### ``

**Returns:** 0 if connected, 1 if not

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `get_database_open_mode`

---

### ``

Get the current database open mode

---

### ``

---

### ``

**Returns:** Open mode string or empty if not accessible

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_instance_info`

---

### ``

Query v$instance and v$parameter (available in NOMOUNT and higher)

---

### ``

---

### ``

**Returns:** Pipe-separated values: INSTANCE_NAME|STATUS|STARTUP_TIME|VERSION|...

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_database_info`

---

### ``

Query v$database (available in MOUNT and higher)

---

### ``

---

### ``

**Returns:** Pipe-separated values: DB_NAME|DB_UNIQUE_NAME|DBID|LOG_MODE|...

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_datafile_size`

---

### ``

Query total datafile size (available in MOUNT and higher)

---

### ``

---

### ``

**Returns:** Size in GB

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_memory_usage`

---

### ``

Query current memory usage (available in MOUNT and OPEN)

---

### ``

---

### ``

**Returns:** SGA|PGA in GB

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_sessions_info`

---

### ``

Query session information (available in MOUNT and OPEN)

---

### ``

---

### ``

**Returns:** NON_ORACLE_USERS|NON_ORACLE_SESSIONS|ORACLE_USERS|ORACLE_SESSIONS

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `query_pdb_info`

---

### ``

Query pluggable database information (available in OPEN for CDB)

---

### ``

---

### ``

**Returns:** PDB_NAME1(MODE1), PDB_NAME2(MODE2), ...

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `format_uptime`

---

### ``

Format uptime from timestamp

---

### ``

---

### ``

**Returns:** Formatted string like "2025-12-15 20:37 (0d 0h 8m)"

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `show_oracle_home_status`

---

### ``

Display Oracle Home environment info for non-database homes

---

### ``

---

### ``

---

### ``

---

### ``

**Source:** `oradba_db_functions.sh`

---

### ``

---

### `show_database_status`

---

### ``

Display comprehensive database status based on open mode

---

### ``

---

### ``

---

### ``

---

