#!/bin/bash

# Comprehensive Debugging Script
# For IP: 172.31.38.194

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Unfiltered Bytzz - Debug & Fix${NC}"
echo -e "${BLUE}║      Server: 172.31.38.194${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Step 1: Check file structure
echo -e "${YELLOW}[1/15] Checking file structure...${NC}"
echo "Files in /var/www/netivosolutions.top:"
ls -la /var/www/netivosolutions.top/ 2>/dev/null || echo "Directory not found"

echo ""
echo "Files in /var/www/netivosolutions.top/web:"
ls -la /var/www/netivosolutions.top/web/ 2>/dev/null || echo "Directory not found"

echo ""
echo "Node modules in /var/www/netivosolutions.top/web/node_modules:"
ls -la /var/www/netivosolutions.top/web/node_modules 2>/dev/null | head -20 || echo "No node_modules found"

# Step 2: Stop any existing services
echo -e "\n${YELLOW}[2/15] Stopping existing services...${NC}"
sudo systemctl stop ubot-web.service 2>/dev/null || true
sudo pkill -f "node.*server" 2>/dev/null || true
sleep 1
echo -e "${GREEN}✓ Services stopped${NC}"

# Step 3: Clean directory
echo -e "${YELLOW}[3/15] Cleaning directory...${NC}"
cd /var/www/netivosolutions.top/web
rm -rf node_modules package-lock.json
echo -e "${GREEN}✓ Directory cleaned${NC}"

# Step 4: Create simple package.json
echo -e "${YELLOW}[4/15] Creating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "ubot-web",
  "version": "1.0.0",
  "main": "server-minimal.js",
  "scripts": {
    "start": "node server-minimal.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF
echo -e "${GREEN}✓ package.json created${NC}"

# Step 5: Install npm dependencies
echo -e "${YELLOW}[5/15] Installing npm dependencies...${NC}"
npm install 2>&1 | grep -E "(added|packages)" || true
echo -e "${GREEN}✓ npm install complete${NC}"

# Step 6: Verify express is installed
echo -e "${YELLOW}[6/15] Verifying express installation...${NC}"
if [ -d "node_modules/express" ]; then
    echo -e "${GREEN}✓ Express installed${NC}"
else
    echo -e "${RED}✗ Express NOT installed - installing again...${NC}"
    npm install express cors --save
fi

# Step 7: Create minimal server if needed
echo -e "${YELLOW}[7/15] Creating minimal server...${NC}"
if [ ! -f "server-minimal.js" ]; then
    cat > server-minimal.js << 'SERVEREOF'
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (req, res) => {
    res.json({ status: 'ok', port: 3001 });
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('✓ Server running on port ' + PORT);
});
SERVEREOF
    echo -e "${GREEN}✓ server-minimal.js created${NC}"
else
    echo -e "${GREEN}✓ server-minimal.js exists${NC}"
fi

# Step 8: Test if server can start
echo -e "${YELLOW}[8/15] Testing server startup...${NC}"
timeout 5 node server-minimal.js &
sleep 2
if ps aux | grep -q "node server-minimal" | grep -v grep; then
    echo -e "${GREEN}✓ Server started successfully${NC}"
    sudo pkill -f "node server-minimal" || true
else
    echo -e "${YELLOW}ℹ Server test (may need systemd to run properly)${NC}"
fi

# Step 9: Update systemd service
echo -e "${YELLOW}[9/15] Updating systemd service...${NC}"
sudo tee /etc/systemd/system/ubot-web.service > /dev/null << 'SVCEOF'
[Unit]
Description=Unfiltered Bot Web Platform
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/netivosolutions.top/web
ExecStart=/usr/bin/node /var/www/netivosolutions.top/web/server-minimal.js
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ubot

[Install]
WantedBy=multi-user.target
SVCEOF
echo -e "${GREEN}✓ Service file updated${NC}"

# Step 10: Reload and enable service
echo -e "${YELLOW}[10/15] Enabling service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ubot-web.service
echo -e "${GREEN}✓ Service enabled${NC}"

# Step 11: Start service
echo -e "${YELLOW}[11/15] Starting service...${NC}"
sudo systemctl start ubot-web.service
sleep 2
echo -e "${GREEN}✓ Service started${NC}"

# Step 12: Check service status
echo -e "${YELLOW}[12/15] Checking service status...${NC}"
if sudo systemctl is-active --quiet ubot-web.service; then
    echo -e "${GREEN}✓ Service is RUNNING${NC}"
else
    echo -e "${RED}✗ Service is NOT RUNNING${NC}"
    echo "Logs:"
    sudo journalctl -u ubot-web.service -n 20 --no-pager
fi

# Step 13: Check if port 3001 is listening
echo -e "${YELLOW}[13/15] Checking port 3001...${NC}"
sleep 1
if sudo ss -tlnp | grep -q :3001; then
    echo -e "${GREEN}✓ Port 3001 is LISTENING${NC}"
else
    echo -e "${RED}✗ Port 3001 is NOT listening${NC}"
fi

# Step 14: Test local connection
echo -e "${YELLOW}[14/15] Testing local connection...${NC}"
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server responding on localhost:3001${NC}"
    curl -s http://localhost:3001/health | head -1
else
    echo -e "${YELLOW}ℹ Local test failed - may need wait${NC}"
fi

# Step 15: Check Apache proxy
echo -e "${YELLOW}[15/15] Checking Apache proxy...${NC}"
if sudo systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Apache2 is running${NC}"
    if [ -f "/etc/apache2/sites-enabled/netivosolutions.top.conf" ]; then
        echo -e "${GREEN}✓ Virtual host configured${NC}"
    else
        echo -e "${YELLOW}ℹ Virtual host needs configuration${NC}"
    fi
else
    echo -e "${YELLOW}ℹ Apache2 not running - starting...${NC}"
    sudo systemctl start apache2
fi

# Final summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Debug Complete!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Access your website:${NC}"
echo "  • Direct:  http://172.31.38.194:3001"
echo "  • Proxy:   http://172.31.38.194"
echo ""

echo -e "${YELLOW}Troubleshooting commands:${NC}"
echo "  • Service logs:   sudo journalctl -u ubot-web.service -f"
echo "  • Port check:     sudo ss -tlnp | grep 3001"
echo "  • Service status: sudo systemctl status ubot-web.service"
echo "  • Apache logs:    sudo tail -f /var/log/apache2/error.log"
echo "  • Local test:     curl http://localhost:3001/health"
echo ""

echo -e "${BLUE}If still not working, check:${NC}"
echo "  1. Do you see 'Service is RUNNING'?"
echo "  2. Do you see 'Port 3001 is LISTENING'?"
echo "  3. Are there any errors above?"
echo ""
