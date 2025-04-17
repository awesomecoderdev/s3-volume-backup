#!/bin/bash

# Configure paths
SOURCE_DIR="/app/mysql"
BACKUP_ROOT="/app/backup"
DATE_STAMP=$(date +"%d-%m-%Y")
TIME_STAMP=$(date +"%I-%M-%p")
BACKUP_DIR="${BACKUP_ROOT}/${DATE_STAMP}"
FILE_NAME="backup-${TIME_STAMP}.zip"
BACKUP_FILE="${BACKUP_DIR}/${FILE_NAME}"
S3_TARGET="s3://${AWS_BUCKET}/backups/${DATE_STAMP}/${FILE_NAME}"

# Log function for consistent output
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check for required environment variables
if [ -z "$AWS_BUCKET" ]; then
  log "ERROR: AWS_BUCKET environment variable is not set"
  exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  log "Creating backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# Check if source directory exists and is not empty
if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A $SOURCE_DIR 2>/dev/null)" ]; then
  log "ERROR: Source directory '$SOURCE_DIR' does not exist or is empty"
  exit 2
fi

# Create zip archive
log "Creating backup archive: $BACKUP_FILE"
# zip -r "$BACKUP_FILE" "$SOURCE_DIR" -q
cd "$SOURCE_DIR" && zip -r "$BACKUP_FILE" . -q
if [ $? -ne 0 ]; then
  log "ERROR: Failed to create backup archive"
  exit 3
fi

# Upload to S3
log "Uploading backup to S3: $S3_TARGET"
aws s3 cp "$BACKUP_FILE" "$S3_TARGET" \
  --region "$AWS_DEFAULT_REGION" \
  --no-progress

if [ $? -eq 0 ]; then
  log "Upload successful. Removing local backup file: $BACKUP_FILE"
  # rm -f "$BACKUP_FILE"
  rm -rf "$BACKUP_DIR"
else
  log "ERROR: Upload failed. Backup file retained: $BACKUP_FILE"
  exit 4
fi

log "Backup completed successfully"
