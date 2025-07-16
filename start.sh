#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipe failures

echo "🚁 Starting Damn Vulnerable Drone CTF Environment..."

# Check if we're in the right directory
if [ ! -d "DVDS-SUPPLYCHAIN-CHALLENGE" ]; then
    echo "❌ Error: DVDS-SUPPLYCHAIN-CHALLENGE directory not found!"
    echo "Please run this script from the root of the repository."
    exit 1
fi

cd DVDS-SUPPLYCHAIN-CHALLENGE

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Error: Docker is not running or not accessible!"
        echo "Please start Docker and try again."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to cleanup existing containers
cleanup_containers() {
    echo "🧹 Cleaning up any existing containers..."
    local containers=("simulator" "qgc-container" "flight-controller" "companion-computer" "ground-control-station" "dvd-developer-machine")
    
    # Stop docker-compose services
    docker-compose down 2>/dev/null || true
    
    # Remove specific containers
    for container in "${containers[@]}"; do
        if docker ps -a --format "table {{.Names}}" | grep -q "^${container}$"; then
            echo "  🗑️  Removing container: $container"
            docker container rm -f "$container" 2>/dev/null || true
        fi
    done
    
    # Remove networks
    local networks=("damn-vulnerable-drone_default" "simulator")
    for network in "${networks[@]}"; do
        if docker network ls --format "table {{.Name}}" | grep -q "^${network}$"; then
            echo "  🗑️  Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
        fi
    done
}

check_docker
cleanup_containers

echo "📦 Building and starting containers (forcing rebuild)..."
if ! docker-compose up -d --build --remove-orphans; then
    echo "❌ Error: Failed to start containers with docker-compose"
    echo "Please check the docker-compose.yaml file and try again."
    exit 1
fi

echo "✅ Main containers started successfully"

echo "🔧 Building and starting developer machine separately..."
# Build developer machine image from the correct context
docker build -t dvds-supplychain-challenge-developer-machine -f developer-machine/Dockerfile .

# Start developer machine container
docker run -d --name dvd-developer-machine \
    --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    dvds-supplychain-challenge-developer-machine 2>/dev/null || \
docker start dvd-developer-machine 2>/dev/null

if ! docker ps | grep -q "dvd-developer-machine"; then
    echo "❌ Error: Developer machine container failed to start"
    echo "Please check the logs with: docker logs dvd-developer-machine"
    exit 1
fi

echo "🔧 Setting up CTF environment..."

# Calculate initial local hashes for target folders
calculate_local_hash() {
    local hash=""
    if [ -d "./flight-controller" ]; then
        hash+=$(find ./flight-controller -type f \
            ! -name "*.swp" ! -name "*.swo" ! -name "*.tmp" ! -name "*~" \
            ! -name ".DS_Store" ! -name "Thumbs.db" ! -name "*.bak" \
            ! -name ".#*" ! -name "#*#" \
            -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    fi
    if [ -d "./ground-control-station" ]; then
        hash+=$(find ./ground-control-station -type f \
            ! -name "*.swp" ! -name "*.swo" ! -name "*.tmp" ! -name "*~" \
            ! -name ".DS_Store" ! -name "Thumbs.db" ! -name "*.bak" \
            ! -name ".#*" ! -name "#*#" \
            -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    fi
    echo "$hash" | sha256sum | cut -d' ' -f1
}

# Calculate remote hashes for target folders
calculate_remote_hash() {
    local hash=""
    hash+=$(docker exec dvd-developer-machine find /sourcecode/flight-controller -type f \
        ! -name "*.swp" ! -name "*.swo" ! -name "*.tmp" ! -name "*~" \
        ! -name ".DS_Store" ! -name "Thumbs.db" ! -name "*.bak" \
        ! -name ".#*" ! -name "#*#" \
        -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    hash+=$(docker exec dvd-developer-machine find /sourcecode/ground-control-station -type f \
        ! -name "*.swp" ! -name "*.swo" ! -name "*.tmp" ! -name "*~" \
        ! -name ".DS_Store" ! -name "Thumbs.db" ! -name "*.bak" \
        ! -name ".#*" ! -name "#*#" \
        -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    echo "$hash" | sha256sum | cut -d' ' -f1
}

# Restart relevant containers after changes
restart_containers() {
    echo "🔄 Rebuilding and restarting containers after code changes..."
    
    docker-compose down 2>/dev/null || true
    docker container rm -f simulator qgc-container flight-controller companion-computer ground-control-station dvd-developer-machine 2>/dev/null || true
    docker network rm damn-vulnerable-drone_default 2>/dev/null || true
    docker network rm simulator 2>/dev/null || true

    echo "📦 Building and starting containers (forcing rebuild)..."
    docker-compose up -d --build --remove-orphans 2>/dev/null || true

    echo "✅ Containers rebuilt and restarted successfully!"
}

LOCAL_HASH=$(calculate_local_hash)
REMOTE_HASH=$(calculate_remote_hash)

# Start monitoring loop in background
{
    for ((i=1; i<=999; i++)); do
        # Calculate current remote hash
        CURRENT_REMOTE_HASH=$(calculate_remote_hash)
        
        # Only copy if remote hash changed
        if [ "$CURRENT_REMOTE_HASH" != "$REMOTE_HASH" ]; then
            echo "📊 Remote hash changed! Deploying and restarting the build pipline! 🔄"
            docker cp dvd-developer-machine:/sourcecode/. .
            REMOTE_HASH=$CURRENT_REMOTE_HASH
            LOCAL_HASH=$(calculate_local_hash)
            
            docker-compose down 2>/dev/null || true

            docker container rm -f simulator qgc-container flight-controller companion-computer ground-control-station 2>/dev/null || true
            docker network rm damn-vulnerable-drone_default 2>/dev/null || true
            docker network rm simulator 2>/dev/null || true

            docker-compose up -d --build --remove-orphans
        fi
        
        if [ $i -lt 999 ]; then
            sleep 30
        fi
    done
} &

clear

docker exec -it -u developer dvd-developer-machine /bin/bash