// Global state
let currentSessionId = null;
let currentVoucherCode = null;
const API_BASE = '/api';

// Navigation
function navigateTo(page) {
    document.querySelectorAll('.page').forEach(el => el.classList.remove('active'));
    document.getElementById(page).classList.add('active');
    window.scrollTo(0, 0);
}

// Toggle step visibility
function toggleStep(stepNum) {
    const stepContent = document.getElementById(`step-${stepNum}`);
    const stepHeader = stepContent.previousElementSibling;
    const chevron = stepHeader.querySelector('i.fas-chevron-down');
    
    if (stepContent.style.display === 'none' || !stepContent.style.display) {
        stepContent.style.display = 'block';
        if (chevron) chevron.classList.add('rotate');
    } else {
        stepContent.style.display = 'none';
        if (chevron) chevron.classList.remove('rotate');
    }
}

// Show status message
function showStatus(elementId, message, type = 'info') {
    const container = document.getElementById(elementId);
    container.innerHTML = `
        <div class="status-message ${type} show">
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            ${message}
        </div>
    `;
}

// Validate Voucher
async function validateVoucher() {
    const voucherCode = document.getElementById('voucher-code').value.trim();
    
    if (!voucherCode) {
        showStatus('voucher-status', 'Please enter a voucher code', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/vouchers/check`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ code: voucherCode })
        });

        const data = await response.json();

        if (!data.success) {
            showStatus('voucher-status', `Error: ${data.error}`, 'error');
            return;
        }

        if (!data.isValid) {
            let errorMsg = 'Voucher is invalid. ';
            if (data.isUsed) errorMsg += 'It has already been used.';
            if (data.isExpired) errorMsg += 'It has expired.';
            showStatus('voucher-status', errorMsg, 'error');
            return;
        }

        currentVoucherCode = voucherCode;

        // Create session with voucher
        const userId = `user_${Math.random().toString(36).substr(2, 9)}`;
        const deployResponse = await fetch(`${API_BASE}/deployment/validate-voucher`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                code: voucherCode, 
                userId: userId 
            })
        });

        const deployData = await deployResponse.json();

        if (deployData.success) {
            currentSessionId = deployData.sessionId;
            showStatus('voucher-status', '✓ Voucher valid! Session created. Proceed to Step 2.', 'success');
            setTimeout(() => {
                toggleStep(2);
            }, 1000);
        } else {
            showStatus('voucher-status', `Error: ${deployData.error}`, 'error');
        }
    } catch (error) {
        showStatus('voucher-status', `Network error: ${error.message}`, 'error');
        console.error('Voucher validation error:', error);
    }
}

// Generate QR Code
async function generateQRCode() {
    if (!currentSessionId) {
        showStatus('pairing-status', 'Please validate voucher first', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/deployment/generate-qr`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId: currentSessionId })
        });

        const data = await response.json();

        if (data.success) {
            const resultDiv = document.getElementById('qr-code-result');
            resultDiv.innerHTML = `
                <div style="text-align: center;">
                    <img src="${data.qrCode}" alt="QR Code" style="max-width: 300px; border: 2px solid #000;">
                    <p style="margin-top: 15px; color: #666;">Scan this QR code with WhatsApp's Linked Devices feature</p>
                </div>
            `;
            showStatus('pairing-status', 'QR Code generated. Scan with WhatsApp', 'success');
        } else {
            showStatus('pairing-status', `Error: ${data.error}`, 'error');
        }
    } catch (error) {
        showStatus('pairing-status', `Error: ${error.message}`, 'error');
        console.error('QR generation error:', error);
    }
}

// Get Pairing Code
async function getPairingCode() {
    const phoneNumber = document.getElementById('phone-number').value.trim();

    if (!phoneNumber) {
        showStatus('pairing-status', 'Please enter your phone number', 'error');
        return;
    }

    if (!currentSessionId) {
        showStatus('pairing-status', 'Please validate voucher first', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/deployment/get-pairing-code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                sessionId: currentSessionId, 
                phoneNumber: phoneNumber 
            })
        });

        const data = await response.json();

        if (data.success) {
            const resultDiv = document.getElementById('pairing-code-result');
            resultDiv.innerHTML = `
                <div style="background-color: #f0f0f0; padding: 20px; border-radius: 5px; margin-top: 15px; text-align: center;">
                    <p style="color: #666; margin-bottom: 10px;">Your Pairing Code:</p>
                    <div style="font-size: 2rem; font-weight: bold; color: #000; letter-spacing: 5px; font-family: monospace; margin-bottom: 10px;">
                        ${data.pairingCode}
                    </div>
                    <p style="color: #999; font-size: 0.9rem;">Enter this code in WhatsApp Linked Devices. Expires in 5 minutes.</p>
                </div>
            `;
            showStatus('pairing-status', 'Pairing code generated successfully', 'success');
        } else {
            showStatus('pairing-status', `Error: ${data.error}`, 'error');
        }
    } catch (error) {
        showStatus('pairing-status', `Error: ${error.message}`, 'error');
        console.error('Pairing code error:', error);
    }
}

// Deploy Bot
async function deployBot() {
    if (!currentSessionId) {
        showStatus('deployment-status', 'Please complete previous steps', 'error');
        return;
    }

    const botName = document.getElementById('bot-name').value.trim();
    if (!botName) {
        showStatus('deployment-status', 'Please enter a bot name', 'error');
        return;
    }

    // Get enabled features
    const features = {};
    document.querySelectorAll('.features-checklist input[type="checkbox"]').forEach(checkbox => {
        features[checkbox.value] = checkbox.checked;
    });

    try {
        const response = await fetch(`${API_BASE}/deployment/deploy`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                sessionId: currentSessionId,
                botName: botName,
                features: features
            })
        });

        const data = await response.json();

        if (data.success) {
            showStatus('deployment-status', `✓ Deployment started! Deployment ID: ${data.deploymentId}`, 'success');
            setTimeout(() => {
                navigateTo('manage');
                loadSessions();
            }, 2000);
        } else {
            showStatus('deployment-status', `Error: ${data.error}`, 'error');
        }
    } catch (error) {
        showStatus('deployment-status', `Error: ${error.message}`, 'error');
        console.error('Deployment error:', error);
    }
}

// Load Sessions
async function loadSessions() {
    try {
        const response = await fetch(`${API_BASE}/deployment/sessions`);
        
        // Since we don't have a list endpoint, we'll show stored sessions
        const sessionsGrid = document.getElementById('sessions-grid');
        
        if (currentSessionId) {
            const sessionResponse = await fetch(`${API_BASE}/deployment/session/${currentSessionId}`);
            const sessionData = await sessionResponse.json();
            
            if (sessionData.success) {
                const session = sessionData.session;
                sessionsGrid.innerHTML = createSessionCard(session);
                return;
            }
        }

        sessionsGrid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <p>No sessions found. Deploy a bot to get started!</p>
            </div>
        `;
    } catch (error) {
        console.error('Error loading sessions:', error);
    }
}

function createSessionCard(session) {
    const statusClass = session.status === 'deployed' ? 'status-active' : 'status-inactive';
    const statusText = session.status === 'deployed' ? 'Active' : 'Pairing';

    return `
        <div class="session-card">
            <div class="session-header">
                <span class="session-name">${session.bot_name || 'Unnamed Bot'}</span>
                <span class="status-badge ${statusClass}">${statusText}</span>
            </div>
            <div class="session-info">
                <p><strong>Session ID:</strong> ${session.id.substring(0, 12)}...</p>
                <p><strong>Voucher:</strong> ${session.voucher_code}</p>
                <p><strong>Created:</strong> ${new Date(session.created_at).toLocaleDateString()}</p>
                <p><strong>Deployment Status:</strong> ${session.deployment_status || 'pending'}</p>
            </div>
            <div class="session-buttons">
                <button class="btn btn-primary" onclick="toggleFeatures('${session.id}')">
                    <i class="fas fa-sliders-h"></i> Features
                </button>
                <button class="btn btn-danger" onclick="deleteSession('${session.id}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `;
}

async function toggleFeatures(sessionId) {
    try {
        const response = await fetch(`${API_BASE}/deployment/session/${sessionId}/features`);
        const data = await response.json();
        
        if (data.success) {
            alert(`Session Features:\n\n${data.features.map(f => `${f.feature_name}: ${f.is_enabled ? 'ON' : 'OFF'}`).join('\n')}`);
        }
    } catch (error) {
        console.error('Error loading features:', error);
    }
}

function deleteSession(sessionId) {
    if (confirm('Are you sure you want to delete this session?')) {
        alert('Delete session: ' + sessionId);
    }
}

// Search Sessions
function searchSessions() {
    const searchTerm = document.getElementById('session-search').value.toLowerCase();
    // Implement search functionality
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    console.log('Application initialized');
    // Set initial page
    navigateTo('home');
});
