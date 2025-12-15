#!/usr/bin/env bash
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# init_git.sh - Initialize git repository and create first commit
# -----------------------------------------------------------------------

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "========================================="
echo "Initializing Git Repository"
echo "========================================="
echo ""

# Check if git is initialized
if [ -d ".git" ]; then
    echo "Git repository already initialized."
    echo ""
    git status
else
    echo "Initializing new git repository..."
    git init
    echo ""
fi

# Show current status
echo "Current status:"
echo ""
git status --short || true
echo ""

# Prompt for initial commit
read -p "Create initial commit? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Adding files to git..."
    
    # Add all files
    git add .
    
    echo ""
    echo "Files to be committed:"
    git status --short
    
    echo ""
    echo "Creating initial commit..."
    git commit -m "Initial commit: oradba Oracle Database Administration Toolset

- Core oraenv.sh script for environment setup
- Self-contained installer with base64 payload
- Comprehensive BATS test suite
- GitHub Actions CI/CD workflows
- Complete documentation
- Semantic versioning
- Apache 2.0 license

Version: 0.1.0"
    
    echo ""
    echo "✓ Initial commit created successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Create GitHub repository: https://github.com/new"
    echo "2. Add remote: git remote add origin git@github.com:oehrlis/oradba.git"
    echo "3. Push to GitHub: git push -u origin main"
    echo ""
else
    echo ""
    echo "Skipping initial commit."
    echo ""
fi

echo "Repository ready!"
