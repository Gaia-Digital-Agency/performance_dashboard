// runner.js
const { default: lighthouse } = require('lighthouse');
const puppeteer = require('puppeteer');
const { Pool } = require('pg');
const { SITES_TO_MONITOR, dbConfig } = require('./config');

// Configuration for your database
const pool = new Pool(dbConfig);

/**
 * Runs a Lighthouse audit on a given URL.
 * @param {string} url The URL to audit.
 * @param {object} browser A Puppeteer browser instance.
 * @returns {Promise<object>} The structured Lighthouse report data.
 */
async function runLighthouse(url, browser) {
    console.log(`Running Lighthouse for: ${url}`);
    const { lhr } = await lighthouse(url, {
        port: (new URL(browser.wsEndpoint())).port,
        output: 'json',
        logLevel: 'info',
        onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
    });

    // Extract the most important scores
    // Extract Core Web Vitals from audits (use ?? to handle 0 values correctly)
    const lcp = lhr.audits['largest-contentful-paint']?.numericValue ?? null;
    const cls = lhr.audits['cumulative-layout-shift']?.numericValue ?? null;
    const tbt = lhr.audits['total-blocking-time']?.numericValue ?? null;

    return {
        url: url,
        performance_score: Math.round(lhr.categories.performance.score * 100),
        accessibility_score: Math.round(lhr.categories.accessibility.score * 100),
        best_practices_score: Math.round(lhr.categories['best-practices'].score * 100),
        seo_score: Math.round(lhr.categories.seo.score * 100),
        pwa_score: 0, // PWA category removed in newer Lighthouse versions
        lcp_ms: lcp !== null ? Math.round(lcp) : null,
        cls: cls !== null ? parseFloat(cls.toFixed(4)) : null,
        tbt_ms: tbt !== null ? Math.round(tbt) : null,
    };
}

/**
 * Saves a Lighthouse report to the database.
 * @param {object} report The report data from runLighthouse.
 * @param {object} client A pg Client.
 */
async function saveReportToDB(report, client) {
    const query = `
        INSERT INTO reports(url, performance_score, accessibility_score, best_practices_score, seo_score, pwa_score, lcp_ms, cls, tbt_ms, created_at)
        VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
    `;
    const values = [
        report.url,
        report.performance_score,
        report.accessibility_score,
        report.best_practices_score,
        report.seo_score,
        report.pwa_score,
        report.lcp_ms,
        report.cls,
        report.tbt_ms,
    ];

    try {
        await client.query(query, values);
        console.log(`Successfully saved report for ${report.url}`);
    } catch (err) {
        console.error(`Error saving report for ${report.url}:`, err);
    }
}

/**
 * The main function to run audits for all sites.
 */
async function runAllAudits() {
    console.log(`Starting audits for ${SITES_TO_MONITOR.length} sites...`);
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const dbClient = await pool.connect();

    try {
        // Run audits sequentially to avoid browser conflicts
        for (const site of SITES_TO_MONITOR) {
            try {
                const report = await runLighthouse(site, browser);
                await saveReportToDB(report, dbClient);
            } catch (error) {
                console.error(`Audit failed for ${site}:`, error);
            }
        }

    } catch (error) {
        console.error('A critical error occurred during the audit run:', error);
    } finally {
        // Ensure resources are always released
        console.log('Closing browser and database connection...');
        await browser.close();
        dbClient.release();
    }

    console.log('All audits completed.');
}

// For testing, you can run it directly
// runAllAudits();

// Export the function to be used by the scheduler
module.exports = { runAllAudits };
