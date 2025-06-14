#!/bin/bash

# DVD Developer Machine Entrypoint Script
# This script initializes the development environment

echo "🚁 DVD Developer Machine Starting..."

# Start cron service
echo "Starting cron service..."
service cron start

# Ensure all required directories exist
echo "Creating required directories..."
mkdir -p /builds /opt/shared-builds /sourcecode /home/developer/src /home/developer/modules /home/developer/config

# Set proper permissions
chmod 755 /builds /opt/shared-builds /sourcecode
chown -R developer:developer /home/developer

# Create initial RTL module if it doesn't exist
if [ ! -f /builds/return-to-land.py ]; then
    echo "Creating initial RTL module..."
    cat > /builds/return-to-land.py << 'EOF'
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
    chmod +x /builds/return-to-land.py
    chown developer:developer /builds/return-to-land.py
fi

# Show active cron jobs
echo "Active cron jobs:"
ls -la /etc/cron.d/

# Run initial build pipeline
echo "Running initial build pipeline..."
/bin/build-update.sh

echo "✅ DVD Developer Machine initialized successfully!"
echo ""
echo "Available directories:"
echo "- /sourcecode/ - Place files here for automatic deployment"
echo "- /opt/shared-builds/ - Deployment target"
echo "- /builds/ - Build artifacts"
echo ""
echo "Active services:"
echo "- Source monitor: Runs every minute"
echo "- Build pipeline: Runs every 2 minutes"
echo ""

# Keep container running
exec "$@"