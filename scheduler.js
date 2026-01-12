// scheduler.js
const cron = require('node-cron');
const { Pool } = require('pg');
const { runAllAudits } = require('./runner');
const { dbConfig } = require('./config');

const pool = new Pool(dbConfig);

console.log('Scheduler started. Waiting for the scheduled time to run audits.');

// Schedule to run audits once daily at 11:00 PM.
// Cron format: minute hour day-of-month month day-of-week
cron.schedule('0 23 * * *', () => {
    console.log('Scheduled task triggered: Running Lighthouse audits at 11:00 PM...');
    runAllAudits().catch(err => {
        console.error('An error occurred during the scheduled audit run:', err);
    });
}, {
    scheduled: true,
    timezone: "America/New_York" // TODO: Set to your timezone
});

// Schedule a cleanup job to run once a day at 3:00 AM.
// This job deletes old reports AND removes duplicate daily reports, keeping only the 11:00 PM run.
cron.schedule('0 3 * * *', async () => {
    console.log('Running daily cleanup job...');
    const client = await pool.connect();
    try {
        // Step 1: Delete records older than 7 days
        const deleteOld = await client.query("DELETE FROM reports WHERE created_at < NOW() - INTERVAL '7 days'");
        console.log(`Deleted ${deleteOld.rowCount} records older than 7 days.`);

        // Step 2: Keep only one report per day per site (the one closest to 11:00 PM)
        // This handles cases where multiple reports exist for the same day
        const deleteDuplicates = await client.query(`
            DELETE FROM reports
            WHERE id NOT IN (
                SELECT DISTINCT ON (url, DATE(created_at))
                id
                FROM reports
                ORDER BY url, DATE(created_at), ABS(EXTRACT(EPOCH FROM (created_at::time - '23:00:00'::time)))
            )
        `);
        console.log(`Deleted ${deleteDuplicates.rowCount} duplicate daily records.`);
        console.log('Cleanup complete.');
    } catch (err) {
        console.error('Error during daily cleanup:', err);
    } finally {
        client.release();
    }
}, {
    scheduled: true,
    timezone: "America/New_York" // TODO: Set to your timezone
});
