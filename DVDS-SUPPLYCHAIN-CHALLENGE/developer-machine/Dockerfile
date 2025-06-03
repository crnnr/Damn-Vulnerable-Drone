# DEVELOPER MACHINE - DAMN VULNERABLE DRONE EDITION
# WARNING: This container contains intentional vulnerabilities for educational purposes
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Create developer user with limited privileges (MITRE: Initial Access)
RUN useradd -m -s /bin/bash developer && \
    echo "developer:dev123" | chpasswd

# Install development tools and dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    curl \
    iproute2 \
    nano \
    vim \
    net-tools \
    iputils-ping \
    python3 \
    python3-pip \
    wget \
    git \
    make \
    g++ \
    expect \
    cron \
    sudo \
    openssh-client \
    build-essential \
    gosu \
    && pip3 install future pymavlink MAVProxy mavsdk \
    && rm -rf /var/lib/apt/lists/*

RUN echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir scripts

# Add developer to sudo group for certain commands (MITRE: Privilege Escalation - Sudo)
RUN usermod -aG sudo developer

# Create CTF directories in root
RUN mkdir -p /Documents /projects /builds /bin

# Create build-update.sh script inline
RUN cat > /bin/build-update.sh << 'EOF'
#!/bin/bash
# Build Update Script - DVD Build System
# This script updates and deploys drone components automatically
# MITRE ATT&CK: T1195.002 - Supply Chain Compromise (when modified)

# Log the execution for debugging
echo "$(date): Build update script executed by $(whoami)" >> /home/developer/build-update.log

# Check if builds directory exists
if [ ! -d "/home/developer/builds" ]; then
    echo "$(date): Creating builds directory" >> /home/developer/build-update.log
    mkdir -p /home/developer/builds
    chmod 755 /home/developer/builds
fi

# Check if shared builds directory exists and copy to it
if [ -d "/opt/shared-builds" ]; then
    echo "$(date): Copying to shared builds directory" >> /home/developer/build-update.log
    cp /home/developer/builds/return-to-land.py /opt/shared-builds/ 2>/dev/null || true
fi

# Currently just performs routine maintenance (initially benign)
echo "$(date): Performing routine build maintenance..." >> /home/developer/build-update.log

# Simple file check and maintenance
if [ -f "/home/developer/builds/return-to-land.py" ]; then
    echo "$(date): RTL module found, version check passed" >> /home/developer/build-update.log
else
    echo "$(date): RTL module missing, deploying default version..." >> /home/developer/build-update.log
fi

# NOTE FOR DEVELOPERS: 
# To deploy updated RTL modules, modify this script to create new versions
# Example: cat > /home/developer/builds/return-to-land.py << 'EOF'
# (Add your malicious RTL code here)
# EOF

echo "$(date): Build maintenance complete" >> /home/developer/build-update.log
exit 0
EOF

RUN chmod +x /bin/build-update.sh

# Create legitimate RTL module inline
RUN cat > /builds/return-to-land.py << 'EOF'
#!/usr/bin/env python3
"""
Legitimate Return-to-Land Module
This is the original, safe implementation that will be replaced
"""

from pymavlink import mavutil
import time
import math

def wait_for_mode(master, mode):
    """Wait for the drone to enter the specified mode"""
    while True:
        msg = master.recv_match(type='HEARTBEAT', blocking=True)
        if msg and msg.custom_mode == mode:
            break
        time.sleep(0.1)

def return_to_launch():
    """Safe return-to-launch implementation"""
    try:
        # Connect to the drone
        connection_string = "udp:0.0.0.0:14550"
        master = mavutil.mavlink_connection(connection_string)
        master.wait_heartbeat()
        
        print("Connected to drone")
        print("Initiating safe return-to-launch sequence...")
        
        # Set RTL mode
        master.mav.set_mode_send(
            master.target_system,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
            mavutil.mavlink.COPTER_MODE_RTL
        )
        
        print("RTL mode activated")
        print("Drone returning to launch point safely")
        
        # Wait for RTL mode confirmation
        wait_for_mode(master, mavutil.mavlink.COPTER_MODE_RTL)
        
        print("Return-to-launch complete")
        return True
        
    except Exception as e:
        print(f"RTL failed: {e}")
        print("Emergency landing initiated")
        return False

if __name__ == "__main__":
    print("DVD Drone Return-to-Land Module v1.0")
    print("Safe return-to-launch system")
    return_to_launch()
EOF

RUN chmod +x /builds/return-to-land.py

# Copy build-update.sh script from context
COPY developer-machine/build-update.sh /bin/build-update.sh
RUN chmod +x /bin/build-update.sh

# Create cron file that runs the build script as root (intentional vulnerability)
RUN echo "*/2 * * * * root /bin/build-update.sh" > /etc/cron.d/build-update && \
    chmod 0644 /etc/cron.d/build-update && \
    touch /var/log/cron.log && \
    touch /var/log/build-pipeline.log

# Create a simple development project for realism
RUN echo '#!/usr/bin/env python3' > /projects/drone_dev.py && \
    echo '# Drone Development Test Script' >> /projects/drone_dev.py && \
    echo 'print("DVD Drone Development Environment")' >> /projects/drone_dev.py && \
    echo 'print("Available build targets: RTL, navigation, telemetry")' >> /projects/drone_dev.py && \
    echo 'print("Use build system for deployments")' >> /projects/drone_dev.py && \
    chmod +x /projects/drone_dev.py

RUN chown -R developer:developer /home/developer

# Create startup script that initializes the environment
RUN cat > /startup.sh << 'EOF'
#!/bin/bash

# Start cron service
service cron start

# Ensure build directories exist
mkdir -p /builds /opt/shared-builds

# Set proper permissions
chmod 755 /builds /opt/shared-builds
chown developer:developer /builds

# Create initial RTL module if it doesn't exist
if [ ! -f /builds/return-to-land.py ]; then
    cat > /builds/return-to-land.py << 'INNER_EOF'
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
INNER_EOF
    chmod +x /builds/return-to-land.py
    chown developer:developer /builds/return-to-land.py
fi

# Run initial build pipeline
/bin/build-update.sh

# Keep container running
exec "$@"
EOF

RUN chmod +x /startup.sh

# Set startup command
CMD ["/startup.sh", "tail", "-f", "/dev/null"]