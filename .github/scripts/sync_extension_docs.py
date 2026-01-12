#!/usr/bin/env python3
"""
Sync extension documentation from registered extension repositories.
This script reads .github/extensions.yml and pulls documentation from each
registered extension repository into src/doc/extensions/<name>/.
"""

import os
import sys
import yaml
import shutil
import subprocess
import re
from pathlib import Path
from typing import Dict, List

def load_extensions_registry(registry_path: str) -> List[Dict]:
    """Load extensions from the registry YAML file."""
    with open(registry_path, 'r') as f:
        data = yaml.safe_load(f)
    return data.get('extensions', [])

def clone_or_update_repo(repo: str, target_dir: Path, branch: str = 'main') -> bool:
    """Clone or update a git repository."""
    repo_url = f"https://github.com/{repo}.git"
    
    if target_dir.exists():
        print(f"  Updating existing clone: {target_dir}")
        try:
            subprocess.run(['git', 'pull'], cwd=target_dir, check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"  ⚠️  Failed to update: {e}")
            return False
    else:
        print(f"  Cloning {repo_url} to {target_dir}")
        try:
            subprocess.run(['git', 'clone', '--depth', '1', '--branch', branch, repo_url, str(target_dir)],
                         check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            # Try without branch if it fails
            try:
                subprocess.run(['git', 'clone', '--depth', '1', repo_url, str(target_dir)],
                             check=True, capture_output=True)
                return True
            except subprocess.CalledProcessError as e:
                print(f"  ⚠️  Failed to clone: {e}")
                return False

def sync_extension_docs(extension: Dict, work_dir: Path, docs_dir: Path) -> bool:
    """Sync documentation for a single extension."""
    name = extension['name']
    repo = extension['repo']
    docs_path = extension.get('docs_path', 'doc')
    
    print(f"\n📦 Syncing {name} from {repo}")
    
    # Clone/update the extension repo
    repo_dir = work_dir / name
    if not clone_or_update_repo(repo, repo_dir):
        return False
    
    # Check if doc directory exists
    source_docs = repo_dir / docs_path
    if not source_docs.exists():
        print(f"  ⚠️  Doc directory not found: {docs_path}")
        return False
    
    # Copy docs to target location
    target_docs = docs_dir / 'extensions' / name
    target_docs.parent.mkdir(parents=True, exist_ok=True)
    
    if target_docs.exists():
        shutil.rmtree(target_docs)
    
    # Define subdirectories to exclude from sync
    exclude_subdirs = [
        'release_notes',        # Release notes directory with broken links
        '.git',                 # Git directory
        '__pycache__',          # Python cache
    ]
    
    # Define file patterns to always exclude
    exclude_file_patterns = [
        '.git*',                # Git files
        '*.pyc',                # Python compiled files
    ]
    
    def should_exclude(file_path: Path) -> bool:
        """Check if file should be excluded based on patterns."""
        import fnmatch
        
        # Get relative path from source_docs to check for subdirectories
        rel_path = file_path.relative_to(source_docs)
        
        # Exclude if file is in an excluded subdirectory
        for part in rel_path.parts[:-1]:  # Check all directory parts except the filename
            if part in exclude_subdirs:
                return True
        
        # Check if filename matches exclusion patterns
        for pattern in exclude_file_patterns:
            if fnmatch.fnmatch(file_path.name, pattern):
                return True
        
        return False
    
    # Copy files selectively
    target_docs.mkdir(parents=True, exist_ok=True)
    for item in source_docs.rglob('*'):
        if item.is_file() and not should_exclude(item):
            rel_path = item.relative_to(source_docs)
            target_file = target_docs / rel_path
            target_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target_file)
    
    print(f"  ✓ Copied docs to {target_docs}")
    
    # If README.md exists but index.md doesn't, use README as index
    readme_file = target_docs / 'README.md'
    index_file = target_docs / 'index.md'
    if readme_file.exists() and not index_file.exists():
        shutil.move(str(readme_file), str(index_file))
        print(f"  ✓ Renamed README.md to index.md")
    
    # Clean up broken links in synced documentation
    cleanup_broken_links(target_docs)
    
    # Create or update navigation metadata
    create_extension_nav(extension, target_docs)
    leanup_broken_links(docs_dir: Path) -> None:
    """Remove or fix broken links that point outside the doc directory."""
    # Patterns for links that will be broken (point to source code, not docs)
    broken_link_patterns = [
        r'\[([^\]]+)\]\(\.\./lib/[^\)]+\)',      # ../lib/...
        r'\[([^\]]+)\]\(\.\./bin/[^\)]+\)',      # ../bin/...
        r'\[([^\]]+)\]\(\.\./CHANGELOG\.md\)',   # ../CHANGELOG.md
        r'\[([^\]]+)\]\(\.\./Makefile\)',        # ../Makefile
        r'\[([^\]]+)\]\(lib/README\.md\)',       # lib/README.md
        r'\[([^\]]+)\]\(bin/[^\)]+\)',           # bin/...
        r'\[([^\]]+)\]\(README\.md\)',           # README.md (in same dir as index.md)
        r'\[([^\]]+)\]\(release_notes/\)',       # release_notes/
        r'\[([^\]]+)\]\(etc/\)',                 # etc/
    ]
    
    files_cleaned = 0
    for md_file in docs_dir.rglob('*.md'):
        content = md_file.read_text(encoding='utf-8')
        original_content = content
        
        # Remove broken links, keep the link text as plain text
        for pattern in broken_link_patterns:
            content = re.sub(pattern, r'\1', content)
        
        # Write back if changes were made
        if content != original_content:
            md_file.write_text(content, encoding='utf-8')
            files_cleaned += 1
    
    if files_cleaned > 0:
        print(f"  ✓ Cleaned broken links in {files_cleaned} file(s)")

def c
    return True

def create_extension_nav(extension: Dict, docs_dir: Path) -> None:
    """Create a .pages file for mkdocs-awesome-pages-plugin (if used) or metadata."""
    metadata = {
        'title': extension['display_name'],
        'description': extension['description'],
        'category': extension['category'],
        'repository': f"https://github.com/{extension['repo']}",
        'status': extension['status']
    }
    
    # Create a metadata file for reference
    meta_file = docs_dir / '.metadata.yml'
    with open(meta_file, 'w') as f:
        yaml.dump(metadata, f)
    
    print(f"  ✓ Created metadata file")

def update_extensions_index(extensions: List[Dict], index_file: Path) -> None:
    """Update the extensions catalog index page with current extensions."""
    
    if not index_file.exists():
        print(f"⚠️  Index file not found: {index_file}")
        return
    
    with open(index_file, 'r') as f:
        content = f.read()
    
    # Find the auto-generated section
    start_marker = "<!-- EXTENSIONS_LIST_START -->"
    end_marker = "<!-- EXTENSIONS_LIST_END -->"
    
    if start_marker not in content or end_marker not in content:
        print("⚠️  Index markers not found in catalog page")
        return
    
    # Generate extension list - only include extensions with synced docs
    ext_list = ["\n"]
    synced_count = 0
    
    docs_dir = index_file.parent / 'extensions'
    
    for ext in extensions:
        if ext['status'] != 'active':
            continue
        
        # Check if extension docs were synced
        ext_docs = docs_dir / ext['name']
        if not ext_docs.exists() or not (ext_docs / 'index.md').exists():
            print(f"  ⓘ  Skipping {ext['name']} - no docs synced")
            continue
        
        ext_list.append(f"### {ext['display_name']}\n\n")
        ext_list.append(f"**Repository:** [{ext['repo']}](https://github.com/{ext['repo']})  \n")
        ext_list.append(f"**Category:** {ext['category']}  \n")
        ext_list.append(f"**Status:** {ext['status'].title()}  \n\n")
        ext_list.append(f"{ext['description']}\n\n")
        ext_list.append(f"[View Documentation](extensions/{ext['name']}/index.md){{ .md-button }}\n\n")
        synced_count += 1
    
    # If no extensions with docs, show placeholder message
    if synced_count == 0:
        ext_list = ["\n"]
        ext_list.append("No extensions with documentation are currently available. Extensions will appear here once\n")
        ext_list.append("they have documentation in their `doc/` directory and are registered in the extensions registry.\n\n")
        ext_list.append("To add your extension, see the [Extension System Guide](18-extensions.md).\n")
    
    # Replace content between markers
    start_idx = content.index(start_marker) + len(start_marker)
    end_idx = content.index(end_marker)
    
    new_content = content[:start_idx] + ''.join(ext_list) + content[end_idx:]
    
    with open(index_file, 'w') as f:
        f.write(new_content)
    
    print(f"✓ Updated extensions index with {synced_count} extension(s)")


def main():
    # Setup paths
    repo_root = Path(__file__).parent.parent.parent
    registry_file = repo_root / '.github' / 'extensions.yml'
    docs_dir = repo_root / 'src' / 'doc'
    index_file = docs_dir / 'extensions-catalog.md'
    work_dir = repo_root / '.extensions_work'
    
    print("🔄 OraDBA Extension Documentation Sync")
    print(f"   Registry: {registry_file}")
    print(f"   Docs Dir: {docs_dir}")
    
    # Load extensions
    if not registry_file.exists():
        print(f"❌ Registry file not found: {registry_file}")
        sys.exit(1)
    
    extensions = load_extensions_registry(registry_file)
    print(f"   Found {len(extensions)} registered extension(s)")
    
    # Create work directory
    work_dir.mkdir(parents=True, exist_ok=True)
    
    # Sync each extension
    success_count = 0
    for extension in extensions:
        if extension.get('status') == 'active':
            if sync_extension_docs(extension, work_dir, docs_dir):
                success_count += 1
    
    # Update the index page
    update_extensions_index(extensions, index_file)
    
    print(f"\n✅ Synced {success_count}/{len(extensions)} extensions")
    
    # Cleanup work directory (optional - comment out to keep for debugging)
    # shutil.rmtree(work_dir)

if __name__ == '__main__':
    main()
