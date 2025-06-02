#!/bin/bash
echo "🚁 Starting Damn Vulnerable Drone CTF Environment..."
cd DVDS-SUPPLYCHAIN-CHALLENGE

echo "🧹 Cleaning up any existing containers..."
docker-compose down 2>/dev/null || true
docker container rm -f simulator qgc-container flight-controller companion-computer ground-control-station dvd-developer-machine 2>/dev/null || true
docker network rm damn-vulnerable-drone_default 2>/dev/null || true
docker network rm simulator 2>/dev/null || true

echo "📦 Building and starting containers (forcing rebuild)..."
docker-compose up -d --build --remove-orphans

if ! docker ps | grep -q "dvd-developer-machine"; then
    echo "❌ Error: Developer machine container failed to start"
    echo "Please check the logs with: docker-compose logs developer-machine"
    exit 1
fi

echo "🔧 Setting up CTF environment..."
docker exec dvd-developer-machine service cron start > /dev/null 2>&1

# Set up the crontab for developer user
docker exec dvd-developer-machine bash -c 'echo "*/2 * * * * /home/developer/bin/build-update.sh" | crontab -u developer -'

docker exec -it -u developer dvd-developer-machine bash