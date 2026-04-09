#!/bin/bash
# =============================================================================
# Skilloka - Database Backup Script
# Automated PostgreSQL backup with retention
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/backups/postgres"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/skilloka_${TIMESTAMP}.sql.gz"

# Database configuration (from environment or defaults)
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_DATABASE:-skilloka}"
DB_USER="${DB_USERNAME:-skilloka}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log "Starting database backup..."

# Perform the backup
if docker exec skilloka-postgres pg_dump \
    -h localhost \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --no-owner \
    --no-acl \
    --format=custom \
    | gzip > "$BACKUP_FILE"; then
    
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "${GREEN}✓ Backup completed: $BACKUP_FILE (${BACKUP_SIZE})${NC}"
else
    log "${RED}✗ Backup failed${NC}"
    exit 1
fi

# Upload to S3 (if configured)
if [ -n "${AWS_S3_BUCKET:-}" ]; then
    log "Uploading backup to S3..."
    
    if aws s3 cp "$BACKUP_FILE" "s3://${AWS_S3_BUCKET}/backups/postgres/$(basename $BACKUP_FILE)"; then
        log "${GREEN}✓ Backup uploaded to S3${NC}"
    else
        log "${RED}✗ S3 upload failed${NC}"
    fi
fi

# Cleanup old backups
log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "$BACKUP_DIR" -name "skilloka_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

# Count remaining backups
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/skilloka_*.sql.gz 2>/dev/null | wc -l)
log "Total local backups: ${BACKUP_COUNT}"

log "${GREEN}✓ Backup process completed${NC}"
