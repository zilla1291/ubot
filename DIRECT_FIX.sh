#!/bin/bash

# Direct Fix - No Git Required
# Run this as root on your VPS

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Unfiltered Bytzz - Direct Fix${NC}"
echo -e "${BLUE}║   No Git Required${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Go to web directory
cd /var/www/netivosolutions.top/web

echo -e "${YELLOW}Stopping services...${NC}"
sudo systemctl stop ubot-web.service 2>/dev/null || true
sudo pkill -f "node" 2>/dev/null || true
sleep 1

echo -e "${YELLOW}Cleaning up...${NC}"
rm -rf node_modules package-lock.json

echo -e "${YELLOW}Creating package.json...${NC}"
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

echo -e "${YELLOW}Installing npm packages...${NC}"
npm install --production 2>&1 | tail -5

echo -e "${YELLOW}Creating server-minimal.js...${NC}"
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
    res.json({ 
        status: 'ok', 
        port: 3001,
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/*', (req, res) => {
    res.json({ 
        message: 'API endpoint',
        path: req.path 
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('[✓] Server running on port ' + PORT);
    console.log('[✓] Access at http://localhost:' + PORT);
});
SERVEREOF

echo -e "${YELLOW}Updating systemd service...${NC}"
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

[Install]
WantedBy=multi-user.target
SVCEOF

echo -e "${YELLOW}Starting service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ubot-web.service
sudo systemctl start ubot-web.service

sleep 2

echo -e "${YELLOW}Checking status...${NC}"
if sudo systemctl is-active --quiet ubot-web.service; then
    echo -e "${GREEN}✓ Service is RUNNING${NC}"
else
    echo -e "${RED}✗ Service failed${NC}"
    sudo journalctl -u ubot-web.service -n 10 --no-pager
    exit 1
fi

echo -e "${YELLOW}Checking port 3001...${NC}"
if sudo ss -tlnp 2>/dev/null | grep -q :3001; then
    echo -e "${GREEN}✓ Port 3001 is LISTENING${NC}"
else
    echo -e "${RED}✗ Port 3001 NOT listening${NC}"
    sleep 2
    ps aux | grep node
fi

echo -e "${YELLOW}Testing connection...${NC}"
sleep 1
if curl -s http://localhost:3001/health >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is responding${NC}"
    curl -s http://localhost:3001/health | head -1
else
    echo -e "${YELLOW}ℹ Testing again...${NC}"
    sleep 2
    curl -v http://localhost:3001/health 2>&1 | tail -5
fi

echo ""
echo -e "${BLUE}✓ Done!${NC}"
echo ""
echo "Access website:"
echo "  http://172.31.38.194:3001"
echo "  http://172.31.38.194  (through Apache)"
echo ""
echo "Commands:"
echo "  systemctl status ubot-web.service"
echo "  journalctl -u ubot-web.service -f"
echo "  curl http://172.31.38.194:3001/health"
echo ""
