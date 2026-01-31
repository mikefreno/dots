#!/bin/bash

# Safe media mover - moves files from overnight_source to Media without overwrites
# Usage: ./move_overnight_media.sh [--dry-run]

SOURCE_DIR="$HOME/overnight_source"
DEST_DIR="/ServerStore/Media"
DRY_RUN=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${BLUE}=== DRY RUN MODE - No files will be moved ===${NC}\n"
fi

# Counters
MOVED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# Arrays to store results
declare -a MOVED_FILES
declare -a SKIPPED_FILES
declare -a ERROR_FILES

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${RED}Error: Source directory $SOURCE_DIR does not exist${NC}"
    exit 1
fi

# Check if destination directory exists
if [[ ! -d "$DEST_DIR" ]]; then
    echo -e "${RED}Error: Destination directory $DEST_DIR does not exist${NC}"
    exit 1
fi

echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo ""

# Process each subdirectory
for subdir in Movies Music TV; do
    SOURCE_SUBDIR="$SOURCE_DIR/$subdir"
    DEST_SUBDIR="$DEST_DIR/$subdir"
    
    # Skip if source subdirectory doesn't exist
    if [[ ! -d "$SOURCE_SUBDIR" ]]; then
        echo -e "${YELLOW}Skipping $subdir - directory not found in source${NC}"
        continue
    fi
    
    # Create destination subdirectory if it doesn't exist
    if [[ ! -d "$DEST_SUBDIR" ]]; then
        echo -e "${YELLOW}Creating destination directory: $DEST_SUBDIR${NC}"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$DEST_SUBDIR"
        fi
    fi
    
    echo -e "${BLUE}Processing $subdir...${NC}"
    
    # Find all files in source subdirectory (including nested directories)
    while IFS= read -r -d '' source_file; do
        # Get relative path from source subdirectory
        rel_path="${source_file#$SOURCE_SUBDIR/}"
        dest_file="$DEST_SUBDIR/$rel_path"
        
        # Create parent directory if needed
        dest_parent=$(dirname "$dest_file")
        if [[ ! -d "$dest_parent" ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$dest_parent"
            fi
        fi
        
        # Check if file already exists at destination
        if [[ -e "$dest_file" ]]; then
            echo -e "  ${YELLOW}SKIP:${NC} $rel_path (already exists)"
            ((SKIPPED_COUNT++))
            SKIPPED_FILES+=("$subdir/$rel_path")
        else
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${GREEN}WOULD MOVE:${NC} $rel_path"
            else
                # Move the file
                if mv "$source_file" "$dest_file" 2>/dev/null; then
                    echo -e "  ${GREEN}MOVED:${NC} $rel_path"
                    ((MOVED_COUNT++))
                    MOVED_FILES+=("$subdir/$rel_path")
                else
                    echo -e "  ${RED}ERROR:${NC} Failed to move $rel_path"
                    ((ERROR_COUNT++))
                    ERROR_FILES+=("$subdir/$rel_path")
                fi
            fi
        fi
    done < <(find "$SOURCE_SUBDIR" -type f -print0)
    
    echo ""
done

# Print summary
echo -e "${BLUE}=== Summary ===${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${GREEN}Files that would be moved: $MOVED_COUNT${NC}"
else
    echo -e "${GREEN}Files moved: $MOVED_COUNT${NC}"
fi
echo -e "${YELLOW}Files skipped (already exist): $SKIPPED_COUNT${NC}"
echo -e "${RED}Errors: $ERROR_COUNT${NC}"

# Remove empty directories from source if not in dry-run mode
if [[ "$DRY_RUN" == false ]] && [[ $MOVED_COUNT -gt 0 ]]; then
    echo ""
    echo "Cleaning up empty directories..."
    find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null
    echo "Done!"
fi

exit 0
