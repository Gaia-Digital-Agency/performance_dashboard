# Database and Environment Setup Guide

This guide provides detailed instructions for setting up your PostgreSQL database and configuring the `.env` file required to run the application.

---

## Part 1: PostgreSQL Database Setup (for Local Development)

This application requires a PostgreSQL database to store Lighthouse reports. For production, you can use a managed service as described in `deployment.md`. These steps are for setting up a local database for development.

### Step 1: Install PostgreSQL

If you don't have PostgreSQL installed, download it from the official PostgreSQL website. Follow the instructions for your operating system (Windows, macOS, or Linux).

During installation, you will typically create a superuser (often named `postgres`) and set a password for it. **Remember this password.**

### Step 2: Create a New User and Database

It's a security best practice to create a dedicated user and database for your application.

1.  **Connect to PostgreSQL:**
    Open your terminal or command prompt and connect to the default PostgreSQL server using the `psql` command-line tool. You will be prompted for the password you set during installation.

    ```bash
    # Connect as the default postgres user
    psql -U postgres
    ```

2.  **Create a Database User:**
    Create a new user (role) that the application will use to connect. Replace `my_app_user` and `a_very_strong_password` with your desired username and a secure password.

    ```sql
    CREATE USER my_app_user WITH PASSWORD 'a_very_strong_password';
    ```

3.  **Create the Database:**
    Create the database that will store the reports. We'll name it `lighthouse_reports`.

    ```sql
    CREATE DATABASE lighthouse_reports;
    ```

4.  **Grant Privileges:**
    Give your new user full control over the new database.

    ```sql
    GRANT ALL PRIVILEGES ON DATABASE lighthouse_reports TO my_app_user;
    ```

5.  **Connect to the New Database and Create the Table:**
    Now, connect to your newly created database and run the `CREATE TABLE` script.

    ```sql
    -- Disconnect from the current session
    \q

    -- Reconnect to the new database as the new user
    psql -U my_app_user -d lighthouse_reports

    -- You will be prompted for the password you just created.
    -- Once connected, run the following command to create the 'reports' table:
    CREATE TABLE reports (
        id SERIAL PRIMARY KEY,
        url VARCHAR(255) NOT NULL,
        performance_score INT NOT NULL,
        accessibility_score INT NOT NULL,
        best_practices_score INT NOT NULL,
        seo_score INT NOT NULL,
        pwa_score INT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL
    );

    -- You can verify the table was created with:
    \dt
    ```

Your database is now ready!

---

## Part 2: Configuring the `.env` File

The `.env` file stores all the configuration and secrets your application needs to run. Create this file in the root of the project (`gaiada_dashboard/.env`).

### Template

Copy this template into your `.env` file and fill it with the values from your setup.

```
# .env

# --- Database Configuration ---
# Use the user, password, and database name you created in Part 1.
DB_USER=my_app_user
DB_PASSWORD=a_very_strong_password
DB_HOST=localhost
DB_DATABASE=lighthouse_reports
DB_PORT=5432

# --- Application Configuration ---
# Port for the backend API server.
API_PORT=3001

# The base URL for the API that the React frontend will use.
# For local development, this should point to your local API server.
REACT_APP_API_BASE_URL=http://localhost:3001
```

**Explanation of Variables:**

- `DB_USER`: The PostgreSQL username you created (`my_app_user`).
- `DB_PASSWORD`: The password for that PostgreSQL user.
- `DB_HOST`: `localhost` for a local database, or the hostname from your managed database provider.
- `DB_DATABASE`: The name of the database you created (`lighthouse_reports`).
- `DB_PORT`: The port PostgreSQL is running on. The default is `5432`.
- `API_PORT`: The port your backend Node.js API will run on.
- `REACT_APP_API_BASE_URL`: Tells your React frontend where to send API requests. For deployment, this is often changed to a relative path like `/api` (as shown in `deployment.md`).