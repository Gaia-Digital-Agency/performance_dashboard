# How to Run the Application

Follow these steps to get the entire application running on your local machine for development and testing.

## Prerequisites

1.  **Node.js:** Ensure you have Node.js (v16 or later) installed.
2.  **PostgreSQL:** Ensure you have a running PostgreSQL server.
3.  **Project Setup:**
    - Run `npm install` in the root directory (`gaiada_dashboard/`) to install backend dependencies.
    - Run `npm install` in the frontend directory (`gaiada_dashboard/dashboard-ui/`) to install frontend dependencies.
4.  **Database Setup:**
    - Follow the detailed instructions in `database_setup.md` to install PostgreSQL and create your database and table.
5.  **Environment Configuration:**
    - Create a `.env` file in the project root. Use `database_setup.md` as a guide for filling in the values.

## Running the Services

You will need to open three separate terminal windows or tabs to run all parts of the application.

### 1. Start the API Server

This server provides data to your frontend dashboard.

```bash
# In terminal 1, from the project root directory:
node app.js
```
> You should see: `API server listening at http://localhost:3001`

### 2. Start the Scheduler

This process runs in the background, triggering Lighthouse audits automatically.

```bash
# In terminal 2, from the project root directory:
node scheduler.js
```
> You should see: `Scheduler started. Waiting for the scheduled time to run audits.`

### 3. Start the Frontend Development Server

This serves the React dashboard UI.

```bash
# In terminal 3, from the dashboard-ui directory:
cd dashboard-ui
npm start
```
> This will automatically open your browser to `http://localhost:3000`, where you can see your dashboard.