# 🤖 Unfiltered Bytzz - WhatsApp Bot Deployment Platform

Professional WhatsApp Bot Deployment & Management System with Web Dashboard, Voucher System, and Multi-Session Support.

<div align="center"> 
  <a href="https://git.io/typing-svg"> 
    <img src="https://git.io/typing-svg"><img src="https://readme-typing-svg.demolab.com?font=Ribeye&size=50&pause=1000&color=33FF00&width=910&height=100&lines=Unfiltered+bytzz+bot;Multi+device+whatsapp+bot" alt="Typing SVG" />
  </a> 
</div>

<div align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Node.js-18+-green?style=for-the-badge" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Platform-VPS-blue?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge" alt="Status"/>
</div>

<div align="center">
  <p><strong>Author:</strong> Glen Zilla | <strong>Telegram:</strong> <a href="https://t.me/unfilteredg">@unfilteredg</a></p>
  <p><strong>Website:</strong> <a href="https://netivosolutions.top">netivosolutions.top</a></p>
</div>

---

## ✨ Features

### 🚀 Core Platform Features
- **One-Click Bot Deployment** - Deploy unlimited WhatsApp bots with a single voucher
- **Web Dashboard** - Black & white theme interface for bot management
- **QR Code & Pairing Code** - Multiple connection methods for WhatsApp linking
- **Voucher System** - Single-use deployment codes for security & monetization
- **Session Management** - Isolated sessions for each bot deployment
- **Feature Toggle** - Enable/disable 100+ bot features in real-time
- **Multi-Device Support** - Support for linked WhatsApp devices
- **CLI Tool** - Command-line interface for voucher management (`ubot` command)

### 🤖 Bot Features (100+)
- **Tag All** - Mention all group members
- **AI Chat** - AI-powered conversations
- **Sticker Maker** - Convert images to stickers
- **Text-to-Speech** - Convert text to audio
- **Anti-Link** - Block malicious links
- **Anti-BadWord** - Filter inappropriate language
- **Music Download** - Download from YouTube, Spotify, etc
- **Social Media** - Download from Instagram, TikTok, Facebook
- **Group Management** - Kick, mute, promote, demote members
- **Games** - Tic-Tac-Toe, 8-Ball, Trivia, and more
- **And 80+ more commands!**

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────┐
│    Web Dashboard (netivosolutions.top)  │
│  HTML/CSS/JS - Black & White Theme      │
└────────────────┬────────────────────────┘
                 │ HTTPS
┌────────────────▼────────────────────────┐
│   Express.js API Server (Port 3001)    │
│   - Voucher Management                 │
│   - Session Management                 │
│   - Deployment Controller               │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│   Node.js Bot Engine (Baileys)          │
│   - WhatsApp Connection                 │
│   - Message Processing (100+ commands) │
│   - Multi-Session Support              │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│   SQLite Database & Storage             │
│   - Voucher Management                 │
│   - Session Data                        │
│   - User Settings                       │
└─────────────────────────────────────────┘
```

---

## 🔐 Security Features

- **Single-Use Vouchers** - Each voucher can only be used once
- **Session Isolation** - Each bot has its own isolated environment
- **Admin-Only Generation** - Voucher generation requires admin key
- **Audit Trail** - Complete tracking of who used which voucher
- **WhatsApp Encryption** - Baileys handles credential encryption
- **HTTPS/SSL** - Secure communication over the web

---

## 💰 Monetization Model

**How it works:**

1. **Generate Vouchers** - `ubot voucher admin 10`
2. **Sell to Users** - Each voucher = $5-20 per deployment
3. **Users Deploy** - One voucher = One bot deployment
4. **You Profit** - Scalable revenue without hosting overhead

---

## 🚀 Quick Start

### For Local Development (5 minutes)

```bash
# Clone repository
git clone https://github.com/zilla5187/unfiltered-bot.git
cd unfiltered-bot

# Install dependencies
npm install
cd web && npm install && cd ..

# Terminal 1: Start web dashboard
cd web && node server.js
# Open http://localhost:3000

# Terminal 2: Start bot
node index.js
# Scan QR code with WhatsApp
```

### For Production VPS (10 minutes)

```bash
# SSH into VPS as root
ssh root@your-server-ip

# Download and run installation script
wget https://raw.githubusercontent.com/zilla5187/unfiltered-bot/main/install.sh
chmod +x install.sh
sudo ./install.sh

# The script will:
# ✓ Install all dependencies
# ✓ Setup directory structure at /var/www/netivosolutions.top
# ✓ Configure Apache & SSL
# ✓ Create systemd services
# ✓ Initialize database
# ✓ Start services

# Generate your first voucher
ubot voucher admin 1

# Access your platform
# https://netivosolutions.top
```

---

## 📱 Deploy Your First Bot

1. **Get a Voucher Code**
   ```bash
   ubot voucher admin 1
   # Output: UBOT-XXXX-XXXX-XXXX
   ```

2. **Visit the Platform**
   - Local: `http://localhost:3000`
   - Production: `https://netivosolutions.top`

3. **Follow 3-Step Deployment**
   - **Step 1:** Enter voucher code (validates & marks as used)
   - **Step 2:** Connect WhatsApp (QR code or pairing code)
   - **Step 3:** Configure bot (name, features, deploy)

4. **Bot is Live!**
   - Use dashboard to manage features
   - Bot responds to commands in WhatsApp

---

## 🛠️ CLI Commands

```bash
# Generate vouchers
ubot voucher admin              # 1 voucher
ubot vouchers generate admin 10 # 10 vouchers

# Validate vouchers
ubot validate UBOT-XXXX-XXXX-XXXX

# List vouchers
ubot list admin

# Get help
ubot help
```

---

## 📊 System Requirements

### Local Development
- Node.js 18+
- npm
- Git
- 2GB RAM

### Production VPS
- Ubuntu 20.04 LTS+
- 2GB RAM (4GB+ recommended)
- 50GB SSD storage
- Apache 2.4+
- SSL certificate support

---

## 📖 Full Documentation

For detailed information, refer to:

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[PRODUCTION_README.md](PRODUCTION_README.md)** - Complete production setup
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical deep dive
- **[SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md)** - Complete system overview

---

## 🔄 How the Voucher System Works

```
Admin: ubot voucher admin 1
          ↓
Generate: UBOT-XXXX-XXXX-XXXX
          ↓
User enters code on website
          ↓
Validate: Check if unused & not expired
          ↓
Approve: Mark as used, create session
          ↓
Deploy: Bot goes live
          ↓
Monetize: Admin keeps revenue
```

**Benefits:**
- ✓ Control deployment scale
- ✓ Monetize each deployment
- ✓ Prevent abuse
- ✓ Track usage
- ✓ One-time use per voucher

---

## 🌐 Support & Contact

- **Telegram**: [@unfilteredg](https://t.me/unfilteredg)
- **Author**: Glen Zilla
- **Website**: [netivosolutions.top](https://netivosolutions.top)
- **GitHub**: [zilla5187/unfiltered-bot](https://github.com/zilla5187/unfiltered-bot)

---

## 📝 License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

---

## 🙌 Contributions

Contributions, issues, and feature requests are welcome! Feel free to open issues or submit pull requests.

---

## 🌟 Show Your Support

If you like this project, please give it a ⭐ star on GitHub!

---

## 🚀 Deployment Options

### Option 1: Local Development
Perfect for testing and development
```bash
git clone https://github.com/zilla5187/unfiltered-bot.git
npm install
cd web && npm install && cd ..
# Run in 2 terminals: node index.js & cd web && node server.js
```

### Option 2: Production VPS
For 24/7 deployment and monetization
```bash
sudo ./install.sh
# Automated setup with Apache, SSL, systemd services
ubot voucher admin 10  # Start selling!
```

### Option 3: Docker (Coming Soon)
Easy containerized deployment

---

## 📈 Scaling & Growth

**Phase 1: MVP**
- 1 VPS, ~50 active bots, SQLite

**Phase 2: Growth**
- Multiple VPS, ~500 bots, PostgreSQL

**Phase 3: Enterprise**
- Kubernetes, ~5000+ bots, Redis caching

---

## ⚠️ Important Warning

**Note:** This bot is created for educational purposes. Using this bot may lead to your WhatsApp account being banned. Use at your own risk. The developers assume no liability for any consequences.

---

## 📜 Legal Disclaimer

- This project is not affiliated with, authorized, or endorsed by WhatsApp or Meta
- This is independent and unofficial software - Use at your own risk
- Do not spam people or use for illegal purposes
- Developers assume no liability for misuse or damage
- Always comply with WhatsApp's Terms of Service

---

## 👏 Credits

- **Baileys Library** - [@adiwajshing](https://github.com/adiwajshing/Baileys)
- **Pairing Code** - [TechGod143](https://github.com/TechGod143) & [Dgxeon](https://github.com/Dgxeon)
- **Platform Developer** - Glen Zilla ([@unfilteredg](https://t.me/unfilteredg))
- **Original Bot** - [Professor](https://github.com/mruniquehacker)

---

<div align="center">
  <p><strong>Made with ❤️ by Glen Zilla</strong></p>
  <p>© 2024 Unfiltered Bytzz. All rights reserved.</p>
  <p>
    <a href="https://t.me/unfilteredg">Telegram</a> • 
    <a href="https://netivosolutions.top">Website</a> • 
    <a href="https://github.com/zilla5187/unfiltered-bot">GitHub</a>
  </p>
</div>
