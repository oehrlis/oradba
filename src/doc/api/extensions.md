# Extension System

Extension system for loading and managing OraDBA extensions.

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `discover_extensions`

---

### ``

Discover extensions in ORADBA_LOCAL_BASE

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of extension paths (one per line) containing .extension marker file

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_all_extensions`

---

### ``

Get all extensions (auto-discovered + manually configured)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of extension paths (one per line)

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_extension_property`

---

### ``

Unified property accessor for extension metadata

---

### ``

---

### ``

**Returns:** Property value from metadata, config override, or fallback

---

### ``

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `parse_extension_metadata`

---

### ``

Parse extension metadata file for key-value pairs

---

### ``

**Arguments:**

- $1 - Metadata file path

---

### ``

**Returns:** 0 on success, 1 if file not found

---

### ``

**Output:** Value for the given key, or empty string if not found

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_extension_name`

---

### ``

Get extension name from metadata or directory name

---

### ``

**Arguments:**

- $1 - Extension path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Extension name

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_extension_version`

---

### ``

Get extension version from metadata

---

### ``

**Arguments:**

- $1 - Extension path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Version string or "unknown"

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_extension_description`

---

### ``

Get extension description from metadata

---

### ``

**Arguments:**

- $1 - Extension path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Description string or empty

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `get_extension_priority`

---

### ``

Get extension priority for sorting

---

### ``

**Arguments:**

- $1 - Extension path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Priority number (lower = loaded first, default 50)

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `is_extension_enabled`

---

### ``

Check if extension is enabled

---

### ``

**Arguments:**

- $1 - Extension name

---

### ``

**Returns:** 0 if enabled, 1 if disabled

---

### ``

**Output:** None

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `extension_provides`

---

### ``

Sort extensions by priority for loading order

---

### ``

**Arguments:**

- $@ - Extension paths (space-separated)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Sorted list of extension paths (one per line)

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `sort_extensions_by_priority`

---

### ``

Sort extensions by priority for loading order

---

### ``

**Arguments:**

- $@ - Extension paths (space-separated)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Sorted list of extension paths (one per line)

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `remove_extension_paths`

---

### ``

Remove extension paths from PATH and SQLPATH

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Updates PATH and SQLPATH environment variables

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `deduplicate_path`

---

### ``

Deduplicate PATH (keep first occurrence)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Updates PATH environment variable

---

### ``

!!! info "Notes"
    Uses oradba_dedupe_path() from oradba_env_builder.sh if available

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `deduplicate_sqlpath`

---

### ``

Deduplicate SQLPATH (keep first occurrence)

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Updates SQLPATH environment variable

---

### ``

!!! info "Notes"
    Uses oradba_dedupe_path() from oradba_env_builder.sh if available

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `load_extensions`

---

### ``

Load all enabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Updates PATH and SQLPATH with extension directories

---

### ``

!!! info "Notes"
    Called from oraenv.sh after configuration loading

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `load_extensions`

---

### ``

Load all enabled extensions

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Updates PATH and SQLPATH with extension directories

---

### ``

!!! info "Notes"
    Called from oraenv.sh after configuration loading

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `create_extension_alias`

---

### ``

Create navigation alias for extension

---

### ``

**Arguments:**

- $1 - Extension name

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates alias like cde<name> (cd extension)

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `show_extension_info`

---

### ``

Show detailed information about a specific extension

---

### ``

**Arguments:**

- $1 - Extension name or path

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Detailed extension information including structure and navigation alias

---

### ``

**Source:** `extensions.sh`

---

### ``

---

### `validate_extension`

---

### ``

Validate extension structure (basic check)

---

### ``

**Arguments:**

- $1 - Extension path

---

### ``

**Returns:** 0 if valid, 1 if warnings found

---

### ``

**Output:** Validation messages and warnings

---

