#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: generate_api_docs.py
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.21
# Revision...: 0.19.1
# Purpose....: Generate API reference documentation from function headers
# Notes......: Extracts function headers from source files and generates
#              organized markdown documentation with categories and index.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

import re
import os
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
SRC_LIB_DIR = PROJECT_ROOT / "src" / "lib"
SRC_BIN_DIR = PROJECT_ROOT / "src" / "bin"
OUTPUT_DIR = PROJECT_ROOT / "src" / "doc" / "api"

# Category mappings
CATEGORY_MAP = {
    "oradba_common.sh": "common",
    "oradba_db_functions.sh": "database",
    "oradba_registry.sh": "registry",
    "oradba_aliases.sh": "aliases",
    "oradba_env_builder.sh": "environment",
    "oradba_env_changes.sh": "environment",
    "oradba_env_config.sh": "environment",
    "oradba_env_parser.sh": "environment",
    "oradba_env_status.sh": "environment",
    "oradba_env_validator.sh": "environment",
    "extensions.sh": "extensions",
}

CATEGORY_TITLES = {
    "common": "Core Utilities",
    "database": "Database Operations",
    "registry": "Registry API",
    "aliases": "Alias Management",
    "environment": "Environment Management",
    "extensions": "Extension System",
    "plugins": "Plugin Interface",
    "scripts": "Scripts and Commands",
}

CATEGORY_DESCRIPTIONS = {
    "common": "Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.",
    "database": "Database-specific operations including query execution, status checks, and database management.",
    "registry": "Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.",
    "aliases": "Alias generation and management for database environments.",
    "environment": "Environment management libraries for building, parsing, validating, and tracking Oracle environments.",
    "extensions": "Extension system for loading and managing OraDBA extensions.",
    "plugins": "Plugin interface for product-specific functionality (database, client, datasafe, java, etc.).",
    "scripts": "Command-line scripts and tools for OraDBA operations.",
}


class FunctionDoc:
    """Represents a parsed function documentation"""
    
    def __init__(self, name, source_file):
        self.name = name
        self.source_file = source_file
        self.purpose = ""
        self.args = []
        self.returns = ""
        self.output = ""
        self.notes = ""
        
    def to_markdown(self):
        """Generate markdown documentation for this function"""
        md = []
        
        # Function header with anchor
        md.append(f"### `{self.name}` {{: #{self.name} }}")
        md.append("")
        
        # Purpose
        if self.purpose:
            md.append(self.purpose)
            md.append("")
        
        # Source file
        md.append(f"**Source:** `{os.path.basename(self.source_file)}`")
        md.append("")
        
        # Arguments
        if self.args:
            md.append("**Arguments:**")
            md.append("")
            for arg in self.args:
                md.append(f"- {arg}")
            md.append("")
        
        # Returns
        if self.returns:
            md.append(f"**Returns:** {self.returns}")
            md.append("")
        
        # Output
        if self.output:
            md.append(f"**Output:** {self.output}")
            md.append("")
        
        # Notes
        if self.notes:
            md.append('!!! info "Notes"')
            for line in self.notes.split('\n'):
                md.append(f"    {line}" if line else "")
            md.append("")
        
        md.append("---")
        md.append("")
        
        return '\n'.join(md)


def get_category(file_path):
    """Determine category for a source file"""
    basename = os.path.basename(file_path)
    
    # Check specific file mappings
    if basename in CATEGORY_MAP:
        return CATEGORY_MAP[basename]
    
    # Check pattern mappings
    if basename.endswith("_plugin.sh") or basename == "plugin_interface.sh":
        return "plugins"
    elif basename.startswith("oradba_"):
        return "scripts"
    else:
        return "scripts"


def parse_function_header(file_path, start_line):
    """Parse a function header starting at the given line"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    func_doc = None
    i = start_line
    current_field = None
    
    while i < len(lines):
        line = lines[i].rstrip()
        i += 1
        
        # Check for function name
        if line.startswith("# Function:"):
            func_name = line.replace("# Function:", "").strip()
            func_doc = FunctionDoc(func_name, file_path)
            current_field = None
            continue
        
        if not func_doc:
            break
        
        # Check for purpose
        if line.startswith("# Purpose.:"):
            func_doc.purpose = line.replace("# Purpose.:", "").strip()
            current_field = "purpose"
            continue
        
        # Check for args
        if line.startswith("# Args...."):
            arg_text = line.replace("# Args....:", "").strip()
            if arg_text:
                func_doc.args.append(arg_text)
            current_field = "args"
            continue
        
        # Check for returns
        if line.startswith("# Returns."):
            func_doc.returns = line.replace("# Returns.:", "").strip()
            current_field = "returns"
            continue
        
        # Check for output
        if line.startswith("# Output.."):
            func_doc.output = line.replace("# Output..:", "").strip()
            current_field = "output"
            continue
        
        # Check for notes
        if line.startswith("# Notes..."):
            func_doc.notes = line.replace("# Notes...:", "").strip()
            current_field = "notes"
            continue
        
        # Check for separator line (end of header)
        if line.startswith("# ------"):
            break
        
        # Check for continuation lines
        if line.startswith("#          ") or line.startswith("#           "):
            continuation = line[11:].strip() if line.startswith("#          ") else line[12:].strip()
            if current_field == "args" and continuation:
                func_doc.args.append(continuation)
            elif current_field == "notes" and continuation:
                if func_doc.notes:
                    func_doc.notes += "\n" + continuation
                else:
                    func_doc.notes = continuation
            continue
        
        # If we hit a non-comment line, we're done
        if not line.startswith("#"):
            break
    
    return func_doc


def scan_file(file_path):
    """Scan a file and extract all function documentation"""
    functions = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines):
        if line.startswith("# Function:"):
            func_doc = parse_function_header(file_path, i)
            if func_doc and func_doc.name:
                functions.append(func_doc)
    
    return functions


def scan_all_files():
    """Scan all source files and extract function documentation"""
    functions_by_category = defaultdict(list)
    total_functions = 0
    
    print("=" * 72)
    print("OraDBA API Documentation Generator")
    print("=" * 72)
    print()
    print("[INFO] Scanning source files for functions...")
    
    # Scan lib files
    for pattern in ["*.sh", "plugins/*.sh"]:
        for file_path in SRC_LIB_DIR.glob(pattern):
            if file_path.is_file():
                functions = scan_file(file_path)
                if functions:
                    category = get_category(file_path)
                    functions_by_category[category].extend(functions)
                    print(f"[INFO]   {file_path.name}: {len(functions)} functions")
                    total_functions += len(functions)
    
    # Scan bin files
    for file_path in SRC_BIN_DIR.glob("*.sh"):
        if file_path.is_file():
            functions = scan_file(file_path)
            if functions:
                category = get_category(file_path)
                functions_by_category[category].extend(functions)
                print(f"[INFO]   {file_path.name}: {len(functions)} functions")
                total_functions += len(functions)
    
    print(f"[INFO] Total functions found: {total_functions}")
    print()
    
    return functions_by_category


def generate_category_page(category, functions):
    """Generate markdown page for a category"""
    output_file = OUTPUT_DIR / f"{category}.md"
    
    print(f"[INFO] Generating category page: {category}.md")
    
    title = CATEGORY_TITLES.get(category, category.title())
    description = CATEGORY_DESCRIPTIONS.get(category, "")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"# {title}\n\n")
        f.write(f"{description}\n\n")
        f.write("---\n\n")
        
        # Sort functions alphabetically
        for func in sorted(functions, key=lambda x: x.name):
            f.write(func.to_markdown())
    
    print(f"[INFO]   Added {len(functions)} functions to {category}.md")


def generate_index_page():
    """Generate API reference index page"""
    output_file = OUTPUT_DIR / "index.md"
    
    print("[INFO] Generating index page")
    
    current_date = datetime.now().strftime("%Y-%m-%d")
    
    content = f"""# API Reference

Complete function reference for OraDBA libraries and scripts.

## Overview

OraDBA provides a comprehensive set of shell functions organized into logical categories. All functions follow standardized header documentation including purpose, arguments, return codes, and output specifications.

## Categories

### [Core Utilities](common.md)

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

**Key Functions:**

- [`oradba_log`](common.md#oradba_log) - Unified logging with configurable levels
- [`oradba_dedupe_path`](common.md#oradba_dedupe_path) - Remove duplicate PATH entries
- [`detect_product_type`](common.md#detect_product_type) - Detect Oracle product type from filesystem
- [`parse_oratab`](common.md#parse_oratab) - Parse oratab file entries
- [`verify_oracle_env`](common.md#verify_oracle_env) - Verify Oracle environment variables

### [Registry API](registry.md)

Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.

**Key Functions:**

- [`oradba_registry_get_all`](registry.md#oradba_registry_get_all) - Get all installations
- [`oradba_registry_get_by_name`](registry.md#oradba_registry_get_by_name) - Get installation by name
- [`oradba_registry_get_by_type`](registry.md#oradba_registry_get_by_type) - Get installations by type
- [`oradba_registry_get_status`](registry.md#oradba_registry_get_status) - Check service status
- [`oradba_registry_validate_entry`](registry.md#oradba_registry_validate_entry) - Validate entry

### [Plugin Interface](plugins.md)

Plugin interface for product-specific functionality supporting database, client, datasafe, java, oud, and other Oracle products.

**Required Plugin Functions:**

- [`plugin_detect_installation`](plugins.md#plugin_detect_installation) - Auto-discover installations
- [`plugin_validate_home`](plugins.md#plugin_validate_home) - Validate ORACLE_HOME
- [`plugin_adjust_environment`](plugins.md#plugin_adjust_environment) - Adjust environment variables
- [`plugin_check_status`](plugins.md#plugin_check_status) - Check service status
- [`plugin_get_metadata`](plugins.md#plugin_get_metadata) - Extract version and edition
- [`plugin_should_show_listener`](plugins.md#plugin_should_show_listener) - Determine if listener applies
- [`plugin_discover_instances`](plugins.md#plugin_discover_instances) - Find instances
- [`plugin_get_instance_status`](plugins.md#plugin_get_instance_status) - Get instance status
- [`plugin_get_instance_type`](plugins.md#plugin_get_instance_type) - Get instance type
- [`plugin_get_pdb_status`](plugins.md#plugin_get_pdb_status) - Get PDB status
- [`plugin_get_version`](plugins.md#plugin_get_version) - Extract version

### [Environment Management](environment.md)

Environment management libraries for building, parsing, validating, and tracking Oracle environments.

**Includes:**

- `oradba_env_parser.sh` - Configuration parsing and merging
- `oradba_env_builder.sh` - Environment variable building
- `oradba_env_validator.sh` - Environment validation
- `oradba_env_config.sh` - Configuration management
- `oradba_env_status.sh` - Status display
- `oradba_env_changes.sh` - Change detection

### [Database Operations](database.md)

Database-specific operations including query execution, status checks, and database management.

**Key Functions:**

- [`execute_db_query`](database.md#execute_db_query) - Execute SQL with simplified interface
- [`check_database_status`](database.md#check_database_status) - Check if database is running
- [`check_listener_status`](database.md#check_listener_status) - Check listener status
- [`get_database_version`](database.md#get_database_version) - Get Oracle database version

### [Alias Management](aliases.md)

Alias generation and management for database environments.

**Key Functions:**

- [`generate_sid_lists`](aliases.md#generate_sid_lists) - Generate SID lists
- [`generate_oracle_home_aliases`](aliases.md#generate_oracle_home_aliases) - Generate Oracle Home aliases
- [`generate_pdb_aliases`](aliases.md#generate_pdb_aliases) - Generate PDB aliases

### [Extension System](extensions.md)

Extension system for loading and managing OraDBA extensions.

**Key Functions:**

- [`oradba_load_extension`](extensions.md#oradba_load_extension) - Load extension from directory
- [`oradba_list_extensions`](extensions.md#oradba_list_extensions) - List available extensions
- [`oradba_extension_discover`](extensions.md#oradba_extension_discover) - Discover extension directories

### [Scripts and Commands](scripts.md)

Command-line scripts and tools for OraDBA operations including environment management, service control, and system utilities.

**Includes:**

- `oradba_env.sh` - Environment switching
- `oradba_homes.sh` - Oracle Home management
- `oradba_dbctl.sh` - Database control
- `oradba_services.sh` - Service management
- `oradba_install.sh` - Installation script
- And more...

## Quick Reference

### Common Patterns

#### Check Database Status

```bash
source "${{ORADBA_BASE}}/lib/oradba_db_functions.sh"

status=$(check_database_status "FREE")
if [[ "$status" == "RUNNING" ]]; then
    echo "Database is up"
fi
```

#### List All Installations

```bash
source "${{ORADBA_BASE}}/lib/oradba_registry.sh"

oradba_registry_get_all | while IFS=: read -r name home type version auto_start desc; do
    echo "Found $type: $name at $home"
done
```

#### Execute Database Query

```bash
source "${{ORADBA_BASE}}/lib/oradba_db_functions.sh"

query="SELECT name FROM v\\$database;"
db_name=$(execute_db_query "$query" "raw")
echo "Database: $db_name"
```

#### Load Plugin and Check Status

```bash
source "${{ORADBA_BASE}}/lib/plugins/database_plugin.sh"

if plugin_validate_home "$ORACLE_HOME"; then
    status=$(plugin_check_status "$ORACLE_HOME" "$ORACLE_SID")
    echo "Status: $status"
fi
```

## See Also

- [Function Index](function-index.md) - Alphabetical function list
- [Architecture Documentation](../../doc/architecture.md) - System design
- [Development Guide](../../doc/development.md) - Development workflow
- [Function Header Guide](../../doc/function-header-guide.md) - Header standards

---

**API Reference Version:** 1.0  
**Last Generated:** {current_date}  
**OraDBA Version:** v0.19.1+
"""
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)


def generate_function_index(functions_by_category):
    """Generate alphabetical function index"""
    output_file = OUTPUT_DIR / "function-index.md"
    
    print("[INFO] Generating function index")
    
    # Collect all functions
    all_functions = []
    for category, functions in functions_by_category.items():
        for func in functions:
            all_functions.append((func.name, category))
    
    # Sort alphabetically
    all_functions.sort(key=lambda x: x[0].lower())
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Function Index\n\n")
        f.write("Alphabetical index of all OraDBA functions with links to detailed documentation.\n\n")
        f.write("---\n\n")
        
        for func_name, category in all_functions:
            category_title = CATEGORY_TITLES.get(category, category.title())
            f.write(f"- [`{func_name}`]({category}.md#{func_name}) - {category_title}\n")
    
    print(f"[INFO]   Function index generated with {len(all_functions)} functions")


def main():
    """Main execution"""
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"[INFO] Created output directory: {OUTPUT_DIR}")
    print()
    
    # Scan all files
    functions_by_category = scan_all_files()
    
    # Generate category pages
    print("[INFO] Generating category pages...")
    for category in ["common", "registry", "plugins", "environment", "database", "aliases", "extensions", "scripts"]:
        if category in functions_by_category:
            generate_category_page(category, functions_by_category[category])
    
    print()
    
    # Generate index and function index
    generate_index_page()
    generate_function_index(functions_by_category)
    
    print()
    print("=" * 72)
    print("API documentation generated successfully!")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 72)
    print()
    print("Generated files:")
    for file in sorted(OUTPUT_DIR.glob("*.md")):
        size = file.stat().st_size
        print(f"  {file.name:30s} {size:>10,} bytes")
    print()


if __name__ == "__main__":
    main()
