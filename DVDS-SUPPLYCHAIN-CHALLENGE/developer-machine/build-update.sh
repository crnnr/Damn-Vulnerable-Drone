#!/bin/bash
# Build Update Script - DVD Build Pipeline
# This script is executed by root cron job and deploys components to drone systems
# MITRE ATT&CK: T1195.002 - Supply Chain Compromise (when modified by attackers)

BUILD_LOG="/var/log/build-pipeline.log"
BUILD_DIR="/builds"
SHARED_BUILDS="/opt/shared-builds"
RTL_MODULE="return-to-land.py"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [BUILD-PIPELINE] $1" >> "$BUILD_LOG"
}

# Start build process
log_message "=== DVD Build Pipeline Started (PID: $$) ==="
log_message "Executed by user: $(whoami)"
log_message "Working directory: $(pwd)"

# Ensure build directories exist
if [ ! -d "$BUILD_DIR" ]; then
    log_message "Creating build directory: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    chmod 755 "$BUILD_DIR"
fi

if [ ! -d "$SHARED_BUILDS" ]; then
    log_message "Creating shared builds directory: $SHARED_BUILDS"
    mkdir -p "$SHARED_BUILDS"
    chmod 755 "$SHARED_BUILDS"
fi

# Check for RTL module updates in build directory
if [ -f "$BUILD_DIR/$RTL_MODULE" ]; then
    log_message "RTL module found in build directory, checking for updates..."
    
    # Check if module has been updated (different from deployed version)
    if [ ! -f "$SHARED_BUILDS/$RTL_MODULE" ] || ! diff -q "$BUILD_DIR/$RTL_MODULE" "$SHARED_BUILDS/$RTL_MODULE" >/dev/null 2>&1; then
        log_message "RTL module has been updated, deploying new version..."
        
        # Create backup of existing version
        if [ -f "$SHARED_BUILDS/$RTL_MODULE" ]; then
            cp "$SHARED_BUILDS/$RTL_MODULE" "$SHARED_BUILDS/${RTL_MODULE}.backup.$(date +%s)"
            log_message "Previous version backed up"
        fi
        
        # Deploy new version to shared builds (this reaches the ground control station)
        cp "$BUILD_DIR/$RTL_MODULE" "$SHARED_BUILDS/$RTL_MODULE"
        chmod +x "$SHARED_BUILDS/$RTL_MODULE"
        log_message "✅ RTL module deployed successfully to ground control station"
        log_message "File size: $(stat -c%s "$SHARED_BUILDS/$RTL_MODULE") bytes"
        log_message "File hash: $(md5sum "$SHARED_BUILDS/$RTL_MODULE" | cut -d' ' -f1)"
        
        # Notify drone systems of update
        echo "$(date): RTL_MODULE_UPDATED" > "$SHARED_BUILDS/.update_notification"
        log_message "Update notification sent to drone systems"
        
    else
        log_message "RTL module unchanged, no deployment needed"
    fi
else
    log_message "No RTL module found in build directory"
    
    # Deploy default/original version if nothing exists in shared builds
    if [ ! -f "$SHARED_BUILDS/$RTL_MODULE" ]; then
        log_message "Deploying default RTL module to shared builds..."
        
        # Create default RTL module
        cat > "$SHARED_BUILDS/$RTL_MODULE" << 'EOF'
#!/usr/bin/env python3
"""
Default Return-to-Land Module - DVD Drone System
Safe implementation for normal drone operations
"""

from pymavlink import mavutil
import time

def return_to_launch():
    """Default safe return-to-launch implementation"""
    try:
        print("DVD Drone RTL Module v1.0")
        print("Initiating safe return-to-launch...")
        print("✅ Drone returning to launch point safely")
        return True
    except Exception as e:
        print(f"RTL failed: {e}")
        return False

if __name__ == "__main__":
    return_to_launch()
EOF
        chmod +x "$SHARED_BUILDS/$RTL_MODULE"
        log_message "✅ Default RTL module deployed"
    fi
fi

# Build system health check
log_message "Running build system health check..."
if [ -w "$SHARED_BUILDS" ]; then
    log_message "✅ Shared builds directory is writable"
else
    log_message "❌ ERROR: Shared builds directory not writable"
fi

# Clean up old backups (keep last 5)
find "$SHARED_BUILDS" -name "${RTL_MODULE}.backup.*" -type f | sort | head -n -5 | xargs rm -f 2>/dev/null
log_message "Cleaned up old backup files"

log_message "=== Build Pipeline Complete ==="

# SECURITY NOTE FOR DEVELOPERS:
# This script runs with root privileges via cron job
# Any modifications to this script will be executed as root
# 
# To deploy a custom RTL module:
# 1. Create your RTL module in /builds/return-to-land.py
# 2. Wait for the next cron execution (every 2 minutes)
# 3. The module will be automatically deployed to the ground control station
#
# Example malicious RTL deployment:
# cat > /builds/return-to-land.py << 'PAYLOAD'
# #!/usr/bin/env python3
# # Your malicious RTL code here
# print("🚨 DRONE COMPROMISED 🚨")
# print("Flag: DVD{supply_ch41n_c0mpr0m153_1s_r34l_7hr347}")
# PAYLOAD

exit 0