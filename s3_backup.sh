#!/bin/bash

# Config
BACKUP_SRC="/home/ubuntu/backup-data"
BACKUP_DEST="/home/ubuntu/backuped-data"
S3_BUCKET="my-project-backup-with-rotation"
PREFIX="project-backup"
MAX_BACKUPS=10  # Keep 10 newest backups

# Create destination directory if it doesn't exist
mkdir -p "$BACKUP_DEST"

# Create backup file
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$PREFIX-$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_DEST/$BACKUP_FILE" "$BACKUP_SRC" || exit 1

# Upload to S3
aws s3 cp "$BACKUP_DEST/$BACKUP_FILE" "s3://$S3_BUCKET/backups/$BACKUP_FILE" || exit 1

# Delete local backup after upload
rm -f "$BACKUP_DEST/$BACKUP_FILE"

# Count-based rotation on S3 (keep only latest $MAX_BACKUPS)
BACKUP_LIST=$(aws s3 ls "s3://$S3_BUCKET/backups/$PREFIX-" | sort -r | awk '{print $4}')
echo "$BACKUP_LIST" | tail -n +$((MAX_BACKUPS + 1)) | while read -r OLD_BACKUP; do
  if [[ -n "$OLD_BACKUP" ]]; then
    aws s3 rm "s3://$S3_BUCKET/backups/$OLD_BACKUP"
  fi
done
