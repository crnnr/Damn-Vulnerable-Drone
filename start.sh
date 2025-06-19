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
        hash+=$(find ./flight-controller -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    fi
    if [ -d "./ground-control-station" ]; then
        hash+=$(find ./ground-control-station -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    fi
    echo "$hash" | sha256sum | cut -d' ' -f1
}

# Calculate remote hashes for target folders
calculate_remote_hash() {
    local hash=""
    hash+=$(docker exec dvd-developer-machine find /sourcecode/flight-controller -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    hash+=$(docker exec dvd-developer-machine find /sourcecode/ground-control-station -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
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
    for ((i=1; i<=60; i++)); do
        # Calculate current remote hash
        CURRENT_REMOTE_HASH=$(calculate_remote_hash)
        
        # Only copy if remote hash changed
        if [ "$CURRENT_REMOTE_HASH" != "$REMOTE_HASH" ]; then
            echo "📊 Remote hash changed! Copying files..."
            docker cp dvd-developer-machine:/sourcecode/. .
            REMOTE_HASH=$CURRENT_REMOTE_HASH
            LOCAL_HASH=$(calculate_local_hash)
            echo "📊 Updated local hash: $LOCAL_HASH"
            echo "📊 Updated remote hash: $REMOTE_HASH"
            echo "📦 Files copied successfully!"
            
            # Restart containers after copying changes
            echo "🔄 Rebuilding and restarting containers after code changes..."
            
            # Stop and clean up docker-compose containers
            docker-compose down 2>/dev/null || true

            # Clean up other containers and networks
            docker container rm -f simulator qgc-container flight-controller companion-computer ground-control-station 2>/dev/null || true
            docker network rm damn-vulnerable-drone_default 2>/dev/null || true
            docker network rm simulator 2>/dev/null || true

            echo "📦 Building and starting containers (forcing rebuild)..."
            docker-compose up -d --build --remove-orphans

            echo "✅ Containers rebuilt and restarted successfully!"
        fi
        
        if [ $i -lt 60 ]; then
            sleep 60
        fi
    done
} &
clear

docker exec -it -u developer dvd-developer-machine /bin/bash