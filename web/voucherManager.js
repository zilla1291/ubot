const { v4: uuidv4 } = require('uuid');
const { getDatabase } = require('./database');
const crypto = require('crypto');
const chalk = require('chalk');

class VoucherManager {
    // Generate a voucher with format: UBOT-XXXX-XXXX-XXXX
    static generateVoucherCode() {
        const timestamp = Date.now().toString(36).toUpperCase();
        const random = crypto.randomBytes(6).toString('hex').toUpperCase();
        const code = `UBOT-${timestamp.slice(0, 4)}-${random.slice(0, 4)}-${random.slice(4, 8)}`;
        return code;
    }

    // Create a new voucher in the database
    static async createVoucher(ownerId, expiresInDays = 30) {
        const db = getDatabase();
        const voucherId = uuidv4();
        const code = this.generateVoucherCode();
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + expiresInDays);

        try {
            await db.run(
                `INSERT INTO vouchers (id, code, owner_id, expires_at) 
                 VALUES (?, ?, ?, ?)`,
                [voucherId, code, ownerId, expiresAt.toISOString()]
            );
            
            console.log(chalk.green(`✓ Voucher created: ${code}`));
            return {
                success: true,
                voucherId,
                code,
                expiresAt: expiresAt.toISOString()
            };
        } catch (error) {
            console.error(chalk.red(`✗ Error creating voucher: ${error.message}`));
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Validate and use a voucher
    static async useVoucher(code, userId) {
        const db = getDatabase();

        try {
            // Check if voucher exists and is valid
            const voucher = await db.get(
                `SELECT * FROM vouchers WHERE code = ?`,
                [code]
            );

            if (!voucher) {
                return {
                    success: false,
                    error: 'Voucher not found'
                };
            }

            if (voucher.is_used) {
                return {
                    success: false,
                    error: 'Voucher already used'
                };
            }

            // Check expiration
            if (new Date(voucher.expires_at) < new Date()) {
                return {
                    success: false,
                    error: 'Voucher expired'
                };
            }

            // Mark voucher as used
            await db.run(
                `UPDATE vouchers 
                 SET is_used = 1, used_by_id = ?, used_at = CURRENT_TIMESTAMP 
                 WHERE code = ?`,
                [userId, code]
            );

            console.log(chalk.green(`✓ Voucher ${code} used by user ${userId}`));
            return {
                success: true,
                voucherId: voucher.id,
                message: 'Voucher activated successfully'
            };
        } catch (error) {
            console.error(chalk.red(`✗ Error using voucher: ${error.message}`));
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Get voucher details
    static async getVoucherDetails(code) {
        const db = getDatabase();

        try {
            const voucher = await db.get(
                `SELECT v.*, u.username as owner_username 
                 FROM vouchers v
                 LEFT JOIN users u ON v.owner_id = u.id
                 WHERE v.code = ?`,
                [code]
            );

            if (!voucher) {
                return {
                    success: false,
                    error: 'Voucher not found'
                };
            }

            return {
                success: true,
                voucher
            };
        } catch (error) {
            console.error(chalk.red(`✗ Error getting voucher: ${error.message}`));
            return {
                success: false,
                error: error.message
            };
        }
    }

    // List all vouchers for a user
    static async listVouchersByOwner(ownerId) {
        const db = getDatabase();

        try {
            const vouchers = await db.all(
                `SELECT id, code, is_used, created_at, used_at, expires_at 
                 FROM vouchers WHERE owner_id = ?
                 ORDER BY created_at DESC`,
                [ownerId]
            );

            return {
                success: true,
                vouchers,
                total: vouchers.length
            };
        } catch (error) {
            console.error(chalk.red(`✗ Error listing vouchers: ${error.message}`));
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Generate multiple vouchers at once
    static async generateMultipleVouchers(ownerId, quantity, expiresInDays = 30) {
        const results = [];

        for (let i = 0; i < quantity; i++) {
            const result = await this.createVoucher(ownerId, expiresInDays);
            results.push(result);
        }

        console.log(chalk.blue(`Generated ${quantity} vouchers for owner ${ownerId}`));
        return {
            success: true,
            total: quantity,
            vouchers: results.filter(r => r.success),
            failed: results.filter(r => !r.success)
        };
    }
}

module.exports = VoucherManager;
