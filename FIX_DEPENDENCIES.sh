#!/bin/bash

# Quick fix for npm dependencies on VPS
set -e

echo "=== Fixing npm dependencies ==="

cd /var/www/netivosolutions.top/web

# Remove broken modules
rm -rf node_modules package-lock.json

# Create minimal package.json with only essential packages
cat > package.json << 'EOF'
{
  "name": "unfiltered-bytzz-web",
  "version": "1.0.0",
  "description": "Unfiltered Bytzz WhatsApp Bot Deployment Platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "author": "Glen Zilla",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

echo "✓ package.json created"

# Install only essential dependencies
echo "Installing dependencies (this may take a minute)..."
npm install --no-optional 2>&1 | tail -20

echo "✓ Dependencies installed"

# List what was installed
echo ""
echo "Installed packages:"
ls -la node_modules | wc -l

# Update systemd service to use minimal server
sudo systemctl stop ubot-web.service 2>/dev/null || true

# Update the service file
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
RestartSec=5
StandardOutput=append:/var/log/ubot/web.log
StandardError=append:/var/log/ubot/web.log
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
SVCEOF

echo "✓ Service file updated"

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable ubot-web.service
sudo systemctl start ubot-web.service

echo "✓ Service started"

# Wait a bit and check status
sleep 2
echo ""
echo "Service status:"
sudo systemctl status ubot-web.service | grep -E "(Active|Running)"

# Check if listening on port 3001
echo ""
echo "Checking port 3001..."
if sudo ss -tlnp | grep -q 3001; then
    echo "✓ Port 3001 is listening!"
else
    echo "✗ Port 3001 is NOT listening - checking logs:"
    sudo tail -20 /var/log/ubot/web.log
fi

# Test local connection
echo ""
echo "Testing local connection..."
sleep 1
if curl -s http://localhost:3001/health | grep -q "healthy"; then
    echo "✓ Web server is responding!"
else
    echo "Trying direct curl..."
    curl -v http://localhost:3001/health 2>&1 | tail -10
fi

echo ""
echo "=== Setup Complete ==="
echo "Access your website at:"
echo "  • http://YOUR_SERVER_IP"
echo "  • http://YOUR_SERVER_IP:3001 (direct)"
echo ""
