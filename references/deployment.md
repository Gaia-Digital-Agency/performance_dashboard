# Deployment Guide for DigitalOcean

This guide provides step-by-step instructions for deploying the Lighthouse Performance Dashboard to a DigitalOcean Droplet.

We will use:
- A **Managed PostgreSQL Database** for data storage.
- A **DigitalOcean Droplet** (Ubuntu) to run our application services.
- **Nginx** as a web server and reverse proxy.
- **PM2** as a process manager for our Node.js applications.

---

## Step 1: Create a Managed PostgreSQL Database

Using a managed database simplifies maintenance and backups.

1.  In your DigitalOcean dashboard, navigate to **Databases** and click **Create Database Cluster**.
2.  Choose **PostgreSQL**.
3.  Select a plan that fits your needs (the smallest plan is usually sufficient to start).
4.  Choose the **same datacenter region** you plan to use for your Droplet to minimize latency.
5.  Give your database cluster a unique name.
6.  After the database is created, go to its **Overview** tab. Under **Connection Details**, select **Connection string** and copy the URI. This contains your `user`, `password`, `host`, `port`, and `database` name.
7.  Go to the **Users & Databases** tab. By default, it creates a `defaultdb` database and a `doadmin` user. You can use these or create new ones.
8.  Go to the **Settings** tab. In the **Trusted Sources** section, you will later add your Droplet's IP address to allow it to connect.

---

## Step 2: Create a DigitalOcean Droplet

The Droplet is the virtual server where your code will run.

1.  In your dashboard, navigate to **Droplets** and click **Create Droplet**.
2.  **Choose an image:** Select **Ubuntu 22.04 (LTS) x64** or a newer LTS version.
3.  **Choose a plan:** A **Basic (Shared CPU)** Droplet is a good starting point (e.g., 1 GB RAM / 1 CPU).
4.  **Choose a datacenter region:** Select the **same region** as your database.
5.  **Authentication:** Select **SSH keys** and add your public SSH key. This is more secure than using a password.
6.  Finalize and click **Create Droplet**.
7.  Once created, copy the Droplet's **public IP address**.

---

## Step 3: Configure the Server

Connect to your Droplet via SSH and install the necessary software.

```bash
# Replace YOUR_DROPLET_IP with the IP you copied
ssh root@YOUR_DROPLET_IP
```

Once connected, run the following commands:

```bash
# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js (we recommend using nvm to manage versions)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts # Installs the latest Long-Term Support version

# Install Nginx web server
sudo apt install nginx -y

# Install Git
sudo apt install git -y

# Install PM2, a process manager for Node.js
npm install pm2 -g
```

---

## Step 4: Deploy the Backend and Frontend

1.  **Clone your project repository:**
    ```bash
    git clone <your-git-repository-url> gaiada_dashboard
    cd gaiada_dashboard
    ```

2.  **Install dependencies:**
    ```bash
    # For the backend
    npm install

    # For the frontend
    cd dashboard-ui
    npm install
    cd ..
    ```

3.  **Configure Environment Variables:**
    Create a `.env` file in the project root (`gaiada_dashboard/`). Use the connection details from your managed database.
    ```bash
    nano .env
    ```
    Add the following content, replacing placeholders with your actual database credentials:
    ```
    # .env
    DB_USER=doadmin
    DB_HOST=your-db-host.db.ondigitalocean.com
    DB_DATABASE=defaultdb
    DB_PASSWORD=your-database-password
    DB_PORT=25060

    API_PORT=3001
    REACT_APP_API_BASE_URL=/api
    ```
    **Note:** We use `/api` for `REACT_APP_API_BASE_URL`. Nginx will handle proxying this path to our backend.

4.  **Build the React App:**
    ```bash
    cd dashboard-ui
    npm run build
    cd ..
    ```

---

## Step 5: Run Services with PM2

PM2 will keep your API and scheduler running in the background.

```bash
# From the project root directory (gaiada_dashboard/)

# Start the API server
pm2 start app.js --name "lighthouse-api"

# Start the scheduler
pm2 start scheduler.js --name "lighthouse-scheduler"

# Save the process list to restart on server reboot
pm2 save

# Generate a startup script to run PM2 on boot
pm2 startup
```
PM2 will output a command you need to copy and run to complete the startup script setup.

---

## Step 6: Configure Nginx

Finally, configure Nginx to serve your React app and act as a reverse proxy for your API.

1.  Create a new Nginx configuration file:
    ```bash
    sudo nano /etc/nginx/sites-available/lighthouse
    ```

2.  Paste the following configuration, replacing `YOUR_DROPLET_IP` with your Droplet's IP address.
    ```nginx
    server {
        listen 80;
        server_name YOUR_DROPLET_IP; # Or your domain name

        # Serve the static React app
        root /root/gaiada_dashboard/dashboard-ui/build;
        index index.html index.htm;

        location / {
            try_files $uri /index.html;
        }

        # Reverse proxy for the API
        location /api/ {
            proxy_pass http://localhost:3001/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

3.  **Enable the site and restart Nginx:**
    ```bash
    # Link the config to enable it
    sudo ln -s /etc/nginx/sites-available/lighthouse /etc/nginx/sites-enabled/

    # Remove the default config to avoid conflicts
    sudo rm /etc/nginx/sites-enabled/default

    # Test the Nginx configuration for syntax errors
    sudo nginx -t

    # Restart Nginx to apply changes
    sudo systemctl restart nginx
    ```

4.  **Allow Traffic:** Open the firewall for HTTP traffic.
    ```bash
    sudo ufw allow 'Nginx Full'
    ```

Your dashboard should now be live at `http://YOUR_DROPLET_IP`.

---

## Step 7: Secure Database Connection

Go back to your **Managed Database** settings in the DigitalOcean dashboard. Under **Trusted Sources**, add your Droplet's IP address. This ensures only your application can connect to the database.