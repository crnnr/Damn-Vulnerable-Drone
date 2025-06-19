# DEVELOPER MACHINE - DAMN VULNERABLE DRONE EDITION
# WARNING: This container contains intentional vulnerabilities for educational purposes
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Copy restart service script from context
COPY developer-machine/restart-gcs-service.sh /bin/restart-gcs-service.sh
RUN chmod +x /bin/restart-gcs-service.sh

# Copy entrypoint script
COPY developer-machine/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN echo "*/2 * * * * root /bin/build-update.sh" > /etc/cron.d/build-update && \
    chmod 0644 /etc/cron.d/build-update && \
    touch /var/log/cron.log && \
    touch /var/log/build-pipeline.log && \
    touch /var/log/infrastructure-restart-service.log

# Create developer user with limited privileges (MITRE: Initial Access)
RUN useradd -m -s /bin/bash developer && \
    echo "developer:dev123" | chpasswd

# Install development tools and dependencies including Docker CLI
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
    docker.io \
    && pip3 install future pymavlink MAVProxy mavsdk \
    && rm -rf /var/lib/apt/lists/*

RUN echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir scripts

# Add developer to sudo group for certain commands (MITRE: Privilege Escalation - Sudo)
RUN usermod -aG sudo developer

# Create CTF directories in root
RUN mkdir -p /Documents /projects /builds /bin /sourcecode

# Copy all container files to sourcecode for monitoring and automatic deployment
COPY ground-control-station/ /sourcecode/ground-control-station/
COPY simulator/ /sourcecode/simulator/
COPY flight-controller/ /sourcecode/flight-controller/
COPY companion-computer/ /sourcecode/companion-computer/

RUN chown -R developer:developer /sourcecode

# Create additional developer directories for source monitoring
RUN mkdir -p /home/developer/src /home/developer/modules /home/developer/config

# Create build-update.sh script inline
RUN cat > /bin/build-update.sh << 'EOF'
#!/bin/bash

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
# Copy build-update.sh script from context
COPY developer-machine/build-update.sh /bin/build-update.sh
RUN chmod +x /bin/build-update.sh

# Create a simple development project for realism
RUN echo '#!/usr/bin/env python3' > /projects/drone_dev.py && \
    echo '# Drone Development Test Script' >> /projects/drone_dev.py && \
    echo 'print("DVD Drone Development Environment")' >> /projects/drone_dev.py && \
    echo 'print("Available build targets: RTL, navigation, telemetry")' >> /projects/drone_dev.py && \
    echo 'print("Use build system for deployments")' >> /projects/drone_dev.py && \
    chmod +x /projects/drone_dev.py

# Create additional source files for monitoring demonstration
RUN echo '#!/usr/bin/env python3' > /home/developer/src/navigation.py && \
    echo '# Navigation Module' >> /home/developer/src/navigation.py && \
    echo 'def navigate_to_waypoint(x, y, z):' >> /home/developer/src/navigation.py && \
    echo '    print(f"Navigating to {x}, {y}, {z}")' >> /home/developer/src/navigation.py && \
    echo '    return True' >> /home/developer/src/navigation.py && \
    chmod +x /home/developer/src/navigation.py

RUN echo '#!/usr/bin/env python3' > /home/developer/modules/telemetry.py && \
    echo '# Telemetry Module' >> /home/developer/modules/telemetry.py && \
    echo 'def send_telemetry_data(data):' >> /home/developer/modules/telemetry.py && \
    echo '    print(f"Sending telemetry: {data}")' >> /home/developer/modules/telemetry.py && \
    echo '    return True' >> /home/developer/modules/telemetry.py && \
    chmod +x /home/developer/modules/telemetry.py

RUN echo '{' > /home/developer/config/drone-config.json && \
    echo '  "flight_mode": "auto",' >> /home/developer/config/drone-config.json && \
    echo '  "max_altitude": 100,' >> /home/developer/config/drone-config.json && \
    echo '  "rtl_enabled": true' >> /home/developer/config/drone-config.json && \
    echo '}' >> /home/developer/config/drone-config.json

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



# Set startup command
CMD ["/entrypoint.sh", "tail", "-f", "/dev/null"]