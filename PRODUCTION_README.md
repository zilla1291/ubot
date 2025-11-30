# 🤖 Unfiltered Bytzz - WhatsApp Bot Deployment Platform

> Professional WhatsApp Bot Deployment & Management Platform with Web Dashboard, Voucher System, and Multi-Session Support.

<div align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Node.js-18+-green?style=for-the-badge" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Platform-VPS%2FCloud-blue?style=for-the-badge" alt="Platform"/>
</div>

---

## ✨ Features

### 🚀 Core Features
- **WhatsApp Bot Creation** - Deploy multiple WhatsApp bots using Baileys library
- **Web Dashboard** - Beautiful black & white theme interface for bot management
- **QR Code & Pairing Code** - Multiple connection methods for WhatsApp linking
- **Voucher System** - Single-use vouchers for secure bot deployment access
- **Session Management** - Isolated sessions for each bot deployment
- **Feature Toggle** - Enable/disable bot features from dashboard
- **Multi-Device Support** - Support for linked WhatsApp devices

### 🔒 Security Features
- **Single-Use Vouchers** - Each voucher can only be used once
- **Session Isolation** - Each user gets their own isolated session
- **Admin Control** - Voucher generation via CLI with admin authentication
- **Secure Storage** - SQLite database with encrypted credentials

### 📊 Bot Features
- **Tag All Members** - Mention all group members at once
- **Anti-Link Detection** - Prevent malicious links in groups
- **Anti-BadWord** - Filter inappropriate language
- **Sticker Maker** - Convert images to WhatsApp stickers
- **Text-to-Speech** - Convert text to audio messages
- **AI Chat** - Integrated AI chatbot capabilities
- **Music Download** - Download from various platforms
- **And 100+ more commands!**

---

## 📋 System Requirements

### For Local Development
- Node.js 18+ 
- npm or yarn
- SQLite3
- FFmpeg (for media processing)
- Git

### For Production VPS
- Ubuntu 20.04 LTS or newer
- Minimum 2GB RAM (4GB+ recommended)
- 50GB SSD storage
- Apache 2.4+
- Node.js 18+
- SSL certificate support

---

## 🚀 Quick Start - Local Development

### 1. Clone the Repository

```bash
git clone https://github.com/zilla5187/unfiltered-bot.git
cd unfiltered-bot
```

### 2. Install Dependencies

```bash
# Install bot dependencies
npm install

# Install web platform dependencies
cd web
npm install
cd ..
```

### 3. Start the Bot

```bash
# Terminal 1: Start the bot
node index.js

# Scan the QR code with WhatsApp
```

### 4. Start the Web Platform

```bash
# Terminal 2: Start the web server
cd web
node server.js

# Open http://localhost:3000
```

### 5. Generate Your First Voucher

```bash
node ubot.js voucher admin 1
```

---

## 🔧 Production Deployment Guide

### Step 1: Prepare Your VPS

```bash
# SSH into your VPS as root
ssh root@your-server-ip
```

### Step 2: Download & Run Installation Script

```bash
cd /tmp
wget https://raw.githubusercontent.com/zilla5187/unfiltered-bot/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

The script will:
- ✓ Update system and install all dependencies
- ✓ Create directory structure at `/var/www/netivosolutions.top`
- ✓ Clone the bot repository
- ✓ Setup web platform and database
- ✓ Configure Apache virtual hosts
- ✓ Setup SSL certificate with Let's Encrypt
- ✓ Create systemd services for auto-restart
- ✓ Initialize database
- ✓ Start all services

### Step 3: Verify Installation

```bash
# Check web service
systemctl status unfiltered-bytzz-web

# Check bot service
systemctl status unfiltered-bytzz-bot

# View logs
journalctl -u unfiltered-bytzz-web -f
```

### Step 4: Access Your Platform

Open your browser and navigate to:
```
https://netivosolutions.top
```

---

## 📱 Using the Web Dashboard

### Step 1: Get a Voucher Code

As admin, generate vouchers using CLI:
```bash
ubot voucher admin 1
# Output: UBOT-XXXX-XXXX-XXXX
```

### Step 2: Deploy a Bot

1. Visit `https://netivosolutions.top`
2. Click "Deploy"
3. Enter voucher code in Step 1
4. Choose WhatsApp connection method (QR or Pairing Code) in Step 2
5. Configure bot name and features in Step 3
6. Click "Deploy Bot"

### Step 3: Manage Your Bot

1. Go to "Manage" section
2. Select your bot session
3. Toggle features on/off
4. Monitor deployment status

---

## 🛠️ CLI Commands

### Generate Vouchers

```bash
# Generate single voucher
ubot voucher admin

# Generate multiple vouchers
ubot vouchers generate admin 10

# Generate with custom expiration (30 days)
ubot voucher admin 1 30
```

### Validate Vouchers

```bash
# Check if voucher is valid
ubot validate UBOT-XXXX-XXXX-XXXX

# List all vouchers for owner
ubot list admin
```

### Help

```bash
ubot help
```

---

## 📁 Directory Structure

```
unfiltered-bot/
├── index.js                 # Main bot entry point
├── config.js               # Configuration
├── settings.js             # Settings
├── ubot.js                 # CLI tool
├── install.sh              # Installation script
├── commands/               # Bot commands (100+)
├── lib/                    # Utilities and helpers
├── data/                   # Data storage
│   ├── bot_platform.db    # Database
│   ├── sessions/          # WhatsApp sessions
│   └── *.json             # Config files
└── web/                   # Web platform
    ├── server.js          # Express server
    ├── database.js        # Database manager
    ├── voucherManager.js  # Voucher system
    ├── routes/            # API routes
    └── public/            # Frontend (HTML/CSS/JS)
```

---

## 🗄️ Database Schema

### Users
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    phone TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    whatsapp_connected BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Vouchers
```sql
CREATE TABLE vouchers (
    id TEXT PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    owner_id TEXT NOT NULL,        -- Who created it
    used_by_id TEXT,               -- Who used it
    is_used BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    used_at DATETIME,
    expires_at DATETIME,
    FOREIGN KEY (owner_id) REFERENCES users(id),
    FOREIGN KEY (used_by_id) REFERENCES users(id)
);
```

### Sessions
```sql
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    voucher_code TEXT NOT NULL,
    bot_name TEXT,
    status TEXT DEFAULT 'pairing',
    qr_code TEXT,
    pairing_code TEXT,
    deployment_status TEXT DEFAULT 'pending',
    features JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (voucher_code) REFERENCES vouchers(code)
);
```

### Features
```sql
CREATE TABLE features (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    feature_name TEXT NOT NULL,
    is_enabled BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

---

## 🔌 API Endpoints

### Deployment APIs

#### Validate Voucher
```
POST /api/deployment/validate-voucher
Body: { "code": "UBOT-XXXX-XXXX-XXXX", "userId": "user_id" }
Response: { "success": true, "sessionId": "uuid" }
```

#### Generate QR Code
```
POST /api/deployment/generate-qr
Body: { "sessionId": "uuid" }
Response: { "success": true, "qrCode": "data:image/png;base64,..." }
```

#### Get Pairing Code
```
POST /api/deployment/get-pairing-code
Body: { "sessionId": "uuid", "phoneNumber": "+1234567890" }
Response: { "success": true, "pairingCode": "123456" }
```

#### Deploy Bot
```
POST /api/deployment/deploy
Body: { "sessionId": "uuid", "botName": "My Bot", "features": {...} }
Response: { "success": true, "deploymentId": "uuid" }
```

#### Get Session
```
GET /api/deployment/session/:sessionId
Response: { "success": true, "session": {...} }
```

#### Toggle Feature
```
POST /api/deployment/toggle-feature
Body: { "sessionId": "uuid", "featureName": "ai", "enabled": true }
Response: { "success": true }
```

### Voucher APIs

#### Check Voucher
```
POST /api/vouchers/check
Body: { "code": "UBOT-XXXX-XXXX-XXXX" }
Response: { "success": true, "isValid": true, "isUsed": false }
```

#### List Vouchers
```
GET /api/vouchers/owner/:ownerId
Response: { "success": true, "vouchers": [...] }
```

---

## 🌐 Environment Variables

Create `.env` file in the `web` directory:

```env
# Server Configuration
NODE_ENV=production
PORT=3001
ADMIN_KEY=your-secret-admin-key

# Database
DATABASE_PATH=/var/lib/unfiltered-bytzz
LOG_PATH=/var/log/unfiltered-bytzz

# Domain
DOMAIN=netivosolutions.top
```

---

## 📞 Support & Contact

- **Telegram**: [@unfilteredg](https://t.me/unfilteredg)
- **Author**: Glen Zilla
- **Website**: [netivosolutions.top](https://netivosolutions.top)

---

## 🔐 Security Considerations

### Voucher System
- Vouchers are single-use only
- Expired vouchers cannot be used
- Each voucher tracked with owner and user
- Voucher codes are randomly generated and unique

### Session Management
- Each user gets isolated session
- WhatsApp credentials stored securely
- Sessions cannot be shared between users
- Automatic cleanup of old sessions

### Authentication
- Admin operations require admin key
- API endpoints can be protected with authentication middleware
- Database credentials stored in environment variables

---

## 🛠️ Maintenance

### Backup Data
```bash
# Backup database and sessions
tar -czf backup-$(date +%Y%m%d).tar.gz /var/lib/unfiltered-bytzz/
```

### Monitor Services
```bash
# Check service status
systemctl status unfiltered-bytzz-bot
systemctl status unfiltered-bytzz-web

# View real-time logs
journalctl -u unfiltered-bytzz-bot -f
journalctl -u unfiltered-bytzz-web -f
```

### Restart Services
```bash
# Restart individual services
systemctl restart unfiltered-bytzz-bot
systemctl restart unfiltered-bytzz-web

# Restart all services
systemctl restart unfiltered-bytzz-bot unfiltered-bytzz-web
```

### Update Platform
```bash
cd /opt/unfiltered-bytzz
git pull origin main
npm install
systemctl restart unfiltered-bytzz-bot
systemctl restart unfiltered-bytzz-web
```

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**Important**: This bot is created for educational purposes. Using this bot may lead to your WhatsApp account being banned. Use at your own risk. The developers assume no liability for any consequences.

---

## 🙌 Credits

- **Baileys Library** - [@adiwajshing](https://github.com/adiwajshing/Baileys)
- **Pairing Code** - [TechGod143](https://github.com/TechGod143) & [Dgxeon](https://github.com/Dgxeon)
- **Platform Developer** - Glen Zilla ([@unfilteredg](https://t.me/unfilteredg))

---

<div align="center">
  <p>Made with ❤️ by Glen Zilla</p>
  <p>© 2024 Unfiltered Bytzz. All rights reserved.</p>
  <p>
    <a href="https://t.me/unfilteredg">Telegram</a> •
    <a href="https://netivosolutions.top">Website</a> •
    <a href="https://github.com/zilla5187/unfiltered-bot">GitHub</a>
  </p>
</div>
