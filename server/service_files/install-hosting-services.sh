#!/usr/bin/env bash
#
# install-hosting-services.sh
#
# Installs updated systemd unit files for the apps that moved into ~/hosting/.
#   odysseus.service  -> /home/mike/hosting/odysseus
#   paperclip.service -> /home/mike/hosting/paperclip
#   firecrawl.service -> /home/mike/hosting/firecrawl  (+ docker v2 compose)
#
# Usage:
#   sudo bash install-hosting-services.sh            # apply
#   sudo bash install-hosting-services.sh --unmount  # restore backups
#   sudo bash install-hosting-services.sh --status   # show current unit state
#
set -euo pipefail

UNIT_DIR="/etc/systemd/system"
STAGED_DIR="/tmp/hosting_service_files"
BACKUP_DIR="${STAGED_DIR}/backup"
SERVICES=(odysseus paperclip firecrawl)

echo "==> Staged units present:"
for s in "${SERVICES[@]}"; do
  ls -l "${STAGED_DIR}/${s}.service" 2>/dev/null || echo "  missing staged ${s}.service (skip)"
done

cmd_backup() {
  echo "==> Backing up existing units to ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  for s in "${SERVICES[@]}"; do
    if [ -f "${UNIT_DIR}/${s}.service" ]; then
      cp -a "${UNIT_DIR}/${s}.service" "${BACKUP_DIR}/${s}.service.bak"
      echo "  backed up: ${s}.service ($(wc -c < "${BACKUP_DIR}/${s}.service.bak") bytes)"
    else
      echo "  (no existing ${s}.service to back up)"
    fi
  done
}

cmd_install() {
  echo "==> Installing updated units"
  for s in "${SERVICES[@]}"; do
    src="${STAGED_DIR}/${s}.service"
    [ -f "$src" ] || { echo "  SKIP ${s}: staged file missing"; continue; }
    cp -a "$src" "${UNIT_DIR}/${s}.service"
    chmod 644 "${UNIT_DIR}/${s}.service"
    echo "  installed: ${s}.service"
  done
  echo "  -> daemon-reload"
  systemctl daemon-reload
}

cmd_unmount() {
  echo "==> Restoring backups"
  for s in "${SERVICES[@]}"; do
    if [ -f "${BACKUP_DIR}/${s}.service.bak" ]; then
      cp -a "${BACKUP_DIR}/${s}.service.bak" "${UNIT_DIR}/${s}.service"
      echo "  restored: ${s}.service from backup"
    else
      echo "  (no backup for ${s}.service — leaving as-is)"
    fi
  done
  systemctl daemon-reload
  echo "  daemon-reload done"
}

cmd_status() {
  echo "==> Unit state"
  for s in "${SERVICES[@]}"; do
    echo "--- ${s}.service"
    systemctl cat "${s}.service" 2>/dev/null | grep -E "Description|WorkingDirectory|ExecStart=|ExecStop=|User=" || echo "  (no unit loaded)"
    systemctl is-enabled "${s}.service" 2>/dev/null | sed 's/^/    enabled: /'
    systemctl is-active "${s}.service" 2>/dev/null | sed 's/^/    active:   /'
  done
}

case "${1:-}" in
  --backup)  cmd_backup ;;
  --install) cmd_backup; cmd_install ;;
  --unmount|--rollback) cmd_unmount ;;
  --status)  cmd_status ;;
  *|--help|-h)
    echo "Usage:"
    echo "  $0 --install   backup + install updated units + daemon-reload"
    echo "  $0 --rollback  restore units from backup"
    echo "  $0 --status    show current unit state"
    ;;
esac