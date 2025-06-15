#!/bin/bash

LOG_FILE="/var/log/infrastructure-restart-service.log"
CHECKSUM_FILE="/tmp/sourcecode-checksum.txt"
DOCKERFILE_CHECKSUM_FILE="/tmp/dockerfile-checksum.txt"
SOURCECODE_DIR="/sourcecode"
SHARED_BUILDS_DIR="/opt/shared-builds"
LOCK_FILE="/tmp/infrastructure-restart.lock"
LOCK_TIMEOUT=300  # 5 minutes
RESTART_TIMEOUT=30
BUILD_TIMEOUT=180  # 3 minutes (reduced from 5)

# Define containers to restart
CONTAINERS=(
    "ground-control-station"
    "simulator" 
    "flight-controller"
    "companion-computer"
    "qgc-container"
)

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFRA-RESTART] $1" | tee -a "$LOG_FILE"
}

# Check for existing process lock with timeout
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)))
    
    if [ "$LOCK_AGE" -gt "$LOCK_TIMEOUT" ]; then
        log_message "⏰ Lock file is stale (${LOCK_AGE}s old), killing stuck process (PID: $LOCK_PID)"
        kill -9 "$LOCK_PID" 2>/dev/null || true
        rm -f "$LOCK_FILE"
    else
        log_message "Another infrastructure restart process is already running (PID: $LOCK_PID, ${LOCK_AGE}s old), exiting"
        exit 0
    fi
fi

# Cleanup stuck processes
cleanup_stuck_processes() {
    log_message "🧹 Performing stuck process cleanup..."
    # Kill any stuck docker build processes older than 30 minutes
    pkill -f "docker build" -P $$ 2>/dev/null || true
    # Kill stuck rsync processes
    pkill -f "rsync.*$SHARED_BUILDS_DIR" 2>/dev/null || true
    log_message "✅ Stuck process cleanup completed"
}

# Create lock file
echo $$ > "$LOCK_FILE"
cleanup_stuck_processes

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "Infrastructure restart process cleanup completed"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

log_message "=== DVD Infrastructure Restart Service Started (PID: $$) ==="

# Function to check if sourcecode directory has changes
check_sourcecode_changes() {
    log_message "Checking for changes in $SOURCECODE_DIR..."
    
    if [ ! -d "$SOURCECODE_DIR" ]; then
        log_message "❌ Sourcecode directory not found: $SOURCECODE_DIR"
        return 1
    fi
    
    # Calculate current checksum
    CURRENT_CHECKSUM=$(find "$SOURCECODE_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.cpp" -o -name "*.h" -o -name "*.c" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.txt" -o -name "*.md" -o -name "Dockerfile*" \) -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
    log_message "Current sourcecode checksum: $CURRENT_CHECKSUM"
    
    # Check if previous checksum exists
    if [ -f "$CHECKSUM_FILE" ]; then
        PREVIOUS_CHECKSUM=$(cat "$CHECKSUM_FILE")
        log_message "Previous sourcecode checksum: $PREVIOUS_CHECKSUM"
        
        if [ "$CURRENT_CHECKSUM" = "$PREVIOUS_CHECKSUM" ]; then
            log_message "ℹ No changes detected in sourcecode directory, skipping restart"
            return 1
        else
            log_message "✅ Changes detected in sourcecode directory"
        fi
    else
        log_message "No previous checksum found, creating initial checksum"
    fi
    
    # Save current checksum
    echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
    return 0
}

# Function to check if Dockerfiles have changed
check_dockerfile_changes() {
    # Calculate current Dockerfile checksum
    CURRENT_DOCKERFILE_CHECKSUM=$(find "$SOURCECODE_DIR" -name "Dockerfile*" -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
    
    # Check if previous Dockerfile checksum exists
    if [ -f "$DOCKERFILE_CHECKSUM_FILE" ]; then
        PREVIOUS_DOCKERFILE_CHECKSUM=$(cat "$DOCKERFILE_CHECKSUM_FILE")
        
        if [ "$CURRENT_DOCKERFILE_CHECKSUM" != "$PREVIOUS_DOCKERFILE_CHECKSUM" ]; then
            log_message "🐳 Dockerfile changes detected - will perform rebuilds"
            echo "$CURRENT_DOCKERFILE_CHECKSUM" > "$DOCKERFILE_CHECKSUM_FILE"
            return 0
        fi
    else
        log_message "🐳 No previous Dockerfile checksum found - will perform rebuilds"
        echo "$CURRENT_DOCKERFILE_CHECKSUM" > "$DOCKERFILE_CHECKSUM_FILE"
        return 0
    fi
    
    return 1
}

# Function to copy sourcecode to shared builds
copy_sourcecode_to_shared_builds() {
    log_message "📦 Copying source code files to shared builds directory..."
    
    # Create shared builds directory if it doesn't exist
    mkdir -p "$SHARED_BUILDS_DIR"
    
    # Use rsync for faster copying if available, otherwise use cp
    if command -v rsync >/dev/null 2>&1; then
        if timeout 60 rsync -av --delete "$SOURCECODE_DIR/" "$SHARED_BUILDS_DIR/" >/dev/null 2>&1; then
            log_message "✅ Successfully copied source code to shared builds"
        else
            log_message "❌ Failed to copy source code with rsync, trying cp..."
            if timeout 60 cp -r "$SOURCECODE_DIR/"* "$SHARED_BUILDS_DIR/" 2>/dev/null; then
                log_message "✅ Successfully copied source code to shared builds with cp"
            else
                log_message "❌ Failed to copy source code to shared builds"
                return 1
            fi
        fi
    else
        if timeout 60 cp -r "$SOURCECODE_DIR/"* "$SHARED_BUILDS_DIR/" 2>/dev/null; then
            log_message "✅ Successfully copied source code to shared builds"
        else
            log_message "❌ Failed to copy source code to shared builds"
            return 1
        fi
    fi
    
    # Set executable permissions on scripts
    find "$SHARED_BUILDS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    log_message "🔧 Set executable permissions on copied files"
    
    return 0
}

# Function to start container with direct docker run
start_container_direct() {
    local container_name="$1"
    local compose_project="dvds-supplychain-challenge"
    local image_name="${compose_project}_${container_name}:latest"
    
    log_message "🐳 Starting $container_name with direct docker run..."
    
    # Container-specific docker run commands
    case "$container_name" in
        "ground-control-station")
            timeout 30 docker run -d --name "$container_name" \
                --privileged \
                -p 8080:8080 \
                -v shared-builds:/opt/shared-builds \
                "$image_name" 2>/dev/null
            ;;
        "simulator")
            timeout 30 docker run -d --name "$container_name" \
                --privileged \
                -p 8000:8000 \
                -v shared-builds:/opt/shared-builds \
                "$image_name" 2>/dev/null
            ;;
        "flight-controller")
            timeout 30 docker run -d --name "$container_name" \
                --privileged \
                -v shared-builds:/opt/shared-builds \
                "$image_name" 2>/dev/null
            ;;
        "companion-computer")
            timeout 30 docker run -d --name "$container_name" \
                --privileged \
                -p 3000:3000 \
                -v shared-builds:/opt/shared-builds \
                "$image_name" 2>/dev/null
            ;;
        "qgc-container")
            timeout 30 docker run -d --name "$container_name" \
                --privileged \
                -e DISPLAY=${DISPLAY} \
                -v /tmp/.X11-unix:/tmp/.X11-unix \
                -v shared-builds:/opt/shared-builds \
                "$image_name" 2>/dev/null
            ;;
        *)
            timeout 30 docker run -d --name "$container_name" \
                "$image_name" 2>/dev/null
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log_message "✅ Container $container_name started with direct docker run"
        return 0
    else
        log_message "❌ Failed to start $container_name with direct docker run"
        return 1
    fi
}

# Function to rebuild a container with Dockerfile
rebuild_container() {
    local container_name="$1"
    local compose_project="dvds-supplychain-challenge"
    
    log_message "🐳 Dockerfile detected for $container_name - initiating complete rebuild"
    
    # Stop and remove existing container
    log_message "🛑 Stopping and removing existing $container_name container..."
    timeout 30 docker stop "$compose_project"_"$container_name"_1 2>/dev/null || \
    timeout 30 docker stop "${compose_project}_${container_name}_1" 2>/dev/null || \
    timeout 30 docker stop "$container_name" 2>/dev/null || true
    
    timeout 30 docker rm "$compose_project"_"$container_name"_1 2>/dev/null || \
    timeout 30 docker rm "${compose_project}_${container_name}_1" 2>/dev/null || \
    timeout 30 docker rm "$container_name" 2>/dev/null || true
    
    log_message "✅ Existing $container_name container removed"
    
    # Remove old image to force rebuild
    log_message "🗑 Removing old $container_name image to force rebuild..."
    docker rmi "${compose_project}_${container_name}:latest" 2>/dev/null || \
    docker rmi "${compose_project}_${container_name}" 2>/dev/null || true
    log_message "✅ Old image removed"
    
    # Build new image with reduced timeout
    log_message "🔨 Building new $container_name image from updated Dockerfile..."
    local dockerfile_path="$SHARED_BUILDS_DIR/$container_name/Dockerfile"
    
    if [ -f "$dockerfile_path" ]; then
        local build_cmd="docker build --no-cache -t ${compose_project}_${container_name}:latest -f $dockerfile_path $SHARED_BUILDS_DIR"
        log_message "Building image: $build_cmd"
        
        # Use timeout to prevent builds from hanging
        local build_start=$(date +%s)
        local build_pid
        
        timeout "$BUILD_TIMEOUT" bash -c "$build_cmd" &
        build_pid=$!
        
        # Monitor build progress
        while kill -0 "$build_pid" 2>/dev/null; do
            local elapsed=$(($(date +%s) - build_start))
            log_message "Building $container_name... (${elapsed}s elapsed)"
            sleep 10
        done
        
        wait "$build_pid"
        local build_result=$?
        
        if [ "$build_result" -eq 0 ]; then
            log_message "✅ Successfully built new $container_name image with updated Dockerfile"
            
            # Start new container with multiple methods
            log_message "🚀 Starting new $container_name container with rebuilt image..."
            
            # Method 1: Try docker-compose if available
            if [ -f "/opt/shared-builds/docker-compose.yml" ]; then
                if timeout 30 docker-compose -f /opt/shared-builds/docker-compose.yml up -d "$container_name" 2>/dev/null; then
                    log_message "✅ Container $container_name started with docker-compose"
                else
                    log_message "⚠️ Docker-compose failed, trying direct docker run..."
                    start_container_direct "$container_name"
                fi
            else
                log_message "📋 No docker-compose.yml found, using direct docker run..."
                start_container_direct "$container_name"
            fi
            
            # Verify container is running
            sleep 3
            if docker ps | grep -q "$container_name"; then
                log_message "✅ Verified: $container_name is running with new image"
                log_message "🎉 New $container_name container started successfully with updated Dockerfile"
                return 0
            else
                log_message "⚠️ Warning: $container_name may not be running properly"
                return 1
            fi
        else
            local elapsed=$(($(date +%s) - build_start))
            if [ "$elapsed" -ge "$BUILD_TIMEOUT" ]; then
                log_message "⏰ Build timeout reached for $container_name, killing build process"
            fi
            log_message "❌ Failed to build new $container_name image from updated Dockerfile"
            log_message "Build log: $(docker logs $(docker ps -lq) 2>&1 | tail -5 | tr '\n' ' ')"
            
            # Try to start with previous image as fallback
            log_message "🔄 Attempting to start with previous image as fallback..."
            if timeout 30 docker-compose -f /opt/shared-builds/docker-compose.yml up -d "$container_name" 2>/dev/null; then
                log_message "✅ Container $container_name started with fallback image"
                return 0
            else
                log_message "❌ Failed to start container $container_name"
                return 1
            fi
        fi
    else
        log_message "❌ Dockerfile not found at $dockerfile_path"
        return 1
    fi
}

# Function to rebuild a container with Dockerfile
rebuild_container() {
    local container_name="$1"
    local compose_project="dvds-supplychain-challenge"
    
    log_message "🐳 Dockerfile detected for $container_name - initiating complete rebuild"
    
    # Stop and remove existing container
    log_message "🛑 Stopping and removing existing $container_name container..."
    timeout 30 docker stop "$container_name" 2>/dev/null || true
    timeout 30 docker rm "$container_name" 2>/dev/null || true
    log_message "✅ Existing $container_name container removed"
    
    # Remove old image to force rebuild
    log_message "🗑 Removing old $container_name image to force rebuild..."
    docker rmi "${compose_project}_${container_name}:latest" 2>/dev/null || true
    log_message "✅ Old image removed"
    
    # Build new image with timeout
    log_message "🔨 Building new $container_name image from updated Dockerfile..."
    local dockerfile_path="$SHARED_BUILDS_DIR/$container_name/Dockerfile"
    
    if [ -f "$dockerfile_path" ]; then
        local build_cmd="docker build --no-cache -t ${compose_project}_${container_name}:latest -f $dockerfile_path $SHARED_BUILDS_DIR"
        log_message "Building image: $build_cmd"
        
        # Use timeout to prevent builds from hanging
        local build_start=$(date +%s)
        
        # Run build in background and monitor
        timeout "$BUILD_TIMEOUT" bash -c "$build_cmd" >/dev/null 2>&1 &
        local build_pid=$!
        
        # Monitor build progress
        while kill -0 "$build_pid" 2>/dev/null; do
            local elapsed=$(($(date +%s) - build_start))
            log_message "Building $container_name... (${elapsed}s elapsed)"
            sleep 10
        done
        
        wait "$build_pid"
        local build_result=$?
        
        if [ "$build_result" -eq 0 ]; then
            log_message "✅ Successfully built new $container_name image with updated Dockerfile"
            
            # Start new container with multiple methods
            log_message "🚀 Starting new $container_name container with rebuilt image..."
            
            # Method 1: Try docker-compose if available
            if [ -f "/opt/shared-builds/docker-compose.yml" ]; then
                if timeout 30 docker-compose -f /opt/shared-builds/docker-compose.yml up -d "$container_name" 2>/dev/null; then
                    log_message "✅ Container $container_name started with docker-compose"
                else
                    log_message "⚠️ Docker-compose failed, trying direct docker run..."
                    start_container_direct "$container_name"
                fi
            else
                log_message "📋 No docker-compose.yml found, using direct docker run..."
                start_container_direct "$container_name"
            fi
            
            # Verify container is running
            sleep 3
            if docker ps | grep -q "$container_name"; then
                log_message "✅ Verified: $container_name is running with new image"
                log_message "🎉 New $container_name container started successfully with updated Dockerfile"
                return 0
            else
                log_message "⚠️ Warning: $container_name may not be running properly"
                return 1
            fi
        else
            local elapsed=$(($(date +%s) - build_start))
            if [ "$elapsed" -ge "$BUILD_TIMEOUT" ]; then
                log_message "⏰ Build timeout reached for $container_name, killing build process"
            fi
            log_message "❌ Failed to build new $container_name image from updated Dockerfile"
            
            # Try to start with previous image as fallback
            log_message "🔄 Attempting to start with previous image as fallback..."
            start_container_direct "$container_name"
            return 1
        fi
    else
        log_message "❌ Dockerfile not found at $dockerfile_path"
        return 1
    fi
}

# Function to fast restart a container (no rebuild)
fast_restart_container() {
    local container_name="$1"
    
    log_message "⚡ Fast restarting $container_name..."
    
    # Try restart first (fastest)
    if timeout "$RESTART_TIMEOUT" docker restart "$container_name" 2>/dev/null || \
       timeout "$RESTART_TIMEOUT" docker restart "dvds-supplychain-challenge_${container_name}_1" 2>/dev/null || \
       timeout "$RESTART_TIMEOUT" docker restart "${container_name}_1" 2>/dev/null; then
        log_message "✅ Fast restart successful for $container_name"
        return 0
    fi
    
    # If restart fails, try stop/start
    log_message "🔄 Fast restart failed, trying stop/start for $container_name..."
    
    timeout 15 docker stop "$container_name" 2>/dev/null || \
    timeout 15 docker stop "dvds-supplychain-challenge_${container_name}_1" 2>/dev/null || \
    timeout 15 docker stop "${container_name}_1" 2>/dev/null || true
    
    sleep 1
    
    if timeout 15 docker start "$container_name" 2>/dev/null || \
       timeout 15 docker start "dvds-supplychain-challenge_${container_name}_1" 2>/dev/null || \
       timeout 15 docker start "${container_name}_1" 2>/dev/null; then
        log_message "✅ Stop/start successful for $container_name"
        return 0
    fi
    
    log_message "❌ Failed to restart $container_name"
    return 1
}

# Function to fast restart a container (no rebuild)
fast_restart_container() {
    local container_name="$1"
    
    log_message "⚡ Fast restarting $container_name..."
    
    # Try restart first (fastest)
    if timeout "$RESTART_TIMEOUT" docker restart "$container_name" 2>/dev/null; then
        log_message "✅ Fast restart successful for $container_name"
        return 0
    fi
    
    # If restart fails, try stop/start
    log_message "🔄 Fast restart failed, trying stop/start for $container_name..."
    
    timeout 15 docker stop "$container_name" 2>/dev/null || true
    sleep 1
    
    if timeout 15 docker start "$container_name" 2>/dev/null; then
        log_message "✅ Stop/start successful for $container_name"
        return 0
    fi
    
    log_message "❌ Failed to restart $container_name"
    return 1
}

# Function to restart all containers (smart mode)
restart_all_containers() {
    local dockerfile_changed=$1
    
    for container in "${CONTAINERS[@]}"; do
        if [ "$dockerfile_changed" = "true" ] && [ -f "$SHARED_BUILDS_DIR/$container/Dockerfile" ]; then
            # Dockerfile exists and has changed - do full rebuild
            rebuild_container "$container"
        else
            # No Dockerfile changes - do fast restart
            fast_restart_container "$container"
        fi
        
        # Small delay between container operations
        sleep 1
    done
}

# Function to restart all containers (smart mode)
restart_all_containers() {
    local dockerfile_changed=$1
    
    log_message "🚀 Starting container restart sequence (dockerfile_changed: $dockerfile_changed)"
    
    for container in "${CONTAINERS[@]}"; do
        if [ "$dockerfile_changed" = "true" ] && [ -f "$SHARED_BUILDS_DIR/$container/Dockerfile" ]; then
            # Dockerfile exists and has changed - do full rebuild
            log_message "🐳 Container $container has Dockerfile changes - rebuilding"
            rebuild_container "$container"
        else
            # No Dockerfile changes - do fast restart
            log_message "⚡ Container $container - performing fast restart"
            fast_restart_container "$container"
        fi
        
        # Small delay between container operations
        sleep 2
    done
    
    # Final health check
    log_message "🏥 Performing final health check..."
    local running_count=0
    for container in "${CONTAINERS[@]}"; do
        if docker ps | grep -q "$container"; then
            ((running_count++))
            log_message "✅ $container is running"
        else
            log_message "❌ $container is not running"
        fi
    done
    
    log_message "🎯 Health check complete: $running_count/${#CONTAINERS[@]} containers running"
}

# Function to deploy updated modules (simplified)
deploy_updated_modules() {
    log_message "🚀 Deploying updated modules..."
    
    # Copy any additional deployment scripts or configs
    if [ -d "$SHARED_BUILDS_DIR/scripts" ]; then
        cp -r "$SHARED_BUILDS_DIR/scripts/"* /usr/local/bin/ 2>/dev/null || true
    fi
    
    log_message "✅ Module deployment completed"
}

# Main execution
log_message "=== DVD Infrastructure Restart Service Started ==="

# Check for sourcecode changes
if ! check_sourcecode_changes; then
    log_message "No sourcecode changes detected, exiting without restart"
    exit 0
fi

log_message "Sourcecode changes detected, proceeding with infrastructure restart..."

# Copy source code
if ! copy_sourcecode_to_shared_builds; then
    log_message "❌ Failed to copy source code, exiting"
    exit 1
fi

# Check if Dockerfiles have changed
dockerfile_changed="false"
if check_dockerfile_changes; then
    dockerfile_changed="true"
    log_message "📦 Will perform Docker rebuilds for containers with updated Dockerfiles"
else
    log_message "⚡ No Dockerfile changes - will perform fast restarts only"
fi

# Restart all containers (smart mode)
restart_all_containers "$dockerfile_changed"

# Deploy modules
deploy_updated_modules

if [ "$dockerfile_changed" = "true" ]; then
    log_message "🎉 Infrastructure restart with Docker rebuilds completed"
else
    log_message "⚡ Fast infrastructure restart completed"
fi

exit 0