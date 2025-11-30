#!/bin/bash

#################################
# Unfiltered Bytzz Installation Script
# Production VPS Setup
# Author: Glen Zilla
# Website: netivosolutions.top
#################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="netivosolutions.top"
APP_DIR="/var/www/$DOMAIN"
BOT_DIR="/opt/unfiltered-bytzz"
WEB_DIR="/var/www/$DOMAIN/web"
DATA_DIR="/var/lib/unfiltered-bytzz"
LOG_DIR="/var/log/unfiltered-bytzz"
APACHE_USER="www-data"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Unfiltered Bytzz - Production Installation${NC}"
echo -e "${BLUE}║  Author: Glen Zilla${NC}"
echo -e "${BLUE}║  Telegram: @unfilteredg${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    echo "Use: sudo ./install.sh"
    exit 1
fi

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info message
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header "Step 1: Update System & Install Dependencies"

# Update system
apt-get update
apt-get upgrade -y
print_success "System updated"

# Install Node.js (if not already installed)
if ! command -v node &> /dev/null; then
    print_info "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    print_success "Node.js installed: $(node --version)"
else
    print_success "Node.js already installed: $(node --version)"
fi

# Install other dependencies
apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    python3 \
    apache2 \
    apache2-utils \
    libapache2-mod-proxy-html \
    libapache2-mod-ssl \
    certbot \
    python3-certbot-apache \
    ffmpeg \
    imagemagick \
    ghostscript

print_success "All dependencies installed"

print_header "Step 2: Create Directory Structure"

# Create directories
mkdir -p "$APP_DIR"
mkdir -p "$BOT_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$WEB_DIR"

# Set permissions
chown -R "$APACHE_USER:$APACHE_USER" "$APP_DIR"
chown -R "$APACHE_USER:$APACHE_USER" "$DATA_DIR"
chown -R "$APACHE_USER:$APACHE_USER" "$LOG_DIR"
chmod -R 755 "$APP_DIR"
chmod -R 755 "$DATA_DIR"
chmod -R 755 "$LOG_DIR"

print_success "Directory structure created"

print_header "Step 3: Clone Bot Repository"

# Check if directory is empty
if [ -z "$(ls -A $BOT_DIR)" ]; then
    print_info "Cloning repository to $BOT_DIR..."
    cd /tmp
    git clone https://github.com/zilla5187/unfiltered-bot.git unfiltered-bot-temp
    cp -r /tmp/unfiltered-bot-temp/* "$BOT_DIR/"
    rm -rf /tmp/unfiltered-bot-temp
    print_success "Repository cloned"
else
    print_info "Bot directory already populated, skipping clone"
fi

print_header "Step 4: Setup Web Application"

# Copy web files to Apache directory
if [ -d "$BOT_DIR/web" ]; then
    cp -r "$BOT_DIR/web"/* "$WEB_DIR/"
    print_success "Web files copied to $WEB_DIR"
else
    print_error "Web directory not found in repository"
fi

# Create .env file for web
cat > "$WEB_DIR/.env" << EOF
NODE_ENV=production
PORT=3001
ADMIN_KEY=$(openssl rand -hex 32)
DATABASE_PATH=$DATA_DIR
LOG_PATH=$LOG_DIR
DOMAIN=$DOMAIN
EOF

print_success ".env file created for web application"

print_header "Step 5: Install Node.js Dependencies"

# Install dependencies for main bot
cd "$BOT_DIR"
npm install
print_success "Bot dependencies installed"

# Install dependencies for web platform
cd "$WEB_DIR"
npm install
print_success "Web platform dependencies installed"

print_header "Step 6: Configure Apache Virtual Host"

# Create Apache configuration
cat > "/etc/apache2/sites-available/$DOMAIN.conf" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin admin@$DOMAIN

    DocumentRoot $APP_DIR

    # Enable Proxy modules
    ProxyPreserveHost On
    ProxyPass /api http://localhost:3001/api
    ProxyPassReverse /api http://localhost:3001/api
    ProxyPass / http://localhost:3001/
    ProxyPassReverse / http://localhost:3001/

    <Directory $APP_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Logging
    ErrorLog $LOG_DIR/apache_error.log
    CustomLog $LOG_DIR/apache_access.log combined

    # Redirect to HTTPS (after SSL setup)
    # Uncomment after SSL certificate is obtained
    # RewriteEngine On
    # RewriteCond %{HTTPS} off
    # RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

# HTTPS Configuration (uncomment after SSL setup)
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerName $DOMAIN
        ServerAlias www.$DOMAIN
        ServerAdmin admin@$DOMAIN

        DocumentRoot $APP_DIR

        ProxyPreserveHost On
        ProxyPass /api http://localhost:3001/api
        ProxyPassReverse /api http://localhost:3001/api
        ProxyPass / http://localhost:3001/
        ProxyPassReverse / http://localhost:3001/

        <Directory $APP_DIR>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog $LOG_DIR/apache_error.log
        CustomLog $LOG_DIR/apache_access.log combined

        SSLEngine on
        SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
    </VirtualHost>
</IfModule>
EOF

# Enable Apache modules
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod ssl

# Enable the virtual host
a2ensite "$DOMAIN.conf"

# Test Apache configuration
if apache2ctl configtest; then
    print_success "Apache configuration is valid"
    systemctl restart apache2
    print_success "Apache restarted"
else
    print_error "Apache configuration has errors"
    exit 1
fi

print_header "Step 7: Setup Systemd Services"

# Create systemd service for bot
cat > "/etc/systemd/system/unfiltered-bytzz-bot.service" << EOF
[Unit]
Description=Unfiltered Bytzz Bot
After=network.target

[Service]
Type=simple
User=$APACHE_USER
WorkingDirectory=$BOT_DIR
ExecStart=/usr/bin/node $BOT_DIR/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

Environment="NODE_ENV=production"
Environment="SESSION_DIR=$DATA_DIR/sessions"

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for web platform
cat > "/etc/systemd/system/unfiltered-bytzz-web.service" << EOF
[Unit]
Description=Unfiltered Bytzz Web Platform
After=network.target

[Service]
Type=simple
User=$APACHE_USER
WorkingDirectory=$WEB_DIR
ExecStart=/usr/bin/node $WEB_DIR/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

Environment="NODE_ENV=production"
Environment="PORT=3001"
Environment="DATABASE_PATH=$DATA_DIR"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable unfiltered-bytzz-bot.service
systemctl enable unfiltered-bytzz-web.service
print_success "Systemd services created and enabled"

print_header "Step 8: Setup SSL Certificate (Let's Encrypt)"

print_info "Requesting SSL certificate from Let's Encrypt..."
certbot certonly --apache -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN" || print_error "SSL setup skipped"

# Update Apache config if SSL was set up
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    print_success "SSL certificate installed"
    # Enable HTTPS redirect in Apache config
    sed -i 's/# RewriteEngine On/RewriteEngine On/g' "/etc/apache2/sites-available/$DOMAIN.conf"
    sed -i 's/# RewriteCond/RewriteCond/g' "/etc/apache2/sites-available/$DOMAIN.conf"
    sed -i 's/# RewriteRule/RewriteRule/g' "/etc/apache2/sites-available/$DOMAIN.conf"
    systemctl restart apache2
fi

print_header "Step 9: Create CLI Command"

# Create symbolic link for CLI command
ln -sf "$BOT_DIR/ubot.js" /usr/local/bin/ubot
chmod +x /usr/local/bin/ubot
chmod +x "$BOT_DIR/ubot.js"

print_success "CLI command 'ubot' installed"

print_header "Step 10: Initialize Database"

cd "$WEB_DIR"
node -e "require('./database.js').initDatabase().then(() => console.log('Database initialized')).catch(e => console.error(e))"
print_success "Database initialized"

print_header "Step 11: Generate Initial Configuration"

# Create initial README for operations
cat > "$APP_DIR/SETUP_COMPLETE.txt" << EOF
╔════════════════════════════════════════════════════════════════╗
║  Unfiltered Bytzz - Production Setup Complete
║  Installation Date: $(date)
║  Author: Glen Zilla
║  Telegram: @unfilteredg
╚════════════════════════════════════════════════════════════════╝

✓ Installation completed successfully!

IMPORTANT INFORMATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Application Directories:
  Bot Application:  $BOT_DIR
  Web Platform:     $WEB_DIR
  Data Directory:   $DATA_DIR
  Log Directory:    $LOG_DIR
  Domain:           $DOMAIN

Services:
  Bot Service:      unfiltered-bytzz-bot
  Web Service:      unfiltered-bytzz-web

Useful Commands:
  Start bot:        systemctl start unfiltered-bytzz-bot
  Stop bot:         systemctl stop unfiltered-bytzz-bot
  Restart bot:      systemctl restart unfiltered-bytzz-bot
  Bot logs:         journalctl -u unfiltered-bytzz-bot -f

  Start web:        systemctl start unfiltered-bytzz-web
  Stop web:         systemctl stop unfiltered-bytzz-web
  Restart web:      systemctl restart unfiltered-bytzz-web
  Web logs:         journalctl -u unfiltered-bytzz-web -f

CLI Command:
  Generate voucher: ubot voucher admin
  List vouchers:    ubot list admin
  Validate voucher: ubot validate UBOT-XXXX-XXXX-XXXX

Website:
  Access: https://$DOMAIN
  Admin Key: Check .env file in $WEB_DIR

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Generate your first voucher:
   ubot voucher admin 1

2. Test the web platform:
   https://$DOMAIN

3. Monitor services:
   systemctl status unfiltered-bytzz-bot
   systemctl status unfiltered-bytzz-web

4. Check logs:
   journalctl -u unfiltered-bytzz-bot -f
   journalctl -u unfiltered-bytzz-web -f

5. Configure bot settings in:
   $BOT_DIR/config.js
   $BOT_DIR/settings.js

For support, contact Glen Zilla on Telegram: @unfilteredg

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

print_success "Setup information saved to $APP_DIR/SETUP_COMPLETE.txt"

print_header "Step 12: Start Services"

print_info "Starting services..."
systemctl start unfiltered-bytzz-web
sleep 2
systemctl start unfiltered-bytzz-bot
sleep 2

# Check service status
echo ""
systemctl status unfiltered-bytzz-web --no-pager
echo ""
systemctl status unfiltered-bytzz-bot --no-pager
echo ""

print_header "Installation Summary"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Installation completed successfully!${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Key Information:${NC}"
echo -e "  Domain:         $DOMAIN"
echo -e "  Bot Directory:  $BOT_DIR"
echo -e "  Web Directory:  $WEB_DIR"
echo -e "  Data Directory: $DATA_DIR"
echo -e ""

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Generate vouchers: ${GREEN}ubot voucher admin${NC}"
echo -e "  2. Access website:    ${GREEN}https://$DOMAIN${NC}"
echo -e "  3. Check logs:        ${GREEN}journalctl -u unfiltered-bytzz-web -f${NC}"
echo -e ""

echo -e "${YELLOW}Support:${NC}"
echo -e "  Telegram: @unfilteredg"
echo -e "  Author:   Glen Zilla"
echo -e ""

# Display admin key
ADMIN_KEY=$(grep ADMIN_KEY "$WEB_DIR/.env" | cut -d '=' -f 2)
echo -e "${BLUE}⚠️  IMPORTANT: Save your admin key${NC}"
echo -e "  Admin Key: ${GREEN}$ADMIN_KEY${NC}"
echo -e ""

echo -e "${GREEN}✓ All done! Your Unfiltered Bytzz platform is ready to deploy bots!${NC}\n"
