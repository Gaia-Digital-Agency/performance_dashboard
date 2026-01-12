# Project Progress & To-Do List

This document tracks the development progress of the Lighthouse Dashboard project.

## Completed

- [x] Initial project setup (backend, API, frontend).
- [x] Programmatic Lighthouse runner script (`runner.js`).
- [x] API endpoints for latest and historical data (`app.js`).
- [x] Basic React dashboard with table and charts (`Dashboard.js`).
- [x] Centralized configuration with `.env` support (`config.js`).
- [x] Refactored runner for parallel execution.
- [x] Refactored frontend with loading/error states.
- [x] Externalized website list to `sites.json`.
- [x] Implemented hourly audit schedule and 7-day data retention policy.

## To-Do

- [ ] **Setup Database:** Install PostgreSQL, create the `lighthouse_reports` database, and run the `CREATE TABLE` script.
- [ ] **Configure Environment:** Create the `.env` file in the root directory and fill in the database credentials.
- [ ] **Deployment:** Plan and execute deployment to a cloud server (e.g., AWS, DigitalOcean).