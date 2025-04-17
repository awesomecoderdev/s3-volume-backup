#!/bin/bash

# Configure paths
BACKUP_ROOT="/app/backup"
DATE_STAMP=$(date +"%d-%m-%Y")
TIME_STAMP=$(date +"%I-%M-%p")
BACKUP_DIR="${BACKUP_ROOT}/${DATE_STAMP}"
SQL_FILE="backup-${TIME_STAMP}.sql"
ZIP_FILE="backup-${TIME_STAMP}.zip"
SQL_PATH="${BACKUP_DIR}/${SQL_FILE}"
ZIP_PATH="${BACKUP_DIR}/${ZIP_FILE}"
S3_TARGET="s3://${AWS_BUCKET}/backups/${DATE_STAMP}/${ZIP_FILE}"

# Log helper
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check required env vars
if [ -z "$AWS_BUCKET" ] || [ -z "$DB_DATABASE" ] || [ -z "$DB_USERNAME" ]; then
  log "ERROR: Required environment variables (AWS_BUCKET, DB_DATABASE, DB_USERNAME) not set"
  exit 1
fi


# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  log "Creating backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# Dump MariaDB
log "[INFO] Dumping database '${DB_DATABASE}'..."
docker exec mariadb \
  mariadb-dump -u"$DB_USERNAME" ${DB_PASSWORD:+-p"$DB_PASSWORD"} "$DB_DATABASE" > "$SQL_PATH"

if [ $? -ne 0 ]; then
  log "ERROR: Failed to dump database"
  exit 2
fi

# Create ZIP archive
log "[INFO] Creating ZIP archive..."
cd "$BACKUP_DIR" && zip -q "$ZIP_FILE" "$SQL_FILE" && rm -f "$SQL_FILE"

if [ $? -ne 0 ]; then
  log "ERROR: Failed to zip SQL dump"
  exit 3
fi

# Upload to S3
log "[INFO] Uploading to S3: $S3_TARGET"
aws s3 cp "$ZIP_PATH" "$S3_TARGET" --region "$AWS_DEFAULT_REGION" --no-progress

if [ $? -eq 0 ]; then
  log "[INFO] Upload successful. Cleaning up..."
  rm -rf "$BACKUP_DIR"
else
  log "ERROR: Upload failed. Backup file retained: $ZIP_PATH"
  exit 4
fi

log "[SUCCESS] Backup completed at $(date)"
