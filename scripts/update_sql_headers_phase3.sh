#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Script.......: update_sql_headers_phase3.sh
# Author.......: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.........: 2025.12.19
# Purpose......: Batch update SQL script headers for Phase 3
# Usage........: ./update_sql_headers_phase3.sh [category]
#                category: aud, tde, sec, util, all (default: all)
# Notes........: Backs up files before modification (.bak)
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
SQL_DIR="${1:-/Users/stefan.oehrli/Development/github/oehrlis/oradba/src/sql}"
NEW_DATE="2025.12.19"
NEW_REVISION="0.8.0"
NEW_REFERENCE="https://github.com/oehrlis/oradba"
CATEGORY="${2:-all}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
updated_count=0
skipped_count=0
error_count=0

# Function to print colored output
print_msg() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to check if file needs update
needs_update() {
    local file=$1
    
    # Check if Date is old (not 2025.12.19)
    if grep -q "Date......: 20[0-2][0-4]\." "$file" 2>/dev/null; then
        return 0  # needs update
    fi
    
    # Check if Revision is empty or not 0.8.0
    if grep -q "Revision\.\.: *$" "$file" 2>/dev/null; then
        return 0  # needs update
    fi
    
    if grep -q "Revision\.\.: *0\.[0-7]\." "$file" 2>/dev/null; then
        return 0  # needs update
    fi
    
    return 1  # no update needed
}

# Function to update a single file
update_file() {
    local file=$1
    local basename=$(basename "$file")
    
    print_msg "$YELLOW" "Processing: $basename"
    
    # Check if file needs update
    if ! needs_update "$file"; then
        print_msg "$GREEN" "  ✓ Already up to date"
        ((skipped_count++))
        return 0
    fi
    
    # Backup file
    cp "$file" "$file.bak"
    
    # Update Date field (handle both old formats)
    sed -i '' 's/--  Date\.\.\.\.\.\.: 20[0-2][0-4]\.[0-1][0-9]\.[0-3][0-9]/--  Date.......: '"$NEW_DATE"'/g' "$file"
    sed -i '' 's/-- Date\.\.\.\.\.\.\.: 20[0-2][0-4]\.[0-1][0-9]\.[0-3][0-9]/-- Date.......: '"$NEW_DATE"'/g' "$file"
    
    # Update Revision field (handle empty and old versions)
    sed -i '' 's/--  Revision\.\.: *$/--  Revision...: '"$NEW_REVISION"'/g' "$file"
    sed -i '' 's/-- Revision\.\.\.: *$/-- Revision...: '"$NEW_REVISION"'/g' "$file"
    sed -i '' 's/--  Revision\.\.: *0\.[0-7]\.[0-9]*/--  Revision...: '"$NEW_REVISION"'/g' "$file"
    sed -i '' 's/-- Revision\.\.\.: *0\.[0-7]\.[0-9]*/-- Revision...: '"$NEW_REVISION"'/g' "$file"
    
    # Add Reference field if missing (insert before License line)
    if ! grep -q "Reference" "$file"; then
        sed -i '' '/--  License/i\
--  Reference..: '"$NEW_REFERENCE"'
' "$file"
    fi
    
    # Verify changes
    if grep -q "$NEW_DATE" "$file" && grep -q "$NEW_REVISION" "$file"; then
        print_msg "$GREEN" "  ✓ Updated successfully"
        ((updated_count++))
        # Remove backup
        rm -f "$file.bak"
    else
        print_msg "$RED" "  ✗ Update failed"
        # Restore from backup
        mv "$file.bak" "$file"
        ((error_count++))
    fi
}

# Get list of files based on category
get_files() {
    local category=$1
    local files=()
    
    case $category in
        aud)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." aud_*.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        tde)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." tde_*.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        sec)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." sec_*.sql s*sec_*.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        util)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." {al,tal,taln,u,ua,ui,uall,uapex,umachine,uopid,uspid,d,df,iux,lgs,ls,net,reg,rj,sp,tab_size,tsq,tsqu}.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        password)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." verify_*.sql *sec_pwverify*.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        all)
            # Get all files with old dates (2018-2024)
            files=($(cd "$SQL_DIR" && grep -l "Date......: 20[0-2][0-4]\." *.sql 2>/dev/null | while read f; do echo "$SQL_DIR/$f"; done))
            ;;
        *)
            print_msg "$RED" "Unknown category: $category"
            echo "Valid categories: aud, tde, sec, util, password, all"
            exit 1
            ;;
    esac
    
    echo "${files[@]}"
}

# Main execution
main() {
    print_msg "$GREEN" "=== OraDBA SQL Header Update - Phase 3 ==="
    print_msg "$YELLOW" "Target Date: $NEW_DATE"
    print_msg "$YELLOW" "Target Revision: $NEW_REVISION"
    print_msg "$YELLOW" "Category: $CATEGORY"
    echo ""
    
    # Check if SQL directory exists
    if [[ ! -d "$SQL_DIR" ]]; then
        print_msg "$RED" "Error: SQL directory not found: $SQL_DIR"
        exit 1
    fi
    
    # Get files to update
    mapfile -t files < <(get_files "$CATEGORY")
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_msg "$YELLOW" "No files found for category: $CATEGORY"
        exit 0
    fi
    
    print_msg "$GREEN" "Found ${#files[@]} files to process"
    echo ""
    
    # Process each file
    for file in "${files[@]}"; do
        update_file "$file"
    done
    
    echo ""
    print_msg "$GREEN" "=== Summary ==="
    print_msg "$GREEN" "Updated: $updated_count files"
    print_msg "$YELLOW" "Skipped: $skipped_count files (already up to date)"
    if [[ $error_count -gt 0 ]]; then
        print_msg "$RED" "Errors: $error_count files"
    fi
    
    # Show git status
    echo ""
    print_msg "$YELLOW" "Git status:"
    cd "$SQL_DIR" && git status --short | head -20
}

# Run main
main

# EOF --------------------------------------------------------------------------
