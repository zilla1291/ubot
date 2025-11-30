# 🔷 Unfiltered Bytzz - System Architecture & Technical Documentation

**Author**: Glen Zilla  
**Contact**: [@unfilteredg](https://t.me/unfilteredg)  
**Website**: netivosolutions.top  
**Last Updated**: 2024

---

## 📚 Table of Contents

1. [System Architecture](#system-architecture)
2. [Voucher System](#voucher-system)
3. [Deployment Flow](#deployment-flow)
4. [Session Management](#session-management)
5. [Security Model](#security-model)
6. [API Reference](#api-reference)
7. [Database Design](#database-design)
8. [Scalability & Performance](#scalability--performance)

---

## System Architecture

### Overview

The Unfiltered Bytzz platform consists of three main components:

```
┌─────────────────────────────────────────────────────────────┐
│                     Web Browser (Frontend)                   │
│              (HTML/CSS/JS - Black & White Theme)             │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/HTTPS
┌────────────────────────▼────────────────────────────────────┐
│                   Apache Web Server                          │
│         (Reverse Proxy to Node.js Applications)              │
├─────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────────┐│
│ │            Web Platform (Express.js)                    ││
│ │  ├─ REST API Server (Port 3001)                        ││
│ │  ├─ SQLite Database Manager                            ││
│ │  ├─ Voucher Management System                          ││
│ │  ├─ Session Management                                 ││
│ │  └─ Deployment Controller                              ││
│ └──────────────────────────────────────────────────────────┘│
│ ┌──────────────────────────────────────────────────────────┐│
│ │         Bot Application (Node.js)                       ││
│ │  ├─ Baileys Library Integration                        ││
│ │  ├─ WhatsApp Connection Manager                        ││
│ │  ├─ Command Handler (100+ commands)                    ││
│ │  ├─ Multi-Session Support                              ││
│ │  └─ Message Processing Engine                          ││
│ └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼─────┐  ┌─────▼──────┐  ┌────▼──────┐
    │ SQLite   │  │ WhatsApp   │  │ Filesystem│
    │ Database │  │    API     │  │  Storage  │
    └──────────┘  └────────────┘  └───────────┘
```

### Component Details

#### 1. **Frontend Web Dashboard**
- **Technology**: HTML5, CSS3, JavaScript (Vanilla)
- **Theme**: Black & White (Minimalist, Professional)
- **Features**:
  - Voucher validation interface
  - WhatsApp pairing (QR & Code)
  - Bot configuration
  - Session management
  - Feature toggles
  - Real-time deployment status

#### 2. **Web Platform Backend**
- **Framework**: Express.js
- **Port**: 3001 (Behind Apache Reverse Proxy)
- **Responsibilities**:
  - REST API endpoints
  - Voucher validation & tracking
  - Session creation & management
  - Feature toggle storage
  - Deployment orchestration
  - Database operations

#### 3. **Bot Application**
- **Framework**: Node.js + Baileys
- **Purpose**: WhatsApp bot core functionality
- **Capabilities**:
  - Multi-device WhatsApp connection
  - Message handling & processing
  - Command execution
  - Media processing
  - Group management

#### 4. **Data Storage**
- **Database**: SQLite3
- **Location**: `/var/lib/unfiltered-bytzz/bot_platform.db`
- **Backup**: Regular automated backups

---

## Voucher System

### How Vouchers Work

```
┌─────────────────────────────────────────────────────┐
│ Voucher Generation (Admin Only)                     │
│ Command: ubot voucher admin 1                       │
│ Output: UBOT-XXXX-XXXX-XXXX                         │
└──────────────────┬──────────────────────────────────┘
                   │ Stored in Database
                   ▼
┌─────────────────────────────────────────────────────┐
│ Voucher Storage & Tracking                          │
│ - Code (Unique)                                     │
│ - Owner ID (Who created)                            │
│ - Status (Unused/Used)                              │
│ - Expiration Date (30 days default)                 │
│ - Used By (User ID)                                 │
│ - Used At (Timestamp)                               │
└──────────────────┬──────────────────────────────────┘
                   │ User enters code on website
                   ▼
┌─────────────────────────────────────────────────────┐
│ Voucher Validation Process                          │
│ 1. Check if code exists                             │
│ 2. Check if already used (is_used = false)          │
│ 3. Check expiration (expires_at > now)              │
│ 4. If valid, mark as used (is_used = true)          │
│ 5. Record used_by and used_at                       │
└──────────────────┬──────────────────────────────────┘
                   │ If valid
                   ▼
┌─────────────────────────────────────────────────────┐
│ Create User Session & Bot Deployment                │
│ - Generate Session ID                               │
│ - Link voucher to session                           │
│ - Initialize bot deployment process                 │
└─────────────────────────────────────────────────────┘
```

### Voucher Code Generation

```javascript
// Format: UBOT-{timestamp}-{random}-{random}
// Example: UBOT-K8H5-A3B2-C1D4

// Properties:
// - Globally unique (UUID-based)
// - Human readable format
// - Cannot be guessed or predicted
// - Timestamp included for reference
```

### Voucher Lifecycle

```
GENERATED → VALID → USED (EXPIRED) OR USED (ACTIVE) → INVALID
  ▲        ▲          ▲
  │        │          │
  │        │      is_used = true
  │    Unexpired &  used_at = timestamp
  │    not used
  │
 New voucher
 expires_at = now + 30 days
```

---

## Deployment Flow

### Complete Deployment Process

```
1. USER SUBMITS DEPLOYMENT REQUEST
   ├─ Enters voucher code
   ├─ Selects WhatsApp connection method
   ├─ Chooses bot features
   └─ Clicks "Deploy"
         │
         ▼
2. VOUCHER VALIDATION
   ├─ Check voucher exists
   ├─ Check not used
   ├─ Check not expired
   └─ Mark as USED
         │
         ▼
3. SESSION CREATION
   ├─ Generate Session ID (UUID)
   ├─ Create database record
   ├─ Link voucher to session
   └─ Set status = 'pairing'
         │
         ▼
4. WHATSAPP CONNECTION
   ├─ Option A: Generate QR Code
   │  └─ User scans with Linked Devices
   │
   └─ Option B: Generate Pairing Code
      ├─ Ask for phone number
      └─ User enters code in WhatsApp
         │
         ▼
5. SUCCESSFUL CONNECTION
   ├─ Update session status = 'paired'
   ├─ Store WhatsApp credentials
   └─ Generate QR for future reference
         │
         ▼
6. BOT DEPLOYMENT
   ├─ Create bot instance
   ├─ Configure enabled features
   ├─ Store feature toggles in database
   ├─ Start bot service
   └─ Set deployment_status = 'deployed'
         │
         ▼
7. ACTIVE & MANAGING
   ├─ User can toggle features
   ├─ Monitor bot activity
   ├─ View deployment logs
   └─ Manage bot from dashboard
```

### Deployment State Machine

```
                      ┌──────────────┐
                      │   CREATED    │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │  PAIRING     │ ◄─── Waiting for WhatsApp
                      └──────┬───────┘
                             │
                    (User scans/enters code)
                             │
                             ▼
                      ┌──────────────┐
                      │  PAIRED      │ ◄─── Connected to WhatsApp
                      └──────┬───────┘
                             │
                    (Start deployment)
                             │
                             ▼
                      ┌──────────────┐
                      │ DEPLOYING    │ ◄─── Setting up services
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │  DEPLOYED    │ ◄─── Bot is active
                      └──────┬───────┘
                             │
                    (Optional: Pause/Delete)
                             │
                             ▼
                      ┌──────────────┐
                      │  STOPPED     │ ◄─── Bot paused
                      └──────────────┘
```

---

## Session Management

### Session Structure

```javascript
{
  id: "uuid",                    // Unique session ID
  user_id: "user_uuid",          // User who owns session
  voucher_code: "UBOT-...",      // Linked voucher
  bot_name: "My Bot",            // Bot display name
  status: "deployed",            // pairing|paired|deploying|deployed
  deployment_status: "active",   // pending|in_progress|active|failed
  qr_code: "data:image/...",     // QR code for connection
  pairing_code: "123456",        // 6-digit pairing code
  features: {                    // Enabled features
    ai: true,
    tagall: true,
    sticker: true,
    tts: false,
    // ... more features
  },
  created_at: "2024-01-01T...",  // Creation timestamp
  updated_at: "2024-01-01T...",  // Last update
  deployed_at: "2024-01-01T...", // Deployment time
  server_path: "/opt/bot-uuid"   // Bot instance path
}
```

### Session Isolation

Each session is completely isolated:

```
Session 1 (User A)          Session 2 (User B)
├─ WhatsApp: +1234567890   ├─ WhatsApp: +1987654321
├─ Features: AI, TagAll    ├─ Features: AI, Sticker
├─ Bot Name: Bot-A         ├─ Bot Name: Bot-B
├─ Data: /opt/bot-uuid1    ├─ Data: /opt/bot-uuid2
└─ Process ID: 1234        └─ Process ID: 5678

⚠️  Cannot:
    - Access other session's WhatsApp
    - Modify other session's features
    - Share database records
    - Mix message handlers
```

---

## Security Model

### Multi-Layer Security

```
Layer 1: Access Control
├─ Voucher-based deployment (single-use)
├─ User authentication (planned v2)
└─ Session-level permissions

Layer 2: Data Protection
├─ SQLite database
├─ Environment variables for secrets
├─ Encrypted WhatsApp credentials (Baileys)
└─ Secure communication (HTTPS/SSL)

Layer 3: Session Isolation
├─ Unique session IDs
├─ User ownership tracking
├─ Feature-level access control
└─ Isolated process spaces

Layer 4: Audit & Monitoring
├─ Voucher usage tracking
├─ Session lifecycle logging
├─ Deployment history
└─ Error tracking
```

### Voucher Security

```
Generation:
├─ Admin key required
├─ Random code generation
├─ Unique per deployment
└─ Expiration enforcement

Usage:
├─ Check validity before use
├─ Mark immediately as used
├─ Record user & timestamp
├─ Prevent reuse
└─ Audit trail
```

### WhatsApp Credential Security

```
Baileys Handles:
├─ Encryption of session data
├─ Secure credential storage
├─ Device registration
└─ Automatic re-authentication

Platform Ensures:
├─ Isolated per session
├─ No credential sharing
├─ Secure file permissions
└─ Regular backups
```

---

## API Reference

### Core Endpoints

#### 1. Validate Voucher
```
POST /api/deployment/validate-voucher
Content-Type: application/json

Request:
{
  "code": "UBOT-XXXX-XXXX-XXXX",
  "userId": "user_abc123"
}

Response (Success):
{
  "success": true,
  "sessionId": "session-uuid",
  "message": "Voucher validated. Session created."
}

Response (Error):
{
  "success": false,
  "error": "Voucher already used" | "Voucher expired" | "Voucher not found"
}
```

#### 2. Generate QR Code
```
POST /api/deployment/generate-qr
Content-Type: application/json

Request:
{
  "sessionId": "session-uuid"
}

Response:
{
  "success": true,
  "sessionId": "session-uuid",
  "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA...",
  "message": "QR Code generated successfully"
}
```

#### 3. Get Pairing Code
```
POST /api/deployment/get-pairing-code
Content-Type: application/json

Request:
{
  "sessionId": "session-uuid",
  "phoneNumber": "+1234567890"
}

Response:
{
  "success": true,
  "sessionId": "session-uuid",
  "pairingCode": "123456",
  "instructions": "Enter this code in your WhatsApp linked devices settings...",
  "message": "Pairing code generated successfully"
}
```

#### 4. Deploy Bot
```
POST /api/deployment/deploy
Content-Type: application/json

Request:
{
  "sessionId": "session-uuid",
  "botName": "My Awesome Bot",
  "features": {
    "ai": true,
    "tagall": true,
    "sticker": true,
    "tts": false,
    "antilink": true
  }
}

Response:
{
  "success": true,
  "deploymentId": "deployment-uuid",
  "sessionId": "session-uuid",
  "message": "Deployment started successfully",
  "status": "in_progress"
}
```

#### 5. Get Session
```
GET /api/deployment/session/:sessionId

Response:
{
  "success": true,
  "session": {
    "id": "session-uuid",
    "bot_name": "My Bot",
    "status": "deployed",
    "deployment_status": "active",
    "features": {...},
    "created_at": "2024-01-01T...",
    "deployed_at": "2024-01-01T..."
  }
}
```

#### 6. Get Session Features
```
GET /api/deployment/session/:sessionId/features

Response:
{
  "success": true,
  "sessionId": "session-uuid",
  "features": [
    {"feature_name": "ai", "is_enabled": true},
    {"feature_name": "tagall", "is_enabled": true},
    {"feature_name": "sticker", "is_enabled": true}
  ]
}
```

#### 7. Toggle Feature
```
POST /api/deployment/toggle-feature
Content-Type: application/json

Request:
{
  "sessionId": "session-uuid",
  "featureName": "ai",
  "enabled": true
}

Response:
{
  "success": true,
  "sessionId": "session-uuid",
  "featureName": "ai",
  "enabled": true,
  "message": "Feature ai enabled"
}
```

#### 8. Check Voucher
```
POST /api/vouchers/check
Content-Type: application/json

Request:
{
  "code": "UBOT-XXXX-XXXX-XXXX"
}

Response:
{
  "success": true,
  "code": "UBOT-XXXX-XXXX-XXXX",
  "isValid": true,
  "isUsed": false,
  "isExpired": false,
  "expiresAt": "2024-02-01T...",
  "createdAt": "2024-01-01T..."
}
```

---

## Database Design

### Schema Overview

```sql
-- Users Table (Future: for user authentication)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  whatsapp_connected BOOLEAN DEFAULT 0,
  session_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Vouchers Table (Core: Voucher management)
CREATE TABLE vouchers (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  owner_id TEXT NOT NULL,
  used_by_id TEXT,
  is_used BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  used_at DATETIME,
  expires_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES users(id),
  FOREIGN KEY (used_by_id) REFERENCES users(id)
);

-- Sessions Table (Core: Deployment sessions)
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  voucher_code TEXT NOT NULL,
  bot_name TEXT,
  status TEXT DEFAULT 'pairing',
  qr_code TEXT,
  pairing_code TEXT,
  deployment_status TEXT DEFAULT 'pending',
  server_path TEXT,
  features JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  deployed_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (voucher_code) REFERENCES vouchers(code)
);

-- Features Table (Core: Feature toggles)
CREATE TABLE features (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  feature_name TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Deployments Table (Tracking: Deployment history)
CREATE TABLE deployments (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  deployment_type TEXT,
  deployment_path TEXT,
  status TEXT DEFAULT 'pending',
  logs TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  FOREIGN KEY (session_id) REFERENCES sessions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes for performance
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_vouchers_code ON vouchers(code);
CREATE INDEX idx_deployments_session ON deployments(session_id);
```

### Data Relationships

```
users
  ├─ 1 ──┬─────── N vouchers (created)
  │      └─────── N vouchers (used by)
  ├─ 1 ──────── N sessions
  └─ 1 ──────── N deployments

vouchers
  ├─ N ──────── 1 user (owner)
  ├─ N ──────── 1 user (used_by)
  └─ 1 ──────── N sessions

sessions
  ├─ N ──────── 1 user
  ├─ N ──────── 1 voucher
  ├─ 1 ──────── N features
  └─ 1 ──────── N deployments

features
  └─ N ──────── 1 session

deployments
  ├─ N ──────── 1 session
  └─ N ──────── 1 user
```

---

## Scalability & Performance

### Current Architecture Capacity

```
Single VPS (2GB RAM):
├─ ~50 active bot sessions
├─ ~100 concurrent dashboard users
├─ ~1000 QPS (queries per second)
└─ Database: ~100K records

Recommendations:
├─ Monitor CPU & Memory
├─ Archive old deployments
├─ Optimize database queries
└─ Use caching for frequent queries
```

### Scaling Strategies

#### Horizontal Scaling
```
Load Balancer
├─ API Server 1 (Express)
├─ API Server 2 (Express)
└─ API Server N (Express)
     └─ Shared Database (PostgreSQL)
```

#### Vertical Scaling
```
Upgrade VPS:
├─ RAM: 2GB → 4GB → 8GB → 16GB
├─ CPU: 2 cores → 4 cores → 8 cores
├─ Storage: 50GB → 100GB → 500GB
└─ Bandwidth: Standard → Dedicated
```

#### Database Optimization
```
Current: SQLite (Single-threaded)
├─ Good for: Development, Small-scale
├─ Limitation: ~100 concurrent connections

Future: PostgreSQL (Multi-threaded)
├─ Better for: Large-scale, Production
├─ Features: Replication, Clustering, ACID
└─ Scalability: Millions of records
```

### Performance Metrics

```
Target Response Times:
├─ Voucher validation: < 100ms
├─ Session creation: < 200ms
├─ QR code generation: < 500ms
├─ Deployment start: < 1000ms
└─ Dashboard load: < 2000ms

Database Performance:
├─ Concurrent connections: 10-50
├─ Query response: < 50ms
├─ Insert/Update: < 100ms
└─ Search/Select: < 200ms
```

---

## Future Enhancements

### v2.0 Planned Features
- [ ] User authentication (OAuth2)
- [ ] Payment integration
- [ ] PostgreSQL support
- [ ] WebSocket real-time updates
- [ ] Bot analytics dashboard
- [ ] Advanced feature permissions
- [ ] Multi-region deployment
- [ ] API rate limiting
- [ ] Webhook integrations
- [ ] Bot marketplace

### v3.0 Vision
- [ ] Microservices architecture
- [ ] Kubernetes deployment
- [ ] AI-powered bot optimization
- [ ] Custom command builder UI
- [ ] Bot template library
- [ ] Community marketplace
- [ ] Enterprise support tier

---

## Troubleshooting

### Common Issues

#### Issue: Voucher marked as used but deployment failed
**Solution**: 
- Check database integrity
- Verify deployment logs
- Contact admin to recreate session

#### Issue: QR code won't scan
**Solution**:
- Ensure proper internet connection
- Try pairing code instead
- Clear WhatsApp cache
- Update WhatsApp app

#### Issue: Bot stops responding
**Solution**:
- Check service status: `systemctl status unfiltered-bytzz-bot`
- View logs: `journalctl -u unfiltered-bytzz-bot -f`
- Restart service: `systemctl restart unfiltered-bytzz-bot`

#### Issue: Database locked error
**Solution**:
- Close other database connections
- Restart web service: `systemctl restart unfiltered-bytzz-web`
- Check file permissions on database

---

## Conclusion

The Unfiltered Bytzz platform is designed to be:
- **User-friendly**: Simple web interface for bot deployment
- **Secure**: Multi-layer security with voucher system
- **Scalable**: Designed to grow from 1 to 1000+ bots
- **Maintainable**: Clear architecture and documentation
- **Extensible**: Modular design for future features

For questions or support, contact Glen Zilla on Telegram: [@unfilteredg](https://t.me/unfilteredg)

---

**Created by**: Glen Zilla  
**Last Updated**: 2024  
**License**: MIT
