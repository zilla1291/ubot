require('dotenv').config();
const express = require('express');
const cors = require('cors');
const chalk = require('chalk');
const path = require('path');
const { initDatabase } = require('./database');
const VoucherManager = require('./voucherManager');

const app = express();
const PORT = process.env.PORT || 3000;
const ADMIN_KEY = process.env.ADMIN_KEY || 'admin-secret-key';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
const deploymentRoutes = require('./routes/deployment');
const voucherRoutes = require('./routes/vouchers');

// API Routes
app.use('/api/deployment', deploymentRoutes);
app.use('/api/vouchers', voucherRoutes);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'Unfiltered Bytzz Deployment Platform',
        timestamp: new Date().toISOString()
    });
});

// Admin endpoint to generate vouchers (must provide ADMIN_KEY)
app.post('/admin/generate-vouchers', (req, res) => {
    try {
        const { key, ownerId, quantity, expiresInDays } = req.body;

        if (key !== ADMIN_KEY) {
            return res.status(403).json({
                success: false,
                error: 'Invalid admin key'
            });
        }

        if (!ownerId) {
            return res.status(400).json({
                success: false,
                error: 'Owner ID is required'
            });
        }

        // Call voucher generation (this is async but we won't await)
        VoucherManager.generateMultipleVouchers(
            ownerId,
            quantity || 1,
            expiresInDays || 30
        ).then(result => {
            console.log(chalk.green('Vouchers generated successfully'));
        }).catch(err => {
            console.error(chalk.red('Error generating vouchers:'), err);
        });

        res.json({
            success: true,
            message: 'Voucher generation started',
            quantity: quantity || 1
        });
    } catch (error) {
        console.error(chalk.red(`✗ Error in admin endpoint: ${error.message}`));
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Dashboard - serve HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
async function startServer() {
    try {
        // Initialize database
        await initDatabase();
        console.log(chalk.green('✓ Database initialized'));

        app.listen(PORT, () => {
            console.log(chalk.blue.bold('\n╔════════════════════════════════════════════════╗'));
            console.log(chalk.blue.bold('║  Unfiltered Bytzz Deployment Platform'));
            console.log(chalk.blue.bold('║  Author: Glen Zilla'));
            console.log(chalk.blue.bold('║  Telegram: @unfilteredg'));
            console.log(chalk.blue.bold('╚════════════════════════════════════════════════╝\n'));
            console.log(chalk.green(`✓ Server running on port ${PORT}`));
            console.log(chalk.yellow(`🌐 Visit http://localhost:${PORT}\n`));
        });
    } catch (error) {
        console.error(chalk.red('✗ Failed to start server:'), error);
        process.exit(1);
    }
}

startServer();

module.exports = app;
