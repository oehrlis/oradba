#!/usr/bin/env bash
# ============================================================================
# Script Name: remove_number_prefixes.sh
# Description: Remove number prefixes from documentation files
#              Updates mkdocs.yml navigation references
# ============================================================================

set -euo pipefail

readonly DOCS_DIR="src/doc"

# File mappings (old -> new)
declare -A FILE_MAP=(
    ["01-introduction.md"]="introduction.md"
    ["02-installation.md"]="installation.md"
    ["02-installation-docker.md"]="installation-docker.md"
    ["03-quickstart.md"]="quickstart.md"
    ["04-environment.md"]="environment.md"
    ["05-configuration.md"]="configuration.md"
    ["06-aliases.md"]="aliases.md"
    ["07-pdb-aliases.md"]="pdb-aliases.md"
    ["08-sql-scripts.md"]="sql-scripts.md"
    ["09-rman-scripts.md"]="rman-scripts.md"
    ["10-functions.md"]="functions.md"
    ["11-rlwrap.md"]="rlwrap.md"
    ["12-troubleshooting.md"]="troubleshooting.md"
    ["13-reference.md"]="reference.md"
    ["14-sqlnet-config.md"]="sqlnet-config.md"
    ["15-log-management.md"]="log-management.md"
    ["16-usage.md"]="usage.md"
    ["17-service-management.md"]="service-management.md"
    ["18-extensions.md"]="extensions.md"
    ["19-extensions-catalog.md"]="extensions-catalog.md"
)

echo "Renaming documentation files..."
echo "==============================="

# Rename files
for old_file in "${!FILE_MAP[@]}"; do
    new_file="${FILE_MAP[$old_file]}"
    
    if [[ -f "${DOCS_DIR}/${old_file}" ]]; then
        git mv "${DOCS_DIR}/${old_file}" "${DOCS_DIR}/${new_file}"
        echo "✓ Renamed: ${old_file} -> ${new_file}"
    else
        echo "⚠ Skipped: ${old_file} (not found)"
    fi
done

echo ""
echo "Updating mkdocs.yml..."

# Update mkdocs.yml (using git so it tracks the change)
cat > mkdocs.yml.new <<'EOF'
site_name: OraDBA Documentation
site_url: https://oehrlis.github.io/oradba
site_description: Oracle Database Administration Toolset - Complete user guides and reference materials
site_author: Stefan Oehrli
copyright: Copyright &copy; 2025 Stefan Oehrli

# Repository
repo_url: https://github.com/oehrlis/oradba
repo_name: oehrlis/oradba
edit_uri: edit/main/src/doc/

# Documentation directory
docs_dir: src/doc
site_dir: site

# Theme configuration
theme:
  name: material
  language: en
  palette:
    # Light mode (default)
    - scheme: default
      primary: blue
      accent: light blue
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    # Dark mode
    - scheme: slate
      primary: blue
      accent: light blue
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  
  font:
    text: Roboto
    code: Roboto Mono
  
  features:
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.sections
    - navigation.expand
    - navigation.path
    - navigation.top
    - navigation.footer
    - search.suggest
    - search.highlight
    - search.share
    - content.code.copy
    - content.code.annotate
    - content.action.edit
    - toc.follow
  
  icon:
    repo: fontawesome/brands/github
    edit: material/pencil
    view: material/eye

# Extensions
markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.tasklist:
      custom_checkbox: true
  - attr_list
  - md_in_html
  - def_list
  - tables
  - footnotes
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
  - toc:
      permalink: true
      title: On this page

# Plugins
plugins:
  - search:
      lang: en
      separator: '[\s\-,:!=\[\]()"/]+|(?!\b)(?=[A-Z][a-z])|\.(?!\d)|&[lg]t;'
  - git-revision-date-localized:
      enable_creation_date: true
      type: timeago

# Navigation structure
nav:
  - Home: index.md
  
  - Getting Started:
    - Introduction: introduction.md
    - Installation: installation.md
    - Quick Start: quickstart.md
    - Environment Management: environment.md
  
  - Configuration:
    - Configuration System: configuration.md
    - Aliases Reference: aliases.md
    - PDB Aliases: pdb-aliases.md
  
  - Scripts & Tools:
    - SQL Scripts: sql-scripts.md
    - RMAN Scripts: rman-scripts.md
    - Database Functions: functions.md
    - rlwrap Filter: rlwrap.md
  
  - Operations:
    - Troubleshooting: troubleshooting.md
    - Quick Reference: reference.md
    - SQL*Net Configuration: sqlnet-config.md
    - Log Management: log-management.md
    - Usage Guide: usage.md
    - Service Management: service-management.md
  
  - Extensions:
    - Extension System: extensions.md
    - Extensions Catalog: extensions-catalog.md

# Extra configuration
extra:
  version:
    provider: mike
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/oehrlis/oradba
    - icon: fontawesome/brands/docker
      link: https://hub.docker.com/u/oehrlis
  generator: false

# Additional CSS
extra_css:
  - stylesheets/extra.css

# Additional JavaScript
extra_javascript:
  - javascripts/extra.js
EOF

mv mkdocs.yml.new mkdocs.yml
echo "✓ Updated mkdocs.yml with new filenames"

echo ""
echo "Done! Summary:"
echo "=============="
echo "- Files renamed to remove number prefixes"
echo "- mkdocs.yml updated with new filenames"
echo "- URLs will now be clean (e.g., /introduction/ instead of /01-introduction/)"
echo "- Navigation order is preserved via explicit nav structure"
echo "- For PDF: Use scripts/build_pdf.sh which reads from nav order"
echo ""
echo "Next steps:"
echo "1. Review changes with: git status"
echo "2. Test locally with: mkdocs serve"
echo "3. Commit changes: git add -A && git commit -m 'docs: Remove number prefixes from filenames'"
