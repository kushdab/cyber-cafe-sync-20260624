#!/bin/bash

# ==============================================================================
# Script Name    : backup.sh
# Description    : Automated encrypted backups for SME accounting files to GDrive
# Author         : Cyber-Cafe-Sync-Project
# Date           : 2026-06-24
# Version        : 1.0.0
# Dependencies   : rclone, gpg, tar
# ==============================================================================

# --- Configuration ---
SOURCE_DIR="/var/www/accounting/data"
BACKUP_TEMP_DIR="/tmp/cafe_backups"
REMOTE_NAME="gdrive-backup"
REMOTE_DEST="AccountingBackups"

# Encryption settings
# Ensure you have a GPG passphrase file secured with 600 permissions
GPG_PASSPHRASE_FILE="$HOME/.backup_passphrase"
RETENTION_DAYS=30

# Logging
LOG_FILE="/var/log/cyber-cafe-sync.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="accounting_backup_$TIMESTAMP"

# --- Functions ---

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    cleanup
    exit 1
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$BACKUP_TEMP_DIR"
}

check_dependencies() {
    local dependencies=("rclone" "gpg" "tar")
    for tool in "${dependencies[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error_exit "Dependency '$tool' is not installed. Aborting."
        fi
    done
}

# --- Execution Flow ---

# 1. Initialization
log "Starting daily backup process..."
mkdir -p "$BACKUP_TEMP_DIR"
check_dependencies

if [ ! -f "$GPG_PASSPHRASE_FILE" ]; then
    error_exit "Passphrase file $GPG_PASSPHRASE_FILE not found."
fi

if [ ! -d "$SOURCE_DIR" ]; then
    error_exit "Source directory $SOURCE_DIR does not exist."
fi

# 2. Archiving
log "Creating tarball of $SOURCE_DIR..."
ARCHIVE_PATH="$BACKUP_TEMP_DIR/$BACKUP_NAME.tar.gz"
if ! tar -czf "$ARCHIVE_PATH" -C "$SOURCE_DIR" .; then
    error_exit "Failed to create tar archive."
fi

# 3. Encryption
log "Encrypting archive with GPG..."
ENCRYPTED_PATH="$ARCHIVE_PATH.gpg"
if ! gpg --batch --yes --passphrase-file "$GPG_PASSPHRASE_FILE" \
    --symmetric --cipher-algo AES256 -o "$ENCRYPTED_PATH" "$ARCHIVE_PATH"; then
    error_exit "Encryption failed."
fi

# 4. Upload to Google Drive
log "Uploading encrypted file to Google Drive ($REMOTE_NAME)..."
if ! rclone copy "$ENCRYPTED_PATH" "$REMOTE_NAME:$REMOTE_DEST"; then
    error_exit "Rclone upload failed."
fi

# 5. Remote Retention Policy
log "Cleaning up remote backups older than $RETENTION_DAYS days..."
rclone delete "$REMOTE_NAME:$REMOTE_DEST" --min-age "${RETENTION_DAYS}d" --dry-run # Remove dry-run for production

# 6. Finalization
log "Backup successful: $BACKUP_NAME.tar.gz.gpg"
cleanup

# Output summary to console
cat <<EOF
----------------------------------------------------------
BACKUP SUMMARY
Status: SUCCESS
File:   $ENCRYPTED_PATH
Remote: $REMOTE_NAME:$REMOTE_DEST
Date:   $TIMESTAMP
----------------------------------------------------------
EOF

exit 0