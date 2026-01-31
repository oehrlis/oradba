# Extension System

Extension system for loading and managing OraDBA extensions.

---

## Functions

### `create_extension_alias` {: #create-extension-alias }

Create navigation alias for extension

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension name
- $2 - Extension path

**Returns:** 0 on success

**Output:** Creates alias like cde\<name\> (cd extension)

---

### `deduplicate_path` {: #deduplicate-path }

Deduplicate PATH (keep first occurrence)

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Updates PATH environment variable

!!! info "Notes"
    Uses oradba_dedupe_path() from oradba_env_builder.sh if available

---

### `deduplicate_sqlpath` {: #deduplicate-sqlpath }

Deduplicate SQLPATH (keep first occurrence)

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Updates SQLPATH environment variable

!!! info "Notes"
    Uses oradba_dedupe_path() from oradba_env_builder.sh if available

---

### `discover_extensions` {: #discover-extensions }

Discover extensions in ORADBA_LOCAL_BASE

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** List of extension paths (one per line) containing .extension marker file

---

### `extension_provides` {: #extension-provides }

**Source:** `extensions.sh`

---

### `get_all_extensions` {: #get-all-extensions }

Get all extensions (auto-discovered + manually configured)

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** List of extension paths (one per line)

---

### `get_extension_description` {: #get-extension-description }

Get extension description from metadata

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 on success

**Output:** Description string or empty

---

### `get_extension_name` {: #get-extension-name }

Get extension name from metadata or directory name

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 on success

**Output:** Extension name

---

### `get_extension_priority` {: #get-extension-priority }

Get extension priority for sorting

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 on success

**Output:** Priority number (lower = loaded first, default 50)

---

### `get_extension_property` {: #get-extension-property }

Unified property accessor for extension metadata

**Source:** `extensions.sh`

**Returns:** Property value from metadata, config override, or fallback

---

### `get_extension_version` {: #get-extension-version }

Get extension version from metadata

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 on success

**Output:** Version string or "unknown"

---

### `is_extension_enabled` {: #is-extension-enabled }

Check if extension is enabled

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension name
- $2 - Extension path

**Returns:** 0 if enabled, 1 if disabled

**Output:** None

---

### `load_extension` {: #load-extension }

Load single extension

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 on success, 1 on error (with warning)

**Output:** Updates PATH/SQLPATH, sources library files, creates aliases

---

### `load_extensions` {: #load-extensions }

Load all enabled extensions

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Updates PATH and SQLPATH with extension directories

!!! info "Notes"
    Called from oraenv.sh after configuration loading

---

### `parse_extension_metadata` {: #parse-extension-metadata }

Parse extension metadata file for key-value pairs

**Source:** `extensions.sh`

**Arguments:**

- $1 - Metadata file path
- $2 - Key to retrieve

**Returns:** 0 on success, 1 if file not found

**Output:** Value for the given key, or empty string if not found

---

### `remove_extension_paths` {: #remove-extension-paths }

Remove extension paths from PATH and SQLPATH

**Source:** `extensions.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Updates PATH and SQLPATH environment variables

---

### `show_extension_info` {: #show-extension-info }

Show detailed information about a specific extension

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension name or path

**Returns:** 0 on success, 1 on error

**Output:** Detailed extension information including structure and navigation alias

---

### `sort_extensions_by_priority` {: #sort-extensions-by-priority }

Sort extensions by priority for loading order

**Source:** `extensions.sh`

**Arguments:**

- $@ - Extension paths (space-separated)

**Returns:** 0 on success

**Output:** Sorted list of extension paths (one per line)

---

### `validate_extension` {: #validate-extension }

Validate extension structure (basic check)

**Source:** `extensions.sh`

**Arguments:**

- $1 - Extension path

**Returns:** 0 if valid, 1 if warnings found

**Output:** Validation messages and warnings

---
