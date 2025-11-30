const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const { open } = require('sqlite');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '../data/bot_platform.db');

// Ensure data directory exists
if (!fs.existsSync(path.dirname(DB_PATH))) {
    fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
}

let db = null;

async function initDatabase() {
    db = await open({
        filename: DB_PATH,
        driver: sqlite3.Database
    });

    // Enable foreign keys
    await db.exec('PRAGMA foreign_keys = ON');

    // Create tables
    await db.exec(`
        CREATE TABLE IF NOT EXISTS users (
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

        CREATE TABLE IF NOT EXISTS vouchers (
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

        CREATE TABLE IF NOT EXISTS sessions (
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

        CREATE TABLE IF NOT EXISTS features (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            feature_name TEXT NOT NULL,
            is_enabled BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (session_id) REFERENCES sessions(id)
        );

        CREATE TABLE IF NOT EXISTS deployments (
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

        CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_vouchers_code ON vouchers(code);
        CREATE INDEX IF NOT EXISTS idx_deployments_session ON deployments(session_id);
    `);

    return db;
}

function getDatabase() {
    return db;
}

async function closeDatabase() {
    if (db) {
        await db.close();
    }
}

module.exports = {
    initDatabase,
    getDatabase,
    closeDatabase
};
