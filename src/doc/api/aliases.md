# Alias Management

Alias generation and management for database environments.

---

## Functions

### `create_dynamic_alias` {: #create-dynamic-alias }

Create a shell alias with optional variable expansion

**Source:** `oradba_aliases.sh`

**Arguments:**

- $1 - Alias name (required)
- $2 - Alias command/value (required)
- $3 - "true" to expand variables at definition time (default: "false")

**Returns:** Exit code from safe_alias (0=created, 1=skipped, 2=error)

**Output:** Creates shell alias, handles shellcheck SC2139 suppression for expanded aliases

---

### `generate_base_aliases` {: #generate-base-aliases }

Generate OraDBA base directory alias

**Source:** `oradba_aliases.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Creates cdbase alias

---

### `generate_sid_aliases` {: #generate-sid-aliases }

Generate SID-specific aliases based on current ORACLE_SID

**Source:** `oradba_aliases.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Creates taa, vaa, via, cdd, cddt, cdda aliases

---

### `get_diagnostic_dest` {: #get-diagnostic-dest }

Get diagnostic_dest from database or fallback to convention

**Source:** `oradba_aliases.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Path to diagnostic_dest directory

---

### `has_rlwrap` {: #has-rlwrap }

Check if rlwrap command is available

**Source:** `oradba_aliases.sh`

**Arguments:**

- None

**Returns:** 0 if rlwrap is available, 1 otherwise

**Output:** None

---

### `oradba_tnsping` {: #oradba-tnsping }

Wrapper for tnsping that falls back to sqlplus -P for Instant Client

**Source:** `oradba_aliases.sh`

**Arguments:**

- All arguments passed to tnsping/sqlplus -P

**Returns:** Exit code from tnsping or sqlplus -P

!!! info "Notes"
    sqlplus -P limitations:
    - Does NOT support full connect descriptors like "(DESCRIPTION=...)"
    - Supports: TNS names (FREE, FREE.world), EZ Connect (host:port/service)
    - Shows notice in verbose/debug mode when falling back to sqlplus -P

---
