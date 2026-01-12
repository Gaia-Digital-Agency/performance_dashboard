// config.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');

const sitesFilePath = path.join(__dirname, 'sites.json');
const SITES_TO_MONITOR = JSON.parse(fs.readFileSync(sitesFilePath, 'utf-8'));

const dbConfig = {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: parseInt(process.env.DB_PORT || '5432', 10),
};

module.exports = {
    SITES_TO_MONITOR,
    dbConfig,
    API_PORT: process.env.API_PORT || 3001,
};