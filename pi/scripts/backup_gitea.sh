#!/bin/bash

BACKUP_DIR="/ServerStore/gitea_backup"
DATE=$(date +%Y%m%d-%H%M%S)
GITEA_CONTAINER="gitea"  # Your container name from docker-compose
COMPOSE_DIR="/home/mike/dots/pi/compose/gitea"  # Adjust to your docker-compose.yml directory

# Create backup directory
mkdir -p "${BACKUP_DIR}"

cd "${COMPOSE_DIR}"

echo "Creating Gitea backup..."

# Create dump as git user in /tmp directory
docker exec -u git -w /tmp "${GITEA_CONTAINER}" /usr/local/bin/gitea dump -c /data/gitea/conf/app.ini

# Get the actual dump filename
DUMP_FILENAME=$(docker exec "${GITEA_CONTAINER}" sh -c 'ls -t /tmp/gitea-dump-*.zip 2>/dev/null | head -1')

if [ -z "$DUMP_FILENAME" ]; then
    echo "Error: Backup file not created!"
    exit 1
fi

echo "Copying backup to host..."
docker cp "${GITEA_CONTAINER}:${DUMP_FILENAME}" "${BACKUP_DIR}/gitea-backup-${DATE}.zip"

# Clean up the dump file in the container
echo "Cleaning up container..."
docker exec "${GITEA_CONTAINER}" rm -f "${DUMP_FILENAME}"

# Keep only last 7 backups
echo "Cleaning old backups..."
cd "${BACKUP_DIR}"
ls -t gitea-backup-*.zip 2>/dev/null | tail -n +8 | xargs -r rm -f

echo ""
echo "✓ Backup completed: ${BACKUP_DIR}/gitea-backup-${DATE}.zip"
du -h "${BACKUP_DIR}/gitea-backup-${DATE}.zip"
echo ""
echo "Recent backups:"
ls -lht "${BACKUP_DIR}"/gitea-backup-*.zip | head -5
