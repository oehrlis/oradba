#!/usr/bin/env python3
"""Fix internal markdown links after removing number prefixes from filenames."""

import re
from pathlib import Path

# Define all the file mappings
FILE_MAPPINGS = {
    '01-introduction.md': 'introduction.md',
    '02-installation.md': 'installation.md',
    '02-installation-docker.md': 'installation-docker.md',
    '03-quickstart.md': 'quickstart.md',
    '04-environment.md': 'environment.md',
    '05-configuration.md': 'configuration.md',
    '06-aliases.md': 'aliases.md',
    '07-pdb-aliases.md': 'pdb-aliases.md',
    '08-sql-scripts.md': 'sql-scripts.md',
    '09-rman-scripts.md': 'rman-scripts.md',
    '10-functions.md': 'functions.md',
    '11-rlwrap.md': 'rlwrap.md',
    '12-troubleshooting.md': 'troubleshooting.md',
    '13-reference.md': 'reference.md',
    '14-sqlnet-config.md': 'sqlnet-config.md',
    '15-log-management.md': 'log-management.md',
    '16-usage.md': 'usage.md',
    '17-service-management.md': 'service-management.md',
    '18-extensions.md': 'extensions.md',
    '19-extensions-catalog.md': 'extensions-catalog.md',
}

def fix_links_in_file(filepath):
    """Fix all internal links in a markdown file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Replace each old filename with new filename
    for old_name, new_name in FILE_MAPPINGS.items():
        # Escape special regex characters
        old_escaped = re.escape(old_name)
        # Replace in markdown links: [text](old-name.md)
        content = re.sub(old_escaped, new_name, content)
    
    # Only write if content changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """Fix links in all markdown files."""
    docs_dir = Path('src/doc')
    
    if not docs_dir.exists():
        print(f"Error: {docs_dir} not found")
        return 1
    
    updated_count = 0
    for md_file in docs_dir.glob('*.md'):
        if fix_links_in_file(md_file):
            print(f"✓ Updated: {md_file.name}")
            updated_count += 1
    
    print(f"\n✓ Updated {updated_count} files")
    return 0

if __name__ == '__main__':
    exit(main())
