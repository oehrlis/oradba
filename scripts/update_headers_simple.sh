#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Simple script to update SQL file headers
# ------------------------------------------------------------------------------

set -u

SQL_DIR="/Users/stefan.oehrli/Development/github/oehrlis/oradba/src/sql"
NEW_DATE="2025.12.19"
NEW_REVISION="0.8.0"
NEW_REFERENCE="https://github.com/oehrlis/oradba"

# Counters
updated=0
skipped=0

cd "$SQL_DIR"

# Find all files with old dates (2018-2024)
for file in $(grep -l "Date......: 20[0-2][0-4]\." *.sql 2>/dev/null); do
    echo "Processing: $file"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Update Date field
    perl -i -pe "s/(--  Date\.\.\.\.\.\.: )20[0-2][0-4]\.[0-1][0-9]\.[0-3][0-9]/\${1}$NEW_DATE/g" "$file" || true
    
    # Update Revision field (empty)
    perl -i -pe "s/(--  Revision\.\.\.: )  *$/\${1}$NEW_REVISION/g" "$file" || true
    
    # Update Revision field (old version)
    perl -i -pe "s/(--  Revision\.\.\.: )0\.[0-7]\.[0-9]*/\${1}$NEW_REVISION/g" "$file" || true
    
    # Add Reference field if missing (before License line)
    if ! grep -q "Reference\.\.\." "$file" 2>/dev/null; then
        if grep -q "License" "$file" 2>/dev/null; then
            perl -i -pe 's/(--  License)/--  Reference..: https:\/\/github.com\/oehrlis\/oradba\n$1/' "$file" || true
        fi
    fi
    
    # Verify
    if grep -q "$NEW_DATE" "$file" 2>/dev/null; then
        echo "  ✓ Updated"
        rm -f "$file.bak"
        ((updated++))
    else
        echo "  ✗ Failed - restoring"
        mv "$file.bak" "$file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Updated: $updated files"

# Show git status
echo ""
echo "=== Git Status ==="
git status --short | head -20
