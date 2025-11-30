const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'Unfiltered Bytzz Platform',
        timestamp: new Date().toISOString()
    });
});

// Index page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API placeholder - return sample dashboard data
app.get('/api/deployment/sessions', (req, res) => {
    res.json({
        status: 'success',
        sessions: [],
        message: 'Platform is running'
    });
});

// Error handling
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
    console.log(`✓ Unfiltered Bytzz Platform running on port ${PORT}`);
    console.log(`✓ Access dashboard at http://localhost:${PORT}`);
});
