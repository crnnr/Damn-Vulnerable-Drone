#!/bin/bash
# DVD CTF Startup Script
# This script starts the entire DVD environment and drops you into the developer machine

echo "🚁 Starting Damn Vulnerable Drone CTF Environment..."
echo ""

# Start the containers in the background
echo "📦 Building and starting containers..."
docker-compose up -d

# Wait for containers to be ready
echo "⏳ Waiting for containers to initialize..."
sleep 10

# Check if developer machine is running
if ! docker ps | grep -q "dvd-developer-machine"; then
    echo "❌ Error: Developer machine container failed to start"
    echo "Please check the logs with: docker-compose logs developer-machine"
    exit 1
fi

# Start cron service in the developer machine
echo "🔧 Setting up CTF environment..."
docker exec dvd-developer-machine service cron start > /dev/null 2>&1

# Display welcome message and connect
echo ""
echo "🎯 === DAMN VULNERABLE DRONE - CTF CHALLENGE ==="
echo "🖥️  Developer Workstation Online..."
echo "🌐 Network: 10.13.0.10"
echo ""
echo "📡 Available systems:"
echo "   - ground-control-station: 10.13.0.4"
echo "   - companion-computer: 10.13.0.3" 
echo "   - flight-controller: 10.13.0.2"
echo "   - simulator: 10.13.0.5"
echo ""
echo "🎯 Goal: Achieve supply chain compromise and crash the drone"
echo "📁 Check /home/developer/Documents/ for hints"
echo "🏁 Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}"
echo ""
echo "🔑 Connecting as developer user..."
echo "   (You are now in an interactive shell as 'developer')"
echo ""

# Connect to the developer machine as the developer user
docker exec -it -u developer dvd-developer-machine bash -c "
cd /home/developer
echo 'Welcome to the DVD CTF Environment!'
echo 'Type \"ls Documents/\" to see available hints'
echo ''
exec bash -l
"