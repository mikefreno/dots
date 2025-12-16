#!/bin/bash
BACKUP_DEST="/ServerStore/gitea_backup"

mkdir -p "$BACKUP_DEST"

DIRECTORIES=(".data" ".config" ".postgres")

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Gitea backup from $SOURCE_DIR to $BACKUP_DEST"
echo "================================================"

for dir in "${DIRECTORIES[@]}"; do
    if [ -d "/home/mike/dots/pi/compose/gitea/$dir" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up $dir..."
        cp -r "/home/mike/dots/pi/compose/gitea/$dir" "$BACKUP_DEST/"
        if [ $? -eq 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Successfully backed up $dir"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Failed to backup $dir"
            exit 1
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ Warning: $dir not found in $SOURCE_DIR"
    fi
done

echo "================================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed!"
