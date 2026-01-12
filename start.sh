#!/bin/bash

# Website Performance Dashboard - Start Script
# This script starts all services needed for the dashboard

echo "🚀 Starting Gaiada Dashboard Services..."
echo ""

# Check if PostgreSQL is running
echo "📊 Checking PostgreSQL status..."
if ! pg_isready -q; then
    echo "⚠️  PostgreSQL is not running. Starting PostgreSQL..."
    brew services start postgresql@14
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 3

    if ! pg_isready -q; then
        echo "❌ Failed to start PostgreSQL. Please check your installation."
        exit 1
    fi
fi
echo "✓ PostgreSQL is running"
echo ""

# Start the API server in the background
echo "🔧 Starting API Server on port 3001..."
node app.js > logs/api.log 2>&1 &
API_PID=$!
echo $API_PID > .pids/api.pid
echo "✓ API Server started (PID: $API_PID)"
echo ""

# Start the Lighthouse scheduler in the background
echo "📈 Starting Lighthouse Scheduler..."
node scheduler.js > logs/scheduler.log 2>&1 &
SCHEDULER_PID=$!
echo $SCHEDULER_PID > .pids/scheduler.pid
echo "✓ Scheduler started (PID: $SCHEDULER_PID)"
echo ""

# Start the React frontend
echo "🎨 Starting React Frontend..."
cd dashboard-ui
npm start > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > ../.pids/frontend.pid
cd ..
echo "✓ Frontend started (PID: $FRONTEND_PID)"
echo ""

echo "✅ All services started successfully!"
echo ""
echo "📋 Service URLs:"
echo "   - API Server: http://localhost:3001"
echo "   - Dashboard UI: http://localhost:3000"
echo ""
echo "📝 Logs are available in the logs/ directory:"
echo "   - API: logs/api.log"
echo "   - Scheduler: logs/scheduler.log"
echo "   - Frontend: logs/frontend.log"
echo ""
echo "🛑 To stop all services, run: ./stop.sh"
