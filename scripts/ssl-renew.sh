#!/bin/bash
# =============================================================================
# Skilloka - SSL Certificate Renewal Script
# Let's Encrypt certificate management
# =============================================================================

set -euo pipefail

# Configuration
DOMAIN="${DOMAIN:-api.skilloka.id}"
EMAIL="${ACME_EMAIL:-admin@skilloka.id}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
NGINX_CONTAINER="skilloka-nginx"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    log "${RED}Certbot is not installed. Installing...${NC}"
    apt-get update && apt-get install -y certbot
fi

# Check certificate expiry
check_expiry() {
    if [ -f "${CERT_DIR}/fullchain.pem" ]; then
        EXPIRY_DATE=$(openssl x509 -enddate -noout -in "${CERT_DIR}/fullchain.pem" | cut -d= -f2)
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_EPOCH=$(date +%s)
        DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
        
        log "Certificate expires in ${DAYS_UNTIL_EXPIRY} days (${EXPIRY_DATE})"
        
        if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
            return 0  # Needs renewal
        else
            return 1  # No renewal needed
        fi
    else
        log "${YELLOW}No certificate found, will create new one${NC}"
        return 0
    fi
}

# Obtain or renew certificate
renew_certificate() {
    log "Renewing SSL certificate for ${DOMAIN}..."
    
    # Stop nginx temporarily for standalone mode
    docker stop ${NGINX_CONTAINER} 2>/dev/null || true
    
    # Run certbot
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "${EMAIL}" \
        -d "${DOMAIN}" \
        -d "*.${DOMAIN}" \
        --preferred-challenges dns \
        --dns-cloudflare \
        --dns-cloudflare-credentials /root/.cloudflare/credentials
    
    if [ $? -eq 0 ]; then
        log "${GREEN}✓ Certificate renewed successfully${NC}"
        
        # Copy certificates to docker volume
        cp "${CERT_DIR}/fullchain.pem" /opt/skilloka/docker/ssl/fullchain.pem
        cp "${CERT_DIR}/privkey.pem" /opt/skilloka/docker/ssl/privkey.pem
        
        # Restart nginx
        docker start ${NGINX_CONTAINER}
        docker exec ${NGINX_CONTAINER} nginx -s reload
        
        log "${GREEN}✓ Nginx reloaded with new certificate${NC}"
    else
        log "${RED}✗ Certificate renewal failed${NC}"
        docker start ${NGINX_CONTAINER}
        exit 1
    fi
}

# Main
case "${1:-check}" in
    check)
        check_expiry
        ;;
    renew)
        if check_expiry; then
            renew_certificate
        else
            log "Certificate renewal not needed yet"
        fi
        ;;
    force-renew)
        renew_certificate
        ;;
    *)
        echo "Usage: $0 {check|renew|force-renew}"
        exit 1
        ;;
esac
