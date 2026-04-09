#!/bin/bash
# =============================================================================
# Skilloka - Database Restore Script
# Restore PostgreSQL from backup
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/backups/postgres"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <backup_file> [--confirm]"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/skilloka_*.sql.gz 2>/dev/null || echo "No backups found in $BACKUP_DIR"
    exit 1
fi

BACKUP_FILE="$1"
CONFIRM="${2:-}"

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    # Try with backup directory prefix
    if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    else
        log "${RED}✗ Backup file not found: $BACKUP_FILE${NC}"
        exit 1
    fi
fi

log "Backup file: $BACKUP_FILE"
log "File size: $(du -h "$BACKUP_FILE" | cut -f1)"

# Confirmation
if [ "$CONFIRM" != "--confirm" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will overwrite the current database!${NC}"
    echo ""
    read -p "Type 'yes' to confirm: " response
    if [ "$response" != "yes" ]; then
        log "Restore cancelled"
        exit 0
    fi
fi

# Create a backup of current database before restore
log "Creating backup of current database..."
CURRENT_BACKUP="${BACKUP_DIR}/pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
./backup-database.sh || log "${YELLOW}Warning: Could not backup current database${NC}"

# Stop application connections
log "Stopping application services..."
docker compose -f docker-compose.prod.yml stop backend horizon scheduler

# Restore the database
log "Restoring database from backup..."

gunzip -c "$BACKUP_FILE" | docker exec -i skilloka-postgres pg_restore \
    -h localhost \
    -U "${DB_USERNAME:-skilloka}" \
    -d "${DB_DATABASE:-skilloka}" \
    --clean \
    --if-exists \
    --no-owner \
    --no-acl

if [ $? -eq 0 ]; then
    log "${GREEN}✓ Database restored successfully${NC}"
else
    log "${RED}✗ Restore failed${NC}"
    
    # Attempt to restore from pre-restore backup
    if [ -f "$CURRENT_BACKUP" ]; then
        log "Attempting to restore pre-restore backup..."
        gunzip -c "$CURRENT_BACKUP" | docker exec -i skilloka-postgres pg_restore \
            -h localhost \
            -U "${DB_USERNAME:-skilloka}" \
            -d "${DB_DATABASE:-skilloka}" \
            --clean \
            --if-exists
    fi
    
    exit 1
fi

# Restart application services
log "Restarting application services..."
docker compose -f docker-compose.prod.yml start backend horizon scheduler

# Run any pending migrations
log "Running database migrations..."
docker compose -f docker-compose.prod.yml exec -T backend php artisan migrate --force

# Clear caches
log "Clearing caches..."
docker compose -f docker-compose.prod.yml exec -T backend php artisan optimize:clear

log "${GREEN}✓ Restore process completed${NC}"
