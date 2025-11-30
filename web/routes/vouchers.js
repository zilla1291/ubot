const express = require('express');
const router = express.Router();
const VoucherManager = require('../voucherManager');
const { getDatabase } = require('../database');
const chalk = require('chalk');

// Get all vouchers (admin)
router.get('/all', async (req, res) => {
    try {
        const db = getDatabase();
        const vouchers = await db.all(
            `SELECT v.*, u.username as owner_username 
             FROM vouchers v
             LEFT JOIN users u ON v.owner_id = u.id
             ORDER BY v.created_at DESC`
        );

        res.json({
            success: true,
            total: vouchers.length,
            vouchers
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error getting vouchers: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get vouchers by owner
router.get('/owner/:ownerId', async (req, res) => {
    try {
        const { ownerId } = req.params;
        const result = await VoucherManager.listVouchersByOwner(ownerId);

        if (!result.success) {
            return res.status(400).json(result);
        }

        res.json(result);
    } catch (error) {
        console.error(chalk.red(`✗ Error getting owner vouchers: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Check if voucher is valid
router.post('/check', async (req, res) => {
    try {
        const { code } = req.body;

        if (!code) {
            return res.status(400).json({
                success: false,
                error: 'Voucher code is required'
            });
        }

        const result = await VoucherManager.getVoucherDetails(code);

        if (!result.success) {
            return res.status(400).json(result);
        }

        const voucher = result.voucher;
        const isExpired = new Date(voucher.expires_at) < new Date();
        const isValid = !voucher.is_used && !isExpired;

        res.json({
            success: true,
            code,
            isValid,
            isUsed: !!voucher.is_used,
            isExpired,
            expiresAt: voucher.expires_at,
            createdAt: voucher.created_at
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error checking voucher: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;
