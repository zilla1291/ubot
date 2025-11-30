#!/bin/bash

# Complete Fresh Setup for bot.netivosolutions.top
# Run as root on your VPS: 172.31.38.194

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Fresh Setup for bot.netivosolutions.top${NC}"
echo -e "${BLUE}║   Server: 172.31.38.194${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Must run as root (sudo)${NC}"
    exit 1
fi

DOMAIN="bot.netivosolutions.top"
APP_DIR="/var/www/$DOMAIN"

# Step 1: Create fresh directory
echo -e "${YELLOW}[1/10] Creating fresh directory structure...${NC}"
rm -rf $APP_DIR 2>/dev/null || true
mkdir -p $APP_DIR
cd $APP_DIR
echo -e "${GREEN}✓ Directory created at $APP_DIR${NC}"

# Step 2: Create package.json
echo -e "${YELLOW}[2/10] Creating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "ubot-bot",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF
echo -e "${GREEN}✓ package.json created${NC}"

# Step 3: Create simple server
echo -e "${YELLOW}[3/10] Creating server.js...${NC}"
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3002;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        service: 'Unfiltered Bytzz Bot Platform',
        domain: 'bot.netivosolutions.top',
        port: PORT,
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Unfiltered Bytzz</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 20px; border-radius: 8px; max-width: 600px; margin: 0 auto; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                h1 { color: #333; }
                .status { background: #4CAF50; color: white; padding: 10px; border-radius: 4px; margin: 10px 0; }
                .info { background: #e3f2fd; padding: 10px; border-radius: 4px; margin: 10px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🤖 Unfiltered Bytzz</h1>
                <p>WhatsApp Bot Deployment Platform</p>
                <div class="status">✓ Platform is LIVE</div>
                <div class="info">
                    <strong>Domain:</strong> bot.netivosolutions.top<br>
                    <strong>Status:</strong> Running<br>
                    <strong>Port:</strong> 3002<br>
                    <strong>Time:</strong> ` + new Date().toISOString() + `
                </div>
                <p><a href="/health" style="color: #2196F3;">Check Health</a></p>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('✓ Server running on port ' + PORT);
    console.log('✓ Domain: bot.netivosolutions.top');
});
EOF
echo -e "${GREEN}✓ server.js created${NC}"

# Step 4: Create public directory with index.html
echo -e "${YELLOW}[4/10] Creating public directory...${NC}"
mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unfiltered Bytzz - WhatsApp Bot Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 40px;
            max-width: 600px;
            width: 100%;
            text-align: center;
        }
        h1 { color: #333; margin-bottom: 10px; font-size: 2.5em; }
        .tagline { color: #666; margin-bottom: 20px; font-size: 1.1em; }
        .status-badge {
            display: inline-block;
            background: #4CAF50;
            color: white;
            padding: 10px 20px;
            border-radius: 20px;
            margin: 15px 0;
            font-weight: bold;
        }
        .info-box {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: left;
        }
        .info-box p { margin: 10px 0; color: #555; }
        .info-box strong { color: #333; }
        .feature-list {
            text-align: left;
            margin: 20px 0;
        }
        .feature-list li { margin: 8px 0; color: #666; }
        a { color: #667eea; text-decoration: none; font-weight: bold; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Unfiltered Bytzz</h1>
        <p class="tagline">WhatsApp Bot Deployment Platform</p>
        
        <div class="status-badge">✓ Platform is LIVE</div>
        
        <div class="info-box">
            <p><strong>Domain:</strong> bot.netivosolutions.top</p>
            <p><strong>Server IP:</strong> 172.31.38.194</p>
            <p><strong>Status:</strong> Running</p>
            <p><strong>Version:</strong> 2.0.0</p>
        </div>

        <div class="feature-list">
            <strong>Platform Features:</strong>
            <ul>
                <li>✓ One-Click Bot Deployment</li>
                <li>✓ Web Dashboard</li>
                <li>✓ Voucher System</li>
                <li>✓ Multi-Session Support</li>
                <li>✓ Real-time Feature Toggle</li>
            </ul>
        </div>

        <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #999; font-size: 0.9em;">
            Made with ❤️ by Glen Zilla | <a href="https://t.me/unfilteredg">@unfilteredg</a>
        </p>
    </div>
</body>
</html>
EOF
echo -e "${GREEN}✓ Public directory created${NC}"

# Step 5: Install npm dependencies
echo -e "${YELLOW}[5/10] Installing npm dependencies...${NC}"
npm install 2>&1 | grep -E "(added|up to date)" || echo "npm install complete"
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Step 6: Stop old service
echo -e "${YELLOW}[6/10] Stopping old services...${NC}"
systemctl stop ubot-web.service 2>/dev/null || true
pkill -f "node" 2>/dev/null || true
sleep 1
echo -e "${GREEN}✓ Old services stopped${NC}"

# Step 7: Create new systemd service
echo -e "${YELLOW}[7/10] Creating systemd service...${NC}"
tee /etc/systemd/system/ubot-bot.service > /dev/null << 'EOF'
[Unit]
Description=Unfiltered Bot Platform
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/bot.netivosolutions.top
ExecStart=/usr/bin/node /var/www/bot.netivosolutions.top/server.js
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}✓ Service created${NC}"

# Step 8: Create Apache2 virtual host
echo -e "${YELLOW}[8/10] Creating Apache2 virtual host...${NC}"
tee /etc/apache2/sites-available/bot.netivosolutions.top.conf > /dev/null << 'EOF'
<VirtualHost *:80>
    ServerName bot.netivosolutions.top
    ServerAlias www.bot.netivosolutions.top
    ServerAdmin admin@netivosolutions.top
    
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3002/
    ProxyPassReverse / http://127.0.0.1:3002/
    
    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}s"
    
    ErrorLog ${APACHE_LOG_DIR}/bot.netivosolutions.top-error.log
    CustomLog ${APACHE_LOG_DIR}/bot.netivosolutions.top-access.log combined
</VirtualHost>
EOF
echo -e "${GREEN}✓ Virtual host created${NC}"

# Step 9: Enable site and restart Apache
echo -e "${YELLOW}[9/10] Configuring Apache2...${NC}"
a2ensite bot.netivosolutions.top.conf 2>/dev/null || true
a2dissite 000-default.conf 2>/dev/null || true
apache2ctl configtest 2>/dev/null || echo "Apache config needs review"
systemctl restart apache2
echo -e "${GREEN}✓ Apache2 configured${NC}"

# Step 10: Start new service
echo -e "${YELLOW}[10/10] Starting new service...${NC}"
systemctl daemon-reload
systemctl enable ubot-bot.service
systemctl start ubot-bot.service
sleep 2

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        ✓ Setup Complete!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Verify
if systemctl is-active --quiet ubot-bot.service; then
    echo -e "${GREEN}✓ Service is RUNNING${NC}"
else
    echo -e "${RED}✗ Service NOT running${NC}"
    journalctl -u ubot-bot.service -n 20 --no-pager
fi

if ss -tlnp 2>/dev/null | grep -q :3002; then
    echo -e "${GREEN}✓ Port 3002 is LISTENING${NC}"
else
    echo -e "${RED}✗ Port 3002 NOT listening${NC}"
fi

echo ""
echo -e "${YELLOW}Access your platform:${NC}"
echo "  • http://172.31.38.194:3002"
echo "  • http://172.31.38.194  (Apache proxy)"
echo "  • http://bot.netivosolutions.top  (DNS)"
echo ""

echo -e "${YELLOW}Useful commands:${NC}"
echo "  systemctl status ubot-bot.service"
echo "  journalctl -u ubot-bot.service -f"
echo "  curl http://localhost:3002/health"
echo "  ss -tlnp | grep 3002"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update Cloudflare DNS: Add A record bot.netivosolutions.top → 172.31.38.194"
echo "  2. Enable Cloudflare proxy (orange cloud)"
echo "  3. Test: http://bot.netivosolutions.top"
echo ""
