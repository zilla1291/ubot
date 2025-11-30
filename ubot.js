#!/usr/bin/env node

/**
 * Unfiltered Bytzz CLI Tool
 * Generate vouchers and manage the bot platform
 */

const path = require('path');
const fs = require('fs');
const chalk = require('chalk');

// Add the web directory to the path so we can import database modules
const dbPath = path.join(__dirname, '..', 'web');
process.env.DATABASE_PATH = path.join(__dirname, '..', 'data');

// Import modules dynamically after setting up paths
async function importModules() {
    try {
        // Initialize database from web directory
        const { initDatabase, getDatabase, closeDatabase } = require(path.join(dbPath, 'database.js'));
        const VoucherManager = require(path.join(dbPath, 'voucherManager.js'));
        return { initDatabase, getDatabase, closeDatabase, VoucherManager };
    } catch (error) {
        console.error(chalk.red('Error loading modules:'), error.message);
        process.exit(1);
    }
}

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];
const params = args.slice(1);

async function main() {
    const { initDatabase, getDatabase, closeDatabase, VoucherManager } = await importModules();

    console.log(chalk.blue.bold('\n╔════════════════════════════════════════════════╗'));
    console.log(chalk.blue.bold('║  Unfiltered Bytzz - CLI Tool'));
    console.log(chalk.blue.bold('║  Version 1.0.0'));
    console.log(chalk.blue.bold('╚════════════════════════════════════════════════╝\n'));

    try {
        // Initialize database
        await initDatabase();

        switch (command) {
            case 'voucher':
                await handleVoucher(params, VoucherManager);
                break;
            
            case 'vouchers':
                await handleVouchers(params, VoucherManager);
                break;
            
            case 'validate':
                await handleValidate(params, VoucherManager);
                break;
            
            case 'list':
                await handleList(params, VoucherManager);
                break;
            
            case 'help':
                showHelp();
                break;
            
            default:
                console.log(chalk.yellow('Unknown command. Use: ubot help'));
                showHelp();
        }
    } catch (error) {
        console.error(chalk.red('Error:'), error.message);
    } finally {
        await closeDatabase();
    }
}

async function handleVoucher(params, VoucherManager) {
    // ubot voucher [owner_id] [quantity] [days]
    const ownerId = params[0] || 'admin';
    const quantity = parseInt(params[1]) || 1;
    const expiresInDays = parseInt(params[2]) || 30;

    console.log(chalk.blue(`\nGenerating ${quantity} voucher(s) for owner: ${ownerId}`));
    console.log(`Expiration: ${expiresInDays} days\n`);

    if (quantity === 1) {
        const result = await VoucherManager.createVoucher(ownerId, expiresInDays);
        if (result.success) {
            console.log(chalk.green('\n╔════════════════════════════════════════════════╗'));
            console.log(chalk.green('║  VOUCHER GENERATED SUCCESSFULLY'));
            console.log(chalk.green('╚════════════════════════════════════════════════╝\n'));
            console.log(chalk.yellow(`Voucher Code: ${chalk.bold.white(result.code)}`));
            console.log(chalk.yellow(`Voucher ID:   ${result.voucherId}`));
            console.log(chalk.yellow(`Expires At:   ${new Date(result.expiresAt).toLocaleString()}`));
            console.log(chalk.yellow(`Status:       ${chalk.green('ACTIVE')}\n`));
            
            // Copy to clipboard message
            console.log(chalk.gray('📋 Voucher code ready to share with user\n'));
        } else {
            console.log(chalk.red(`✗ Error: ${result.error}`));
        }
    } else {
        const result = await VoucherManager.generateMultipleVouchers(ownerId, quantity, expiresInDays);
        console.log(chalk.green(`\n✓ Generated ${result.vouchers.length} vouchers`));
        console.log(chalk.yellow('Voucher Codes:\n'));
        
        result.vouchers.forEach((v, i) => {
            if (v.success) {
                console.log(chalk.white(`${i + 1}. ${chalk.bold.cyan(v.code)}`));
            }
        });
        console.log();
    }
}

async function handleVouchers(params, VoucherManager) {
    // ubot vouchers generate [owner_id] [quantity]
    const subcommand = params[0];
    
    if (subcommand === 'generate') {
        const ownerId = params[1] || 'admin';
        const quantity = parseInt(params[2]) || 5;
        
        console.log(chalk.blue(`\nGenerating bulk vouchers`));
        const result = await VoucherManager.generateMultipleVouchers(ownerId, quantity, 30);
        
        console.log(chalk.green(`\n✓ Successfully generated ${result.vouchers.length} vouchers\n`));
        
        result.vouchers.forEach((v, i) => {
            if (v.success) {
                console.log(chalk.white(`${i + 1}. ${chalk.bold.cyan(v.code)}`));
            }
        });
        console.log();
    } else {
        console.log(chalk.yellow('Usage: ubot vouchers generate [owner_id] [quantity]'));
    }
}

async function handleValidate(params, VoucherManager) {
    // ubot validate [code]
    const code = params[0];
    
    if (!code) {
        console.log(chalk.yellow('Usage: ubot validate <voucher_code>'));
        return;
    }

    console.log(chalk.blue(`\nValidating voucher: ${code}\n`));

    const result = await VoucherManager.getVoucherDetails(code);

    if (result.success) {
        const voucher = result.voucher;
        const isExpired = new Date(voucher.expires_at) < new Date();
        const isValid = !voucher.is_used && !isExpired;

        console.log(chalk.green('╔════════════════════════════════════════════════╗'));
        console.log(chalk.green('║  VOUCHER DETAILS'));
        console.log(chalk.green('╚════════════════════════════════════════════════╝\n'));
        console.log(`Code:      ${chalk.bold(voucher.code)}`);
        console.log(`Status:    ${isValid ? chalk.green('✓ VALID') : chalk.red('✗ INVALID')}`);
        console.log(`Used:      ${voucher.is_used ? chalk.red('Yes') : chalk.green('No')}`);
        console.log(`Expired:   ${isExpired ? chalk.red('Yes') : chalk.green('No')}`);
        console.log(`Owner:     ${voucher.owner_username || 'Unknown'}`);
        console.log(`Created:   ${new Date(voucher.created_at).toLocaleString()}`);
        console.log(`Expires:   ${new Date(voucher.expires_at).toLocaleString()}`);
        if (voucher.used_at) {
            console.log(`Used At:   ${new Date(voucher.used_at).toLocaleString()}`);
        }
        console.log();
    } else {
        console.log(chalk.red(`✗ Error: ${result.error}`));
    }
}

async function handleList(params, VoucherManager) {
    // ubot list [owner_id]
    const ownerId = params[0] || 'admin';

    console.log(chalk.blue(`\nListing vouchers for owner: ${ownerId}\n`));

    const result = await VoucherManager.listVouchersByOwner(ownerId);

    if (result.success && result.vouchers.length > 0) {
        console.log(chalk.green(`Found ${result.total} vouchers:\n`));
        
        const table = result.vouchers.map(v => ({
            Code: chalk.cyan(v.code),
            Status: v.is_used ? chalk.red('USED') : chalk.green('ACTIVE'),
            Created: new Date(v.created_at).toLocaleDateString(),
            Expires: new Date(v.expires_at).toLocaleDateString()
        }));

        console.table(table);
    } else if (result.vouchers.length === 0) {
        console.log(chalk.yellow('No vouchers found for this owner'));
    } else {
        console.log(chalk.red(`✗ Error: ${result.error}`));
    }
    console.log();
}

function showHelp() {
    console.log(chalk.cyan.bold('Available Commands:\n'));
    
    console.log(chalk.yellow('  ubot voucher [owner_id] [quantity] [days]'));
    console.log(chalk.gray('    Generate one or more vouchers\n'));
    
    console.log(chalk.yellow('  ubot vouchers generate [owner_id] [quantity]'));
    console.log(chalk.gray('    Generate multiple vouchers (alias for voucher command)\n'));
    
    console.log(chalk.yellow('  ubot validate <voucher_code>'));
    console.log(chalk.gray('    Check if a voucher is valid\n'));
    
    console.log(chalk.yellow('  ubot list [owner_id]'));
    console.log(chalk.gray('    List all vouchers for an owner\n'));
    
    console.log(chalk.yellow('  ubot help'));
    console.log(chalk.gray('    Show this help message\n'));

    console.log(chalk.cyan.bold('Examples:\n'));
    console.log(chalk.white('  ubot voucher admin'));
    console.log(chalk.gray('    → Generate 1 voucher for admin\n'));
    
    console.log(chalk.white('  ubot vouchers generate admin 10'));
    console.log(chalk.gray('    → Generate 10 vouchers for admin\n'));
    
    console.log(chalk.white('  ubot validate UBOT-XXXX-XXXX-XXXX'));
    console.log(chalk.gray('    → Validate a specific voucher\n'));
    
    console.log(chalk.white('  ubot list glen'));
    console.log(chalk.gray('    → List all vouchers for glen\n'));
}

// Run main function
if (require.main === module) {
    main().catch(error => {
        console.error(chalk.red('Fatal error:'), error);
        process.exit(1);
    });
}
