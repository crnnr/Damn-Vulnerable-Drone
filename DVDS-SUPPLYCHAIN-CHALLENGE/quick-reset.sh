#!/bin/bash

# Quick Infrastructure Reset - Emergency Fix

echo "🚨 Quick Infrastructure Reset"
echo "============================="

# Kill any stuck processes
echo "1. Killing stuck processes..."
pkill -f "docker build" 2>/dev/null
pkill -f "restart-gcs-service" 2>/dev/null

# Remove lock files
rm -f /tmp/infrastructure-restart.lock
rm -f /tmp/sourcecode-checksum.txt

# Stop and remove all DVD containers (except developer machine)
echo "2. Stopping containers..."
containers=("ground-control-station" "simulator" "flight-controller" "companion-computer" "qgc-container")

for container in "${containers[@]}"; do
    docker stop "$container" 2>/dev/null
    docker rm "$container" 2>/dev/null
    echo "   ✅ Stopped $container"
done

# Clean up orphaned containers with random names
docker ps -a --format "{{.Names}}" | grep -E "(laughing_|vigorous_|eager_|amazing_|cranky_)" | while read container; do
    docker stop "$container" 2>/dev/null
    docker rm "$container" 2>/dev/null
    echo "   🗑️ Removed orphaned: $container"
done

# Remove dangling images
echo "3. Cleaning images..."
docker image prune -f >/dev/null 2>&1

# Restart with docker-compose
echo "4. Restarting infrastructure..."
cd /home/christof/go/github.com/Damn-Vulnerable-Drone/DVDS-SUPPLYCHAIN-CHALLENGE
docker-compose down 2>/dev/null
docker-compose up -d

echo ""
echo "✅ Quick reset complete!"
echo ""
echo "Check status:"
echo "  docker ps"
echo ""
echo "Access simulator:"
echo "  http://localhost:8000"