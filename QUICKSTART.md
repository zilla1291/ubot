# 🚀 Unfiltered Bytzz - Quick Start Guide

**Welcome to Unfiltered Bytzz!** This guide will get you up and running in minutes.

---

## 📋 Prerequisites

Choose your deployment method:

### For Local Development
- Node.js 18+ installed
- Git installed
- 2GB RAM available

### For Production VPS
- Ubuntu 20.04 LTS+
- 2GB RAM (4GB+ recommended)
- Root or sudo access

---

## ⚡ Quick Start - Local Development (5 minutes)

### 1. Clone Repository
```bash
git clone https://github.com/zilla5187/unfiltered-bot.git
cd unfiltered-bot
```

### 2. Install Dependencies
```bash
npm install
cd web && npm install && cd ..
```

### 3. Start in Two Terminals

**Terminal 1 - Start Web Dashboard**
```bash
cd web
node server.js
# Open http://localhost:3000
```

**Terminal 2 - Start Bot**
```bash
node index.js
# Scan the QR code with WhatsApp
```

### 4. Generate a Test Voucher
```bash
node ubot.js voucher admin 1
# Output: UBOT-XXXX-XXXX-XXXX
```

### 5. Deploy Your First Bot
1. Open http://localhost:3000
2. Click "Deploy"
3. Enter the voucher code from step 4
4. Follow the on-screen instructions
5. Your bot is ready!

---

## 🌍 Production Deployment (10 minutes)

### 1. On Your VPS (as root)
```bash
cd /tmp
wget https://raw.githubusercontent.com/zilla5187/unfiltered-bot/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

The script will:
- ✓ Install all dependencies
- ✓ Setup directories
- ✓ Configure Apache & SSL
- ✓ Initialize database
- ✓ Start services

### 2. After Installation
```bash
# Generate your first voucher
ubot voucher admin 1

# Check services
systemctl status unfiltered-bytzz-web
systemctl status unfiltered-bytzz-bot

# View logs
journalctl -u unfiltered-bytzz-web -f
```

### 3. Access Your Platform
```
https://netivosolutions.top
```

---

## 📱 Deploy Your First Bot

### Step-by-Step

1. **Get Voucher Code**
   ```bash
   ubot voucher admin 1
   # Save the code: UBOT-XXXX-XXXX-XXXX
   ```

2. **Visit Dashboard**
   - Local: `http://localhost:3000`
   - Production: `https://netivosolutions.top`

3. **Click "Deploy" Tab**

4. **Step 1: Verify Voucher**
   - Enter your voucher code
   - Click "Validate Voucher"

5. **Step 2: Connect WhatsApp**
   - Choose QR Code or Pairing Code
   - Scan/Enter in WhatsApp

6. **Step 3: Configure Bot**
   - Enter bot name
   - Toggle features you want
   - Click "Deploy Bot"

7. **Done!** 🎉
   - Your bot is deployed
   - Go to "Manage" to control it

---

## 🛠️ Useful Commands

### Voucher Management
```bash
# Generate single voucher
ubot voucher admin

# Generate 10 vouchers
ubot vouchers generate admin 10

# Check voucher status
ubot validate UBOT-XXXX-XXXX-XXXX

# List all vouchers
ubot list admin

# Get help
ubot help
```

### Service Management
```bash
# Check status
systemctl status unfiltered-bytzz-web
systemctl status unfiltered-bytzz-bot

# Start/Stop/Restart
systemctl start unfiltered-bytzz-web
systemctl stop unfiltered-bytzz-bot
systemctl restart unfiltered-bytzz-web

# View logs
journalctl -u unfiltered-bytzz-web -f
journalctl -u unfiltered-bytzz-bot -f
journalctl -u unfiltered-bytzz-web --since "1 hour ago"
```

### Database
```bash
# Backup database
cp /var/lib/unfiltered-bytzz/bot_platform.db /backup/bot_platform.db.bak

# View database
sqlite3 /var/lib/unfiltered-bytzz/bot_platform.db
```

---

## 🎯 Features to Enable

When deploying a bot, you can enable:

| Feature | Description |
|---------|-------------|
| 🤖 AI | AI chatbot conversation |
| 📢 Tag All | Mention all group members |
| 🎨 Sticker | Convert images to stickers |
| 🔊 Text-to-Speech | Convert text to audio |
| 🔗 Anti-Link | Block malicious links |
| 🚫 Anti-Badword | Filter inappropriate words |
| 🎮 Games | Tic-Tac-Toe, 8-Ball, etc |
| 👥 Group Manage | Kick, mute, promote, demote |
| 🎵 Music | Download from various platforms |
| 📸 Social Media | Download from Instagram, TikTok, etc |

---

## ⚙️ Configuration

### Edit Bot Settings
```bash
# Bot name, theme, owner number
vim config.js

# API keys and global settings
vim settings.js
```

### Edit Web Configuration
```bash
# Copy example to .env
cp web/.env.example web/.env

# Edit with your values
vim web/.env
```

---

## 🔍 Troubleshooting

### Bot Won't Start
```bash
# Check logs
journalctl -u unfiltered-bytzz-bot -f

# Common fixes
systemctl restart unfiltered-bytzz-bot
rm -rf data/sessions/*  # Clear sessions
npm install --legacy-peer-deps
```

### Web Platform Not Accessible
```bash
# Check if service is running
systemctl status unfiltered-bytzz-web

# Check port 3001
netstat -tlnp | grep 3001

# Check Apache config
apache2ctl configtest

# Restart Apache
systemctl restart apache2
```

### Database Issues
```bash
# Check database file
ls -lah /var/lib/unfiltered-bytzz/

# Verify permissions
sudo chown www-data:www-data /var/lib/unfiltered-bytzz/*

# Rebuild database
cd web
node -e "require('./database.js').initDatabase()"
```

### WhatsApp Connection Issues
```bash
# Clear sessions
rm -rf data/sessions/*

# Restart bot
systemctl restart unfiltered-bytzz-bot

# Try pairing code instead of QR
# In dashboard, use "Pairing Code" option
```

---

## 📊 Monitor Your Deployment

### Dashboard
- Visit `https://netivosolutions.top`
- Go to "Manage" tab
- View all your bot sessions
- Toggle features in real-time

### Command Line
```bash
# Real-time logs
journalctl -u unfiltered-bytzz-web -f

# Bot statistics
ps aux | grep node

# Service health
systemctl status unfiltered-bytzz-web
```

### Database Queries
```bash
# Connect to database
sqlite3 /var/lib/unfiltered-bytzz/bot_platform.db

# List vouchers
SELECT code, is_used, created_at FROM vouchers;

# List sessions
SELECT bot_name, status, deployment_status FROM sessions;

# Count active bots
SELECT COUNT(*) FROM sessions WHERE status='deployed';
```

---

## 🔐 Security Best Practices

1. **Save Admin Key**
   - Store in password manager
   - Don't share in chat/email

2. **Rotate API Keys**
   - Update monthly
   - Use strong random keys

3. **Backup Regularly**
   ```bash
   tar -czf backup-$(date +%Y%m%d).tar.gz /var/lib/unfiltered-bytzz/
   ```

4. **Update System**
   ```bash
   apt-get update && apt-get upgrade -y
   ```

5. **Monitor Vouchers**
   ```bash
   ubot list admin  # Check who used vouchers
   ```

---

## 📞 Support

### Get Help
- **Telegram**: [@unfilteredg](https://t.me/unfilteredg)
- **Website**: [netivosolutions.top](https://netivosolutions.top)
- **Author**: Glen Zilla

### Common Questions

**Q: How many bots can I deploy?**
A: Unlimited! Each uses one voucher. Generate more with `ubot vouchers generate admin 10`

**Q: Can I use one voucher twice?**
A: No, each voucher is single-use for security. Once deployed, it's marked as used.

**Q: How long do vouchers last?**
A: 30 days by default. Generated vouchers expire after this period if not used.

**Q: Can I toggle features after deployment?**
A: Yes! Go to "Manage" → Select bot → Toggle features

**Q: What if deployment fails?**
A: Your voucher won't be consumed. Try again. Contact support if it persists.

**Q: How do I update the platform?**
A: `cd /opt/unfiltered-bytzz && git pull && npm install`

---

## 🎓 Next Steps

1. ✓ Deploy your first bot
2. ✓ Enable features you need
3. ✓ Test all commands
4. ✓ Customize settings
5. ✓ Share with users
6. ✓ Monitor & optimize

---

## 📄 Full Documentation

For detailed information, see:
- **PRODUCTION_README.md** - Complete setup guide
- **ARCHITECTURE.md** - Technical architecture
- **commands/README.md** - Bot commands list

---

**Ready to deploy? Start with step 1 above!** 🚀

---

*Made with ❤️ by Glen Zilla*  
*Telegram: [@unfilteredg](https://t.me/unfilteredg)*  
*Website: [netivosolutions.top](https://netivosolutions.top)*
