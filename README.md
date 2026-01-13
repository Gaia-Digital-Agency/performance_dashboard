# Website Performance Dashboard

This project is a comprehensive dashboard for monitoring the Lighthouse performance scores (Performance, Accessibility, Best Practices, SEO) of multiple websites over time.

It consists of a Node.js backend that periodically runs Lighthouse audits, stores the results in a PostgreSQL database, and serves the data via a REST API. The frontend is a React application that visualizes this data in a clean, easy-to-read dashboard.

## Features

- **Automated Audits:** A scheduler runs Lighthouse audits automatically at configurable intervals.
- **Historical Data:** Stores performance reports to track trends and regressions.
- **Dynamic Site List:** Websites to be monitored can be easily managed in a `sites.json` file.
- **Data Visualization:** The dashboard displays the latest scores for all sites and provides historical charts for individual sites.
- **Automatic Data Cleanup:** Old records are automatically purged to keep the database lean.
- **Site Sync Script:** Easy-to-use script (`site_updates.sh`) to sync database with sites.json and run audits.

## Tech Stack

- **Backend:** Node.js, Express.js
- **Frontend:** React
- **Database:** PostgreSQL
- **Scheduling:** `node-cron`
- **Lighthouse Runner:** `lighthouse`, `puppeteer`

## Architecture

The application is composed of three main services:

1.  **Scheduler (`scheduler.js`):** A long-running process that triggers the Lighthouse runner on a schedule.
2.  **API Server (`app.js`):** An Express server that provides endpoints for the frontend to fetch report data.
3.  **Frontend (`dashboard-ui`):** A React single-page application that presents the data to the user.

```
+-------------------+      +-------------------+      +-----------------+
|   Scheduled Job   |----->|   Lighthouse    |----->|    Websites     |
|   (node-cron)     |      |   Runner Script   |      | (from sites.json) |
+-------------------+      +-------------------+      +-----------------+
                             |
                             v (Saves Report)
+-------------------+      +-------------------+      +-----------------+
|   Dashboard UI    |<-----|    API Server     |<-----|    Database     |
|     (React)       |      |    (Express.js)   |      |  (PostgreSQL)   |
+-------------------+      +-------------------+      +-----------------+
```

## Quick Start

### Managing Sites

Add or remove websites in `sites.json`:
```json
[
  "https://example.com",
  "https://another-site.com"
]
```

### Syncing Sites & Running Audits

After updating `sites.json`, use the site sync script:

```bash
# Run audits in foreground (see progress in real-time)
./site_updates.sh

# Run audits in background (faster, runs in background)
./site_updates.sh --background

# Force re-audit all sites even if they have data
./site_updates.sh --force
```

The script will:
1. Read all sites from `sites.json`
2. Remove any sites from the database that are no longer in `sites.json`
3. Run Lighthouse audits for all sites
4. Show you a summary of the results

### Starting the Dashboard

```bash
# Start all services (API + Scheduler + Frontend)
./start.sh

# Or start individually:
node app.js           # API server (port 3001)
node scheduler.js     # Scheduled audits
cd dashboard-ui && npm start  # Frontend (port 3000)
```

Then open [http://localhost:3000](http://localhost:3000) in your browser.