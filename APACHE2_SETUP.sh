#!/bin/bash

#################################
# Unfiltered Bytzz - Apache2 Setup
# Production VPS Setup with Apache2
# Author: Glen Zilla
#################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Unfiltered Bytzz - Apache2 Setup${NC}"
echo -e "${BLUE}║   Author: Glen Zilla${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

DOMAIN="netivosolutions.top"
APP_DIR="/var/www/$DOMAIN"

# Step 1: Update system
echo -e "${YELLOW}[1/12] Updating system...${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

# Step 2: Install Apache2
echo -e "${YELLOW}[2/12] Installing Apache2...${NC}"
apt-get install -y apache2 apache2-utils libapache2-mod-proxy-html
echo -e "${GREEN}✓ Apache2 installed${NC}"

# Step 3: Enable required modules
echo -e "${YELLOW}[3/12] Enabling Apache2 modules...${NC}"
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod ssl
a2enmod headers
echo -e "${GREEN}✓ Apache2 modules enabled${NC}"

# Step 4: Install Node.js and npm
echo -e "${YELLOW}[4/12] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    apt-get install -y nodejs npm
fi
echo -e "${GREEN}✓ Node.js: $(node --version)${NC}"

# Step 5: Create directories
echo -e "${YELLOW}[5/12] Creating directories...${NC}"
mkdir -p $APP_DIR
mkdir -p /var/lib/ubot
mkdir -p /var/log/ubot
echo -e "${GREEN}✓ Directories created${NC}"

# Step 6: Copy application files
echo -e "${YELLOW}[6/12] Copying application files...${NC}"
if [ -d "/home/ubuntu/ubot" ]; then
    cp -r /home/ubuntu/ubot/* $APP_DIR/ 2>/dev/null || true
    echo -e "${GREEN}✓ Files copied from /home/ubuntu/ubot${NC}"
elif [ -d "/root/ubot" ]; then
    cp -r /root/ubot/* $APP_DIR/ 2>/dev/null || true
    echo -e "${GREEN}✓ Files copied from /root/ubot${NC}"
else
    echo -e "${YELLOW}ℹ Using existing files at $APP_DIR${NC}"
fi

# Step 7: Set permissions
echo -e "${YELLOW}[7/12] Setting permissions...${NC}"
chown -R www-data:www-data $APP_DIR
chown -R www-data:www-data /var/lib/ubot
chown -R www-data:www-data /var/log/ubot
chmod -R 755 $APP_DIR
echo -e "${GREEN}✓ Permissions set${NC}"

# Step 8: Install dependencies
echo -e "${YELLOW}[8/12] Installing web dependencies...${NC}"
cd $APP_DIR/web
npm install --production --omit=dev 2>&1 | grep -v "npm WARN" || true
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Step 9: Create Apache2 virtual host
echo -e "${YELLOW}[9/12] Creating Apache2 virtual host...${NC}"
cat > /etc/apache2/sites-available/$DOMAIN.conf << 'EOF'
<VirtualHost *:80>
    ServerName netivosolutions.top
    ServerAlias www.netivosolutions.top
    ServerAdmin admin@netivosolutions.top
    
    # Proxy settings
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3001/
    ProxyPassReverse / http://127.0.0.1:3001/
    
    # WebSocket support
    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteCond %{HTTP:Upgrade} websocket [NC]
        RewriteCond %{HTTP:Connection} upgrade [NC]
        RewriteRule ^/?(.*) "ws://127.0.0.1:3001/$1" [P,L]
    </IfModule>
    
    # Headers
    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}s"
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-Content-Type-Options "nosniff"
    
    # Logging
    ErrorLog ${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog ${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF

echo -e "${GREEN}✓ Virtual host created${NC}"

# Step 10: Enable virtual host and disable default
echo -e "${YELLOW}[10/12] Enabling virtual host...${NC}"
a2ensite $DOMAIN.conf
a2dissite 000-default.conf 2>/dev/null || true
echo -e "${GREEN}✓ Virtual host enabled${NC}"

# Step 11: Test Apache2 configuration
echo -e "${YELLOW}[11/12] Testing Apache2 configuration...${NC}"
if apache2ctl configtest; then
    echo -e "${GREEN}✓ Apache2 configuration valid${NC}"
else
    echo -e "${RED}✗ Apache2 configuration error${NC}"
    exit 1
fi

# Step 12: Create systemd service and start
echo -e "${YELLOW}[12/12] Creating systemd service...${NC}"
cat > /etc/systemd/system/ubot-web.service << 'EOF'
[Unit]
Description=Unfiltered Bot Web Platform
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/netivosolutions.top/web
ExecStart=/usr/bin/node /var/www/netivosolutions.top/web/server.js
Restart=always
RestartSec=5
StandardOutput=append:/var/log/ubot/web.log
StandardError=append:/var/log/ubot/web.log
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF

# Create log file
touch /var/log/ubot/web.log
chmod 644 /var/log/ubot/web.log
chown www-data:www-data /var/log/ubot/web.log

# Start services
systemctl daemon-reload
systemctl enable apache2
systemctl enable ubot-web.service
systemctl restart apache2
systemctl start ubot-web.service

sleep 2

echo -e "${GREEN}✓ Services started${NC}"

# Verify services
echo ""
echo -e "${YELLOW}Verifying setup:${NC}"

if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Apache2 is running${NC}"
else
    echo -e "${RED}✗ Apache2 is NOT running${NC}"
fi

if systemctl is-active --quiet ubot-web.service; then
    echo -e "${GREEN}✓ Web service is running${NC}"
else
    echo -e "${RED}✗ Web service is NOT running${NC}"
    echo -e "${YELLOW}Last 30 lines of logs:${NC}"
    tail -30 /var/log/ubot/web.log || true
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Apache2 Setup Complete!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Access your website:${NC}"
echo -e "  • http://YOUR_SERVER_IP"
echo -e "  • http://$DOMAIN (if DNS configured)"

echo -e "\n${YELLOW}Useful commands:${NC}"
echo -e "  • View web logs: tail -f /var/log/ubot/web.log"
echo -e "  • View Apache errors: tail -f /var/log/apache2/$DOMAIN-error.log"
echo -e "  • Service status: systemctl status ubot-web.service"
echo -e "  • Restart web: systemctl restart ubot-web.service"
echo -e "  • Apache status: systemctl status apache2"
echo -e "  • Apache test: apache2ctl configtest"

echo -e "\n${YELLOW}Generate vouchers:${NC}"
echo -e "  cd $APP_DIR"
echo -e "  node ubot.js voucher admin 1"

echo ""
