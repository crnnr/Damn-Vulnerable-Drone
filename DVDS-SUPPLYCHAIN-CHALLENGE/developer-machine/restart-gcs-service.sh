#!/bin/bash

# DVD Infrastructure Restart Service
# This service restarts all drone infrastructure containers every 2 minutes
# Used for supply chain attack demonstration to ensure updated modules are loaded

LOG_FILE="/var/log/infrastructure-restart-service.log"
CHECKSUM_FILE="/tmp/sourcecode-checksum.txt"
SOURCECODE_DIR="/sourcecode"

# Define containers to restart (excluding developer machine)
CONTAINERS=(
    "ground-control-station"
    "simulator" 
    "flight-controller"
    "companion-computer"
    "qgc-container"
)

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFRA-RESTART] $1" >> "$LOG_FILE"
}

# Function to check if sourcecode directory has changes
check_sourcecode_changes() {
    log_message "Checking for changes in $SOURCECODE_DIR..."
    
    # Check if sourcecode directory exists
    if [ ! -d "$SOURCECODE_DIR" ]; then
        log_message "⚠️ Sourcecode directory $SOURCECODE_DIR not found"
        return 1
    fi
    
    # Generate current checksum of all files in sourcecode directory
    local current_checksum
    current_checksum=$(find "$SOURCECODE_DIR" -type f -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
    
    if [ -z "$current_checksum" ]; then
        log_message "⚠️ Could not generate checksum for sourcecode directory"
        return 1
    fi
    
    log_message "Current sourcecode checksum: $current_checksum"
    
    # Check if previous checksum exists
    if [ ! -f "$CHECKSUM_FILE" ]; then
        log_message "No previous checksum found, creating initial checksum"
        echo "$current_checksum" > "$CHECKSUM_FILE"
        return 0  # First run, proceed with restart
    fi
    
    # Read previous checksum
    local previous_checksum
    previous_checksum=$(cat "$CHECKSUM_FILE" 2>/dev/null)
    
    log_message "Previous sourcecode checksum: $previous_checksum"
    
    # Compare checksums
    if [ "$current_checksum" != "$previous_checksum" ]; then
        log_message "✅ Changes detected in sourcecode directory"
        echo "$current_checksum" > "$CHECKSUM_FILE"
        return 0  # Changes found, proceed with restart
    else
        log_message "ℹ️ No changes detected in sourcecode directory, skipping restart"
        return 1  # No changes, skip restart
    fi
}

log_message "=== DVD Infrastructure Restart Service Started ==="

# Check for sourcecode changes before proceeding
if ! check_sourcecode_changes; then
    log_message "No sourcecode changes detected, exiting without restart"
    exit 0
fi

log_message "Sourcecode changes detected, proceeding with infrastructure restart..."

# Function to restart a specific container
restart_container() {
    local container_name="$1"
    log_message "Initiating restart for container: $container_name"
    
    # Check if container exists and is running
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log_message "Container $container_name found, restarting..."
        
        # Restart the container
        docker restart "$container_name" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "✅ Container $container_name restarted successfully"
            return 0
        else
            log_message "❌ Failed to restart container $container_name"
            return 1
        fi
    else
        log_message "⚠️ Container $container_name not found or not running, attempting to start..."
        
        # Try to start it if it's not running
        docker start "$container_name" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "✅ Container $container_name started successfully"
            return 0
        else
            log_message "❌ Failed to start container $container_name"
            return 1
        fi
    fi
}

# Function to restart all infrastructure containers
restart_all_containers() {
    log_message "Starting infrastructure-wide restart sequence..."
    local success_count=0
    local total_count=${#CONTAINERS[@]}
    
    for container in "${CONTAINERS[@]}"; do
        if restart_container "$container"; then
            ((success_count++))
            
            # Wait between restarts to avoid overwhelming the system
            sleep 2
        fi
    done
    
    log_message "Restart sequence completed: $success_count/$total_count containers restarted successfully"
    
    # Special handling for ground control station - deploy modules after restart
    if [[ " ${CONTAINERS[@]} " =~ " ground-control-station " ]]; then
        log_message "Waiting for ground control station to fully initialize..."
        sleep 5
        deploy_updated_modules_to_gcs
    fi
}

# Function to deploy updated modules to the restarted ground control station
deploy_updated_modules_to_gcs() {
    log_message "Checking for module updates to deploy to ground control station..."
    
    # Copy the updated RTL module into the restarted container
    if [ -f "/opt/shared-builds/return-to-land.py" ]; then
        docker exec ground-control-station bash -c "
            if [ -f /opt/shared-builds/return-to-land.py ]; then
                cp /opt/shared-builds/return-to-land.py /return-to-land.py
                chmod +x /return-to-land.py
                echo 'RTL module updated in ground control station'
            fi
        " >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "✅ RTL module successfully deployed to ground control station"
        else
            log_message "⚠️ Failed to deploy RTL module to ground control station"
        fi
    else
        log_message "No RTL module found in shared builds directory"
    fi
    
    # Deploy other critical modules that might need deployment
    local modules=("arm-and-takeoff.py" "autopilot-flight.py" "post-flight-analysis.py")
    
    for module in "${modules[@]}"; do
        if [ -f "/opt/shared-builds/$module" ]; then
            docker exec ground-control-station bash -c "
                if [ -f /opt/shared-builds/$module ]; then
                    cp /opt/shared-builds/$module /$module
                    chmod +x /$module
                fi
            " >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                log_message "✅ Updated $module in ground control station"
            else
                log_message "⚠️ Failed to update $module in ground control station"
            fi
        fi
    done
}

# Function to deploy updated configurations to other containers
deploy_updated_configs() {
    log_message "Deploying updated configurations to infrastructure containers..."
    
    # Deploy to simulator if it has shared builds access
    if docker ps --format "table {{.Names}}" | grep -q "^simulator$"; then
        docker exec simulator bash -c "
            if [ -d /opt/shared-builds ]; then
                # Copy any simulator-specific updates
                if [ -f /opt/shared-builds/simulator-config.json ]; then
                    cp /opt/shared-builds/simulator-config.json /config/simulator-config.json 2>/dev/null
                fi
            fi
        " >/dev/null 2>&1
        log_message "Configuration updates deployed to simulator"
    fi
    
    # Deploy to companion computer if it has shared builds access
    if docker ps --format "table {{.Names}}" | grep -q "^companion-computer$"; then
        docker exec companion-computer bash -c "
            if [ -d /opt/shared-builds ]; then
                # Copy any companion computer updates
                if [ -f /opt/shared-builds/companion-config.json ]; then
                    cp /opt/shared-builds/companion-config.json /config/companion-config.json 2>/dev/null
                fi
            fi
        " >/dev/null 2>&1
        log_message "Configuration updates deployed to companion computer"
    fi
    
    # Deploy to flight controller
    if docker ps --format "table {{.Names}}" | grep -q "^flight-controller$"; then
        docker exec flight-controller bash -c "
            if [ -d /opt/shared-builds ]; then
                # Copy any flight controller updates
                if [ -f /opt/shared-builds/flight-params.txt ]; then
                    cp /opt/shared-builds/flight-params.txt /config/flight-params.txt 2>/dev/null
                fi
            fi
        " >/dev/null 2>&1
        log_message "Configuration updates deployed to flight controller"
    fi
}

# Function to verify infrastructure health after restart
verify_infrastructure_health() {
    log_message "Performing infrastructure health check..."
    
    local healthy_containers=0
    local total_containers=${#CONTAINERS[@]}
    
    # Wait a moment for all containers to fully initialize
    sleep 5
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            # Check if container is responsive
            if docker exec "$container" echo "health-check" >/dev/null 2>&1; then
                log_message "✅ Container $container is healthy and responsive"
                ((healthy_containers++))
            else
                log_message "⚠️ Container $container is running but not responsive"
            fi
        else
            log_message "❌ Container $container is not running"
        fi
    done
    
    log_message "Health check completed: $healthy_containers/$total_containers containers are healthy"
    
    if [ $healthy_containers -eq $total_containers ]; then
        log_message "🎉 All infrastructure containers are healthy"
    else
        log_message "⚠️ Some containers may need attention"
    fi
}

# Main execution
restart_all_containers
deploy_updated_configs
verify_infrastructure_health
log_message "Infrastructure restart service execution complete"

exit 0