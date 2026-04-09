# =============================================================================
# Skilloka Nginx - Dockerfile
# Optimized reverse proxy configuration
# =============================================================================

FROM nginx:1.25-alpine

# Install additional tools
RUN apk add --no-cache curl openssl

# Create log directory
RUN mkdir -p /var/log/nginx

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configurations
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/ /etc/nginx/conf.d/
COPY docker/nginx/snippets/ /etc/nginx/snippets/

# Copy SSL certificates placeholder (will be mounted in production)
RUN mkdir -p /etc/nginx/ssl

# Create cache directories
RUN mkdir -p /var/cache/nginx/fastcgi \
    && mkdir -p /var/cache/nginx/proxy

# Set permissions
RUN chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx

EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
