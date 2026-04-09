#!/bin/bash
# =============================================================================
# Skilloka - Blue-Green Switch Script
# Switches traffic between blue and green environments
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NGINX_UPSTREAM_DIR="${PROJECT_DIR}/docker/nginx/conf.d/upstream"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get current active environment
get_current_env() {
    if [ -f "${PROJECT_DIR}/.current-env" ]; then
        cat "${PROJECT_DIR}/.current-env"
    else
        echo "blue"  # Default
    fi
}

# Switch to specified environment
switch_to() {
    local target_env="$1"
    
    if [ "$target_env" != "blue" ] && [ "$target_env" != "green" ]; then
        log "${RED}Invalid environment: $target_env. Must be 'blue' or 'green'${NC}"
        exit 1
    fi
    
    local current_env=$(get_current_env)
    
    if [ "$current_env" == "$target_env" ]; then
        log "Already on ${target_env} environment"
        return 0
    fi
    
    log "Switching from ${current_env} to ${target_env}..."
    
    # Update nginx upstream configuration
    if [ "$target_env" == "blue" ]; then
        cat > "${NGINX_UPSTREAM_DIR}/backend.conf" << 'EOF'
upstream backend {
    server backend-blue:9000 weight=1;
    # server backend-green:9000 backup;
    keepalive 32;
}
EOF
    else
        cat > "${NGINX_UPSTREAM_DIR}/backend.conf" << 'EOF'
upstream backend {
    server backend-green:9000 weight=1;
    # server backend-blue:9000 backup;
    keepalive 32;
}
EOF
    fi
    
    # Reload nginx
    docker exec skilloka-nginx nginx -t && docker exec skilloka-nginx nginx -s reload
    
    # Update state file
    echo "$target_env" > "${PROJECT_DIR}/.current-env"
    
    log "${GREEN}✓ Successfully switched to ${target_env} environment${NC}"
}

# Show current status
status() {
    local current_env=$(get_current_env)
    echo ""
    echo "Current Environment: ${current_env}"
    echo ""
    echo "Container Status:"
    docker ps --filter "name=skilloka-backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
}

# Main
case "${1:-status}" in
    blue)
        switch_to "blue"
        ;;
    green)
        switch_to "green"
        ;;
    toggle)
        current=$(get_current_env)
        if [ "$current" == "blue" ]; then
            switch_to "green"
        else
            switch_to "blue"
        fi
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {blue|green|toggle|status}"
        exit 1
        ;;
esac
