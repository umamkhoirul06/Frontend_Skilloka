#!/bin/bash
# =============================================================================
# Skilloka - Deployment Script
# Handles application deployment with zero-downtime
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.prod.yml"
LOG_FILE="${PROJECT_DIR}/logs/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message=$@
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

info() { log "INFO" "${BLUE}$@${NC}"; }
success() { log "SUCCESS" "${GREEN}$@${NC}"; }
warning() { log "WARNING" "${YELLOW}$@${NC}"; }
error() { log "ERROR" "${RED}$@${NC}"; }

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    command -v docker >/dev/null 2>&1 || { error "Docker is not installed"; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || command -v "docker compose" >/dev/null 2>&1 || { error "Docker Compose is not installed"; exit 1; }
    
    if [ ! -f "${PROJECT_DIR}/.env.production" ]; then
        error "Production environment file not found: .env.production"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Pull latest images
pull_images() {
    info "Pulling latest Docker images..."
    docker compose -f "$COMPOSE_FILE" pull
    success "Images pulled successfully"
}

# Run database migrations
run_migrations() {
    info "Running database migrations..."
    docker compose -f "$COMPOSE_FILE" run --rm backend php artisan migrate --force
    success "Migrations completed"
}

# Clear and warm caches
optimize_app() {
    info "Optimizing application..."
    
    docker compose -f "$COMPOSE_FILE" exec -T backend php artisan config:cache
    docker compose -f "$COMPOSE_FILE" exec -T backend php artisan route:cache
    docker compose -f "$COMPOSE_FILE" exec -T backend php artisan view:cache
    docker compose -f "$COMPOSE_FILE" exec -T backend php artisan event:cache
    
    success "Application optimized"
}

# Restart services
restart_services() {
    info "Restarting services with zero-downtime..."
    
    # Scale up new instances first
    docker compose -f "$COMPOSE_FILE" up -d --scale backend=2 --no-recreate
    
    # Wait for new instances to be healthy
    sleep 15
    
    # Remove old instances
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    
    success "Services restarted"
}

# Health check
health_check() {
    info "Running health checks..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf http://localhost/health > /dev/null; then
            success "Health check passed"
            return 0
        fi
        
        warning "Health check attempt $attempt/$max_attempts failed, retrying..."
        sleep 2
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
    return 1
}

# Cleanup
cleanup() {
    info "Cleaning up..."
    
    # Remove unused images
    docker image prune -af --filter "until=72h"
    
    # Remove unused volumes
    docker volume prune -f
    
    success "Cleanup completed"
}

# Rollback
rollback() {
    error "Deployment failed, initiating rollback..."
    
    local previous_tag=$(cat "${PROJECT_DIR}/.previous-deployment" 2>/dev/null || echo "")
    
    if [ -z "$previous_tag" ]; then
        error "No previous deployment found for rollback"
        exit 1
    fi
    
    info "Rolling back to: $previous_tag"
    
    export IMAGE_TAG="$previous_tag"
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    
    if health_check; then
        success "Rollback completed successfully"
    else
        error "Rollback failed! Manual intervention required"
        exit 1
    fi
}

# Main deployment function
deploy() {
    info "Starting deployment..."
    
    # Create log directory
    mkdir -p "${PROJECT_DIR}/logs"
    
    # Save current deployment for potential rollback
    if [ -f "${PROJECT_DIR}/.current-deployment" ]; then
        cp "${PROJECT_DIR}/.current-deployment" "${PROJECT_DIR}/.previous-deployment"
    fi
    
    # Execute deployment steps
    check_prerequisites
    pull_images
    
    # Backup database before migration
    info "Creating database backup..."
    ${SCRIPT_DIR}/backup-database.sh || warning "Database backup failed, continuing..."
    
    run_migrations
    restart_services
    
    if health_check; then
        optimize_app
        
        # Restart queue workers
        info "Restarting queue workers..."
        docker compose -f "$COMPOSE_FILE" exec -T backend php artisan horizon:terminate
        
        # Save current deployment info
        echo "${IMAGE_TAG:-latest}" > "${PROJECT_DIR}/.current-deployment"
        
        cleanup
        success "Deployment completed successfully!"
    else
        rollback
        exit 1
    fi
}

# Script entry point
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    health)
        health_check
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|health}"
        exit 1
        ;;
esac
