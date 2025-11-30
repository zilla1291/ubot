const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getDatabase } = require('../database');
const VoucherManager = require('../voucherManager');
const QRCode = require('qrcode');
const chalk = require('chalk');

// Validate voucher and create session
router.post('/validate-voucher', async (req, res) => {
    try {
        const { code, userId } = req.body;

        if (!code || !userId) {
            return res.status(400).json({
                success: false,
                error: 'Code and userId are required'
            });
        }

        // Use the voucher
        const voucherResult = await VoucherManager.useVoucher(code, userId);

        if (!voucherResult.success) {
            return res.status(400).json(voucherResult);
        }

        // Create a new session for the user
        const sessionId = uuidv4();
        const db = getDatabase();

        await db.run(
            `INSERT INTO sessions (id, user_id, voucher_code, status) 
             VALUES (?, ?, ?, 'pairing')`,
            [sessionId, userId, code]
        );

        res.json({
            success: true,
            sessionId,
            message: 'Voucher validated. Session created.'
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error validating voucher: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Generate QR Code for session
router.post('/generate-qr', async (req, res) => {
    try {
        const { sessionId } = req.body;

        if (!sessionId) {
            return res.status(400).json({
                success: false,
                error: 'Session ID is required'
            });
        }

        // Simulate QR code data (in production, this would come from Baileys)
        const qrData = JSON.stringify({
            sessionId,
            timestamp: Date.now(),
            domain: 'netivosolutions.top'
        });

        const qrCode = await QRCode.toDataURL(qrData, {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            quality: 0.95,
            margin: 1,
            width: 300
        });

        // Update session with QR code
        const db = getDatabase();
        await db.run(
            `UPDATE sessions SET qr_code = ? WHERE id = ?`,
            [qrCode, sessionId]
        );

        res.json({
            success: true,
            sessionId,
            qrCode,
            message: 'QR Code generated successfully'
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error generating QR: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get pairing code (paired by phone number)
router.post('/get-pairing-code', async (req, res) => {
    try {
        const { sessionId, phoneNumber } = req.body;

        if (!sessionId || !phoneNumber) {
            return res.status(400).json({
                success: false,
                error: 'Session ID and phone number are required'
            });
        }

        // Validate phone number format
        if (!/^\d{10,15}$/.test(phoneNumber.replace(/\D/g, ''))) {
            return res.status(400).json({
                success: false,
                error: 'Invalid phone number format'
            });
        }

        // Generate a mock pairing code (in production, use Baileys)
        const pairingCode = Math.random().toString().slice(2, 8);

        const db = getDatabase();
        await db.run(
            `UPDATE sessions 
             SET pairing_code = ?, status = 'pairing_requested' 
             WHERE id = ?`,
            [pairingCode, sessionId]
        );

        console.log(chalk.green(`✓ Pairing code generated for session ${sessionId}: ${pairingCode}`));

        res.json({
            success: true,
            sessionId,
            pairingCode,
            instructions: `Enter this code in your WhatsApp linked devices settings. Code expires in 5 minutes.`,
            message: 'Pairing code generated successfully'
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error getting pairing code: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get session details
router.get('/session/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const db = getDatabase();

        const session = await db.get(
            `SELECT * FROM sessions WHERE id = ?`,
            [sessionId]
        );

        if (!session) {
            return res.status(404).json({
                success: false,
                error: 'Session not found'
            });
        }

        // Parse features JSON
        if (session.features) {
            session.features = JSON.parse(session.features);
        }

        res.json({
            success: true,
            session
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error getting session: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Deploy bot for session
router.post('/deploy', async (req, res) => {
    try {
        const { sessionId, botName, features } = req.body;

        if (!sessionId || !botName) {
            return res.status(400).json({
                success: false,
                error: 'Session ID and bot name are required'
            });
        }

        const db = getDatabase();
        const deploymentId = uuidv4();

        // Check if session exists and is paired
        const session = await db.get(
            `SELECT * FROM sessions WHERE id = ?`,
            [sessionId]
        );

        if (!session) {
            return res.status(404).json({
                success: false,
                error: 'Session not found'
            });
        }

        // Create deployment record
        await db.run(
            `INSERT INTO deployments (id, session_id, user_id, deployment_type, status, logs)
             VALUES (?, ?, ?, 'vps', 'in_progress', ?)`,
            [deploymentId, sessionId, session.user_id, 'Starting deployment...']
        );

        // Update session
        await db.run(
            `UPDATE sessions 
             SET bot_name = ?, deployment_status = 'in_progress', features = ?, status = 'deployed'
             WHERE id = ?`,
            [botName, JSON.stringify(features || {}), sessionId]
        );

        console.log(chalk.green(`✓ Deployment started for session ${sessionId}`));

        res.json({
            success: true,
            deploymentId,
            sessionId,
            message: 'Deployment started successfully',
            status: 'in_progress'
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error deploying bot: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Toggle feature on/off
router.post('/toggle-feature', async (req, res) => {
    try {
        const { sessionId, featureName, enabled } = req.body;

        if (!sessionId || !featureName || enabled === undefined) {
            return res.status(400).json({
                success: false,
                error: 'Session ID, feature name, and enabled status are required'
            });
        }

        const db = getDatabase();
        const featureId = uuidv4();

        // Check if feature already exists for this session
        const existingFeature = await db.get(
            `SELECT id FROM features 
             WHERE session_id = ? AND feature_name = ?`,
            [sessionId, featureName]
        );

        if (existingFeature) {
            await db.run(
                `UPDATE features SET is_enabled = ? WHERE id = ?`,
                [enabled ? 1 : 0, existingFeature.id]
            );
        } else {
            await db.run(
                `INSERT INTO features (id, session_id, feature_name, is_enabled)
                 VALUES (?, ?, ?, ?)`,
                [featureId, sessionId, featureName, enabled ? 1 : 0]
            );
        }

        console.log(chalk.blue(`✓ Feature ${featureName} toggled to ${enabled}`));

        res.json({
            success: true,
            sessionId,
            featureName,
            enabled,
            message: `Feature ${featureName} ${enabled ? 'enabled' : 'disabled'}`
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error toggling feature: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get session features
router.get('/session/:sessionId/features', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const db = getDatabase();

        const features = await db.all(
            `SELECT feature_name, is_enabled FROM features 
             WHERE session_id = ?
             ORDER BY feature_name ASC`,
            [sessionId]
        );

        res.json({
            success: true,
            sessionId,
            features
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error getting features: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;
