# Alias Management

Alias generation and management for database environments.

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `create_dynamic_alias`

---

### ``

Create a shell alias with optional variable expansion

---

### ``

**Arguments:**

- $1 - Alias name (required)

---

### ``

**Returns:** Exit code from safe_alias (0=created, 1=skipped, 2=error)

---

### ``

**Output:** Creates shell alias, handles shellcheck SC2139 suppression for expanded aliases

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `get_diagnostic_dest`

---

### ``

Get diagnostic_dest from database or fallback to convention

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Path to diagnostic_dest directory

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `has_rlwrap`

---

### ``

Check if rlwrap command is available

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if rlwrap is available, 1 otherwise

---

### ``

**Output:** None

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `oradba_tnsping`

---

### ``

Wrapper for tnsping that falls back to sqlplus -P for Instant Client

---

### ``

**Arguments:**

- All arguments passed to tnsping/sqlplus -P

---

### ``

**Returns:** Exit code from tnsping or sqlplus -P

---

### ``

---

### ``

!!! info "Notes"
    sqlplus -P limitations

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `generate_sid_aliases`

---

### ``

Generate SID-specific aliases based on current ORACLE_SID

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates taa, vaa, via, cdd, cddt, cdda aliases

---

### ``

**Source:** `oradba_aliases.sh`

---

### ``

---

### `generate_base_aliases`

---

### ``

Generate OraDBA base directory alias

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates cdbase alias

---

