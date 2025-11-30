#!/bin/bash

#################################
# Unfiltered Bytzz - Quick Fix
# Diagnostic & Fix Script
#################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Unfiltered Bytzz - Diagnostics & Fix${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

DOMAIN="netivosolutions.top"
APP_DIR="/var/www/$DOMAIN"

# Step 1: Check Node.js
echo -e "${YELLOW}[1/10] Checking Node.js...${NC}"
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js: $(node --version)${NC}"
else
    echo -e "${RED}✗ Node.js not installed${NC}"
    apt-get install -y nodejs npm
fi

# Step 2: Check if app directory exists
echo -e "${YELLOW}[2/10] Checking application directory...${NC}"
if [ -d "$APP_DIR" ]; then
    echo -e "${GREEN}✓ Application directory: $APP_DIR${NC}"
else
    echo -e "${RED}✗ Application directory not found${NC}"
    mkdir -p $APP_DIR
    if [ -d "/home/ubuntu/ubot" ]; then
        cp -r /home/ubuntu/ubot/* $APP_DIR/
    fi
fi

# Step 3: Check dependencies
echo -e "${YELLOW}[3/10] Checking web dependencies...${NC}"
if [ -f "$APP_DIR/web/package.json" ]; then
    cd $APP_DIR/web
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing missing dependencies...${NC}"
        npm install --production
    fi
    echo -e "${GREEN}✓ Dependencies ready${NC}"
else
    echo -e "${RED}✗ package.json not found${NC}"
fi

# Step 4: Check Nginx
echo -e "${YELLOW}[4/10] Checking Nginx...${NC}"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✓ Nginx installed${NC}"
else
    echo -e "${YELLOW}Installing Nginx...${NC}"
    apt-get install -y nginx
fi

# Step 5: Create simple Nginx config
echo -e "${YELLOW}[5/10] Creating Nginx configuration...${NC}"
cat > /etc/nginx/sites-available/$DOMAIN << 'EOF'
upstream bot_app {
    server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    location / {
        proxy_pass http://bot_app;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Connection "";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

echo -e "${GREEN}✓ Nginx config created${NC}"

# Step 6: Enable Nginx site
echo -e "${YELLOW}[6/10] Enabling Nginx configuration...${NC}"
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Step 7: Test Nginx
echo -e "${YELLOW}[7/10] Testing Nginx configuration...${NC}"
if nginx -t 2>&1; then
    echo -e "${GREEN}✓ Nginx config is valid${NC}"
else
    echo -e "${RED}✗ Nginx config has errors${NC}"
fi

# Step 8: Create systemd service
echo -e "${YELLOW}[8/10] Creating systemd service...${NC}"
cat > /etc/systemd/system/ubot-web.service << 'EOF'
[Unit]
Description=Unfiltered Bot Web Platform
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/netivosolutions.top/web
ExecStart=/usr/bin/node /var/www/netivosolutions.top/web/server.js
Restart=always
RestartSec=5
StandardOutput=append:/var/log/ubot/web.log
StandardError=append:/var/log/ubot/web.log
SyslogIdentifier=ubot-web

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
mkdir -p /var/log/ubot
touch /var/log/ubot/web.log
chmod 777 /var/log/ubot/web.log

echo -e "${GREEN}✓ Systemd service created${NC}"

# Step 9: Start services
echo -e "${YELLOW}[9/10] Starting services...${NC}"
systemctl daemon-reload
systemctl enable nginx
systemctl enable ubot-web.service
systemctl restart nginx
systemctl restart ubot-web.service

sleep 2

echo -e "${GREEN}✓ Services started${NC}"

# Step 10: Verify services
echo -e "${YELLOW}[10/10] Verifying services...${NC}"
echo ""

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    systemctl start nginx
fi

if systemctl is-active --quiet ubot-web.service; then
    echo -e "${GREEN}✓ Web service is running${NC}"
else
    echo -e "${RED}✗ Web service is not running${NC}"
    echo -e "${YELLOW}Checking logs:${NC}"
    journalctl -u ubot-web.service -n 20
fi

# Check port listening
echo ""
echo -e "${YELLOW}Checking ports:${NC}"
if ss -tlnp | grep -q 3001; then
    echo -e "${GREEN}✓ Port 3001 is listening${NC}"
else
    echo -e "${RED}✗ Port 3001 is NOT listening${NC}"
fi

if ss -tlnp | grep -q 80; then
    echo -e "${GREEN}✓ Port 80 is listening${NC}"
else
    echo -e "${RED}✗ Port 80 is NOT listening${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Setup Complete!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Access your website at:${NC}"
echo -e "  • http://your-server-ip"
echo -e "  • http://$DOMAIN (if DNS is configured)"

echo -e "\n${YELLOW}Useful commands:${NC}"
echo -e "  • View web logs: tail -f /var/log/ubot/web.log"
echo -e "  • View Nginx logs: tail -f /var/log/nginx/error.log"
echo -e "  • Service status: systemctl status ubot-web.service"
echo -e "  • Restart service: systemctl restart ubot-web.service"
echo -e "  • Nginx status: systemctl status nginx"

echo ""
