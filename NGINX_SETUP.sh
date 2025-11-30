#!/bin/bash

#################################
# Unfiltered Bytzz - Nginx Setup
# Production VPS Setup
# Author: Glen Zilla
#################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Unfiltered Bytzz - Nginx Setup${NC}"
echo -e "${BLUE}║  Author: Glen Zilla${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

DOMAIN="netivosolutions.top"
APP_DIR="/var/www/$DOMAIN"

# Update system
echo -e "${YELLOW}Updating system...${NC}"
apt-get update
apt-get upgrade -y

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    nodejs \
    npm \
    nginx \
    certbot \
    python3-certbot-nginx \
    build-essential

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p $APP_DIR
mkdir -p /var/lib/ubot
mkdir -p /var/log/ubot

echo -e "${GREEN}✓ Directories created${NC}"

# Copy application files
echo -e "${YELLOW}Copying application files...${NC}"
if [ -d "/home/ubuntu/ubot" ]; then
    cp -r /home/ubuntu/ubot/* $APP_DIR/
elif [ -d "/root/ubot" ]; then
    cp -r /root/ubot/* $APP_DIR/
fi

# Set permissions
chown -R www-data:www-data $APP_DIR
chown -R www-data:www-data /var/lib/ubot
chown -R www-data:www-data /var/log/ubot

echo -e "${GREEN}✓ Files copied and permissions set${NC}"

# Install web dependencies
echo -e "${YELLOW}Installing web platform dependencies...${NC}"
cd $APP_DIR/web
npm install --production

echo -e "${GREEN}✓ Web dependencies installed${NC}"

# Create Nginx configuration
echo -e "${YELLOW}Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/$DOMAIN << 'NGINX_CONFIG'
upstream bot_app {
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name netivosolutions.top www.netivosolutions.top;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name netivosolutions.top www.netivosolutions.top;
    
    # SSL certificates (update paths as needed)
    ssl_certificate /etc/letsencrypt/live/netivosolutions.top/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/netivosolutions.top/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Proxy settings
    location / {
        proxy_pass http://bot_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
    }
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/javascript application/json application/javascript;
    
    # Logs
    access_log /var/log/nginx/netivosolutions-access.log;
    error_log /var/log/nginx/netivosolutions-error.log;
}
NGINX_CONFIG

# Enable the site
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
rm -f /etc/nginx/sites-enabled/default

echo -e "${GREEN}✓ Nginx configured${NC}"

# Test Nginx config
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
nginx -t

# Setup SSL with Let's Encrypt
echo -e "${YELLOW}Setting up SSL certificate...${NC}"
certbot certonly --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN || echo -e "${YELLOW}SSL setup skipped (manual setup required)${NC}"

# Create systemd service for web platform
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/ubot-web.service << 'SERVICE_CONFIG'
[Unit]
Description=Unfiltered Bot Web Platform
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/netivosolutions.top/web
ExecStart=/usr/bin/node /var/www/netivosolutions.top/web/server.js
Restart=always
RestartSec=10
Environment="NODE_ENV=production"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_CONFIG

# Enable and start services
echo -e "${YELLOW}Starting services...${NC}"
systemctl daemon-reload
systemctl enable nginx
systemctl enable ubot-web.service
systemctl restart nginx
systemctl start ubot-web.service

echo -e "${GREEN}✓ Services started${NC}"

# Generate first voucher
echo -e "${YELLOW}Generating first voucher...${NC}"
cd $APP_DIR
NODE_ENV=production /usr/bin/node ubot.js voucher admin 1 || echo -e "${YELLOW}Manual voucher generation required${NC}"

# Display setup summary
echo -e "\n${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Installation Complete!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✓ Setup Summary:${NC}"
echo -e "  • Application: $APP_DIR"
echo -e "  • Web Platform: http://localhost:3001"
echo -e "  • Domain: https://$DOMAIN"
echo -e "  • Node.js: $(node --version)"
echo -e "  • Npm: $(npm --version)"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Access dashboard: https://$DOMAIN"
echo -e "  2. Generate vouchers: node $APP_DIR/ubot.js voucher admin 10"
echo -e "  3. Start selling deployments!"
echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "  • View logs: tail -f /var/log/nginx/netivosolutions-error.log"
echo -e "  • Service status: systemctl status ubot-web.service"
echo -e "  • Restart service: systemctl restart ubot-web.service"
echo -e "  • Check Nginx: nginx -t"

echo -e "\n${BLUE}Need help? Contact: @unfilteredg on Telegram${NC}\n"
