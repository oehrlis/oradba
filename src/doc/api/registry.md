# Registry API

Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_get_all`

---

### ``

Get all Oracle installations (databases + homes)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** List of installation objects (one per line)

---

### ``

!!! info "Notes"
    Combines oratab and oradba_homes.conf entries

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_get_by_name`

---

### ``

Get installation by name (SID or home name)

---

### ``

**Arguments:**

- $1 - Installation name to search for

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Installation object if found

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_get_by_type`

---

### ``

Get all installations of specific product type

---

### ``

**Arguments:**

- $1 - Product type (database, datasafe, client, oud, etc.)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of installation objects matching type

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_get_databases`

---

### ``

Get all database installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of database installation objects

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_get_field`

---

### ``

Extract specific field from installation object

---

### ``

**Arguments:**

- $1 - Installation object

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Field value

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_sync_oratab`

---

### ``

Sync database homes from oratab to oradba_homes.conf

---

### ``

**Arguments:**

- $1 - (Optional) Force sync even if home exists (default: false)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Number of homes added

---

### ``

!!! info "Notes"
    Deduplicates homes - only adds unique ORACLE_HOME paths

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_discover_all`

---

### ``

Auto-discover Oracle installations on the system

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of discovered installation objects

---

### ``

!!! info "Notes"
    Scans common locations and running processes

---

### ``

**Source:** `oradba_registry.sh`

---

### ``

---

### `oradba_registry_validate`

---

### ``

Validate registry format and consistency

---

### ``

---

### ``

**Returns:** 0 if valid, 1 if errors found

---

### ``

**Output:** Validation errors (if any)

---

