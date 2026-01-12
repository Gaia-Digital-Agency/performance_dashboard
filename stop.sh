#!/bin/bash

# Website Performance Dashboard - Stop Script
# This script stops all running services

echo "🛑 Stopping Gaiada Dashboard Services..."
echo ""

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file=$2

    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if ps -p $PID > /dev/null 2>&1; then
            echo "⏹️  Stopping $service_name (PID: $PID)..."
            kill $PID
            sleep 1

            # Force kill if still running
            if ps -p $PID > /dev/null 2>&1; then
                echo "⚠️  Force stopping $service_name..."
                kill -9 $PID
            fi
            echo "✓ $service_name stopped"
        else
            echo "ℹ️  $service_name is not running"
        fi
        rm -f "$pid_file"
    else
        echo "ℹ️  No PID file found for $service_name"
    fi
}

# Stop API Server
stop_service "API Server" ".pids/api.pid"

# Stop Scheduler
stop_service "Scheduler" ".pids/scheduler.pid"

# Stop Frontend
stop_service "Frontend" ".pids/frontend.pid"

# Also try to kill any remaining node processes for this project
echo ""
echo "🧹 Cleaning up any remaining processes..."

# Kill any node processes running app.js, scheduler.js
pkill -f "node app.js" 2>/dev/null
pkill -f "node scheduler.js" 2>/dev/null

# Kill React development server on port 3000
lsof -ti:3000 | xargs kill -9 2>/dev/null

# Kill API server on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null

echo ""
echo "✅ All services stopped successfully!"
echo ""
echo "💡 PostgreSQL is still running. To stop it, run:"
echo "   brew services stop postgresql@14"
