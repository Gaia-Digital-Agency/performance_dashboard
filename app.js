// api.js
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { dbConfig, API_PORT } = require('./config');

const app = express();

// Use CORS to allow your frontend to connect
app.use(cors());

const pool = new Pool(dbConfig);

// Root endpoint - API status
app.get('/', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Lighthouse Performance Dashboard API',
        version: '1.0.0',
        endpoints: {
            'GET /api/latest-reports': 'Get the latest report for each monitored site',
            'GET /api/history/:url': 'Get historical reports for a specific site URL'
        }
    });
});

// API endpoint to get the latest report for each site
app.get('/api/latest-reports', async (req, res) => {
    try {
        // This query gets the most recent report for each unique URL
        const query = `
            SELECT DISTINCT ON (url) *
            FROM reports
            ORDER BY url, created_at DESC;
        `;
        const { rows } = await pool.query(query);
        res.json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// API endpoint to get historical data for a specific site
app.get('/api/history/:url', async (req, res) => {
    try {
        const url = decodeURIComponent(req.params.url);
        const query = `
            SELECT * FROM reports
            WHERE url = $1
            ORDER BY created_at ASC;
        `;
        const { rows } = await pool.query(query, [url]);
        res.json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


app.listen(API_PORT, () => {
    console.log(`API server listening at http://localhost:${API_PORT}`);
});
