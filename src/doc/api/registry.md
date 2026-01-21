# Registry API

Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.

---

### `oradba_registry_discover_all` {: #oradba_registry_discover_all }

Auto-discover Oracle installations on the system

**Source:** `oradba_registry.sh`

**Returns:** 0 on success

**Output:** List of discovered installation objects

!!! info "Notes"
    Scans common locations and running processes

---
### `oradba_registry_get_all` {: #oradba_registry_get_all }

Get all Oracle installations (databases + homes)

**Source:** `oradba_registry.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 on error

**Output:** List of installation objects (one per line)

!!! info "Notes"
    Combines oratab and oradba_homes.conf entries

---
### `oradba_registry_get_by_name` {: #oradba_registry_get_by_name }

Get installation by name (SID or home name)

**Source:** `oradba_registry.sh`

**Arguments:**

- $1 - Installation name to search for

**Returns:** 0 on success, 1 if not found

**Output:** Installation object if found

---
### `oradba_registry_get_by_type` {: #oradba_registry_get_by_type }

Get all installations of specific product type

**Source:** `oradba_registry.sh`

**Arguments:**

- $1 - Product type (database, datasafe, client, oud, etc.)

**Returns:** 0 on success

**Output:** List of installation objects matching type

---
### `oradba_registry_get_databases` {: #oradba_registry_get_databases }

Get all database installations

**Source:** `oradba_registry.sh`

**Returns:** 0 on success

**Output:** List of database installation objects

---
### `oradba_registry_get_field` {: #oradba_registry_get_field }

Extract specific field from installation object

**Source:** `oradba_registry.sh`

**Arguments:**

- $1 - Installation object
- $2 - Field name (type|name|home|version|flags|order|alias|desc)

**Returns:** 0 on success, 1 on error

**Output:** Field value

---
### `oradba_registry_sync_oratab` {: #oradba_registry_sync_oratab }

Sync database homes from oratab to oradba_homes.conf

**Source:** `oradba_registry.sh`

**Arguments:**

- $1 - (Optional) Force sync even if home exists (default: false)

**Returns:** 0 on success, 1 on error

**Output:** Number of homes added

!!! info "Notes"
    Deduplicates homes - only adds unique ORACLE_HOME paths
    Updates existing entries if they differ

---
### `oradba_registry_validate` {: #oradba_registry_validate }

Validate registry format and consistency

**Source:** `oradba_registry.sh`

**Returns:** 0 if valid, 1 if errors found

**Output:** Validation errors (if any)

---
